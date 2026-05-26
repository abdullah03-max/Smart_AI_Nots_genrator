# backend/app/services/ai_service.py
# AI service — supports Groq (default, FREE + FAST), Gemini, and OpenAI
# Switch provider in .env: AI_PROVIDER=groq | gemini | openai

import json
import re
import httpx
from app.core.config import get_settings


class AiService:
    """
    Handles all AI API calls.
    Default provider: Groq (free, ~10x faster than Gemini).
    Get a free key at: https://console.groq.com
    """

    def __init__(self):
        self.settings = get_settings()

    # ── Public methods ────────────────────────────────────────────────────────

    async def _extract_text_from_pdf_url(self, pdf_url: str) -> str:
        try:
            import io
            from pypdf import PdfReader
            
            async with httpx.AsyncClient(timeout=30.0) as client:
                resp = await client.get(pdf_url)
                resp.raise_for_status()
                pdf_bytes = resp.content
            
            pdf_file = io.BytesIO(pdf_bytes)
            reader = PdfReader(pdf_file)
            
            text_list = []
            char_count = 0
            # Limit to first 5 pages and 8000 characters to prevent Groq free tier rate limits (6000 TPM)
            for i, page in enumerate(reader.pages[:5]):
                page_text = page.extract_text()
                if page_text:
                    if char_count + len(page_text) > 8000:
                        remaining_chars = 8000 - char_count
                        if remaining_chars > 0:
                            text_list.append(f"--- Page {i+1} ---\n{page_text[:remaining_chars]}\n[Content Truncated due to Rate Limits]")
                        break
                    text_list.append(f"--- Page {i+1} ---\n{page_text}")
                    char_count += len(page_text)
            
            return "\n\n".join(text_list)
        except Exception as e:
            return f"\n[Error extracting text from PDF: {str(e)}]\n"

    async def summarize(self, content: str, file_url: str = None, file_type: str = None) -> str:
        pdf_text = ""
        if file_url and file_type == "pdf":
            pdf_text = await self._extract_text_from_pdf_url(file_url)

        full_content = content
        if pdf_text:
            full_content += f"\n\n=== ATTACHED PDF CONTENT ===\n{pdf_text}"

        prompt = f"""You are a helpful study assistant.
Summarize the following notes and any attached PDF content in clear, concise bullet points (max 10 bullets).
Use simple language a student can understand. Make sure to cover key points from the attached PDF if present.

NOTES / PDF CONTENT:
{full_content}

OUTPUT: bullet points only, starting each with •"""
        return await self._call_ai(prompt, file_url, file_type)

    async def explain(self, text: str) -> str:
        prompt = f"""You are a patient tutor helping a university student.
Explain the following text in simple, easy-to-understand language.
Use examples where possible. Keep it under 200 words.

TEXT:
{text}

Simple explanation:"""
        return await self._call_ai(prompt)

    async def generate_quiz(self, content: str, num_questions: int = 5, file_url: str = None, file_type: str = None) -> list[dict]:
        pdf_text = ""
        if file_url and file_type == "pdf":
            pdf_text = await self._extract_text_from_pdf_url(file_url)

        full_content = content
        if pdf_text:
            full_content += f"\n\n=== ATTACHED PDF CONTENT ===\n{pdf_text}"

        prompt = f"""Create exactly {num_questions} multiple-choice questions from these notes and the attached PDF content if present.
Make sure to include questions from the attached PDF content if present.

RULES:
- Each question has exactly 4 options
- Only ONE option is correct
- Include a brief explanation for the correct answer

NOTES / PDF CONTENT:
{full_content}

RESPOND ONLY WITH VALID JSON — no markdown, no code fences, no extra text:
{{"questions":[{{"id":"q1","question":"...","options":["A","B","C","D"],"correct_index":0,"explanation":"..."}}]}}"""

        raw = await self._call_ai(prompt, file_url, file_type)
        return self._parse_quiz_json(raw, num_questions)

    # ── Provider routing ──────────────────────────────────────────────────────

    async def _call_ai(self, prompt: str, file_url: str = None, file_type: str = None) -> str:
        provider = self.settings.ai_provider.lower()
        if provider == "groq":
            return await self._call_groq(prompt, file_url, file_type)
        elif provider == "openai":
            return await self._call_openai(prompt, file_url, file_type)
        elif provider == "gemini":
            return await self._call_gemini(prompt, file_url, file_type)
        else:
            return await self._call_groq(prompt, file_url, file_type)  # default

    # ── Groq (FREE + FASTEST) ─────────────────────────────────────────────────

    async def _call_groq(self, prompt: str, file_url: str = None, file_type: str = None) -> str:
        """
        Call Groq API — free tier, ~500 tokens/sec.
        Model: llama-3.3-70b-versatile (best free model)
        Get key: https://console.groq.com
        """
        api_key = self.settings.groq_api_key
        if not api_key:
            return self._placeholder_response(prompt)

        url = "https://api.groq.com/openai/v1/chat/completions"
        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        }

        model = "llama-3.3-70b-versatile"
        messages = [
            {
                "role": "system",
                "content": "You are a helpful AI study assistant for university students.",
            }
        ]

        if file_url and file_type == "image":
            # Switch to vision model on Groq
            model = "meta-llama/llama-4-scout-17b-16e-instruct"
            messages.append({
                "role": "user",
                "content": [
                    {"type": "text", "text": prompt},
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": file_url
                        }
                    }
                ]
            })
        else:
            messages.append({"role": "user", "content": prompt})

        payload = {
            "model": model,
            "messages": messages,
            "max_tokens": 2048,
            "temperature": 0.7,
        }

        async with httpx.AsyncClient(timeout=30.0) as client:
            resp = await client.post(url, headers=headers, json=payload)
            if resp.status_code != 200:
                raise Exception(f"Groq API Error {resp.status_code}: {resp.text}")
            data = resp.json()
            return data["choices"][0]["message"]["content"]

    # ── Gemini (Google) ───────────────────────────────────────────────────────

    async def _call_gemini(self, prompt: str, file_url: str = None, file_type: str = None) -> str:
        api_key = self.settings.gemini_api_key
        if not api_key:
            return self._placeholder_response(prompt)

        url = (
            f"https://generativelanguage.googleapis.com/v1beta/models/"
            f"gemini-1.5-flash:generateContent?key={api_key}"
        )

        parts = [{"text": prompt}]

        if file_url and file_type == "image":
            try:
                import base64
                async with httpx.AsyncClient(timeout=30.0) as client:
                    img_resp = await client.get(file_url)
                    img_resp.raise_for_status()
                    img_bytes = img_resp.content
                    mime_type = img_resp.headers.get("content-type", "image/jpeg")
                
                parts.append({
                    "inlineData": {
                        "mimeType": mime_type,
                        "data": base64.b64encode(img_bytes).decode("utf-8")
                    }
                })
            except Exception as e:
                parts[0]["text"] += f"\n[Warning: Could not load attached image: {str(e)}]"

        payload = {
            "contents": [{"parts": parts}],
            "generationConfig": {"temperature": 0.7, "maxOutputTokens": 2048},
        }

        async with httpx.AsyncClient(timeout=60.0) as client:
            resp = await client.post(url, json=payload)
            if resp.status_code != 200:
                raise Exception(f"Gemini API Error {resp.status_code}: {resp.text}")
            data = resp.json()
            return data["candidates"][0]["content"]["parts"][0]["text"]

    # ── OpenAI ────────────────────────────────────────────────────────────────

    async def _call_openai(self, prompt: str, file_url: str = None, file_type: str = None) -> str:
        api_key = self.settings.openai_api_key
        if not api_key:
            return self._placeholder_response(prompt)

        url = "https://api.openai.com/v1/chat/completions"
        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        }

        messages = [
            {"role": "system", "content": "You are a helpful AI study assistant."}
        ]

        if file_url and file_type == "image":
            messages.append({
                "role": "user",
                "content": [
                    {"type": "text", "text": prompt},
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": file_url
                        }
                    }
                ]
            })
        else:
            messages.append({"role": "user", "content": prompt})

        payload = {
            "model": "gpt-4o-mini",
            "messages": messages,
            "max_tokens": 2048,
            "temperature": 0.7,
        }

        async with httpx.AsyncClient(timeout=60.0) as client:
            resp = await client.post(url, headers=headers, json=payload)
            if resp.status_code != 200:
                raise Exception(f"OpenAI API Error {resp.status_code}: {resp.text}")
            data = resp.json()
            return data["choices"][0]["message"]["content"]

    # ── Helpers ───────────────────────────────────────────────────────────────

    def _parse_quiz_json(self, raw: str, num_questions: int) -> list[dict]:
        try:
            clean = re.sub(r"```(?:json)?", "", raw).strip()
            # Sometimes the model wraps in extra text — find the JSON object
            match = re.search(r'\{.*\}', clean, re.DOTALL)
            if match:
                data = json.loads(match.group())
                questions = data.get("questions", [])
                if questions:
                    return questions
        except (json.JSONDecodeError, KeyError, AttributeError):
            pass
        return self._dummy_questions(num_questions)

    def _dummy_questions(self, n: int) -> list[dict]:
        return [
            {
                "id": f"q{i+1}",
                "question": f"Sample Q{i+1}: What is the main topic of your notes?",
                "options": [
                    "The correct answer (add GROQ_API_KEY for real questions)",
                    "Distractor B",
                    "Distractor C",
                    "Distractor D",
                ],
                "correct_index": 0,
                "explanation": "Set GROQ_API_KEY=your_key in backend/.env for AI-generated questions.",
            }
            for i in range(n)
        ]

    def _placeholder_response(self, prompt: str) -> str:
        if "quiz" in prompt.lower() or "questions" in prompt.lower():
            return json.dumps({"questions": self._dummy_questions(5)})
        elif "summarize" in prompt.lower() or "summary" in prompt.lower():
            return (
                "• Add your GROQ_API_KEY to backend/.env for real AI summaries\n"
                "• Get a FREE key at https://console.groq.com (no credit card)\n"
                "• Groq runs Llama 3.3 70B — fast and free\n"
                "• Restart the backend after adding the key"
            )
        return (
            "AI features need an API key. "
            "Get a FREE Groq key at https://console.groq.com and add "
            "GROQ_API_KEY=your_key to backend/.env"
        )
