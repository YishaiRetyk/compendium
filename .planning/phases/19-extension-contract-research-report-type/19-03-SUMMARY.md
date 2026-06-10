---
phase: 19-extension-contract-research-report-type
plan: "03"
subsystem: lint
tags: [lint, provenance, source-types, research-report, epistemic-laundering]

# Dependency graph
requires:
  - phase: 19-01
    provides: source-types.md contract with research-report source_type enum
  - phase: 19-02
    provides: "#r<n> locator row in provenance.md; audit selector additions"
provides:
  - "bin/lint.sh LINT_VERSION 1.9.0 with VALID_SOURCE_TYPES, D-08 derived-never-direct check, D-09 source_type enum validation"
  - "103 |direct| markers in 14 dependent wiki pages swept to |derived| for both research-report source IDs"
  - "vlm-ocr-hallucination.md epistemic_status re-graded from sourced to mixed"
affects:
  - 19-04
  - phase-final-gate

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "D-08: derived-never-direct — research-report sources must be cited with |derived| on non-source pages"
    - "D-09: source_type enum validation in lint yaml category"
    - "VALID_SOURCE_TYPES constant defining 7 valid values alongside VALID_TYPES/VALID_STATUS/VALID_EPISTEMIC/VALID_COMPILATION"
    - "Atomic commit protocol: lint enforcement and data sweep land in same commit to prevent CI landmine"

key-files:
  created: []
  modified:
    - "bin/lint.sh"
    - "wiki-cloud/entities/claude-code.md"
    - "wiki-cloud/entities/gsd.md"
    - "wiki-cloud/entities/spec-kit.md"
    - "wiki-cloud/entities/superpowers.md"
    - "wiki-cloud/entities/omnidocbench.md"
    - "wiki-cloud/entities/olmocr.md"
    - "wiki-cloud/concepts/subagents.md"
    - "wiki-cloud/concepts/vlm-ocr-hallucination.md"
    - "wiki-cloud/concepts/progressive-disclosure.md"
    - "wiki-cloud/concepts/spec-driven-development.md"
    - "wiki-cloud/overviews/agent-skills.md"
    - "wiki-cloud/comparisons/ocr-pipeline-vs-vlm-ingestion.md"
    - "wiki-cloud/comparisons/claude-code-orchestration-frameworks.md"
    - "wiki-cloud/overviews/pdf-text-extraction-for-llm-ingestion.md"

key-decisions:
  - "Atomic commit required: D-08 lint check and D-11 sweep land together to prevent CI landmine when Plan 04 flips source_type frontmatter"
  - "D-08 vacuous within this plan (no source has source_type: research-report until Plan 04); non-vacuous proof deferred to Plan 04 phase-final gate"
  - "Pre-sweep count 97 matched planning estimate exactly (97 lines, 103 markers)"
  - "Only vlm-ocr-hallucination.md (100% report-citing) re-graded to mixed; agent-skills.md (3/23 ≈ 13%) stays sourced per >50% threshold rule"
  - "VALID_SOURCE_TYPES added alongside existing VALID_* constants (VALID_TYPES/VALID_STATUS/VALID_EPISTEMIC/VALID_COMPILATION)"

patterns-established:
  - "D-08 guard pattern: fm.get('type') != 'source' scopes derived-never-direct to non-source pages only (source summary self-citations are correct as |direct|)"
  - "FLAT source_registry access: source_registry.get(source_id) returns frontmatter dict directly — no .get('fm', {}) indirection"

requirements-completed:
  - RPT-03
  - RPT-06

# Metrics
duration: 15min
completed: 2026-06-10
---

# Phase 19 Plan 03: Lint Enforcement + Retro-Classification Sweep Summary

**LINT_VERSION bumped to 1.9.0 with VALID_SOURCE_TYPES, D-08 derived-never-direct check, and D-09 source_type enum validation; 97 grep lines (103 markers) swept from |direct| to |derived| in 14 dependent wiki pages for both research-report source IDs; vlm-ocr-hallucination.md re-graded to mixed**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-06-10T20:36:57Z
- **Completed:** 2026-06-10T20:50:52Z
- **Tasks:** 2 (committed atomically per plan requirement)
- **Files modified:** 17 (bin/lint.sh + 14 wiki pages + log.md + lint-report.md)

## Accomplishments

- Added `VALID_SOURCE_TYPES` constant to bin/lint.sh with 7 valid values: article, paper, transcript, journal, data, image, research-report
- Added D-09 source_type enum validation: unknown `source_type` values on source pages are a lint error
- Added D-08 derived-never-direct check: `[prov:<research-report-src>#...|direct]` on non-source pages triggers "Epistemic laundering" error; source pages are explicitly excluded (they correctly self-cite with direct)
- Bumped LINT_VERSION from 1.8.0 to 1.9.0
- Swept 97 grep lines (103 markers) from `|direct|` to `|derived|` in 14 dependent wiki pages for two research-report source IDs
- D-12: vlm-ocr-hallucination.md `epistemic_status` changed from `sourced` to `mixed` (100% report-citing markers) and `updated_at` bumped to 2026-06-10
- Source summary self-citations (54 `|direct|` markers) left unchanged
- Full lint green: 0 errors after sweep

