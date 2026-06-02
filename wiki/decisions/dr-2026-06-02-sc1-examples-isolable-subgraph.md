---
id: dr-2026-06-02-sc1-examples-isolable-subgraph
title: "SC1 Reframing: examples/ Forms a Visually Isolable Sub-Graph"
type: decision
status: active
summary: "Phase 13.1 SC1 is renegotiated from 'graph not contaminated by examples/' to 'examples/ forms a visually isolable sub-graph,' because Obsidian's single Excluded-files mechanism cannot both keep the fixtures Dataview-indexed and hide them from the graph without mutating the committed .obsidian/."
created_at: 2026-06-02
updated_at: 2026-06-02
sources: []
epistemic_status: sourced
tags:
  - obsidian
  - graph
  - dataview
  - verification
  - meta
domains:
  - wiki-infrastructure
supersedes:
superseded_by:
privacy: cloud_safe
aliases: []
has_contradictions: false
knowledge_domain: software
trigger_type: reframing
affected_pages: []
---

<!-- FORBIDDEN PATTERNS (see AGENTS.md section 3):
     - No wikilinks in frontmatter (use plain string IDs in sources[], affected_pages[], supersedes, etc.)
     - No display aliases: write [[Page Title]] not [[Page Title|Alias]]
     - Link each page only on first mention in the body -->

## TL;DR

Phase 13.1's first success criterion (SC1) originally read "graph view is not contaminated by `examples/`." That literal outcome is not deliverable: Obsidian exposes a SINGLE exclusion mechanism (Settings → Files & Links → Excluded files, persisted as `userIgnoreFilters` in `.obsidian/app.json`), and that one switch governs BOTH Dataview indexing AND graph membership. The render verification (DEBT-01) requires the `examples/dataview-fixtures/` set to stay indexed so the five canonical Dataview queries return their expected row counts — which means the same fixtures necessarily appear in the graph. SC1 is therefore reframed to "`examples/` forms a VISUALLY ISOLABLE sub-graph": the reference cluster renders as a disconnected/isolable component rather than entangling the active wiki graph, instead of being absent from the graph entirely.

## Decision

Adopt the reframed SC1: the goal is a **visually isolable** `examples/` sub-graph, not an absent one.

- The `examples/dataview-fixtures/` set MUST remain Dataview-indexed during render verification (DEBT-01) so the five canonical fixture-scoped queries reproduce their documented counts. Excluding `examples/` to hide it from the graph would zero out those queries and defeat the verification.
- Acceptable outcomes for the SC1 graph sub-check are: (a) confirming the `examples/` pages render as a disconnected/isolable component of the graph while staying indexed; or (b) performing a one-time, graph-only Excluded-files pass purely to eyeball isolation, then REMOVING it so Dataview re-indexes the fixtures before the counts are read.
- The committed `.obsidian/` directory is NOT mutated to encode a permanent exclusion (per the Phase 13.2 D-03 no-`.obsidian/`-mutation rule); `.obsidian/app.json` stays `{}` so the fixtures index by default.

## Why

The framing adopted is "`examples/` forms a VISUALLY ISOLABLE sub-graph." The framing it replaces is "graph not contaminated by `examples/`" — i.e. the reference cluster absent from the graph entirely. The replacement is forced by a tool constraint, not a preference: Obsidian's Excluded-files setting is the only lever, and it is shared between the Dataview index and the graph. You cannot keep the fixtures indexed (required for the render-count verification) AND simultaneously hide them from the graph through any per-surface switch. Given that, "absent from the graph" and "indexed for Dataview" are mutually exclusive under the no-`.obsidian/`-mutation constraint, so the honest, deliverable criterion is isolability (a disconnected component) rather than absence. Recording the reframing as a decision record keeps the renegotiation auditable instead of silently relaxing a shipped success criterion.

## Alternatives Considered

- **Mutate the committed `.obsidian/` to add `examples/` to `userIgnoreFilters`.** Rejected per the Phase 13.2 D-03 no-`.obsidian/`-mutation rule. A persisted exclusion would hide the fixtures from the graph but would ALSO drop them from the Dataview index, breaking the DEBT-01 render verification (the five queries would return 0 rows). It also bakes a personal display preference into a template-public file. The single shared mechanism makes "hide from graph but keep indexed" impossible by configuration.
- **Keep SC1 literal and mark it permanently unmet (or blocked).** Rejected as misleading: the criterion as written is not achievable by ANY Phase 13.1/13.2 plan under the tool constraint, so leaving it as an open failure would imply a fixable gap that does not exist. Reframing to the achievable, equally-rigorous "isolable sub-graph" states the real, verifiable bar.
- **Drop the graph sub-check from SC1 entirely.** Rejected because graph hygiene is a genuine quality signal — a reference cluster that entangles the active wiki graph would be a real defect. Isolability preserves that check in a form the tool can actually satisfy.

## Consequences

- The DEBT-01 render verification reads the five Dataview counts with `examples/` INDEXED (the default `.obsidian/app.json` `{}` state); the graph isolation check is a separate visual confirmation, optionally via a reverted graph-only Excluded-files pass.
- Future render verifications inherit the isolable-sub-graph bar; no plan should re-assert the literal "absent from graph" criterion without first superseding this record.
- No `.obsidian/` file is committed or mutated to encode an exclusion; the template ships with the fixtures indexable by default so adopters reproduce the documented counts on first open.
- No new wiki page types, directories, or schema fields are introduced. This is a verification-criterion reframing only.

## Affected Pages

None. This is an infrastructure-only reframing decision record (`affected_pages: []`); no pre-existing wiki page is restructured by renegotiating the Phase 13.1 graph success criterion. The reframing is consumed by the Phase 13.1 render-verification record and the Phase 13.2 closure gate, both in `.planning/`.

## Sources

- [.planning/phases/13.1-docs-finalization-obsidian-starter/13.1-VERIFICATION.md](../../.planning/phases/13.1-docs-finalization-obsidian-starter/13.1-VERIFICATION.md) — DEBT-01 render checklist + SC1 graph sub-check (the renegotiation flagged as a Phase 13.2 follow-up).
- [docs/reference/examples.md](../../docs/reference/examples.md) — `examples/dataview-fixtures/` inventory + the five canonical Dataview queries with expected counts, and the corrected Excluded-files / `.obsidianignore` behavior.
- [.planning/ROADMAP.md](../../.planning/ROADMAP.md) — Phase 13.1 success criteria (SC1) and Phase 13.2 closure gate.
