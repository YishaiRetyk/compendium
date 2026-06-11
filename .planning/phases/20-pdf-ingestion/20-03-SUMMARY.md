---
phase: 20-pdf-ingestion
plan: 03
subsystem: testing
tags: [lint, ingest, pdf, bash, python, frontmatter-validation]

# Dependency graph
requires:
  - phase: 20-01
    provides: tests/phase-20 harness (run.sh aggregator + lib.sh), test_pdf_extract_markers.sh
  - phase: 20-02
    provides: schema/reference/pdf-ingestion.md (convention doc + tiered epistemic policy), frontmatter.md PDF fields, AGENTS.md routing row
provides:
  - "bin/lint.sh conditional original_asset=*.pdf extraction-field check (D-07) + bare-co-located-filename guard; LINT_VERSION 1.10.0"
  - "bin/ingest.sh --asset <path> flag co-locating the original PDF alongside source.md in one bundle (D-11)"
  - "Four phase-20 tests proving both tool edits; aggregator now 5/5 green"
affects: [21-video-ingestion, pdf-validation-ingest]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Conditional source-field lint gate: a new validation requirement gated on a discriminator field (original_asset->*.pdf) lands as a parallel branch inside the type==source block, never appended to the unconditional SOURCE_EXTRA_FIELDS list"
    - "Data-then-check ordering: gate on a field no existing page carries (original_asset), so the check is green between commits"
    - "Asset-precondition-before-write: all --asset validation runs before mkdir/copy so a failure leaves no partial bundle"

key-files:
  created:
    - tests/phase-20/test_pdf_extraction_fields.sh
    - tests/phase-20/test_pdf_convention_doc.sh
    - tests/phase-20/test_pdf_epistemic_tiers.sh
    - tests/phase-20/test_ingest_asset_flag.sh
  modified:
    - bin/lint.sh
    - bin/ingest.sh

key-decisions:
  - "Tasks 1-3 landed as ONE feat(20-03) commit (tests assert against both tool edits; splitting strands them red between commits)"
  - "extraction_date kept as a distinct field (not collapsed into ingested_at) -- matches the four-field convention authored by Plan 02"
  - "Bare-co-located-filename guard rejects any original_asset with a '/' or leading '..' (conservative traversal guard; over-rejects ..scan.pdf by design)"

patterns-established:
  - "Conditional lint branch parallel to the source_type enum check inside if fm.get('type')=='source'"
  - "WIKI_ROOT-override fixture-frontmatter lint test asserting on STDERR finding-line content (never bare exit code)"
  - "Isolated temp-cwd ingest integration test with explicit --contributor to bypass git-context resolution"

requirements-completed: [PDF-02, PDF-04]

# Metrics
duration: 12min
completed: 2026-06-11
---

# Phase 20 Plan 03: PDF Convention Enforcement + Asset Co-location Summary

**Conditional lint check enforcing the four extraction_* fields on PDF sources (D-07, LINT_VERSION 1.10.0), an `--asset` flag on bin/ingest.sh co-locating the original PDF beside source.md (D-11), and four phase-20 tests taking the aggregator to 5/5 green.**

## Performance

- **Duration:** ~12 min
- **Tasks:** 3 (committed as one feat commit per the plan's COMMIT SHAPE directive)
- **Files modified:** 6 (2 modified, 4 created)

## Accomplishments
- bin/lint.sh: added a parallel conditional branch inside the `type=='source'` block gated on `original_asset` ending `.pdf` (case-insensitive). Missing any of `extraction_tool`/`extraction_model`/`extraction_date`/`original_asset` produces an `error`/`yaml` finding; an `original_asset` with a directory component (`/tmp/x.pdf`, `../x.pdf`) produces a bare-co-located-filename error. LINT_VERSION bumped 1.9.1 -> 1.10.0 (MINOR, additive). SOURCE_EXTRA_FIELDS and the 7-value source_type enum left untouched.
- bin/ingest.sh: added `--asset <path>` with arity check (mirroring `--slug`), all preconditions (file existence, source.md-basename guard, no-overwrite-without-force) validated BEFORE `mkdir`/copy, and a pure-file-I/O copy into the same dated bundle dir. Usage documents the flag. Charter intact -- no LLM call added.
- Four phase-20 tests authored and green: conditional-lint unit (Variants A/B/C), convention-doc smoke, epistemic-tier grep, and the `--asset` integration test. Aggregator reports `PHASE 20 TESTS: 5/5 passed, 0 skipped`.

## Task Commits

Tasks 1-3 landed as a single commit per the plan's round-4 COMMIT SHAPE directive (the tests assert against both tool edits; splitting would strand the suite red between commits):

1. **Tasks 1-3: lint enforcement + ingest --asset + four tests** - `527da4f` (feat)

## Files Created/Modified
- `bin/lint.sh` - LINT_VERSION 1.10.0; conditional `original_asset->*.pdf` extraction-field check + bare-filename guard inside the `type=='source'` block
- `bin/ingest.sh` - `--asset <path>` flag: arity check, pre-write precondition validation, bundle co-location, usage doc
- `tests/phase-20/test_pdf_extraction_fields.sh` - WIKI_ROOT-override lint unit (missing-field, all-fields-clean, path-component variants)
- `tests/phase-20/test_pdf_convention_doc.sh` - pdf-ingestion.md / frontmatter.md / AGENTS.md routing smoke
- `tests/phase-20/test_pdf_epistemic_tiers.sh` - tiered-policy token grep (born-digital/tentative/spot-verif/support_type:direct, NOT derived)
- `tests/phase-20/test_ingest_asset_flag.sh` - isolated-temp-cwd `--asset` co-location integration (no model call)

## Decisions Made
- Tasks 1-3 committed together as `feat(20-03)` per the plan's COMMIT SHAPE note.
- Kept the four-field convention verbatim (extraction_date NOT collapsed into ingested_at) -- matches Plan 02's authored frontmatter and the lint check's PDF_EXTRACTION_FIELDS list.
- The fixture frontmatter was authored to lint clean on its own (zero unrelated yaml findings), so Variant A/C assertions target only the PDF check.

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
None. The verification grep failures observed during development were shell history-expansion artifacts in the compound command, not file-content mismatches -- confirmed with `grep -F` fixed-string matching.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- PDF-02 (enforcement) and PDF-04 (--asset tooling) are mechanically proven by tests; the phase-20 aggregator is fully green (5/5).
- The format-orthogonal sub-case pattern (conditional lint branch + asset co-location) is ready for Phase 21 (video) to inherit.
- Wave-2 exit gate satisfied: `bash bin/lint.sh --ci --dry-run --category yaml` exits 0; `bash bin/check-neutrality.sh` exits 0; the real `sources/` + `wiki-cloud/` trees are unchanged by the suite.

---
*Phase: 20-pdf-ingestion*
*Completed: 2026-06-11*

## Self-Check: PASSED

All claimed files exist on disk; commit `527da4f` is present in the git log.
