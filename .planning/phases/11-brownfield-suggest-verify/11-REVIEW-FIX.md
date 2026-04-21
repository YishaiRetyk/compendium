---
phase: 11-brownfield-suggest-verify
fixed_at: 2026-04-20T00:00:00Z
review_path: .planning/phases/11-brownfield-suggest-verify/11-REVIEW.md
iteration: 1
findings_in_scope: 4
fixed: 4
skipped: 0
status: all_fixed
---

# Phase 11: Code Review Fix Report

**Fixed at:** 2026-04-20T00:00:00Z
**Source review:** .planning/phases/11-brownfield-suggest-verify/11-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 4
- Fixed: 4
- Skipped: 0

All 47 Phase 11 tests pass after fixes. Cross-phase tests (Phases 07, 08, 09, 09.1) also pass. Phase 10 shows only the 11 pre-existing `ruamel.yaml`-bootstrap failures documented in `deferred-items.md` — no new regressions.

## Fixed Issues

### WR-01: `suggest` preview's TASK regex fails to match `- [ ]` / `- [x]` checklists

**Files modified:** `bin/brownfield.sh`
**Commit:** b815f82
**Applied fix:** Deleted the duplicated heredoc regex block (WIKILINK_ONLY, QUESTION, TASK, SOURCE_ID, PLACEHOLDER, BULLET_TOP_LEVEL, EP_PRESENT, PV_PRESENT, SECTION_HDR, plus the `is_eligible_top_level` and `section_scan_top_level` helpers) and imported the canonical `section_scan` from `brownfield_provenance` (already available on `sys.path` via `BROWNFIELD_LIB_DIR`). The suggest preview now uses the exact same eligibility logic as `02-provenance-bootstrap.sh` on `--apply`, so preview/apply cannot drift. Also updated the `sample` construction to unpack the `(lineno, line)` tuples that `section_scan` returns.

### WR-02: `suggest` preview's BULLET_TOP_LEVEL regex rejects tab-indented top-level bullets

**Files modified:** `bin/brownfield.sh`
**Commit:** b815f82
**Applied fix:** Resolved by the same import refactor as WR-01. The canonical `BULLET_TOP_LEVEL_RE = re.compile(r'^-(?: |\t)(.+)$')` in `brownfield_provenance.py` accepts both `- claim` and `-\tclaim` forms, matching what 02 accepts on `--apply`.

### WR-03: `suggest` re-run appends duplicate `## Cross-link candidates` / `## Privacy review` sections

**Files modified:** `bin/brownfield.sh`
**Commit:** 19aad63
**Applied fix:** Before appending the Phase 11 advisory sections, the suggest subcommand now reads the existing `.brownfield/REPORT.md`, finds the first `\n## Cross-link candidates\n` marker, and truncates the file from that point onward. The bootstrap-produced prefix (everything before the Phase 11 sections) is preserved; the Phase 11 sections are rewritten fresh on every run. First-run behavior is unchanged (if the file doesn't exist or the marker is absent, nothing is truncated).

### WR-04: `01-page-typing.sh` dereferences `candidates`/`decisions` without None-guard on empty YAML

**Files modified:** `schema/brownfield/migrations/01-page-typing.sh`
**Commit:** 6a38993
**Applied fix:** Added `or {}` fallback to both `yaml.load(fh)` calls, so empty YAML parses to `{}` instead of `None`. Added an explicit empty-state guard that exits with exit code 1 and a clean error message (`"ERROR: decisions or candidates YAML is empty — re-run bin/brownfield.sh suggest to regenerate."`) when either file has no `clusters` list. `sys` was already imported on line 123, so no additional imports were needed.

---

_Fixed: 2026-04-20T00:00:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
