# backend/app/main.py
# FastAPI backend for AI Smart Notes App

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.routes import ai_routes, notes_routes, file_routes, health_routes

# ── App Instance ─────────────────────────────────────────────────────────────
app = FastAPI(
    title="AI Smart Notes API",
    description="Backend API for AI-powered notes, quiz generation, and summarization",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# ── CORS Middleware ───────────────────────────────────────────────────────────
# Allow Flutter app (any origin during development)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],          # In production: restrict to your domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Route Registration ────────────────────────────────────────────────────────
app.include_router(health_routes.router, tags=["Health"])
app.include_router(ai_routes.router, prefix="/api/ai", tags=["AI"])
app.include_router(notes_routes.router, prefix="/api/notes", tags=["Notes"])
app.include_router(file_routes.router, prefix="/api/files", tags=["Files"])


# ── Root endpoint ─────────────────────────────────────────────────────────────
@app.get("/")
async def root():
    return {
        "message": "AI Smart Notes API is running!",
        "version": "1.0.0",
        "docs": "/docs",
    }
