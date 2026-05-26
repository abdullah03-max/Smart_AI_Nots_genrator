# backend/app/api/routes/notes_routes.py
# Notes endpoints — these are optional if you use Supabase directly from Flutter.
# Useful for server-side validation or additional processing.

from fastapi import APIRouter, Depends, HTTPException
from app.core.auth_middleware import verify_token, get_current_user_id

router = APIRouter()


@router.get("/")
async def list_notes(token: dict = Depends(verify_token)):
    """
    List notes for the current user.
    NOTE: The Flutter app queries Supabase directly — this endpoint is
    a server-side alternative for when you need backend processing.
    """
    user_id = get_current_user_id(token)
    return {
        "message": f"Notes for user {user_id}",
        "note": "Use Supabase client in Flutter for direct DB access",
    }


@router.get("/{note_id}")
async def get_note(note_id: str, token: dict = Depends(verify_token)):
    """Get a specific note by ID."""
    user_id = get_current_user_id(token)
    return {"note_id": note_id, "user_id": user_id}
