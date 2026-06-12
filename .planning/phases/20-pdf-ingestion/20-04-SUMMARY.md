---
phase: 20-pdf-ingestion
plan: 04
subsystem: ingest
tags: [pdf, olmocr, ollama, ingest, provenance, page-markers, epistemics, drug-repurposing, nature]

# Dependency graph
requires:
  - phase: 20-01
    provides: tests/phase-20 harness + test_pdf_extract_markers.sh (page-marker contract)
  - phase: 20-02
    provides: schema/reference/pdf-ingestion.md (acquisition runbook + tiered epistemic policy), frontmatter PDF fields
  - phase: 20-03
    provides: bin/lint.sh conditional extraction-field gate (LINT_VERSION 1.10.0) + bin/ingest.sh --asset co-location flag
provides:
  - "First real PDF acquired + ingested end-to-end (PDF-04): Ghareeb et al. Nature 'A multi-agent system for automating scientific discovery' (Robin), doi:10.1038/s41586-026-10652-y"
  - "Dated bundle sources/2026/2026-06/2026-06-12-multi-agent-scientific-discovery/ holding page-marked source.md + co-located s41586-026-10652-y.pdf"
  - "Source summary + overview + 2 concept pages in wiki-cloud/, all with #p<N>-anchored provenance resolving against <!-- page: N --> markers"
  - "Decision record dr-2026-06-11-pdf-ingestion (PDF-as-format-orthogonal-sub-case + first local-model-invoking script)"
  - "Human-verification epistemic-refinement pass tightening estimate/interpretation/preclinical framing across the four Robin pages"
affects: [21-video-ingestion]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Real-PDF acquisition via local VLM served over Ollama: olmOCR-2 weights (bartowski Q4_K_M GGUF) on Ollama 0.30.7, num_ctx raised to 8192 for dense pages"
    - "Page-anchored provenance in anger: every claim carries [prov:...#p<N>|support_type|date]; #p resolves against hand-marked <!-- page: N --> boundaries in the bundle source.md"
    - "Tiered VLM-hallucination epistemic policy applied: born-digital input keeps the sourced default; author-estimate / interpretation claims downgraded per claim, not per page"
    - "Human-verify-then-refine: APPROVED-WITH-EDITS checkpoint feeds an UPDATE-class refinement pass that adjusts support_type (direct->tentative) and epistemic markers without touching #p locators"

key-files:
  created:
    - sources/2026/2026-06/2026-06-12-multi-agent-scientific-discovery/source.md
    - sources/2026/2026-06/2026-06-12-multi-agent-scientific-discovery/s41586-026-10652-y.pdf
    - wiki-cloud/sources/src-2026-06-12-multi-agent-scientific-discovery.md
    - wiki-cloud/overviews/robin-multi-agent-discovery-system.md
    - wiki-cloud/concepts/llm-agent-scientific-discovery.md
    - wiki-cloud/concepts/ai-for-drug-repurposing.md
    - wiki-cloud/decisions/dr-2026-06-11-pdf-ingestion.md
  modified:
    - wiki-cloud/index.md
    - wiki-cloud/log.md

key-decisions:
  - "Extraction environment deviated from the plan-named model: richardyoung/olmocr2:7b-q8 is broken under Ollama <=0.20.x (llama.cpp-runner M-RoPE incompatibility), so allenai olmOCR-2-7B-1025 was served via bartowski Q4_K_M GGUF on Ollama 0.30.7 over an SSH tunnel; the convention is tool-agnostic (D-04) so frontmatter records the model actually used"
  - "num_ctx raised to 8192 for the dense page 23 to clear the default 4096-token ceiling"
  - "36-page PDF sits slightly above the ~5-30-page D-12 soft range; user-approved for this validation"
  - "Original 22MB PDF ghostscript /ebook-compressed to a 12MB co-located asset (readability verified); user-approved"
  - "Human verification returned APPROVED-WITH-EDITS: claims are faithful AS reports of the Nature accelerated-article-preview but not independently/clinically validated; epistemic framing tightened accordingly"
  - "source + overview pages bumped epistemic_status sourced->mixed after the refinement (tentative + inferred claims now present); the two concept pages stayed sourced (their edits were scoping caveats on sourced claims)"

patterns-established:
  - "Author-estimate guard: efficiency/time-on-task figures from survey-derived models get support_type tentative + [epistemic:: tentative] even when directly stated, distinct from reported measurements"
  - "Interpretation-vs-measurement split: an exact measured magnitude (ABCA1 3-fold, p=2.13e-83) stays sourced while the mechanistic claim built on it is marked [epistemic:: inferred]"
  - "Scope-the-number refinement: narrow a benchmark figure to its actual experimental condition (44.5% -> 15 Crow-ablated assay proposals; Sonnet 3.7 baseline ran with no harness/data/code) rather than letting it read as a blanket rate"

requirements-completed: [PDF-04]

# Metrics
duration: ~25min
completed: 2026-06-12
---

# Phase 20 Plan 04: PDF End-to-End Validation Summary

