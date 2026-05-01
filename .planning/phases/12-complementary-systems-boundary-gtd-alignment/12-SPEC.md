# Phase 12: Complementary Systems Boundary + GTD Alignment — Specification

**Created:** 2026-05-01
**Ambiguity score:** 0.107 (gate: ≤ 0.20)
**Requirements:** 6 locked

## Goal

Make compendium's role inside a multi-system agent stack — durable, provenance-backed wiki memory and review support, NOT task execution / reminders / calendar / high-churn operational state — explicit in the canonical shipped surface (decision record + reference doc + audited README) before v1.1 closes, without expanding the schema or `wiki/` directory taxonomy.

## Background

The boundary substance already exists in three exploratory notes — `.planning/notes/2026-04-24-agentic-gtd-boundary.md` (3-layer model + good-fits / poor-fits lists), `.planning/notes/2026-04-24-openbrain-vs-compendium-critique.md` (heavy-write/cheap-read tradeoff + non-goals), and `.planning/notes/2026-04-24-wiki-compiler-idea.md` (architecture origin). REQUIREMENTS.md tracks the boundary as `BOUND-01/02/03` (all Pending). REQUIREMENTS.md `CLOSE-04` final scope-leak check depends on the boundary being shipped consistently.

The canonical shipped surface does NOT yet reflect this boundary:
- `wiki/decisions/` has 4 records (Phase-6 type, Kahneman-to-examples, progressive-disclosure-extraction, brownfield-apply-vs-advisory) — none about complementary systems.
- `docs/reference/` has 10 files (brownfield, ci, commit-examples, dataview-queries, examples, index, privacy-model, release, schema-tour, setup-prerequisites) — no 3-layer / boundary doc.
- `README.md` (50 lines) frames compendium as "local-first LLM knowledge compiler" / "compounding knowledge base"; it does not position compendium inside a multi-system stack and does not point users at a complementary-systems doc.
- No phase 12 directory existed before this SPEC.

This phase converts the exploratory notes into the canonical shipped surface.

## Requirements

1. **BOUND-01 — Decision record exists**: A type-decision page in `wiki/decisions/` states that compendium owns durable, provenance-backed wiki memory and review support, while complementary systems own executable commitments, reminders, calendars, transactional state, and high-churn operational events.
   - Current: No decision record on system boundary exists in `wiki/decisions/`.
   - Target: `wiki/decisions/dr-2026-05-DD-complementary-systems-boundary.md` exists with `type: decision`, `trigger_type: schema-update`, `affected_pages: []` (infrastructure-only, matching the `dr-2026-04-14-phase6-decision-type` inaugural-record precedent), and the 7 required sections (TL;DR, Decision, Why, Alternatives Considered, Consequences, Affected Pages, Sources) per AGENTS.md §4.6.
   - Acceptance: File exists with correct frontmatter (passes `bin/lint.sh --category yaml,provenance`); body contains all 7 required sections with non-placeholder content; "Why" explicitly contrasts compendium ownership (durable synthesis) vs complementary-system ownership (executable commitments / reminders / calendars / transactional state); "Alternatives Considered" lists at least the "all-in-one PKM/task system" alternative with rejection rationale.

2. **BOUND-02 — Reference doc exists**: A reference doc in `docs/reference/` explains the 3-layer model (task layer / working-memory layer / wiki-compiler layer) and includes a routing table for capture / clarify / organize / review.
   - Current: No `docs/reference/` file describes the 3-layer model or GTD-verb routing.
   - Target: `docs/reference/three-layer-model.md` (or equivalent under `docs/reference/`) exists with three explicit sections: (a) 3-layer model narrative naming each layer and what it owns; (b) Routing Rules — a markdown table with columns `Verb | Belongs in (layer) | Compendium role | Out of scope` and rows for capture / clarify / organize / review (all 4 GTD verbs present); (c) Anti-features list explicitly excluding inbox, next-action execution, calendar, reminders, rapid transactional updates, high-churn waiting-for state, and Slack/ticket/event-stream ingest.
   - Acceptance: File exists; `grep` confirms the 4 GTD-verb rows in the routing table; `grep` confirms each anti-feature appears in the anti-features section; `docs/reference/index.md` lists the new file; the doc cites the BOUND-01 decision record by ID.

