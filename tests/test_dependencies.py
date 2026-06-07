"""Tests for the per-IP sliding-window rate limiter."""

from types import SimpleNamespace

import pytest
from fastapi import Depends
from fastapi import FastAPI
from fastapi import Request
from fastapi.testclient import TestClient

from src import dependencies
from src.dependencies import rate_limit


def _client_with_limit(max_requests: int, window: int) -> TestClient:
    app = FastAPI()
    limiter = rate_limit(max_requests=max_requests, window=window)

    @app.get("/limited", dependencies=[Depends(limiter)])
    async def limited() -> dict[str, str]:
        return {"ok": "yes"}

    return TestClient(app)


def test_rate_limit_when_under_limit_allows_requests() -> None:
    client = _client_with_limit(max_requests=2, window=60)
    assert client.get("/limited").status_code == 200
    assert client.get("/limited").status_code == 200


def test_rate_limit_when_over_limit_returns_429() -> None:
    client = _client_with_limit(max_requests=1, window=60)
    assert client.get("/limited").status_code == 200

    response = client.get("/limited")
    assert response.status_code == 429
    assert "Rate limit exceeded" in response.json()["detail"]


def test_rate_limit_when_window_elapsed_allows_again(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    clock = SimpleNamespace(now=1000.0)
    monkeypatch.setattr(
        dependencies, "time", SimpleNamespace(monotonic=lambda: clock.now)
    )
    client = _client_with_limit(max_requests=1, window=10)

    assert client.get("/limited").status_code == 200
    clock.now = 1011.0  # 11s later: the earlier request falls outside the window
    assert client.get("/limited").status_code == 200


def test_rate_limit_when_no_client_uses_unknown_bucket() -> None:
    limiter = rate_limit(max_requests=1, window=60)
    scope: dict[str, object] = {
        "type": "http",
        "method": "GET",
        "path": "/",
        "headers": [],
        "client": None,
    }

    limiter(Request(scope))  # client is None -> "unknown" bucket, no raise
