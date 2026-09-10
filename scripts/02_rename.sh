#!/usr/bin/env bash
# One-shot template rename: replaces the "python_dev"/"python-dev" project name
# everywhere it is hardcoded, regenerates uv.lock, then removes itself and its
# Makefile target. Run once, right after creating a repo from this template:
#
#   make rename NAME=my-project
set -euo pipefail

NEW="${1:-}"
if [[ -z "$NEW" ]]; then
    echo "usage: bash scripts/02_rename.sh <new-project-name>" >&2
    echo "       (lowercase; starts with a letter; letters, digits, - or _)" >&2
    exit 2
fi
if [[ ! "$NEW" =~ ^[a-z][a-z0-9_-]*$ ]]; then
    echo "error: invalid name '$NEW' — must match ^[a-z][a-z0-9_-]*$" >&2
    exit 2
fi

SNAKE="${NEW//-/_}"   # package-style name (pyproject [project].name)
KEBAB="${NEW//_/-}"   # display/image-style name (FastAPI title, MCP server, Docker tags)

cd "$(dirname "$0")/.."

FILES=(
    pyproject.toml
    docker-compose.yml
    .github/workflows/ci.yml
    src/main.py
    CLAUDE.md
)
for f in "${FILES[@]}"; do
    perl -pi -e "s/python_dev/${SNAKE}/g; s/python-dev/${KEBAB}/g" "$f"
done

# uv.lock records the (normalized) project name — regenerate it.
uv lock

# This script and its Makefile target are single-use: remove both.
perl -0pi -e 's/\n\.PHONY: rename\nrename:\n(\t.*\n)+//' Makefile
rm -- "$0"

cat <<DONE

Renamed to: ${KEBAB} (package name: ${SNAKE})

Manual follow-ups:
  - README.md : rewrite the title/description for your project and delete the
                "Using this template" section
  - LICENSE   : set your own copyright holder and year (or swap the license)
  - Then run  : make all

DONE
