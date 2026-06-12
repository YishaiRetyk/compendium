---
id: dr-2026-06-11-pdf-ingestion
title: "PDF as Format-Orthogonal Source Sub-Case + First Local-Model Acquisition Script"
type: decision
status: active
summary: "Records that PDF is a format-orthogonal acquisition-path sub-case (not a new source_type), specified in a lazy-loaded authoritative pdf-ingestion.md with a lean registry pointer, four flat extraction frontmatter fields under conditional lint enforcement, a tiered VLM-hallucination epistemic policy that keeps support_type direct, and bin/pdf-extract.sh as the first repo script to invoke a local model."
created_at: 2026-06-11
updated_at: 2026-06-12
sources: []
epistemic_status: sourced
tags:
  - meta
  - schema
domains:
  - wiki-infrastructure
supersedes: null
superseded_by: null
aliases:
  - dr-2026-06-11-pdf-ingestion
has_contradictions: false
knowledge_domain: software
trigger_type: schema-update
affected_pages: []
---

# PDF as Format-Orthogonal Source Sub-Case + First Local-Model Acquisition Script

## TL;DR

Phase 20 treats PDF as a **format-orthogonal acquisition-path sub-case**, not a new `source_type`: content is classified to its parent type (article / paper / data / ...) and the PDF convention layers on top via four flat extraction frontmatter fields (conditionally lint-enforced), the existing `#p` locator, and a tiered epistemic policy for VLM hallucination that keeps `support_type` `direct`. The convention lives in a lazy-loaded authoritative `schema/reference/pdf-ingestion.md`; acquisition ships as `bin/pdf-extract.sh`, the first repo script to invoke a local model.

## Decision

Phase 20 introduced five coupled deliverables:

**1. PDF is a format-orthogonal sub-case, NOT a new `source_type` (D-05).**

A PDF can carry any kind of content — an article, a paper, a data table, a journal entry — so the format describes how the bytes arrived, not what the content *is*. At Pass 0 the content is classified to its parent type exactly as if it had arrived as Markdown, and the PDF convention layers on top. Walking the 5-dimension extension contract (`schema/reference/source-types.md`), only **Acquisition** changes unconditionally and **Epistemic Default** changes conditionally (degraded scans only); Locator, Extraction Granularity, and Drift are all inherited from the parent type. Because the decision rule (a new `source_type` is justified only if it changes at least one dimension in a way a sub-case cannot absorb) is not met, adding `pdf` to the enum is an anti-pattern: it would lock content to a single parent type and erase the article/paper/data distinction the content actually carries. The provisional `pdf` registry row in `source-types.md` was finalized with this format-orthogonal verdict.

**2. Lazy-loaded authoritative doc + lean registry pointer (D-01/D-02).**

The full convention (frontmatter fields, locator usage, epistemic tiers, acquisition runbook) lives in a new authoritative `schema/reference/pdf-ingestion.md`. PDF content is not needed at Pass-0 classification time, so it must not bloat `source-types.md` (the progressive-disclosure argument that drove the v1.2 refactor). `source-types.md` carries only a one-row Evaluated-Candidates pointer to the convention doc; the runbook is never duplicated into the contract file. `pdf-ingestion.md` gets a routing-table row in AGENTS.md/CLAUDE.md (Phase 19 precedent: every authoritative `schema/reference/*.md` gets a row), validated by the `routing` lint category and kept byte-equal by `bin/sync-claude.sh`.

**3. Four flat extraction frontmatter fields + conditional lint enforcement (D-06/D-07).**

A PDF-acquired source summary carries four flat `snake_case` fields — `extraction_tool`, `extraction_model`, `extraction_date`, `original_asset` — present ONLY on PDF-acquired sources and OMITTED entirely on every other source. They are flat (not a nested YAML block) so each stays independently Dataview-queryable. Lint **requires** all four when `original_asset` points at a `*.pdf`, and requires `original_asset` to be a bare co-located filename (no directory components). "Convention-only would silently regress" (Phase 19 D-08 posture), so the check is mechanically enforced.

`extraction_date` is deliberately kept distinct from `ingested_at`: the acquisition date (when the PDF was run through the extractor) and the wiki-ingest date (when the extracted Markdown was compiled into the wiki) can legitimately differ — a PDF may be extracted weeks before it is ingested — and keeping them as two independent flat fields lets a Dataview query filter on either axis. (This closes the RESEARCH open question of whether the two should collapse: they stay separate.)

**4. Tiered epistemic policy for VLM hallucination; support_type stays direct (D-08/D-09).**

The human classifies clean-vs-degraded at acquisition time (born-digital vs scan is trivially observable, so no fragile machine heuristic is needed). Born-digital/clean input keeps the parent type's normal `sourced` default with no verification mandate. Degraded/scanned input defaults to page-level `epistemic_status: tentative` plus a mandatory spot-verification of N = 3 pages (first, middle, last), upgradeable to `sourced` only after the spot-verified pages match the co-located original. Throughout, claims keep `support_type: direct` — a PDF is a *primary* source and OCR is extraction, not derivation. The hallucination risk is carried by the page's epistemic status, never by the support type; using the `derived` type here would be an epistemic-laundering error (`derived` is reserved for genuinely secondary syntheses, per the Phase 19 contract).

