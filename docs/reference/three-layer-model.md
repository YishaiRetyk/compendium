# The Three-Layer Model

Compendium is the wiki-compiler layer of a multi-system stack. It owns durable, provenance-backed memory; complementary systems own task execution, calendar, reminders, and transactional / operational state. This document explains the boundary and routes four GTD-style verbs — capture, clarify, organize, review — across the three layers. (Classic GTD has five steps: capture, clarify, organize, reflect, engage. This document uses the four roadmap-scoped verbs intentionally — `engage` is operationally a task-system concern with no compendium contribution; `reflect` is folded into `review` here.)

## The Three Layers

- **Task layer** — owns executable commitments, next actions, reminders, calendar, waiting-for mechanics, and transactional state. Examples of typical task-layer systems: Things, OmniFocus, Todoist, a GTD-shaped capture-list, a calendar app. Heavy-read at every check-in; cheap-write at capture.
- **Working-memory layer** — owns recent conversations, scratch context, inbox material, short-lived reasoning state. Examples of typical working-memory systems: chat scrollback, an active LLM session's context, a daily-note inbox, an open Obsidian pane. Ephemeral by design; not the system of record for anything durable.
- **Wiki-compiler layer (compendium)** — owns durable synthesis, project support material, decisions and rationale, patterns across notes / journals / reading / conversations, higher-horizon thinking, long-term preferences, provenance-backed beliefs, and reflective memory. Heavy-write at ingest; cheap-read at query. The output is a persistent, compounding artifact — cross-references already there, contradictions already flagged, syntheses already reflect everything ingested.

The original framing of these three layers lives in `.planning/notes/2026-04-24-agentic-gtd-boundary.md`.

## Routing Rules

Read each row as: when doing `<Verb>`, work primarily happens in `<Belongs in>`; `<Compendium role>` describes what (if anything) compendium contributes; `<Out of scope>` lists what compendium explicitly does not own.

| Verb | Belongs in | Compendium role | Out of scope |
|------|------------|-----------------|--------------|
| capture | working-memory layer | optionally ingest a captured note as a `wiki/sources/` entry once the note crosses the durable-synthesis threshold | inbox UI, quick-capture hotkeys, Slack / email / event-stream ingest |
| clarify | working-memory layer | no role at clarify time itself; durable rationale or decisions about clarified items can be ingested afterward as `wiki/decisions/`, `wiki/concepts/`, or other appropriate page types | next-action prompts, waiting-for tracking, energy / context tagging |
| organize | task layer | no role for executable task organization (projects / contexts / areas live in the task system); compendium organizes durable knowledge as `entity / concept / source / comparison / overview / decision` pages per AGENTS.md §4 | projects / contexts / areas database, scheduled / recurring tasks, calendar |
| review | all three layers (task + working-memory + wiki-compiler) | surface stale claims, contradictions, neglected projects, and durable insights via lint + query write-back; complement (not replace) the task system's review surfaces | GTD review dashboards, canonical Dataview review surfaces, reminder / nudge engines |

## Anti-features

Compendium intentionally does not ship the following surfaces. Each item is a complementary-system responsibility — adding it to compendium would defeat the heavy-write / cheap-read shape that makes durable synthesis trustworthy.

- **Inbox UI / quick-capture interface** — capture is a working-memory-layer concern; compendium ingests durable material via `bin/ingest.sh`, not a tap-to-capture front door.
- **Next-action execution** — task-layer responsibility; compendium has no concept of "do this next."
- **Calendar** — task-layer responsibility; compendium has no time / scheduling primitives.
- **Reminders** — task-layer responsibility; compendium does not nudge, ping, or escalate.
- **Rapid transactional updates** — every wiki page is provenance-backed and contradiction-aware; high-frequency mutation defeats the auditability guarantees.
- **High-churn waiting-for state** — waiting-for is a clarify-time / task-layer artifact; tracking it in `wiki/` would create stale entries faster than ingest produces durable ones.
- **Slack / ticket / event-stream ingest** — operational data has no durability threshold and would flood the wiki with low-signal entries; complementary systems are the systems of record for events.

The complementary-systems boundary is captured as a decision record in `wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md` (BOUND-01); see that record for the framing pivot and rejected alternatives.

## See also

- [AGENTS.md](../../AGENTS.md) — canonical schema (page types, frontmatter, workflows).
- [../../wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md](../../wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md) — BOUND-01 decision record (the architectural framing this doc operationalizes).
- [../../README.md](../../README.md) — entry point (the "What this is" section points back here).
