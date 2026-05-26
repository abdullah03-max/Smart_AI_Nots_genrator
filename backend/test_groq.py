import httpx
import json
import os
from dotenv import load_dotenv

load_dotenv()
api_key = os.getenv("GROQ_API_KEY", "")
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
    },
    {"role": "user", "content": "Hello"}
]

payload = {
    "model": model,
    "messages": messages,
    "max_tokens": 2048,
    "temperature": 0.7,
}

try:
    with httpx.Client(timeout=10.0) as client:
        resp = client.post(url, headers=headers, json=payload)
        print("Status:", resp.status_code)
        print("Response:", resp.text)
except Exception as e:
    print("Error:", str(e))
