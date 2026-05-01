# Phase 12: Complementary Systems Boundary + GTD Alignment - Context

**Gathered:** 2026-05-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Pure docs delivery to make compendium's role inside a multi-system agent stack explicit in the canonical shipped surface (decision record + reference doc + audited README) before v1.1 closes. Zero `bin/`, zero schema, zero new wiki page types, zero new `wiki/` taxonomies. Verifies BOUND-01/02/03 and `CLOSE-04`'s scope-leak precondition.

</domain>

<spec_lock>
## Requirements (locked via SPEC.md)

**6 requirements are locked.** See `12-SPEC.md` for full requirements, boundaries, and acceptance criteria.

Downstream agents MUST read `12-SPEC.md` before planning or implementing. Requirements are not duplicated here.

**In scope (from SPEC.md):**
- One new decision record in `wiki/decisions/` capturing the complementary-systems boundary (BOUND-01).
- One new reference doc in `docs/reference/` with 3-layer model + routing table + anti-features section (BOUND-02).
- One contextual pointer sentence added to `README.md` under "What this is" pointing at the new reference doc.
- One bullet added to `docs/reference/index.md` listing the new reference doc.
- One Decisions-section entry added to `wiki/index.md` for the new DR (per AGENTS.md §11.4 step 5 / §12).
- One reflect entry appended to `wiki/log.md` for Phase 12 (per AGENTS.md §11.4 step 6 / §12).
- Reviewed-match audit (inline snippet in `12-VERIFICATION.md`) confirming every grep hit on boundary patterns is negative/exclusionary framing — zero positive ownership claims (BOUND-03).
- REQUIREMENTS.md status flips for BOUND-01/02/03.
- VERIFICATION.md artifact for Phase 12 (records the captured phase-base SHA used for diff acceptance).

**Out of scope (from SPEC.md):**
- Any task manager / reminder / calendar feature implementation.
- Any `bin/` script changes (Phase 12 is pure docs + decision record).
- Any new wiki page type or new `wiki/` top-level directory.
- GTD-specific Dataview dashboards or review templates (deferred to backlog Phase 999.6).
- Slack/ticket/event-stream ingest design.
- Multi-system integration tooling (e.g., bridging compendium to a task backend).
- Re-framing the exploratory `.planning/notes/2026-04-24-*.md` notes (they remain inputs).
- Updating older decision records to back-link to BOUND-01 via `decision_history`.

</spec_lock>

<decisions>
## Implementation Decisions

### Reference doc filename + structure
- **D-01:** Filename is `docs/reference/three-layer-model.md`. Names the doc by its primary mental model; matches sibling `privacy-model.md` style.
- **D-02:** Section order is `Model → Routing → Anti-features`. Conceptual frame first, then operator-facing rules, then explicit exclusions. Mirrors `.planning/notes/2026-04-24-agentic-gtd-boundary.md` flow.
- **D-03:** Doc opens with a 1-paragraph TL;DR-style framing before Section 1, mirroring how `docs/reference/privacy-model.md` and `docs/reference/brownfield.md` open. Suggested wording: "Compendium is the wiki-compiler layer of a multi-system stack. It owns durable, provenance-backed memory; complementary systems own task execution, calendar, and operational state. This doc explains the boundary and routes four GTD-style verbs (capture / clarify / organize / review) across the three layers." Note: classic GTD is five steps (capture, clarify, organize, reflect, engage); this phase uses the four roadmap-scoped verbs intentionally — the doc should acknowledge the truncation if the planner judges it useful.

### Routing table cell content
- **D-04:** Routing table has 4 columns: `Verb | Belongs in | Compendium role | Out of scope`. Rows: `capture`, `clarify`, `organize`, `review` (all four GTD verbs required, in this order).
- **D-05:** `Belongs in` column maps verbs to layers as follows:
  - `capture` → working-memory layer
  - `clarify` → working-memory layer
  - `organize` → task layer
  - `review` → all three layers (task + working-memory + wiki-compiler)
  Most accurate of the available framings — captures that ephemeral capture/clarify is short-lived (working-memory), organization is the task-system's job, and review is the only verb where compendium contributes substantively across all layers.