**5. bin/pdf-extract.sh is the first repo script to invoke a local model (D-10/D-11).**

Acquisition ships as thin glue: `bin/pdf-extract.sh` renders each page (pdftoppm), OCRs it via a local Ollama VLM, and assembles `<!-- page: N -->` markers (positionally correct as a free side effect of the per-page loop). This is the first repo script to call a model — so `bin/ingest.sh`'s "no LLM calls" charter is explicitly **per-script, not repo-wide**. `bin/ingest.sh` gains an `--asset` flag so one invocation co-locates the original PDF alongside `source.md` in the dated bundle dir. The convention is tool-agnostic (D-04): any extractor that emits the `<!-- page: N -->` markers satisfies the pipeline; olmOCR 2 via Ollama is the named worked instance.

## Why

The framing adopted is **format-orthogonality**: acquisition format is a dimension that cuts across the content-type taxonomy rather than a member of it. This replaces the naive framing that "a PDF is a kind of source" (which would have produced a `pdf` `source_type`). The naive framing fails because it conflates transport with content: it cannot answer "is this PDF an article or a paper?" without a second classification axis anyway, so it is strictly worse than classifying the content directly and recording the format in orthogonal metadata.

The epistemic design defends against the VLM-OCR hallucination failure mode (`vlm-ocr-hallucination`): vision-language models can emit plausible-but-wrong text with high fluency on degraded input. The mechanical defense is the human clean/degraded call plus the tentative-default-and-spot-verify gate for scans — expressed entirely through epistemic status so the support-type semantics (`direct` = primary, `derived` = secondary) stay clean.

## Alternatives Considered

**`source_type: pdf` (new enum value).** Rejected: locks content to a single parent type, erases the article/paper/data distinction, and fails the extension-contract decision rule (format changes only acquisition unconditionally). It would also force every downstream query that means "papers" to special-case PDFs.

**Nested extraction YAML block.** Rejected: a nested `extraction: { tool, model, date }` block is not independently Dataview-queryable per field and conflicts with the no-blob-in-frontmatter rule. Flat fields win.

**Collapse `extraction_date` into `ingested_at`.** Rejected: acquisition and ingest dates can legitimately differ; collapsing them loses a queryable axis for no real simplification.

**`support_type: derived` for OCR-extracted claims.** Rejected as epistemic laundering: OCR is extraction of a primary source, not synthesis across sources. Hallucination risk belongs in epistemic status, not support type.

**Folding the runbook into `source-types.md`.** Rejected: re-bloats the always-relevant contract file with content only needed at acquisition time, against the progressive-disclosure principle. The lazy-loaded `pdf-ingestion.md` + one-row pointer is the chosen shape.

## Consequences

- `schema/reference/pdf-ingestion.md` is the new authoritative convention doc, routing-registered in AGENTS.md/CLAUDE.md.
- `bin/lint.sh` enforces the four extraction fields conditionally on `original_asset=*.pdf` and requires a bare co-located `original_asset` filename (LINT_VERSION 1.10.0). The check was proven non-vacuously by the PDF-04 validation ingest — it now fires and passes on a real PDF source.
- `bin/pdf-extract.sh` establishes that the "no LLM calls" charter is per-script; the milestone's "at most thin glue" constraint is honored. The extraction tool is recorded in frontmatter, so the convention survives tool substitution — during the PDF-04 validation, the olmOCR-2 weights were served via a newer Ollama engine (model tag `hf.co/bartowski/allenai_olmOCR-2-7B-1025-GGUF:Q4_K_M`) because the originally-named packaging `richardyoung/olmocr2:7b-q8` is broken under Ollama ≤0.20.x (llama.cpp-runner M-RoPE incompatibility); the GGUFs require Ollama ≥0.30. D-04's tool-agnostic contract covers this: the wiki records the model actually used.
- This DR aids Phase 21 (video ingestion), which inherits the same format-orthogonal sub-case pattern (transcript parent type + a `#t` locator + an external acquisition tool).

## Affected Pages

None. This is an infrastructure decision record (cf. `dr-2026-06-08-skills-overlay.md`, `affected_pages: []`). It documents a schema convention rather than restructuring existing content pages; the `wiki-cloud/index.md` Decisions-section entry is catalog registration, not a `decision_history` backlink.

## Sources

- `schema/reference/pdf-ingestion.md` — the authoritative PDF sub-case convention and acquisition runbook.
- `schema/reference/source-types.md` — the 5-dimension extension contract whose decision rule classifies PDF as a sub-case.
- `.planning/phases/20-pdf-ingestion/20-CONTEXT.md` — the D-01..D-12 implementation decisions summarized here.
