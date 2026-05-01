---
phase: 12-complementary-systems-boundary-gtd-alignment
plan: 01
subsystem: docs

tags:
  - decision-record
  - boundary
  - gtd-alignment
  - architecture
  - meta
  - schema

# Dependency graph
requires:
  - phase: 06-reflection-drift-detection
    provides: "type: decision page-type contract + dr-2026-04-14-phase6-decision-type inaugural-record precedent (affected_pages: [], trigger_type: schema-update)"
  - phase: 11-brownfield-suggest-verify
    provides: "dr-2026-04-20-brownfield-apply-vs-advisory most-recent-DR base-fields shape used as structural template"
provides:
  - "BOUND-01 decision record at wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md"
  - "Canonical complementary-systems boundary statement for v1.1 close (CLOSE-04 scope-leak gate dependency)"
  - "Alternatives Considered rejecting all-in-one PKM/task framing, v2-deferral, and README-only embedding"
  - "Decision-record reference target for Plan 12-02 (ref doc cites this DR by ID) and Plan 12-03 (wiki/index.md Decisions entry, wiki/log.md reflect entry)"
affects:
  - "Plan 12-02 (ref doc cites this DR by ID dr-2026-05-01-complementary-systems-boundary)"
  - "Plan 12-03 (wiki/index.md Decisions entry + wiki/log.md reflect entry name this DR)"
  - "Plan 12-04 (reviewed-match audit grep scans this file's Alternatives Considered + body — every match must be annotated negative-framing per BOUND-03)"
  - "REQUIREMENTS.md BOUND-01 status flip (Pending -> Complete)"
  - "CLOSE-04 v1.1 scope-leak gate (becomes verifiable once Phase 12 closes)"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Infrastructure-only DR with affected_pages: [] (continues dr-2026-04-14-phase6-decision-type inaugural-record precedent)"
    - "Body links to non-wiki refs use plain markdown (relative paths from wiki/decisions/), NOT wikilinks — established by Phase 6 + Phase 11 DR precedent"
    - "Sources section cites .planning/notes/ origin material as plain markdown links (sources: [] in frontmatter is empty because cited material is not wiki/sources/ pages)"

key-files:
  created:
    - "wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md (77 lines, 7 required sections, type: decision)"
  modified: []

key-decisions:
  - "DR honors locked CONTEXT D-15 (filename dr-2026-05-01-complementary-systems-boundary.md), D-16 (trigger_type: schema-update + affected_pages: []), D-17 (Sources cites three .planning/notes/2026-04-24-*.md origin notes + REQUIREMENTS.md + ROADMAP.md + new ref doc), D-18 (Alternatives Considered names and rejects (a) all-in-one PKM/task framing, (b) deferring to v2, (c) README-only embedding)"
  - "Why section adopts the heavy-write/cheap-read vs cheap-write/heavy-read framing pivot from .planning/notes/2026-04-24-openbrain-vs-compendium-critique.md as the rejection rationale for the all-in-one assumption"
  - "Body links three-layer-model.md once (in Decision section first-mention; subsequent Sources mention is a separate link line per CONTEXT, treated as the canonical deeper-link site) using relative markdown path ../../docs/reference/three-layer-model.md — ref doc does not yet exist (Plan 12-02 creates it in same Wave 1 per wave_1_coordination_note)"

patterns-established:
  - "Tier-1 inline boundary DR pattern: trigger_type: schema-update + affected_pages: [] for architectural-framing decisions that do not restructure existing wiki pages"
  - "Negative-framing language ('compendium does NOT own X', 'task manager / calendar / reminders / inbox are out of scope') is REQUIRED content in Alternatives Considered + Consequences per BOUND-03 audit semantics — those mentions are correct content, not contradictions"

requirements-completed:
  - BOUND-01

# Metrics
duration: 2min
completed: 2026-05-01
---

# Phase 12 Plan 01: Complementary Systems Boundary Decision Record Summary

