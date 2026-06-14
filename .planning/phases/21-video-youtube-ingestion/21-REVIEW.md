---
phase: 21-video-youtube-ingestion
reviewed: 2026-06-14T17:10:00Z
depth: standard
files_reviewed: 19
files_reviewed_list:
  - AGENTS.md
  - CLAUDE.md
  - schema/AGENTS.template.md
  - schema/fixtures/canonical-AGENTS.md
  - schema/reference/frontmatter.md
  - schema/reference/source-types.md
  - schema/reference/video-ingestion.md
  - schema/workflows/ingest.md
  - sources/2026/2026-06/2026-06-14-hassabis-amodei-day-after-agi.md
  - wiki-cloud/concepts/agi-timelines.md
  - wiki-cloud/concepts/ai-self-improvement-loop.md
  - wiki-cloud/decisions/dr-2026-06-14-video-ingestion.md
  - wiki-cloud/entities/anthropic.md
  - wiki-cloud/entities/dario-amodei.md
  - wiki-cloud/entities/demis-hassabis.md
  - wiki-cloud/index.md
  - wiki-cloud/log.md
  - wiki-cloud/maintenance/lint-report.md
  - wiki-cloud/sources/src-2026-06-14-hassabis-amodei-day-after-agi.md
findings:
  critical: 0
  warning: 5
  info: 4
  total: 9
status: fixed
fixes_applied: 2026-06-14T18:00:00Z
fixes_summary: "5/5 warnings resolved (commit fix(21)); 4 info deferred (out of default --fix scope)"
---

# Phase 21: Code Review Report

**Reviewed:** 2026-06-14T17:10:00Z
**Depth:** standard
**Files Reviewed:** 19
**Status:** issues_found

## Summary

Phase 21 adds the "video is a sub-case of `transcript`" convention (a new authoritative `schema/reference/video-ingestion.md`, a finalized registry row, frontmatter fields, a decision record, and the first end-to-end video-acquired ingest of a Hassabis/Amodei panel). The core machinery is sound and I verified the high-risk surfaces empirically:

- **AGENTS.md ⇄ CLAUDE.md byte-equality holds** (`diff` identical; `sync-claude.sh --check` passes).
- **Neutrality gate passes** (`check-neutrality.sh` exit 0). The personal STT tool name is not leaked onto any template-public surface; the source-summary uses generic `extraction_tool: stt` plus public library names (`faster-whisper`, `pyannote`), which is permitted on real vault pages under D-07.
- **Provenance resolves.** I traced every `#t<start>-<end>` locator against `bin/audit-claims.sh`'s `TS_RE` parser and the committed transcript: all 14 distinct timestamp ranges land on real segment boundaries and resolve. `support_type: direct` is correct for a primary transcript source.
- **The `publish_date` 2026-01-20 vs filename 2026-06-14 question is NOT a bug.** The wiki dates source files by *ingest* date (confirmed against the prior PDF exemplar `2026-06-12-multi-agent-scientific-discovery`, whose paper was published 2026-05-19 but is filed under its ingest date), so `publish_date` correctly carries the separate publication date.
- **Lint passes with 0 errors**; no lint finding touches any Phase 21 file (verified by grep).

The defects below are documentation/traceability and convention-conformance issues, not correctness or security failures. Most consequential are three broken decision-record cross-references and a control-plane log entry that under-reports findings.

## Warnings

### WR-01: `source-types.md` registry row cites the wrong decision number for spot-verification

**File:** `schema/reference/source-types.md:50`
**Issue:** The finalized `video` registry row ends with "degraded audio gets `tentative` + N=3 spot-verification **(D-09)**." But in the authoritative `schema/reference/video-ingestion.md`, **D-09 is the claim-level hedging mandate** (line 56) and the **N=3 spot-verification divergence is D-10** (line 59). The decision record agrees with video-ingestion.md (D-09 = hedging, D-10 = spot-verification). Since video-ingestion.md is declared authoritative ("If you find a discrepancy between this file and AGENTS.md, this file wins"), the registry row carries a mislabeled D-number, breaking traceability from the registry to the decision rationale.
**Fix:** Change the trailing citation on the video row to `(D-10)` (or `(D-09/D-10)` if the intent is to reference both the hedging and the spot-verification decisions):
```
... Claims stay `support_type: direct`; degraded audio gets `tentative` + N=3 spot-verification (D-10). |
```

### WR-02: `log.md` ingest entry references a non-existent decision D-13

**File:** `wiki-cloud/log.md:742`
**Issue:** The Phase 21 ingest log entry attributes the tool-generic STT contract to "(D-04/D-13)". The video decision set (in `dr-2026-06-14-video-ingestion.md` and `video-ingestion.md`) defines the tool-generic contract as **D-04 only**; **D-13 is not defined anywhere in the video convention or DR.** D-13 appears to be copy-paste residue from the unrelated brownfield DR (`dr-2026-04-20-brownfield-apply-vs-advisory`, where D-13/D-14/D-15 govern `bootstrap_stage`). A reader following "D-13" lands on the wrong decision.
**Fix:** Drop the dangling reference — `(D-04)`:
```
... Acquired locally with the tool-generic STT contract (a video downloader + a timestamped speech-to-text engine, D-04) into a single timestamped transcript ...
```

