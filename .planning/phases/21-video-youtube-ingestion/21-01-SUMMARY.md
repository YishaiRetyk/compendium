---
phase: 21-video-youtube-ingestion
plan: 01
subsystem: schema
tags: [video, youtube, transcript, stt, convention, source-types, frontmatter, routing]

# Dependency graph
requires:
  - phase: 19-extension-contract-research-report
    provides: "5-dimension source-type extension contract + sub-case-vs-new-enum decision rule in source-types.md; #r locator + audit selector precedent"
  - phase: 20-pdf-ingestion
    provides: "pdf-ingestion.md 8-section convention-doc skeleton + tiered epistemic policy + tool-generic-contract-with-worked-instance posture + routing/byte-sync/fixture-regen pattern"
provides:
  - "schema/reference/video-ingestion.md — authoritative video-as-sub-case-of-transcript convention + tool-generic acquisition runbook (lazy-loaded via routing table)"
  - "Finalized source-types.md section-4 video registry row (sub-case of transcript, no longer provisional)"
  - "Five video sub-case frontmatter fields (url, channel, title, publish_date, duration) + convention-only extraction_* fields documented in frontmatter.md"
  - "Pass-0 video classification pointer in ingest.md"
  - "video-ingestion.md routing-table row in AGENTS.md (byte-synced to CLAUDE.md), schema/AGENTS.template.md, and regenerated canonical-AGENTS.md fixture"
affects: [21-02 (validation ingest of a real multi-speaker YouTube video — consumes this convention)]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Sub-case-on-existing-type (not new enum) — video absorbed by transcript, mirroring Phase 20 PDF format-orthogonal framing"
    - "Tool-generic template-public convention with the worked instance kept in .planning/ only (D-04 neutrality posture)"
    - "Routing-row + sync-claude byte-equality + template-mirror + fixture-regen-in-same-commit (Phase 16/19/20 pattern)"

key-files:
  created:
    - "schema/reference/video-ingestion.md"
  modified:
    - "schema/reference/source-types.md"
    - "schema/reference/frontmatter.md"
    - "schema/workflows/ingest.md"
    - "AGENTS.md"
    - "CLAUDE.md"
    - "schema/AGENTS.template.md"
    - "schema/fixtures/canonical-AGENTS.md"

key-decisions:
  - "Convention shipped as a new schema/reference/video-ingestion.md (Phase 20 PDF pattern) rather than extending an existing transcript doc — gets its own routing row + byte-sync + fixture-regen"
  - "Single-hour-digit [H:MM:SS] timestamp form chosen for the convention (matches existing transcripts; audit TS_RE tolerates all forms)"
  - "N=3 spot-verify segment selection = first / middle / last (analogous to the PDF first/middle/last page sampling; catches cold-start, mid-stream, and tail transcription drift)"
  - "extraction_tool/extraction_model use neutral placeholders (<stt-tool>/<asr-model>) in frontmatter.md — diverges from the PDF block's public model tag because the personal STT tool is forbidden on template-public surfaces"

patterns-established:
  - "Deliberately-lighter sub-case re-skin: video DROPS the PDF lint mandate (D-07), the --asset mechanism (D-05), and the named worked instance + bin/ script (D-04), and re-aims spot-verification at the live url (D-10)"
  - "Convention-only frontmatter fields (recorded but explicitly NOT lint-enforced) when no mechanical trigger distinguishes the sub-case"

requirements-completed: [VID-01, VID-02, VID-03]

# Metrics
duration: 3min
completed: 2026-06-14
---

# Phase 21 Plan 01: Video Ingestion Convention Summary

**Authored `schema/reference/video-ingestion.md` (video as a sub-case of `transcript`, tool-generic `yt-dlp`+STT acquisition runbook with no repo script and no worked-instance name) and wired it into the schema machinery — finalized the source-types.md registry row, documented the five VID-02 frontmatter fields, added a Pass-0 classify pointer, and propagated a routing row through AGENTS.md / byte-synced CLAUDE.md / template / regenerated fixture.**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-06-14T12:16:23Z
- **Completed:** 2026-06-14T12:19:47Z
- **Tasks:** 3 completed
- **Files modified:** 8 (1 created, 7 modified)

## Accomplishments
- New authoritative convention doc (`video-ingestion.md`, 86 lines) covering all 8 required sections — classification (sub-case of transcript, D-14), the five frontmatter fields + convention-only extraction fields, `#t` locator usage with `support_type: direct`, the tiered epistemic policy (clean → sourced + mandated hedging; degraded → tentative + N=3 live-url spot-verify), the tool-generic acquisition runbook, the single-file ingest checklist, and a See Also block.
- All four deliberate divergences from `pdf-ingestion.md` applied and verified: D-04 (no `bin/` script, no worked-instance name — only the public `yt-dlp` is named), D-05 (no `--asset`, single `.md` file), D-06 (link-rot drift stance — committed transcript is the durable archive), D-07 (extraction fields convention-only, no lint mandate), D-10 (spot-verification re-watches the live `url` at the `#t` timestamp).
- Schema wiring completed atomically: the source-types.md video row is finalized (no longer provisional), the five fields land in frontmatter.md with neutral placeholders, ingest.md Pass-0 gains a one-line video pointer, and the routing row propagates through AGENTS.md → CLAUDE.md → template → fixture in one commit so the setup-parity byte-equality CI gate stays green.

## Task Commits

Tasks 1-3 landed as ONE `schema(21):` commit — one logical operation (CLAUDE.md §3: one-commit-per-logical-operation), which also makes two atomicity requirements trivial (the routing row + the file it points at land together; the template edit + regenerated fixture land together).

