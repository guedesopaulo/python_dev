"""FastAPI application + FastMCP server."""

from collections.abc import AsyncGenerator
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.responses import RedirectResponse
from fastmcp import FastMCP
from loguru import logger

from src.config import settings
from src.endpoints.echo import router as echo_router
from src.exception_handlers import register_exception_handlers
from src.middleware import BearerTokenMiddleware


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None]:
    _ = app
    async with mcp_app.router.lifespan_context(mcp_app):
        logger.info("startup complete")
        yield
        logger.info("shutdown complete")


app = FastAPI(
    title="python-dev",
    version="0.0.2",
    swagger_ui_parameters={"displayRequestDuration": True},
    lifespan=lifespan,
)

register_exception_handlers(app)
app.add_middleware(BearerTokenMiddleware)
app.include_router(echo_router)

# MCP: auto-generate tools from all FastAPI routes.
# Tools call back into these routes over HTTP, so that loopback request must carry the
# Bearer token BearerTokenMiddleware expects — otherwise every tool call gets a 401.
_mcp_client_kwargs: dict[str, object] = {}
if settings.ENVIRONMENT == "local" and settings.LOCAL_API_TOKEN:
    _mcp_client_kwargs["headers"] = {
        "Authorization": f"Bearer {settings.LOCAL_API_TOKEN}"
    }

mcp = FastMCP.from_fastapi(
    app, name="python-dev", httpx_client_kwargs=_mcp_client_kwargs
)
mcp_app = mcp.http_app(transport="http", path="/")
app.mount("/mcp", mcp_app)


@app.get("/", response_class=RedirectResponse, include_in_schema=False)
async def redirect_to_docs() -> str:
    return "/docs"


@app.get("/health", tags=["health"])
async def health() -> dict[str, str]:
    return {"status": "ok"}
