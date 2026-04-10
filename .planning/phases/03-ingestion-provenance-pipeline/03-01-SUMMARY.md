---
phase: 03-ingestion-provenance-pipeline
plan: 01
subsystem: ingestion-pipeline-spec
tags:
  - agents-md
  - pipeline
  - granularity
  - update-policy
  - source-types
requirements:
  - CMPL-01
  - CMPL-02
  - CMPL-03
  - CMPL-04
  - CMPL-05
  - CMPL-06
  - CMPL-07
  - PROV-05
  - INGST-01
  - INGST-02
dependency_graph:
  requires:
    - Phase 01 schema-structure-conventions (pipeline passes, UPDATE operation, provenance syntax)
    - Phase 02 page-types-examples-navigation (existing example source summary page)
  provides:
    - Operational claim granularity rules (D-01 through D-05) that any LLM agent can execute
    - Operational incremental update policy (D-06 through D-10) that governs wiki integration
    - Canonical book-chapter source type (replaces legacy book)
  affects:
    - AGENTS.md sections 9, 10, 11.1
    - wiki/sources/ example page
tech-stack:
  added: []
  patterns:
    - append-then-synthesize incremental update policy
    - adaptive claim granularity driven by source type classification
    - softened stale/supersede wording to avoid front-running Phase 5
key-files:
  created: []
  modified:
    - AGENTS.md
    - wiki/sources/src-2026-04-09-thinking-fast-and-slow-part1.md
decisions:
  - Book content uses book-chapter as the single canonical source type (not book); full books ingested as sequence of chapters
  - Claim granularity follows "smallest unit that preserves meaningful provenance without making the page unreadable" — atomic for articles/papers, mixed for books/essays, grouped for transcripts/journals, image-locator-tied for mixed media
  - Incremental updates follow append-then-synthesize: append in detail layer, re-synthesize summary layer every update, supersede explicitly, framing shifts go to decision records
  - Supersede/stale wording deliberately softened to reference "current schema conventions" and defer formal contradiction semantics to Phase 5
  - Logs and source summary pages are strict append-only exceptions to the append-then-synthesize default
metrics:
  duration_min: 2
  tasks_completed: 2
  files_changed: 2
  completed_date: 2026-04-10
---

# Phase 03 Plan 01: Encode Claim Granularity and Incremental Update Policy Summary

Encoded user decisions D-01 through D-10 into AGENTS.md sections 9, 10, and 11.1 to make the ingestion pipeline fully operational for any LLM agent, and normalized the legacy book source type to book-chapter.

## Overview

Before this plan, AGENTS.md described WHAT each pipeline pass did but lacked the granularity rules (how fine to extract claims) and update policy (how to merge new material into existing pages). Agents reading the schema could not unambiguously execute the ingest pipeline. This plan closes both gaps by encoding the two key operational decisions into the conceptual pipeline section (Pass 2 and Pass 3) and cross-referencing them from both the structured operations section and the ingest workflow. It also locks book-chapter as the single canonical source type for book content and normalizes the existing example source summary page that used the legacy book value.

## What Was Built

### Task 1: Claim Granularity Rules + book-chapter Normalization

**Commit:** `75c19aa`

- Added book-chapter to the Pass 0 (Classify) source type enumeration as the canonical type for book content. Added a note clarifying that full books are ingested as a sequence of book-chapter sources and that the legacy book value is no longer accepted.
- Added a Claim Granularity Rules subsection to Pass 2 (Extract) containing the guiding heuristic "the smallest unit that preserves meaningful provenance without making the page unreadable", a 4-row table mapping source types to default granularity and guidance, and a bias-toward-atomic split/group decision rule.
- Updated workflow step 5 (Extract) in section 11.1 to explicitly cross-reference "the claim granularity rules from Section 10 Pass 2 based on the source type classified in step 3".
- Normalized `wiki/sources/src-2026-04-09-thinking-fast-and-slow-part1.md` frontmatter from `source_type: book` to `source_type: book-chapter`.

### Task 2: Incremental Update Policy (Append-Then-Synthesize)

**Commit:** `1666839`

