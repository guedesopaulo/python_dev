#!/usr/bin/env bash
# PreToolUse hook: refuse to touch the real .env (.env.example is fine).
set -euo pipefail

TARGET=$(cat \
    | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' \
    2>/dev/null || echo "")

case "$TARGET" in
    *.env|*/.env)
        echo ".env is off limits - it holds real credentials. Use .env.example instead." >&2
        exit 2
        ;;
esac
exit 0
