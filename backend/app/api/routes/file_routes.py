# backend/app/api/routes/file_routes.py

import os
import uuid
from fastapi import APIRouter, Depends, File, UploadFile, HTTPException
from app.core.auth_middleware import verify_token
from app.core.config import get_settings
from app.models.schemas import FileUploadResponse

router = APIRouter()


@router.post("/upload", response_model=FileUploadResponse)
async def upload_file(
    file: UploadFile = File(...),
    token: dict = Depends(verify_token),
):
    """
    Upload a file (PDF or image) to the server.
    In production, this would upload to Supabase Storage or S3.
    The Flutter app can also upload directly to Supabase Storage.
    """
    settings = get_settings()
    max_bytes = settings.max_upload_size_mb * 1024 * 1024

    # ── Validate file extension ──────────────────────────────────────────────
    extension = file.filename.split(".")[-1].lower() if file.filename else ""
    if extension not in settings.allowed_extensions:
        raise HTTPException(
            status_code=400,
            detail=f"File type '{extension}' not allowed. "
            f"Allowed: {', '.join(settings.allowed_extensions)}",
        )

    # ── Read and validate file size ──────────────────────────────────────────
    content = await file.read()
    if len(content) > max_bytes:
        raise HTTPException(
            status_code=413,
            detail=f"File too large. Maximum size: {settings.max_upload_size_mb}MB",
        )

    # ── Generate unique filename ─────────────────────────────────────────────
    unique_name = f"{uuid.uuid4()}.{extension}"

    # ── TODO: Upload to Supabase Storage ─────────────────────────────────────
    # from supabase import create_client
    # supabase = create_client(settings.supabase_url, settings.supabase_service_role_key)
    # supabase.storage.from_("note-files").upload(unique_name, content)
    # public_url = supabase.storage.from_("note-files").get_public_url(unique_name)

    # For now, return a placeholder URL
    placeholder_url = f"https://your-supabase-project.supabase.co/storage/v1/object/public/note-files/{unique_name}"

    return FileUploadResponse(
        url=placeholder_url,
        file_name=unique_name,
        file_type=extension,
        size_bytes=len(content),
    )