## Task Commits

Both tasks committed as a single atomic commit per the plan's `<atomic_commit_protocol>`:

1. **Tasks 1+2 (atomic):** `3d7eeb1` — ingest(retro-classify): enforce derived-never-direct (D-08), sweep report-citing direct markers, bump lint 1.9.0

## Files Created/Modified

- `bin/lint.sh` — LINT_VERSION 1.9.0; VALID_SOURCE_TYPES constant; D-09 source_type enum check inside `if fm.get('type') == 'source':` block; D-08 derived-never-direct check as `else:` branch in provenance loop with `fm.get('type') != 'source'` guard
- `wiki-cloud/entities/claude-code.md` — 7 `|direct|` → `|derived|` for src-2026-04-16-claude-code-frameworks-report
- `wiki-cloud/entities/gsd.md` — 9 markers swept
- `wiki-cloud/entities/spec-kit.md` — 9 markers swept
- `wiki-cloud/entities/superpowers.md` — 8 markers swept
- `wiki-cloud/entities/omnidocbench.md` — 6 markers swept
- `wiki-cloud/entities/olmocr.md` — 9 markers swept
- `wiki-cloud/concepts/subagents.md` — 8 markers swept
- `wiki-cloud/concepts/vlm-ocr-hallucination.md` — 6 markers swept + epistemic_status: sourced → mixed + updated_at: 2026-06-10
- `wiki-cloud/concepts/progressive-disclosure.md` — 6 markers swept
- `wiki-cloud/concepts/spec-driven-development.md` — 7 markers swept
- `wiki-cloud/overviews/agent-skills.md` — 3 markers swept (stays sourced — only 13% report-citing)
- `wiki-cloud/comparisons/ocr-pipeline-vs-vlm-ingestion.md` — 6 markers swept
- `wiki-cloud/comparisons/claude-code-orchestration-frameworks.md` — 7 markers swept
- `wiki-cloud/overviews/pdf-text-extraction-for-llm-ingestion.md` — 12 markers swept

## Decisions Made

- Atomic commit required (per plan): D-08 lint check and D-11 sweep must land together so CI does not go red when Plan 04 flips `source_type: research-report` on the source summary pages
- D-08 is vacuous within this plan (no source summary has `source_type: research-report` yet — Plan 04 sets that); the non-vacuous proof + negative test runs in Plan 04's phase-final gate
- Pre-sweep count of 97 lines exactly matched the planning estimate; binding acceptance criterion (residual = 0) confirmed after sweep

## Deviations from Plan

None - plan executed exactly as written. The atomic commit protocol followed as specified; both tasks landed in commit 3d7eeb1.

## Issues Encountered

None. Pre-sweep count (97) matched planning estimate exactly; sed sweeps completed without requiring re-application; full lint passed on first run.

## Verification Results

All 7 success criteria from plan `<verification>` section confirmed:

1. `bash bin/lint.sh --require-version 1.9.0` — exits 0
2. `bash bin/lint.sh --category provenance` — exits 0 (0 errors; D-08 vacuous — no source has `source_type: research-report` yet)
3. `bash bin/lint.sh --category yaml` — exits 0 (existing source pages with valid source_type values pass D-09)
4. `bash bin/lint.sh` (full) — exits 0, 0 errors, 69 warnings (pre-existing), 4 info
5. `grep "VALID_SOURCE_TYPES" bin/lint.sh | wc -l` — 3 (definition + usage in D-09 + comment in D-08 block)
6. Residual `|direct|` markers in entities/concepts/comparisons/overviews for both source IDs — 0
7. `grep "epistemic_status: mixed" wiki-cloud/concepts/vlm-ocr-hallucination.md` — match confirmed

## Known Stubs

None — all swept markers are now correctly `|derived|`; no placeholder data in plan output.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries introduced. bin/lint.sh changes are additive lint checks only (no new input/output surfaces). Wiki page marker changes are content-only.

## Next Phase Readiness

- Plan 04 can now safely set `source_type: research-report` on the two source summary pages — D-08 lint check will validate the sweep was complete (non-vacuous proof)
- Plan 04's phase-final gate runs the negative test (place a deliberate `|direct|` citation and verify D-08 fires)
- D-09 enum validation is live: any typo in `source_type` (e.g., `research_report` or `report`) on a source page will be a lint error

---
*Phase: 19-extension-contract-research-report-type*
*Completed: 2026-06-10*
