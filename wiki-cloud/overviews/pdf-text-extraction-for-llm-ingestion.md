---
id: pdf-text-extraction-for-llm-ingestion
title: "PDF-to-Text Extraction for LLM Ingestion"
type: overview
status: active
summary: "The 2025–2026 landscape for turning PDFs into clean Markdown for LLM and
  knowledge-base ingestion: a three-camp taxonomy (traditional OCR, pipeline tools,
  VLM-OCR), the extraction-vs-native-vision paradigm debate, benchmarks, per-page
  cost across self-hosted and commercial tiers, and a concrete pipeline recommendation."
created_at: 2026-06-09
updated_at: 2026-06-09
sources:
- src-2026-06-09-pdf-to-text-llm-ingestion-sota
epistemic_status: mixed
tags:
- pdf-extraction
- ocr
- document-ai
- vlm
- markdown
- llm-ingestion
domains:
- document-ai
- ocr
- software
supersedes: null
superseded_by: null
aliases:
- "PDF-to-Text Extraction for LLM Ingestion"
- "PDF-to-Markdown Extraction"
- "pdf-text-extraction-for-llm-ingestion"
has_contradictions: false
knowledge_domain: software
example: false
---

## TL;DR

Turning PDFs into clean Markdown for LLM ingestion in 2025–2026 splits into three camps: traditional OCR pipelines (Tesseract/PaddleOCR), specialized document-parsing pipeline tools ([[mineru|MinerU]], [[marker|Marker]], Docling), and VLM-based parsers ([[olmocr|olmOCR]], GLM-OCR, PaddleOCR-VL, plus general Gemini/GPT/Claude vision). VLM-OCR now leads the [[omnidocbench|OmniDocBench]] leaderboard by folding detection, recognition, and post-processing into one forward pass, but pipeline tools still win on standard documents while VLMs generalize better to slides, handwriting, and unconventional formats. The two competing paradigms — extraction/OCR-to-Markdown pipelines vs native multimodal vision ingestion — are contrasted in [[ocr-pipeline-vs-vlm-ingestion|OCR Pipeline vs VLM Ingestion]]. The strongest self-hosting pick is olmOCR 2; commercial APIs are cheap and win on SLA/compliance but hold no decisive accuracy edge. The defining reliability risk of the native-vision path is [[vlm-ocr-hallucination|VLM OCR Hallucination]].

## Key Facts

- The field has three camps in 2025–2026 — traditional OCR pipelines, specialized document-parsing pipeline tools, and VLM-based parsers — with VLM-OCR topping OmniDocBench via a single-forward-pass design; traditional OCR survives for CPU-only, air-gapped, deterministic, and clean high-throughput scans. [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:three-camps|derived|2026-06-09] [epistemic:: sourced]
- Pipeline tools (e.g. MinerU) beat general VLMs on standard documents (papers, financial reports); general VLMs generalize better to slides and handwriting — on English text-recognition edit distance MinerU leads at 0.15 over GPT-4o (0.233) and Marker (0.336). [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:three-camps|derived|2026-06-09] [epistemic:: tentative]
- The strongest self-hosting recommendation is olmOCR 2 (open Qwen2.5-VL-7B fine-tune): 82.4 on olmOCR-Bench, Markdown with equations/tables/handwriting, ~10,000 pages for under $2 on one H100. [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:olmocr|derived|2026-06-09] [epistemic:: tentative]
- Commercial APIs cluster cheap (Textract/Azure/Google DocAI $0.0015–0.05/pg; Mistral OCR ~$0.001–0.002/pg) and win on SLA, compliance, region, and audit logs — but open-weight VLM OCR can match or beat them on public benchmarks and is cheaper at scale. [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:commercial|derived|2026-06-09] [epistemic:: sourced]
- The native-vision paradigm's defining risk is hallucination: VLMs default to linguistic priors on degraded images, producing plausible-but-wrong text rather than flagging unreadability. [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:hallucination-caveat|derived|2026-06-09] [epistemic:: sourced]

## Detail

### The three camps

Document-to-text tooling in 2025–2026 falls into three groups. Traditional OCR pipelines (Tesseract, EasyOCR, classic PaddleOCR) run detection, recognition, and post-processing as separate stages. Specialized document-parsing pipeline tools (MinerU, Marker, Docling) wrap layout models and OCR into a Markdown-emitting pipeline. VLM-based parsers (olmOCR, GLM-OCR, PaddleOCR-VL, dots.ocr, and general multimodal models) fold the whole job into a single forward pass [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:three-camps|derived|2026-06-09]. VLM-OCR has displaced the traditional three-stage pipeline for complex document understanding and now leads OmniDocBench, while traditional OCR remains relevant mainly for CPU-only, air-gapped, deterministic, and simple high-throughput scans (and as a cheap first pass in hybrid cost-tier pipelines) [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:three-camps|derived|2026-06-09] [epistemic:: sourced].

