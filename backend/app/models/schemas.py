# backend/app/models/schemas.py
# Pydantic models for request/response validation

from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


# ── AI Schemas ────────────────────────────────────────────────────────────────

class SummarizeRequest(BaseModel):
    content: str = Field(default="", description="Note content to summarize")
    file_url: Optional[str] = None
    file_type: Optional[str] = None

class SummarizeResponse(BaseModel):
    summary: str
    word_count: int

class ExplainRequest(BaseModel):
    text: str = Field(..., min_length=5, description="Text to explain")

class ExplainResponse(BaseModel):
    explanation: str

class QuizRequest(BaseModel):
    content: str = Field(default="", description="Note content for quiz")
    num_questions: int = Field(default=5, ge=1, le=15)
    file_url: Optional[str] = None
    file_type: Optional[str] = None

class QuizQuestion(BaseModel):
    id: str
    question: str
    options: list[str] = Field(..., min_length=2, max_length=6)
    correct_index: int = Field(..., ge=0)
    explanation: Optional[str] = None

class QuizResponse(BaseModel):
    questions: list[QuizQuestion]
    total: int


# ── Notes Schemas ─────────────────────────────────────────────────────────────

class NoteCreateRequest(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    content: str = Field(..., min_length=1)
    tags: list[str] = []
    file_url: Optional[str] = None
    file_type: Optional[str] = None

class NoteResponse(BaseModel):
    id: str
    title: str
    content: str
    user_id: str
    tags: list[str]
    file_url: Optional[str]
    file_type: Optional[str]
    created_at: datetime
    updated_at: datetime


# ── File Upload Schemas ───────────────────────────────────────────────────────

class FileUploadResponse(BaseModel):
    url: str
    file_name: str
    file_type: str
    size_bytes: int


# ── Health Schema ─────────────────────────────────────────────────────────────

class HealthResponse(BaseModel):
    status: str
    version: str
    ai_provider: str
    ai_configured: bool
