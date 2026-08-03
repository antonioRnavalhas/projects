from pathlib import Path

import pytest

from app.config import Settings
from app.memory import InMemoryConversationStore
from app.repository import ProductRepository
from app.services.assistant import ShoppingAssistant
from app.services.intent import IntentExtractor


@pytest.fixture
def repository() -> ProductRepository:
    return ProductRepository(Path("data/products.json"))


@pytest.fixture
def assistant(repository: ProductRepository) -> ShoppingAssistant:
    test_settings = Settings(
        iaedu_api_key=None,
        max_results=4,
        session_ttl_seconds=3600,
        max_history_messages=8,
    )
    return ShoppingAssistant(
        repository=repository,
        memory=InMemoryConversationStore(3600, 8),
        extractor=IntentExtractor(api_key=None, endpoint=None, channel_id=None),
        settings=test_settings,
    )
