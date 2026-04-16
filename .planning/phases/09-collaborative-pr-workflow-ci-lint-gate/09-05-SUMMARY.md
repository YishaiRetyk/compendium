---
phase: 09-collaborative-pr-workflow-ci-lint-gate
plan: 05
subsystem: ci-integration
tags: [github-actions, ci, pr-template, agents-md, annotations, pattern-twin]

requires:
  - phase: 09-02
    provides: LINT_VERSION=1.1.0, --format json, --ci, --require-version flags on bin/lint.sh
  - phase: 09-03
    provides: --strict flag, --count-skips, contributor category, origin/main fallback on bin/lint.sh
  - phase: 09-04
    provides: bin/check-privacy.sh standalone guard, bin/ingest.sh --contributor flag, .git-author-map.txt
provides:
  - ".github/workflows/lint.yml: 3 parallel jobs (lint, privacy-leak, strict) wiring Plans 02/03/04 primitives into live CI gate (CI-01)"
  - ".github/scripts/json-to-annotations.py: JSON -> GitHub workflow-command shim with 10/10/50 annotation-cap handling (CI-05)"
  - ".github/pull_request_template.md: D-29 6-section PR template (COLAB-02)"
  - "AGENTS.md §11.1 step 9a: --contributor resolution order documented (COLAB-04 doc)"
  - "AGENTS.md §11.3 'CI mode (Phase 9)' subsection: source-of-truth designation + all 7 CI flags + escape-hatch marker contract + severity remap table"
  - "AGENTS.md §12 'Contributor inline field' subsection: contributor:: @handle as Dataview inline body field (COLAB-03)"
  - "CLAUDE.md byte-identical to AGENTS.md (Phase 7 pre-commit hook preserved)"
affects: [09-06]

tech-stack:
  added: []  # Zero new runtime deps
  patterns:
    - "Pattern-twin workflow file: lint.yml mirrors neutrality.yml + setup-parity.yml enforcement-model comment block (pull_request HARD GATE / push ADVISORY)"
    - "Three independent parallel jobs (no needs: edges) -- operator sets 3 required checks in branch protection (D-16 / D-17)"
    - "continue-on-error + step-outcome fail pattern: lint step captures exit code; annotation shim always runs; final step fails iff lint outcome was failure"
    - "Annotation cap handling: sort errors first (preserves critical findings under cap), emit trailing ::notice when dropped, avoid silent info loss"
    - "Source-of-truth designation in AGENTS.md §11.3: prevents spec duplication drift across docs/reference/ci.md / CONTRIBUTING.md / workflow comments (Codex MEDIUM review fix)"
    - "Escape-hatch marker adjacency load-bearing: marker on line N, claim on N+1; blank line invalidates (D-09)"

key-files:
  created:
    - ".github/workflows/lint.yml (84 lines) -- 3-job CI workflow"
    - ".github/scripts/json-to-annotations.py (87 lines) -- GitHub annotation shim"
    - ".github/pull_request_template.md (34 lines) -- D-29 6-section template"
    - "tests/phase-09/test_lint_workflow.sh (54 lines)"
    - "tests/phase-09/test_annotation_shim.sh (56 lines)"
    - "tests/phase-09/test_pr_template.sh (34 lines)"
    - "tests/phase-09/test_agents_section_11_1.sh (22 lines)"
    - "tests/phase-09/test_agents_section_11_3.sh (39 lines)"
    - "tests/phase-09/test_agents_section_12.sh (27 lines)"
  modified:
    - "AGENTS.md (+41 lines: §11.1 step 9a, §11.3 CI mode subsection, §12 contributor inline field subsection)"
    - "CLAUDE.md (+41 lines, byte-identical to AGENTS.md via bin/sync-claude.sh)"

