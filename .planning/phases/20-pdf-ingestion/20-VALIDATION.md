---
phase: 20
slug: pdf-ingestion
status: ready
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-11
---

# Phase 20 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash test scripts under `tests/phase-20/` (per-phase `run.sh` aggregator + `lib.sh`; pattern from Phases 07-18) |
| **Config file** | none — Wave 0 (Plan 01 Task 0) clones `tests/phase-18/{run.sh,lib.sh}` into `tests/phase-20/` |
| **Quick run command** | `bash tests/phase-20/run.sh` (after Wave 0) |
| **Full suite command** | `bash tests/phase-20/run.sh && bash bin/lint.sh --ci && bash bin/check-neutrality.sh && bash bin/sync-claude.sh --check` |
| **Estimated runtime** | ~15 seconds (model-gated extraction test SKIPs when Ollama unreachable) |

---

## Sampling Rate

- **After every task commit:** Run `bash bin/lint.sh --ci` (or `--ci --category` subset — default mode always exits 0; only --ci/--strict are exit-code-meaningful) + the relevant `tests/phase-20/test_*.sh`
- **After every plan wave:** Run `bash tests/phase-20/run.sh` + `bash bin/sync-claude.sh --check` + `bash bin/check-neutrality.sh`
- **Before `/gsd-verify-work`:** `bin/lint.sh --ci` exits 0 + `tests/phase-20/run.sh` reports 5/5 passed, 0 skipped + PDF-04 human checkpoint signed off
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 20-01-00 | 01 | 1 | PDF-01 | — | N/A (test scaffold) | scaffold | `bash -n tests/phase-20/run.sh` | ❌ W0 | ⬜ pending |
| 20-01-01 | 01 | 1 | PDF-01 | T-20-01/02/04 | quoted paths; jq -n JSON escaping; Ollama preflight probe; localhost-only | smoke | `bash -n bin/pdf-extract.sh && bash bin/check-neutrality.sh` | ❌ W0 | ⬜ pending |
| 20-01-02 | 01 | 1 | PDF-01 | — | model-gated; skip-not-fail | integration | `bash tests/phase-20/test_pdf_extract_markers.sh` | ❌ W0 | ⬜ pending |
| 20-02-01 | 02 | 1 | PDF-01/02/03 | T-20-05 | placeholders only; neutrality gate | content grep | `bash tests/phase-20/test_pdf_convention_doc.sh` + `bash bin/check-neutrality.sh` | ❌ W0 | ⬜ pending |
| 20-02-02 | 02 | 1 | PDF-02 | T-20-05 | enum untouched; lint green | smoke | `bash bin/lint.sh --ci` | ✅ | ⬜ pending |
| 20-02-03 | 02 | 1 | PDF-01 | T-20-06/07 | CLAUDE.md byte-sync; routing path validated | smoke | `bash bin/sync-claude.sh --check && bash bin/lint.sh --ci --category routing` | ✅ | ⬜ pending |
| 20-03-01 | 03 | 2 | PDF-02 | T-20-09 | conditional check; str-guard; no eval | unit | `bash tests/phase-20/test_pdf_extraction_fields.sh` | ❌ W0 | ⬜ pending |
| 20-03-02 | 03 | 2 | PDF-04 | T-20-08 | basename strips traversal; existence check | integration | `bash tests/phase-20/test_ingest_asset_flag.sh` | ❌ W0 | ⬜ pending |
| 20-03-03 | 03 | 2 | PDF-02/03/04 | T-20-10 | mktemp isolation; real tree untouched | aggregate | `bash tests/phase-20/run.sh` (5/5) | ❌ W0 | ⬜ pending |
| 20-04-02 | 04 | 3 | PDF-04 | T-20-11/12 | cloud-safe verified; audit resolves #p (scoped, no insufficient-locator) | manual + audit | `bash bin/lint.sh --ci && bash bin/audit-claims.sh` (content-asserted) | partial (human-gated) | ⬜ pending |
| 20-04-03 | 04 | 3 | PDF-04 | T-20-13 | valid trigger_type; lint green | smoke | `bash bin/lint.sh --ci` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Wave 0 is folded into Plan 01 Task 0 + Task 2 and Plan 03 Task 3 (the test files Plan 03 owns are referenced by the aggregator Plan 01 creates, so no later plan edits `run.sh`):

- [ ] `tests/phase-20/run.sh` + `tests/phase-20/lib.sh` — aggregator + helpers (Plan 01 Task 0; clone `tests/phase-18/`)
- [ ] `tests/phase-20/fixtures/.gitkeep` — fixture dir (Plan 01 Task 0)
- [ ] `tests/phase-20/test_pdf_extract_markers.sh` — PDF-01, model-gated (Plan 01 Task 2)
- [ ] `tests/phase-20/test_pdf_extraction_fields.sh` — PDF-02 conditional lint (Plan 03 Task 3)
- [ ] `tests/phase-20/test_pdf_convention_doc.sh` — PDF-02 doc smoke (Plan 03 Task 3)
- [ ] `tests/phase-20/test_pdf_epistemic_tiers.sh` — PDF-03 content grep (Plan 03 Task 3)
- [ ] `tests/phase-20/test_ingest_asset_flag.sh` — PDF-04 --asset integration (Plan 03 Task 3)

Note: the model-dependent extraction assertion is gated behind a server-reachable probe (`curl -sf localhost:11434/api/tags`) PLUS a model-tag-present probe PLUS a fixture-present check — it SKIPs (exit 0) on GPU-less CI, mirroring the Phase 13.1 `blocked-on-host-runtime` precedent. Cross-AI review fix: not-yet-authored test files SKIP rather than FAIL in the aggregator, so it exits 0 at every commit — it reports `1/1 passed, 4 skipped` after Plan 01 and `5/5 passed, 0 skipped` after Plan 03. The SKIP count (not a FAIL count) is the honest Wave-0 signal; Wave-1 exit gate = lint --ci green + existing tests green individually, Wave-2 exit gate = 0 skipped.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| User supplies a clean born-digital cloud-safe PDF | PDF-04 | The validation artifact cannot be fabricated; the user picks it at execution time (D-12) | Plan 04 Task 1 `checkpoint:human-action`: confirm born-digital, cloud-safe, ~5-30 pages via `pdfinfo` + user confirmation |
| End-to-end ingest faithfulness | PDF-04 | OCR/hallucination faithfulness on real content needs a human eyeball against the original PDF | Plan 04 Task 4 `checkpoint:human-verify`: spot-check 2-3 cited `#p` pages against the original PDF; confirm bundle co-location + four extraction fields |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or are human checkpoints with Wave 0 dependencies satisfied
- [x] Sampling continuity: no 3 consecutive tasks without automated verify (every auto task has an `<automated>` block)
- [x] Wave 0 covers all MISSING references (7 test artifacts, all authored in Plan 01 + Plan 03)
- [x] No watch-mode flags (all commands are single-shot)
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-11
