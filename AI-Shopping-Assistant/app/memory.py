from __future__ import annotations

import time
import uuid
from dataclasses import dataclass, field
from threading import Lock

from app.models import Language, SearchCriteria


@dataclass
class ConversationState:
    language: Language = "en"
    iaedu_thread_id: str = field(default_factory=lambda: str(uuid.uuid4()))
    messages: list[dict[str, str]] = field(default_factory=list)
    last_product_ids: list[str] = field(default_factory=list)
    last_criteria: SearchCriteria | None = None
    updated_at: float = field(default_factory=time.time)


class InMemoryConversationStore:
    def __init__(self, ttl_seconds: int, max_history_messages: int):
        self._sessions: dict[str, ConversationState] = {}
        self._ttl_seconds = ttl_seconds
        self._max_history_messages = max_history_messages
        self._lock = Lock()

    def get_or_create(self, session_id: str | None) -> tuple[str, ConversationState]:
        with self._lock:
            self._remove_expired()
            safe_id = session_id or str(uuid.uuid4())
            state = self._sessions.setdefault(safe_id, ConversationState())
            state.updated_at = time.time()
            return safe_id, state

    def add_message(self, state: ConversationState, role: str, content: str) -> None:
        state.messages.append({"role": role, "content": content})
        state.messages = state.messages[-self._max_history_messages :]
        state.updated_at = time.time()

    def delete(self, session_id: str) -> bool:
        with self._lock:
            return self._sessions.pop(session_id, None) is not None

    def _remove_expired(self) -> None:
        cutoff = time.time() - self._ttl_seconds
        expired = [
            session_id
            for session_id, state in self._sessions.items()
            if state.updated_at < cutoff
        ]
        for session_id in expired:
            del self._sessions[session_id]
