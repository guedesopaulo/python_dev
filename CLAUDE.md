# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run development server (FastAPI on :8000, hot-reload)
bash scripts/00_start.sh

# Run the MCP server standalone (streamable HTTP on :8002)
bash scripts/01_start_mcp.sh

# Run all tests with coverage
uv run pytest && uv run coverage report -m

# Run a single test
uv run pytest tests/test_main.py::test_root_when_called_redirects_to_docs -v

# Lint and format
uv run ruff check .
uv run ruff format .
uv run ruff check --fix --unsafe-fixes  # auto-fix with type cleanup

# Type checking
uv run mypy .

# Pre-commit (runs ruff + mypy + bandit)
uv run pre-commit run --all-files

# Makefile shortcuts
make all       # deps + check + test
make check     # pre-commit run --all-files
make test      # pytest
make cov       # coverage: 100% on tests/*, plus the 70% project floor
```

## Architecture

FastAPI REST API with a FastMCP server auto-generated from the same routes — every FastAPI
endpoint is also exposed as an MCP tool, so there's no separate hand-written tool registry. This
is a minimal starter intended as a foundation for AI/ML/LLM tooling; today it ships a single
example `/echo` endpoint.

**Application wiring** (`src/main.py`):
- Build the `FastAPI` app, then `register_exception_handlers(app)`, add `BearerTokenMiddleware`,
  and `include_router(echo_router)`.
- `mcp = FastMCP.from_fastapi(app, name="python-dev")` reflects the routes into MCP tools;
  `mcp_app = mcp.http_app(transport="http", path="/")` is mounted at `app.mount("/mcp", mcp_app)`
  (streamable HTTP). The MCP app's lifespan is driven from the FastAPI `lifespan`.
- `GET /` redirects to `/docs`; `GET /health` returns `{"status": "ok"}`.

**Module layering** (the pattern for new features):
`endpoints/<module>.py` (route + validation) -> `service/<module>.py` (pure business logic) ->
`resources/<module>.py` (external I/O: DB/HTTP).

- Only `src/endpoints/echo.py` exists today. `service/` and `resources/` are conventions to follow
  when you add a module that needs business logic or external I/O — create them as needed.
- **Endpoints** define FastAPI routes, query validation, and per-endpoint rate limits via
  `dependencies.rate_limit()`.
- **Services** should be pure functions that transform data (no I/O).
- **Resources** own all external I/O. Use `httpx.AsyncClient` for outbound HTTP and manage its
  lifecycle via the FastAPI lifespan. Mock or monkeypatch the resource layer in tests — never hit
  real external systems in CI.

**Rate limiting** (`src/dependencies.py`): `rate_limit(max_requests, window)` returns a FastAPI
dependency enforcing a per-IP sliding window. Each endpoint creates its own independent limiter,
e.g. `@router.get("/x", dependencies=[Depends(rate_limit(30, 60))])`.

**Errors** (`src/exceptions.py` + `src/exception_handlers.py`): `AppServerError` (500),
`AppRequestError` (400), and `AppNotFoundError` (404) subclass `HTTPException`;
`register_exception_handlers` wires their handlers plus a `RequestValidationError` -> 422 handler,
all logging via loguru.

**Config** (`src/config.py`): pydantic-settings `Settings` (`ENVIRONMENT`, `LOCAL_API_TOKEN`)
loaded from `.env`. Singleton via `settings = Settings.model_validate({})`.

## Authentication

`BearerTokenMiddleware` in `src/middleware.py` (ASGI-level, applied globally):
- **Public paths** — `_PUBLIC_PATHS = {"/", "/health", "/docs", "/openapi.json"}` bypass auth
  entirely. Note `/mcp` is **not** public, so MCP calls require the token in local mode.
- **`ENVIRONMENT=local`** — validates the `Authorization: Bearer <token>` header against
  `LOCAL_API_TOKEN` from `.env`.
- **Cloud envs** (`dev`/`qas`/`prod`) — middleware currently passes through (placeholder comment
  for your JWT/OAuth2 validation).

To add a new public path, add it to `_PUBLIC_PATHS` in `src/middleware.py`.

## Code Standards

**Type safety:**
- No `dict[str, Any]` or untyped `JSONResponse` for structured payloads.
- Use `TypedDict` for structured entities (API payloads, configs).
- Modern syntax: `str | None`, `dict`, `list` (not `Optional`, `Dict`, `List`).

**Testing:**
- Naming: `test_<function>_<scenario>` (e.g., `test_echo_when_message_provided_returns_message`).
- Every FastAPI endpoint needs at least a smoke test.
- Minimum 70% coverage (enforced in `pyproject.toml`).

**Style:**
- KISS over OOP: prefer pure functions and dataclasses.
- `async def` for all I/O-bound routes.
- Structured logging with loguru.
- Ruff config in `ruff.toml`: UP040 is ignored (mypy CI compatibility), isort uses
  `force-single-line`, `ARG` rules are relaxed in tests.