**BOUND-01 decision record at wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md establishes compendium as durable, provenance-backed wiki memory inside a multi-system stack, rejecting all-in-one PKM/task framing, v2-deferral, and README-only embedding.**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-05-01T13:22:56Z
- **Completed:** 2026-05-01T13:25:00Z (approx)
- **Tasks:** 1
- **Files modified:** 1 (created)

## Accomplishments

- Created the first canonical-shipped-surface artifact stating that compendium owns durable, provenance-backed wiki memory and review support, while complementary systems own executable commitments, reminders, calendars, transactional state, and high-churn operational events.
- Honored every locked CONTEXT decision (D-15 filename, D-16 frontmatter shape, D-17 Sources contents, D-18 Alternatives Considered contents).
- Promoted exploratory substance from three `.planning/notes/2026-04-24-*.md` notes into the canonical wiki/decisions/ surface without re-deriving from scratch.
- Unblocked Plan 12-02 (ref doc cites this DR by ID), Plan 12-03 (wiki/index.md + wiki/log.md entries name this DR), and Plan 12-04 (reviewed-match audit will annotate body matches as `negative-framing`).

## Task Commits

Each task was committed atomically:

1. **Task 1: Write BOUND-01 decision record at wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md** — `3fd9ce2` (reflect)

_Note: Plan 12-01 has a single task per the PLAN; no plan-metadata commit is added in worktree mode (orchestrator owns shared-file updates after wave merge)._

## Files Created/Modified

- `wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md` (created, 77 lines) — BOUND-01 decision record. Frontmatter: `type: decision`, `trigger_type: schema-update`, `affected_pages: []`, `epistemic_status: sourced`, `privacy: cloud_safe`, `knowledge_domain: software`. Body: 7 required sections per AGENTS.md §4.6 (TL;DR, Decision, Why, Alternatives Considered, Consequences, Affected Pages, Sources), each with substantive non-placeholder content. Sources section uses plain markdown links to non-wiki refs (`.planning/notes/2026-04-24-*.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `docs/reference/three-layer-model.md`) per CONTEXT D-17.

## Decisions Made

- **Frontmatter shape mirrors the inaugural-record precedent.** Used `affected_pages: []` + `sources: []` (in frontmatter) + `epistemic_status: sourced` matching `dr-2026-04-14-phase6-decision-type.md`. Body's `## Sources` section uses plain markdown links to non-wiki refs because cited material is not source-summary pages in `wiki/sources/`.
- **Why section adopts heavy-write/cheap-read framing pivot.** The framing-replaced statement reads "compendium owns durable, provenance-backed synthesis and reflective memory; complementary systems own executable commitments, reminders, calendars, and transactional / operational state" replacing the implicit "all-in-one PKM/task system" assumption. Substance promoted from `.planning/notes/2026-04-24-openbrain-vs-compendium-critique.md`.
- **Alternatives Considered carries all three locked rejections (D-18) with full rationales.** All-in-one framing rejected as fundamental category error (heavy-write/cheap-read vs cheap-write/heavy-read shape mismatch). v2 deferral rejected because CLOSE-04 scope-leak gate cannot pass without canonical boundary statement. README-only embedding rejected because decision records are the canonical home per AGENTS.md §4.6 and Phase 6 dr-2026-04-14-phase6-decision-type precedent.
- **Negative-framing language is REQUIRED content per BOUND-03 audit semantics, not a contradiction.** The DR's Alternatives Considered and Consequences sections explicitly mention "task manager", "calendar", "reminders", "inbox", "all-in-one" — the Plan 12-04 reviewed-match audit will annotate every such match as `negative-framing` (rejection / out-of-scope context), not `positive-claim`.
- **Forward reference to docs/reference/three-layer-model.md is a relative markdown link, NOT a wikilink.** AGENTS.md §6 provenance lint only flags wikilinks resolving to wiki pages; the relative path to a `docs/reference/` doc is not lint-flagged as broken even before Plan 12-02 lands. Per `wave_1_coordination_note` in PLAN.md, this transient forward reference is acceptable in Wave 1 because both 12-01 and 12-02 ship before Plan 12-04 audit runs.

## Deviations from Plan

None — plan executed exactly as written.

The plan-level acceptance_criteria + must_haves checklist (file exists, filename convention, 7 required sections, type/trigger_type/affected_pages/id/epistemic_status/privacy frontmatter values, Why section names both ownership halves, Alternatives Considered names all-in-one + v2/defer + README, Sources cites the three 2026-04-24 notes + new ref doc, no wikilinks in frontmatter, forbidden-patterns reminder present) all passed on the first write.

`bash bin/lint.sh --category yaml,provenance` exited 0 with zero errors / zero warnings / zero info findings.

A minor cleanup step was needed before commit: running `bin/lint.sh` as part of verification appended a lint log entry to `wiki/log.md` and created `wiki/maintenance/lint-report.md`. Per Plan 12-01's locked scope (only `wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md` is in this plan's `files_modified` list), those lint side-effects were reverted (`git checkout -- wiki/log.md`, `rm -rf wiki/maintenance/`) before the task commit. The wiki/log.md reflect entry for Phase 12 is a Plan 12-03 deliverable per AGENTS.md §11.4 step 6 / §12 + the SPEC's "in-scope deliverables" list — not a Plan 12-01 deliverable. This is not a deviation; it is correct plan-scope hygiene.

