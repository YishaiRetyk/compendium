---
phase: 20-pdf-ingestion
plan: 02
subsystem: schema
tags: [pdf, olmocr, ollama, source-types, frontmatter, routing, neutrality]

# Dependency graph
requires:
  - phase: 19-source-type-extensions
    provides: 5-dimension extension contract, provisional pdf registry row, research-report worked instance, routing-table precedent
provides:
  - Authoritative schema/reference/pdf-ingestion.md (format-orthogonal sub-case convention + acquisition runbook)
  - Finalized source-types.md section-4 pdf registry row (format-orthogonal verdict + Convention Doc pointer)
  - Four flat PDF extraction frontmatter fields (extraction_tool/model/date, original_asset)
  - Pass-0 PDF classification pointer in ingest.md
  - pdf-ingestion.md routing row in AGENTS.md/CLAUDE.md + AGENTS.template.md (with Phase 19 drift repair)
  - Regenerated canonical-AGENTS.md fixture in sync with the template
affects: [20-03 lint conditional check, 20-04 tooling + decision record, 21 video sub-case (inherits this shape)]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Format-orthogonal acquisition-path sub-case: format classifies at Pass 0 to parent type, convention layers on top (no new enum value)"
    - "Lazy-loaded convention doc (A + lean B): self-contained reference file, one-row pointer in the contract file"
    - "Template-public neutrality: abstract placeholders for vault terms; public tool names (olmOCR/Ollama/poppler) permitted"

key-files:
  created:
    - schema/reference/pdf-ingestion.md
  modified:
    - schema/reference/source-types.md
    - schema/reference/frontmatter.md
    - schema/workflows/ingest.md
    - AGENTS.md
    - CLAUDE.md
    - schema/AGENTS.template.md
    - schema/fixtures/canonical-AGENTS.md

key-decisions:
  - "PDF is a format-orthogonal acquisition-path sub-case, NOT a source_type enum value (D-05)"
  - "Four flat snake_case extraction fields, present only on PDF-acquired sources; OMITTED on non-PDF (D-06)"
  - "extraction_date kept distinct from ingested_at — acquisition and ingest dates can legitimately differ, both independently Dataview-queryable"
  - "Claims from PDF sources stay support_type: direct; hallucination risk carried by epistemic_status (D-09)"
  - "Tiered epistemic policy: born-digital→sourced; degraded→tentative + N=3 spot-verify (first/middle/last page), upgradeable (D-08)"
  - "Generic extractor contract (any tool emitting page markers); olmOCR 2 via Ollama (richardyoung/olmocr2:7b-q8) as named worked instance (D-04)"

patterns-established:
  - "Pattern: per-phase sub-case finalization fills the existing provisional registry row + authors a lazy-loaded convention doc + adds one routing row (Phase 21 video inherits this)"

requirements-completed: [PDF-01, PDF-02, PDF-03]

# Metrics
duration: 8 min
completed: 2026-06-11
---

# Phase 20 Plan 02: PDF Sub-case Convention Doc Summary

**Authoritative schema/reference/pdf-ingestion.md defining PDF as a format-orthogonal acquisition sub-case (parent-type classification + four flat extraction fields + tiered VLM-hallucination epistemic policy + olmOCR/Ollama acquisition runbook), wired into source-types.md, frontmatter.md, ingest.md, and the AGENTS.md/CLAUDE.md/template/fixture router chain.**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-06-11
- **Completed:** 2026-06-11
- **Tasks:** 3 (committed as one `schema:` logical operation per plan COMMIT SHAPE)
- **Files modified:** 8 (1 created, 7 modified)

## Accomplishments
- Authored `schema/reference/pdf-ingestion.md` (89 lines): 8 required sections — header, classification (format-orthogonal, 5-dimension walk), four flat frontmatter fields, `#p` locator usage (support_type direct), tiered epistemic policy (born-digital→sourced; degraded→tentative + N=3 spot-verify), acquisition runbook (generic contract + olmOCR worked instance + pdftoppm→per-page→marker pipeline), ingest checklist, See Also.
- Finalized the `source-types.md` section-4 `pdf` registry row with a format-orthogonal verdict and a Convention Doc pointer to `pdf-ingestion.md`; the 7-value enum and Retro-fit Table untouched.
- Documented the four flat extraction fields (`extraction_tool`, `extraction_model`, `extraction_date`, `original_asset`) in `frontmatter.md` with a prominent OMIT-on-non-PDF conditional note.
- Added a one-line Pass-0 PDF pointer to `ingest.md`.
- Added the `pdf-ingestion.md` routing row to `AGENTS.md`, updated the inclusion-audit baseline (288→289), byte-synced `CLAUDE.md`, mirrored both rows (pdf-ingestion + source-types Phase 19 drift repair) into `AGENTS.template.md`, and regenerated `canonical-AGENTS.md` so the setup-parity byte-equality gate passes.

