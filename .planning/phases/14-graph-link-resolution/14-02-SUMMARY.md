---
phase: 14-graph-link-resolution
plan: "02"
subsystem: bin/lint.sh linkres category + tests
tags:
  - lint
  - linkres
  - piped-links
  - masking
  - orphan
dependency_graph:
  requires:
    - 14-01-docs (independent, wave 1 parallel)
  provides:
    - linkres enforcement of piped-form convention
    - mask_markdown() helper for safe code/comment exclusion
    - alias-free orphan resolution
    - LINT_VERSION 1.6.0
  affects:
    - bin/lint.sh
    - tests/phase-09/test_lint_linkres.sh
    - tests/phase-09/test_lint_require_version.sh
    - tests/phase-09/test_lint_strict_dr_match.sh
    - tests/phase-09/test_lint_version.sh
tech_stack:
  added: []
  patterns:
    - length-preserving markdown masking (offset-aligned positional --fix)
    - piped-link form enforcement with gap-vs-error contract
    - id-only orphan resolution (no aliases)
key_files:
  created: []
  modified:
    - bin/lint.sh
    - tests/phase-09/test_lint_linkres.sh
    - tests/phase-09/test_lint_require_version.sh
    - tests/phase-09/test_lint_strict_dr_match.sh
    - tests/phase-09/test_lint_version.sh
decisions:
  - LINT_VERSION bumped to 1.6.0 (MINOR: non-breaking category re-point)
  - Positional bare->piped --fix chosen over global regex sub (idempotency + offset safety)
  - Frontmatter preserved via full-file read + length-preserving mask (not body-only write)
  - Alias-free orphan map: id/stem only, no aliases, consistent with corrected Obsidian premise
  - Vestigial self-aliases kept (D-07) but not indexed for orphan/gap resolution
metrics:
  duration: "~45 minutes"
  completed: "2026-06-03"
  tasks_completed: 2
  files_modified: 5
---

# Phase 14 Plan 02: Re-point linkres + masking helper + alias-free orphan Summary

bin/lint.sh linkres category re-pointed from wrong-premise self-alias validation to correct piped-form enforcement with YAML/code/comment masking, positional bare-to-piped --fix preserving frontmatter, and alias-free orphan resolution; 13-case test suite with neutral fixtures passes, aggregator 30/30 green.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | Re-point linkres + masking helper + alias-free orphan in bin/lint.sh | bafb5dd | bin/lint.sh |
| 2 | Re-point test suite (13 cases) + update version tests + fix DR fixture | 9227863 | tests/phase-09/test_lint_linkres.sh, tests/phase-09/test_lint_require_version.sh, tests/phase-09/test_lint_strict_dr_match.sh, tests/phase-09/test_lint_version.sh |

## What Was Built

### bin/lint.sh changes (LINT_VERSION 1.6.0)

**New: mask_markdown() helper** — A length-preserving masking function that neutralises YAML frontmatter, fenced code blocks (```` ``` ````, `~~~`), HTML comments (`<!-- ... -->`), and inline code spans (`` ` `` ) before both the linkres scan AND the `--fix` rewrite. Newlines are preserved; all other masked characters become spaces. Offsets are index-aligned between the masked string and the real file content, enabling positional rewrites that never touch masked spans.

**Re-pointed linkres block** — The old Subcheck A (self-alias invariant enforcement) and Subcheck B (normalized match variant check) are replaced with form-first masked logic:

- **Piped links** `[[target|display]]`: OK if `target.lower()` is in `known_ids` (exact id/stem match). Error if target uses path-style (`/`), or normalizes to a known page but isn't the literal id. Gap (info, §3 red link) if target has no normalized match and no slash.
- **Bare links** `[[X]]` (no pipe): ALWAYS a linkres error regardless of match (D-02 unconditional piped form). Error + auto-fixable for unique normalized match; error-unfixable for no match; warning for multi-match.
- **`--fix`**: Positional splice rewrite. Finds bare-link spans in the MASKED body, collects `(start, end, replacement)` tuples, sorts them, then applies them against the FULL raw file content (not the parsed body-only string). This preserves YAML frontmatter byte-for-byte and is idempotent.

