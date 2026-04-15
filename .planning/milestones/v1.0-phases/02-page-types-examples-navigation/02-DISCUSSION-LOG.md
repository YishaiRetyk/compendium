# Phase 2: Page Types, Examples & Navigation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-09
**Phase:** 02-page-types-examples-navigation
**Areas discussed:** Example page topics, Epistemic inline syntax, Index strategy, Template design

---

## Example Page Topics

| Option | Description | Selected |
|--------|-------------|----------|
| Your actual interests | Personal knowledge topics (psychology, health, etc.) | |
| Famous thinkers/ideas | Well-known figures and concepts (Kahneman, cognitive biases) | ✓ |
| Minimal placeholders | Bare minimum content, focus on structure | |

**User's choice:** Famous thinkers/ideas
**Notes:** Easy to verify correctness, no privacy concerns, replaceable when real sources ingested in Phase 3. Specific topics: Kahneman (entity), Cognitive Biases (concept), Thinking Fast and Slow chapter (source), System 1 vs 2 (comparison), Decision Making (overview). User asked about purpose of example pages before deciding — chose based on verifiability and replaceability.

---

## Epistemic Inline Syntax

| Option | Description | Selected |
|--------|-------------|----------|
| Dataview inline fields | `[epistemic:: sourced]` — queryable, Obsidian-native | ✓ |
| Parenthetical markers | `(sourced)` — plain text, not queryable | |
| Frontmatter only | Page-level only, no inline (violates EPST-02) | |

**User's choice:** Dataview inline fields with explicit mixed grammar design
**Notes:** User brought advisor input recommending Dataview for epistemic (queryable, feeds into lint) but keeping custom `[prov:...]` for provenance (portable, compact). Mixed grammar must be documented in AGENTS.md section 6 as intentional. Pattern: `Claim. [prov:source#loc|type] [epistemic:: status]`

---

## Index Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Dataview queries | Auto-populated from wiki/ subdirectories | |
| Manual curated list | Agent maintains entries during ingest | ✓ |
| Hybrid | Dataview + manual pinned section | |

**User's choice:** Manual curated list
**Notes:** User challenged the Dataview recommendation — fully generated indexes are "comprehensive but usually too noisy and low-signal." Manual curation is higher signal, more navigable, better for LLM query workflow. User added: pair with lint checks for index drift rather than relying only on workflow discipline. Claude agreed and revised recommendation.

---

## Template Design

| Option | Description | Selected |
|--------|-------------|----------|
| Skeleton with comments | Minimal structure, placeholder frontmatter, brief constraint comments | ✓ (layer 1) |
| Filled-in example defaults | Pre-filled with realistic content | |
| Bare minimum | Just headings and frontmatter, no comments | |

**User's choice:** Two-layer pattern (user-proposed)
**Notes:** User proposed separating templates (skeleton+comments for copying) from exemplars (fully filled examples for reference). The example pages in wiki/ serve as the companion exemplars — no extra files needed. Agent workflow: read AGENTS.md → copy template → consult example page for style/density → fill in.

---

## Claude's Discretion

- Log entry exact format details (parseable, ISO timestamps, operation types)
- Exact example page content (specific claims and facts)
- Template comment wording
- AGENTS.md section 6 update approach for mixed grammar documentation

## Deferred Ideas

None — discussion stayed within phase scope
