---
id: omnidocbench
title: "OmniDocBench"
type: entity
status: active
summary: "The authoritative CVPR 2025 benchmark for diverse PDF document parsing —
  ~1,651 pages across ~10 document types with block- and span-level annotations and
  three evaluation modes spanning text OCR, tables, formulas, layout, and reading
  order; the standard reference for PDF-to-Markdown accuracy claims."
created_at: 2026-06-09
updated_at: 2026-06-09
sources:
- src-2026-06-09-pdf-to-text-llm-ingestion-sota
epistemic_status: mixed
tags:
- omnidocbench
- benchmark
- document-ai
- ocr
- pdf-extraction
- cvpr-2025
domains:
- document-ai
- ocr
- software
supersedes: null
superseded_by: null
aliases:
- "OmniDocBench"
- "omnidocbench"
has_contradictions: false
knowledge_domain: software
example: false
---

## TL;DR

OmniDocBench is the authoritative CVPR 2025 benchmark for diverse PDF document parsing, used as the standard reference for PDF-to-Markdown accuracy. It covers ~1,651 PDF pages across ~10 document types (981 pages / 9 types in the earlier arXiv v2 draft) with block- and span-level annotations and three evaluation modes — end-to-end, task-specific, and attribute-based — spanning text OCR, table recognition, formula recognition, layout detection, and reading order. It is the benchmark behind the finding that pipeline tools like [[mineru|MinerU]] beat general VLMs on standard documents, and its 2026 v1.5 leaderboard is now topped by specialized document VLMs. Sibling fact-based benchmarks like olmOCR-Bench (used to evaluate [[olmocr|olmOCR]]) complement it.

## Key Facts

- Authoritative CVPR 2025 benchmark for diverse PDF document parsing; ~1,651 pages across ~10 document types, 5 layout types, 5 languages (981 pages / 9 types in the arXiv v2 draft — the difference reflects benchmark growth). [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:omnidocbench|derived|2026-06-09] [epistemic:: sourced]
- Defines 19 layout categories, 15 attribute labels, and 100k+ annotations at block and span level. [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:omnidocbench|derived|2026-06-09] [epistemic:: sourced]
- Three evaluation modes — end-to-end, task-specific, and attribute-based — across text OCR, table recognition, formula recognition, layout detection, and reading order. [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:omnidocbench|derived|2026-06-09] [epistemic:: sourced]
- The 2026 OmniDocBench v1.5 leaderboard is topped by specialized document VLMs (GLM-OCR ~94.6, PaddleOCR-VL-1.5 ~94.5, MinerU2.5, Qwen3-VL, Gemini-3 Pro at the top end). [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:omnidocbench|derived|2026-06-09] [epistemic:: tentative]

## Detail

OmniDocBench (OpenDataLab, CVPR 2025) is the reference benchmark for evaluating how well tools parse diverse real-world PDFs into structured text. Its scale figures grew between drafts — the arXiv v2 paper cites 981 pages across 9 document types, while the current GitHub repo and CVPR 2025 final cite ~1,651 pages across 10 document types, 5 layout types, and 5 languages. It provides block- and span-level annotations (19 layout categories, 15 attribute labels, 100k+ annotations) and supports three evaluation modes: end-to-end (full document parse), task-specific (text OCR, table recognition, formula recognition, layout detection, reading order), and attribute-based (slicing by document characteristic) [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:omnidocbench|derived|2026-06-09] [epistemic:: sourced].

OmniDocBench is the source of the well-cited tradeoff that [[ocr-pipeline-vs-vlm-ingestion|pipeline tools beat general VLMs on standard documents]] (e.g. MinerU's English text-recognition edit distance of 0.15, ahead of GPT-4o and Marker) while general VLMs generalize better to slides and handwriting. By 2026 the picture has shifted: the v1.5 leaderboard is topped by specialized document-parsing VLMs (GLM-OCR ~94.6, PaddleOCR-VL-1.5 ~94.5, MinerU2.5, Qwen3-VL, Gemini-3 Pro), which postdate the original pipeline-vs-general-VLM framing [prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:omnidocbench|derived|2026-06-09] [epistemic:: tentative].

Caveat: a specific OmniDocBench end-to-end leaderboard ranking (with exact numeric scores) failed adversarial verification in the underlying research and is not treated as fact — the leaderboard ordering is real and directionally accurate, but precise per-model scores are volatile and version-dependent. olmOCR-Bench, the fact-based benchmark used to evaluate olmOCR, is a separate, Ai2-authored complement focused on machine-checkable unit tests rather than OmniDocBench's annotation-based scoring.

## Related Pages

- [[pdf-text-extraction-for-llm-ingestion|PDF-to-Text Extraction for LLM Ingestion]] — landscape overview anchored on this benchmark.
- [[ocr-pipeline-vs-vlm-ingestion|OCR Pipeline vs VLM Ingestion]] — the pipeline-vs-VLM tradeoff OmniDocBench documents.
- [[olmocr|olmOCR]] — evaluated on the sibling olmOCR-Bench rather than OmniDocBench directly.
- [[vlm-ocr-hallucination|VLM OCR Hallucination]] — a reliability risk OmniDocBench's accuracy scores do not isolate on their own.

## Sources

- [[src-2026-06-09-pdf-to-text-llm-ingestion-sota|PDF-to-Text Extraction and LLM PDF Ingestion: State of the Art (2025–2026)]]: synthesized deep-research report (2026-06-09)
