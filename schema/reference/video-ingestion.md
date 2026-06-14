# Video Ingestion

> Agent-authoritative reference for the video-as-sub-case-of-transcript convention and the YouTube acquisition runbook.
> The AGENTS.md routing table points here. If you find a discrepancy between this file and AGENTS.md, this file wins.

Use this file when acquiring a YouTube/video source (running the acquisition runbook), authoring the source summary for a video-acquired transcript, or deciding the epistemic status of claims drawn from STT-extracted spoken text.

## 1. Classification — Video Is a Sub-case of `transcript`

Video is a **sub-case of the `transcript` source type** (D-14), NOT a new `source_type` enum value. The video format tells you how the bytes arrived (downloaded + machine-transcribed), not what the content *is* — a spoken-word recording is a transcript whether it was recorded locally or pulled from a video URL.

At Pass 0 the content is classified normally to its parent type, `transcript`, exactly as a locally-recorded transcript would be. The video convention then *layers on top* of that classification. Walking the 5 dimensions of the extension contract (`schema/reference/source-types.md`):

| Dimension | Effect of the video format |
|-----------|----------------------------|
| **Acquisition** | Changes (download via a `yt-dlp`-equivalent + a timestamped speech-to-text engine vs. a locally-recorded transcript). |
| **Locator** | **Unchanged** — `#t<start>-<end>` already exists (`schema/reference/provenance.md`); the STT emits the `[H:MM:SS]` lines it resolves against. |
| **Extraction Granularity** | **Unchanged** — inherited from `transcript` (utterance / paragraph clusters). |
| **Drift** | **Unchanged** — static after recording; the committed transcript is the durable archive, and link-rot of `url` is the only concern (D-06). |
| **Epistemic Default** | Changes **conditionally** — only for degraded audio. Clean spoken-word keeps `transcript`'s `sourced` default. See the Tiered Epistemic Policy section below. |

Because only one dimension changes unconditionally (Acquisition) and one conditionally (Epistemic Default), video does **not** earn a new `source_type` enum value: it is a sub-case of `transcript`. This is the same format-orthogonal framing carried forward from Phase 20 — the format describes acquisition, not content.

## 2. Frontmatter Fields (Video-acquired Transcripts)

A source summary acquired from a video carries five flat `snake_case` fields describing the video itself:

| Field | Meaning |
|-------|---------|
| `url` | The video URL — a courtesy pointer that may rot (D-06). This is a base source-summary field, **reused** (already documented in `schema/reference/frontmatter.md`), not duplicated. |
| `channel` | Publishing channel / author. |
| `title` | Video title. This is a base field, reused. |
| `publish_date` | ISO 8601 video publication date. |
| `duration` | Runtime (e.g. `~12 min`). |

A video-acquired transcript also records the convention-only extraction fields:

| Field | Meaning |
|-------|---------|
| `extraction_tool` | The downloader/STT pipeline that produced the transcript. |
| `extraction_model` | The ASR model used for the transcription. |
| `extraction_date` | ISO 8601 date the video was transcribed. |

These extraction fields are **convention-only** — they are recorded on STT-extracted transcripts but are explicitly **NOT** validated by lint (D-07). This diverges from the PDF sub-case: a PDF carries an `original_asset → *.pdf` trigger that lint can key a required-fields check on, but there is **no mechanical signal** distinguishing an STT-built transcript from one assembled off the video's official captions. Any lint rule would have to guess, so the convention records these fields without a mechanical mandate. Author them when the transcript came from STT; omit them otherwise.

## 3. `#t` Locator Usage

Claims from video sources use the existing `#t<start>-<end>` timestamp locators, which resolve against the `[H:MM:SS]` lines the STT emits — see `schema/reference/provenance.md` (Locator Types). Do not redefine the grammar; this convention only specifies that the STT pipeline produces those `[H:MM:SS]` lines as a side effect of the per-segment transcription loop.

Claims keep `support_type: direct` (D-11). A video is a **primary** transcript source: STT is *extraction*, not *derivation*, so the support type stays direct. Transcription risk is carried by the page's `epistemic_status`, NEVER by the support type. The derived support type is reserved for genuinely secondary sources (synthesis across sources); using it on a video claim would be an epistemic-laundering error.

