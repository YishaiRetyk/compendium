---
phase: 21-video-youtube-ingestion
plan: 02
subsystem: wiki-ingestion
tags: [video, youtube, transcript, stt, diarization, yt-dlp, timestamp-provenance, schema]

# Dependency graph
requires:
  - phase: 21-01
    provides: "schema/reference/video-ingestion.md convention doc + frontmatter/source-types/routing wiring"
  - phase: 20-pdf-ingestion
    provides: "format-orthogonal sub-case pattern + tool-generic-acquisition-with-worked-instance posture + validation-checkpoint pattern"
provides:
  - "First real video-acquired transcript ingested end-to-end (VID-04): single-file sources/ transcript + wiki-cloud/ source summary + 4 topic pages with #t|direct provenance"
  - "Worked exercise of the multi-speaker SPEAKER: labeling path (D-03) with raw diarization mended to meaningful names at ingest"
  - "Schema-update decision record dr-2026-06-14-video-ingestion recording the video sub-case + four deliberate divergences from the PDF sub-case"
affects: [future video/transcript ingests, phase-21-verification, v1.3 milestone closure]

# Tech tracking
tech-stack:
  added: [torchcodec (pinned 0.10.0 into the local STT venv to unblock diarization under torch 2.10)]
  patterns:
    - "Video as sub-case of transcript: single .md file (no bundle, no --asset), source_type: transcript, #t|direct claims"
    - "Diarization-fallback branch (b): raw SPEAKER_NN labels mended to meaningful names by content attribution at ingest (D-03)"
    - "VID-02 metadata flow: yt-dlp --print fields cross-checked against the YouTube watch page before authoring frontmatter; upload_date YYYYMMDD normalized to ISO"

key-files:
  created:
    - sources/2026/2026-06/2026-06-14-hassabis-amodei-day-after-agi.md
    - wiki-cloud/sources/src-2026-06-14-hassabis-amodei-day-after-agi.md
    - wiki-cloud/entities/demis-hassabis.md
    - wiki-cloud/entities/dario-amodei.md
    - wiki-cloud/concepts/agi-timelines.md
    - wiki-cloud/concepts/ai-self-improvement-loop.md
    - wiki-cloud/decisions/dr-2026-06-14-video-ingestion.md
  modified:
    - wiki-cloud/entities/anthropic.md
    - wiki-cloud/index.md
    - wiki-cloud/log.md
    - wiki-cloud/maintenance/lint-report.md

key-decisions:
  - "Mended raw 3-speaker diarization (SPEAKER_00/01/02) to HOST/HASSABIS/AMODEI/AUDIENCE by content attribution (D-03 fallback branch b) — the raw diarizer conflated the two guests and merged some Q/A turns, which a rerun would not fix"
  - "Converted bin/ingest.sh's bundle-dir output (DEST_DIR/source.md) to the flat single-file form mandated by D-05 (no bundle, no asset)"
  - "Authored the schema-update DR (Claude's discretion per CONTEXT.md L50) — the four deliberate divergences from the PDF sub-case warrant a record"

patterns-established:
  - "Local STT acquisition (no SSH tunnel — D-13) runs on this workstation; a missing torchcodec dep is a Rule-3 blocker fixed by pinning the torch-compatible build"
  - "Post-commit source-scoped audit asserts non-vacuously: source selected (length>0) AND zero insufficient-locator — the audit's 'insufficient' (verifier-not-run) verdict means the #t locator DID resolve"

requirements-completed: [VID-04]

# Metrics
duration: ~85min
completed: 2026-06-14
---

# Phase 21 Plan 02: Video/YouTube Ingestion Validation Summary

**First real YouTube video acquired locally via STT → ingested as a single-file timestamped transcript with mended 3-speaker labels, a source summary + 4 topic pages carrying #t|direct provenance, and a schema-update decision record — validating VID-04 end-to-end.**

## Performance

- **Duration:** ~85 min (continuation agent; Task 1 + Task 2 checkpoint already done)
- **Started:** 2026-06-14T16:33Z (acquisition start)
- **Completed:** 2026-06-14T14:00:15Z (UTC clock; local wall-clock ~17:00)
- **Tasks:** 2 (Task 3 ingest + Task 4 DR)
- **Files modified:** 11 (7 created, 4 modified)

