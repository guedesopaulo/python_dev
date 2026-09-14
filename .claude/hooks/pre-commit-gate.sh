#!/usr/bin/env bash
# Stop hook: don't let a Claude Code turn end with a broken pre-commit run.
# Ships with this template so every project cloned from it inherits the guardrail.
set -euo pipefail
cd "${CLAUDE_PROJECT_DIR:-$(pwd)}"

INPUT="$(cat)"

# Required: a blocking Stop hook MUST honour stop_hook_active, or it re-blocks its own
# block forever. https://github.com/anthropics/claude-code/issues/55754
ACTIVE=$(printf '%s' "$INPUT" \
    | python3 -c 'import json,sys; print(json.load(sys.stdin).get("stop_hook_active", False))' \
    2>/dev/null || echo False)
[ "$ACTIVE" = "True" ] && exit 0

# Check exactly what this turn touched: tracked changes plus new files. `--all-files`
# would skip untracked ones, which is precisely the common case (a brand-new module).
CHANGED=$(
    { git diff --name-only HEAD 2>/dev/null
      git ls-files --others --exclude-standard 2>/dev/null
    } | sort -u | while read -r f; do [ -f "$f" ] && printf '%s\n' "$f"; done
)
[ -z "$CHANGED" ] && exit 0

if ! OUTPUT=$(echo "$CHANGED" | xargs uv run pre-commit run --files 2>&1); then
    echo "pre-commit failed on this turn's changes - fix the issues below, then finish:" >&2
    echo "$OUTPUT" | grep -vE '^\s*$' | tail -n 60 >&2
    exit 2
fi
exit 0
