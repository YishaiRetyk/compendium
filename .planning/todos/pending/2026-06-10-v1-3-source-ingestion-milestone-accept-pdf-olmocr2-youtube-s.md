---
created: 2026-06-10T05:57:27.259Z
title: Bring v1.3 Source Ingestion assessment (PDF via olmocr2 + YouTube via stt) into /gsd-new-milestone
area: planning
files:
  - .planning/seeds/primary-source-type-extensions.md
  - .planning/seeds/research-report-ingest.md
  - .planning/notes/2026-05-31-milestone-grouping-proposal.md
  - .planning/ROADMAP.md
---

## Problem

v1.2 shipped 2026-06-08; project is between milestones (STATE: "Awaiting next
milestone"). On 2026-06-10 the creator decided to ACCEPT two new source-ingestion
capabilities into the next milestone, and an assessment session confirmed fit.
This todo preserves that assessment so `/gsd-new-milestone` questioning starts
from settled facts instead of re-deriving them.

**Decision: accept both into the next milestone.**

1. **PDF parsing** — acquisition via olmOCR 2, already pulled locally as Ollama
   model `richardyoung/olmocr2:7b-q8` (9.5 GB). This is the wiki's own headline
   self-hosting recommendation (see
   `wiki-cloud/sources/src-2026-06-09-pdf-to-text-llm-ingestion-sota.md`:
   82.4 olmOCR-Bench, beats Marker 76.1 / MinerU 75.8).
2. **YouTube video ingestion** — acquisition via the creator's working `stt`
   CLI at `~/code/transcript/` (separate repo): faster-whisper large-v3
   (English) + IVRIT Hebrew fine-tune, pyannote 3.3.2 diarization,
   `stt/youtube.py` + yt-dlp dependency, and **timestamped output**
   (`stt/formatter.py`: segments → timestamped plain text with speaker labels).
   Local-only, RTX 5070 Ti 12GB VRAM, sequential model loading.

**Why they fit (assessment findings):**

- The seed `primary-source-type-extensions.md` anticipated exactly this; its
  revisit trigger ("creator has a concrete YouTube video to ingest") has fired.
  Tooling acquisition (olmocr2 pull + stt build) is the demonstrated intent.
- Per that seed's 5-dimension decision framework, both are likely **sub-cases,
  not new source types**: video = `transcript` sub-case (the `#t<start>-<end>`
  locator already exists; acquisition was "the real friction" and stt solves
  it, including timestamps); PDF = article/paper sub-case (the `<!-- page: N -->`
  / `#p` page-locator convention from Phase 13 already exists; olmocr2 solves
  acquisition). Milestone work is conventions + frontmatter metadata + docs +
  thin glue, not new schema machinery.
- Role division preserved: stt and olmocr2 are acquisition tooling *upstream*
  of ingest — they produce the raw source.md; the human still curates sources.
  No web-research operation is added (the four-op vocabulary stays intact).
- The 2026-05-31 milestone-grouping proposal already names this cluster
  ("Source Ingestion"): design the source-type extension contract ONCE
  (5-dimension recipe + primary/secondary axis), then ship per-type
  implementations independently. `research-report-ingest` (design-LOCKED,
  secondary) ships first; PDF and video are primary instances and separable.

## Solution

Run `/gsd-new-milestone` and shape **v1.3 "Source Ingestion"**:

- Extension-contract design phase, then `research-report` (locked, first),
  PDF (olmocr2), and video (stt) as separable phases.
- 999.5 External Source Drift is optional scope: pairs naturally with
  research-report URL bibliographies; PDF/video are immutable-once-acquired
  and don't need drift. If the milestone feels heavy (~4 phases, v1.2-sized),
  999.5 is the piece to defer.

Two things to scope carefully at questioning time:

1. **VLM hallucination epistemics for PDF** — the SOTA report's central
   caveat: VLMs hallucinate on degraded scans by defaulting to linguistic
   priors. The PDF convention needs epistemic defaults / spot-verification
   guidance for olmocr2 output on poor-quality scans (touches the trust
   model, not just acquisition).
2. **Settled facts that close seed open-questions** — the seed's "which
   timestamped-transcript path is the documented default?" is now answered
   (stt + yt-dlp, timestamped speaker-labeled output); acquisition tooling
   existence converts several open questions into documentation tasks.

Unrelated but adjacent: the standing `phase-14-lint-mask-fence-edge-cases`
todo could be cleared via `/gsd-quick` before or alongside the milestone.
