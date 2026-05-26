# backend/app/api/routes/ai_routes.py

from fastapi import APIRouter, Depends, HTTPException
from app.models.schemas import (
    SummarizeRequest, SummarizeResponse,
    ExplainRequest, ExplainResponse,
    QuizRequest, QuizResponse, QuizQuestion,
)
from app.services.ai_service import AiService
from app.core.auth_middleware import verify_token

router = APIRouter()
ai_service = AiService()


@router.post("/summarize", response_model=SummarizeResponse)
async def summarize_note(
    request: SummarizeRequest,
    _token: dict = Depends(verify_token),
):
    """
    Summarize the given note content using AI.
    Requires a valid Supabase JWT in the Authorization header.
    """
    try:
        summary = await ai_service.summarize(
            request.content,
            request.file_url,
            request.file_type,
        )
        return SummarizeResponse(
            summary=summary,
            word_count=len(summary.split()),
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI service error: {str(e)}")


@router.post("/explain", response_model=ExplainResponse)
async def explain_text(
    request: ExplainRequest,
    _token: dict = Depends(verify_token),
):
    """Explain a difficult piece of text in simple language."""
    try:
        explanation = await ai_service.explain(request.text)
        return ExplainResponse(explanation=explanation)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI service error: {str(e)}")


@router.post("/generate-quiz", response_model=QuizResponse)
async def generate_quiz(
    request: QuizRequest,
    _token: dict = Depends(verify_token),
):
    """
    Generate multiple-choice quiz questions from note content.
    Returns structured JSON with questions, options, and correct answers.
    """
    try:
        questions_data = await ai_service.generate_quiz(
            content=request.content,
            num_questions=request.num_questions,
            file_url=request.file_url,
            file_type=request.file_type,
        )

        questions = []
        for i, q in enumerate(questions_data):
            questions.append(
                QuizQuestion(
                    id=q.get("id", f"q{i+1}"),
                    question=q.get("question", ""),
                    options=q.get("options", []),
                    correct_index=q.get("correct_index", 0),
                    explanation=q.get("explanation"),
                )
            )

        return QuizResponse(questions=questions, total=len(questions))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Quiz generation failed: {str(e)}")
