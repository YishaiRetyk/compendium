---
quick_id: 260602-d6a
slug: a1-lexical-dedup-lint-category
title: "a1 lexical near-duplicate page detection — `duplicate` lint category"
completed: 2026-06-02
mode: quick
status: complete
---

# Quick Task 260602-d6a Summary: `duplicate` lexical near-duplicate-page lint category

Added a dependency-free, report-only `duplicate` lint category to `bin/lint.sh`
that flags same-`type` page pairs whose titles/aliases are lexical near-duplicates
(substring containment OR Levenshtein < 3), surfacing them as `warning`-severity
MERGE candidates (§9, human-confirmed — never auto-merges). Bumped `LINT_VERSION`
1.3.0 → 1.4.0 and registered the category across all four mirror surfaces.

## What shipped

**Task 1 — the check (`bin/lint.sh`):**
- New `should_run('duplicate')` block in the single python3 block, placed after
  the `gap` check and before the `drift` check.
- Pure-stdlib `_levenshtein()` helper (two-row DP, no new imports/deps).
- Self-contained candidate inventory + inbound-wikilink graph (the orphan check's
  `resolution_map`/`inbound_links` are scoped to `should_run('orphan')`, so the
  duplicate check rebuilds its own — works even when run with `--category duplicate`).
- Candidate iff **same type** AND EITHER: title/alias substring containment
  (contained length > 5, case-insensitive) OR `levenshtein(a, b) < 3` for strings
  longer than 5 chars.
- Survivor = page with MORE inbound wikilinks; tie → lexicographically-first id.
  One finding per pair (sorted `(id_a, id_b)` pair-key dedup). Severity `warning`,
  category `duplicate`, report-only (no `--fix`, no mutation, no auto-merge).
- Excludes `EXCLUDE_DIRS`/`examples/`, `example: true`, and archived/superseded
  pages.

**Task 2 — registration + version (`bin/lint.sh`, `AGENTS.md`, `CLAUDE.md`,
`schema/AGENTS.template.md`, `docs/reference/ci.md`):**
- `LINT_VERSION` 1.3.0 → 1.4.0; `duplicate` added to `--category` help text.
- Deliberately left OUT of `CI_SEVERITY_REMAP` so it falls through to its original
  `warning` severity (non-blocking in `--ci`).
- `AGENTS.md §11.3`: new step 11 (the duplicate check) + `duplicate` added to the
  Categories valid-values list; subsequent steps renumbered (drift 11→12,
  compile/log/commit 12/13/14 → 13/14/15). DRFT-04 source comment in `lint.sh`
  updated to reference "step 12".
- `CLAUDE.md` synced byte-equal via `bin/sync-claude.sh`.
- `schema/AGENTS.template.md` mirror edits (token-preserving; 4 `{{...}}`
  placeholders untouched).
- `docs/reference/ci.md`: `duplicate` warning row added to the severity table.

**Task 3 — test (`tests/phase-09/test_lint_duplicate.sh`):**
- Self-contained (no git needed — duplicate check is pure file inspection).
- Positive: near-duplicate same-type entity pair → exactly one `warning`/`duplicate`
  finding naming the higher-inbound page (`geoffrey-hinton`, 2 inbound) as survivor,
  `geoff-hinton` (1 inbound) as loser.
- Negative: distinct same-type pages (`OpenAI` / `DeepMind`) → zero findings.
- Exclusion: `example: true` and `status: archived` near-dupes → zero findings.

## Deviations from Plan

**[Rule 1 — Bug] Realigned stale version-pin tests to 1.4.0.**
- Found during: Task 3 regression check.
- Issue: `tests/phase-09/test_lint_version.sh` asserted `1.2.0` and
  `test_lint_require_version.sh` was built around `1.2.0`/`1.3.0` pivots. Both were
  already stale — `LINT_VERSION` had been `1.3.0` since the DRFT-04 bump (f43dc62,
  May 31), so these tests pre-dated and were already inconsistent with HEAD before
  this task.
- Fix: updated both to `1.4.0` (exact-match passes 1.4.0; newer-pin-fails case
  re-pivoted 1.3.0→1.5.0; semver-tuple case 1.10.0>1.4.0 still holds).
- Rationale for in-scope fix: the assertions are *directly* coupled to the
  `LINT_VERSION` value I bumped; leaving them asserting 1.2.0 against a 1.4.0
  binary would be a knowingly-broken suite. Committed in the Task 3 test commit.
- Files: `tests/phase-09/test_lint_version.sh`, `tests/phase-09/test_lint_require_version.sh`.

No other deviations. No architectural changes (Rule 4 not triggered). No auth gates.

## Known false positives (expected, by design)

`--category duplicate` on the live wiki surfaces 3 findings, all acceptable
report-only candidates feeding human-confirmed MERGE:
- `entities/anthropic.md` vs `entities/anthropic-financial-services.md` (substring
  "Anthropic" ⊂ "Anthropic Financial Services") — the documented FP from the seed
  (parent org vs division). **This is acceptance gate 2.**
- `entities/anthropic.md` vs `entities/claude-api.md` (alias "Anthropic" ⊂ alias
  "Anthropic API").
- Two cookbook source-summary pages (near-identical titles).

The human dismisses these via the report-only contract — exactly the propose/confirm
shape the seed specified. If the substring-rule FP rate proves noisy at scale, the
seed flags a token-boundary gate as the follow-up.

## Acceptance gates (all PASS)

| # | Gate | Result |
|---|------|--------|
| 1 | `bash bin/lint.sh --version` → `1.4.0` | PASS (`1.4.0`) |
| 2 | `bash bin/lint.sh --category duplicate` exits 0; surfaces `anthropic.md` vs `anthropic-financial-services.md` | PASS (exit 0; pair present) |
| 3 | `bash bin/sync-claude.sh --check` exits 0 (AGENTS ≡ CLAUDE byte-equal) | PASS (exit 0) |
| 4 | `bash bin/check-neutrality.sh` exits 0 | PASS (exit 0) |
| 5 | Full `bash bin/lint.sh` exits cleanly (no new errors) | PASS (exit 0; 0 error findings) |
| 6 | Task 3 test exits 0 (positive + negative + exclusion) | PASS (exit 0) |

Additional: full `tests/phase-09/run.sh` suite → **29/29 PASS**.

## Commits

- `65cd73e` feat(quick-260602-d6a): add duplicate near-duplicate-page lint check
- `c2e75f5` schema(quick-260602-d6a): register duplicate category, bump LINT_VERSION 1.4.0
- `fcddefc` test(quick-260602-d6a): add duplicate lint test; fix version-pin tests for 1.4.0

## Out of scope (not built, per plan)

Semantic/embedding dedup (a2), auto-merge, cross-type pairs, tag/domain
consolidation (b), cluster detection (c). Auto-merge remains a permanent non-goal
(§9 MERGE is human-confirmed).