3. **BOUND-03 — Surface consistency**: README, `docs/`, and `wiki/decisions/` consistently exclude "all-in-one PKM/task system" framing (zero positive ownership claims) AND no new wiki page types or `wiki/` directory taxonomies are introduced. Note: the new BOUND-01 DR's "Alternatives Considered" section and the new BOUND-02 doc's Anti-features section MUST mention the excluded systems (task manager, calendar, reminders, inbox, etc.) in negative/exclusionary framing — those are required content, not contradictions.
   - Current: README.md does not contradict the boundary but does not mention it; no audit confirms `docs/` and `wiki/decisions/` are clean.
   - Target: README.md gains a single contextual pointer sentence under the existing "What this is" section, making the boundary discoverable from the entry point; a **reviewed-match audit** over README.md, AGENTS.md, `docs/`, and `wiki/decisions/` enumerates every `grep` hit on the boundary patterns and confirms each match is negative/exclusionary framing (e.g., "compendium is NOT a task manager", "out of scope: calendar", or appears inside an "Alternatives Considered" section listing rejected framings) — zero matches asserting compendium IS such a system; zero new page types added to AGENTS.md §4 enum (still 6: entity, concept, source, comparison, overview, decision); zero new top-level subdirectories under `wiki/` beyond the existing set.
   - Acceptance: README.md contains exactly one new contextual pointer sentence referencing the BOUND-02 doc; the reviewed-match audit (inline shell snippet captured in `12-VERIFICATION.md`) lists every match and the verdict for each (`negative-framing` or `positive-claim`); zero matches with `positive-claim` verdict; AGENTS.md §4 page-type enum unchanged; `find wiki -maxdepth 1 -type d` returns the same set as before this phase plus the unchanged existing `decisions/` and `maintenance/`.

4. **REQUIREMENTS.md status sync**: BOUND-01, BOUND-02, BOUND-03 flip from `Pending` to `Complete` in REQUIREMENTS.md and the Phase 12 traceability rows reflect the verification artifact.
   - Current: BOUND-01/02/03 marked Pending; traceability table lists `BOUND-01..03 | Phase 12 | Pending`.
   - Target: All three checkboxes flipped to `[x]` in the BOUND section; traceability rows updated to `Complete`; `bin/requirements-sync.sh --strict --phase 12` reports zero drift after VERIFICATION.md is written.
   - Acceptance: `grep "^- \[x\] \*\*BOUND-0[123]\*\*" .planning/REQUIREMENTS.md` returns 3 lines; `bin/requirements-sync.sh --strict --phase 12` exits 0.

5. **VERIFICATION.md artifact**: Phase 12 closes with a verification artifact that records BOUND-01/02/03 as Complete and provides evidence (file paths + grep proofs).
   - Current: No Phase 12 verification artifact exists.
   - Target: `.planning/phases/12-complementary-systems-boundary-gtd-alignment/12-VERIFICATION.md` exists with REQ-ID rows for BOUND-01, BOUND-02, BOUND-03 marked Complete plus evidence path/line references for each.
   - Acceptance: File parses under `bin/requirements-sync.sh` REQ-ID parser (bare bullets / `[x]` checkboxes / **bold** REQ-IDs all tolerated per Phase 07 contract); each row has explicit file-path evidence.

