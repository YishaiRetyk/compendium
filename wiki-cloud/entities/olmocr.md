---
id: olmocr
title: "olmOCR"
type: entity
status: active
summary: "Ai2's open-source, self-hostable VLM document converter (fine-tuned from
  Qwen2-VL-7B; olmOCR 2 rebased on Qwen2.5-VL-7B) that outputs Markdown with
  equations, tables, and handwriting; the headline self-hosting recommendation for
  PDF-to-Markdown, scoring 82.4 on olmOCR-Bench."
created_at: 2026-06-09
updated_at: 2026-06-09
sources:
- src-2026-06-09-pdf-to-text-llm-ingestion-sota
epistemic_status: mixed
tags:
- olmocr
- vlm
- ocr
- pdf-extraction
- open-source
- self-hosted
- allen-ai
domains:
- document-ai
- ocr
- software
supersedes: null
superseded_by: null
aliases:
- "olmOCR"
- "olmOCR 2"
- "olmocr"
has_contradictions: false
knowledge_domain: software
example: false
---

## TL;DR

olmOCR is an open-source (Apache-2.0), self-hostable vision-language document converter from Ai2, fine-tuned from Qwen2-VL-7B-Instruct (olmOCR 2 rebased on Qwen2.5-VL-7B). It outputs Markdown — with LaTeX equations, HTML/Markdown tables, and handwriting — in correct reading order even on complex multi-column layouts, and is the strongest self-hosting recommendation for a PDF-to-Markdown pipeline. olmOCR 2 scores 82.4 on [[omnidocbench|OmniDocBench]]'s sibling benchmark olmOCR-Bench, beating [[marker|Marker]] (76.1) and [[mineru|MinerU]] (75.8), and processes ~10,000 pages for under $2 on a single H100. It is a [[ocr-pipeline-vs-vlm-ingestion|VLM-based]] parser and inherits the general VLM-OCR caution around [[vlm-ocr-hallucination|hallucination]] on degraded input.

## Key Facts

- Open-source (Apache-2.0), self-hostable via vLLM/SGLang/Docker; fine-tuned from Qwen2-VL-7B-Instruct, with olmOCR 2 rebased on Qwen2.5-VL-7B. [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:olmocr|derived|2026-06-09] [epistemic:: sourced]
- Outputs Markdown with LaTeX equations, HTML/Markdown tables, and handwriting, preserving correct reading order on complex multi-column layouts. [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:olmocr|derived|2026-06-09] [epistemic:: sourced]
- olmOCR 2 scores 82.4 on olmOCR-Bench, beating Marker (76.1) and MinerU (75.8), competitive with Chandra OCR 0.1.0 (83.1) and Infinity-Parser 7B (82.5), and ahead of the Mistral OCR API (72.0). [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:olmocr|derived|2026-06-09] [epistemic:: tentative]
- Large complex-layout gains in olmOCR 2: tables 84.9% (from 72.9%), multi-column 83.7% (from 77.3%), math scans 82.3% (from 79.9%). [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:olmocr|derived|2026-06-09] [epistemic:: tentative]
- Cheap at scale: processes ~1M pages for ~$190 (about 1/32 the cost of GPT-4o batch APIs); the FP8-quantized model reaches 3,400 output tokens/sec on a single H100, ~10,000 pages for under $2. [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:self-hosted|derived|2026-06-09] [epistemic:: tentative]

## Detail

olmOCR is built by Ai2 (Allen Institute for AI) by fine-tuning an open Qwen vision-language model; the original release used Qwen2-VL-7B-Instruct and olmOCR 2 moved its base to Qwen2.5-VL-7B. It is Apache-2.0 licensed and runs locally via vLLM, SGLang, or Docker, making it suitable for privacy-preserving, air-gapped ingestion. Output is Markdown with LaTeX equations, HTML/Markdown tables, and handwriting recognition, in correct reading order even for complex multi-column documents. Known edge-case limits include complex layered tables and occasional repeated n-grams in very small text [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:olmocr|derived|2026-06-09] [epistemic:: sourced].

On the accuracy side, olmOCR 2 scores 82.4 on olmOCR-Bench — ahead of Marker (76.1) and MinerU (75.8), competitive with Chandra OCR 0.1.0 (83.1) and Infinity-Parser 7B (82.5), and well ahead of the Mistral OCR API (72.0). Its complex-layout subscores improved substantially over the prior version: tables to 84.9%, multi-column to 83.7%, math scans to 82.3%. A newer chandra-2 (85.9) exists; the cited olmOCR 2 figures remain accurate as of mid-2026 [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:olmocr|derived|2026-06-09] [epistemic:: tentative]. In a human-judged pairwise study (11 researchers, 2,017 PDFs, 452 comparisons), olmOCR output was preferred over Marker in 61.3% of comparisons, over GOT-OCR in 58.6%, and over MinerU in 71.4%, with an ELO above 1800 [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:olmocr|derived|2026-06-09] [epistemic:: tentative].

A key sourcing caveat: olmOCR-Bench and the human evaluation are authored/run by Ai2, olmOCR's own team, so olmOCR-vs-Marker/MinerU comparisons are first-party rather than a neutral third-party arena, and the Chandra/Infinity scores reported on that bench are author-reported. The cost and throughput figures are marginal GPU-compute estimates that exclude hardware amortization. As a VLM-based parser, olmOCR also inherits the general native-vision risk of confidently hallucinating text on badly degraded scans [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:hallucination-caveat|derived|2026-06-09] [epistemic:: sourced].

## Related Pages

- [[pdf-text-extraction-for-llm-ingestion|PDF-to-Text Extraction for LLM Ingestion]] — landscape overview where olmOCR is the headline self-hosting pick.
- [[ocr-pipeline-vs-vlm-ingestion|OCR Pipeline vs VLM Ingestion]] — olmOCR sits on the native-vision (VLM) side.
- [[omnidocbench|OmniDocBench]] — the standard document-parsing benchmark; olmOCR-Bench is Ai2's sibling fact-based benchmark.
- [[vlm-ocr-hallucination|VLM OCR Hallucination]] — the reliability caveat olmOCR inherits as a VLM parser.

## Sources

- [[src-2026-06-09-pdf-to-text-llm-ingestion-sota|PDF-to-Text Extraction and LLM PDF Ingestion: State of the Art (2025–2026)]]: synthesized deep-research report (2026-06-09)
