# State of the Art: PDF-to-Text Extraction and LLM PDF Ingestion (2025–2026)

> Synthesized deep-research report. Target: clean Markdown / structured-text output for a knowledge-base ingestion pipeline. Scope: born-digital text-layer PDFs, scanned/image PDFs requiring OCR, and complex layouts (multi-column papers, tables, charts/graphs, math, footnotes), across both self-hosted/open-source and cloud/commercial tiers. Methodology: 5 search angles, 21 sources fetched, 99 claims extracted, 25 adversarially verified (3-vote, 2/3-refute-to-kill); 22 confirmed, 3 refuted. The refuted claims are recorded below for the provenance trail and are NOT treated as findings.

## Summary

For a Markdown-producing knowledge-base ingestion pipeline in 2025–2026, the field has bifurcated into three camps: traditional OCR pipelines (Tesseract / PaddleOCR), specialized document-parsing pipeline tools (MinerU, Marker, Docling), and VLM-based parsers — with VLM OCR now leading OmniDocBench and folding detection, recognition, and post-processing into a single forward pass. Pipeline tools still win on standard documents (academic papers, financial reports) while VLMs generalize better to slides, handwriting, and unconventional formats. The strongest concrete recommendation for self-hosting is olmOCR 2 (an open Qwen2.5-VL-7B fine-tune): it scores 82.4 on olmOCR-Bench, beats Marker (76.1) and MinerU (75.8), outputs Markdown with equations/tables/handwriting, and processes ~10,000 pages for under $2 on a single H100 — roughly 1/32 the cost of GPT-4o batch APIs. Commercial APIs cluster cheap and may still win on SLA, compliance, region availability, and audit logs, but open-weight VLM OCR can match or beat them on public benchmarks and is cheaper at scale. A key reliability caveat for the native-vision paradigm: multimodal LLMs hallucinate on degraded images by defaulting to linguistic priors instead of grounding in visual evidence, producing plausible-but-wrong text rather than flagging unreadability.

## Three Camps

By 2025–2026 the landscape splits into three approaches:

1. Traditional OCR pipelines — Tesseract, EasyOCR, classic PaddleOCR. Detection → recognition → post-processing as separate stages.
2. Specialized document-parsing pipeline tools — MinerU, Marker, Docling. Layout-aware pipelines that emit Markdown.
3. VLM-based OCR — vision-language models (olmOCR, GLM-OCR, PaddleOCR-VL, dots.ocr, plus general Gemini/GPT/Claude) that fold the whole job into a single forward pass.

By 2025–2026, VLM-based OCR has displaced traditional three-stage OCR pipelines for complex document understanding by folding detection, recognition, and post-processing into a single forward pass, and specialized document-parsing VLMs now lead the OmniDocBench leaderboard. Traditional OCR (Tesseract, EasyOCR, classic PaddleOCR) remains relevant mainly for CPU-only, air-gapped, deterministic, and simple high-throughput scans. Hybrid cost-tier pipelines also still use traditional OCR as a cheap first pass.

On OmniDocBench, traditional pipeline tools (e.g. MinerU) outperform general VLMs on standard documents like academic papers and financial reports, while general VLMs generalize better to specialized formats like slides and handwritten notes. On overall text-recognition edit distance (lower is better) MinerU leads English at 0.15 over GPT-4o (0.233) and Marker (0.336); for Chinese, Qwen2-VL-72B (0.327) and MinerU (0.357) lead over GPT-4o (0.399) and Marker (0.556). This is a snapshot of the general-VLM-vs-traditional-pipeline tradeoff; the broader 2026 landscape has shifted toward specialized VLM-OCR models leading overall.

## Paradigm Comparison

Two competing paradigms target the same Markdown output:

- Extraction / OCR-to-Markdown pipeline: layout model → OCR → reconstruct Markdown. Deterministic, structured, cheap, strong on standard layouts; brittle on unseen layouts with multi-stage error compounding. Best representative on OmniDocBench is MinerU (English text edit-distance 0.15).
- Native multimodal VLM ingestion: feed a page image, model emits Markdown directly. Generalizes to messy/novel formats; one model does the whole job. Its core weakness is hallucination on degraded input.

Specialized VLMs increasingly win overall, but pipeline tools remain best on clean standard documents, and traditional OCR remains the deterministic, no-hallucination choice for CPU/edge and clean high-throughput scans.

## VLM Hallucination Caveat