6. **No scope expansion of schema/tooling**: This phase ships docs and a decision record only — no changes to `bin/`, no new schema fields, no new lint rules, no new page-type enums.
   - Current: The bin/, schema/, and AGENTS.md page-type enum are stable post-Phase 11.
   - Target: Phase 12's diff touches only `wiki/decisions/dr-2026-05-DD-*.md`, `docs/reference/three-layer-model.md`, `docs/reference/index.md`, `README.md` (one contextual pointer sentence), `wiki/index.md` (Decisions section adds the new DR per AGENTS.md §11.4 step 5), `wiki/log.md` (single reflect entry per AGENTS.md §11.4 step 6 / §12), `.planning/REQUIREMENTS.md` (status flips), `.planning/phases/12-*/` (planning artifacts).
   - Acceptance: A captured phase-base SHA recorded in `12-VERIFICATION.md` (taken at SPEC commit time) anchors the diff; `git diff --name-only <phase_base>...HEAD` (or equivalent walk over phase-12 commits if no remote `origin/main` exists) shows zero files under `bin/`, `schema/`, or content edits to `AGENTS.md` / `CLAUDE.md`; the AGENTS.md ↔ CLAUDE.md byte-equality hook continues to pass.

## Boundaries

**In scope:**
- One new decision record in `wiki/decisions/` capturing the complementary-systems boundary (BOUND-01).
- One new reference doc in `docs/reference/` with 3-layer model + routing table + anti-features section (BOUND-02).
- One contextual pointer sentence added to `README.md` under "What this is" pointing at the new reference doc.
- One bullet added to `docs/reference/index.md` listing the new reference doc.
- One Decisions-section entry added to `wiki/index.md` for the new DR (per AGENTS.md §11.4 step 5).
- One reflect entry appended to `wiki/log.md` for Phase 12 (per AGENTS.md §11.4 step 6 and §12).
- Reviewed-match audit (inline shell snippet in `12-VERIFICATION.md`) confirming every grep hit on boundary patterns is negative/exclusionary framing — zero positive ownership claims (BOUND-03).
- REQUIREMENTS.md status flips for BOUND-01/02/03.
- VERIFICATION.md artifact for Phase 12.

**Out of scope:**
- Any task manager / reminder / calendar feature implementation — explicitly excluded by the boundary itself; would defeat the phase's purpose.
- Any `bin/` script changes — Phase 12 is pure docs + decision record. Tooling changes belong to other v1.1 phases (12.1 NEUT-08 curation, 12.2 local write gate, 13 claim audit).
- Any new wiki page type or new `wiki/` top-level directory — explicitly forbidden by BOUND-03 (creating one would itself contradict the boundary).
- GTD-specific Dataview dashboards or review templates — deferred to backlog Phase 999.6 per ROADMAP.md until observed practice justifies them.
- Slack/ticket/event-stream ingest design — explicitly out of scope per ROADMAP.md non-goals; goes against the boundary.
- Multi-system integration tooling (e.g., bridging compendium to a task backend) — declared "complementary system" responsibility, not compendium's.
- Re-framing exploratory notes under `.planning/notes/` — those notes are inputs to this phase; they remain as-is and are NOT promoted into `wiki/`.
- Updating decision records older than this phase to back-link to the new BOUND-01 record — `decision_history` back-links are optional per AGENTS.md §4.6 and not required for this phase.

## Constraints

- **No new page types**: AGENTS.md §4 page-type enum stays at 6 (entity, concept, source, comparison, overview, decision). Adding a new type to express the boundary would itself contradict BOUND-03.
- **No new `wiki/` taxonomies**: `find wiki -maxdepth 1 -type d` must return the same set after Phase 12 as before. No `wiki/gtd/`, `wiki/tasks/`, `wiki/projects/` directories.
- **Decision record schema compliance**: The new DR conforms to AGENTS.md §4.6 — uses `type: decision`, has all 7 required sections, has `trigger_type` from the fixed 6-value enum (`schema-update` is the chosen value), and `affected_pages: []` per the inaugural-record precedent.
- **Reference doc schema neutrality**: The new doc lives in `docs/reference/` (operator-facing, not `wiki/`-facing) so it does not need wiki frontmatter. It is a standard markdown reference doc like `docs/reference/privacy-model.md` and `docs/reference/schema-tour.md`.
- **Cross-link contracts**: README's pointer line uses the existing markdown-link convention (no wikilinks in README — README is rendered by GitHub, not Obsidian). The reference doc cites the BOUND-01 decision record by its file path or ID, not via a wikilink.
- **AGENTS.md ↔ CLAUDE.md byte-equality**: The pre-commit hook (`.githooks/pre-commit`) continues to enforce byte-equality. Since Phase 12 does not edit AGENTS.md content (no §4 enum or §11 workflow changes), this constraint is automatically satisfied.
- **No additional dependencies**: Pure markdown additions; no new Python packages, no new CLI helpers.

