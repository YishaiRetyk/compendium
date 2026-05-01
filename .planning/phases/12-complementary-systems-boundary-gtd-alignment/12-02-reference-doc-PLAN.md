---
id: 12-02-reference-doc
plan_id: 12-02
phase: 12
plan: 02
wave: 1
type: execute
depends_on: []
files_modified:
  - docs/reference/three-layer-model.md
requirements:
  - BOUND-02
autonomous: true
must_haves:
  truths:
    - "A reference doc exists at docs/reference/three-layer-model.md."
    - "The doc explains the 3-layer model: task layer, working-memory layer, wiki-compiler layer — each named with what it owns."
    - "The doc contains a routing table with 4 columns (Verb | Belongs in | Compendium role | Out of scope) and 4 rows for capture / clarify / organize / review (in that order)."
    - "The doc contains an `## Anti-features` section with explicit bullets for inbox UI / quick-capture interface, next-action execution, calendar, reminders, rapid transactional updates, high-churn waiting-for state, Slack/ticket/event-stream ingest."
    - "The doc cites the BOUND-01 decision record by ID (dr-2026-05-01-complementary-systems-boundary)."
  artifacts:
    - path: docs/reference/three-layer-model.md
      provides: "BOUND-02 reference doc — 3-layer model + routing rules + anti-features"
      contains: "## Anti-features"
  key_links:
    - from: docs/reference/three-layer-model.md
      to: wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md
      via: "citation of BOUND-01 DR by ID or relative path"
      pattern: "dr-2026-05-01-complementary-systems-boundary"
---

<objective>
Create the BOUND-02 operator-facing reference doc `docs/reference/three-layer-model.md` explaining the 3-layer model (task / working-memory / wiki-compiler), the 4-verb routing table (capture / clarify / organize / review), and the anti-features list (what compendium explicitly does not own).

Purpose: Operationalize the BOUND-01 decision record for operators choosing where work belongs in the multi-system stack. Satisfies BOUND-02 acceptance and is cited from README (Plan 12-03) and the BOUND-01 DR (Plan 12-01).
Output: One new reference doc in standard markdown (no wiki frontmatter — operator-facing per Phase 12 SPEC constraint), styled to match `docs/reference/privacy-model.md` and `docs/reference/brownfield.md`.
</objective>

<context>
@.planning/phases/12-complementary-systems-boundary-gtd-alignment/12-SPEC.md
@.planning/phases/12-complementary-systems-boundary-gtd-alignment/12-CONTEXT.md
@docs/reference/privacy-model.md
@docs/reference/brownfield.md
@docs/reference/schema-tour.md
@docs/reference/index.md
@.planning/notes/2026-04-24-agentic-gtd-boundary.md
@.planning/notes/2026-04-24-openbrain-vs-compendium-critique.md
@AGENTS.md
</context>

<threat_model>
N/A — pure docs phase. This plan adds one markdown reference doc under docs/reference/. No executable code paths, no API surface, no new attack surface introduced. Existing CI gates (neutrality, privacy-leak, lint) operate on content, not file boundaries, and continue to apply unchanged.
</threat_model>

<tasks>