**First real PDF acquired and ingested end-to-end (Ghareeb et al. Nature "Robin" paper) — page-marked bundle + co-located PDF asset, a source summary + overview + 2 concept pages with #p-anchored provenance, a schema-update decision record, and a human-verification pass that tightened the estimate/interpretation/preclinical epistemics across all four pages.**

## Performance

- **Duration:** ~25 min (continuation refinement + finalization; full plan spanned the prior executor's acquisition+ingest session)
- **Completed:** 2026-06-12
- **Tasks:** 4 (acquire+ingest, page authoring, decision record, human-verify checkpoint → refinement)
- **Files modified:** 9 (7 created across the bundle + wiki-cloud; index.md + log.md modified)

## Accomplishments
- Proved the entire PDF pipeline in anger on one real, user-supplied born-digital PDF: acquisition via a local olmOCR-2 VLM, page-marked Markdown, `--asset` bundle co-location, `#p`-anchored claims, and `bin/audit-claims.sh` locator resolution.
- Ingested the Nature paper into four interlinked wiki pages (source summary, Robin overview, two concept pages) plus a schema-update decision record, all cloud-safe.
- Applied a human-verification refinement pass (APPROVED-WITH-EDITS) that reframed author estimates, scoped benchmark figures to their actual experimental conditions, separated measured magnitudes from mechanistic interpretation, and added preclinical/in-vitro framing throughout — without disturbing any `#p` locator.

## Task Commits

1. **Acquire + ingest the PDF end-to-end (PDF-04)** - `b584da9` (ingest) — bundle source.md + co-located PDF, source summary, overview + 2 concept pages, all `#p<N>|direct` provenance; index + log updated.
2. **Schema-update decision record** - `16ea71e` (reflect) — dr-2026-06-11-pdf-ingestion records the PDF-as-format-orthogonal-sub-case + first local-model-invoking-script decisions.
3. **Human-verification epistemic refinement (UPDATE-class)** - `e9f1f86` (ingest) — refined claim epistemics across all four Robin pages per the APPROVED-WITH-EDITS checkpoint; index + log updated; all `#p` locators preserved.

**Plan metadata:** committed separately (docs: complete plan) with this SUMMARY + STATE/ROADMAP/REQUIREMENTS.

## Files Created/Modified
- `sources/2026/2026-06/2026-06-12-multi-agent-scientific-discovery/source.md` - page-marked extracted Markdown (`<!-- page: N -->` boundaries)
- `sources/2026/2026-06/2026-06-12-multi-agent-scientific-discovery/s41586-026-10652-y.pdf` - co-located original PDF asset (12MB, ghostscript /ebook-compressed from 22MB)
- `wiki-cloud/sources/src-2026-06-12-multi-agent-scientific-discovery.md` - source summary; extraction_* fields; `#p`-anchored Extracted Claims; epistemic_status mixed after refinement
- `wiki-cloud/overviews/robin-multi-agent-discovery-system.md` - Robin overview; epistemic_status mixed after refinement
- `wiki-cloud/concepts/llm-agent-scientific-discovery.md` - paradigm concept page (stayed sourced)
- `wiki-cloud/concepts/ai-for-drug-repurposing.md` - application concept page (stayed sourced)
- `wiki-cloud/decisions/dr-2026-06-11-pdf-ingestion.md` - schema-update decision record
- `wiki-cloud/index.md` - added the four pages + DR; refreshed source + overview to (mixed, 2026-06-12)
- `wiki-cloud/log.md` - ingest, reflect, lint, and the UPDATE refinement entries

## Decisions Made

### Extraction-environment deviation (full record)
The plan named `richardyoung/olmocr2:7b-q8` as the extraction model. That packaging is broken under Ollama ≤0.20.x due to a llama.cpp-runner M-RoPE incompatibility (the model repulled overnight per the prior pause note). The work-around, executed by the prior executor and recorded in the source frontmatter, served the `allenai olmOCR-2-7B-1025` weights via the `bartowski` `Q4_K_M` GGUF on Ollama 0.30.7 over an SSH tunnel to the GPU host. Because the PDF convention is explicitly tool-agnostic (D-04), the frontmatter records the model actually used (`hf.co/bartowski/allenai_olmOCR-2-7B-1025-GGUF:Q4_K_M`) rather than the plan-named tag. Dense figure page 23 required raising the model context window (`num_ctx: 8192`) above the default 4096-token ceiling. The 36-page document sits slightly above the ~5–30-page D-12 soft range — explicitly user-approved for this validation. The original 22 MB PDF was ghostscript `/ebook`-compressed to the co-located 12 MB asset with readability verified — also user-approved.

### Human-verification refinement pass (this continuation)
The Task-4 `checkpoint:human-verify` returned **APPROVED-WITH-EDITS**. The human verified every ingested claim against the PDF and confirmed they are substantially faithful *as claims about what the paper reports*, but not independently-validated facts beyond this Nature accelerated-article-preview. The ten requested refinements were applied across the four pages (every occurrence of each affected claim), with `#p` locators left untouched:

1. Efficiency/time-saving numbers (551 papers / 30 min / 540 human hours / ~200-fold) reframed as **author estimates**, not a controlled time-motion study; noted the paper's related ~825-references / "over 800 hours" variant; support_type on these claims changed `direct`→`tentative`.
2. The 872–937 human-hours → <2 hours figure reframed as the authors' time-on-task **estimate**, not measured replacement of real researchers.
3. Cost "45 Crow + 30 Falcon ≈ $10.76" caveated: valid for the stated configuration; **Finch excluded** (authors treat its cost as negligible).
4. "151 papers → ten mechanisms → 30 candidates" given the missing nuance: after the 151-paper mechanism step, Robin also reviewed **~400 papers** on RPE phagocytosis / dry AMD *before* proposing the 30 candidates.
5. ABCA1 "3-fold, adjusted p = 2.13×10⁻⁸³" kept exact; the mechanism/"linking" phrasing reframed as the **paper's mechanistic interpretation**, not proven causality (`[epistemic:: inferred]`).
6. Ripasudil "1.89-fold, approved in Japan, outperformed Y-27632" kept; "favorable" safety softened to **relative to Y-27632**, not absolute.
7. KL001 novelty kept, phrased as **"to the authors' knowledge."**
8. Crow / o4-mini "44.5% hallucinated references" **scoped** to the 15 Crow-ablated assay proposals where Crow produces final reports — not a blanket Robin rate.
9. Finch on BixBench "22.8% vs Sonnet 3.7 1.6%": added the caveat that the base Sonnet 3.7 condition had **no agent harness, no data access, no code execution** — not a clean same-model-minus-tools comparison.
10. Deep Research baseline **scoped**: a June 2025 ChatGPT Deep Research run on the same candidate-generation prompt, 17 unique candidates after de-duplication, none of which were hits in the RPE-SC assay.
11. General: all dAMD therapeutic findings framed as **preclinical / in-vitro** results reported by this preprint, not clinically validated.

Page-level: `epistemic_status` bumped `sourced`→`mixed` on the source summary and the Robin overview (they now carry tentative + inferred claims); the two concept pages stayed `sourced` (their edits were scoping caveats on otherwise-sourced claims). Index entries for the two reclassified pages updated to `(mixed, 2026-06-12)`. The refinement was logged as one structured `UPDATE` entry and committed as one logical operation.

## Deviations from Plan

The extraction-environment substitution (broken plan-named model → working GGUF on a newer Ollama, num_ctx bump, 36-page/22MB→12MB approvals) is documented above. It was handled under the plan's tool-agnostic D-04 latitude and explicit user approvals during the prior executor's session, not as scope creep. No code deviations in this continuation; the refinement pass is the planned outcome of the human-verify checkpoint.

**Total deviations:** 1 environment substitution (model packaging + context-window + size, all user-approved).
**Impact on plan:** None on the deliverable — PDF-04 acquired, ingested, page-anchored, audit-verified, and human-validated as intended.

## Issues Encountered
- The plan-named `richardyoung/olmocr2:7b-q8` model would not run (M-RoPE incompatibility under old Ollama). Resolved by serving the `allenai olmOCR-2-7B-1025` weights as a `bartowski Q4_K_M` GGUF on Ollama 0.30.7 (documented above).
- Dense page 23 truncated at the default 4096-token context; resolved by `num_ctx: 8192`.
- The source-scoped audit reports `insufficient` (semantic-confidence) verdicts but **zero `insufficient-locator`** verdicts — every `#p` locator resolves against the page markers. The `insufficient` verdicts are the review-only audit's confidence category and do not block.

## Verification Gates (re-run after the refinement)
- `bash bin/lint.sh --ci --dry-run --category yaml` → **exit 0**, 0 findings.
- `bash bin/lint.sh --ci --dry-run --category crossref` → 18 errors, all pre-existing and on unrelated pages (bounded-context / comprehension-debt / programming-as-theory-building cluster); **no new** crossref errors on the four Robin pages.
- `bash bin/check-sources-cloud-safe.sh` → **exit 0** (26 files checked).
- `bin/validate-op.sh UPDATE <source page>` → **PASS** (5/5 checks).
- Source-scoped audit (`--since 59dd5fa --sample 100`): `[ ... insufficient-locator ] | length == 0` → **true**. All `#p` locators still resolve.

## User Setup Required
None - the PDF was supplied by the user at the Task-4 human-action checkpoint and acquisition was performed against a user-provided local Ollama host. No further external configuration required.

## Next Phase Readiness
- PDF-04 complete: the format-orthogonal PDF sub-case is now validated end-to-end with a real artifact, page-anchored provenance, and human-verified epistemics.
- Phase 21 (video/YouTube ingestion) inherits the format-orthogonal acquisition pattern, the page/timestamp-locator precedent, and the author-estimate / interpretation-vs-measurement epistemic guards established here.

---
*Phase: 20-pdf-ingestion*
*Completed: 2026-06-12*

## Self-Check: PASSED

All claimed files exist on disk (bundle source.md + co-located PDF, the four wiki-cloud pages, the decision record, and this SUMMARY). Commits `b584da9` (ingest), `16ea71e` (reflect), and `e9f1f86` (refinement UPDATE) are present in the git log.
