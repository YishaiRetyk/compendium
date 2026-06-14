---
phase: 21-video-youtube-ingestion
verified: 2026-06-14T00:00:00Z
status: passed
score: 4/4
overrides_applied: 0
---

# Phase 21: Video/YouTube Ingestion — Verification Report

**Phase Goal:** YouTube videos can be acquired via a documented pipeline and ingested as a sub-case of the transcript source type, with timestamp-anchored provenance and a clear drift stance.
**Verified:** 2026-06-14
**Status:** PASSED
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Documented video acquisition pipeline exists in `schema/` (tool-generic yt-dlp + timestamped STT, no personal tool name on template-public surface) | VERIFIED | `schema/reference/video-ingestion.md` exists, 86 lines, names yt-dlp-or-equivalent contract; `bin/check-neutrality.sh` exits 0; no personal STT tool name present |
| 2 | Video source summary records url, channel, title, publish_date (ISO), duration; every claim uses `#t<start>-<end>` locators | VERIFIED | `wiki-cloud/sources/src-2026-06-14-hassabis-amodei-day-after-agi.md` has all five fields with ISO `publish_date: 2026-01-20`; 37 claims all use `#t` locators with `\|direct\|`; claim-level `[epistemic:: tentative]` hedging present |
| 3 | Convention explicitly states drift stance: immutable once published, link-rot is the only concern, no drift machinery | VERIFIED | `schema/reference/video-ingestion.md` L19: "Drift: Unchanged — static after recording; the committed transcript is the durable archive, and link-rot of url is the only concern (D-06)"; Section 5 Decision Record confirms "no drift machinery" as a deliberate choice |
| 4 | One real YouTube video acquired via pipeline, ingested, wiki pages in `sources/` with timestamp-anchored provenance | VERIFIED | `sources/2026/2026-06/2026-06-14-hassabis-amodei-day-after-agi.md` exists as a SINGLE .md file (no bundle dir); 4 distinct speaker labels (HOST, HASSABIS, AMODEI, AUDIENCE); `[H:MM:SS] SPEAKER: text` lines throughout; post-commit audit: 37 claims selected, 0 `insufficient-locator` verdicts |

**Score:** 4/4 truths verified

---

## Required Artifacts

### Plan 01 Artifacts (Schema Machinery)

| Artifact | Status | Evidence |
|----------|--------|----------|
| `schema/reference/video-ingestion.md` | VERIFIED | Exists, 86 lines (>= 55), all 8 sections present, sub-case-of-transcript verdict, five VID-02 fields, #t locator usage, N=3 spot-verify tiered policy, tool-generic runbook, no --asset, no named bin script, no lint mandate |
| `schema/reference/source-types.md` | VERIFIED | Video row finalized: `| video | sub-case of transcript | Acquisition (always); Epistemic Default (degraded audio only) | schema/reference/video-ingestion.md | ...` — no "provisional"; section-3 retro-fit table still has exactly 7 type rows |
| `schema/reference/frontmatter.md` | VERIFIED | `channel:`, `publish_date:`, `duration:` fields present with `<stt-tool>` / `<asr-model>` neutral placeholders; convention-only comment present; `url` reused (not duplicated) |
| `schema/workflows/ingest.md` | VERIFIED | Pass-0 one-line video sub-bullet present: "Video / YouTube sources: a video is a sub-case of transcript, NOT a new source_type... See schema/reference/video-ingestion.md" |
| `AGENTS.md` | VERIFIED | Routing row present at L52; inclusion-audit baseline 290 matches `wc -l` 290 |
| `CLAUDE.md` | VERIFIED | `cmp -s AGENTS.md CLAUDE.md` exits 0; `bash bin/sync-claude.sh --check` reports "OK" |
| `schema/AGENTS.template.md` | VERIFIED | Routing row present at L53 |
| `schema/fixtures/canonical-AGENTS.md` | VERIFIED | Routing row present; `bash tests/phase-08/test_canonical_byte_equality.sh` passes (PASS: MANUAL-06 byte-equality) |

### Plan 02 Artifacts (End-to-End Validation)