1. **Task 1: Author schema/reference/video-ingestion.md** - `f929411` (schema)
2. **Task 2: Finalize source-types.md video row + frontmatter.md fields + ingest.md pointer** - `f929411` (schema)
3. **Task 3: Routing row in AGENTS.md + byte-synced CLAUDE.md + template + regenerated fixture** - `f929411` (schema)

**Plan metadata:** (this SUMMARY + STATE.md + ROADMAP.md + REQUIREMENTS.md) committed separately as the final `docs(21-01):` commit.

## Files Created/Modified
- `schema/reference/video-ingestion.md` (created) — the authoritative video-as-sub-case-of-transcript convention + tool-generic acquisition runbook.
- `schema/reference/source-types.md` — section-4 video registry row finalized (sub-case of transcript verdict + Convention Doc pointer; dropped "provisional").
- `schema/reference/frontmatter.md` — added the video sub-case fields (channel, publish_date, duration + convention-only extraction_*) to the Source Summary Additional Fields block; url and title reused as base fields.
- `schema/workflows/ingest.md` — Pass-0 step 3 gains a one-line "Video / YouTube sources" sub-bullet.
- `AGENTS.md` — added the video-ingestion.md routing-table row; inclusion-audit baseline re-recorded (290 lines @ 2026-06-14).
- `CLAUDE.md` — byte-synced from AGENTS.md via `bin/sync-claude.sh` (never hand-edited).
- `schema/AGENTS.template.md` — mirrored the routing row (wizard source).
- `schema/fixtures/canonical-AGENTS.md` — regenerated from the edited template in the same commit (setup-parity byte-equality gate).

## Decisions Made
- New `schema/reference/video-ingestion.md` (vs. extending an existing transcript doc) — matched the Phase 20 PDF precedent; gets a routing row + byte-sync + fixture-regen.
- Single-hour-digit `[H:MM:SS]` timestamp form in the convention (matches the existing transcripts; `TS_RE` tolerates all hour-digit forms anyway).
- N=3 spot-verify selection = first / middle / last segment (direct analogy to PDF page sampling).
- Neutral placeholders (`<stt-tool>` / `<asr-model>`) for the video extraction fields in frontmatter.md — deliberate neutrality divergence from the PDF block's public model tag, since the personal STT tool name is forbidden on template-public surfaces.

## Deviations from Plan

None - plan executed exactly as written. All three tasks completed in order, all acceptance criteria and pre-commit gates passed on the first commit attempt (pre-staging CLAUDE.md + regenerating the fixture before commit collapsed the documented multi-attempt path to one).

## Issues Encountered
None. The baseline was clean (AGENTS.md ≡ CLAUDE.md, neutrality green, inclusion-audit baseline at 289 lines before the +1 routing row → 290). Pre-existing dirty working-tree files (`.planning/STATE.md`, `.planning/config.json`, `wiki-local/maintenance/audit-*.md`) were left untouched and excluded from the per-task commit (staged files individually, never `git add -A`).

## Authentication Gates
None.

## Verification Results

All plan-level verification and acceptance gates pass:
- `schema/reference/video-ingestion.md` exists, 86 lines (≥55), `support_type: direct` present, `support_type: derived` absent, `tentative`/`spot-verif`/`degraded`/`N = 3` present, `yt-dlp` present, no `bin/*-extract` script named, no `--asset`, no "lint requires" mandate (`convention-only` present), `link-rot` + `durable archive` present.
- source-types.md video row finalized (`sub-case of `transcript``, Convention Doc pointer, no "provisional"); the 7-value source_type enum and the transcript Retro-fit row untouched (7 type rows confirmed).
- frontmatter.md carries channel/publish_date/duration + the `<stt-tool>` placeholder; ingest.md Pass-0 has the video pointer.
- `bin/sync-claude.sh --check` exit 0; `cmp -s AGENTS.md CLAUDE.md` exit 0; inclusion-audit baseline (290) == `wc -l AGENTS.md` (290).
- `bash bin/lint.sh --ci --dry-run --category yaml` exit 0; `--category routing` exit 0.
- `bash tests/phase-08/test_canonical_byte_equality.sh` exit 0 (wizard render byte-equal to the regenerated fixture).
- `bash bin/check-neutrality.sh` exit 0; `bash bin/gen-skills.sh --check` exit 0.

## Threat Surface (T-21-01 mitigation)
Documentation/convention phase — no executable code added (D-04 ships no script), no input handling, no network/auth surface. The single trust boundary (template-public information disclosure, T-21-01) was mitigated at write-time: abstract placeholders (`<channel-name>`, `<stt-tool>`, `<asr-model>`) for all examples; only the public tool name `yt-dlp` named; no worked-instance name and no private vault slug in any template-public file. `bin/check-neutrality.sh` (the backstop gate) passes. No new threat surface introduced beyond the plan's threat model.

## Requirements Completed
- **VID-01 (doc half):** the tool-generic video acquisition pipeline (`yt-dlp`-equivalent + timestamped STT) is documented in an authoritative `schema/` file discoverable via the routing table; no personal tool name leaks (worked instance stays in `.planning/` notes).
- **VID-02 (convention):** the five video frontmatter fields are documented; claims use the existing `#t<start>-<end>` locators (not redefined); the source-types.md video row is finalized as a sub-case of transcript.
- **VID-03:** the convention documents the drift stance (immutable once published; link-rot is the only concern; no drift machinery) AND the tiered epistemic policy (clean → sourced + mandated hedging; degraded → tentative + N=3 live-url spot-verify); `support_type` stays direct.

> VID-04 (end-to-end validation ingest of a real multi-speaker YouTube video, human-checkpoint) is owned by Plan 21-02, not this plan.

## Self-Check: PASSED

All created/modified files verified present on disk; commit `f929411` verified in git history.