key-decisions:
  - "lint.yml uses actions/checkout@v6 + actions/setup-python@v6 + pip install pyyaml uniformly across all 3 jobs for operator muscle memory with neutrality.yml + setup-parity.yml"
  - "strict job sets fetch-depth: 0 on checkout (D-10 / CI-06 requires origin/main...HEAD unified-diff) and if: github.event.pull_request.draft == false || github.event_name == 'push' (D-07 draft-skip)"
  - "privacy-leak job includes pip install pyyaml for uniformity even though bin/check-privacy.sh is regex-only; <2s overhead, keeps all 3 jobs identical scaffolding"
  - "annotation shim maps info -> ::notice (NOT ::info) -- ::info is not a valid GitHub workflow command (GitHub's lowest tier is 'notice')"
  - "Annotation cap: per-severity 10 error + 10 warning + 50 total per GitHub Docs 2026; errors sorted first so critical findings survive capping; dropped count emitted as trailing ::notice with 'more' token"
  - "Shim exits 1 with clear stderr (not Python traceback) on missing/invalid JSON -- keeps CI logs readable"
  - "PR template uses ../PRIVACY.md relative link (GitHub resolves PR-template relative links from repo root)"
  - "AGENTS.md §11.3 CI mode subsection opens with source-of-truth blockquote (Codex MEDIUM review fix) preventing spec duplication drift"
  - "Test awk section extractors use flag-based pattern (/^### 11\\.1 /{flag=1; next} /^### 11\\.[02-9]/{flag=0} flag) instead of range-pair (/start/,/end/) because range-pair collapses when start and end patterns both match the start line"

patterns-established:
  - "Pattern: Pattern-twin CI workflows -- new CI gates (lint.yml) clone structure of existing gates (neutrality.yml, setup-parity.yml) for operator muscle memory on GitHub branch-protection UI"
  - "Pattern: Annotation cap safety net -- always emit a summary ::notice on cap hit so PR reviewers know findings were dropped and can check workflow logs"
  - "Pattern: AGENTS.md source-of-truth designation -- authoritative-spec blockquote at the top of cross-cutting sections prevents documentation drift across CONTRIBUTING.md / docs/reference/*.md / workflow comments"

requirements-completed: [CI-01, CI-05, COLAB-02, COLAB-03]

duration: 6min
completed: 2026-04-16
---

# Phase 09 Plan 05: CI Workflow + AGENTS.md Amendments + PR Template Summary

**Wires Plans 02/03/04's primitives (bin/lint.sh --ci/--format/--strict + bin/check-privacy.sh) into a live 3-job GitHub Actions CI gate; ships the D-29 PR template; and canonicalizes Phase 9 schema decisions in AGENTS.md §§11.1/11.3/12 with CLAUDE.md byte-identical.**

## Performance

- **Duration:** ~6 min
- **Started:** 2026-04-16T08:09:34Z
- **Completed:** 2026-04-16T08:15:30Z
- **Tasks:** 3 (all `type="auto" tdd="true"`, all green first attempt after test-extractor fix)
- **Files created:** 9 (1 workflow, 1 shim, 1 PR template, 6 tests)
- **Files modified:** 2 (AGENTS.md, CLAUDE.md)

## Accomplishments

