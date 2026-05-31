---
title: "Wiki quality heuristics — dedup, tag/domain consolidation, cluster/overview detection (deferred)"
trigger_condition: "v1.1 closes AND the wiki grows enough that quality drift is observed in practice (tag/domain sprawl, or domains large enough to warrant overviews) — i.e. Tier-1 limits start to bite per AGENTS.md §14. EXCEPTION: lexical dedup (item a1) is dependency-free and promotable immediately via /gsd-quick the moment a duplicate-ish page pair is observed — it is NOT gated by this trigger."
planted_date: 2026-05-31
milestone_hint: v1.2+
---

# Wiki quality heuristics — dedup, tag/domain consolidation, cluster/overview detection (deferred)

## What

A cluster of markdown-native, mostly dependency-free lint/reflect-tier quality checks, ported (at compendium's altitude) from GraphRAG enrichment mechanisms in `neo4j-labs/llm-graph-builder`. Source analysis + file:line references: `.planning/notes/2026-05-31-neo4j-graph-tools-comparison.md` (learnings #2, #3, #4, #5, #6).

**(a) Near-duplicate page detection → MERGE candidates. TWO STAGES — do NOT conflate them:**

- **(a1) Lexical dedup — dependency-free, NOT gated by this milestone.** New lint check `category: duplicate`, severity `warning`, report-only. Flag same-`type` page pairs when EITHER: one title/alias contains the other as a substring, OR edit distance < 3 (for strings >5 chars). Survivor heuristic = the page with more inbound wikilinks (graph-builder orders by node degree). Pure string ops, zero new dependencies. **This stage is small enough to ship as a standalone `/gsd-quick` enhancement once v1.1 closes** (precedent: backlog Phase 999.7, a one-flag lint/CLI addition delivered via `/gsd-quick` without a phase) — it does not need the rest of this seed to gate it. Promote it the moment a duplicate-ish pair is first observed; value grows with page count but the code is ready at any scale. Closes compendium's weakest current relationship heuristic — today nothing detects `Attention Mechanism` vs `Attention Mechanisms` or `Geoff Hinton` vs `Geoffrey Hinton`.
- **(a2) Semantic dedup — Tier-4-gated extension.** Augment (a1) with embedding cosine similarity > 0.97 (graph-builder's `DUPLICATE_SCORE_VALUE`) to catch reworded-but-equivalent pages that share no lexical overlap. Rides the embedding index from (d) below; ships only when Tier 4 + a local embedding model exist. This is the same code path as (a1) with one extra candidate-pairing predicate.

Both stages: same-`type` only, feed the existing `MERGE` operation (§9), never auto-merge (MERGE stays human-confirmed — exactly graph-builder's propose/confirm split).

**(b) Tag/domain consolidation (canonicalization).**
Reflect-tier (or lint `info`) check: surface near-synonym `tags`/`domains` across the corpus (`agent-skills`/`agent-skill`/`skills`; `ai-agents`/`autonomous-agents`) and propose a canonicalization map, applied via a logged decision record. compendium's tag/domain lists are free-form with no reconciliation mechanism today.

**(c) Cluster / overview detection.**
Lint `info`: find densely interlinked page clusters (connected components / high mutual-wikilink density within a domain) that LACK an `overview` page → suggest creating one. Also flag overviews whose member pages changed materially since the overview's `updated_at` (stale-synthesis signal). Inverse of §14's "split pages too large." Pairs with connectivity ranking (rank pages by inbound-wikilink count) — already used for Phase 13 sampling.

**(d) Embedding-derived index (heavier; Tier-4-gated extension).**
A `bin/`-computed embedding index (markdown stays source of truth; index regenerable) enabling "semantically near but unlinked → suggest cross-reference" (catches conceptual neighbors that share no tags, which the lexical missing-xref check misses) and powering the semantic dedup stage (a2). This is the natural content of §14 Tier 4's derived/SQLite acceleration layer. **Privacy-gated (§13):** `local_only` pages must route through a LOCAL embedding model, never a cloud API; gate the whole feature behind local-model availability. Do NOT build until (a)–(c) exist and Tier 4 is justified.

**(e) Local-vs-global query routing (lightest; may not need a full phase).**
§11.2 query workflow has one inherently-*local* retrieval path. Add: classify a question local-vs-global; for broad/global questions, read `overview` TL;DRs first (a global synthesis layer) rather than deep-reading many entity pages. Cheap query-workflow refinement, no deps. Could ship as a small §11.2 enhancement independent of this phase.

## Why this is deferred

1. **Premature without volume.** These are quality heuristics for a wiki past Tier-1 limits (§14). At current page counts they'd find little and add lint noise. The trigger is observed drift, not a date.
2. **Scope discipline.** v1.1 is "make the template shareable"; quality-heuristic expansion is v1.2+ and would widen scope. Phase 13 (faithfulness) is the prioritized integrity work for now.
3. **Embeddings cross a dependency/architecture line.** (d) — and the semantic dedup stage (a2) that depends on it — add a derived index + local-model dependency + privacy surface: a Tier-4 move that should follow, not precede, the dependency-free checks (a1)–(c) and a real need.

**Carve-out:** the **lexical dedup stage (a1)** is the exception to this deferral — it is dependency-free and ready now, and is best promoted as a standalone `/gsd-quick` task whenever a duplicate-ish pair is first observed, independent of this seed's milestone. The deferral above governs (a2), (b), (c), (d), (e) — the parts that need volume or Tier 4.

## Revisit trigger

Surface when ANY becomes true:
- Duplicate-ish or near-synonym pages are observed coexisting (manual MERGE friction appears).
- `tags`/`domains` sprawl is noticeable when authoring (uncertainty about which variant to use).
- A domain grows large enough that a hand-authored overview is overdue, or an existing overview has visibly drifted from its members.
- §14 Tier 4 (DB-backed metadata) is adopted for other reasons — then (d) embeddings + semantic dedup (a2) become cheap to add.
- (a1 only) a duplicate-ish page pair is observed — promote the lexical dedup check immediately via `/gsd-quick`, independent of the rest of this seed.

## Out of scope at revisit time

- Auto-merge / auto-rewrite of any kind (report-only; MERGE stays human-confirmed per §9).
- New page types or `wiki/` directory taxonomies (contradicts `dr-2026-05-01-complementary-systems-boundary.md`).
- Sending `local_only` content to any cloud embedding/LLM API (§13) — local model or skip.
- Building the embedding index (d) / semantic dedup (a2) before the dependency-free checks (a1)–(c) prove the value and Tier 4 is justified.

## Related artifacts

- Source analysis + file:line refs: `.planning/notes/2026-05-31-neo4j-graph-tools-comparison.md`
- Existing relationship heuristic this extends: AGENTS.md §11.3 step 5 (missing cross-references)
- Operation these feed: AGENTS.md §9 MERGE; reflect workflow §11.4 (decision record for consolidation)
- Scaling constraint for (d): AGENTS.md §14 Tier 4
- Privacy constraint for (d): AGENTS.md §13
- Connectivity-ranking already applied: `phases/13-claim-faithfulness-audit/13-DESIGN-NOTES.md` (FAITH-01 selector)
