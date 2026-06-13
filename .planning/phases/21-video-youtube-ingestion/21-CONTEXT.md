# Phase 21: Video/YouTube Ingestion - Context

**Gathered:** 2026-06-13
**Status:** Ready for planning

<domain>
## Phase Boundary

Document how a YouTube video becomes an ingested wiki source — as a **sub-case of the existing `transcript` source type**, not a new type — with timestamp-anchored provenance (`#t<start>-<end>`) and a clear "immutable / link-rot is the only concern" drift stance. Delivers: an authoritative `schema/reference/` convention doc (acquisition runbook + sub-case convention), the schema wiring it needs, and one end-to-end validation ingest of a real YouTube video (VID-01..04).

This phase is the direct video parallel of Phase 20 (PDF). Reuse the PDF phase's structure wherever it transfers; the decisions below record only where video diverges or where a choice was genuinely open.

</domain>

<decisions>
## Implementation Decisions

### Transcript marker format & line grammar
- **D-01:** In-transcript line grammar is **`[H:MM:SS] SPEAKER: text`** — timestamp first, speaker prefix (when present) as part of the line text. This is backward-compatible with the existing audit resolver (`bin/audit-claims.sh` `TS_RE` matches a timestamp at line start) and the de-facto format of the existing transcript sources. No new locator and no audit-resolver change is needed — `#t<start>-<end>` already resolves against this grammar today.
- **D-02:** **Per-segment timestamp density** — one `[H:MM:SS]` line per STT segment (~2–5s), exactly as the tool emits and matching the existing transcripts. No paragraph-clustering/merge step. Gives finest `#t` anchor precision with zero post-processing.
- **D-03:** **Speaker labels only when multi-speaker.** Single-speaker videos omit labels entirely (matches the existing exemplar `src-2026-05-03-is-this-the-only-skill-left`). Multi-speaker videos carry a `SPEAKER:` prefix; the raw diarization label may be kept or mapped to a meaningful name at ingest (optional, agent/human judgment).

### Tooling depth (template-public posture)
- **D-04:** **No new `bin/` script.** The `schema/` doc defines a **tool-generic contract** — any pipeline of `yt-dlp` (or equivalent) + a timestamped STT that emits the D-01 line grammar satisfies it. The creator's personal `stt` CLI is the **worked instance**, documented in `.planning/` phase notes only (VID-01: template-public docs stay tool-generic; the personal tool name must not leak into `schema/`, `bin/`, `docs/`, etc.). Rationale: `stt` already does URL→speaker-labeled-timestamped-transcript end-to-end, so a repo wrapper would wrap a single command. This diverges from Phase 20 D-10 (PDF shipped `bin/pdf-extract.sh`) because olmOCR/Ollama are public tools nameable in template-public text, whereas `stt` is not.

### What gets committed (asset handling) — diverges from PDF
- **D-05:** **Transcript-only, single `.md` file** — rich frontmatter + `[H:MM:SS]` lines. No bundle directory (bundles exist to co-locate assets; a video has none committable). The committed transcript **is** the durable record. This diverges from Phase 20 D-11 (`bin/ingest.sh --asset` co-located the original PDF binary); a video file is too large and is not committed, so the `--asset` mechanism is not used for video.
- **D-06:** **Link-rot stance (VID-03 convention wording):** *the committed transcript + frontmatter metadata is the durable archive; the `url` is a courtesy pointer that may rot.* No remediation machinery, no re-checking, no drift tooling. `#t` locators resolve against the committed transcript, not the live video, so claims keep working after the video is gone. This is the literal reading of VID-03's "no drift machinery."
- **D-07:** **Convention-only extraction fields** (no lint). Record `extraction_tool` / `extraction_model` / `extraction_date` on STT-extracted transcripts (real vault pages may freely name `stt` + the whisper model — neutrality binds only template-public surfaces). Deliberately **not** lint-enforced: unlike PDF's `original_asset → *.pdf` trigger, there is no mechanical signal distinguishing an STT transcript from one built off official captions, so a lint rule would guess. This diverges from Phase 20 D-07 (PDF extraction fields were lint-enforced).
- **D-08:** **Optional `## Description` section**, case-by-case at ingest — permitted between frontmatter and transcript when the video description carries substance (reference links, chapters, named sources); skipped when it's pure promo. Agent/human judgment, no enforcement.

