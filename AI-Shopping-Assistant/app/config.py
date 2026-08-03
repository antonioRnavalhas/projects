from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path

from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent.parent
load_dotenv(BASE_DIR / ".env")


@dataclass(frozen=True)
class Settings:
    app_name: str = "Léo — Shopping Assistant Prototype"
    iaedu_api_key: str | None = os.getenv("IAEDU_API_KEY") or None
    iaedu_api_endpoint: str | None = os.getenv("IAEDU_API_ENDPOINT") or None
    iaedu_channel_id: str | None = os.getenv("IAEDU_CHANNEL_ID") or None
    iaedu_timeout_seconds: float = float(os.getenv("IAEDU_TIMEOUT_SECONDS", "12"))
    iaedu_debug_stream: bool = os.getenv("IAEDU_DEBUG_STREAM", "0") == "1"
    session_ttl_seconds: int = int(os.getenv("SESSION_TTL_SECONDS", "3600"))
    max_history_messages: int = 8
    max_results: int = 4

    @property
    def ai_enabled(self) -> bool:
        return bool(
            self.iaedu_api_key
            and self.iaedu_api_endpoint
            and self.iaedu_channel_id
        )


settings = Settings()
