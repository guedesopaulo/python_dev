---
name: weekly-deps
description: Process the weekly dependency-audit report that the scheduled Claude routine
  committed under reports/ — verify its claims, apply the safe updates, and prepare the PR.
argument-hint: [path/to/reports/updates-YYYY-MM-DD.md]
allowed-tools: Bash(git *) Bash(uv *) Bash(make *) Bash(gh *)
---

## What this routine is

A scheduled Claude Code routine audits this repository once a week: it checks dependency
versions, security advisories and ecosystem practices, then opens a PR adding an advisory
report at `reports/updates-<YYYY-MM-DD>.md`. That PR changes nothing else — the report is
advisory only, and applying it is a separate, deliberate step. This skill is that step.

The report is **frequently wrong** in specific, recurring ways. Read
[reference.md](reference.md) before acting on it: it lists this repo's standing decisions
(which the report keeps recommending against) and the report's known failure modes.

## Steps

1. Read the report — the path in `$0` if given, otherwise the newest file in `reports/`.
2. Read `reference.md` in this skill directory and treat it as authoritative. Anything in
   the report that contradicts a standing decision is noise unless the report presents new
   evidence that changes the decision's basis; say so explicitly rather than re-litigating.
3. **Verify every claim before acting.** Latest versions come from
   `https://pypi.org/pypi/<package>/json`, not from the report's prose. Breaking-change and
   security claims need the actual release notes for the exact version range.
4. Establish ground truth locally, which also covers transitive dependencies the report may
   have missed: `uv audit --locked --preview-features audit-command`, and a full
   `uv lock --upgrade` to see everything that actually moves.
5. Apply what is safe. Prefer a full `uv lock --upgrade` over targeted `--upgrade-package`:
   the targeted form does not move unnamed transitives, which is how 11 CVEs once
   accumulated unnoticed.
6. Verify: `uv sync --locked`, `make check`, `make cov`, `make smoke`. For anything touching
   the image or compose, also rebuild and re-run the container checks.
7. Report back: what was applied, what was deliberately skipped and why, plus any claim in
   the report that turned out to be wrong. Then hand over the branch name, PR title and PR
   description (or invoke the `create-pr` skill).
