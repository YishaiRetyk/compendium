---
id: dr-2026-06-03-uniform-piped-links
title: "Uniform Piped Links: Correcting the Obsidian Link Resolution Convention"
type: decision
status: active
summary: "Corrects CLAUDE.md/AGENTS.md §8 to state Obsidian resolves wikilinks by filename/path ONLY (never aliases); mandates the uniform piped-link form (id target, title display); removes the self-alias invariant; supersedes the wrong-premise dr-2026-06-02-obsidian-filename-alias-resolution."
created_at: 2026-06-03
updated_at: 2026-06-03
sources: []
epistemic_status: sourced
tags:
  - meta
  - schema
domains:
  - wiki-infrastructure
supersedes: dr-2026-06-02-obsidian-filename-alias-resolution
superseded_by:
privacy: cloud_safe
aliases:
  - "Uniform Piped Links: Correcting the Obsidian Link Resolution Convention"
  - dr-2026-06-03-uniform-piped-links
has_contradictions: false
knowledge_domain: software
trigger_type: schema-update
affected_pages:
  - dr-2026-06-02-obsidian-filename-alias-resolution
---

<!-- FORBIDDEN PATTERNS (see AGENTS.md section 3):
     - No wikilinks in frontmatter (use plain string IDs in sources[], affected_pages[], supersedes, etc.)
     - No bare `[[Title]]` links: ALWAYS write `[[id|Exact Title]]` (target=id, display=title)
     - Link each page only on first mention in the body
     - No example content in this template -- fill with real content when using -->

## TL;DR

Phase 14 (self-aliases) was built on the false premise that Obsidian resolves `[[X]]` by
filename stem + `aliases`. Confirmed false at v1.12.7 (intentional Obsidian design): resolution
is **filename/path ONLY**. The fix: adopt **uniform piped links** `[[id|Title]]` everywhere —
target = page `id` (= filename, always resolves), display = canonical `title`. §8 is inverted,
the self-alias invariant is removed, and `linkres` is re-pointed to enforce resolvable link targets.

## Decision

Adopt **uniform piped links** `[[id|Exact Title]]` as the mandatory intra-wiki link form:
- **Target** (before `|`): the page `id`, which equals the filename stem — always resolves in
  stock Obsidian because Obsidian resolves `[[X]]` by **filename/path ONLY**.
- **Display** (after `|`): the exact canonical `title` from the page's frontmatter.
- The convention is **unconditional** — every intra-wiki body link is piped, including
  single-word-title pages (e.g. `[[backpressure|Backpressure]]`).

`CLAUDE.md`/`AGENTS.md` §8 is rewritten to mandate this form and state the real resolution rule.
The self-alias invariant (`aliases ⊇ {title, id}`) is removed from §5 and §8 — `aliases` reverts
to an optional field for genuine alternate names (Quick Switcher / autocomplete), not for resolution.
`bin/lint.sh`'s `linkres` category is re-pointed to validate that every link target is a known page
`id` (bare `[[X]]` without a pipe is a `linkres` error).

## Why

The self-alias approach (Phase 14 plans 01/02/03) was invalidated at the LINK-10 human-verify gate:
after 53 self-aliases were added, the Obsidian graph still showed multi-word-title pages as orphans.
Decisive probe: clicking `[[Domain-Driven Design]]` in a linked page → unresolved (red). Quick
Switcher DID surface the alias — confirming aliases power autocomplete, not link resolution.

Obsidian moderator confirmation for v1.12.7: "not a bug… it's how it has always worked and it's an
intentional design decision." Source: forum.obsidian.md/t/wikilink-resolution-does-not-honor-frontmatter-aliases-1-12-7/113902

The piped-link approach was chosen because it:
1. Uses only the stable, documented filename/path mechanism — no undocumented API dependency.
2. Aligns with the existing `id == filename` invariant (§5).
3. Makes the §8 rule **unconditional** — agents never evaluate a per-link condition.
4. Makes `linkres` validation trivial: "is the target before `|` a known page `id`?" — exact match.
5. Dissolves the variant problem (plural/parens/casing live in cosmetic display text, not the target).
6. The rewrite cost (paid once by a script; humans see the clean display title in reading view).

## Alternatives Considered

1. **Self-aliases (original approach)** — REJECTED: does not connect the graph. Obsidian ignores
   `aliases` for bare `[[X]]` resolution. The 53 aliases added by Phase 14-03 are harmless but
   useless for connectivity; they stay as vestigial residue (Quick Switcher convenience).

2. **Bundle a small Obsidian resolver plugin** — REJECTED: violates §1 ("functions as plain markdown
   regardless of tooling"); the plugin injects into `metadataCache.uniqueFileLookup` — an undocumented
   internal API that breaks on Obsidian updates; "Obsidian plugin distribution" is v1.2-deferred per
   PROJECT.md. Adds an unofficial dependency to every clone of the template.

3. **Bare slug links `[[id]]` (no display text)** — REJECTED: resolves, but Obsidian displays the raw
   slug in reading view (e.g. "domain-driven-design" instead of "Domain-Driven Design") — unreadable.
   Previously rejected in `dr-2026-06-02-obsidian-filename-alias-resolution`.

4. **Rename wiki files to their titles** — REJECTED: breaks the `id == filename` invariant (§5),
   provenance source IDs (every `[prov:source_id#...]` marker), and all slug-based tooling.
   Previously rejected in `dr-2026-06-02-obsidian-filename-alias-resolution`.

## Consequences

- §8 is an unconditional rule: agents always write `[[id|Title]]`, never bare `[[Title]]`.
- `aliases` field is optional — removing the mandate does not break existing pages (the 53 self-
  aliases remain harmless; future pages omit them unless genuinely needed for alternate names).
- `linkres` re-pointed: errors on bare `[[X]]` and piped `[[target|...]]` where target is not a
  known `id`. Red links (not-yet-existing `id` targets) remain `gap`/info per §3.
- Body links in `wiki/` + `examples/` require a one-time rewrite to piped form (Phase 14 Wave 2).
- The v1.2 schema progressive-disclosure refactor (999.4) is correctly sequenced AFTER this fix.

## Affected Pages

- [[dr-2026-06-02-obsidian-filename-alias-resolution|Obsidian Filename + Alias Resolution: Self-Alias Invariant]]
  — superseded by this decision; its `superseded_by` field is updated to
  `dr-2026-06-03-uniform-piped-links`.

## Sources

No external sources. The decision is grounded in:
- Obsidian moderator confirmation: https://forum.obsidian.md/t/wikilink-resolution-does-not-honor-frontmatter-aliases-1-12-7/113902
- Official Obsidian aliases docs: https://obsidian.md/help/aliases
- Phase 14 LINK-10 human-verify gate failure (2026-06-03)