The native multimodal-LLM vision paradigm has a key reliability weakness for document ingestion: VLMs (GPT-4o, Claude, Gemini class) are incomplete under real-world visual degradation (blur, occlusion, low contrast) and hallucinate text by defaulting to linguistic priors instead of grounding in visual evidence, producing plausible-but-wrong OCR output rather than recognizing they cannot read the text. This is documented in a NeurIPS 2025 poster ("Seeing is Believing? Mitigating OCR Hallucinations in Multimodal LLMs") and corroborated by multiple 2025–2026 papers (including DeepSeek-OCR work showing priors inflate accuracy 60–80% dropping to ~20% zero-prior). One contrary clinical-report study found VLMs more robust than Tesseract on noisy text but still acknowledged hallucination as a challenge. For a provenance- and faithfulness-sensitive knowledge base, this is the single biggest risk of the "just feed pages to a vision LLM" approach.

## Self-Hosted / Local Tier

olmOCR 2 (Ai2, Apache-2.0) is the strongest self-hosting recommendation. Marker and MinerU are first-choice open document-parsing pipeline tools per an independent September 2025 deep-dive, with Dolphin and MarkItDown as supplementary tools; Docling is increasingly favored for enterprise RAG.

Marker (open-source) runs free locally on consumer GPUs (3.17–5 GB VRAM), supports 90+ languages, and offers a hosted option at ~$0.004/page. Its "free" status is bounded by an Open-RAIL-M / under-$2M-revenue license.

Self-hosted open-source VLM OCR is dramatically cheaper than commercial vision-LLM ingestion at scale: olmOCR processes ~1M PDF pages for ~$190 (about 1/32 the cost of GPT-4o batch APIs), and olmOCR 2's FP8-quantized model achieves 3,400 output tokens/sec on a single H100, processing ~10,000 pages for under $2. These are vendor-self-reported marginal GPU-compute estimates excluding hardware amortization. Open-weight self-hosted VLM OCR can match or beat paid commercial APIs on public document-parsing benchmarks and can be cheaper at scale (e.g. LightOn OCR ~1M pages for $141, ~10.6× cheaper than cloud), but commercial APIs may still win on SLA, compliance, region availability, and audit logs.

## Cloud / Commercial Tier

Cloud/commercial document-processing APIs cluster at the low end of per-page cost: Amazon Textract $0.0015–0.05/pg, Azure Document Intelligence $0.0015–0.03/pg, Google Document AI $0.0015–0.03/pg, and Mistral OCR ~$0.001–0.002/pg (batch at half price). Mistral OCR can process up to 2000 pages/minute on a single node. (A later Mistral OCR 3, December 2025, is repriced to $2/1000 pages with a 50% batch discount; Textract Forms+Tables+Queries combined can reach ~$0.07/pg.)

What commercial APIs buy over self-hosting: SLA, SOC2/compliance, region/data-residency, audit logging, RBAC/SSO. What they do not buy: a decisive accuracy edge — open-weight VLM OCR can match or beat them on public benchmarks and is cheaper at scale. Vendor self-reported accuracy numbers proved the least trustworthy class of claim in this research and should be discounted.

## OmniDocBench

OmniDocBench is the authoritative CVPR 2025 benchmark for diverse PDF document parsing. The arXiv v2 draft cites 981 PDF pages across 9 document types; the current GitHub repo and CVPR 2025 final cite ~1,651 pages across 10 document types, 5 layout types, and 5 languages (the difference reflects benchmark growth). It defines 19 layout categories, 15 attribute labels, 100k+ annotations, block- and span-level annotations, and three evaluation modes (end-to-end, task-specific, attribute-based) across text OCR, table recognition, formula recognition, layout detection, and reading order. The 2026 OmniDocBench v1.5 leaderboard is now topped by specialized document VLMs (GLM-OCR ~94.6, PaddleOCR-VL-1.5 ~94.5, MinerU2.5, Qwen3-VL, Gemini-3 Pro at the top end).

## olmOCR

olmOCR is a self-hosted open-source VLM document converter, originally fine-tuned from Qwen2-VL-7B-Instruct; olmOCR 2 rebased on Qwen2.5-VL-7B. It is Apache-2.0 open weights, self-hostable via vLLM/SGLang/Docker, and outputs Markdown with LaTeX equations, HTML/Markdown tables, and handwriting in correct reading order even for complex multi-column layouts. Edge-case limits include complex layered tables and occasional repeated n-grams in very small text.

