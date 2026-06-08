---
id: src-2026-06-09-pdf-to-text-llm-ingestion-sota
title: "PDF-to-Text Extraction and LLM PDF Ingestion: State of the Art (2025–2026)"
type: source
status: active
summary: "Synthesized deep-research report on PDF-to-Markdown extraction and LLM
  document ingestion: a three-camp taxonomy (traditional OCR / pipeline tools /
  VLM-OCR), the extraction-vs-native-vision paradigm debate, OmniDocBench and
  olmOCR-Bench accuracy benchmarks, per-page cost across self-hosted and
  commercial tiers, the VLM hallucination failure mode, and a concrete pipeline
  recommendation. 22 of 25 sampled claims survived 3-vote adversarial verification."
created_at: 2026-06-09
updated_at: 2026-06-09
sources: []
epistemic_status: mixed
tags:
- pdf-extraction
- ocr
- document-ai
- vlm
- markdown
- llm-ingestion
- benchmarks
- olmocr
- omnidocbench
domains:
- document-ai
- ocr
- software
supersedes: null
superseded_by: null
aliases:
- "PDF-to-Text Extraction and LLM PDF Ingestion: State of the Art (2025–2026)"
- "PDF-to-Text and LLM Ingestion SOTA"
- "src-2026-06-09-pdf-to-text-llm-ingestion-sota"
has_contradictions: false
knowledge_domain: software
example: false
path: sources/2026/2026-06/2026-06-09-pdf-to-text-llm-ingestion-sota.md
content_hash: "sha256:b4ee5d61bc68de0086827e67d1aead71dff84caf89f4b6bbdc4212ef2ee13c1e"
ingested_at: 2026-06-09
source_type: article
compilation_status: compiled
compiled_against_hash: "sha256:b4ee5d61bc68de0086827e67d1aead71dff84caf89f4b6bbdc4212ef2ee13c1e"
compiled_targets:
- pdf-text-extraction-for-llm-ingestion
- ocr-pipeline-vs-vlm-ingestion
- olmocr
- omnidocbench
- vlm-ocr-hallucination
---

## TL;DR

A synthesized deep-research report (5 search angles, 21 sources fetched, 99 claims extracted, 25 adversarially verified at 3 votes each with 2/3-refute-to-kill; 22 confirmed, 3 refuted) mapping the 2025–2026 state of the art for turning PDFs into clean Markdown for LLM/knowledge-base ingestion. Core findings: the field has split into three camps — traditional OCR pipelines (Tesseract/PaddleOCR), specialized document-parsing pipeline tools (MinerU, Marker, Docling), and VLM-based parsers — with VLM-OCR now leading the OmniDocBench leaderboard by folding detection/recognition/post-processing into one forward pass. Pipeline tools still win on standard documents; VLMs generalize better to slides, handwriting, and unconventional formats. The headline self-hosting recommendation is olmOCR 2 (open Qwen2.5-VL-7B fine-tune): 82.4 on olmOCR-Bench, beats Marker (76.1) and MinerU (75.8), ~10,000 pages for under $2 on one H100. Commercial APIs are cheap and win on SLA/compliance, but open weights match or beat them on public benchmarks. A central reliability caveat: VLMs hallucinate on degraded images by defaulting to linguistic priors instead of the pixels.

## Key Takeaways

- The landscape has three camps in 2025–2026 — traditional OCR pipelines, specialized document-parsing pipeline tools, and VLM-based parsers — with VLM-OCR now topping OmniDocBench via a single-forward-pass design. [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:three-camps|direct|2026-06-09]
- Two competing paradigms target the same Markdown output: extraction/OCR-to-Markdown pipelines (deterministic, cheap, strong on standard layouts) vs native multimodal VLM ingestion (generalizes to messy formats, but hallucinates on degraded input). [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:paradigm-comparison|direct|2026-06-09]
- olmOCR 2 is the strongest self-hosting recommendation: open weights, Markdown with equations/tables/handwriting, 82.4 on olmOCR-Bench, ~10,000 pages for under $2 on one H100. [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:olmocr|direct|2026-06-09]
- Commercial APIs cluster cheap ($0.0015–0.05/pg for Textract/Azure/Google DocAI; ~$0.001–0.002/pg for Mistral OCR) and win on SLA, compliance, region, and audit logs — but not on a decisive accuracy edge. [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:commercial|direct|2026-06-09]
- VLMs hallucinate on degraded scans by defaulting to linguistic priors rather than grounding in pixels — producing plausible-but-wrong text rather than flagging unreadability. This is the biggest risk of the native-vision paradigm for a provenance-sensitive wiki. [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:hallucination-caveat|direct|2026-06-09]
- Vendor self-reported accuracy numbers were the least reliable claim class: three vendor/leaderboard accuracy claims were refuted in verification and excluded. [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:refuted|direct|2026-06-09]

