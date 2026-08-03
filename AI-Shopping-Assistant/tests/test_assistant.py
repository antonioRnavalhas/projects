from app.models import ChatRequest


def test_follow_up_explains_previous_sustainable_results(assistant):
    first = assistant.chat(
        ChatRequest(message="Show me sustainable dining furniture", language="en")
    )
    follow_up = assistant.chat(
        ChatRequest(
            session_id=first.session_id,
            message="Why is it sustainable?",
            language="en",
        )
    )

    assert first.intent == "product_search"
    assert [product["id"] for product in first.products] == [
        "table-extend",
        "chair-cane",
    ]
    assert follow_up.intent == "sustainability_followup"
    assert [product["id"] for product in follow_up.products] == [
        "table-extend",
        "chair-cane",
    ]
    assert "FSC" in follow_up.message
    assert "not a complete" in follow_up.message


def test_selected_products_create_comparison_without_llm(assistant):
    response = assistant.chat(
        ChatRequest(
            message="Compare selected products",
            language="en",
            selected_product_ids=["desk-nordic", "desk-forge"],
        )
    )

    assert response.intent == "compare"
    assert response.mode == "demo"
    assert [product["id"] for product in response.comparison] == [
        "desk-nordic",
        "desk-forge",
    ]


def test_explicit_api_language_preference_is_supported(assistant):
    response = assistant.chat(
        ChatRequest(
            message="Show me a compact desk",
            language="pt",
        )
    )
    assert response.language == "pt"
    assert response.message.startswith("Encontrei")


def test_first_message_language_is_detected_when_not_selected(assistant):
    response = assistant.chat(
        ChatRequest(message="Procuro uma secretária compacta abaixo de 300 €")
    )
    assert response.language == "pt"
    assert response.products[0]["id"] == "desk-forge"
