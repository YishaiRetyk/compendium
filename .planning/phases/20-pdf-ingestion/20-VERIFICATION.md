---
phase: 20-pdf-ingestion
verified: 2026-06-12T00:00:00Z
status: passed
score: 4/4
overrides_applied: 0
---

# Phase 20: PDF Ingestion — Verification Report

**Phase Goal:** PDF documents can be acquired via a documented pipeline and ingested as a sub-case of an existing source type, with page-anchored provenance and honest epistemic handling for degraded scans.
**Verified:** 2026-06-12
**Status:** passed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | An agent can find a documented PDF acquisition pipeline in schema/ — running olmOCR 2 via local Ollama produces Markdown with `<!-- page: N -->` markers ready for standard ingest | VERIFIED | `schema/reference/pdf-ingestion.md` (89 lines) exists, is routing-table registered in AGENTS.md/CLAUDE.md, defines the generic extractor contract (D-04), names olmOCR 2 as the worked instance, and documents the pdftoppm→per-page-VLM→marker-assembly pipeline. `bin/pdf-extract.sh` (243 lines) implements it via the Ollama HTTP `/api/generate` endpoint, never `ollama run`, with `--rawfile`/`-d @file` file-based payload I/O. Test `test_pdf_extract_markers.sh` exercised the live loop end-to-end on a committed 2-page fixture and confirmed marker count == page count. |
| 2 | A source summary page for a PDF records the extraction tool + model version in frontmatter, and every claim uses `#p<N>` locators pointing to the correct page | VERIFIED | `wiki-cloud/sources/src-2026-06-12-multi-agent-scientific-discovery.md` carries all four extraction fields: `extraction_tool: olmocr`, `extraction_model: "hf.co/bartowski/allenai_olmOCR-2-7B-1025-GGUF:Q4_K_M"` (the model actually used, per D-04 tool-agnostic convention), `extraction_date: 2026-06-12`, `original_asset: s41586-026-10652-y.pdf`. All claims use `#p<N>` page locators (e.g. `#p3`, `#p4`, `#p5`, `#p6`, `#p7`). `frontmatter.md` documents all four fields. `bin/lint.sh` enforces them conditionally when `original_asset` ends `.pdf` (LINT_VERSION 1.10.0); `--ci --dry-run --category yaml` exits 0. |
| 3 | When a PDF is degraded/scanned, the convention specifies spot-verification steps and/or mandates a lower epistemic default — VLM-extracted text is not silently treated as high-confidence | VERIFIED | `schema/reference/pdf-ingestion.md` Section 4 "Tiered Epistemic Policy" defines: born-digital/clean → parent type's normal `sourced` default; degraded/scanned → `epistemic_status: tentative` + mandatory spot-verification of N=3 pages (first, middle, last), upgradeable only after the spot-verified pages match the co-located original. Explicitly describes the confident-hallucination failure mode. `support_type: direct` is preserved throughout (D-09 — hallucination risk is in epistemic status, never in support type). Test `test_pdf_epistemic_tiers.sh` verifies tokens: `born-digital`, `tentative`, `spot-verif`, `support_type: direct`, and absence of `support_type: derived`. |
| 4 | One real PDF artifact acquired via the pipeline, ingested, wiki pages in sources/ with page-anchored provenance; original PDF co-located as a bundle asset alongside source.md | VERIFIED | Bundle `sources/2026/2026-06/2026-06-12-multi-agent-scientific-discovery/` holds `source.md` (36 `<!-- page: N -->` markers, one per page of the 36-page PDF) and the co-located asset `s41586-026-10652-y.pdf`. Four wiki pages authored in `wiki-cloud/`: source summary, Robin overview, and two concept pages — all with `#p<N>|direct` provenance. The decision record `wiki-cloud/decisions/dr-2026-06-11-pdf-ingestion.md` captures the schema decisions. Index and log updated. |

**Score:** 4/4 truths verified

