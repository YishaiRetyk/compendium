---
id: dr-2026-06-14-video-ingestion
title: "Video as Sub-Case of Transcript + Tool-Generic Acquisition (No Repo Script)"
type: decision
status: active
summary: "Records that video is a sub-case of the transcript source type (not a new source_type): only Acquisition changes unconditionally and Epistemic Default changes conditionally for degraded audio, specified in a lazy-loaded authoritative video-ingestion.md with a lean registry pointer, a tool-generic acquisition contract with no repo script, a transcript-only single-file commit with no asset, a plain link-rot stance, and convention-only extraction fields that are deliberately not lint-enforced."
created_at: 2026-06-14
updated_at: 2026-06-14
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
  - dr-2026-06-14-video-ingestion
has_contradictions: false
knowledge_domain: software
trigger_type: schema-update
affected_pages: []
---

# Video as Sub-Case of Transcript + Tool-Generic Acquisition (No Repo Script)

## TL;DR

Phase 21 treats video as a **sub-case of the `transcript` source type**, not a new `source_type`: a spoken-word recording is a transcript whether it was recorded locally or pulled from a video URL, so the format describes acquisition, not content. Walking the 5-dimension extension contract, only **Acquisition** changes unconditionally (download + timestamped speech-to-text vs. a locally-recorded transcript) and **Epistemic Default** changes conditionally (degraded audio only); Locator, Extraction Granularity, and Drift are inherited from `transcript`. The convention lives in a lazy-loaded authoritative `schema/reference/video-ingestion.md` with a lean registry-row pointer. Four divergences from the Phase 20 PDF sub-case are deliberate: a **tool-generic acquisition contract with no repo script**, a **transcript-only single `.md` commit with no co-located asset**, a **plain link-rot stance with no drift machinery**, and **convention-only extraction fields that are not lint-enforced**.

## Decision

Phase 21 introduced these coupled deliverables:

**1. Video is a sub-case of `transcript`, NOT a new `source_type` (D-14).**

A video carries spoken-word content — the format tells you how the bytes arrived (downloaded + machine-transcribed), not what the content *is*. At Pass 0 the content is classified to its parent type, `transcript`, exactly as a locally-recorded transcript would be, and the video convention layers on top. Walking the 5-dimension extension contract (`schema/reference/source-types.md`): **Acquisition** changes unconditionally (a video downloader plus a timestamped speech-to-text engine, vs. a recorded transcript); **Epistemic Default** changes conditionally (only for degraded audio); and **Locator**, **Extraction Granularity**, and **Drift** are all inherited from `transcript`. Because the decision rule (a new `source_type` is justified only if the format changes a dimension a sub-case cannot absorb) is not met, adding `video` to the enum is an anti-pattern. The provisional `video` registry row in `source-types.md` is finalized with this verdict — the same format-orthogonal framing carried forward from Phase 20.

**2. Lazy-loaded authoritative doc + lean registry pointer (carried from Phase 20 D-01/D-02).**

The full convention (frontmatter fields, locator usage, epistemic tiers, acquisition runbook) lives in a new authoritative `schema/reference/video-ingestion.md`. Video content is not needed at Pass-0 classification time, so it must not bloat `source-types.md`; the contract file carries only a one-row pointer to the convention doc. `video-ingestion.md` gets a routing-table row in AGENTS.md/CLAUDE.md, validated by the `routing` lint category and kept byte-equal by the CLAUDE.md⇄AGENTS.md sync gate.

**3. Tool-generic acquisition contract, NO repo script (D-04) — diverges from Phase 20.**

Acquisition ships as a **tool-generic contract**: any pipeline of a video downloader (`yt-dlp` or equivalent) plus a timestamped speech-to-text engine that emits the `[H:MM:SS] SPEAKER: text` line grammar satisfies the convention. No repo script is shipped. This diverges from Phase 20, which shipped `bin/pdf-extract.sh`: the PDF extractor's tools are publicly nameable in template-public text, whereas the worked STT instance used here is a personal tool that must not be named on a template-public surface. The convention therefore names only a generic downloader-plus-timestamped-STT contract; `yt-dlp` is named because it is a public tool, and its metadata fields (`title`, `channel`, `upload_date`, `duration`) are the canonical source for the video frontmatter fields, manually cross-checked against the watch page before authoring.

