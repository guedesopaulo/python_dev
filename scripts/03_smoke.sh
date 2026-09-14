#!/usr/bin/env bash
# End-to-end smoke test: real HTTP against a running instance.
#
#   scripts/03_smoke.sh                        # starts uvicorn itself, tests, tears down
#   scripts/03_smoke.sh http://127.0.0.1:8000  # tests an already-running instance (CI)
#
# These are the same assertions CI runs against the container, kept here so they can be
# run locally without Docker and so both places share one source of truth.
set -euo pipefail
cd "$(dirname "$0")/.."

BASE="${1:-}"
TOKEN="${LOCAL_API_TOKEN:-smoke-token}"
PID=""
# shellcheck disable=SC2329  # invoked indirectly by the trap below
cleanup() { [ -n "$PID" ] && kill "$PID" 2>/dev/null || true; }
trap cleanup EXIT

if [ -z "$BASE" ]; then
    PORT="${SMOKE_PORT:-8099}"
    BASE="http://127.0.0.1:$PORT"
    ENVIRONMENT=local LOCAL_API_TOKEN="$TOKEN" \
        uv run --no-sync uvicorn src.main:app --host 127.0.0.1 --port "$PORT" >/dev/null 2>&1 &
    PID=$!
fi

for _ in $(seq 1 30); do
    if curl -fsS "$BASE/health" >/dev/null 2>&1; then break; fi
    sleep 1
done

fail=0
check() {  # check <label> <actual> <expected>
    if [ "$2" = "$3" ]; then
        printf '  ok   %-26s %s\n' "$1" "$2"
    else
        printf '  FAIL %-26s got=%s want=%s\n' "$1" "$2" "$3"
        fail=1
    fi
}
code() { curl -s -o /dev/null -w '%{http_code}' "$@" 2>/dev/null || true; }

echo "smoke: $BASE"
check "GET /health"          "$(code "$BASE/health")" 200
check "GET / (redirect)"     "$(code "$BASE/")" 307
check "GET /echo no token"   "$(code "$BASE/echo?message=hi")" 401
check "GET /echo bad token"  "$(code -H 'Authorization: Bearer wrong' "$BASE/echo?message=hi")" 403
check "GET /echo ok"         "$(curl -s -H "Authorization: Bearer $TOKEN" "$BASE/echo?message=hi" || true)" '{"message":"hi"}'

# MCP tools proxy back into the FastAPI routes over ASGITransport, so a 401 on that hop
# is invisible to the REST checks above -- that exact bug shipped once.
META='"_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28","io.modelcontextprotocol/clientCapabilities":{}}'
MCP=$(curl -s -X POST "$BASE/mcp/" \
    -H "Authorization: Bearer $TOKEN" \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json, text/event-stream' \
    -H 'MCP-Protocol-Version: 2026-07-28' \
    -H 'mcp-method: tools/call' \
    -H 'mcp-name: echo_echo_get' \
    -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{\"name\":\"echo_echo_get\",\"arguments\":{\"message\":\"smoke-ok\"},$META}}" || true)
case "$MCP" in
    *smoke-ok*) check "MCP tools/call" ok ok ;;
    *)          check "MCP tools/call" fail ok ;;
esac

exit "$fail"