---

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `schema/reference/pdf-ingestion.md` | Authoritative PDF sub-case convention + acquisition runbook | VERIFIED | 89 lines; contains: format-orthogonal classification, four extraction fields, #p locator usage, tiered epistemic policy, acquisition runbook, ingest checklist |
| `bin/pdf-extract.sh` | PDF→Markdown acquisition glue | VERIFIED | 243 lines, executable; `api/generate`, `--rawfile`, `-d @`, `pdftoppm`, `pdfinfo`, `set -euo pipefail`, namespaced env vars, per-page timeout |
| `bin/lint.sh` | Conditional original_asset→*.pdf extraction-field check; LINT_VERSION 1.10.0 | VERIFIED | `LINT_VERSION="1.10.0"`, `PDF_EXTRACTION_FIELDS`, `endswith('.pdf')`, bare-filename guard — all present |
| `bin/ingest.sh` | `--asset` flag co-locating bundle asset | VERIFIED | `ASSET_FILE=""` state var, `--asset)` case, all preconditions validated before mkdir/copy; CR-01 collision guard (`ASSET_DEST = DEST_FILE`) at line 340 — verified fixed |
| `tests/phase-20/run.sh` | Aggregator listing all 5 test files | VERIFIED | `PHASE 20 TESTS` header, exactly 5 `run_test` invocations |
| `tests/phase-20/test_pdf_extract_markers.sh` | PDF-01 marker-count test, model-gated | VERIFIED | Static assertions + live-gated model probe |
| `tests/phase-20/test_pdf_extraction_fields.sh` | PDF-02 conditional-lint unit test | VERIFIED | Variants A (missing field), B (all clean), C (path component) |
| `tests/phase-20/test_pdf_convention_doc.sh` | PDF-02 convention-doc smoke | VERIFIED | Greps pdf-ingestion.md, frontmatter.md, AGENTS.md routing |
| `tests/phase-20/test_pdf_epistemic_tiers.sh` | PDF-03 epistemic-tiers grep | VERIFIED | born-digital, tentative, spot-verif, support_type direct confirmed |
| `tests/phase-20/test_ingest_asset_flag.sh` | PDF-04 --asset co-location integration | VERIFIED | Isolated temp-cwd, --contributor bypass, confirms both source.md + asset present |
| `tests/phase-20/fixtures/sample.pdf` | 2-page born-digital fixture | VERIFIED | Present; pdfinfo confirms 2 pages |
| `wiki-cloud/sources/src-2026-06-12-multi-agent-scientific-discovery.md` | Source summary with extraction fields + #p-anchored claims | VERIFIED | All 4 extraction fields; source_type: paper (not pdf); original_asset bare filename |
| `sources/2026/2026-06/2026-06-12-multi-agent-scientific-discovery/` | Dated bundle with source.md + PDF asset | VERIFIED | Both `source.md` (36 page markers) and `s41586-026-10652-y.pdf` present |
| `wiki-cloud/decisions/dr-2026-06-11-pdf-ingestion.md` | Schema-update decision record | VERIFIED | `trigger_type: schema-update`, `type: decision`, `format-orthogonal`, `extraction_date` rationale recorded |
| `schema/reference/frontmatter.md` | Four flat PDF extraction fields | VERIFIED | All four field names present with conditional OMIT note |
| `schema/workflows/ingest.md` | Pass-0 PDF pointer | VERIFIED | `pdf-ingestion.md` reference present |
| `AGENTS.md` and `CLAUDE.md` | Routing-table row for pdf-ingestion.md | VERIFIED | Both carry the row; `bin/sync-claude.sh --check` byte-equality confirmed by routing lint passing |

