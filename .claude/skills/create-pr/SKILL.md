---
name: create-pr
description: Prepare a branch name, commit message and PR title/description for the current
  changes, following this repo's conventions. Pass --apply to actually create the branch,
  commit, push and open the PR via gh.
argument-hint: [--apply]
allowed-tools: Bash(git *) Bash(gh *) Bash(make *) Bash(uv run *)
---

## Steps

1. Run `git status --porcelain`. If clean, say so and stop — there is nothing to open a PR for.
2. Run the verification ritual: `make check`, `make cov`, `make smoke`. If any of them fails,
   stop and report the failure — never draft a PR for code that does not pass.
3. Derive a branch name `<type>/<short-kebab-description>` and a PR title
   `type: imperative summary`, using conventional-commit types (feat, fix, chore, docs,
   refactor) based on what the diff actually does.
4. Draft the PR description:
   - a short "why" **only** if it is not obvious from the title;
   - bullets of what changed;
   - a `Verified` section listing only the checks actually run in step 2 — never claim a
     check that did not run in this invocation.
5. **Default (no `--apply`)**: print the branch name, title and description as text. Do not
   touch git — the repo owner runs the git commands.
6. **With `--apply`**: create the branch, review `git status` before staging (never a blind
   `git add -A`), commit (title as the first line, description as the body), push, then
   `gh pr create` with that title and body. Print the resulting PR URL.
7. Do not append a tool-attribution footer to the PR description — no "Generated with ..."
   line, no co-author trailer in the PR body.

## Conventions in this repo

- Everything written into the repo is in English, including PR titles and descriptions.
- Keep the description factual and skimmable; no invented benefits, no filler sections.