- **`.github/workflows/lint.yml`** ships with 3 parallel jobs:
  - `lint` — invokes `bash bin/lint.sh --require-version 1.1.0 --ci --format json > /tmp/lint.json` with `continue-on-error: true`, converts JSON to GitHub annotations via `.github/scripts/json-to-annotations.py`, then fails the step iff `steps.lint_run.outcome == 'failure'`. This maps Plan 02's CI severity remap into inline PR annotations while still blocking merge on error-severity findings.
  - `privacy-leak` — invokes `bash bin/check-privacy.sh` as a single step. Exit 2 blocks merge (CI-07).
  - `strict` — invokes `bash bin/lint.sh --require-version 1.1.0 --strict` with `fetch-depth: 0` on `actions/checkout@v6` (D-10: `--strict`'s `git diff --unified=0 origin/main...HEAD` parser needs full history) and `if: github.event.pull_request.draft == false || github.event_name == 'push'` (D-07: skip on draft PRs).
- **Header comment block** mirrors `neutrality.yml`/`setup-parity.yml` enforcement-model conventions: `pull_request` is the HARD GATE, `push` to `main` is ADVISORY, operator sets 3 required checks (`lint`, `privacy-leak`, `strict`) in branch protection.
- **`.github/scripts/json-to-annotations.py`** ships as a 87-line shim:
  - Maps `error → ::error`, `warning → ::warning`, `info → ::notice` (GitHub uses `notice` as lowest tier; `::info` is not a valid workflow command).
  - Applies `10 error + 10 warning + 50 total` annotation caps per GitHub Docs 2026; sorts errors first so critical findings survive capping; emits trailing `::notice` with dropped count and "more" token when cap is exceeded.
  - Escapes `%`, `\r`, `\n` per GitHub Actions workflow-command convention (`%25`, `%0D`, `%0A`).
  - Clean stderr error path on missing file / invalid JSON / non-array root — no Python traceback leaks into CI logs.
  - Category prefix added to message: `[skip-count] exempted` (reviewer context).
- **`.github/pull_request_template.md`** ships with D-29 6-section structure: Summary, Ingest type (6 checkboxes), Source attribution, Privacy review (single checkbox + PRIVACY.md link), Lint (collapsible `<details>` block), Expected findings (escape-hatch marker pointer). Terse/mechanical tone per D-30; no governance/CoC noise.
- **AGENTS.md §11.1** gains **step 9a** documenting `bin/ingest.sh --contributor` resolution order: explicit flag > single-author omit > `.git-author-map.txt` lookup > map-miss warn-and-omit. Explicit "NEVER write a bare email into the `contributor::` field" rule. Git commit authorship remains the attribution source of truth.
- **AGENTS.md §11.3** gains the **"CI mode (Phase 9)" subsection**:
  - Opens with a **source-of-truth designation blockquote** (Codex MEDIUM review fix): "This section is the authoritative specification for: (a) the severity-remap dispatch table, (b) the `--format json` output schema, (c) the escape-hatch marker contract, and (d) the `--require-version` semantics. Other docs (`docs/reference/ci.md`, `CONTRIBUTING.md`, `.github/workflows/lint.yml` comments) MUST link here rather than restating the policy."
  - Documents all 7 CI flags in a table: `--format json`, `--ci`, `--skip-category`, `--strict`, `--require-version`, `--version`, `--count-skips`.
  - Documents escape-hatch marker syntax with the 4 strictness rules (immediately-above adjacency + id-match + non-empty reason + skip-count info emission).
  - References `.github/workflows/lint.yml` with its 3 required-check names.
- **AGENTS.md §12** gains the **"Contributor inline field (COLAB-03, Phase 9)" subsection** immediately before §13: `contributor:: @github-handle` is a Dataview **inline body field** (NOT frontmatter per §3 prohibition). Handle format `@github-handle`; `bin/search.sh` accepts bare form. Single-author repos omit the field entirely. Git commit authorship is the attribution source of truth. `.git-author-map.txt` format documented. Includes a Dataview query example.
- **CLAUDE.md** byte-identical to AGENTS.md via `bash bin/sync-claude.sh`; Phase 7 pre-commit hook invariant preserved (`bash bin/sync-claude.sh --check` exits 0).

## Task Commits

Each task followed TDD (RED → GREEN):

1. **Task 1 RED: failing tests for lint.yml + annotation shim** — `61f85fd` (test)
2. **Task 1 GREEN: lint.yml workflow + json-to-annotations.py shim** — `8dded72` (feat)
3. **Task 2 RED: failing test for PR template** — `ad062a9` (test)
4. **Task 2 GREEN: PR template** — `a92bf60` (feat)
5. **Task 3 RED: failing tests for AGENTS.md §§11.1/11.3/12** — `c3e936d` (test)
6. **Task 3 GREEN: AGENTS.md amendments + CLAUDE.md sync + test-extractor fix** — `a9f99d4` (feat)

## Files Created/Modified

### Created
- `.github/workflows/lint.yml` (84 lines) — 3-job CI workflow with enforcement-model comment block
- `.github/scripts/json-to-annotations.py` (87 lines, executable) — GitHub annotation shim
- `.github/pull_request_template.md` (34 lines) — D-29 6-section template
- `tests/phase-09/test_lint_workflow.sh` (54 lines, executable) — YAML structure + enforcement-model assertion
- `tests/phase-09/test_annotation_shim.sh` (56 lines, executable) — severity mapping + cap + missing-file error path
- `tests/phase-09/test_pr_template.sh` (34 lines, executable) — 6-section + 6-checkbox + PRIVACY.md link + details block + lint:expect-inferred pointer
- `tests/phase-09/test_agents_section_11_1.sh` (22 lines, executable) — §11.1 --contributor documentation
- `tests/phase-09/test_agents_section_11_3.sh` (39 lines, executable) — §11.3 CI mode subsection complete
- `tests/phase-09/test_agents_section_12.sh` (27 lines, executable) — §12 contributor:: inline field + CLAUDE.md sync check

### Modified
- `AGENTS.md` (+41 lines across 3 edits): step 9a in §11.1, "CI mode (Phase 9)" subsection in §11.3, "Contributor inline field" subsection in §12
- `CLAUDE.md` (+41 lines, byte-identical to AGENTS.md via `bin/sync-claude.sh`)

## Workflow YAML Final Structure

```yaml
name: Lint + Privacy + Strict
on:
  pull_request:
  push:
    branches: [main]
jobs:
  lint:        # ubuntu-latest, v6 actions, bin/lint.sh --ci --format json + shim + fail-on-lint-outcome
  privacy-leak: # ubuntu-latest, v6 actions, bin/check-privacy.sh
  strict:      # ubuntu-latest, fetch-depth: 0, draft-skip if, bin/lint.sh --strict
```

Enforcement model: `pull_request` = HARD GATE, `push` to main = ADVISORY. Operator sets 3 branch-protection required checks.

## Annotation Shim Severity Mapping

| lint.sh severity | Workflow command | Rationale |
|------------------|------------------|-----------|
| `error` | `::error` | Blocks merge via workflow step exit 1 |
| `warning` | `::warning` | Yellow in PR UI, informational |
| `info` | `::notice` | Lowest GitHub tier (NOT `::info`) |

Cap strategy (GitHub 2026 limits: 10 error + 10 warning + 50 total): sort errors first → emit up to cap → count dropped → trailing `::notice` with dropped count + "see workflow logs" pointer.

## PR Template Final Section List

1. `## Summary`
2. `## Ingest type` (6 checkboxes: new source / update existing page / merge pages / supersede page / docs-only / other)
3. `## Source attribution`
4. `## Privacy review` (single checkbox + `[PRIVACY.md](../PRIVACY.md)` link)
5. `## Lint` (checkbox + `<details><summary>lint output</summary>...</details>` collapsible block)
6. `## Expected findings (optional)` (HTML comment pointing to `lint:expect-inferred` escape-hatch marker docs in `docs/reference/ci.md`)

## AGENTS.md Amendment Locations (post-edit line numbers)

- **§11.1 (Ingest Workflow):** step 9a added at lines 1199–1204 (after step 9, before commit step 10).
- **§11.3 (Lint Workflow):** "CI mode (Phase 9)" subsection added at lines 1348–1378 (after Auto-Fix Boundary paragraph, before **Steps:**).
- **§12 (Index and Log):** "Contributor inline field (COLAB-03, Phase 9)" subsection added at lines 1555–1582 (after structured-operation examples, before §13 Privacy Routing).
- **Net:** +41 lines; AGENTS.md grew from 1718 → 1759 lines; CLAUDE.md synced to match.

## CLAUDE.md Sync Confirmation

```
$ bash bin/sync-claude.sh --check
OK: AGENTS.md == CLAUDE.md
```

Phase 7 `.githooks/pre-commit` hook invariant preserved. Any drift would auto-sync on next commit.

## Decisions Made

- **Pattern-twin workflow file** (copy enforcement-model block from `neutrality.yml`): operators who set up `neutrality` branch protection already know the pattern — `lint`, `privacy-leak`, `strict` are just 3 more required checks in the same UI.
- **`info → ::notice`** (not `::info`): GitHub's workflow-command set only has 3 severity levels (`error`, `warning`, `notice`). Emitting `::info` would be silently ignored or rendered as plain log text. Verified against GitHub Docs 2026.
- **Annotation cap handled in Python, not YAML**: Putting the cap logic in the shim keeps the workflow YAML short and makes cap-handling testable (test case 4 in `test_annotation_shim.sh` asserts `≤ 10 ::error` on 15-error input plus trailing "more" notice).
- **Sort errors first, warnings next, info last**: Under the 10/10/50 cap, this guarantees error-severity findings are visible in the PR UI even if warning/info-severity findings are dropped.
- **Three parallel jobs, no `needs:` edges** (D-16): Fast feedback — all 3 run concurrently on ubuntu-latest. A failing `lint` job does not block `strict` or `privacy-leak` from running.
- **`fetch-depth: 0` on strict job only** (D-10): `--strict`'s unified-diff parser requires full history for `origin/main...HEAD`. The `lint` and `privacy-leak` jobs work on the working tree only, so default shallow clone is fine.
- **Uniform `pip install pyyaml` across all 3 jobs**: Consistency with Phase 7/8 baseline. Cost is ~2s per job. Keeps the scaffold copy-paste-able.
- **PR-template `../PRIVACY.md` relative link**: GitHub renders PR-template relative links from repo root (tested pattern). The `../` indicates "one level up from `.github/`" which resolves to the repo-root `PRIVACY.md`.
- **Source-of-truth designation in §11.3** (Codex MEDIUM review fix): Without this, the severity policy would likely be copy-pasted into `docs/reference/ci.md` + `CONTRIBUTING.md` + workflow comments, each version drifting separately. The blockquote makes AGENTS.md §11.3 the canonical spec and instructs Plan 06 to link rather than restate.
- **Flag-based awk section extraction in test_agents_section_*.sh**: The original plan used `awk '/^### 11\.1/,/^### 11\.[0-9]/'` range syntax, but awk ranges collapse to one line when the start regex is a subset of the end regex (both match `### 11.1`). Rewrote to `/^### 11\.1 /{flag=1; next} /^### 11\.[02-9]/{flag=0} flag` — the extra space after the section number + the excluded `1` in the end class ensures the flag turns on immediately after the section header and turns off at the next sibling section.

## Deviations from Plan

**1. [Rule 1 — Bug] Fix awk section-extraction in test_agents_section_11_1.sh + test_agents_section_11_3.sh.**

The plan's test spec used `awk '/^### 11\.1/,/^### 11\.[0-9]/' "$A" | head -n -1`. The range-pair `(start, end)` collapses to one line because `^### 11\.[0-9]` matches the start line `### 11.1` immediately — awk emits the start line and exits the range on the same line. Result: `SECTION` contained only the section header, and the subsequent `grep` assertions all failed even though the amendments were correctly applied to AGENTS.md.

Fix: switch to flag-based extraction:
- `/^### 11\.1 /{flag=1; next} /^### 11\.[02-9]/{flag=0} flag` for §11.1
- `/^### 11\.3 /{flag=1; next} /^### 11\.[0-24-9]/{flag=0} flag` for §11.3

The trailing space in the start regex (`11\.1 `) and the excluded digit class in the end regex (`[02-9]`) ensure the flag turns on strictly after the section header line and turns off at the next sibling `### 11.N` header where N is not 1/3. Applied in commit `a9f99d4` alongside the AGENTS.md amendments.

No deviation in behavior contract — the fix only adjusts test extraction logic; the assertions themselves (grep for `--contributor`, `contributor::`, `.git-author-map.txt`, etc.) are unchanged and verify exactly what the plan's `<acceptance_criteria>` requires.

## Issues Encountered

**1. awk range collapsing:** described above. Caught on first run of `test_agents_section_11_1.sh` after AGENTS.md edit; fixed by rewriting the extractor.

**2. Nothing else.** The PR template test, lint.yml test, and annotation shim test all passed first-try after GREEN implementation. PyYAML is a pre-existing dep on the test environment so no install needed for local runs.

## Verification Results

All 6 new tests pass:

```
PASS: workflow YAML structure valid
PASS: lint.yml structure + enforcement-model comment
PASS: annotation shim (error/warning/notice mapping + cap + error handling)
PASS: PR template 6-section structure
PASS: AGENTS.md §11.1 documents --contributor flow
PASS: AGENTS.md §11.3 CI-mode subsection complete
OK: AGENTS.md == CLAUDE.md
PASS: AGENTS.md §12 + CLAUDE.md sync
```

Full Phase 9 suite:

```
PHASE 09 TESTS: 25/25
```

Phase regressions (all green):

```
PHASE 07 TESTS: 22/22
PHASE 08 TESTS: 21/21
```

CLAUDE.md sync invariant:

```
$ bash bin/sync-claude.sh --check
OK: AGENTS.md == CLAUDE.md
```

## Known Stubs

None — all deliverables fully populated. The workflow YAML invokes real scripts; the annotation shim has complete error handling; the PR template has substantive checklist content; AGENTS.md amendments cover all required surface. `docs/reference/ci.md` and `CONTRIBUTING.md` are Plan 06's scope and explicitly out of scope for this plan (the AGENTS.md §11.3 blockquote tells Plan 06 to link rather than restate).

## Self-Check: PASSED

All created files exist:
- `.github/workflows/lint.yml` — FOUND (3 jobs: lint, privacy-leak, strict)
- `.github/scripts/json-to-annotations.py` — FOUND (executable)
- `.github/pull_request_template.md` — FOUND
- `tests/phase-09/test_lint_workflow.sh` — FOUND (executable)
- `tests/phase-09/test_annotation_shim.sh` — FOUND (executable)
- `tests/phase-09/test_pr_template.sh` — FOUND (executable)
- `tests/phase-09/test_agents_section_11_1.sh` — FOUND (executable)
- `tests/phase-09/test_agents_section_11_3.sh` — FOUND (executable)
- `tests/phase-09/test_agents_section_12.sh` — FOUND (executable)

Files modified verified:
- `AGENTS.md` — FOUND (contains step 9a, "CI mode (Phase 9)" subsection, "Contributor inline field" subsection)
- `CLAUDE.md` — FOUND (byte-identical to AGENTS.md)

Commits verified in git log:
- `61f85fd` — FOUND (Task 1 RED: failing tests for lint.yml + annotation shim)
- `8dded72` — FOUND (Task 1 GREEN: lint.yml workflow + shim)
- `ad062a9` — FOUND (Task 2 RED: failing test for PR template)
- `a92bf60` — FOUND (Task 2 GREEN: PR template)
- `c3e936d` — FOUND (Task 3 RED: failing tests for AGENTS.md amendments)
- `a9f99d4` — FOUND (Task 3 GREEN: AGENTS.md amendments + CLAUDE.md sync + awk fix)

## Next Phase Readiness

### Ready for Plan 09-06 (CONTRIBUTING.md + docs/reference/ci.md)

- AGENTS.md §11.3's source-of-truth blockquote tells Plan 06 to **link** to §11.3 for severity policy / JSON schema / escape-hatch contract / `--require-version` semantics, **not restate** them. This prevents the documentation drift Codex MEDIUM called out.
- `.github/workflows/lint.yml`'s header comment already references `docs/reference/ci.md` — Plan 06 populates that file.
- PR template escape-hatch comment points contributors to `docs/reference/ci.md (section: escape-hatch markers)` — Plan 06 writes that section.
- CONTRIBUTING.md (Plan 06 scope) can reference all four contributor primitives: `bin/ingest.sh --contributor`, `bin/search.sh --contributor`, `.git-author-map.txt` format, and the `contributor::` inline-body-field convention documented in AGENTS.md §12.

### When the operator pushes to the public repo

- Opening a PR fires three jobs (`lint`, `privacy-leak`, `strict`) in parallel on `ubuntu-latest`.
- Lint findings surface as inline `::error` / `::warning` / `::notice` annotations in the PR UI via the JSON-to-annotations shim.
- Privacy-leak attempts (local_only frontmatter in public paths) fail the PR.
- Strict ratchet catches unmatched `[inferred]` claims and new-page-without-provenance.
- The PR body auto-populates with D-29's 6-section checklist for the contributor to fill out.
- Operator sets 3 required checks (`lint`, `privacy-leak`, `strict`) in branch-protection UI — one-time action, same pattern as existing `neutrality` + `setup-parity` checks.

### No blockers or concerns.

---
*Phase: 09-collaborative-pr-workflow-ci-lint-gate*
*Plan: 05 (ci-workflow-agents-amendments-pr-template)*
*Completed: 2026-04-16*