---

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `AGENTS.md` routing table | `schema/reference/pdf-ingestion.md` | routing-table row | WIRED | `grep -q 'pdf-ingestion.md' AGENTS.md` confirmed; routing lint exits 0 |
| `CLAUDE.md` | `AGENTS.md` | byte-equality via bin/sync-claude.sh | WIRED | Routing lint exits 0; SUMMARY confirms `cmp -s` passes |
| `schema/reference/source-types.md` | `schema/reference/pdf-ingestion.md` | Convention Doc column in section-4 pdf row | WIRED | `grep -q 'pdf-ingestion.md' source-types.md` confirmed |
| `schema/workflows/ingest.md` | `schema/reference/pdf-ingestion.md` | Pass-0 PDF sub-bullet | WIRED | `grep -q 'pdf-ingestion.md' ingest.md` confirmed |
| `bin/pdf-extract.sh` | `http://localhost:11434/api/generate` | curl POST per page with base64 image (--rawfile) | WIRED | `api/generate`, `--rawfile`, `-d @` all present in the script |
| `wiki-cloud/sources/src-2026-06-12-multi-agent-scientific-discovery.md` frontmatter | co-located PDF | `original_asset: s41586-026-10652-y.pdf` | WIRED | `original_asset` is a bare filename; PDF file exists at the bundle path |
| Claims in source summary | `sources/.../source.md` page markers | `#p<N>` locators | WIRED | `#p3`, `#p4`, `#p5`, `#p6`, `#p7` present in source summary body; 36 `<!-- page: N -->` markers in bundle source.md; post-commit audit confirmed zero `insufficient-locator` verdicts |

---

## Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `src-2026-06-12-multi-agent-scientific-discovery.md` | Extracted claims with #p<N> locators | `sources/.../source.md` page-marked Markdown produced by `bin/pdf-extract.sh` on the real 36-page PDF | Yes — 36 page markers confirmed in bundle source.md; audit-claims.sh confirmed zero insufficient-locator verdicts post-commit | FLOWING |
| `bin/lint.sh` PDF check | `original_asset` YAML field | Source frontmatter in `wiki-cloud/sources/` | Yes — check fired non-vacuously on the real PDF source and passed; confirmed by `--ci --dry-run --category yaml` exit 0 | FLOWING |

---

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Test aggregator exits 0 with 5/5 passed | `PDF_EXTRACT_SKIP_LIVE=1 bash tests/phase-20/run.sh` | `PHASE 20 TESTS: 5/5 passed, 0 skipped` | PASS |
| Scoped yaml lint exits 0 | `bash bin/lint.sh --ci --dry-run --category yaml` | `EXIT: 0`, 0 Errors, 0 Warnings | PASS |
| Routing lint exits 0 | `bash bin/lint.sh --ci --dry-run --category routing` | `EXIT: 0`, 0 Errors, 0 Warnings | PASS |
| pdf-extract.sh syntax clean | `bash -n bin/pdf-extract.sh` | Exit 0 | PASS |
| ingest.sh syntax clean | `bash -n bin/ingest.sh` | Exit 0 | PASS |
| PDF bundle contains both source.md + PDF | `ls sources/2026/2026-06/2026-06-12-multi-agent-scientific-discovery/` | `s41586-026-10652-y.pdf` and `source.md` present | PASS |
| source.md has 36 page markers | `grep -c '^<!-- page:' sources/.../source.md` | 36 | PASS |
| CR-01 collision guard (resolved destination) | `grep -n 'ASSET_DEST.*DEST_FILE' bin/ingest.sh` | Line 340: `if [ "${ASSET_DEST}" = "${DEST_FILE}" ]` | PASS |

---

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| PDF-01 | 20-01 (tooling), 20-02 (doc) | Documented PDF acquisition pipeline: olmOCR 2 via Ollama → Markdown with `<!-- page: N -->` markers | SATISFIED | `bin/pdf-extract.sh` implements the pipeline; `schema/reference/pdf-ingestion.md` documents it; both the runbook and the generic contract (D-04) are authoritative and routing-registered |
| PDF-02 | 20-02 (convention), 20-03 (enforcement) | PDF sub-case convention records extraction tool/model in frontmatter; claims use existing `#p` page locators | SATISFIED | `schema/reference/pdf-ingestion.md` defines the four flat fields; `frontmatter.md` documents them; lint enforces them; real source summary uses all four with `#p<N>` claims |
| PDF-03 | 20-02 (policy), 20-03 (test) | VLM-hallucination guidance: degraded/scanned input gets spot-verification + lower epistemic default | SATISFIED | `schema/reference/pdf-ingestion.md` Section 4 defines the tiered policy (born-digital→sourced, degraded→tentative+N=3 spot-verify); `test_pdf_epistemic_tiers.sh` mechanically verifies the policy tokens; `support_type: direct` maintained throughout |
| PDF-04 | 20-03 (tooling), 20-04 (end-to-end) | End-to-end validation: one real PDF acquired, ingested, wiki pages with page-anchored provenance, bundle convention | SATISFIED | Nature Robin paper: bundle with `source.md` (36 page markers) + `s41586-026-10652-y.pdf` co-located; four wiki-cloud pages with `#p<N>|direct` provenance; post-commit audit confirmed zero insufficient-locator verdicts; lint clean; human-verified (APPROVED-WITH-EDITS) |