### WR-03: `log.md` lint entries under-report findings vs the actual full lint run

**File:** `wiki-cloud/log.md` (the two `## [2026-06-14] lint` entries) and `wiki-cloud/maintenance/lint-report.md:26-28`
**Issue:** Both 2026-06-14 lint log entries (and the committed `lint-report.md`) record "**findings: 0 total** (0 errors, 0 warnings, 0 info)." A full unscoped `bin/lint.sh` run actually returns **0 errors but 69 warnings + 9 info (78 total)** — a pre-existing backlog of contradiction-candidates, crossref gaps, and red links from earlier (May/June) sources. The *first* log lint entry honestly scopes itself ("scope: yaml category … the unscoped --ci crossref gate carries a pre-existing backlog out of this phase's scope"), but the **second** lint entry records a bare "0 total (0 info)" with no scope qualifier, and the committed `lint-report.md` likewise presents "Total findings: 0" with no scope note. A reader of either artifact in isolation will believe the wiki is fully clean when it is not. This also masks WR-04 (a red link this very phase introduced).
**Fix:** Either record the true full-run counts in `lint-report.md` (0 errors / 69 warnings / 9 info) and the second log entry, or add the same scope qualifier the first entry carries so the "0" is unambiguously the scoped-gate result, not the wiki health total. The "0 errors" gating claim is true; the "0 total" framing is not.

### WR-04: New `google-deepmind` red link introduced but not recorded

**File:** `wiki-cloud/entities/demis-hassabis.md:36,58`
**Issue:** `demis-hassabis.md` links `[[google-deepmind|Google DeepMind]]` in both TL;DR and Related Pages, but no `wiki-cloud/entities/google-deepmind.md` page exists (verified: it is the *only* referencer, and the link was absent at the base commit — it is net-new this phase). Red links are permitted by the schema (they signal knowledge gaps), but this is asymmetric with the parallel `dario-amodei.md`, whose `[[anthropic|Anthropic]]` target *does* exist, and the gap is hidden by the inaccurate "0 info" lint accounting in WR-03 (a full lint surfaces it as `red-link:google-deepmind`). Demis Hassabis is the central subject of this phase's source yet his employing org has no page.
**Fix:** Either create a minimal `google-deepmind` entity page (the source supports several claims: the Gemini 3 rebound, the "engine room of Google" framing, AlphaFold/Isomorphic), or explicitly acknowledge the red link as a deliberate gap in the lint/log accounting so it is not silently dropped under a "0 findings" report.

### WR-05: D-09 claim-level hedging mandate applied inconsistently

**File:** `wiki-cloud/sources/src-2026-06-14-hassabis-amodei-day-after-agi.md:62,78,90`; also `wiki-cloud/concepts/ai-self-improvement-loop.md:41,42`
**Issue:** `video-ingestion.md` D-09 states the convention "**MANDATES** claim-level hedging on the STT failure surface: proper nouns / named entities, technical terms, numbers & statistics." Several claims that contain exactly those triggers carry no `[epistemic:: tentative]` marker — e.g. "Amodei cites **mechanistic interpretability** as **Anthropic's** research lineage" (line 62), "frames both **Anthropic** and **Google** as research-led companies" (line 78), "Amodei traces **Anthropic's** safety work to **mechanistic interpretability**" (line 90). Other claims naming the same entities/numbers (revenue figures, Gemini 3, AlphaFold/Isomorphic) *are* hedged, so the application is internally inconsistent. The author's Notes section documents a narrower intent (hedge proper nouns, numbers, and forward-looking/market-position claims), but that selective reading is in tension with the categorical mandate the convention ships.
**Fix:** Either (a) add `[epistemic:: tentative]` to the unhedged proper-noun/technical-term claims to satisfy the mandate as written, or (b) soften the D-09 language in `video-ingestion.md` from a categorical MUST to the judgment-based "STT-failure-surface where mis-transcription changes meaning" rule the implementation actually follows — so the spec and the worked instance agree.

## Info

### IN-01: First-mention-only wikilink rule violated on three new pages

**File:** `wiki-cloud/entities/dario-amodei.md:37,49`; `wiki-cloud/entities/demis-hassabis.md` (TL;DR + Detail); `wiki-cloud/concepts/agi-timelines.md:37,48`
**Issue:** `[[ai-self-improvement-loop|…]]` is linked twice in **body prose** (once in TL;DR, again in Detail) on each of these three pages. CLAUDE.md and `schema/reference/wikilinks.md:16` require "Link on FIRST mention only per page. Subsequent mentions are plain text." (Repeats in the Related Pages / Sources footer are the accepted exception and are fine.) Lint does not mechanically enforce this, so it slipped through, but the pre-existing pages (e.g. `anthropic.md`) follow the one-prose-link convention.
**Fix:** Demote the second prose occurrence of each repeated link to plain text, keeping the wikilink on first mention and in the Related Pages footer only.