## Extracted Claims

### Three-camp taxonomy and paradigm shift

- By 2025–2026, VLM-based OCR has displaced traditional three-stage OCR pipelines for complex document understanding by folding detection, recognition, and post-processing into a single forward pass, and specialized document-parsing VLMs now lead the OmniDocBench leaderboard; traditional OCR (Tesseract, EasyOCR, classic PaddleOCR) remains relevant mainly for CPU-only, air-gapped, deterministic, and simple high-throughput scans. [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:three-camps|direct|2026-06-09] [epistemic:: sourced]
- On OmniDocBench, traditional pipeline tools (e.g. MinerU) outperform general VLMs on standard documents like academic papers and financial reports, while general VLMs generalize better to specialized formats like slides and handwritten notes. [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:three-camps|direct|2026-06-09] [epistemic:: sourced]
- On overall text-recognition edit distance (lower is better) MinerU leads English at 0.15 over GPT-4o (0.233) and Marker (0.336); for Chinese, Qwen2-VL-72B (0.327) and MinerU (0.357) lead over GPT-4o (0.399) and Marker (0.556). [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:three-camps|direct|2026-06-09] [epistemic:: tentative]

### OmniDocBench

- OmniDocBench is the authoritative CVPR 2025 benchmark for diverse PDF document parsing, covering ~1,651 PDF pages across ~10 document types (981 pages / 9 types in the arXiv v2 draft), with 19 layout categories, 15 attribute labels, 100k+ annotations, block- and span-level annotations, and three evaluation modes (end-to-end, task-specific, attribute-based) across text OCR, table recognition, formula recognition, layout detection, and reading order. [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:omnidocbench|direct|2026-06-09] [epistemic:: sourced]
- The 2026 OmniDocBench v1.5 leaderboard is topped by specialized document VLMs (GLM-OCR ~94.6, PaddleOCR-VL-1.5 ~94.5, MinerU2.5, Qwen3-VL, Gemini-3 Pro at the top end). [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:omnidocbench|direct|2026-06-09] [epistemic:: tentative]

### olmOCR (self-hosted)

- olmOCR is a self-hosted open-source VLM document converter (fine-tuned from Qwen2-VL-7B-Instruct; olmOCR 2 rebased on Qwen2.5-VL-7B) that outputs Markdown and handles equations, tables, and handwriting in correct reading order even for complex multi-column layouts. [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:olmocr|direct|2026-06-09] [epistemic:: sourced]
- olmOCR 2 scores 82.4 on olmOCR-Bench, outperforming Marker (76.1) and MinerU (75.8), competitive with Chandra OCR 0.1.0 (83.1) and Infinity-Parser 7B (82.5), and ahead of the Mistral OCR API (72.0); complex-layout gains: tables 84.9% (from 72.9%), multi-column 83.7% (from 77.3%), math scans 82.3% (from 79.9%). [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:olmocr|direct|2026-06-09] [epistemic:: tentative]
- olmOCR-Bench measures document-level OCR quality via ~7,010 discrete machine-checkable "fact" unit tests across seven document types (arXiv Math, Old Scans Math, Tables, Old Scans, Headers/Footers, Multi-Column, Long Tiny Text); test counts: Text Presence 721, Text Absence 823, Natural Reading Order 1061, Table Accuracy 1020, Math Formula Accuracy 3385. [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:olmocr|direct|2026-06-09] [epistemic:: sourced]
- In a human-judged pairwise study (11 researchers, 2,017 PDFs, 452 comparisons), olmOCR output was preferred over Marker in 61.3% of comparisons, over GOT-OCR in 58.6%, and over MinerU in 71.4%, with an ELO above 1800. [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:olmocr|direct|2026-06-09] [epistemic:: tentative]
- Self-hosted open-source VLM OCR is dramatically cheaper than commercial vision-LLM ingestion at scale: olmOCR processes ~1M PDF pages for ~$190 (about 1/32 the cost of GPT-4o batch APIs), and olmOCR 2's FP8-quantized model achieves 3,400 output tokens/sec on a single H100, processing ~10,000 pages for under $2. [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:self-hosted|direct|2026-06-09] [epistemic:: tentative]

### Cost, commercial tier, and open-vs-commercial

