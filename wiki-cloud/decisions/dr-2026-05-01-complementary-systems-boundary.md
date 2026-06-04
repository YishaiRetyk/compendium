---
id: dr-2026-05-01-complementary-systems-boundary
title: "Complementary Systems Boundary: Compendium as Durable Wiki Memory in a Multi-System
  Stack"
type: decision
status: active
summary: "Compendium owns durable, provenance-backed wiki memory and review support;
  complementary systems own executable commitments, reminders, calendars, transactional
  state, and high-churn operational events."
created_at: 2026-05-01
updated_at: 2026-05-01
sources: []
epistemic_status: sourced
tags:
- boundary
- architecture
- gtd-alignment
- meta
domains:
- wiki-infrastructure
supersedes: null
superseded_by: null
aliases:
- "Complementary Systems Boundary: Compendium as Durable Wiki Memory in a Multi-System
  Stack"
- "dr-2026-05-01-complementary-systems-boundary"
has_contradictions: false
knowledge_domain: software
trigger_type: schema-update
affected_pages: []
---

<!-- FORBIDDEN PATTERNS (see AGENTS.md section 3):
     - No wikilinks in frontmatter (use plain string IDs in sources[], affected_pages[], supersedes, etc.)
     - No display aliases: write [[Page Title]] not [[Page Title|Alias]]
     - Link each page only on first mention in the body -->

## TL;DR

Compendium owns durable, provenance-backed wiki memory and review support; complementary systems (task manager, calendar, reminder engine, working-memory layer) own executable commitments, transactional state, and high-churn operational events. This record makes the multi-system stack explicit in the canonical shipped surface before v1.1 closes — `CLOSE-04`'s scope-leak gate depends on the boundary being stated, not merely implied.

## Decision

Adopt the following architectural framing for compendium and the systems it sits beside:

- **Compendium** is the wiki-compiler layer of a multi-system agent stack. It owns: durable synthesis, decisions and rationale, provenance-backed beliefs, reflective memory, and review support that surfaces stale claims, contradictions, neglected projects, and durable insights.
- **Complementary systems** own the layers compendium does NOT serve: a task layer (executable commitments, next actions, reminders, calendar, waiting-for mechanics, transactional state) and a working-memory layer (recent conversations, scratch context, inbox material, short-lived reasoning state).
- The boundary is captured in this decision record as the canonical home per AGENTS.md §4.6 and elaborated operationally in [docs/reference/three-layer-model.md](../../docs/reference/three-layer-model.md), which carries the 3-layer model, the 4-verb routing table (capture / clarify / organize / review), and the explicit anti-features list.

## Why

Compendium is heavy-write at ingest and cheap-read at query — the opposite shape of a task / GTD backend, which is heavy-read at every check-in and cheap-write at capture. Conflating the two layers produces a system that is bad at both: noisy and high-friction for transactional task work, and shallow and unfaithful for durable synthesis. The framing adopted is "compendium owns durable, provenance-backed synthesis and reflective memory; complementary systems own executable commitments, reminders, calendars, and transactional / operational state." The framing it replaces is the implicit "all-in-one PKM/task system" assumption that compendium would absorb inbox capture, next-action execution, calendar, reminders, and high-churn operational state. That implicit framing was never written down but was the natural drift direction; this record makes the rejection explicit before v1.1 closes.

The substance of this framing pivot was developed in `.planning/notes/2026-04-24-openbrain-vs-compendium-critique.md` (heavy-write/cheap-read tradeoff + non-goals) and `.planning/notes/2026-04-24-agentic-gtd-boundary.md` (3-layer model + good-fits / poor-fits lists). This decision record promotes that exploratory substance into the canonical shipped surface.

## Alternatives Considered

- **All-in-one PKM/task system framing.** Rejected as a fundamental category error: compendium's ingest pipeline is heavy-write / cheap-read (correct for durable synthesis), which is the wrong shape for capture, clarify, and execute workflows that need cheap-write / heavy-read. Treating compendium as a task backend would produce a system that is shallow at both jobs — high friction for transactional task work and unfaithful for durable knowledge. See `.planning/notes/2026-04-24-openbrain-vs-compendium-critique.md` for the heavy-write/cheap-read tradeoff and `.planning/notes/2026-04-24-agentic-gtd-boundary.md` for the 3-layer good-fits / poor-fits analysis.
- **Deferring the boundary statement to v2.** Rejected because `CLOSE-04` (final scope-leak check) cannot pass while the canonical shipped surface lacks an explicit complementary-systems boundary. Without this record, README.md and `docs/` could be read as ambient endorsement of all-in-one framing, making the v1.1 closure gate unverifiable. Stating the boundary now is cheaper than letting drift accumulate and reframing later.
- **Embedding the boundary inline in README only.** Rejected because decision records are the canonical home for architectural decisions per AGENTS.md §4.6 and the Phase 6 `dr-2026-04-14-phase6-decision-type` precedent. README can point at the boundary, but the boundary itself is structural and lives in `wiki/decisions/`. README is not where future readers will look to ask "why is the wiki shaped this way?" — that is the question decision records answer.

## Consequences

- The complementary-systems boundary is now canonical: future work that would add a task manager, calendar, reminder engine, inbox UI, or Slack/ticket/event-stream ingest pipeline to compendium must either supersede this record or live in a complementary system.
- `docs/reference/three-layer-model.md` becomes the operator-facing operationalization of this record (3-layer model + capture/clarify/organize/review routing + anti-features list). The DR states what the boundary is; the ref doc states how to route work across the boundary.
- README.md gains one contextual pointer sentence under "What this is" (per BOUND-03) referencing the new ref doc — the boundary becomes discoverable from the entry point without bloating the README surface.
- No new wiki page types or `wiki/` directory taxonomies are added. AGENTS.md §4 still enumerates exactly 6 page types (entity, concept, source, comparison, overview, decision); `wiki/` retains its existing top-level subdirectory set. Adding a new type or directory to express the boundary would itself contradict the boundary.
- REQUIREMENTS.md `BOUND-01` (this record), `BOUND-02` (the ref doc), and `BOUND-03` (audit + README pointer + indexes) become unblocked; `CLOSE-04` scope-leak gate becomes verifiable once Phase 12 closes.
- Deferred items remain deferred: GTD review dashboards (backlog Phase 999.6 per ROADMAP.md), task-system bridging (out of scope for v1.1), Slack/ticket/event-stream ingest design (out of scope per ROADMAP.md non-goals). Those concerns belong to complementary systems by definition, not to compendium.

## Affected Pages

None. This is an infrastructure-only decision record (`affected_pages: []`); no pre-existing wiki pages are restructured by stating the complementary-systems boundary.

## Sources

- [.planning/notes/2026-04-24-agentic-gtd-boundary.md](../../.planning/notes/2026-04-24-agentic-gtd-boundary.md) — 3-layer model + good-fits/poor-fits lists.
- [.planning/notes/2026-04-24-openbrain-vs-compendium-critique.md](../../.planning/notes/2026-04-24-openbrain-vs-compendium-critique.md) — heavy-write/cheap-read tradeoff + non-goals.
- [.planning/notes/2026-04-24-wiki-compiler-idea.md](../../.planning/notes/2026-04-24-wiki-compiler-idea.md) — architecture origin.
- [.planning/REQUIREMENTS.md](../../.planning/REQUIREMENTS.md) — BOUND-01, BOUND-02, BOUND-03.
- [.planning/ROADMAP.md](../../.planning/ROADMAP.md) — Phase 12 entry.
- [docs/reference/three-layer-model.md](../../docs/reference/three-layer-model.md) — operator-facing 3-layer model + routing rules.
