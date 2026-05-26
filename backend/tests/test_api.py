# backend/tests/test_api.py
# Basic API tests — run with: pytest tests/ -v

import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app


@pytest.mark.asyncio
async def test_root():
    """Test the root endpoint returns 200."""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        resp = await client.get("/")
    assert resp.status_code == 200
    assert "message" in resp.json()


@pytest.mark.asyncio
async def test_health():
    """Test health check endpoint."""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        resp = await client.get("/health")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "ok"
    assert "version" in data
    assert "ai_provider" in data


@pytest.mark.asyncio
async def test_summarize_requires_auth():
    """Summarize endpoint should return 403 without auth token."""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        resp = await client.post("/api/ai/summarize", json={"content": "Test content"})
    # Should be 403 (no credentials) or 401
    assert resp.status_code in [401, 403]


@pytest.mark.asyncio
async def test_quiz_requires_auth():
    """Quiz endpoint should return 403 without auth token."""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        resp = await client.post(
            "/api/ai/generate-quiz",
            json={"content": "Test content", "num_questions": 3}
        )
    assert resp.status_code in [401, 403]


@pytest.mark.asyncio
async def test_docs_accessible():
    """Swagger docs should be accessible."""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        resp = await client.get("/docs")
    assert resp.status_code == 200
