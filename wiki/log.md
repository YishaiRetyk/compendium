---
id: log
title: Activity Log
type: overview
status: active
summary: "Chronological record of all wiki operations."
created_at: 2026-04-09
updated_at: 2026-04-10
sources: []
epistemic_status: sourced
tags:
  - meta
  - operations
domains: []
supersedes:
superseded_by:
privacy: cloud_safe
---

# Activity Log

## [2026-04-09] schema | Create page type templates

Created 5 page type templates in schema/templates/: entity.md, concept.md, source-summary.md, comparison.md, overview.md. Templates provide operational skeletons with frontmatter schema and progressive disclosure section ordering per AGENTS.md section 4.

## [2026-04-09] schema | Create example pages and populate navigation

Created 5 example pages: Daniel Kahneman (entity), Cognitive Biases (concept), Thinking Fast and Slow Part 1 (source summary), System 1 vs System 2 (comparison), Decision Making (overview). Pages form a connected graph cluster demonstrating cross-references, provenance chains, and epistemic markers. Populated index.md and log.md. Updated AGENTS.md section 6 with epistemic inline syntax documentation.

## [2026-04-10] ingest | Prospect Theory and Loss Aversion Article

Ingested synthetic magazine-style article (source_type: article) on Kahneman and Tversky's prospect theory research. First `article`-type ingest; validates the full AGENTS.md section 11.1 pipeline end-to-end with diff-driven merge targets. Created source summary page src-2026-04-10-kahneman-prospect-theory with 15 atomic claims. Diff pass identified the following page changes:

- UPDATED: wiki/entities/daniel-kahneman.md -- added two biographical key facts (career appointments at Hebrew U / UBC / Berkeley / Princeton; prospect theory published in Econometrica 1979), re-synthesized TL;DR to foreground prospect theory alongside Thinking Fast and Slow, wove publication venue/year into the Detail narrative.
- UPDATED: wiki/concepts/cognitive-biases.md -- added endowment effect, status quo bias, and disposition effect as a distinct family of biases explained downstream of loss aversion rather than by heuristic shortcuts. Re-synthesized TL;DR to distinguish the two origin families. New Detail paragraph contrasts the heuristic-origin biases with the loss-aversion-origin family.
- UPDATED: wiki/comparisons/system-1-vs-system-2.md -- added the novel claim that loss-aversion flinches are a System 1 response that explains why expert knowledge of prospect theory does not train loss aversion away. Extended TL;DR and Bottom Line to mention this dual-process link.
- UPDATED: wiki/overviews/decision-making.md -- added the 90% survival vs 10% mortality framing example, added explicit nudge-theory lineage to prospect theory, and extended the Detail section with the mechanism (reference dependence + loss aversion as footholds for structural interventions).
- CREATED: wiki/concepts/prospect-theory.md -- dedicated concept page. Rationale: the source contains three independent core claims (reference dependence, diminishing sensitivity with the concave-convex-steeper value function, inverted-S probability weighting) plus Econometrica 1979 venue. None of these fit naturally into cognitive-biases.md (which catalogs biases, not unified theories) or daniel-kahneman.md (which is a biography). Creating the page also resolves the pre-existing [[Prospect Theory]] red links on multiple pages.
- CREATED: wiki/concepts/loss-aversion.md -- dedicated concept page. Rationale: loss aversion has a specific empirical signature (coefficient 1.5-2.5, midpoint 2.0) and anchors a coherent family of downstream biases (endowment effect, status quo bias, disposition effect) that deserve a single home rather than being scattered across cognitive-biases.md. The dual-process connection (loss aversion as a System 1 reflex) also fits more cleanly on a dedicated page.

All updates follow the append-then-synthesize policy: claims appended to detail sections, TL;DR and Key Facts re-synthesized, no existing provenance markers removed. All new wikilinks resolve (including the two new concept pages). Source summary contains 15 atomic-granularity provenance markers referencing labeled sections in the source article.