## Task Commits

Tasks 1-3 landed as ONE `schema:` commit (one logical operation; CLAUDE.md §3, plan COMMIT SHAPE round 3 — keeps routing row + target file and template + fixture atomic):

1. **Tasks 1-3 (convention doc + machinery wiring + router sync)** - `ea3059d` (schema)

## Files Created/Modified
- `schema/reference/pdf-ingestion.md` - NEW authoritative PDF sub-case convention + acquisition runbook (lazy-loaded)
- `schema/reference/source-types.md` - Finalized section-4 pdf registry row (format-orthogonal verdict + Convention Doc pointer)
- `schema/reference/frontmatter.md` - Four flat PDF extraction fields in the Source Summary block with conditional OMIT note
- `schema/workflows/ingest.md` - Pass-0 PDF classification sub-bullet (classify to parent type, layer the convention)
- `AGENTS.md` - Routing-table row for pdf-ingestion.md; inclusion-audit baseline 288→289
- `CLAUDE.md` - Byte-synced mirror via bin/sync-claude.sh
- `schema/AGENTS.template.md` - Mirrored pdf-ingestion row + source-types row (Phase 19 wizard-source drift repair)
- `schema/fixtures/canonical-AGENTS.md` - Regenerated wizard-render fixture (setup-parity byte-equality)

## Decisions Made
- Followed all locked decisions D-01..D-09 from 20-CONTEXT.md as written.
- N=3 spot-verification with first/middle/last page selection (Claude's discretion per CONTEXT) — catches header/body/footer extraction drift across the document.
- Recorded the `extraction_date` vs `ingested_at` distinctness rationale inline in pdf-ingestion.md since the field ships in this wave (review round 2 instruction).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Replaced `§N` cross-section references with named-section phrasing**
- **Found during:** Task 3 (routing lint gate)
- **Issue:** `bin/lint.sh --category routing` flagged three `§N` references inside pdf-ingestion.md as "cross-file section-number reference forbidden (D-05)". The lint rule treats any `§N` token as a forbidden cross-file section pointer, even when the reference is intra-file.
- **Fix:** Rewrote the three internal references ("See §5", "(§2)", "(§4)") to name the target section in prose ("See the Tiered Epistemic Policy section below", "see the Frontmatter Fields section", "see the Tiered Epistemic Policy section"). No semantic change.
- **Files modified:** schema/reference/pdf-ingestion.md
- **Verification:** `bin/lint.sh --ci --dry-run --category routing` exits 0; `! grep -q '§' pdf-ingestion.md`; line count remains 89 (≥60); neutrality still passes.
- **Committed in:** ea3059d (part of the schema commit)

---

**Total deviations:** 1 auto-fixed (1 bug).
**Impact on plan:** The fix was required for the routing lint gate to pass; no scope change, no semantic change to the doc. All other tasks executed exactly as written.

## Observations (not deviations)

- **canonical-AGENTS.md fixture was significantly stale before this plan.** The plan-mandated regeneration produced an 827-line diff (mostly deletions). Investigation confirmed NO tracked files were deleted (`git diff --diff-filter=D` empty) — the previous fixture carried legacy content the current template no longer renders (Phase 19 drift). The regenerated 290-line fixture is the authentic wizard render of the current template, and `tests/phase-08/test_canonical_byte_equality.sh` passes against it. This is the intended drift repair, not data loss.

## Issues Encountered
None beyond the auto-fixed routing-lint deviation above.

## User Setup Required
None - no external service configuration required (user_setup: []).

## Next Phase Readiness
- PDF-01 (doc half), PDF-02 (convention + fields), PDF-03 (tiered epistemic policy) complete and discoverable via the routing table.
- Ready for 20-03 (lint conditional check for the four extraction fields when original_asset points at a *.pdf — D-07) and 20-04 (bin/pdf-extract.sh + bin/ingest.sh --asset + decision record).
- No source page yet carries `original_asset`, so the future conditional lint check is moot at this point — the repo lints green between commits as Phase 19 ordering lesson requires.

## Self-Check: PASSED

- `schema/reference/pdf-ingestion.md` exists on disk (89 lines, ≥60).
- All four extraction field names present in both pdf-ingestion.md and frontmatter.md.
- Commit `ea3059d` present in git log.
- All verification gates pass: yaml lint, routing lint, sync-claude --check, cmp -s AGENTS.md CLAUDE.md, byte-equality test, check-neutrality, gen-skills --check.

---
*Phase: 20-pdf-ingestion*
*Completed: 2026-06-11*
