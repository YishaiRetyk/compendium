---
title: "Agent Memory Interface — MCP read/write surface over the wiki (deferred)"
trigger_condition: "v1.1 closes (Phase 13.2 gate passes) AND a concrete second agent/system in the stack needs programmatic wiki access (read at minimum), OR the GTD/working-memory layer described in docs/reference/three-layer-model.md gets a real implementation that must query durable memory"
planted_date: 2026-05-31
milestone_hint: v1.2+
---

# Agent Memory Interface — MCP read/write surface over the wiki (deferred)

## What

Expose compendium to *other* agents in a multi-system stack as the durable-memory layer, via a stable programmatic interface (MCP is the natural transport — cf. Neo4j Labs `create-context-graph`, which generates exactly this for Claude Desktop over its graph). The role is already declared in `dr-2026-05-01-complementary-systems-boundary.md`; this seed is about the *interface*, not the framing.

**Two-tier design (the load-bearing split):**

- **Tier 1 — Read / search / compare (build first).** Broad, read-only, the *cheap-read* surface compendium is architecturally optimized for. Tools: search (`bin/search.sh` already exists), get-page (progressive disclosure: TL;DR → Key Facts → Detail), navigate index, compare N pages. Zero integrity risk; immediately makes the wiki shared memory for the agent stack. This is the high-value, low-risk starting point.
- **Tier 2 — Guarded writes (build cautiously).** Expose the EXISTING high-altitude operations — `UPDATE / MERGE / SUPERSEDE / ARCHIVE` (§9) and the ingest/query workflows (§11) — each running its *full* pipeline (`validate-op.sh` → provenance-required → Phase 12.2 write-gate → `log.md` audit entry). NEVER raw `create_node` / `create_link` CRUD primitives.

**Audit logging is ~80% already shipped** — do not rebuild. `log.md` is an append-only structured operation log (§12); git is a second trail; `validate-op.sh` is pre-write validation; `lint` is post-write integrity; **DRFT-04** (lint, shipped 2026-05-31) is an operation↔git reconciliation check that catches "operation logged but artifacts not committed." The net-new work is *exposing* a machine-readable per-operation record for an external consumer (reuse the `--format json` precedent), not inventing an audit mechanism.

## Why this is deferred (and why the obvious framing is wrong)

1. **Wrong altitude trap.** The intuitive framing — "create node, create link, compare, search" — is NAMS/graph-primitive (cheap-write CRUD) vocabulary. Adopting it literally recreates `neo4j-agent-memory` and discards provenance, typing, append-then-synthesize, contradiction handling, and the write-gate — i.e. everything that differentiates *curated* memory from *accumulating* memory. The Phase 12 DR names this exact category error: compendium is **heavy-write / cheap-read**, the opposite shape of the cheap-write store CRUD primitives assume. A `create_node({text})` primitive fights the architecture. Writes must stay pipeline-mediated.

2. **Phase 12 boundary is binding.** `dr-2026-05-01-complementary-systems-boundary.md` consequence list: **no new page types, no new directory taxonomies.** If the interface tempts a generic "node" concept distinct from the 6 page types (entity/concept/source/comparison/overview/decision), that contradicts the shipped boundary. The interface is a surface *over* the existing model, not an expansion of it.

3. **Concurrency → Tier 4 pressure.** Today's model assumes one agent writing at a time. Multiple agents writing a markdown+git wiki = merge conflicts and lost updates. §14 Tier 4 (DB-backed metadata / SQLite acceleration layer) is the project's pre-registered answer. A genuinely concurrent write interface pulls Tier 4 forward; a single-writer-serialized interface avoids it. This is a real architectural fork to decide at design time, not bolt-on.

4. **Provenance erosion under automation.** The faster/more-primitive writes get, the more tempting it is to skip provenance — exactly the error-compounding Phase 13 exists to fight. Any write op must keep provenance mandatory *at the boundary*.

5. **Scope discipline.** Mid-v1.1 with Phase 13 (Claim Faithfulness Audit) next; this is a v1.2+ structural move. It deserves its own decision record (architectural framing belongs in `wiki/decisions/`, like Phase 12) and its own phase, not a bolt-on.

## Revisit trigger

Surface this seed when ANY becomes true:

- v1.1 closes (Phase 13.2 closure gate passes) — clears the scope-discipline objection.
- A second system in the stack (task layer or working-memory layer per `three-layer-model.md`) gets a real implementation that needs to *read* durable memory programmatically — Tier 1 alone justifies the build.
- An external agent (Claude Desktop via MCP, or a non-Claude agent) has a concrete need to query the wiki and ad-hoc `Read`/grep is proving insufficient.

## Out of scope at revisit time

- Low-level node/edge CRUD primitives that bypass the operations pipeline (the core anti-pattern this seed exists to prevent).
- New page types or `wiki/` directory taxonomies (contradicts `dr-2026-05-01-complementary-systems-boundary.md`).
- Turning compendium into a task/calendar/reminder backend (complementary-systems boundary — those live in the task layer).
- Slack/ticket/event-stream ingest as a write source (deferred per ROADMAP non-goals; belongs to complementary systems).
- Auto-write-back without provenance, or any write that skips the write-gate / `validate-op.sh`.

## Related artifacts

- Binding decision: `wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md` (compendium = durable-memory layer; heavy-write/cheap-read; no new types/taxonomies)
- Operationalization: `docs/reference/three-layer-model.md` (3-layer model + capture/clarify/organize/review routing + anti-features)
- Memory-layer framing context: `agentic-gtd-system-with-wiki-compiler.md` (repo root) — its "Personal Assistant Memory" section is the use-case; note the automatic-vs-curated contrast with NAMS
- Reference implementations (cloned to /tmp during 2026-05-31 exploration): `neo4j-labs/create-context-graph` (generates an MCP server over agent memory — read/write tool profiles `core`/`extended`), `neo4j-labs/llm-graph-builder` (retrieval modes)
- Scaling constraint: AGENTS.md §14 Tier 4 (DB-backed metadata for concurrent access)
- Existing audit surface: AGENTS.md §12 (`log.md`), §9 (`validate-op.sh`), §11.3 lint DRFT-04 (operation↔git reconciliation)
- Operations to expose as the guarded write surface: AGENTS.md §9 (UPDATE/MERGE/SUPERSEDE/ARCHIVE), §11 (ingest/query workflows)