### Epistemic policy for STT-extracted text (VID-03 / failure surface)
- **D-09:** **`sourced` default + mandated claim-level hedging + degraded-audio escape.** Clean spoken-word audio keeps the `transcript` type's normal page-level `sourced` default. The convention **mandates claim-level hedging** on the STT failure surface — proper nouns / named entities, technical terms, numbers & statistics, and anything the speaker themselves hedges — formalizing what the existing two transcripts already do inline. **PDF-symmetric escape:** genuinely degraded audio (music bed, heavy crosstalk, poor mic, heavy accent) → page-level `epistemic_status: tentative` + spot-verify **N = 3 sampled segments**.
- **D-10:** **Spot-verification target = the live video at the segment's `#t` timestamp** (re-watch on YouTube and confirm the transcript matches). Honest about the transcript-only / no-local-asset reality (D-05); `url` + `#t` make it fast. Convention caveat: if the video is already rotted, the segment stays `tentative` (cannot verify what is gone). Read-only; no new audit machinery — reuse `bin/audit-claims.sh` for `#t` resolution where useful.
- **D-11:** Claims from video sources stay **`support_type: direct`** — video is a primary transcript source; STT is extraction, not derivation. Transcription risk is expressed through epistemic status only, never support type (carries forward Phase 20 D-09 / Phase 19's reserved `derived`).

### End-to-end validation (VID-04)
- **D-12:** Validation artifact is **one clean, cloud-safe, multi-speaker (2+) YouTube video, ~5–20 min** (local faster-whisper practicality). Multi-speaker is chosen deliberately to exercise the one piece of new convention surface with zero existing coverage: the `SPEAKER:` labeling path (D-03) + diarization. The user supplies the specific URL at an execution-time **`checkpoint:human-action`** (carries forward Phase 20 D-12's pattern). `sources/` is cloud-safe-only — verify before ingest.
- **D-13:** **Transcription runs locally on this workstation**, not the remote GPU box. `stt` is installed here (`~/.local/bin/stt`, uv-managed project at `~/transcript`) with a capable local GPU (RTX 5070 Ti Laptop). No SSH tunnel is needed for Phase 21 — this diverges from Phase 20, where OCR ran on the remote box over a tunnel. (`yt-dlp` is not on the global PATH and `faster-whisper` is not globally importable, but `stt` runs in its own uv venv, so this is expected, not a blocker — the planner should confirm `stt` runs end-to-end on a URL before the validation checkpoint.)

### Sub-case verdict (carry-forward, not re-discussed)
- **D-14:** `video` is finalized as a **sub-case of `transcript`**, not a new enum value — the 5-dimension walk-through (per the extension contract in `source-types.md`) confirms only **Acquisition** changes (download + STT vs. recorded), with Epistemic Default changing **conditionally** for degraded audio (D-09). The provisional retro-fit-table row for `video` is finalized in this phase. Mirrors Phase 20 D-05's format-orthogonal framing.

### Claude's Discretion
- Exact section structure/wording of the new convention doc (must use neutral placeholders on template-public surfaces per the MUST-NOT list; the doc lives at `schema/reference/` — likely `video-ingestion.md` or similar, planner's call on the exact filename).
- Whether the convention doc is a brand-new `schema/reference/*.md` (Phase 20 PDF pattern) vs. an extension of an existing transcript doc — planner decides based on what exists; if new, it gets a routing-table row in AGENTS.md/CLAUDE.md with byte-sync + neutrality gates (Phase 20 D-01/D-02/D-03 pattern).
- Exact frontmatter field spelling for the five VID-02 fields (`url`, `channel`, `title`, `publish_date`, `duration`) and whether they're added to `frontmatter.md` as documented transcript-sub-case fields; whether `duration`/`publish_date` reuse existing base fields.
- `N`-segment selection method for the degraded-audio spot-verification (first/middle/last by analogy to PDF, or another sampling).
- Hour-digit normalization in timestamps (`0:04:56` vs `00:04:56`) — confirm the audit `TS_RE` tolerance and pick one for the convention.
- Whether the schema edits warrant a `reflect`-tier decision record in `wiki-cloud/decisions/` (Phase 18/19/20 precedent — author one if they do).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Locator & source-type machinery (already exists — do not redefine)
- `schema/reference/provenance.md` — the `#t<start>-<end>` timestamp locator is already defined (`#t00:12:10-00:12:48`, HH:MM:SS) with a worked transcript example. VID-02's locator need is already satisfied.
- `schema/reference/source-types.md` — the `transcript` enum row (primary / recorded-or-downloaded / `#t` / utterance clusters / static / `sourced`) and the **provisional `video` sub-case row** in the retro-fit table that this phase finalizes (D-14). Also the 5-dimension extension-contract decision rule.
- `bin/audit-claims.sh` — existing `#t` resolution logic (`TS_RE`, `_resolve_t`, `_ts_to_secs`). Confirms the D-01 line grammar resolves with zero changes; the resolver is the constraint the marker format must satisfy.

### Structural precedent (Phase 20 PDF — mirror where it transfers)
- `schema/reference/pdf-ingestion.md` — the Phase 20 convention doc: section structure, tiered epistemic policy, tool-generic-contract-with-worked-instance posture, routing/byte-sync. The video doc mirrors this.
- `.planning/phases/20-pdf-ingestion/20-CONTEXT.md` — Phase 20 decisions D-01..D-12, several carried forward here (tool posture, support_type, validation-checkpoint pattern).

### De-facto format exemplars (existing transcript sources)
- `sources/2026/2026-05/2026-05-03-is-this-the-only-skill-left.md` — the canonical existing YouTube transcript: `[H:MM:SS] text` grammar, frontmatter shape (`url`, `author`, `publication: YouTube`, `date`, `source_type: transcript`), single-speaker (no labels).
- `wiki-cloud/sources/src-2026-05-03-is-this-the-only-skill-left.md` and `src-2026-05-04-three-artifacts-build-with-ai.md` — existing transcript source-summary pages showing `sourced` page status + the de-facto claim-level hedging that D-09 formalizes.
- `wiki-cloud/concepts/jagged-frontier.md` — live examples of `#t`-anchored claims (`...#t00:04:56-00:05:21|direct|...`) authored from a YouTube transcript.

### Requirements
- `.planning/REQUIREMENTS.md` — VID-01..VID-04 (rows ~36–39, traceability ~85–88).
- `.planning/ROADMAP.md` — Phase 21 entry (goal, 4 success criteria, depends-on Phase 19 extension contract).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `bin/audit-claims.sh`: `#t` locator resolution already implemented and working against the `[H:MM:SS]` line grammar — no changes needed for video; reused for optional spot-verification (D-10).
- `bin/ingest.sh`: the single-file ingest path is the right fit for transcript-only video sources (D-05). The Phase-20 `--asset` flag is NOT used for video (no committed binary).
- The local `stt` CLI (`~/transcript`, on PATH): `youtube.py` (yt-dlp), `asr.py` (faster-whisper), `diarize.py` (pyannote diarization → speaker labels), `formatter.py`. Likely takes a URL straight to a speaker-labeled timestamped transcript — the worked instance behind the generic contract (D-04). Worked-instance details stay in `.planning/`, never in `schema/`/`bin/`.

### Established Patterns
- **Sub-case-on-existing-type**, not new enum (the v1.3 milestone thesis; PDF set the precedent). The extension-contract 5-dimension walk-through is the mechanism (D-14).
- **Tool-generic in template-public surfaces, worked-instance in `.planning/`** — the neutrality gate (`bin/check-neutrality.sh`) enforces it; prevent leaks at write-time (D-04, D-07).
- **New `schema/reference/*.md` → routing-table row + `bin/sync-claude.sh` byte-equality + `routing` lint category** (Phase 16/19/20 pattern), if the planner creates a new doc.

### Integration Points
- New convention doc routed from AGENTS.md/CLAUDE.md routing table (if new file).
- `source-types.md` retro-fit-table `video` row flips from provisional to finalized.
- Validation ingest writes to `sources/` (raw transcript) + `wiki-cloud/sources/` (summary) + topic pages, all cloud-safe.

</code_context>

<specifics>
## Specific Ideas

- The existing Hack / Agentive Stack YouTube transcript (`is-this-the-only-skill-left`) is the concrete "I want it like this" reference for the committed format: timestamp-first lines, YouTube frontmatter, single-speaker no-labels.
- STT runs on **this workstation** (RTX 5070 Ti), not the remote box — a deliberate divergence from Phase 20's remote-OCR setup (D-13).
- Multi-speaker validation video specifically to prove the new `SPEAKER:` labeling path (D-12).

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope. (Options explicitly considered and declined, preserved for traceability: committing a `yt-dlp .info.json`/thumbnail bundle for richer post-rot metadata — declined in favor of transcript-only D-05; an `archive_url`/Wayback field and a `url_dead:` rot-annotation convention — declined in favor of the plain transcript-is-the-archive stance D-06; lint-enforcing the extraction fields — declined as unmechanizable D-07. A future phase could revisit any of these if link-rot becomes a felt problem.)

</deferred>

---

*Phase: 21-Video/YouTube Ingestion*
*Context gathered: 2026-06-13*