**Traceability mismatch note:** REQUIREMENTS.md currently shows `PDF-01`, `PDF-02`, and `PDF-03` as "Pending" (rows 81–83), even though plans 20-01, 20-02, and 20-03 completed and delivered them. `PDF-04` shows "Complete" (row 84). The "Pending" status in the table is a bookkeeping lag — the codebase clearly satisfies all four requirements as verified above. The orchestrator should reconcile this via `phase.complete` (which will update the traceability rows to "Complete" for PDF-01/02/03).

---

## Anti-Patterns Found

| File | Pattern | Severity | Impact |
|------|---------|----------|--------|
| `bin/pdf-extract.sh` | `ls "$TMP/page-$N"-*.png` / `ls | wc -l` (SC2012) | Info | In-scope: `$TMP` is from `mktemp -d`, no spaces/newlines; functionally safe. Deferred per code-review IN-03 (not a correctness risk). |
| `bin/pdf-extract.sh` | `echo "$RESP"` (flag-sensitive on -n/-e) | Info | Deferred per code-review IN-02; Ollama always returns JSON starting with `{`, so never triggers in practice. |
| `bin/pdf-extract.sh` | `$RESP` re-parsed by `jq` 4 times per page | Info | Deferred per code-review IN-01; maintainability only, no correctness impact. |
| `bin/pdf-extract.sh` | Missing numeric validation for `--dpi` | Warning | Deferred per code-review WR-03; a non-numeric DPI produces a misleading downstream error message, not incorrect output. |

All findings in the Warning/Info tier are deferred per the 20-REVIEW.md resolution record (`c363426` fixed the BLOCKER CR-01 and the real-bug warnings WR-01/WR-02/WR-04/WR-05). None of the deferred items prevent goal achievement or produce incorrect output on the happy path.

---

## Human Verification Required

None. The Plan 04 `checkpoint:human-verify` gate was executed and returned **APPROVED-WITH-EDITS**. The user:
1. Confirmed both `source.md` (page markers) and the co-located PDF are present in the bundle.
2. Verified the source summary carries all four extraction fields and `#p<N>|direct` provenance.
3. Spot-checked cited pages against the PDF and confirmed faithful extraction.
4. Requested 11 epistemic refinements (scope claims, add preclinical framing, reframe author estimates) — all applied in commit `e9f1f86`.

The human-verify gate is closed. No further human testing is required to accept this phase.

---

## Gaps Summary

No gaps. All four success criteria are fully satisfied in the codebase:

1. The documented PDF acquisition pipeline (`schema/reference/pdf-ingestion.md` + `bin/pdf-extract.sh`) exists, is routing-registered, is tool-agnostic (D-04), and produces `<!-- page: N -->` marker-aligned Markdown ready for standard ingest.
2. The real source summary records `extraction_tool`, `extraction_model` (actual model used, not the plan-named tag — correctly reflecting the D-04 tool-agnostic convention), `extraction_date`, and `original_asset`; every claim uses `#p<N>` page locators with `support_type: direct`.
3. The convention explicitly mandates tentative epistemic status and N=3 spot-verification for degraded/scanned input; the failure mode (confident VLM hallucination) is documented in prose.
4. One real PDF (36-page Nature Robin paper) is acquired, ingested, in `sources/` as a bundle with the co-located PDF, and has four interlinked wiki-cloud pages with `#p<N>|direct` provenance — all verified by the post-commit audit and human checkpoint.

The CR-01 data-loss bug (BLOCKER from code review) was fixed in commit `c363426` before this verification was written; the collision guard now keys on the resolved destination path (`ASSET_DEST = DEST_FILE`), not just the literal `source.md` basename.

---

_Verified: 2026-06-12T00:00:00Z_
_Verifier: Claude (gsd-verifier)_