### IN-02: `duration` format deviates from the documented convention

**File:** `wiki-cloud/sources/src-2026-06-14-hassabis-amodei-day-after-agi.md:38,113`
**Issue:** `duration: "31:11"` (and "Duration: 31:11" in the body) uses a clock format, but both `schema/reference/frontmatter.md:80` and `schema/reference/video-ingestion.md:34` document the field as a natural-language runtime, e.g. `"~12 min"`. The value is internally correct (1871s = 31:11, per the log), only the format diverges from the spec example.
**Fix:** Normalize to the documented form (`"~31 min"`), or update the spec examples to permit `MM:SS` if the clock format is intended to be canonical.

### IN-03: `## Source Metadata` body block duplicates frontmatter and can drift

**File:** `wiki-cloud/sources/src-2026-06-14-hassabis-amodei-day-after-agi.md:107-120`
**Issue:** Channel, URL, publish date, and duration are restated in a body `## Source Metadata` section that mirrors the frontmatter. They agree today, but two copies of the same facts (one machine-read in YAML, one prose) is a future drift hazard with no lint syncing them. Not present on the PDF exemplar's pattern in the same form.
**Fix:** Optional — keep the frontmatter as the single source of truth and trim the body block to only the narrative (the yt-dlp cross-check note), or accept the duplication as deliberate human-readable redundancy.

### IN-04: `inclusion-audit` baseline comment bumped without a recorded WF-08 re-run

**File:** `AGENTS.md:7` / `CLAUDE.md:7`
**Issue:** The resident-core baseline comment was updated `289 lines @ 2026-06-11` → `290 lines @ 2026-06-14` to account for the one added routing-table row. The adjacent instruction says "Re-run WF-08 and update this baseline." The +1 line is correct and justified (a dispatch routing row), but there is no artifact confirming the WF-08 inclusion test was actually re-run rather than the count being hand-edited.
**Fix:** Confirm the WF-08 re-run happened (or note it in the phase summary); no content change needed if the audit was performed.

---

## Fixes Applied (2026-06-14)

Applied via `/gsd-code-review fix 21` (default scope: Critical + Warning). Committed as `fix(21): apply code review warnings`.

| Finding | Disposition | What changed |
|---------|-------------|--------------|
| WR-01 | ✅ Fixed | `schema/reference/source-types.md` video row: spot-verification citation `(D-09)` → `(D-10)` (D-09 is the hedging mandate; D-10 is the spot-verification divergence, per authoritative `video-ingestion.md`). |
| WR-02 | ✅ Fixed | `wiki-cloud/log.md` ingest entry: `(D-04/D-13)` → `(D-04)`. D-13 is a planning-internal CONTEXT decision (local execution), unresolvable from the public wiki and not the tool-generic-contract decision. |
| WR-03 | ✅ Fixed | Added the scope qualifier (with true counts) to the second `2026-06-14 lint` log entry, and regenerated `wiki-cloud/maintenance/lint-report.md` via a full `bin/lint.sh` run so the standalone report shows honest wiki health: **0 errors / 69 warnings / 9 info (78 total)** instead of the scoped "0 total". |
| WR-04 | ◑ Accounting fixed; page deferred | The `google-deepmind` red link is permitted by the schema; it is no longer masked — the regenerated report and qualified log entry now surface it explicitly. A dedicated `google-deepmind` entity page was **not** authored (content authoring is beyond review-fix scope) — recommended as a follow-up ingest/query. |
| WR-05 | ✅ Fixed (option a) | Added the missing `[epistemic:: tentative]` markers on the STT-failure-surface claims (mechanistic-interpretability / proper-noun / technical-term claims) in `src-2026-06-14-hassabis-amodei-day-after-agi.md` (L62/78/90) and `ai-self-improvement-loop.md` (L41/42), conforming the data to the categorical D-09 mandate. Softening D-09 to a judgment-based rule (option b) was **not** taken — that is an authoritative-schema change that warrants a deliberate reflect/decision-record, not a silent review-fix edit. |

**Info findings IN-01…IN-04** were not addressed — the default `--fix` scope is Critical + Warning. Re-run with `--all` to include them, or address individually:
- IN-01 first-mention-only wikilink repeats (3 pages)
- IN-02 `duration` clock-format vs documented `~N min`
- IN-03 `## Source Metadata` body/frontmatter duplication
- IN-04 confirm the WF-08 inclusion-audit re-run

---

_Reviewed: 2026-06-14T17:10:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Fixes applied: 2026-06-14T18:00:00Z (Claude)_
_Depth: standard_
