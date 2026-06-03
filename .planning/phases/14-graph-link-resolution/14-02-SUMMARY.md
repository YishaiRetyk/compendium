---
phase: 14-graph-link-resolution
plan: "02"
subsystem: bin/lint.sh
tags:
  - lint
  - linkres
  - link-resolution
  - obsidian
  - self-alias
  - tdd
  - graph-integrity
dependency_graph:
  requires:
    - 14-01-PLAN.md  # CLAUDE.md §11.3 linkres entry in source-of-truth table (same wave)
  provides:
    - bin/lint.sh linkres category (LINK-04, LINK-05)
    - bin/lint.sh --fix self-alias backfill (LINK-06)
    - LINT_VERSION 1.5.0
    - 11-case test suite (test_lint_linkres.sh)
  affects:
    - 14-03-PLAN.md  # data remediation uses linkres to measure progress
tech_stack:
  added: []
  patterns:
    - TDD (RED -> GREEN)
    - defensive variable initialization (obsidian_map build guard)
    - YAML-double-quoting for colon-safe alias emission
    - literal membership vs stem-reachability distinction (LINK-02)
key_files:
  created:
    - tests/phase-09/test_lint_linkres.sh
  modified:
    - bin/lint.sh
    - tests/phase-09/test_lint_require_version.sh
    - tests/phase-09/test_lint_version.sh
    - tests/phase-09/test_lint_strict_dr_match.sh
    - tests/phase-09/test_lint_strict_escape_hatch.sh
    - tests/phase-09/fixtures/strict-missing-dr/wiki/concepts/attention.md
    - tests/phase-09/fixtures/strict-missing-dr/wiki/sources/src-2026-04-16-test.md
    - tests/phase-09/fixtures/strict-escape-hatch/wiki/concepts/attention.md
    - tests/phase-09/fixtures/strict-escape-hatch/wiki/sources/src-2026-04-16-test.md
    - docs/reference/ci.md
decisions:
  - "LINK-02 literal membership enforcement is CI-enforced (not just --fix-healed): pages with id==filename-stem still get a linkres error if the literal id alias is absent (Cycle-3 MEDIUM ruling). This aligns the error predicate and --fix to_add to use identical criteria."
  - "obsidian_map (stem+alias only) replaces the old resolution_map (which included title) in both the orphan block (Change 5) and the gap block (reuse guard). This stops the orphan check from masking title-unreachable pages (D-03)."
  - "Defensive obsidian_map build inside the linkres block (if 'obsidian_map' not in dir():) mirrors the gap block's guard, fixing NameError under --category linkres (HIGH BUG #1)."
  - "_yaml_quote_alias YAML-double-quotes every emitted alias value so colon-containing titles parse as YAML strings not dicts (HIGH BUG #2). Re-emitting existing aliases with quoting is idempotent and repairs any prior unquoted entries."
  - "Fixture pages in strict-missing-dr and strict-escape-hatch gained self-aliases (Rule 1 auto-fix) because --strict runs all categories including the new linkres, and these fixtures predated the LINK-02 invariant."
metrics:
  duration: "~45min"
  completed_date: "2026-06-03"
  tasks: 2
  files_changed: 10
---

# Phase 14 Plan 02: Linkres Lint Category + --fix Self-Alias Backfill Summary

**One-liner:** `linkres` CI-gating category in `bin/lint.sh` (LINT_VERSION 1.5.0) enforces LINK-02 literal self-alias invariant, flags normalized-match body links, and `--fix` YAML-double-quotes backfilled aliases to handle colon-titled pages.

## What Was Built

Added the `linkres` lint category to `bin/lint.sh` with two subchecks:

**Subcheck A (LINK-04, LINK-06):** Every page's `aliases` list must contain its `title` AND `id` slug as LITERAL members. This is a HARD CI error — not just a `--fix`-healed deviation — even when the id equals the filename stem (Obsidian would resolve by stem, but LINK-02 mandates the explicit alias). `--fix` backfills missing title/id aliases using YAML-double-quoted values so colon-bearing titles (e.g. `SC1 Reframing: examples/...`) parse as YAML strings, not dicts.

**Subcheck B (LINK-05):** Body links that don't resolve via Obsidian's stem+alias rules are checked against a normalized map (`normalize_link`: casefold + strip punct-as-chars + plural map). Unique match → `error`; multiple matches → `warning`; no match → silent (stays in `gap`).

