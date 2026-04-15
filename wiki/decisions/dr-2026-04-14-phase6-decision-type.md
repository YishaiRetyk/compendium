---
id: dr-2026-04-14-phase6-decision-type
title: "Introduce Decision Record Page Type"
type: decision
status: active
summary: "Decision records are a dedicated page type (type: decision) with their own template, directory (wiki/decisions/), and index category, rather than overloading the overview type."
created_at: 2026-04-14
updated_at: 2026-04-14
sources: []
epistemic_status: sourced
tags:
  - meta
  - schema
domains:
  - wiki-infrastructure
supersedes:
superseded_by:
privacy: cloud_safe
aliases: []
has_contradictions: false
knowledge_domain: software
trigger_type: schema-update
affected_pages: []
---

<!-- FORBIDDEN PATTERNS (see AGENTS.md section 3):
     - No wikilinks in frontmatter (use plain string IDs in sources[], affected_pages[], supersedes, etc.)
     - No display aliases: write [[Page Title]] not [[Page Title|Alias]]
     - Link each page only on first mention in the body -->

## TL;DR

Decision records get a dedicated `type: decision` page type with their own template, directory, and index category, replacing the prior convention of storing them as overview pages.

## Decision

Created `wiki/decisions/` as a first-class content directory, `schema/templates/decision.md` as the canonical template, and added `decision` to the `type` enum in AGENTS.md section 5. Decision records use a fixed section ordering (TL;DR, Decision, Why, Alternatives Considered, Consequences, Affected Pages, Sources) and introduce two type-specific frontmatter fields: `trigger_type` (enum over merge, split, schema-update, domain-reorg, reframing, contradiction-resolution) and `affected_pages` (YAML list of page IDs). A new optional back-link field, `decision_history`, is defined for any page that is referenced by a decision record.

## Why

The previous reflect workflow (AGENTS.md section 11.4) stored decision records as overview pages in `wiki/overviews/`. This conflated structural reasoning (why the wiki is shaped the way it is) with topic synthesis (what a body of knowledge says). A dedicated page type separates these concerns and enables targeted Dataview queries (`type = "decision"`), clearer navigation in `wiki/index.md`, and machine-parseable audit trails via the `trigger_type` and `affected_pages` fields. The framing adopted is "decision records as a first-class page type" -- a structural peer of entity, concept, source, comparison, and overview. The framing it replaced is "decision records overloaded onto the overview type" -- a convention that hid decisions among topic syntheses and denied them type-specific validation.

## Alternatives Considered

- **Keep using the overview type with a tag (e.g., `tags: [decision]`):** Rejected because tags are ad hoc and cannot enforce type-specific sections, required fields (`trigger_type`, `affected_pages`), or directory placement. Lint validation would have no clean hook to apply decision-specific checks.
- **Store decisions as a flat markdown file outside `wiki/` (e.g., `DECISIONS.md` at repo root):** Rejected because it breaks Obsidian graph navigation, Dataview queries, and the uniform "every structural artifact is a wiki page" model that the rest of the schema depends on.
- **Embed decisions inline in `wiki/log.md`:** Rejected because decisions need structured sections (Why, Alternatives, Consequences) and bidirectional links to affected pages; the log is append-only, chronological, and not designed for multi-section records. Per AGENTS.md section 12, the log records WHAT happened; decision records explain WHY.

## Consequences

- All six trigger types (`merge`, `split`, `schema-update`, `domain-reorg`, `reframing`, `contradiction-resolution`) produce decision records in `wiki/decisions/` going forward.
- Existing overview pages are NOT retroactively converted -- this is a forward-only change.
- Pages referenced in an `affected_pages` list gain a `decision_history` field in their frontmatter (optional, added on first reference), enabling bidirectional navigation between decisions and the pages they reshape.
- Lint validation (Plan 02 of this phase) gains decision-specific checks: `trigger_type` enum validation, `affected_pages` type validation, and `decision_history` type validation where present.
- The reflect workflow (Plan 03 of this phase) writes decision records into `wiki/decisions/` using this template and updates `wiki/index.md` under the new Decisions category.
- The `wiki/index.md` Decisions category becomes a stable navigation surface for browsing the structural history of the wiki.

## Affected Pages

None. This is the inaugural decision record; no pre-existing pages are restructured by introducing the page type itself.

## Sources

None. This is an internal schema decision; the decision record itself is the source of truth.
