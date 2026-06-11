# PDF Ingestion

> Agent-authoritative reference for the PDF-as-sub-case convention and the PDF-to-Markdown acquisition runbook.
> The AGENTS.md routing table points here. If you find a discrepancy between this file and AGENTS.md, this file wins.

Use this file when acquiring a PDF source (running the extraction runbook), authoring the source summary for a PDF-acquired source, or deciding the epistemic status of claims drawn from extracted PDF text.

## 1. Classification — PDF Is a Format-Orthogonal Sub-case

PDF is a **format-orthogonal acquisition-path sub-case**, NOT a `source_type` enum value (D-05). A PDF can carry any kind of content — an article, a paper, a data table, a journal entry — so the format tells you how the bytes arrived, not what the content *is*.

At Pass 0 the content is classified normally to its **parent type** (`article` / `paper` / `data` / ...) exactly as it would be if the same content had arrived as Markdown. The PDF convention then *layers on top* of that classification. Walking the 5 dimensions of the extension contract (`schema/reference/source-types.md`):

| Dimension | Effect of the PDF format |
|-----------|--------------------------|
| **Acquisition** | Changes **unconditionally** — the source is obtained by running a PDF-to-Markdown extractor (the runbook below) rather than downloading or copy-pasting Markdown. |
| **Locator** | **Unchanged** — `#p<N>` page locators already exist (`schema/reference/provenance.md`); the extractor emits the `<!-- page: N -->` markers they resolve against. |
| **Extraction Granularity** | **Unchanged** — inherited from the parent type. |
| **Drift** | **Unchanged** — inherited from the parent type (a born-digital PDF is static like any downloaded document). |
| **Epistemic Default** | Changes **conditionally** — only for *degraded* input (scans). Born-digital PDFs keep the parent type's default. See the Tiered Epistemic Policy section below. |

Because only one dimension changes unconditionally (Acquisition) and one conditionally (Epistemic Default), PDF does **not** earn a new `source_type` enum value. Adding `pdf` to the 7-value enum is an anti-pattern (D-05): it would lock content to a single parent type and erase the article/paper/data distinction the content actually carries.

## 2. Frontmatter Fields (PDF-acquired Sources Only)

A source summary acquired from a PDF carries four flat `snake_case` fields, present **ONLY** on PDF-acquired sources and OMITTED entirely on every other source (D-06):

| Field | Meaning |
|-------|---------|
| `extraction_tool` | The extractor that emitted the page markers. olmOCR is the worked instance (`extraction_tool: olmocr`). |
| `extraction_model` | The model tag, e.g. `richardyoung/olmocr2:7b-q8`. |
| `extraction_date` | ISO 8601 date the PDF was extracted. |
| `original_asset` | A bare co-located filename in the bundle (e.g. `original.pdf`) — never a path with directory components. |

These are flat, not a nested YAML block, so each stays independently Dataview-queryable (D-06).

**Why `extraction_date` is distinct from `ingested_at`:** the acquisition date (when the PDF was run through the extractor) and the wiki-ingest date (when the extracted Markdown was compiled into the wiki) can legitimately differ — a PDF may be extracted weeks before it is ingested. Keeping them as two flat fields lets a Dataview query filter on either axis independently. This decision is locked from this wave forward (the decision record in the tooling plan restates it).

Lint **requires** all four fields when `original_asset` points at a `*.pdf` (D-07). The conditional check lands with the tooling plan; the field contract is authoritative here.

## 3. `#p` Locator Usage

Claims from PDF sources use the existing `#p<N>` page locators, which resolve against the `<!-- page: N -->` markers the acquisition emits — see `schema/reference/provenance.md` (Locator Types + Page-marker convention). Do not redefine the grammar; this convention only specifies that the extractor produces those markers as a side effect of the per-page extraction loop.

Claims keep `support_type: direct` (D-09). A PDF is a **primary** source: OCR is *extraction*, not *derivation*, so the support type stays direct. The hallucination risk of extracted text is carried by the page's `epistemic_status`, NEVER by the support type. The derived support type is reserved for genuinely secondary sources (synthesis across sources), and using it here would be an epistemic-laundering error.

## 4. Tiered Epistemic Policy (PDF-03)

The **human classifies clean-vs-degraded at acquisition time** — born-digital vs scanned is trivially observable, so no fragile machine heuristic is needed (D-08).

- **Born-digital / clean** → the parent type's normal `sourced` default. No verification mandate.
- **Degraded / scanned** → page-level `epistemic_status: tentative` by default, plus a **mandatory spot-verification of N = 3 pages**: the **first page, a middle page, and the last page** (this selection catches header/body/footer extraction drift across the document). A degraded source upgrades from `tentative` to `sourced` only after the spot-verified pages match the co-located original.

Spot-verification is **read-only**: read the N pages against the co-located `original_asset` PDF, or resolve `#p<N>` via `bin/audit-claims.sh` (no new audit machinery is introduced). If pointing at the relevant local wiki context is useful, use the abstract placeholder form `wiki-cloud/concepts/<concept-slug>.md`.

**The failure mode this defends against:** VLM-based OCR can emit plausible-but-wrong text with high fluency on degraded input — a confident hallucination that reads naturally yet does not match the page. The `tentative` default + spot-verification mandate is the mechanical defense; the support type stays direct throughout.

## 5. Acquisition Runbook

**Generic contract (D-04):** any PDF-to-Markdown extractor that emits the `<!-- page: N -->` markers satisfies the pipeline. The convention is tool-agnostic; the worked instance below is one concrete realization.

**Worked instance:** olmOCR 2 via Ollama, model tag `richardyoung/olmocr2:7b-q8`, run via `bin/pdf-extract.sh`, recommended per the local wiki's PDF-extraction tooling overview (`wiki-cloud/overviews/<overview-slug>.md`).

**Pipeline reality:** Ollama takes images, not PDFs. The extraction loop is therefore:

1. `pdftoppm` renders each PDF page to an image.
2. A per-page model call extracts that page's text.
3. Marker assembly stitches the per-page outputs together, prepending `<!-- page: N -->` to each (markers come free and positionally correct from the loop).

**Prerequisites:** poppler (`pdftoppm` / `pdfinfo`), a reachable Ollama server, `jq`, and `base64`.

**Operational notes:**
- The FIRST page's model call includes the cold model load and can exceed the default `PDF_EXTRACT_TIMEOUT=300` on a slow host. Raise the env override rather than reading the wait as a hang.
- The pipeline uses GNU `base64 -w0`, so the runbook targets GNU coreutils / Linux. macOS would need a portability shim (out of scope).

## 6. Ingest Checklist

1. Run `bin/pdf-extract.sh <input.pdf>` to produce the marked-up Markdown (`<!-- page: N -->` markers included).
2. Run `bin/ingest.sh --asset <input.pdf> <extracted.md>` to co-locate the original PDF alongside `source.md` in the bundle.
3. Author the source summary with `source_type` = the content's **parent** type (article / paper / data / ...) plus the four `extraction_*` / `original_asset` fields (see the Frontmatter Fields section).
4. Claims use `#p<N>` locators with `support_type: direct`.
5. If the input is degraded → page-level `tentative` + spot-verify N pages (see the Tiered Epistemic Policy section); otherwise → `sourced`.

## See Also

- `schema/reference/source-types.md`
- `schema/reference/frontmatter.md`
- `schema/reference/provenance.md`
- `schema/workflows/ingest.md`