- Added an Incremental Update Policy: Append-Then-Synthesize subsection to Pass 3 (Merge) with the four-step policy: (1) append in detail layer, (2) mark superseded/stale per current schema conventions, (3) re-synthesize summary layer, (4) record framing shifts in decision entries.
- Added an Exceptions block covering strict-append-only logs/source summaries and the exceptional full-section-rewrite case.
- Included the mantra: "Append in the detail layer, synthesize in the summary layer, supersede explicitly when needed."
- Deliberately softened supersede/stale wording by referencing "current schema conventions" and stating "Phase 5 will formalize the exact contradiction and staleness semantics" so this plan does not front-run Phase 5's formal contradiction workflow.
- Added cross-reference at the end of the Section 9 UPDATE operation definition pointing to Section 10 Pass 3 (Append-Then-Synthesize).
- Updated workflow step 6 (Merge) in section 11.1 to reference "the append-then-synthesize policy (Section 10 Pass 3)".

## Verification Results

All plan verification queries pass:

- `grep -c 'book-chapter' AGENTS.md` returns 3 (>= 2 required)
- `grep -c 'Claim Granularity Rules' AGENTS.md` returns 1
- `grep -c 'Append-Then-Synthesize' AGENTS.md` returns 2 (header + section 9 cross-ref)
- `grep -ci 'append-then-synthesize' AGENTS.md` returns 3 (header + section 9 + section 11.1 lowercase cross-ref)
- `grep 'per current schema conventions' AGENTS.md` matches (softened wording confirmed)
- `grep 'Phase 5 will formalize' AGENTS.md` matches
- `grep 'source_type: book-chapter' wiki/sources/src-2026-04-09-thinking-fast-and-slow-part1.md` matches
- No `source_type: book` (bare) remains in the source file
- All 16 top-level `## N.` section headers in AGENTS.md still present (no deletions to existing structure)

## Deviations from Plan

None - plan executed exactly as written. The plan's final verification block specifies `grep -c 'append-then-synthesize' AGENTS.md >= 3`, which depends on case-sensitivity interpretation; the header and Section 9 cross-reference use title case "Append-Then-Synthesize" while the Section 11.1 cross-reference uses lowercase "append-then-synthesize". Under case-insensitive matching (the clear intent — "header + section 9 ref + section 11.1 ref") all three references exist as specified in the plan body and all acceptance criteria are satisfied. No content change was needed; this is a note about the verification command's case-sensitivity, not a deviation.

## Key Decisions Made

1. **book-chapter is canonical, not book.** Full books must be ingested as a sequence of chapter-level sources. This enables per-chapter provenance, cleaner diffs, and progressive ingestion. Encoded as a Pass 0 note that explicitly says "`book` is no longer accepted."

2. **Granularity heuristic is source-type driven.** Different source types warrant different extraction depths. Articles and papers get atomic claims; book-chapters and essays get mixed atomic/paragraph; transcripts and journal entries get paragraph-level clusters; image-heavy sources tie provenance to specific visual elements.

3. **Append-then-synthesize is the default for living pages; strict append-only is an exception for records.** Logs and source summaries are records, not living synthesis, so they never get rewritten. Full section rewrite is reserved for exceptional cases only and requires a decision record.

4. **Softened stale/supersede wording.** This plan encodes the shape of the policy (mark superseded claims, preserve the provenance trail, add notes) without committing to specific contradiction semantics. Those are deferred to Phase 5.

5. **All edits located by section heading, never by line number.** AGENTS.md may drift between planning and execution; edits used heading-string matching exclusively.

## Impact

Any LLM agent reading AGENTS.md sections 9, 10, and 11.1 can now unambiguously execute the full ingest pipeline: the source type enumeration tells them what classifications exist, Pass 2 tells them how fine to extract claims for each type, and Pass 3 tells them how to integrate new claims into existing pages without destroying content. The compiler pipeline specification is now operationally complete for the scope of this plan; remaining phase 03 plans build the provenance tooling, lint workflow, and query workflow on top of this foundation.

## Self-Check: PASSED

- AGENTS.md: FOUND
- wiki/sources/src-2026-04-09-thinking-fast-and-slow-part1.md: FOUND
- Commit 75c19aa: FOUND
- Commit 1666839: FOUND
- All verify queries match expected output
