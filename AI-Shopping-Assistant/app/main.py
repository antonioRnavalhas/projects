from __future__ import annotations

from pathlib import Path

from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

from app.config import BASE_DIR, settings
from app.memory import InMemoryConversationStore
from app.models import ChatRequest, ChatResponse, HealthResponse
from app.repository import ProductRepository
from app.services.assistant import ShoppingAssistant
from app.services.intent import IntentExtractor

app = FastAPI(
    title=settings.app_name,
    description="Shopping assistant prototype with deterministic catalogue control.",
    version="1.0.0",
)

app.mount("/static", StaticFiles(directory=BASE_DIR / "app" / "static"), name="static")
templates = Jinja2Templates(directory=BASE_DIR / "app" / "templates")

repository = ProductRepository(BASE_DIR / "data" / "products.json")
memory = InMemoryConversationStore(
    ttl_seconds=settings.session_ttl_seconds,
    max_history_messages=settings.max_history_messages,
)
extractor = IntentExtractor(
    api_key=settings.iaedu_api_key,
    endpoint=settings.iaedu_api_endpoint,
    channel_id=settings.iaedu_channel_id,
    timeout_seconds=settings.iaedu_timeout_seconds,
    debug_stream=settings.iaedu_debug_stream,
)
assistant = ShoppingAssistant(repository, memory, extractor, settings)


@app.get("/", response_class=HTMLResponse, include_in_schema=False)
async def home(request: Request):
    return templates.TemplateResponse(
        request=request,
        name="index.html",
        context={
            "app_name": settings.app_name,
            "initial_mode": "ai" if settings.ai_enabled else "demo",
        },
    )


@app.get("/api/health", response_model=HealthResponse)
async def health() -> HealthResponse:
    return HealthResponse(
        status="ok",
        mode="ai" if settings.ai_enabled else "demo",
        provider="iaedu" if settings.ai_enabled else None,
    )


@app.post("/api/chat", response_model=ChatResponse)
async def chat(payload: ChatRequest) -> ChatResponse:
    try:
        return assistant.chat(payload)
    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail="The assistant could not process this message.",
        ) from exc


@app.delete("/api/sessions/{session_id}", status_code=204)
async def clear_session(session_id: str):
    memory.delete(session_id)
    return None