## 4. Tiered Epistemic Policy (VID-03)

The **human classifies clean-vs-degraded audio at acquisition time** — a clear spoken-word recording vs. a music-bed / heavy-crosstalk / poor-mic / heavy-accent track is observable on listen, so no fragile machine heuristic is needed.

- **Clean spoken-word audio** → the `transcript` type's normal `sourced` default. The convention **MANDATES claim-level hedging** on the STT failure surface: proper nouns / named entities, technical terms, numbers & statistics, and anything the speaker themselves hedges (D-09 — this formalizes what the existing transcripts already do inline). Hedge these with `[epistemic:: tentative]` on the individual claim even when the page is `sourced`.
- **Degraded audio** (music bed, heavy crosstalk, poor mic, heavy accent) → page-level `epistemic_status: tentative` by default, plus a **mandatory spot-verification of N = 3 sampled segments**: the **first segment, a middle segment, and the last segment** (this selection catches transcription drift across the runtime — cold-start, mid-stream, and tail). A degraded source upgrades from `tentative` to `sourced` only after the spot-verified segments match the audio.

**Spot-verification target diverges from the PDF sub-case (D-10):** there is no co-located local asset (D-05), so verification **re-watches the live `url` at each segment's `#t` timestamp** and confirms the transcript matches the audio. Resolve `#t` via `bin/audit-claims.sh` where useful (no new audit machinery is introduced); the re-watch is read-only. **Convention caveat:** if the video has already rotted, the segment cannot be verified — it stays `tentative` (you cannot verify what is gone).

**The failure mode this defends against:** speech-to-text on degraded audio can emit plausible-but-wrong tokens with high fluency — a confident hallucination that reads naturally yet does not match what was said (wrong proper nouns, mangled numbers, invented technical terms). The `tentative` default + spot-verification mandate + claim-level hedging are the mechanical defenses; the support type stays direct throughout.

## 5. Acquisition Runbook

**Generic contract (D-04):** any pipeline of a video downloader (`yt-dlp` or equivalent) + a timestamped speech-to-text engine that emits the `[H:MM:SS] SPEAKER: text` line grammar (D-01) satisfies this convention. No repo script is shipped; the convention is tool-generic.

**Line grammar the pipeline must emit (D-01/D-02/D-03):**

- The `[H:MM:SS]` timestamp stays **first** on every line, so the audit resolver matches it at line start. The resolver tolerates `[H:MM:SS]`, `[HH:MM:SS]`, and `[MM:SS]` alike; this convention writes the single-hour-digit `[H:MM:SS]` form (matching the existing transcripts).
- One `[H:MM:SS]` line per STT segment (~2–5s), as the engine emits — no paragraph-clustering or merge step. This gives the finest `#t` anchor precision with zero post-processing.
- A `SPEAKER:` prefix appears **only on multi-speaker videos** (D-03); single-speaker videos omit speaker labels entirely. The prefix is opaque line text after the timestamp, so it needs zero resolver change.

## 6. Ingest Checklist

1. Run the (tool-generic) URL → timestamped-transcript pipeline.
2. Commit the transcript as a **single `.md` file** (no bundle directory — D-05), with rich frontmatter + `[H:MM:SS]` lines. An OPTIONAL `## Description` section is permitted between the frontmatter and the transcript when the video description carries substance — reference links, chapters, named sources (D-08); skip it for pure promo.
3. Author the source summary with `source_type: transcript` plus the five video frontmatter fields (see the Frontmatter Fields section).
4. Claims use `#t<start>-<end>` locators with `support_type: direct`; mandate claim-level hedging on the STT failure surface.
5. If the audio is degraded → page-level `tentative` + spot-verify N = 3 segments against the live `url` (see the Tiered Epistemic Policy section); otherwise → `sourced`.

## See Also

- `schema/reference/source-types.md`
- `schema/reference/frontmatter.md`
- `schema/reference/provenance.md`
- `schema/workflows/ingest.md`
