---
phase: 06-reflection-drift-detection
plan: 02
subsystem: lint-drift-detection
tags: [lint, drift, decision-type, reflection]
dependency_graph:
  requires:
    - 06-01 (decision page type schema)
  provides:
    - drift detection integrated into bin/lint.sh
    - decision page yaml validation
    - category-labeled lint report subsections
  affects:
    - bin/lint.sh (extended with Check 10 drift block)
tech_stack:
  added: [hashlib (stdlib), collections.OrderedDict (stdlib)]
  patterns:
    - "do_fix and not dry_run" gating for all file-mutating auto-fixes
    - severity-first report structure with category subsections
key_files:
  created: []
  modified:
    - bin/lint.sh
decisions:
  - Auto-fix of compilation_status uses the same (do_fix and not dry_run) gating as stale marker auto-fixes
  - autofix_applied counts across all categories via findings filter, not stale-specific counter
  - format_findings groups by category within severity using OrderedDict to preserve insertion order
  - DRFT-02 surfaced a legitimate missing source file (thinking-fast-and-slow-part1) -- working as intended
metrics:
  duration: 5min
  completed_at: 2026-04-14
  tasks: 2
  files_modified: 1
requirements: [DRFT-01, DRFT-02, DRFT-03, DRFT-04]
---

# Phase 06 Plan 02: Lint Drift Detection Summary

Drift detection checks (DRFT-01..04) and decision page validation integrated into bin/lint.sh with --fix-gated auto-fix for content-hash drift.

## What Changed

- `VALID_TYPES` extended to include `decision`
- New decision-specific YAML validation: `trigger_type` enum (6 values), `affected_pages` list, optional `decision_history` list of strings
- `--category drift` filter added to usage
- Check 10 block with 5 sub-checks appended after Check 9:
  - 10a: Walk `sources/` for unrepresented raw source .md files (DRFT-01)
  - 10b: Verify `path` frontmatter field on each source summary points to an existing file (DRFT-02)
  - 10c: SHA-256 recompute against `content_hash`; auto-fix sets `compilation_status: stale` only when `--fix` passed
  - 10d: Index coverage -- pages not found by id or title in `wiki/index.md`
  - 10e: Obsidian vault awareness (missing `.obsidian/`, non-md files in wiki/) (DRFT-03)
- `autofix_applied` now counts all findings with category `autofix`, enabling drift autofixes to be reported
- `format_findings` groups findings by category under `### Category` subsections within each severity level (DRFT-04 report format)

## Verification Results

- `bin/lint.sh --dry-run wiki/`: exit 0, 1 error (legitimate DRFT-02 finding -- missing source file on disk), 2 warnings, 7 info
- `bin/lint.sh --dry-run --category drift wiki/`: exit 0, shows only drift-category findings
- `bin/lint.sh --dry-run --category yaml wiki/`: decision page passes (no errors for wiki/decisions/)
- Pre-existing non-drift checks preserved: the 2 contradiction-candidate warnings and maturity/red-link info findings from baseline all still present

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed tuple unpacking in Check 10d**
- **Found during:** Task 2 insertion
- **Issue:** Plan's template code for Check 10d used `for page_path, page_fm, page_body in all_pages`, but `all_pages` stores 4-tuples `(path, fm, body, err)` (line 231 of lint.sh).
- **Fix:** Changed to `for page_path, page_fm, page_body, page_err in all_pages:` to match actual structure.
- **Files modified:** bin/lint.sh (Check 10d)
- **Commit:** b77cbc4

## Known Stubs

None. All drift checks are fully wired; the DRFT-02 error is surfacing a real missing file in the working tree, which is the intended behavior (drift detection catching actual drift).

## Self-Check: PASSED

- FOUND: bin/lint.sh
- FOUND commit a3548cc (Task 1)
- FOUND commit b77cbc4 (Task 2)
- grep `'decision'` in bin/lint.sh: present in VALID_TYPES
- grep `VALID_TRIGGER_TYPES`: present
- grep `should_run('drift')`: present
- grep `Check 10a` through `Check 10e`: all 5 comments present
- grep `import hashlib`: present inside drift block
- grep `autofix_applied = sum`: present
- grep `OrderedDict`: present in format_findings