<task type="auto" tdd="false">
  <name>Task 1: Write docs/reference/three-layer-model.md with 3-layer model + routing table + anti-features</name>
  <files>docs/reference/three-layer-model.md</files>
  <read_first>
    - .planning/phases/12-complementary-systems-boundary-gtd-alignment/12-SPEC.md (BOUND-02 acceptance criteria — routing table 4 verbs, anti-features explicit bullets)
    - .planning/phases/12-complementary-systems-boundary-gtd-alignment/12-CONTEXT.md (locked decisions D-01 filename, D-02 section order, D-03 opening framing, D-04..D-08 routing table cell content)
    - .planning/notes/2026-04-24-agentic-gtd-boundary.md (3-layer model + good-fits/poor-fits — primary source)
    - .planning/notes/2026-04-24-openbrain-vs-compendium-critique.md (anti-features list — primary source)
    - docs/reference/privacy-model.md (closest sibling style — opening paragraph + section cadence; note: it is currently a stub but its frontmatter-free markdown style is the model)
    - docs/reference/brownfield.md (larger sibling — opening paragraph + linked-table style; emulate its operator-facing tone)
    - docs/reference/schema-tour.md (operator-facing reference style — for cadence)
    - docs/reference/index.md (index entry to be added in Plan 12-03; reference for surrounding bullet shape)
    - AGENTS.md §4 (page-type enum: entity / concept / source / comparison / overview / decision — cited by the `organize` row's Compendium role cell)
  </read_first>
  <action>
Create exactly one new file at `docs/reference/three-layer-model.md`. Standard markdown, NO YAML frontmatter (operator-facing reference docs in `docs/reference/` are not wiki pages and do not carry `wiki/` frontmatter — match `docs/reference/privacy-model.md` and `docs/reference/brownfield.md` which both open with an `# H1` title and no frontmatter).

**Section order (per D-02):** opening paragraph → `## The Three Layers` → `## Routing Rules` → `## Anti-features` → `## See also`.

**Title (H1):** `# The Three-Layer Model`

**Opening framing paragraph (per D-03)** — drop the verbatim suggested wording, polished slightly for cadence:

> Compendium is the wiki-compiler layer of a multi-system stack. It owns durable, provenance-backed memory; complementary systems own task execution, calendar, reminders, and transactional / operational state. This document explains the boundary and routes four GTD-style verbs — capture, clarify, organize, review — across the three layers. (Classic GTD has five steps: capture, clarify, organize, reflect, engage. This document uses the four roadmap-scoped verbs intentionally — `engage` is operationally a task-system concern with no compendium contribution; `reflect` is folded into `review` here.)

**Section 1 — `## The Three Layers`:**

Three subsections (or a tight bulleted list — operator's choice for cadence; treat the structure as locked but the prose as discretionary):

- **Task layer** — owns executable commitments, next actions, reminders, calendar, waiting-for mechanics, and transactional state. Examples of typical task-layer systems: Things, OmniFocus, Todoist, a GTD-shaped capture-list, a calendar app. Heavy-read at every check-in; cheap-write at capture.
- **Working-memory layer** — owns recent conversations, scratch context, inbox material, short-lived reasoning state. Examples of typical working-memory systems: chat scrollback, an active LLM session's context, a daily-note inbox, an open Obsidian pane. Ephemeral by design; not the system of record for anything durable.
- **Wiki-compiler layer (compendium)** — owns durable synthesis, project support material, decisions and rationale, patterns across notes / journals / reading / conversations, higher-horizon thinking, long-term preferences, provenance-backed beliefs, and reflective memory. Heavy-write at ingest; cheap-read at query. The output is a persistent, compounding artifact — cross-references already there, contradictions already flagged, syntheses already reflect everything ingested.

Reference `.planning/notes/2026-04-24-agentic-gtd-boundary.md` for the original framing of the three layers.

**Section 2 — `## Routing Rules`:**

Open with the one-line caption verbatim from D-08 (operator may polish):

> Read each row as: when doing `<Verb>`, work primarily happens in `<Belongs in>`; `<Compendium role>` describes what (if anything) compendium contributes; `<Out of scope>` lists what compendium explicitly does not own.

Then the routing table — markdown table with EXACTLY these 4 columns and 4 rows in this order (per D-04, D-05, D-06, D-07):

```
| Verb | Belongs in | Compendium role | Out of scope |
|------|------------|-----------------|--------------|
| capture | working-memory layer | optionally ingest a captured note as a `wiki/sources/` entry once the note crosses the durable-synthesis threshold | inbox UI, quick-capture hotkeys, Slack / email / event-stream ingest |
| clarify | working-memory layer | no role at clarify time itself; durable rationale or decisions about clarified items can be ingested afterward as `wiki/decisions/`, `wiki/concepts/`, or other appropriate page types | next-action prompts, waiting-for tracking, energy / context tagging |
| organize | task layer | no role for executable task organization (projects / contexts / areas live in the task system); compendium organizes durable knowledge as `entity / concept / source / comparison / overview / decision` pages per AGENTS.md §4 | projects / contexts / areas database, scheduled / recurring tasks, calendar |
| review | all three layers (task + working-memory + wiki-compiler) | surface stale claims, contradictions, neglected projects, and durable insights via lint + query write-back; complement (not replace) the task system's review surfaces | GTD review dashboards, canonical Dataview review surfaces, reminder / nudge engines |
```

(The cell wording above is the locked semantic content from D-05 / D-06 / D-07. The operator may lightly polish prose for cadence as long as the four verbs in column 1, the layer mappings in column 2, and the semantic content of columns 3 and 4 are preserved.)

**Section 3 — `## Anti-features`:**

Open with one explanatory sentence:

> Compendium intentionally does not ship the following surfaces. Each item is a complementary-system responsibility — adding it to compendium would defeat the heavy-write / cheap-read shape that makes durable synthesis trustworthy.

Then a bulleted list with EVERY item below as an explicit bullet (per BOUND-02 acceptance — each must be a discrete bullet, not a buried mention):

- **Inbox UI / quick-capture interface** — capture is a working-memory-layer concern; compendium ingests durable material via `bin/ingest.sh`, not a tap-to-capture front door.
- **Next-action execution** — task-layer responsibility; compendium has no concept of "do this next."
- **Calendar** — task-layer responsibility; compendium has no time / scheduling primitives.
- **Reminders** — task-layer responsibility; compendium does not nudge, ping, or escalate.
- **Rapid transactional updates** — every wiki page is provenance-backed and contradiction-aware; high-frequency mutation defeats the auditability guarantees.
- **High-churn waiting-for state** — waiting-for is a clarify-time / task-layer artifact; tracking it in `wiki/` would create stale entries faster than ingest produces durable ones.
- **Slack / ticket / event-stream ingest** — operational data has no durability threshold and would flood the wiki with low-signal entries; complementary systems are the systems of record for events.

Each bullet header word/phrase MUST appear verbatim so the SPEC's grep audit (Plan 12-04) matches them: `inbox`, `next-action`, `calendar`, `reminder`, `rapid transactional`, `high-churn waiting-for`, `Slack`. (The acceptance criteria below assert each pattern with grep.)

Close with one sentence pointing out that the boundary is canonical:

> The complementary-systems boundary is captured as a decision record in `wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md` (BOUND-01); see that record for the framing pivot and rejected alternatives.

**Section 4 — `## See also`:**

Match the `## See also` cadence used in `docs/reference/privacy-model.md`:

- [AGENTS.md](../../AGENTS.md) — canonical schema (page types, frontmatter, workflows).
- [../../wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md](../../wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md) — BOUND-01 decision record (the architectural framing this doc operationalizes).
- [../../README.md](../../README.md) — entry point (the "What this is" section points back here).

**Cross-link rule:** Cite the BOUND-01 DR by relative path AND by ID string `dr-2026-05-01-complementary-systems-boundary` so the acceptance grep matches both the link form and the bare-ID form. The closing sentence of the Anti-features section names the DR by ID; the See-also section names it by relative path.

**Style:** Match the operator-facing tone of `docs/reference/brownfield.md` (clear, declarative, no marketing voice, no emojis). Use plain markdown links (NOT wikilinks — this is `docs/`, not `wiki/`).
  </action>
  <verify>
    <automated>test -f docs/reference/three-layer-model.md && grep -c '^## \(The Three Layers\|Routing Rules\|Anti-features\|See also\)$' docs/reference/three-layer-model.md | grep -q '^4$' && grep -E '^\| (capture|clarify|organize|review) \|' docs/reference/three-layer-model.md | wc -l | grep -q '^4$'</automated>
  </verify>
  <acceptance_criteria>
    - File exists at the locked path: `test -f docs/reference/three-layer-model.md` returns exit 0.
    - All 4 H2 sections present: `grep -c '^## \(The Three Layers\|Routing Rules\|Anti-features\|See also\)$' docs/reference/three-layer-model.md` returns exactly `4`.
    - H1 title present: `grep -c '^# The Three-Layer Model$' docs/reference/three-layer-model.md` returns exactly `1`.
    - File has NO YAML frontmatter (operator-facing reference doc per Phase 12 constraint): `head -1 docs/reference/three-layer-model.md | grep -c '^---$'` returns 0.
    - Routing table has all 4 GTD verbs as left-column rows: `grep -E '^\| (capture|clarify|organize|review) \|' docs/reference/three-layer-model.md | wc -l` returns exactly `4`.
    - Routing table header present with the 4 specified columns: `grep -c '^| Verb | Belongs in | Compendium role | Out of scope |$' docs/reference/three-layer-model.md` returns at least 1.
    - `capture` row maps to working-memory layer: `grep -E '^\| capture \| working-memory layer \|' docs/reference/three-layer-model.md` returns exit 0 (1 match).
    - `clarify` row maps to working-memory layer: `grep -E '^\| clarify \| working-memory layer \|' docs/reference/three-layer-model.md` returns exit 0.
    - `organize` row maps to task layer: `grep -E '^\| organize \| task layer \|' docs/reference/three-layer-model.md` returns exit 0.
    - `review` row maps to all three layers: `grep -E '^\| review \| all three layers' docs/reference/three-layer-model.md` returns exit 0.
    - Anti-features section has bullets for each required item (each as a separate bullet line under `## Anti-features`):
      - `awk '/^## Anti-features$/,/^## See also$/' docs/reference/three-layer-model.md | grep -Eic 'inbox' ` returns at least 1.
      - `awk '/^## Anti-features$/,/^## See also$/' docs/reference/three-layer-model.md | grep -Eic 'next-action'` returns at least 1.
      - `awk '/^## Anti-features$/,/^## See also$/' docs/reference/three-layer-model.md | grep -Eic 'calendar'` returns at least 1.
      - `awk '/^## Anti-features$/,/^## See also$/' docs/reference/three-layer-model.md | grep -Eic 'reminder'` returns at least 1.
      - `awk '/^## Anti-features$/,/^## See also$/' docs/reference/three-layer-model.md | grep -Eic 'rapid transactional'` returns at least 1.
      - `awk '/^## Anti-features$/,/^## See also$/' docs/reference/three-layer-model.md | grep -Eic 'high-churn waiting-for'` returns at least 1.
      - `awk '/^## Anti-features$/,/^## See also$/' docs/reference/three-layer-model.md | grep -Eic 'slack|ticket|event-stream'` returns at least 1.
    - Cites the BOUND-01 DR by ID: `grep -c 'dr-2026-05-01-complementary-systems-boundary' docs/reference/three-layer-model.md` returns at least 1.
    - Cites the BOUND-01 DR by relative path in See-also: `grep -c '../../wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md' docs/reference/three-layer-model.md` returns at least 1.
    - Routing-table caption present (locked one-liner from D-08, allowing minor prose polish): `grep -Eic 'Read each row as.*Verb.*Belongs in.*Compendium role.*Out of scope' docs/reference/three-layer-model.md` returns at least 1.
    - All three layers named in `## The Three Layers` section: `awk '/^## The Three Layers$/,/^## Routing Rules$/' docs/reference/three-layer-model.md | grep -Eic 'task layer'` returns at least 1, AND `awk '/^## The Three Layers$/,/^## Routing Rules$/' docs/reference/three-layer-model.md | grep -Eic 'working-memory layer'` returns at least 1, AND `awk '/^## The Three Layers$/,/^## Routing Rules$/' docs/reference/three-layer-model.md | grep -Eic 'wiki-compiler layer'` returns at least 1.
  </acceptance_criteria>
  <done>
    Reference doc exists at `docs/reference/three-layer-model.md`, has the 4 H2 sections, the 4-verb routing table with locked semantic cell content, the anti-features section with explicit bullets for every SPEC-required item, and citation of the BOUND-01 DR by both ID and relative path.
  </done>
</task>

</tasks>

<verification>
- File exists at `docs/reference/three-layer-model.md` with no YAML frontmatter.
- 4 H2 sections in the locked order.
- Routing table: 4 columns (Verb / Belongs in / Compendium role / Out of scope), 4 rows (capture / clarify / organize / review), semantic cell content per D-05/D-06/D-07.
- Anti-features section contains every SPEC-required item as an explicit bullet.
- Cites BOUND-01 DR by ID and by relative path.
- Sibling style matches docs/reference/privacy-model.md + docs/reference/brownfield.md cadence.
</verification>

<success_criteria>
- `docs/reference/three-layer-model.md` exists and matches all acceptance criteria above.
- The doc is consumable by Plan 12-03 (README pointer cites this doc by relative path; docs/reference/index.md adds a bullet pointing here).
- The doc is consumable by Plan 12-04 (BOUND-03 reviewed-match audit — all `inbox` / `task manager` / `calendar` / `reminders` mentions inside this file's Anti-features section are correctly framed as exclusions, so the audit annotates them `negative-framing`).
</success_criteria>

<output>
After completion, this ref doc is consumed by:
- Plan 12-03 (README "What this is" pointer cites `docs/reference/three-layer-model.md`; docs/reference/index.md adds a bullet for it).
- Plan 12-04 (audit grep scans the Anti-features section; matches must verdict `negative-framing`).
- Plan 12-01 (BOUND-01 DR's Sources section cross-links this doc by relative path — already covered by Plan 12-01's content).
</output>
