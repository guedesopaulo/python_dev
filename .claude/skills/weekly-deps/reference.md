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
| Security linting comes from ruff's `S` (flake8-bandit) selector; the standalone bandit hook was removed | One fewer tool to version, same class of checks. Verified empirically: `S` finds only `S101` in tests, which is relaxed there |
| No image publishing / release workflow (GHCR was considered and declined) | Deploy and registry conventions differ per company; a template that bakes in ours gets in the way more than it helps |
| Trivy blocks on **library** CVEs and only reports **OS** ones | OS CVEs come from the base image and are fixed by bumping `FROM`, not by the PR at hand. Blocking on them turns unrelated PRs red whenever Debian publishes an advisory |
| Dependabot is security-only (`open-pull-requests-limit: 0`) with a 7-day cooldown | Routine version bumps belong to this weekly routine. Cooldown guards version updates only — security fixes are never delayed by it |
| Dependabot security PRs are grouped per ecosystem (`applies-to: security-updates`), and CI re-runs weekly on `main` | Per-package PRs deadlock against the whole-lockfile audit gate, and without a scheduled run `main` stays green while advisories pile up. Both together let 103 CVEs and 17 red PRs accumulate unnoticed for two months (cleared in #45) |
| hadolint runs in CI, and shellcheck uses `shellcheck-py` | Both upstream pre-commit hooks shell out to Docker, which would break `make check` on any machine without a running daemon |
| GitHub Actions are pinned by version tag, not commit SHA, for trusted publishers, but **only when the tag is an immutable GitHub release**; otherwise hash-pin (today: `actions/checkout`) | Readability over hash churn. A tag is only as safe as it is immovable: in March 2026 an attacker rewrote 76 of 77 `trivy-action` tags (GHSA-69fq-xp46-6x23), and only the immutable release survived. SHA-pinning every action adds churn without protection once the release is immutable. `.github/zizmor.yml` enforces hash-pinning for publishers outside the allow-list and for `actions/checkout` |

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
   pins, the Dockerfile base image, and `uv` itself. Check those separately — see the
   inventory below.

## Tooling inventory to check for drift

Beyond `pyproject.toml`, these carry pinned versions that go stale silently:

- **pre-commit hooks** (`.pre-commit-config.yaml`): pre-commit-hooks, ruff-pre-commit,
  mirrors-mypy, uv-pre-commit, typos, shellcheck-py, zizmor-pre-commit, plus a local `deptry` hook.
- **GitHub Actions** (`.github/workflows/ci.yml`): actions/checkout, astral-sh/setup-uv,
  docker/setup-buildx-action, docker/build-push-action, hadolint/hadolint-action,
  aquasecurity/trivy-action. Verify a tag actually exists before proposing it — a
  non-existent ref fails the whole job at setup (this has happened). Also check it is an
  immutable release: `gh api repos/<owner>/<repo>/releases/tags/<tag> --jq .immutable`.
  Publishers decide this per release, so check on every bump. If it is `false`, propose a
  hash pin with the version as a trailing comment (`@<sha> # vX.Y.Z`) and a matching
  `hash-pin` entry in `.github/zizmor.yml`.
- **uv itself**, pinned in three places that must agree: the `setup-uv` step in CI, the
  `COPY --from=ghcr.io/astral-sh/uv` line in the Dockerfile, and the `uv-pre-commit` rev.
- **Dockerfile base image** (`python:3.13-slim-bookworm`) — the fix for OS-level CVEs.

## Verification ritual

`uv sync --locked` → `make check` → `make cov` → `make audit` → `make smoke`. Anything touching the image or
compose additionally needs a container rebuild and the compose checks. Never report a check
as passing unless it actually ran.
