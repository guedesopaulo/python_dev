# syntax=docker/dockerfile:1

# ---------- builder: resolve dependencies into /app/.venv ----------
FROM python:3.13-slim-bookworm AS builder

# Pinned to the same uv version used locally and in CI.
COPY --from=ghcr.io/astral-sh/uv:0.12.10 /uv /uvx /bin/

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=0

WORKDIR /app

# Dependencies only, from the lockfile. This layer stays cached until uv.lock or
# pyproject.toml change, so source edits don't trigger a reinstall.
# --no-dev keeps pytest/ruff/mypy out of the runtime image.
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --locked --no-dev --no-install-project

# ---------- runtime ----------
FROM python:3.13-slim-bookworm AS runtime

# Fixed uid/gid: predictable for Kubernetes `runAsUser` and for volume ownership,
# instead of whatever id useradd happens to pick.
RUN groupadd --system --gid 999 app \
    && useradd --system --gid 999 --uid 999 --create-home --home-dir /home/app app

WORKDIR /app

COPY --from=builder --chown=app:app /app/.venv /app/.venv
COPY --chown=app:app src ./src

# The project is not installed as a package (pyproject has no [build-system]), so
# `src` is imported from the working directory — same reason scripts/ set PYTHONPATH.
ENV PATH="/app/.venv/bin:$PATH" \
    PYTHONPATH=/app \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

USER app
EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import sys, urllib.request; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=2).status == 200 else 1)"

# No --reload: that is dev-only (see scripts/00_start.sh). The MCP server is mounted
# at /mcp on this same app, so one process serves both the REST API and MCP.
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
