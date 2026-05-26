# backend/app/api/routes/health_routes.py

from fastapi import APIRouter
from app.models.schemas import HealthResponse
from app.core.config import get_settings

router = APIRouter()


@router.get("/health", response_model=HealthResponse)
async def health_check():
    """Check if the server is running and AI is configured."""
    settings = get_settings()
    ai_configured = bool(
        settings.groq_api_key or settings.gemini_api_key or settings.openai_api_key
    )
    return HealthResponse(
        status="ok",
        version=settings.app_version,
        ai_provider=settings.ai_provider,
        ai_configured=ai_configured,
    )