- Cloud/commercial document-processing APIs cluster at the low end of per-page cost: Amazon Textract $0.0015–0.05/pg, Azure Document Intelligence $0.0015–0.03/pg, Google Document AI $0.0015–0.03/pg, Mistral OCR ~$0.001–0.002/pg (batch at half price); Mistral OCR can process up to 2000 pages/minute on a single node. [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:commercial|direct|2026-06-09] [epistemic:: tentative]
- Marker runs free locally on consumer GPUs (3.17–5 GB VRAM), supports 90+ languages, and offers a hosted option at ~$0.004/page; an independent Sept 2025 deep-dive recommends Marker and MinerU as first-choice open-source PDF-to-Markdown tools, with Dolphin and MarkItDown as supplements. [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:self-hosted|direct|2026-06-09] [epistemic:: sourced]
- Open-weight self-hosted VLM OCR can match or beat paid commercial APIs on public document-parsing benchmarks and can be cheaper at scale, but commercial APIs may still win on SLA, compliance, region availability, and audit logs. [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:commercial|direct|2026-06-09] [epistemic:: sourced]

### Reliability caveat

- The native multimodal-LLM vision paradigm has a key reliability weakness: VLMs (GPT-4o, Claude, Gemini class) are incomplete under real-world visual degradation (blur, occlusion, low contrast) and hallucinate text by defaulting to linguistic priors instead of grounding in visual evidence, producing plausible-but-wrong OCR output rather than recognizing they cannot read the text. [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:hallucination-caveat|direct|2026-06-09] [epistemic:: sourced]

### Pipeline recommendation

- For a Markdown KB ingestion pipeline: use a deterministic extractor (PyMuPDF/pdfplumber) for born-digital text layers; escalate complex layouts/scans/math/tables to self-hosted olmOCR 2; fall back to MinerU/Marker locally or a cheap commercial API when no GPU is available; add a reliability guardrail (flag low-confidence pages, cross-check against deterministic OCR) to mitigate VLM hallucination; verify chart/graph-derived numbers manually. [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:recommendations|direct|2026-06-09] [epistemic:: inferred]

## Notes

- **Methodology:** deep-research harness — 5 search angles, 21 sources fetched, 99 claims extracted, 25 sampled for 3-vote adversarial verification (need 2/3 refutes to kill). 22 confirmed, 3 killed. Findings carried here are the confirmed set only.
- **Refuted claims (NOT findings, preserved for the provenance trail):** (1) a specific OmniDocBench end-to-end leaderboard ranking (MinerU2.5-Pro 95.75 / GLM-OCR 95.22 / Gemini 3 Pro 92.91 / Marker 78.44), refuted 1-2; (2) Mistral OCR model 2503 scoring 94.89% overall on an internal benchmark beating Google/Azure/Gemini/GPT-4o, refuted 0-3; (3) Mistral OCR 94.29% math / 96.12% tables / 98.96% scanned, refuted 1-2. Treat all vendor internal-benchmark accuracy numbers with suspicion. [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:refuted|direct|2026-06-09]
- **Time-sensitivity is the dominant caveat** — this field moves monthly; benchmark-leaderboard positions and per-page prices are volatile. Edit-distance numbers, the v1.5 leaderboard ordering, the olmOCR-Bench scores, the human-eval ELO, and the per-page price table are all marked `[epistemic:: tentative]` for this reason (and because several rest on first-party or aggregator sources), not because they are contested today.
- **First-party / vendor sourcing:** olmOCR-Bench is authored by Ai2 (olmOCR's own team), so olmOCR-vs-Marker/MinerU comparisons and the human-eval ELO are vendor-run; Chandra/Infinity scores on that bench are author-reported. Self-hosted cost/throughput figures are marginal GPU-compute estimates excluding hardware amortization.
- **Gaps:** Docling and the commercial premium parsers (LlamaParse, Reducto, Unstructured) were in scope but no verified accuracy/cost claims survived for them — candidates for a follow-up query.
- **Privacy:** `cloud_safe`. Report covers public technology and public sources; no PII or proprietary content. Single-author repo, contributor field omitted.

## Source Metadata

- **Type:** synthesized deep-research report (secondary synthesis over public web sources)
- **Produced:** 2026-06-09, via the deep-research harness
- **Source file:** `sources/2026/2026-06/2026-06-09-pdf-to-text-llm-ingestion-sota.md`
- **Content hash:** `sha256:b4ee5d61bc68de0086827e67d1aead71dff84caf89f4b6bbdc4212ef2ee13c1e`
- **Ingested:** 2026-06-09
- **Underlying primary sources (verified):** OmniDocBench (github.com/opendatalab/OmniDocBench; arXiv 2412.07626), olmOCR / olmOCR 2 (olmocr.allenai.org/blog; allenai.org/blog/olmocr-2; arXiv 2502.18443, 2510.19817; github.com/allenai/olmocr/tree/main/olmocr/bench), "Seeing is Believing? Mitigating OCR Hallucinations in Multimodal LLMs" (arXiv 2506.20168, NeurIPS 2025), Mistral OCR (mistral.ai/news/mistral-ocr, mistral.ai/pricing), Artificial Analysis OCR aggregator, CodeSOTA OCR landscape, Jimmy Song open-source PDF-to-Markdown deep-dive (Sept 2025).