## Accomplishments

- Acquired a real multi-speaker YouTube interview (Demis Hassabis × Dario Amodei, "The Day After AGI", DRM News, 31:11) locally via the tool-generic STT contract and committed it as a SINGLE `.md` transcript — no bundle, no co-located asset (D-05).
- Exercised the genuinely-new SPEAKER: labeling path (D-03): raw diarization yielded 3 distinct labels but conflated the two guests and merged some question/answer turns; mended at ingest to HOST / HASSABIS / AMODEI / AUDIENCE (4 distinct labels on the committed file) by content attribution, splitting merged Q/A segments at their natural boundary.
- Authored the source summary with the five video frontmatter fields (title/channel/publish_date/duration from yt-dlp, cross-checked against the watch page, upload_date 20260120 → ISO 2026-01-20), #t-anchored `direct` claims, and claim-level `[epistemic:: tentative]` hedging on proper nouns/numbers (sourced tier — D-09); created 2 entity + 2 concept topic pages.
- Post-commit source-scoped audit passed non-vacuously: the source's #t claims were selected (37 findings) and zero carry `insufficient-locator` — every timestamp locator resolves against the committed transcript (VID-04 proven).
- Authored `dr-2026-06-14-video-ingestion` capturing the video sub-case + four deliberate divergences from the PDF sub-case, mirroring the Phase-20 DR, neutrality-clean (STT tool described generically).

## Task Commits

1. **Task 3: Acquire + ingest + author pages with #t provenance, verify, log** — `7299091` (ingest)
2. **Task 4: Author the schema-update decision record** — `e2b7abb` (reflect)

_Tasks 1 (pre-flight probe) and 2 (human-action checkpoint) were completed before this continuation agent._

## Files Created/Modified

- `sources/2026/2026-06/2026-06-14-hassabis-amodei-day-after-agi.md` — single-file raw transcript, `[H:MM:SS] SPEAKER: text` lines, 4 distinct mended labels, `source_type: transcript`, `privacy: cloud_safe`
- `wiki-cloud/sources/src-2026-06-14-hassabis-amodei-day-after-agi.md` — source summary; five video fields + `#t|direct` claims + claim-level hedging; extraction_tool/model/date name the real local tools (NOT template-public — D-07)
- `wiki-cloud/entities/demis-hassabis.md` — Google DeepMind CEO; cautious-timeline position
- `wiki-cloud/entities/dario-amodei.md` — Anthropic CEO; faster-timeline + no-chips-to-adversaries policy
- `wiki-cloud/concepts/agi-timelines.md` — the debate's central axis (Amodei faster vs Hassabis cautious)
- `wiki-cloud/concepts/ai-self-improvement-loop.md` — the coding/AI-research loop whose closure rate sets the timeline
- `wiki-cloud/decisions/dr-2026-06-14-video-ingestion.md` — schema-update DR
- `wiki-cloud/entities/anthropic.md` — added Dario Amodei backlink in Related Pages
- `wiki-cloud/index.md` — catalog entries for the source + 2 entities + 2 concepts + the DR
- `wiki-cloud/log.md` — ingest entry, lint health-check entry, reflect entry
- `wiki-cloud/maintenance/lint-report.md` — refreshed by the reserved non-dry-run yaml lint

## Decisions Made

