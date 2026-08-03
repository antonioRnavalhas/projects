from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_home_is_served_by_fastapi():
    response = client.get("/")
    assert response.status_code == 200
    assert "Léo" in response.text
    assert "/static/js/app.js" in response.text


def test_health_endpoint():
    response = client.get("/api/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_chat_contract():
    response = client.post(
        "/api/chat",
        json={
            "message": "I need a compact sofa under €1,000",
            "language": "en",
        },
    )
    payload = response.json()
    assert response.status_code == 200
    assert payload["session_id"]
    assert payload["mode"] in {"demo", "ai"}
    assert payload["products"]


def test_api_detects_message_language_without_a_forced_preference():
    response = client.post(
        "/api/chat",
        json={
            "message": "I need a compact sofa under €1,000",
            "language": None,
        },
    )

    assert response.status_code == 200
    assert response.json()["language"] == "en"
    assert response.json()["message"].startswith("I found")