- **D-06:** `Compendium role` column uses **concrete actions per verb**, not abstract role labels. Compendium has a legitimate (narrow) durable-knowledge contribution at every verb — the cells must NOT erase it. Suggested cell content (planner may refine wording):
  - `capture` → "optionally ingest a captured note as a `wiki/sources/` entry once the note crosses the durable-synthesis threshold"
  - `clarify` → "no role at clarify time itself; durable rationale or decisions about clarified items can be ingested afterward as `wiki/decisions/`, `wiki/concepts/`, or other appropriate page types"
  - `organize` → "no role for executable task organization (projects / contexts / areas live in the task system); compendium organizes durable knowledge as `entity / concept / source / comparison / overview / decision` pages per AGENTS.md §4"
  - `review` → "surface stale claims, contradictions, neglected projects, and durable insights via lint + query write-back; complement (not replace) the task system's review surfaces"
- **D-07:** `Out of scope` column uses **per-verb specific entries**, not a shared 'see anti-features section' pointer. Suggested cell content:
  - `capture` → "inbox UI, quick-capture hotkeys, Slack / email / event-stream ingest"
  - `clarify` → "next-action prompts, waiting-for tracking, energy / context tagging"
  - `organize` → "projects / contexts / areas database, scheduled / recurring tasks, calendar"
  - `review` → "GTD review dashboards, canonical Dataview review surfaces, reminder / nudge engines"
- **D-08:** Routing table includes a 1-line caption above it explaining the 4-column reading order. Suggested wording: "Read each row as: when doing `<Verb>`, work primarily happens in `<Belongs in>`; `<Compendium role>` describes what (if anything) compendium contributes; `<Out of scope>` lists what compendium explicitly does not own."

### README pointer placement + wording
- **D-09:** README pointer line lands at the **end of the "What this is" section**, after the existing "Unlike search-over-notes or chat-on-top-of-PDFs..." paragraph. The reader gets the framing first; the boundary pointer arrives as the next-step-for-curious-readers (mirrors how `docs/quickstart.md` is referenced from "First step" — a separate concern in its own line).
- **D-10:** Wording is a **contextual sentence with embedded link**, not a bare "See:" line. Suggested wording: "Compendium is the durable wiki-memory layer of a multi-system stack — it complements a task / GTD backend rather than substituting for one. See [docs/reference/three-layer-model.md](docs/reference/three-layer-model.md) for the boundary and routing rules." (Phrased positively — avoids the bounded `replaces`/`replacement for` audit pattern in D-12 to prevent self-referential audit hits in README.)
- **D-11:** `docs/reference/index.md` gains a single-bullet entry matching existing index style. Suggested wording: "- [three-layer-model.md](three-layer-model.md) — The 3-layer model and complementary-systems boundary."

### Audit grep patterns + scope
- **D-12:** Audit greps for **Core 6 + bounded 'replaces' patterns** (note: `inbox` added to bounded group per cross-AI review):
  1. `all-in-one`
  2. `task manager`
  3. `task backend`
  4. `reminder system`
  5. `calendar app`
  6. `inbox interface`
  7. Bounded regex: `(replaces|replacement for) (a |an |your )?(task|gtd|todo|reminder|calendar|inbox)` — catches "replaces a task manager" / "replacement for your inbox" without bare-`replaces` false positives.