**Body link scan coverage:** Both `wiki/index.md` and `wiki/log.md` are scanned for body links (they're excluded from `all_pages` frontmatter scan but must not be blind spots for LINK-05).

**Reconciled orphan/gap resolution (D-03):** The `orphan` block's `resolution_map` is now `obsidian_map` (stem+alias only, title excluded), matching actual Obsidian resolution. Previously, the orphan check resolved `[[My Concept]]` via the `title` field, masking that the page was truly unreachable. After `--fix` adds the title alias, the orphan check correctly sees the page as reachable.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Updated test_lint_version.sh from 1.4.0 to 1.5.0**
- **Found during:** Task 2 (full Phase 09 test suite run)
- **Issue:** `test_lint_version.sh` hardcoded `1.4.0` but LINT_VERSION bumped to `1.5.0`
- **Fix:** Updated the assertion to expect `1.5.0`
- **Files modified:** `tests/phase-09/test_lint_version.sh`
- **Commit:** d1edb27

**2. [Rule 1 - Bug] Added self-aliases to strict fixture pages for LINK-02 compliance**
- **Found during:** Task 2 (full Phase 09 test suite run revealed `test_lint_strict_dr_match.sh` + `test_lint_strict_escape_hatch.sh` failing)
- **Issue:** `--strict` runs all lint categories including the new `linkres`. The pre-existing fixture pages (`strict-missing-dr/wiki/concepts/attention.md`, `strict-missing-dr/wiki/sources/src-2026-04-16-test.md`, `strict-escape-hatch/wiki/concepts/attention.md`, `strict-escape-hatch/wiki/sources/src-2026-04-16-test.md`) had `aliases: []` and predated the LINK-02 literal-membership invariant. The new linkres check fired `error` findings, causing `--strict` to exit 1 on the "should pass with matching DR" branch.
- **Fix:** Added proper self-aliases (title + id slug) to all four fixture files. Also updated the dynamically created DR page in `test_lint_strict_dr_match.sh` to include self-aliases.
- **Files modified:** 4 fixture files + `test_lint_strict_dr_match.sh`
- **Commit:** d1edb27

**3. [Rule 3 - Blocking] Fixed source fixture aliases in test_lint_linkres.sh Test 7**
- **Found during:** First GREEN run of `test_lint_linkres.sh`
- **Issue:** Test 7's source summary page had `aliases: ["Src Test 01", "src-test-01"]` but title "Source Test 01" — the title literal was missing, causing a linkres error on the "should stay green" page.
- **Fix:** Changed the alias to `"Source Test 01"` (exact title match) in both the main wiki source fixture and the strict-wiki source fixture within the test.
- **Files modified:** `tests/phase-09/test_lint_linkres.sh`
- **Commit:** d1edb27 (folded into the GREEN commit)

## TDD Gate Compliance

- **RED commit:** `02b1ef9` — `test(14-02): add failing test for linkres lint category (11 cases, RED)`
- **GREEN commit:** `d1edb27` — `feat(14-02): add linkres lint category + --fix self-alias backfill (LINT_VERSION 1.5.0)`

RED gate: test_lint_linkres.sh exited 1 with `AssertionError: FAIL T1: expected >=2 title-unreachable errors, got 0` (linkres category not yet implemented).
GREEN gate: all 11 test cases pass, full Phase 09 suite 30/30.

## Commits

| Hash | Message |
|------|---------|
| 02b1ef9 | test(14-02): add failing test for linkres lint category (11 cases, RED) |
| d1edb27 | feat(14-02): add linkres lint category + --fix self-alias backfill (LINT_VERSION 1.5.0) |

## Known Stubs

None. The linkres category is fully implemented with real lint output. No mock data or placeholder logic.

## Threat Flags

None found. The `--fix` write path is scoped to frontmatter section only (via `fm_end = content.find('\n---', 3)` and `ALIASES_RE count=1`), and all alias values are YAML-double-quoted to prevent injection via colon/bracket characters.

## Self-Check: PASSED

- `tests/phase-09/test_lint_linkres.sh` exists at expected path: FOUND
- `bin/lint.sh` has `_yaml_quote_alias`, `obsidian_map not in dir`, `linkres: error` in remap: FOUND
- Commit 02b1ef9 exists: FOUND
- Commit d1edb27 exists: FOUND
- Full Phase 09 suite: 30/30 PASS