- **Diarization mended by content, not rerun (D-03 branch b).** Raw pyannote+whisper output gave 3 distinct labels but unfaithfully — the two guests collapsed onto one label and answers bled into the host's segments because whisper segment boundaries did not align with diarization turns. Branch (a) rerun would not fix boundary misalignment, and branch (c) reject was unwarranted (the content unambiguously identifies each speaker). Mending to HOST/HASSABIS/AMODEI/AUDIENCE by content attribution, splitting merged Q/A turns, is exactly what D-03 permits and what the human instructed.
- **Authored the optional DR.** CONTEXT.md L50 leaves this to Claude's discretion; the four deliberate divergences from the PDF sub-case are a non-trivial design statement (mirroring the Phase 18/19/20 precedent), so the DR was authored.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Installed missing torchcodec dependency into the local STT venv**
- **Found during:** Task 3 (acquisition)
- **Issue:** The first `stt` run downloaded + transcribed the audio but the diarization pass crashed with `TorchCodec is required for load_with_torchcodec`. torch 2.10.0 defers audio decoding to torchcodec, which was absent from the STT tool venv. No transcript file was written.
- **Fix:** Installed torchcodec into the uv tool venv, pinning to `0.10.0` after `0.14.0` (too new — shared-lib load failure) and `0.9.0` (C++ ABI mismatch: `undefined symbol: _ZN3c1013MessageLoggerC1EPKcii`) both failed against torch 2.10.0. Re-transcribed from the already-downloaded mp3 (no re-download), and diarization completed.
- **Files modified:** none in the repo (environment-only fix in `~/.local/share/uv/tools/stt/`)
- **Verification:** `AudioDecoder` imports cleanly; the diarization pass produced a 3-speaker transcript; recorded in the source summary `extraction_model` and the log ingest entry.
- **Committed in:** n/a (no repo file changed by the env fix)

**2. [Rule 1 - Bug] Converted bin/ingest.sh bundle-dir output to the flat single-file form (D-05)**
- **Found during:** Task 3 (ingest step 4)
- **Issue:** The plan's step 4 expected `bin/ingest.sh --slug <slug> <file>` to produce a single-file source path, but `bin/ingest.sh` always creates a bundle dir `sources/.../YYYY-MM-DD-<slug>/source.md`. D-05 and the plan's own acceptance criterion require a flat single `.md` file with NO bundle dir.
- **Fix:** `git mv` the bundled `source.md` to `sources/2026/2026-06/2026-06-14-<slug>.md` and removed the empty bundle dir; content_hash unchanged.
- **Files modified:** sources/2026/2026-06/2026-06-14-hassabis-amodei-day-after-agi.md (final flat path)
- **Verification:** `find sources -name '*<slug>*.md' -not -path '*/source.md'` returns the flat path; no bundle dir exists; cloud-safe guard + audit pass against the flat file.
- **Committed in:** 7299091 (Task 3 ingest commit)

---

**Total deviations:** 2 auto-fixed (1 Rule-3 blocking dependency, 1 Rule-1 D-05 conformance)
**Impact on plan:** Both were necessary to complete the validation exactly as the decisions require. The torchcodec fix is environment-only (no template-public surface touched). The single-file conversion enforces D-05. No scope creep.

## Issues Encountered

- **Video duration over the ~5-20 min target (31:11).** The human explicitly supplied this exact URL and confirmed 3 speakers, so the duration was accepted — local faster-whisper handled the ~31-min audio in a few minutes. Noted here for traceability against D-12's practicality guideline.
- **`google-deepmind` red link.** `demis-hassabis.md` links `[[google-deepmind|Google DeepMind]]`, which has no page yet. Red links are explicitly allowed and intentional (signal a knowledge gap, tracked by lint as a non-gating warning); the crossref delta confirmed no new gating error from the new pages. A future ingest can fill it.

## Known Stubs

None. Every page is wired to the committed transcript via real `#t|direct` provenance; no placeholder/empty-data stubs.

## User Setup Required

None — no external service configuration required. (The torchcodec dependency was installed into the existing local STT tool venv as part of the blocking-issue fix.)

## Next Phase Readiness

- VID-04 is satisfied: a real YouTube video is acquired, ingested as a single-file transcript sub-case, and its wiki pages carry timestamp-anchored provenance the audit resolves.
- The multi-speaker SPEAKER: path (D-03) is exercised end-to-end; the convention's "mend raw labels at ingest" allowance proved load-bearing in practice.
- Phase 21 plans 01 + 02 are both complete; the phase is ready for verification/close.
- wiki-local audit control-plane (`audit-report.md`, `audit-state.md`) left as uncommitted local state by design; pre-existing dirty `.planning/config.json` not touched.

## Self-Check: PASSED

All 8 claimed files exist on disk; both task commits (`7299091`, `e2b7abb`) exist in git history.

---
*Phase: 21-video-youtube-ingestion*
*Completed: 2026-06-14*