olmOCR 2 scores 82.4 on olmOCR-Bench, outperforming Marker (76.1) and MinerU (75.8), competitive with the top open models (Chandra OCR 0.1.0 at 83.1, Infinity-Parser 7B at 82.5), and notably ahead of the Mistral OCR API (72.0). It shows large gains on complex layout: tables 84.9% (up from 72.9%), multi-column 83.7% (up from 77.3%), math scans 82.3% (up from 79.9%). A newer chandra-2 (85.9) exists; the cited versions remain accurate. olmOCR-Bench is authored by Ai2 (olmOCR's own team), so olmOCR-vs-Marker/MinerU comparisons are first-party rather than a neutral third-party arena, and Chandra/Infinity scores on that bench are author-reported.

olmOCR-Bench measures document-level OCR quality via ~7,010 discrete machine-checkable "fact" unit tests across seven document types (arXiv Math, Old Scans Math, Tables, Old Scans, Headers/Footers, Multi-Column, Long Tiny Text), covering text presence/absence, natural reading order, table accuracy, and math formula accuracy. Test counts: Text Presence 721, Text Absence 823, Natural Reading Order 1061, Table Accuracy 1020, Math Formula Accuracy 3385.

In a human-judged pairwise study (11 researchers, 2,017 PDFs, 452 comparisons), olmOCR output was preferred over Marker in 61.3% of comparisons, over GOT-OCR in 58.6%, and over MinerU in 71.4%, achieving an ELO score above 1800. This is a vendor-run human evaluation (Ai2 is olmOCR's developer), correctly scoped as a specific study finding.

## Recommendations

For a Markdown knowledge-base ingestion pipeline spanning all document types across both tiers:

1. Born-digital text-layer PDFs: start with a deterministic extractor (PyMuPDF / pdfplumber) for the text layer — free, fast, no hallucination. Escalate only when layout is complex.
2. Complex layouts / scans / math / tables / footnotes: use olmOCR 2 self-hosted as the workhorse — best accuracy-per-dollar, keeps data local (suits a local privacy tier), and emits Markdown with equations and tables natively.
3. No GPU to self-host: use MinerU or Marker locally on a consumer GPU, or a cheap commercial API (Mistral OCR / Document AI) for cloud-safe sources only.
4. Reliability guardrail: do not blindly trust single-pass VLM output on degraded scans. Flag low-confidence pages for review or cross-check against a deterministic OCR pass — this directly mitigates the hallucination failure mode.
5. Charts/graphs remain the weakest area across all tools; expect to verify chart-derived numbers manually.

## Caveats and Time-Sensitivity

Time-sensitivity is the dominant caveat: this field moves monthly, so benchmark-leaderboard positions and per-page prices are volatile. Benchmark snapshots already diverge (OmniDocBench 981→1,651 pages between draft and final; the v1.5 leaderboard is now topped by specialized document VLMs that postdate the original pipeline-vs-general-VLM framing). Several key sources are vendor/self-interested: olmOCR-Bench is authored by Ai2, so olmOCR-vs-Marker/MinerU comparisons and the human-eval ELO are first-party. Cost/throughput figures for self-hosted models are marginal GPU-compute estimates excluding hardware amortization. Pricing is volatile (Mistral OCR repriced between v1 and v3; Marker "free" is license-bounded). Docling and the commercial premium parsers (LlamaParse, Reducto, Unstructured) were named in the research scope but no verified accuracy/cost claims survived verification for them.

## Refuted Claims

These claims FAILED 3-vote adversarial verification and are NOT findings. Recorded for the provenance trail and as a warning that vendor internal-benchmark accuracy numbers are unreliable:

- A specific OmniDocBench end-to-end leaderboard ranking (MinerU2.5-Pro 95.75, GLM-OCR 95.22, Gemini 3 Pro 92.91, Marker 78.44) — refuted 1-2.
- Mistral OCR (model 2503) scoring 94.89% overall on an internal benchmark, beating Google Document AI (83.42%), Azure OCR (89.52%), Gemini-1.5-Flash-002 (90.23%), GPT-4o-2024-11-20 (89.77%) — refuted 0-3.
- Mistral OCR achieving 94.29% on math and 96.12% on tables, beating GPT-4o and Gemini Flash; scanned documents 98.96% — refuted 1-2.

## Source Citations

Primary and high-quality sources underpinning the verified findings:

- OmniDocBench — GitHub: https://github.com/opendatalab/OmniDocBench
- OmniDocBench — arXiv (CVPR 2025): https://arxiv.org/html/2412.07626v2
- olmOCR — Ai2 blog: https://olmocr.allenai.org/blog
- olmOCR 2 — Ai2 blog: https://allenai.org/blog/olmocr-2
- olmOCR — arXiv: https://arxiv.org/abs/2502.18443
- olmOCR 2 — arXiv: https://arxiv.org/abs/2510.19817
- olmOCR-Bench — GitHub: https://github.com/allenai/olmocr/tree/main/olmocr/bench
- "Seeing is Believing? Mitigating OCR Hallucinations in Multimodal LLMs" — arXiv (NeurIPS 2025): https://arxiv.org/html/2506.20168v2
- Mistral OCR — vendor news/pricing: https://mistral.ai/news/mistral-ocr/ , https://mistral.ai/pricing/
- Artificial Analysis OCR aggregator: https://artificialanalysis.ai/agents/ocr
- CodeSOTA OCR landscape: https://www.codesota.com/ocr
- Open-source PDF-to-Markdown deep-dive (Jimmy Song, Sept 2025): https://jimmysong.io/blog/pdf-to-markdown-open-source-deep-dive/
