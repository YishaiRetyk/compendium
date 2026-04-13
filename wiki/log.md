---
id: log
title: Activity Log
type: overview
status: active
summary: "Chronological record of all wiki operations."
created_at: 2026-04-09
updated_at: 2026-04-12
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

## [2026-04-10] ingest | Personal Decision Journal

Ingested personal journal entry on applying cognitive frameworks to everyday decisions. First `journal entry` source type ingested; validates that the pipeline handles paragraph-level extraction granularity distinct from the article ingest's atomic-claim granularity, and that privacy routing is enforced during merge target selection.

- CREATED: wiki/sources/src-2026-04-10-personal-decision-journal.md -- source summary page. privacy: local_only. source_type: journal entry. Contains 7 paragraph-level provenance clusters (one per labeled `## para:N` section in the source file), not atomic claims. This is deliberately coarser than the Plan 03 article ingest (20 atomic markers) and follows the AGENTS.md section 10 Pass 2 journal-entry granularity rule.
- CREATED: wiki/overviews/personal-decision-patterns.md -- new overview page. privacy: local_only. Rationale: the journal's experiential claims (salary-anchoring-as-politeness observation, "explain the want" heuristic, sunk-cost pre-mortem self-diagnosis, personal decision-fatigue threshold, committed action items, the "flinch is the tell" meta-observation) are genuine novel content but are PERSONAL and must be local_only. Merging them into the cloud_safe wiki/overviews/decision-making.md would have contaminated that page's privacy tier for the whole vault. The safer and correct option (Codex review HIGH-severity concern, option a) is a dedicated local_only page.
- UPDATED: wiki/overviews/decision-making.md -- LINK ONLY. The page's privacy field remains cloud_safe. No provenance markers pointing at the journal source were added. The journal source is NOT listed in this page's `sources:` frontmatter. The only content change is a single wikilink `- [[personal-decision-patterns]] -- personal experiential patterns (local_only)` appended in the Related Pages section, plus an `updated_at` date bump. All pre-existing provenance markers on this page are preserved.
- UPDATED: wiki/index.md -- added source entry and new overview entry, both flagged **local_only** so index readers can see at a glance that they are private.
- UPDATED: wiki/log.md -- this entry.

Privacy separation verification: grepping the wiki for provenance markers pointing at the journal source returns only the source summary page and personal-decision-patterns.md. No cloud_safe page carries a provenance marker or frontmatter reference to the journal source. decision-making.md remains privacy: cloud_safe.

Granularity comparison: journal entry = 7 paragraph-level clusters; Plan 03 article ingest = 20 atomic claims. This confirms the source-type-driven granularity difference.

## [2026-04-12] query | How does prospect theory explain irrational financial decisions?

answer: Prospect theory explains irrational financial decisions through three mechanisms: reference dependence (evaluating outcomes relative to a status quo rather than absolute value), loss aversion (losses hurt ~2x more than equivalent gains), and probability distortion (overweighting small probabilities, underweighting large ones). These produce predictable irrationalities like the disposition effect (selling winners too early, holding losers too long) and status quo bias in investment portfolios.
write_back: NO-WRITE-BACK: reformulated restatement of existing prospect-theory.md and loss-aversion.md pages -- no novel claims or connections produced
delta_compiled: none (all referenced sources have compilation_status: compiled)
pages_affected: none

## [2026-04-12] query | Compare heuristic-origin vs loss-aversion-origin cognitive biases

answer: The wiki's cognitive-biases page already distinguishes two bias families: (1) heuristic-origin biases (anchoring, availability, representativeness) arising from System 1's reliance on mental shortcuts, and (2) loss-aversion-origin biases (endowment effect, status quo bias, disposition effect) explained downstream of prospect theory's asymmetric value function rather than by heuristic shortcuts.
write_back: NO-WRITE-BACK: the heuristic-origin vs loss-aversion-origin categorization is already explicitly stated in cognitive-biases.md TL;DR and Detail sections -- no novel synthesis produced
delta_compiled: none (all referenced sources have compilation_status: compiled)
pages_affected: none

## [2026-04-12] query | What personal decision patterns have I recorded?

answer: The wiki records personal decision patterns in the local_only page personal-decision-patterns.md, sourced from a personal journal entry. Key patterns: (1) frameworks work by training the ability to notice a pre-decision physical "flinch," not by improving after-the-fact reasoning, (2) salary anchoring used as a politeness mechanism, (3) an "explain the want" heuristic, (4) sunk-cost pre-mortem self-diagnosis, (5) personal decision-fatigue threshold awareness, and (6) committed action items for practice.
write_back: NO-WRITE-BACK: pure lookup of existing local_only content in personal-decision-patterns.md -- no novel synthesis. Note: all contributing sources (src-2026-04-10-personal-decision-journal) are privacy: local_only; any write-back would require local_only target per Section 13 inheritance rule.
delta_compiled: none (src-2026-04-10-personal-decision-journal has compilation_status: compiled)
pages_affected: none

## [2026-04-13] lint | wiki health check

findings: 0 total (0 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki/maintenance/lint-report.md

## [2026-04-13] lint | wiki health check

findings: 4 total (0 errors, 2 warnings, 2 info)
auto_fixes: 0 applied
report: wiki/maintenance/lint-report.md

## [2026-04-13] lint | wiki health check

findings: 4 total (0 errors, 2 warnings, 2 info)
auto_fixes: 0 applied
report: wiki/maintenance/lint-report.md

## [2026-04-13] lint | wiki health check

findings: 4 total (0 errors, 2 warnings, 2 info)
auto_fixes: 0 applied
report: wiki/maintenance/lint-report.md
