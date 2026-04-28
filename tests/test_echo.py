"""Smoke tests for the echo endpoint."""

from fastapi.testclient import TestClient

from src.main import app

client = TestClient(app)


def test_echo_when_message_provided_returns_message() -> None:
    response = client.get("/echo", params={"message": "hello"})
    assert response.status_code == 200
    assert response.json() == {"message": "hello"}


def test_echo_when_message_missing_returns_422() -> None:
    response = client.get("/echo")
    assert response.status_code == 422
