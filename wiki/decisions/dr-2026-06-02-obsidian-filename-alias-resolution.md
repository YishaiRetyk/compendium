---
id: dr-2026-06-02-obsidian-filename-alias-resolution
title: "Obsidian Filename + Alias Resolution: Self-Alias Invariant"
type: decision
status: active
summary: "Corrects AGENTS.md §8 to state Obsidian resolves wikilinks by filename stem + aliases (not title); mandates self-alias invariant; adds bin/lint.sh linkres enforcement."
created_at: 2026-06-02
updated_at: 2026-06-02
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
aliases:
  - "Obsidian Filename + Alias Resolution: Self-Alias Invariant"
  - dr-2026-06-02-obsidian-filename-alias-resolution
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

Obsidian resolves `[[X]]` by filename stem + `aliases` frontmatter field, NEVER by the `title` field. The wiki spec falsely claimed otherwise; this decision corrects §8 + §5 checklist, mandates that every page include its title and id slug in `aliases` (the self-alias invariant), updates all 12 schema templates, and adds a `linkres` lint category to catch violations going forward.

## Decision

Five changes are adopted:

1. **AGENTS.md §8** now states the real Obsidian resolution mechanism: `[[X]]` resolves by filename stem + `aliases` entry, never by the `title` frontmatter field. Rule 4's misleading sentence is replaced; new rule 4a mandates the self-alias invariant.
2. **Self-alias invariant adopted**: every page's `aliases` MUST include its `title` and `id` slug as literal entries (`aliases ⊇ {title, id}`). This is the LINK-02 requirement.
3. **§5 checklist items 18--19** enforce the invariant at page-authoring time: item 18 requires `title` as a literal `aliases` member; item 19 requires `id` slug as a literal `aliases` member.
4. **`bin/lint.sh` gains a `linkres` category** (CI-gating, error severity in the `--ci` remap) enforced in Wave 1 (Plan 02) to prevent regression. `--fix` backfills both entries automatically.
5. **All `wiki/` and `examples/` pages** receive self-alias backfill in Wave 2 (Plan 03), making the graph connect in Obsidian.

## Why

The root cause: Obsidian's `title` frontmatter field is display metadata -- it does not participate in link resolution. Obsidian's link resolver uses (1) the filename stem and (2) the `aliases` frontmatter list. Pages named `domain-driven-design.md` with `title: "Domain-Driven Design"` and empty `aliases` are unreachable via `[[Domain-Driven Design]]` -- Obsidian renders these as unresolved red links even though a page with that title exists.

This caused 31 of 49 wiki pages to appear as graph orphans in Obsidian's graph view, silently breaking the "Obsidian-first" promise of the wiki system. The pages had 11 inbound + 7 outbound wikilinks each (from other wiki pages) that were rendering disconnected.

The framing adopted: **filename + aliases is the ground truth for Obsidian resolution; title is display metadata; self-aliases are the invariant that bridges the two**. Adding the title and id slug to `aliases` costs nothing and makes `[[Title]]` and `[[slug]]` both resolve deterministically.

The framing replaced: "Obsidian resolves aliases to the canonical page automatically" (the prior rule 4 text), which implied title-based resolution and left authors unaware that their `[[Title]]` wikilinks would render as red links.

## Alternatives Considered

1. **Rename wiki files to spaced titles** (e.g., `Domain-Driven Design.md`) -- rejected because it breaks the `id == filename` invariant (§5), provenance source IDs, and all tooling that relies on slug filenames. Every `[prov:domain-driven-design#...]` marker would need updating, and the `id: domain-driven-design` frontmatter field would diverge from the filename.

2. **Rewrite body links to slug form** (e.g., `[[domain-driven-design]]`) -- rejected because it abandons the readable `[[Exact Page Title]]` linking convention (§8) and makes prose harder to read. The link text would be slug-like identifiers rather than human-readable titles.

3. **Accept orphans as a known limitation** -- rejected because graph connectivity is the core value of the wiki's cross-reference layer; accepting 31/49 disconnected pages defeats the purpose of the Obsidian-first architecture. The wiki would be internally consistent in its markdown but visually broken in its primary browsing interface.

## Consequences

- `linkres` lint category (severity `error` in `--ci` remap, via `bin/lint.sh --category linkres`) prevents the same breakage from recurring on any future page. `--fix` backfills missing self-aliases automatically.
- All 12 schema templates now ship self-alias guidance, so new pages are correctly configured by default (6 `schema/templates/` files get the comment block; 6 `schema/obsidian/` files get `aliases: - {{title}}` seeding the title alias at page-creation time).
- 45 wiki/ pages + 8 lint-visible examples/ pages receive self-alias backfill in Wave 2 (mechanically via `--fix`). The 10 `examples/dataview-fixtures/` content pages are `example: true` (lint-skipped by `--fix`) but are still remediated by hand in Wave 2 (LINK-09: lint-skip means NOT-LINT-ENFORCED, not NOT-REMEDIATED). Only the 2 scaffolding files in `examples/kahneman/` (`README.md` + `log.md`) are remediation-exempt.
- `bin/lint.sh --category linkres` exits 0 over `wiki/` after Wave 2 remediation, confirming the graph connectivity defect is fully resolved.

## Affected Pages

None. This is an infrastructure-only schema correction targeting AGENTS.md, CLAUDE.md, and schema templates. No existing wiki topic page has its structure changed by this decision. The self-alias backfill in Wave 2 (Plan 03) is a data-level additive change (aliases added, nothing removed or restructured).

## Sources

None. Internal schema decision based on direct inspection of Obsidian's link-resolution behavior and enumeration of 31 orphaned wiki pages.