## Acceptance Criteria

- [ ] `wiki/decisions/dr-2026-05-DD-complementary-systems-boundary.md` exists with `type: decision`, `trigger_type: schema-update`, `affected_pages: []`, and all 7 sections (TL;DR, Decision, Why, Alternatives Considered, Consequences, Affected Pages, Sources) populated with non-placeholder content.
- [ ] `bin/lint.sh --category yaml,provenance` exits 0 against the new decision record.
- [ ] `docs/reference/three-layer-model.md` exists and contains: (a) a 3-layer model section naming task / working-memory / wiki-compiler layers, (b) a markdown routing table with columns `Verb | Belongs in | Compendium role | Out of scope` and rows for `capture`, `clarify`, `organize`, `review` (all 4 present), and (c) an `## Anti-features` section containing each of the following as an explicit bullet: inbox UI / quick-capture interface, next-action execution, calendar, reminders, rapid transactional updates, high-churn waiting-for state, and Slack/ticket/event-stream ingest.
- [ ] `docs/reference/index.md` lists the new reference doc.
- [ ] `README.md` contains exactly one new contextual pointer sentence referencing the BOUND-02 doc, placed under the existing "What this is" section.
- [ ] `wiki/index.md` Decisions section lists the new DR with a one-line summary entry per AGENTS.md §12 index format.
- [ ] `wiki/log.md` ends with a single new reflect entry for Phase 12 per AGENTS.md §11.4 step 6 / §12 log format.
- [ ] **Reviewed-match audit (BOUND-03):** running the inline shell command captured in `12-VERIFICATION.md` against README.md + AGENTS.md + `docs/` + `wiki/decisions/` enumerates all matches; every match is annotated with verdict `negative-framing` (boundary, anti-feature, or alternative-considered context) or `positive-claim`. Phase passes iff zero matches carry the `positive-claim` verdict.
- [ ] `find wiki -maxdepth 1 -type d` returns the same set after Phase 12 as before (no new top-level wiki directories).
- [ ] AGENTS.md §4 page-type enum still lists exactly 6 types (entity, concept, source, comparison, overview, decision).
- [ ] BOUND-01, BOUND-02, BOUND-03 marked `[x]` in `.planning/REQUIREMENTS.md`; traceability rows updated to `Complete`.
- [ ] `bin/requirements-sync.sh --strict --phase 12` exits 0.
- [ ] `.planning/phases/12-complementary-systems-boundary-gtd-alignment/12-VERIFICATION.md` exists with REQ-ID rows for BOUND-01/02/03 each carrying explicit file-path evidence, plus the captured phase-base SHA used for the diff acceptance check.
- [ ] AGENTS.md ↔ CLAUDE.md byte-equality pre-commit hook passes (no AGENTS.md content edits expected).
- [ ] Diff over phase-12 commits (anchored on the captured phase-base SHA in `12-VERIFICATION.md`) contains zero files under `bin/` or `schema/`, and zero content changes to `AGENTS.md` / `CLAUDE.md`.

## Ambiguity Report

