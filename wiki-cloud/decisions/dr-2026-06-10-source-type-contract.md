---
id: dr-2026-06-10-source-type-contract
title: "Source-Type Extension Contract + research-report Secondary Source Type"
type: decision
status: active
summary: "Formalizes the 5-dimension source-type extension contract in schema/reference/source-types.md and adds source_type: research-report as the first worked secondary instance, with derived-only provenance, citation registries, and lint enforcement against epistemic laundering."
created_at: 2026-06-10
updated_at: 2026-06-10
sources: []
epistemic_status: sourced
tags:
  - meta
  - schema
domains:
  - wiki-infrastructure
supersedes: null
superseded_by: null
aliases:
  - dr-2026-06-10-source-type-contract
has_contradictions: false
knowledge_domain: software
trigger_type: schema-update
affected_pages: []
---

# Source-Type Extension Contract + research-report Secondary Source Type

## TL;DR

Phase 19 adds the 5-dimension source-type extension contract (`schema/reference/source-types.md`) and `source_type: research-report` as the first secondary-source type, enforcing `derived`-only provenance to prevent epistemic laundering from AI-synthesized reports.

## Decision

Phase 19 introduced two coupled deliverables:

**1. The source-type extension contract (`schema/reference/source-types.md`)**

A new authoritative reference file formalizing the 5-dimension recipe for evaluating and adding source types:

- **Acquisition** — how the source enters the vault
- **Locator** — how claims within the source are addressed
- **Extraction granularity** — how atomic claims are scoped during ingest
- **Drift / staleness** — how to detect when the source has aged out
- **Epistemic default** — what epistemic_status to assign freshly ingested pages

The file introduces the primary/secondary axis: primary sources are first-hand records (`direct` support type), secondary sources are syntheses of other sources (`derived` support type). The decision rule: a new `source_type` is justified only if it changes at least one of the 5 dimensions; otherwise it is a sub-case of an existing type.

The contract includes a retro-fit table mapping all seven types (the existing six plus `research-report`) across the 5 dimensions, an "Evaluated candidates" sub-case registry (PDF verdict: article sub-case; video: transcript sub-case), and routing-table registration in AGENTS.md/CLAUDE.md.

**2. The `research-report` type (RPT-01 through RPT-06)**

Fully implemented as the contract's worked secondary instance:

- **RPT-01:** `source_type: research-report` added to the frontmatter enum in `schema/reference/frontmatter.md`
- **RPT-02:** Citation registry convention: a body `## References` block with `r<n>::` keyed entries (URL, title, access date, promotion status) — no new frontmatter field
- **RPT-03:** `derived`-only provenance enforced by lint D-08: `[prov:<report>#...|direct|...]` on a research-report source is an error
- **RPT-04:** `bin/audit-claims.sh` gains a 5th priority selector (`derived-report`) and `#r<n>` locator resolver for positional bibliography lookup
- **RPT-05:** Model C promotion path: when a cited source earns promotion, the human acquires it; the earning claim is re-pointed from `derived` to `direct`; the registry entry is marked `promoted → <new-source-id>`
- **RPT-06:** Retro-classification of the two existing AI deep-research reports: `source_type: article` → `research-report`; citation registries backfilled; no new claims extracted (D-14)

**3. Lint enforcement (D-08/D-09)**

LINT_VERSION bumped 1.8.0 → 1.9.0. Two new checks:

- **D-08:** Error if any wiki page outside `wiki-cloud/sources/` cites a `research-report` source with `|direct|` support type (anti-laundering gate)
- **D-09:** Error if `source_type` has an unknown value (closes the typo-bypass hole)

**4. Claims sweep**

All 103 `|direct|` markers across 14 dependent wiki pages (entities, concepts, comparisons, overviews) citing the two research-report sources were rewritten to `|derived|`. Source summary self-citations are excluded (they correctly remain `|direct|` — a source summary cites its own raw source).

## Why

The epistemic-laundering threat: AI deep-research reports (Claude, ChatGPT, Perplexity) synthesize and paraphrase primary sources. If their claims are ingested as `direct`-sourced, the wiki acquires false confidence — a claim that traces back to a secondary synthesis is presented with the same epistemic weight as a claim from a peer-reviewed paper or firsthand observation.

The mechanical defense is three-layered:

1. **`derived` support type** — claims from research-report sources carry `|derived|` in their provenance markers, making the secondary-source nature explicit and queryable
2. **Lower epistemic default** — `research-report` pages default to `mixed` (not `sourced`) as the page-level `epistemic_status`, propagating the uncertainty to dependent pages
3. **Lint enforcement** — D-08 makes a direct-on-research-report marker a hard error; a typo-proof validator (D-09) prevents `research_report` (underscore) from bypassing the check
4. **Citation registry** — `## References` with `r<n>::` entries provides a promotion path: individual citations can be independently verified and promoted to primary-sourced claims, converting the secondary synthesis into a traceable set of first-hand sources over time

The design lineage is `.planning/seeds/research-report-ingest.md` (LOCKED): "separate *performing* research from *ingesting* a research artifact." The report enters the vault as a source summary; its internal citations form a bibliography waiting to be promoted.

## Alternatives Considered

**Model A: Report-as-source, no citation registry.** Treat research reports as opaque article-type sources, ingest their claims verbatim with `direct` markers. Rejected: too opaque; no path to promote the underlying citations; epistemic laundering risk is unchecked.

**Model B: Citations-as-sources (auto-promotion).** Automatically extract and ingest each cited source from the bibliography. Rejected: over-engineered; citation-level sources often require separate acquisition (paywalls, PDFs, transcripts); many secondary references are paraphrase-only with no retrievable full text. Model B was explicitly deferred as "likely out of scope even when this seed promotes" in the seed design.

**Model C (hybrid — chosen):** Ingest the report as a secondary source with `derived` markers; capture the bibliography as a `## References` registry with positional `r<n>` keys; promote individual citations on demand when a load-bearing claim needs primary sourcing. The registry is a cheap first pass; promotion is triggered by use, not predicted in advance.

## Consequences

- `bin/lint.sh` LINT_VERSION bumped to 1.9.0; D-08 and D-09 checks are now CI-enforced
- All report-citing `|direct|` markers in 14 wiki pages changed to `|derived|`; `vlm-ocr-hallucination.md` re-graded to `mixed` (its primary-sourced claims were outweighed by derived ones after the sweep)
- `schema/reference/source-types.md` is the new evaluation contract for Phases 20 (PDF) and 21 (video ingestion)
- Citation registries are the natural future trigger for 999.5 External Source Drift detection (explicitly deferred from v1.3)
- `bin/audit-claims.sh` gains a 5th selector (`derived-report`, rank 5) for targeted faithfulness audits of secondary-source claims

## Affected Pages

None. This is an infrastructure decision record (cf. `dr-2026-06-08-skills-overlay.md`, `affected_pages: []`). The `wiki-cloud/index.md` Decisions-section entry is a catalog registration, not a content page that gained a `decision_history` backlink. D-14 explicitly makes the retro-classification a schema change, not a content migration.

## Sources

- `schema/reference/source-types.md` — the 5-dimension extension contract document
- `.planning/seeds/research-report-ingest.md` — design lineage (LOCKED): Model C hybrid provenance, ingest mechanics, epistemic-laundering threat model