**4. Transcript-only, single `.md` file, no bundle / no `--asset` (D-05) — diverges from Phase 20.**

The transcript is committed as a **single `.md` file** with rich frontmatter plus `[H:MM:SS]` lines — no bundle directory, no co-located asset, no `--asset` flag. Bundles exist to co-locate assets, and a video has no committable asset: the video binary is too large and is not committed. The committed transcript **is** the durable record. This diverges from Phase 20 D-11, where `bin/ingest.sh --asset` co-located the original PDF binary in a dated bundle dir.

**5. Plain link-rot stance, no drift machinery (D-06, VID-03).**

The committed transcript plus frontmatter metadata is the durable archive; the `url` is a courtesy pointer that may rot. There is no remediation machinery, no re-checking, and no drift tooling. `#t` locators resolve against the committed transcript, not the live video, so claims keep working after the video is gone — this is the literal reading of VID-03's "no drift machinery."

**6. Convention-only extraction fields, NOT lint-enforced (D-07) — diverges from Phase 20.**

A video-acquired transcript records `extraction_tool` / `extraction_model` / `extraction_date` as flat `snake_case` fields. They are deliberately **not** lint-enforced. The PDF sub-case carries an `original_asset → *.pdf` trigger that lint can key a required-fields check on, but there is **no mechanical signal** distinguishing an STT-built transcript from one assembled off a video's official captions — any lint rule would have to guess. The convention records the fields without a mechanical mandate. This diverges from Phase 20 D-07, where the PDF extraction fields were conditionally lint-enforced.

**7. Tiered epistemic policy with claim-level hedging; support_type stays direct (D-09/D-10/D-11).**

The human classifies clean-vs-degraded audio at acquisition time (a clear spoken-word recording vs. a music-bed / heavy-crosstalk / poor-mic track is observable on listen, so no fragile machine heuristic is needed). Clean audio keeps the `transcript` type's `sourced` default, with a **mandated claim-level hedging** on the STT failure surface — proper nouns / named entities, technical terms, numbers & statistics, and anything the speaker hedges get an `[epistemic:: tentative]` marker. Degraded audio defaults to page-level `tentative` plus a mandatory spot-verification of N = 3 sampled segments (first, middle, last), re-watched against the live `url` at each segment's `#t` timestamp, upgradeable to `sourced` only after they match. Throughout, claims keep `support_type: direct` — a video is a *primary* transcript source and STT is extraction, not derivation. Transcription risk is carried by the page's epistemic status, never by the support type; using `derived` here would be an epistemic-laundering error.

## Why

The framing adopted is **format-orthogonality**: acquisition format is a dimension that cuts across the content-type taxonomy rather than a member of it. This replaces the naive framing that "a video is a kind of source" (which would have produced a `video` `source_type`). The naive framing fails because it conflates transport with content: a spoken-word recording is a transcript regardless of whether it was recorded locally or downloaded, so locking it to a `video` enum value would erase the `transcript` classification the content actually carries and force every downstream "transcripts" query to special-case video.

The epistemic design defends against the STT failure mode: speech-to-text on degraded audio can emit plausible-but-wrong tokens with high fluency — a confident hallucination that reads naturally yet does not match what was said (wrong proper nouns, mangled numbers, invented technical terms). The mechanical defense is the human clean/degraded call plus the tentative-default-and-spot-verify gate for degraded audio plus the claim-level hedging mandate for clean audio — all expressed through epistemic status so the support-type semantics (`direct` = primary, `derived` = secondary) stay clean.

