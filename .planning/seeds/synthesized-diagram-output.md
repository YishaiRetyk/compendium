---
title: "Synthesized diagrams as a page output — mermaid relationship maps with provenance on edges"
trigger_condition: "You want a wiki page to contain an LLM-generated synthesis diagram (e.g., a query answer is best expressed as a relationship map, or an overview/concept page would benefit from a visual of how its entities/concepts connect). Promote to /gsd-discuss-phase when ready to plan."
planted_date: 2026-06-04
milestone_hint: v1.3+ or standalone (authoring/output capability, NOT a source type; NOT v1.2)
---

# Synthesized diagrams as a page output (mermaid, edges = provenanced claims)

## What

Let wiki pages **contain LLM-generated diagrams** (mermaid first — Obsidian renders it natively; you
already have a `creating-mermaid-diagrams` skill) that *synthesize* relationships across the wiki:
architecture maps, concept-derivation trees, comparison matrices, flow-of-influence graphs. The idea
note already endorses diagram/chart/canvas as legitimate query-answer forms; this seed is about doing it
*with the system's provenance discipline intact*.

**This is NOT a source type.** It is a page **output / authoring** capability (Role 3 from the
2026-06-04 "graphs as source?" discussion — Roles 1–2, graphs *inside* sources, are already handled by
`#img`/`image-heavy` and need nothing). It belongs to page authoring + the query workflow's write-back,
not to ingest.

## The crux: a diagram's edges are claims

A mermaid edge `A --> B` asserts a relationship. If that assertion has no provenance, you have **smuggled
an unprovenanced claim into a picture** — exactly the kind of laundering the system exists to prevent.
So the load-bearing design question is: *where does edge-provenance live, and what keeps a diagram
honest?*

**Leaning (input for discuss, NOT locked): a diagram is a VIEW over already-provenanced claims, not a new
claim surface.** Under this framing:
- Every edge in a synthesized diagram must correspond to a claim **already provenanced in the page body**
  (prose with `[prov:src#loc]`). The diagram re-presents existing provenanced content visually — it
  introduces no new unbacked assertions.
- This mirrors progressive disclosure: the **diagram is the shallow visual** (like TL;DR), the
  **provenanced claim list is the substance** (like Key Facts / Detail). Mermaid stays clean; provenance
  stays grep-able in the body.
- A diagram edge with **no corresponding provenanced claim** on the page is the lint-able violation
  (candidate new lint check: "every mermaid edge maps to a provenanced body claim").

## Design options for where provenance attaches (all OPEN)

1. **Companion provenanced legend (leaning).** Diagram + a body list where each edge is a provenanced
   bullet: `- A → B: <claim> [prov:src#loc]`. Cleanest; keeps mermaid syntax untouched; provenance
   grep-able.
2. **Mermaid comments** `%% [prov:src#loc]` inside the block. Grep-able but invisible/fragile.
3. **Edge labels carry ref-ids** `A -->|r3| B`, resolved in a legend. Hybrid of 1 and 2.

## Why this is genuinely novel (and what it connects to)

- **The wiki *is* a graph** (Obsidian graph view; wikilinks = edges; v1.1.1 was entirely about its
  connectivity). A synthesized in-page diagram is a *curated, provenanced* sub-graph view — complementary
  to Obsidian's automatic link graph.
- **Typed-edges-as-data:** relates to the neo4j `ccg-edges` idea parked in
  `[[agent-memory-interface]]` (a fenced structured edge block in a page body, lint-parseable). A
  provenanced mermaid diagram is the human-legible cousin of that machine-typed-edge concept — worth
  designing them together if both promote.
- **Stale-synthesis risk:** a diagram drifts from its underlying claims exactly like an overview drifts
  from its members — the cluster/overview staleness signal in `[[wiki-quality-heuristics]]` applies
  (flag diagrams whose source claims changed since the page's `updated_at`).

## Open questions for `/gsd-discuss-phase` (do NOT pre-decide)

1. **View-over-claims vs new-claim-surface:** is a diagram strictly a re-presentation of already-
   provenanced body claims (leaning), or may it introduce edges that are themselves the provenance anchor?
2. **Where provenance attaches:** companion legend / mermaid comments / edge-label ref-ids (options above)?
3. **Lint enforcement:** add a check that every mermaid edge maps to a provenanced body claim? Severity?
4. **Which page types** may carry synthesis diagrams (overview/comparison natural; entity/concept?), and
   does it touch the §4/§7 section-ordering (e.g., an optional `## Diagram` slot)?
5. **Diagram beyond mermaid:** matplotlib/canvas/other (the idea note lists them) — in scope or mermaid-only?
6. **Query write-back:** when a query answer is best expressed as a diagram, how does it file back
   (UPDATE a page with a `## Diagram` + legend) per §11.2 write-back?
7. **Staleness:** how to detect/flag a diagram that drifted from its underlying claims (tie to
   `[[wiki-quality-heuristics]]` cluster/overview staleness)?
8. **Relationship to typed-edges (`[[agent-memory-interface]]` ccg-edges):** one mechanism or two
   (human-legible mermaid vs machine-parseable edge block)?

## Out of scope at revisit time

- Diagrams with **unprovenanced edges** presented as fact (the core anti-pattern this seed exists to
  prevent).
- Treating diagrams as a new *source* type (they are output; graphs-in-sources are Role 1, already handled).
- A general drawing/whiteboard surface or interactive editor — markdown-renderable diagrams only.
- New page types or directory taxonomies (binding: `dr-2026-05-01-complementary-systems-boundary`).

## Why deferred (not v1.2)

New *authoring capability*, not extraction. v1.2 Schema Architecture relocates existing spec text; this
adds page-output behavior + possibly a lint check. v1.3-ish or standalone.

## Privacy

A diagram synthesizing `wiki-local/` content is itself local — it stays on the local side under the v1.2
Phase-0 two-dir model (a cloud session must not render/read it). Standard fail-closed default applies.

## Revisit trigger

- A query answer is genuinely best expressed as a diagram and you want it filed back into a page.
- An overview/comparison page would be clearer with a relationship map than prose.
- `[[agent-memory-interface]]` (typed edges) or `[[wiki-quality-heuristics]]` (cluster/overview) promotes
  — design the diagram view alongside.

## Related artifacts

- Origin discussion: 2026-06-04 "graphs as a source?" (Role-3 split: embedded/standalone/output)
- Related seeds: `[[agent-memory-interface]]` (ccg-edges typed-edges-as-data),
  `[[wiki-quality-heuristics]]` (cluster/overview detection + stale-synthesis),
  `[[primary-source-type-extensions]]` (Roles 1–2: graphs *inside* sources)
- Rendering substrate: Obsidian mermaid; `creating-mermaid-diagrams` skill
- Provenance grammar: AGENTS.md §6 (`[prov:src#loc]`); §8 wikilinks (the existing edge layer)
- Output-form precedent: idea note `.planning/notes/2026-04-24-wiki-compiler-idea.md` (chart/canvas/Marp answers)
- Write-back: AGENTS.md §11.2 query workflow