## Issues Encountered

None. No bugs, no blockers, no architectural questions. The locked CONTEXT (D-15..D-18) and the SPEC's locked acceptance criteria fully constrained the implementation; the only non-trivial editorial choice (exact prose of the Why-section framing pivot) was guided by the suggested wording in PLAN.md `<action>` and refined for cadence.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- **Plan 12-02 (Wave 1 sibling)** is unblocked. The ref doc `docs/reference/three-layer-model.md` can now cite this DR by ID `dr-2026-05-01-complementary-systems-boundary`. Note: 12-02 ships in the same Wave 1 commit batch; the relative-markdown forward-link from this DR to the ref doc resolves once 12-02's commit lands. AGENTS.md §6 provenance lint does NOT flag relative-markdown forward-refs (only wikilinks to non-existent wiki pages are flagged), so no transient lint failure exists.
- **Plan 12-03 (Wave 2)** is unblocked. `wiki/index.md` Decisions section can add a bullet for this DR; `wiki/log.md` can append a single Phase 12 reflect entry naming this DR's slug. Both per AGENTS.md §11.4 step 5 / step 6 / §12.
- **Plan 12-04 (Wave 3)** is unblocked. The reviewed-match audit grep will scan this DR's body, find matches on "task manager", "calendar", "reminders", "inbox", "all-in-one" inside the Alternatives Considered + Consequences sections, and annotate every match as `negative-framing` per CONTEXT D-14 + BOUND-03. Zero matches will carry `positive-claim` verdict.
- **CLOSE-04 v1.1 scope-leak gate** is one step closer to verifiable. The canonical boundary statement now exists in `wiki/decisions/`. Once 12-02/03/04 complete, CLOSE-04 can run.

## TDD Gate Compliance

Not applicable — Plan 12-01 is a docs/decision-record plan (`type: execute`, `tdd: false` in PLAN.md frontmatter for Task 1). No RED/GREEN/REFACTOR cycle expected or required.

## Self-Check: PASSED

Verified before sealing this SUMMARY:

- File exists: `wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md` — FOUND
- Commit hash exists: `3fd9ce2` — FOUND in `git log --oneline -3`
- All 17 acceptance_criteria from PLAN.md Task 1 — verified PASS via inline shell checks (file exists, filename convention, 7 sections, frontmatter values, Why section coverage, Alternatives coverage of three locked rejections, Sources coverage, no wikilinks in frontmatter, forbidden-patterns comment present)
- `bash bin/lint.sh --category yaml,provenance` exit code 0 — PASS
- Lint side-effects (`wiki/log.md` modification, `wiki/maintenance/lint-report.md`) reverted before commit — PASS (clean `git status --short` showed only the DR file before commit)

---
*Phase: 12-complementary-systems-boundary-gtd-alignment*
*Completed: 2026-05-01*