The four divergences from Phase 20 are each forced by a real difference between the two formats: a video has no committable asset (so no bundle, no `--asset`); the worked STT tool is not template-public (so a tool-generic contract rather than a named repo script); a transcript built off official captions is mechanically indistinguishable from an STT transcript (so no lint-enforced extraction fields); and a transcript is self-contained once committed (so a plain link-rot stance suffices, with no drift machinery).

## Alternatives Considered

**`source_type: video` (new enum value).** Rejected: locks spoken-word content to a single format axis, erases the `transcript` classification, and fails the extension-contract decision rule (the format changes only Acquisition unconditionally). It would also force every "transcripts" query to special-case video.

**A `yt-dlp` `.info.json` / thumbnail bundle for richer post-rot metadata.** Rejected in favor of the transcript-only single-file commit (D-05): the four cross-checked video frontmatter fields capture the metadata that matters, and a bundle would re-introduce the asset-co-location machinery the video sub-case deliberately drops.

**An `archive_url` / Wayback field plus a `url_dead:` rot-annotation convention.** Rejected in favor of the plain transcript-is-the-archive stance (D-06): `#t` locators resolve against the committed transcript, not the live video, so claims survive link-rot without any drift machinery to maintain.

**Lint-enforcing the extraction fields (as the PDF sub-case does).** Rejected as unmechanizable (D-07): there is no mechanical signal distinguishing an STT transcript from one built off official captions, so a required-fields lint rule would have to guess. The fields are recorded by convention without enforcement.

**Shipping a repo acquisition script (as Phase 20's `bin/pdf-extract.sh`).** Rejected (D-04): the worked STT instance is a personal tool that cannot be named on a template-public surface, and the acquisition is a single command, so a repo wrapper would wrap one command while risking a neutrality leak. The convention is tool-generic instead.

**`support_type: derived` for STT-extracted claims.** Rejected as epistemic laundering: STT is extraction of a primary transcript source, not synthesis across sources. Transcription risk belongs in epistemic status, not support type.

## Consequences

- `schema/reference/video-ingestion.md` is the new authoritative convention doc, routing-registered in AGENTS.md/CLAUDE.md and kept byte-synced.
- The provisional `video` row in `source-types.md` is finalized as a format-orthogonal sub-case of `transcript`.
- The five video frontmatter fields (`url`, `channel`, `title`, `publish_date`, `duration`) are documented as transcript-sub-case fields in `schema/reference/frontmatter.md`; `url` and `title` reuse existing base source-summary fields. The extraction fields are convention-only, not lint-enforced — so unlike the PDF sub-case, no video-specific lint rule fires.
- The `[H:MM:SS] SPEAKER: text` line grammar resolves under the existing audit `TS_RE` with zero resolver change; the multi-speaker `SPEAKER:` path was exercised end-to-end by the VID-04 validation ingest, where raw diarization labels were mended to meaningful names at ingest (the convention's mapping allowance), and the post-commit source-scoped audit confirmed every `#t` locator resolves against the committed transcript.
- This DR is the direct video parallel of the Phase 20 PDF decision record, which forward-referenced this phase: both adopt the format-orthogonal sub-case pattern (a content parent type + a format-specific locator + an external acquisition tool), differing only where the two formats genuinely differ.

## Affected Pages

None. This is an infrastructure decision record (cf. `dr-2026-06-11-pdf-ingestion.md`, `affected_pages: []`). It documents a schema convention rather than restructuring existing content pages; the `wiki-cloud/index.md` Decisions-section entry is catalog registration, not a `decision_history` backlink.

## Sources

- `schema/reference/video-ingestion.md` — the authoritative video sub-case convention and acquisition runbook.
- `schema/reference/source-types.md` — the 5-dimension extension contract whose decision rule classifies video as a sub-case.
- `wiki-cloud/decisions/dr-2026-06-11-pdf-ingestion.md` — the Phase 20 PDF decision record this one mirrors; it inherits the same format-orthogonal sub-case pattern.
