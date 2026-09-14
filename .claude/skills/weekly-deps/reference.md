# Dependency policy and known report failure modes

Authoritative reference for the `weekly-deps` skill. It is also the single source of truth
for the audit routine's own prompt — the routine should read this file rather than carry its
own copy of the list.

## Standing decisions

These are settled. The weekly report keeps recommending against them; that is noise, not a
finding. Re-open one only by presenting evidence that changes its basis, and say explicitly
what changed.

| Decision | Rationale |
|---|---|
| `mypy` is pinned exactly (`==`), in lock-step with the `mirrors-mypy` pre-commit rev | A floor lets the hook and the dev dependency drift apart and disagree |
| CI uses `uv sync --locked` | It verifies the lockfile matches `pyproject.toml` and fails on drift. `--frozen` skips that check; `uv lock --check` is redundant with it |
| The Makefile calls `uv run <tool>`, never `uvx` | `uvx` resolves an unpinned version at call time, reintroducing the hook-vs-dependency mismatch |
| `ruff.toml` keeps an explicit `select` list | Changes to ruff's *default* rule set therefore cannot affect this repo — a recurring source of false "HIGH severity" alarms |
| Cyclomatic complexity capped at 10 (`C901`) | Documented in CLAUDE.md so it steers code as it is written, not only at lint time |
| No docs site, no Python version matrix, no copier/cookiecutter conversion | Deliberate scope limits for a minimal starter |

## Known failure modes of the report

Observed repeatedly. Check for each before trusting the report.

1. **Blind to transitive dependencies.** It audits direct dependencies only. This is how
   `cryptography` accumulated 7 CVEs unnoticed — it is a transitive of `fastmcp`, and
   targeted `uv lock --upgrade-package` never moves unnamed transitives. Always cross-check
   with `uv audit` and a full `uv lock --upgrade`.
2. **Hallucinated versions and features.** It has attributed features to releases that
   shipped years earlier (e.g. crediting a recent FastAPI version with webhooks and
   Swagger 5, both from 2023). Verify against PyPI and the actual release notes.
3. **Severity not calibrated to this repo.** It rated ruff's default-rule expansion as
   breaking, which cannot affect a config with an explicit `select`. Always check the
   relevant config before accepting a severity.
4. **Re-recommends against standing decisions.** Unpinning mypy, switching to `uvx`,
   `--frozen`, `uv lock --check` — all already settled above.
5. **Scope limited to Python packages.** It ignores pre-commit hook revs, GitHub Actions
   pins, the Dockerfile base image, and `uv` itself. Check those separately.

## Verification ritual

`uv sync --locked` → `make check` → `make cov` → `make smoke`. Anything touching the image or
compose additionally needs a container rebuild and the compose checks. Never report a check
as passing unless it actually ran.
