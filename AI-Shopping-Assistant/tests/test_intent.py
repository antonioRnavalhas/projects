import pytest

from app.services.intent import IntentExtractor


@pytest.mark.parametrize(
    ("message", "expected"),
    [
        ("A sofa under €1,000", 1000),
        ("Un canapé à moins de 1 000 €", 1000),
        ("Um sofá abaixo de 1000 euros", 1000),
    ],
)
def test_extracts_localised_budget_formats(message, expected):
    criteria, used_ai = IntentExtractor(None, None, None).extract(
        message, None, None, "test-thread", [], []
    )
    assert criteria.max_price == expected
    assert used_ai is False


def test_detects_portuguese_sustainable_dining_query():
    criteria, _ = IntentExtractor(None, None, None).extract(
        "Procuro mobiliário de jantar sustentável", None, None, "test-thread", [], []
    )
    assert criteria.language == "pt"
    assert criteria.category == "dining"
    assert criteria.sustainable is True


def test_iaedu_failure_falls_back_to_local_rules(monkeypatch):
    extractor = IntentExtractor("test-key", "https://example.test/stream", "channel")

    def fail(*args, **kwargs):
        raise RuntimeError("simulated provider failure")

    monkeypatch.setattr(extractor, "_extract_with_iaedu", fail)
    criteria, used_ai = extractor.extract(
        "compact desk under €300", "en", None, "test-thread", [], []
    )

    assert criteria.category == "desk"
    assert criteria.max_price == 300
    assert used_ai is False


def test_parses_iaedu_sse_json_response():
    criteria = IntentExtractor._criteria_from_stream(
        [
            'data: {"type":"message","content":"{\\"intent\\":\\"product_search\\",\\"language\\":\\"en\\",\\"category\\":\\"sofa\\",\\"max_price\\":1000}"}',
            "data: [DONE]",
        ]
    )

    assert criteria.intent == "product_search"
    assert criteria.category == "sofa"
    assert criteria.max_price == 1000


def test_parses_iaedu_token_stream_without_start_event_content():
    criteria = IntentExtractor._criteria_from_stream(
        [
            'data: {"type":"start","content":"processing","run_id":"run"}',
            'data: {"type":"token","content":"{\\"intent\\":\\"product_search\\",","run_id":"run"}',
            'data: {"type":"token","content":"\\"language\\":\\"en\\"}","run_id":"run"}',
        ]
    )

    assert criteria.intent == "product_search"
    assert criteria.language == "en"


def test_finds_criteria_after_non_json_stream_metadata():
    criteria = IntentExtractor._criteria_from_stream(
        [
            'data: {"type":"token","content":"trace {not-json} result {\\"intent\\":\\"help\\",\\"language\\":\\"pt\\"}","run_id":"run"}',
        ]
    )

    assert criteria.intent == "help"
    assert criteria.language == "pt"