- **D-13:** Audit scope is `README.md + AGENTS.md + docs/ + wiki/decisions/` exactly — matches BOUND-03 wording ("README, docs, and decision records") plus AGENTS.md (canonical agent spec). Excludes `.planning/`, `examples/`, and other `wiki/` subtrees (those are work-in-progress / illustrative / per-user content).
- **D-14:** Audit is a **reviewed-match audit**, not a zero-match grep. The audit is REQUIRED to find matches inside the new BOUND-01 DR's "Alternatives Considered" section (mentions "all-in-one PKM/task system") and inside the new BOUND-02 doc's `## Anti-features` section (mentions task manager, calendar, reminders, inbox, etc.) — those matches are correct content, not violations. The audit lives as an **inline shell snippet captured in `12-VERIFICATION.md`** (not a versioned `bin/check-boundary.sh` script — SPEC requirement #6 forbids `bin/` changes). Procedure:
  1. Run `grep -rEni '<Core6 pipe-joined>|<bounded replaces regex>' README.md AGENTS.md docs/ wiki/decisions/` and capture every hit (path:line:text).
  2. Annotate each match with verdict `negative-framing` (appears inside an Anti-features / Alternatives-Considered / boundary-clarification context) or `positive-claim` (asserts compendium IS such a system).
  3. PASS iff zero matches carry the `positive-claim` verdict. The full annotated match list is captured in `12-VERIFICATION.md` as evidence.
  4. Reproducible by anyone re-running the same command against the tree at any future point.
  Note: `bin/check-neutrality.sh` is NOT used as boundary-framing evidence (it scans for creator-specific terms, not framing patterns; conflating the two muddies its scope). `check-neutrality.sh` may run as an independent public-surface sanity check at phase close, but its output is not load-bearing for BOUND-03.

### Decision record (BOUND-01) — implementation hints inherited from SPEC + prior phase
- **D-15:** DR filename: `wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md` (today's date; existing inaugural-record `dr-2026-04-14-phase6-decision-type.md` precedent).
- **D-16:** DR `trigger_type: schema-update`; `affected_pages: []` (locked by SPEC).
- **D-17:** DR Sources section cites the three exploratory notes as origin material:
  - `.planning/notes/2026-04-24-agentic-gtd-boundary.md`
  - `.planning/notes/2026-04-24-openbrain-vs-compendium-critique.md`
  - `.planning/notes/2026-04-24-wiki-compiler-idea.md`
  Plus `.planning/REQUIREMENTS.md` BOUND-01/02/03 + `.planning/ROADMAP.md` Phase 12 entry. Body links new ref doc by relative path.
- **D-18:** DR "Alternatives Considered" lists at least: (1) all-in-one PKM / task system framing — rejected as a fundamental category error per the boundary discussion; (2) deferring boundary statement to v2 — rejected because `CLOSE-04` scope-leak gate cannot pass without it; (3) embedding boundary inline in README only — rejected because decision records are the canonical home for architectural decisions per AGENTS.md §4.6 / Phase 6 precedent.

### Claude's Discretion
- Exact prose of every `Compendium role` and `Out of scope` cell, the routing-table caption, the README sentence, the index entry bullet, and the DR's Why / Consequences sections is open to gsd-doc-writer / planner refinement. The above wordings are *suggestions* that lock semantic content; the planner may polish for cadence + clarity as long as semantic content is preserved.
- Anti-features section list ordering and grouping — discretionary as long as all SPEC-required items appear: inbox, next-action execution, calendar, reminders, rapid transactional updates, high-churn waiting-for state, Slack/ticket/event-stream ingest.
- Whether to add a small "Why this exists" paragraph in the new ref doc — discretionary; the TL;DR opening (D-03) may absorb that role.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 12 contract
- `.planning/phases/12-complementary-systems-boundary-gtd-alignment/12-SPEC.md` — Locked requirements, boundaries, and acceptance criteria. MUST read before planning.
- `.planning/REQUIREMENTS.md` BOUND-01..03, CLOSE-04 — Requirement IDs that this phase closes; CLOSE-04 is the downstream gate that depends on Phase 12 shipping.
- `.planning/ROADMAP.md` Phase 12 entry — Goal, dependencies, success criteria, non-goals.

### Source material (origin of the boundary)
- `.planning/notes/2026-04-24-agentic-gtd-boundary.md` — 3-layer model + good-fits / poor-fits lists. Primary source for the routing table.
- `.planning/notes/2026-04-24-openbrain-vs-compendium-critique.md` — Heavy-write/cheap-read tradeoff + non-goals + roadmap consequences. Primary source for the anti-features list.
- `.planning/notes/2026-04-24-wiki-compiler-idea.md` — Architecture origin and 3-layer framing context.

### Schema + decision-record contracts
- `AGENTS.md` §4.6 (Decision page type) — Required frontmatter + 7-section structure for the new BOUND-01 record. Schema MUST be followed.
- `AGENTS.md` §3 "What Agents Must NOT Do" — No wikilinks in frontmatter; first-mention-only links; etc. Applies to the new DR.
- `wiki/decisions/dr-2026-04-14-phase6-decision-type.md` — Inaugural-record precedent for `affected_pages: []` infrastructure-only DRs. The new BOUND-01 DR follows this shape.
- `wiki/decisions/dr-2026-04-20-brownfield-apply-vs-advisory.md` — Most recent DR showing full base-fields frontmatter + sections. Use as structural template.

### Existing reference docs (style siblings for the new doc)
- `docs/reference/privacy-model.md` — Sibling reference doc; same opening-paragraph + section style.
- `docs/reference/brownfield.md` — Larger sibling reference doc; same opening-paragraph + linked-table style.
- `docs/reference/schema-tour.md` — Operator-facing reference style.
- `docs/reference/index.md` — Where the new ref doc gets its index bullet.

### Audit + verification infrastructure
- `bin/lint.sh` — Used for `--category yaml,provenance` check on the new DR (acceptance criterion 2).
- `bin/check-neutrality.sh` — Existing public-paths leak guard. NOT extended by this phase; the boundary audit is a separate inline grep snippet captured in VERIFICATION.md.
- `bin/requirements-sync.sh` — Drift-check tool. `--strict --phase 12` must exit 0 after VERIFICATION.md is written (acceptance criterion 10).

### README + entry-point surface
- `README.md` — Single line addition at end of "What this is" section.
- `.planning/PROJECT.md` — Read-only context. No edits required by Phase 12 (boundary is captured in DR + ref doc; PROJECT.md core-value statement is already compatible).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`bin/lint.sh --category yaml,provenance`** — already validates frontmatter + provenance; will pass against the new DR without modification (DR has zero `[prov:]` markers; type: decision pages don't require provenance per AGENTS.md §4.6).
- **`bin/requirements-sync.sh --strict --phase 12`** — existing tool already handles the phase-keyed VERIFICATION.md ↔ REQUIREMENTS.md drift check; just needs Phase 12 VERIFICATION.md written in the existing REQ-ID format (Phase 7 set the parser contract: bare bullets / `[x]` checkboxes / **bold** REQ-IDs all tolerated).
- **`docs/reference/privacy-model.md`** + **`docs/reference/brownfield.md`** — direct style siblings; new `three-layer-model.md` should match their opening-paragraph + linked-table cadence.
- **Existing 4 decision records under `wiki/decisions/`** — frontmatter shape + 7-section schema already established; the new BOUND-01 DR copies this structure.
- **`.planning/notes/2026-04-24-*.md`** — three exploratory notes that already contain the substance of the boundary; the planner translates that substance into the canonical surface (DR + ref doc) without re-deriving from scratch.

### Established Patterns
- **Decision-record schema** (Phase 6, AGENTS.md §4.6): `type: decision`, full BASE_FIELDS, `trigger_type` from 6-value enum, all 7 sections present. `affected_pages: []` is valid for infrastructure-only records (inaugural-record precedent).
- **Reference-doc style** (Phases 7, 9, 11): markdown only, no wiki frontmatter, opens with a TL;DR-style framing paragraph, uses `## H2` section headers, links to sibling docs by relative path.
- **VERIFICATION.md format** (Phase 7 contract): REQ-ID parser tolerates bare bullets / `[x]` checkboxes / **bold** REQ-IDs. Each row carries explicit file-path evidence.
- **AGENTS.md ↔ CLAUDE.md byte-equality** (Phase 7, .githooks/pre-commit): pre-commit hook auto-syncs and re-stages on drift. Phase 12 does NOT edit AGENTS.md content (no §4 enum or §11 workflow changes), so this hook is automatically satisfied.

### Integration Points
- New DR file under `wiki/decisions/` — picked up by `wiki/index.md` Decisions listing (operator updates index per AGENTS.md §12 — required deliverable, in scope per the SPEC update).
- New ref doc under `docs/reference/` — picked up by `docs/reference/index.md` bullet entry.
- New README line under "What this is" — single-line surgical edit; no structural section changes.
- `.planning/REQUIREMENTS.md` BOUND-01/02/03 checkboxes — flipped `[ ]` → `[x]`; traceability rows updated `Pending` → `Complete`.
- `wiki/log.md` — append a single `## [2026-05-DD] reflect | Phase 12 complementary-systems boundary` entry per AGENTS.md §11.4 step 6 / §12 (required deliverable, in scope per the SPEC update). Format: newest-at-bottom append-only.

</code_context>

<specifics>
## Specific Ideas

- The user explicitly preferred the **most accurate** Belongs-in mapping (option 3 in Q5: working-memory for capture/clarify, task layer for organize, all-layers for review) over the simpler / sharper alternatives. This signals: precision > sharpness in this doc.
- The user explicitly preferred **'replaces' / 'replacement for' patterns** in the audit grep (Q11), accepting the false-positive risk in exchange for catching dynamic framing drift like "replaces your task manager". The bounded regex (D-12) is the answer to that tradeoff.
- The user accepted **Core 6 + bounded replaces** rather than the broader "non-goal terms from ROADMAP.md" option, signaling preference for a tight, low-noise audit set.
- The user picked the **end-of-section README placement** rather than top-of-section (which would inject the boundary upfront), signaling: don't disrupt the reader's first-impression flow with a defensive framing.
- The user picked **contextual sentence with embedded link** rather than bare "See:" line, signaling: give the reader the why before the click.

</specifics>

<deferred>
## Deferred Ideas

- **bin/check-boundary.sh as a CI-enforced ongoing audit** — discussed and rejected for Phase 12 (SPEC requirement #6 forbids `bin/` changes; one-time inline audit is sufficient for v1.1 close). If future drift becomes a recurring issue, promote this to a v1.2 phase.
- **PROJECT.md core-value paragraph update** — discussed implicitly (Q9 alternate option C); user did not pick a path requiring PROJECT.md edits. Current PROJECT.md core-value is already compatible with the boundary; touching it is unnecessary surface change.
- **"How this fits in your stack" as a new README section** — discussed (Q9 option C); rejected as borderline scope creep against SPEC's "one new pointer line" wording. If future user feedback shows the boundary needs more README real estate, promote to a follow-up phase.
- **Adding a 5th GTD verb (engage) to the routing table** — discussed implicitly (Q7 follow-up); not pursued. The 4 verbs match Allen's classic capture/clarify/organize/review framing; engage is operationally a task-system concern with no compendium contribution.
- **Updating the 4 existing decision records to add `decision_history` back-links to BOUND-01** — explicitly out of scope per SPEC. `decision_history` is optional per AGENTS.md §4.6; add only if a future structural decision actually references those older records.
- **Promoting the three `.planning/notes/2026-04-24-*.md` files into `wiki/`** — out of scope by design. Those notes are origin / inputs; the canonical surface (DR + ref doc) is the output. Keeping the notes in `.planning/notes/` preserves the audit trail.

</deferred>

---

## Review-Driven Amendments

After initial SPEC + CONTEXT capture, three external AI reviewers flagged consistent issues. All addressed before planning starts:

- **High — audit semantics:** Original audit was "zero matches" but the new DR's "Alternatives Considered" and the new ref doc's `## Anti-features` section MUST mention task manager / calendar / inbox / reminder etc. in negative framing. Fixed: D-14 redefined as a **reviewed-match audit** — every grep hit gets verdict `negative-framing` or `positive-claim`; PASS iff zero `positive-claim` hits. SPEC requirement 3 + acceptance criteria updated. README pointer wording (D-10) rephrased positively to avoid self-matching the bounded `replaces` regex.
- **Medium — D-06 too sharp:** Cells erased compendium's legitimate durable-knowledge contribution at clarify/organize. Fixed: D-06 cells now record the (narrow but real) post-clarify decision/rationale ingestion path and the durable-knowledge organization role via AGENTS.md §4 page types.
- **Medium — wiki/index.md + wiki/log.md tension:** SPEC's diff-allowlist (req #6) excluded both files but AGENTS.md §11.4 / §12 require them when a new DR lands. Fixed: SPEC scope amended to include `wiki/index.md` (Decisions section entry) and `wiki/log.md` (single reflect entry); CONTEXT integration-points section updated to mark them as required deliverables.
- **Medium — bin/check-neutrality.sh as BOUND-03 evidence:** Removed. Per D-14 note: `check-neutrality.sh` scans for creator-specific terms, not framing patterns; it may run as an independent public-surface sanity check at phase close, but it is NOT load-bearing for BOUND-03.
- **Medium — regex inbox missing:** Fixed: bounded `replaces` regex in D-12 now `(replaces|replacement for) (a |an |your )?(task|gtd|todo|reminder|calendar|inbox)` — catches "replacement for your inbox".
- **Medium — origin/main…HEAD diff acceptance:** Repo `branching_strategy: none` (config.json). Fixed: SPEC requirement #6 acceptance now anchors on a captured **phase-base SHA recorded in 12-VERIFICATION.md**; planner captures that SHA at SPEC commit time.
- **Low — README "not replace one":** Original wording would itself trip an over-loose audit. Fixed: D-10 wording rephrased positively to "complements ... rather than substituting for one"; the bounded D-12 regex (now matching only `replaces` / `replacement for`) does not match this phrasing.
- **Low — SPEC said "See:" line, CONTEXT chose "contextual sentence":** Fixed: SPEC requirement 3 + acceptance criterion now say "one contextual pointer sentence".
- **Low — anti-features grep too loose:** Fixed: SPEC AC for BOUND-02 now requires each excluded item to appear as an explicit **bullet inside a `## Anti-features` section** (not just a global grep hit anywhere).
- **Low — "Allen's 4 classic verbs" misattribution:** Fixed: DISCUSSION-LOG and D-03 now note classic GTD is five steps (capture/clarify/organize/reflect/engage); this phase uses the four roadmap-scoped verbs intentionally.

---

*Phase: 12-complementary-systems-boundary-gtd-alignment*
*Context gathered: 2026-05-01*
*Review-driven amendments applied: 2026-05-01*