**Orphan block changes** — The alias-indexing loop in `obsidian_map` construction is removed. Orphan resolution is id/filename-stem ONLY. A page reached only via its own self-alias does not count as connected. Inbound-link scan now runs over `mask_markdown(body)` so code-fence examples don't create fake inbound links. Piped `[[id|Title]]` links correctly resolve to the page whose stem == `id` (WIKILINK_RE yields target-before-pipe).

### Test changes

`tests/phase-09/test_lint_linkres.sh` — Complete rewrite with 13 cases covering the new semantics, using neutral placeholder fixtures (alpha, beta, gamma-one/two, hub, prov-page, fmtest):
- T1: piped known-id = zero errors
- T2: bare unique-match = error, gone after --fix
- T3: genuine gap (piped, no normalized match, no slash) = zero findings
- T4: malformed piped target (normalizes to known id) = error not gap
- T4b: path-style piped target = error
- T5: bare multi-match via `_PLURAL_MAP` ("gamma contracts" → both "Gamma Contract" and "Gamma Contracts") = WARNING
- T6: --fix rewrites bare → piped
- T7/T7-post: bare no-match = error, remains after --fix (unfixable)
- T8: idempotency
- T9: index.md/log.md specials scanned
- T10: clean piped + prov-page = zero errors
- T11a: piped [[alpha|Alpha]] inbound link counts (id-stem resolution)
- T11b: alias-only inbound does NOT save a page from orphan
- T12: masked spans produce zero findings
- T13: --fix preserves YAML frontmatter byte-for-byte

`test_lint_version.sh` — Updated: `1.5.0` → `1.6.0`.

`test_lint_require_version.sh` — Updated version pins for 1.6.0.

`test_lint_strict_dr_match.sh` — Fixed inline DR fixture: `[[Attention]]` (bare) → `[[attention|Attention]]` (piped). Under the new rules, bare links are errors; `--strict` exits 1 on any errors; the DR body bare link was breaking the test.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Bare link in strict-missing-dr test fixture**
- **Found during:** Task 2 aggregator run
- **Issue:** `test_lint_strict_dr_match.sh` creates an inline DR with `[[Attention]]` (bare). Under new linkres rules, bare links are always errors. `--strict` exits 1 on any errors (it runs all categories), so the test failed.
- **Fix:** Changed `[[Attention]]` → `[[attention|Attention]]` (piped form) in the inline DR creation.
- **Files modified:** `tests/phase-09/test_lint_strict_dr_match.sh`
- **Commit:** 9227863

**2. [Rule 1 - Bug] T1 assertion checked wrong predicate**
- **Found during:** Task 2 first test run
- **Issue:** T1's assertion checked for `'alpha|Alpha' in message`, but the error message for the bare [[Alpha]] link in hub.md says "use [[alpha|Alpha]]" — the suggestion contains the piped form, so it matched. The intent was to verify that a correctly piped link produces zero errors.
- **Fix:** Changed T1 to check that `prov-page.md` (which has only piped links) produces zero linkres errors, directly testing the "known-id piped link is OK" behavior.
- **Files modified:** `tests/phase-09/test_lint_linkres.sh`
- **Commit:** 9227863

## Gap-vs-Error Contract

Stated once for reference (from D-04/D-05):
- PIPED target known id → OK
- PIPED target unknown, no normalized match, no `/` → GAP (deliberate red link, §3; NOT linkres)
- PIPED target unknown but normalizes to a real page, OR contains `/` → linkres ERROR (malformed)
- BARE link → ALWAYS a linkres ERROR (form violation), regardless of match (review HIGH #1)
  - unique match → ERROR + auto-fixable (--fix rewrites)
  - no match → ERROR, not auto-fixable (red link must still be piped once target exists)
  - multi match → WARNING (ambiguous, manual pipe)

## Self-Check: PASSED

### Files exist:
- bin/lint.sh: FOUND
- tests/phase-09/test_lint_linkres.sh: FOUND
- tests/phase-09/test_lint_require_version.sh: FOUND
- tests/phase-09/test_lint_strict_dr_match.sh: FOUND
- tests/phase-09/test_lint_version.sh: FOUND

### Commits exist:
- bafb5dd (Task 1): FOUND
- 9227863 (Task 2): FOUND

### Test results:
- test_lint_linkres.sh: 13/13 PASS
- tests/phase-09/run.sh: 30/30 PASS