The general-VLM-vs-traditional-pipeline tradeoff is documented on OmniDocBench: pipeline tools like MinerU win on standard documents (academic papers, financial reports) while general VLMs generalize better to specialized formats (slides, handwritten notes). On overall text-recognition edit distance (lower is better), MinerU leads English at 0.15 over GPT-4o (0.233) and Marker (0.336); for Chinese, Qwen2-VL-72B (0.327) and MinerU (0.357) lead over GPT-4o (0.399) and Marker (0.556) [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:three-camps|derived|2026-06-09] [epistemic:: tentative]. This is a snapshot; the broader 2026 landscape has shifted toward specialized VLM-OCR models leading overall.

### The two paradigms

Two approaches compete for the same Markdown output: extraction/OCR-to-Markdown pipelines (deterministic, structured, cheap, strong on standard layouts, but brittle on unseen layouts with multi-stage error compounding) and native multimodal VLM ingestion (generalizes to messy/novel formats with one model, but hallucinates on degraded input). The full side-by-side is in [[ocr-pipeline-vs-vlm-ingestion|OCR Pipeline vs VLM Ingestion]].

### Tiers: self-hosted and commercial

On the self-hosted tier, olmOCR 2 is the headline pick, with Marker and MinerU as first-choice open document-parsing pipeline tools (Dolphin and MarkItDown as supplements; Docling increasingly favored for enterprise RAG). Self-hosted open-source VLM OCR is dramatically cheaper at scale — olmOCR processes ~1M pages for ~$190 (about 1/32 the cost of GPT-4o batch APIs); its FP8-quantized model reaches 3,400 output tokens/sec on a single H100, ~10,000 pages for under $2 [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:self-hosted|derived|2026-06-09] [epistemic:: tentative].

On the commercial tier, document-processing APIs cluster cheap: Amazon Textract $0.0015–0.05/pg, Azure Document Intelligence $0.0015–0.03/pg, Google Document AI $0.0015–0.03/pg, Mistral OCR ~$0.001–0.002/pg with batch at half price (Mistral OCR processes up to 2000 pages/minute on a single node) [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:commercial|derived|2026-06-09] [epistemic:: tentative]. Commercial APIs buy SLA, SOC2/compliance, region/data-residency, audit logging, and RBAC/SSO — not a decisive accuracy edge, since open-weight VLM OCR can match or beat them on public benchmarks [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:commercial|derived|2026-06-09] [epistemic:: sourced]. Vendor self-reported accuracy numbers were the least trustworthy claim class in the underlying research (three were refuted in verification) and should be discounted.

### Recommended pipeline

For a Markdown knowledge-base ingestion pipeline spanning all document types: start with a deterministic extractor (PyMuPDF/pdfplumber) for born-digital text layers — free, fast, no hallucination — and escalate only when layout is complex; use self-hosted olmOCR 2 as the workhorse for complex layouts, scans, math, tables, and footnotes (best accuracy-per-dollar, keeps data local, native Markdown); fall back to MinerU/Marker locally or a cheap commercial API for cloud-safe sources when no GPU is available; add a reliability guardrail — flag low-confidence pages for review or cross-check against a deterministic OCR pass — to mitigate VLM hallucination; and verify chart/graph-derived numbers manually, since charts remain the weakest area across all tools [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:recommendations|derived|2026-06-09] [epistemic:: inferred].

### Caveats

This field moves monthly: benchmark-leaderboard positions and per-page prices are volatile, several headline numbers rest on first-party (Ai2) or aggregator sources, and self-hosted cost figures are marginal GPU-compute estimates excluding hardware amortization. Docling and the commercial premium parsers (LlamaParse, Reducto, Unstructured) were in scope but no verified accuracy/cost claims survived for them — a follow-up gap.

## Related Pages

- [[ocr-pipeline-vs-vlm-ingestion|OCR Pipeline vs VLM Ingestion]] — the two competing extraction paradigms, side by side.
- [[olmocr|olmOCR]] — the headline self-hostable VLM-OCR recommendation.
- [[omnidocbench|OmniDocBench]] — the standard benchmark underpinning the accuracy claims.
- [[vlm-ocr-hallucination|VLM OCR Hallucination]] — the native-vision paradigm's defining reliability failure mode.
- [[mineru|MinerU]] — pipeline tool leading on standard documents (page not yet written).
- [[marker|Marker]] — first-choice open PDF-to-Markdown pipeline tool (page not yet written).

## Sources

- [[src-2026-06-09-pdf-to-text-llm-ingestion-sota|PDF-to-Text Extraction and LLM PDF Ingestion: State of the Art (2025–2026)]]: synthesized deep-research report (2026-06-09)