| Dimension          | Score | Min  | Status | Notes                                                                              |
|--------------------|-------|------|--------|------------------------------------------------------------------------------------|
| Goal Clarity       | 0.92  | 0.75 | ✓      | DR + ref doc + README pointer locked; deliverables are explicit files            |
| Boundary Clarity   | 0.90  | 0.70 | ✓      | Roadmap non-goals + audit-only README + empty affected_pages all explicit        |
| Constraint Clarity | 0.85  | 0.65 | ✓      | "No new types/dirs" mechanical; no `bin/` changes mechanical                     |
| Acceptance Criteria| 0.88  | 0.70 | ✓      | Routing table + pointer line + grep audits all mechanically checkable            |
| **Ambiguity**      | 0.107 | ≤0.20| ✓      | Gate met after Round 1                                                            |

Status: ✓ = met minimum, ⚠ = below minimum (planner treats as assumption)

## Interview Log

| Round | Perspective              | Question summary                                          | Decision locked                                                                                                  |
|-------|--------------------------|-----------------------------------------------------------|------------------------------------------------------------------------------------------------------------------|
| 0     | Researcher (pre-question)| What exists in canonical surface today?                   | 3 exploratory notes in `.planning/notes/` carry the substance; canonical surface (DR / docs/ / README) is empty |
| 1     | Boundary Keeper          | Decision record `affected_pages` scope?                   | Infrastructure-only (`affected_pages: []`) — matches `dr-2026-04-14-phase6-decision-type` inaugural precedent   |
| 1     | Simplifier               | Reference doc shape?                                      | 3-layer model section + routing table + explicit anti-features list                                              |
| 1     | Boundary Keeper          | README posture — edit or audit-only?                      | Audit + single pointer line under existing "What this is" section (max discoverability, min surface change)     |
| 1     | Failure Analyst          | How to make routing rules pass/fail?                      | Markdown table with columns `Verb \| Belongs in \| Compendium role \| Out of scope`; all 4 GTD verbs required   |

## Review-Driven Amendments

After CONTEXT.md was captured, three external AI reviewers flagged consistent issues. SPEC was amended (2026-05-01, post-CONTEXT) to address them. See `12-CONTEXT.md` § "Review-Driven Amendments" for the full list. SPEC-level changes:

- **Requirement 3 (BOUND-03):** Replaced "zero matches" audit with **reviewed-match audit** — every grep hit gets verdict `negative-framing` or `positive-claim`; PASS iff zero `positive-claim` hits. Required content (DR's "Alternatives Considered" + ref doc's "Anti-features") explicitly excluded from being treated as contradictions.
- **Requirement 6 (diff scope):** Diff anchor changed from `origin/main...HEAD` to a captured phase-base SHA recorded in `12-VERIFICATION.md` (repo branching_strategy is `none`). Allowed-files list explicitly extended to include `wiki/index.md` (Decisions section entry) and `wiki/log.md` (single reflect entry) per AGENTS.md §11.4 step 5/6 / §12.
- **In-scope list:** Added `wiki/index.md` Decisions entry + `wiki/log.md` reflect entry as required deliverables.
- **README pointer:** Explicit "contextual pointer sentence" wording (was "See: line"). Acceptance criterion updated.
- **Anti-features acceptance:** AC for BOUND-02 strengthened to require each excluded item as an explicit bullet inside a `## Anti-features` section (not just a global grep hit anywhere).
- **bin/check-neutrality.sh:** Removed from BOUND-03 acceptance evidence (it scans for creator-specific terms, not framing patterns).
- **Ambiguity:** Re-scored after amendments — Goal Clarity 0.94, Boundary Clarity 0.93, Constraint Clarity 0.88, Acceptance Criteria 0.92. Ambiguity = 1.0 − (0.35×0.94 + 0.25×0.93 + 0.20×0.88 + 0.20×0.92) = **0.082**. Gate stays met.

---

*Phase: 12-complementary-systems-boundary-gtd-alignment*
*Spec created: 2026-05-01*
*Spec amended: 2026-05-01 (review-driven)*
*Next step: /gsd-plan-phase 12 — research + plan against the amended SPEC + CONTEXT.*