| Artifact | Status | Evidence |
|----------|--------|----------|
| `sources/2026/2026-06/2026-06-14-hassabis-amodei-day-after-agi.md` | VERIFIED | Single .md file (no bundle dir); `source_type: transcript`; `[H:MM:SS] SPEAKER: text` lines; 4 distinct speaker labels; `privacy: cloud_safe` |
| `wiki-cloud/sources/src-2026-06-14-hassabis-amodei-day-after-agi.md` | VERIFIED | All 5 video fields present; `#t` locators with `\|direct\|`; `[epistemic:: tentative]` hedging on STT failure surface; `epistemic_status: sourced`; `source_type: transcript` |
| `wiki-cloud/entities/demis-hassabis.md` | VERIFIED | Exists; 8 `#t` locators linking to the new source |
| `wiki-cloud/entities/dario-amodei.md` | VERIFIED | Exists; 10 `#t` locators linking to the new source |
| `wiki-cloud/concepts/agi-timelines.md` | VERIFIED | Exists; 8 `#t` locators linking to the new source |
| `wiki-cloud/concepts/ai-self-improvement-loop.md` | VERIFIED | Exists; #t locators present |
| `wiki-cloud/decisions/dr-2026-06-14-video-ingestion.md` | VERIFIED | `trigger_type: schema-update`; `type: decision`; all required sections (TL;DR, Decision, Why, Alternatives Considered, Consequences, Affected Pages, Sources); registered in `wiki-cloud/index.md`; `bin/check-neutrality.sh` exits 0 |
| `wiki-cloud/index.md` | VERIFIED | References both the new source and the decision record |
| `wiki-cloud/log.md` | VERIFIED | Ingest entry for the video and reflect entry for the decision record both present |

---

## Key Link Verification

| From | To | Via | Status | Evidence |
|------|----|-----|--------|----------|
| `AGENTS.md` | `schema/reference/video-ingestion.md` | routing-table row at L52 | WIRED | `grep -q 'video-ingestion.md' AGENTS.md` passes |
| `CLAUDE.md` | `AGENTS.md` | byte-equality via `bin/sync-claude.sh` | WIRED | `cmp -s AGENTS.md CLAUDE.md` exits 0 |
| `schema/reference/source-types.md` | `schema/reference/video-ingestion.md` | Convention Doc column in video row | WIRED | `grep -q 'video-ingestion.md' schema/reference/source-types.md` passes |
| `schema/workflows/ingest.md` | `schema/reference/video-ingestion.md` | Pass-0 video sub-bullet | WIRED | `grep -q 'video-ingestion.md' schema/workflows/ingest.md` passes |
| `schema/AGENTS.template.md` | `schema/reference/video-ingestion.md` | wizard-source routing row | WIRED | Present at L53; fixture regenerated and byte-equal |
| `wiki-cloud/sources/src-2026-06-14-hassabis-amodei-day-after-agi.md` | `sources/.../hassabis-amodei-day-after-agi.md` [H:MM:SS] lines | `#t<start>-<end>` locators in claim provenance | WIRED | 37 claims selected by post-commit audit, 0 `insufficient-locator` |

---

## Data-Flow Trace (Level 4)

| Artifact | Data Source | Produces Real Data | Status |
|----------|-------------|-------------------|--------|
| `sources/.../hassabis-amodei-day-after-agi.md` | Local STT acquisition (tool-generic pipeline); metadata from yt-dlp | Yes — full transcript with [H:MM:SS] SPEAKER: lines, video frontmatter | FLOWING |
| `wiki-cloud/sources/src-2026-06-14-hassabis-amodei-day-after-agi.md` | Claims extracted from the committed transcript via #t locators | Yes — 37 claims with direct provenance and claim-level hedging | FLOWING |
| Post-commit audit | `bin/audit-claims.sh --since PRE_REF --sample 100 --format json` | Selected 37 claims for `src-2026-06-14-hassabis-amodei-day-after-agi`; 0 insufficient-locator verdicts | VERIFIED |

