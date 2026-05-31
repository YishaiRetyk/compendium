---
title: "LLM-drafted domain scaffold for the greenfield wizard (deferred)"
trigger_condition: "v1.1 closes AND onboarding friction is observed — new adopters struggle to choose domains/tags vocabulary or knowledge_domain decay buckets from a blank AGENTS.md, OR the wizard track gets a post-v1.1 revisit"
planted_date: 2026-05-31
milestone_hint: v1.2+
---

# LLM-drafted domain scaffold for the greenfield wizard (deferred)

## What

Enhance the greenfield setup track (`bin/init-wizard.sh` + `AGENTS.template.md`) with an optional "describe your domain in plain English → LLM drafts a starter knowledge scaffold" step, modeled on `neo4j-labs/create-context-graph`'s `custom_domain.py`.

Today the wizard prompts for a domain and fills template placeholders. The enhancement: given a plain-English description (e.g. "veterinary clinic management", "AI safety research notes"), an LLM proposes:
- a starter `domains` / `tags` vocabulary,
- `knowledge_domain` decay-bucket assignments (mapping the domain's topics to §6's software/science/biography/personal-goals/custom decay rates),
- optionally, a few candidate entity/concept page stubs to seed the empty wiki.

All **human-confirmed** before anything is written (compendium's ethos), and gated behind a **completeness-validation loop** (the create-context-graph pattern: retry on truncation / parse-failure / missing-required-sections, max N retries). "Describe it in English → LLM drafts the conventions," applied to compendium's frontmatter/taxonomy rather than a Neo4j schema.

Source analysis: `.planning/notes/2026-05-31-neo4j-graph-tools-comparison.md` (learning #7). This is net-new vs `llm-graph-builder` (which used pre-baked per-domain schemas).

## Why this is deferred

1. **Post-v1.1.** v1.1's two-track setup (wizard + manual, byte-identical end state) is the shipped onboarding contract; this is an additive enhancement, not part of "make the template shareable."
2. **Needs the wizard to be settled first.** Builds on `bin/init-wizard.sh` and `AGENTS.template.md` placeholders (Phase 8); should follow any post-v1.1 wizard revisit, not precede it.
3. **Privacy + dependency.** Calling an LLM from the wizard introduces a model dependency and a privacy decision (the domain description is user input — default-safe handling, §13 spirit). Worth a deliberate design pass, not a bolt-on.

## Revisit trigger

Surface when ANY becomes true:
- Observed onboarding friction: new adopters can't easily pick a domains/tags vocabulary or decay buckets from a blank spec.
- The wizard / manual-setup track gets a post-v1.1 revisit for other reasons.
- A "starter content" or "empty-vault is intimidating" complaint recurs.

## Out of scope at revisit time

- Auto-writing wiki pages without human confirmation (propose-then-confirm only).
- New page types or directory taxonomies (`dr-2026-05-01-complementary-systems-boundary.md`).
- Breaking wizard ↔ manual-track byte-equality (Phase 8 contract) — the manual track must still reach the same end state without the LLM step (the scaffold is an optional accelerator, the conventions remain hand-editable).
- Sending user domain descriptions to a cloud API without a privacy-aware default.

## Related artifacts

- Source analysis + file:line refs: `.planning/notes/2026-05-31-neo4j-graph-tools-comparison.md` (#7)
- Reference implementation: `neo4j-labs/create-context-graph` `src/create_context_graph/custom_domain.py` (3-retry completeness-validation loop)
- Wizard substrate: `bin/init-wizard.sh`, `schema/AGENTS.template.md` (Phase 8 two-track setup)
- Decay buckets to assign: AGENTS.md §6 domain decay-rate table; frontmatter `knowledge_domain` (§5)
- Related backlog: Phase 999.3 (Template Placeholder System for published surfaces) — adjacent wizard/template work
