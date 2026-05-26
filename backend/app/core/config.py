# backend/app/core/config.py

from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings


BASE_DIR = Path(__file__).resolve().parents[2]


class Settings(BaseSettings):
    app_name: str = "AI Smart Notes API"
    app_version: str = "1.0.0"
    debug: bool = False

    # ── AI Provider ────────────────────────────────────────────────────────────
    ai_provider: str = "groq"            # "groq" | "gemini" | "openai"

    # Groq — FREE + FAST (recommended)
    # Get key: https://console.groq.com
    groq_api_key: str = ""

    # Google Gemini — free but slower
    gemini_api_key: str = ""

    # OpenAI — paid
    openai_api_key: str = ""

    # ── Supabase ───────────────────────────────────────────────────────────────
    supabase_url: str = ""
    supabase_service_role_key: str = ""
    supabase_jwt_secret: str = ""

    # ── Upload limits ──────────────────────────────────────────────────────────
    max_upload_size_mb: int = 10
    allowed_extensions: list[str] = ["pdf", "png", "jpg", "jpeg"]

    class Config:
        env_file = BASE_DIR / ".env"
        env_file_encoding = "utf-8"


@lru_cache()
def get_settings() -> Settings:
    return Settings()
