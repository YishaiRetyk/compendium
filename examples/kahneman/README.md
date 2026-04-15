---
id: kahneman-readme
title: "Kahneman Reference Cluster"
type: overview
status: active
summary: "Preserved reference example demonstrating the full wiki schema surface end-to-end."
created_at: 2026-04-15
updated_at: 2026-04-15
sources: []
epistemic_status: sourced
tags:
  - meta
  - example
domains:
  - wiki-infrastructure
privacy: cloud_safe
knowledge_domain: software
example: true
---

# Kahneman Reference Cluster

This directory preserves a complete, internally consistent example of the wiki's full feature surface applied to a single domain (Daniel Kahneman's work on judgment and decision-making). It is **reference material only** — it is not part of the active wiki and is skipped by `bin/lint.sh`.

## What this cluster demonstrates

- **Ingest:** Two source summaries (`sources/src-2026-04-09-thinking-fast-and-slow-part1.md`, `sources/src-2026-04-10-kahneman-prospect-theory.md`) produced via the AGENTS.md §11 ingest pipeline.
- **Synthesis:** Overview (`overviews/decision-making.md`) that synthesizes claims across multiple concept and entity pages.
- **Cross-linking:** Wikilinks between entities, concepts, comparisons, sources, and overviews produce a connected graph.
- **Provenance:** Atomic- and paragraph-level `[prov:...]` markers on claims, with support types and `checked_at` where applicable.
- **Contradiction handling:** `cognitive-biases.md` distinguishes heuristic-origin vs loss-aversion-origin bias families — two compatible framings coexisting under a single overview.

## Why it is preserved

Agents and readers benefit from a concrete, filled instance of the schema. An empty starter vault describes the shape of the system; this cluster shows the shape filled in with real content. Keeping it as a reference example (not as starter content in `wiki/`) lets a new user clone the template with an empty vault and still consult a worked example when authoring their first pages.

## How to read it

Start at `entities/daniel-kahneman.md` and walk outward:

1. `entities/daniel-kahneman.md` — the person who anchors the cluster.
2. `concepts/prospect-theory.md` and `concepts/loss-aversion.md` — the two core theoretical contributions.
3. `concepts/cognitive-biases.md` — the broader family of biases, organized by origin.
4. `comparisons/system-1-vs-system-2.md` — the dual-process framework contrast.
5. `overviews/decision-making.md` — the synthesis page tying it together.
6. `sources/src-2026-04-09-...` and `sources/src-2026-04-10-...` — the source summaries that supplied the claims.

## Which AGENTS.md sections it illustrates

- **§2 Directory Structure** — entities/, concepts/, comparisons/, overviews/, sources/ all present.
- **§4 Page Type Templates** — entity, concept, comparison, overview, source-summary all represented.
- **§5 Frontmatter Schema** — base fields + type-specific fields on every page.
- **§6 Epistemic Status and Provenance** — inline `[epistemic::...]` markers and `[prov:...]` markers throughout.
- **§11 Operational Workflows** — the log entries (see `log.md`) show ingest pipeline outcomes end-to-end.

## Do not edit — reference material

These files are frozen. Editing them would drift the example away from the canonical schema snapshot it is meant to preserve. If the schema changes, this cluster may be regenerated wholesale in a future phase, but local edits should not occur.