---

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| `video-ingestion.md` sub-case-of-transcript verdict | `grep -q "sub-case of \`transcript\`" schema/reference/video-ingestion.md` | Found at L10 | PASS |
| D-11 support_type direct; no derived | `grep -q "support_type: direct" && ! grep -q "support_type: derived"` | Both conditions met | PASS |
| D-07 no lint mandate (no "Lint requires") | `! grep -qi "lint requires" schema/reference/video-ingestion.md` | Absent — file says "explicitly NOT validated by lint" | PASS |
| D-05 no --asset in convention | `! grep -q -- "--asset" schema/reference/video-ingestion.md` | Absent | PASS |
| AGENTS.md/CLAUDE.md byte-identity | `cmp -s AGENTS.md CLAUDE.md` | Exit 0 | PASS |
| Fixture byte-equality | `bash tests/phase-08/test_canonical_byte_equality.sh` | PASS: MANUAL-06 byte-equality | PASS |
| Lint yaml | `bash bin/lint.sh --ci --dry-run --category yaml` | Errors: 0, Warnings: 0, Exit 0 | PASS |
| Lint routing | `bash bin/lint.sh --ci --dry-run --category routing` | Errors: 0, Warnings: 0, Exit 0 | PASS |
| Neutrality | `bash bin/check-neutrality.sh` | Exit 0 (no output) | PASS |
| Skills overlay | `bash bin/gen-skills.sh --check` | "OK: .claude/skills/ matches template" | PASS |
| Cloud-safe guard | `bash bin/check-sources-cloud-safe.sh` | "OK: all raw sources cloud-safe (27 files checked)" | PASS |
| Single-file transcript (no bundle dir) | `[ ! -d "sources/2026/2026-06/2026-06-14-hassabis-amodei-day-after-agi" ]` | No bundle dir exists | PASS |
| Distinct speaker labels >= 2 | `grep -oE ...` distinct unique labels | HOST, HASSABIS, AMODEI, AUDIENCE (4 distinct) | PASS |
| Post-commit audit — source selected, 0 insufficient-locator | `bash bin/audit-claims.sh --since 1e638eb --sample 100 --format json` | Selected: 37, insufficient-locator: 0 | PASS |
| 7-row section-3 retro-fit table | `grep -cE ...` | 7 | PASS |
| Inclusion-audit baseline matches wc -l | `inclusion-audit: 290 == wc -l: 290` | Match | PASS |

---

## Requirements Coverage

| Requirement | Phase | Description | Status | Evidence |
|-------------|-------|-------------|--------|----------|
| VID-01 | 21 (Plan 01) | Documented video acquisition pipeline: yt-dlp + timestamped STT, tool-generic, template-public docs contain no personal tool name | SATISFIED | `schema/reference/video-ingestion.md` §5 Acquisition Runbook; neutrality passes; routing-table row in AGENTS.md/CLAUDE.md |
| VID-02 | 21 (Plan 01 + 02) | Video sub-case convention: five frontmatter fields (url, channel, title, publish_date, duration); claims use `#t<start>-<end>` locators | SATISFIED | Five fields in `schema/reference/frontmatter.md`; five fields present in the ingested source summary; 37 `#t` locators with `\|direct\|` in source summary and topic pages |
| VID-03 | 21 (Plan 01) | Convention documents drift stance: immutable once published; link-rot is the only concern; no drift machinery | SATISFIED | `schema/reference/video-ingestion.md` Drift row: "static after recording; durable archive; link-rot of url is the only concern (D-06)"; DR §5 confirms "no drift machinery"; extraction fields convention-only (not lint-enforced, D-07) |
| VID-04 | 21 (Plan 02) | One real YouTube video acquired via pipeline, ingested, wiki pages with timestamp-anchored provenance | SATISFIED | `sources/2026/2026-06/2026-06-14-hassabis-amodei-day-after-agi.md` (single .md, multi-speaker transcript with 4 labels); source summary + entity/concept topic pages in `wiki-cloud/`; post-commit audit: 37 claims, 0 insufficient-locator |

All four requirements SATISFIED with no orphans.

---

## Anti-Patterns Found

No blockers detected.

| File | Pattern Checked | Result |
|------|----------------|--------|
| `schema/reference/video-ingestion.md` | TODO/FIXME/placeholder | None found |
| `schema/reference/video-ingestion.md` | `return null` / empty implementation | N/A (Markdown doc) |
| `schema/reference/video-ingestion.md` | Personal STT tool name (neutrality) | None — `bin/check-neutrality.sh` exits 0 |
| `wiki-cloud/decisions/dr-2026-06-14-video-ingestion.md` | Personal STT tool name (template-public surface) | None — file uses "a timestamped STT engine" generic phrasing; neutrality passes |
| `sources/.../hassabis-amodei-day-after-agi.md` | `source_type: video` (forbidden — must be transcript) | Absent; `source_type: transcript` confirmed |
| `schema/reference/video-ingestion.md` | `support_type: derived` (epistemic-laundering anti-pattern) | Absent; `support_type: direct` present |
| `schema/reference/video-ingestion.md` | "Lint requires" mandate (D-07 divergence) | Absent; "explicitly NOT validated by lint" present |

---

## Human Verification Required

None. All success criteria are verifiable programmatically for this schema/convention phase. The video content is live at `https://www.youtube.com/watch?v=02YLwsCKUww` if spot-verification of STT accuracy is desired, but this is not a phase gate — the post-commit audit confirms all 37 `#t` locators resolve against the committed transcript, and the plan classified this as clean spoken-word audio (sourced tier, not tentative).

---

## Gaps Summary

No gaps. All four roadmap success criteria are verified against the actual codebase.

---

_Verified: 2026-06-14T00:00:00Z_
_Verifier: Claude (gsd-verifier)_
