# Wikilink and Graph Conventions

> Agent-authoritative reference for intra-wiki linking: the uniform piped-link form, red links, and Obsidian graph behavior.
> AGENTS.md §8 and §3 Red Links point here. This file carries the v1.1.1 uniform-piped-link truth.

## Red Links

Red links (wikilinks to non-existent pages) are allowed and intentional. They signal knowledge gaps that the lint workflow tracks. Do not remove red links unless creating the target page or confirming the gap is irrelevant.

## Rules

1. Use `[[id|Exact Title]]` for ALL intra-wiki cross-references in page body text.
   The target before `|` is the page `id` (= filename stem — always resolves in Obsidian
   since Obsidian resolves `[[X]]` by **filename/path ONLY**, never by `title` and never
   by `aliases`). The display text after `|` is the exact canonical `title`.
2. Link on FIRST mention only per page. Subsequent mentions are plain text.
3. ALWAYS write `[[id|Exact Title]]` — bare `[[Title]]` links are a convention error.
   Examples: `[[attention-mechanism|Attention Mechanism]]`, `[[<entity-id>|Entity Title (Parens)]]`.
4. The `aliases` frontmatter field is OPTIONAL — for genuine alternate names (Quick Switcher /
   autocomplete), NOT for link resolution. Obsidian resolves `[[X]]` by **filename/path ONLY**.
5. Red links (links to not-yet-existing page `id`s) are ALLOWED and intentional. They signal
   knowledge gaps for the lint workflow. Write them as `[[not-yet-existing-id|Display Text]]`
   where the `id` is the planned slug.
6. DO NOT put wikilinks in YAML frontmatter. Use string IDs in frontmatter, wikilinks in body text.
7. The `## Related Pages` section lists explicit wikilinks to connected pages.
8. The `## Sources` section in page body lists human-readable source references with wikilinks to
   source summary pages.
9. **Asymmetric cross-tier link rule (D-09):** `wiki-local` → `wiki-cloud` links are fine (local sessions read both tiers). `wiki-cloud` → `wiki-local` links are **FORBIDDEN** -- they break for cloud sessions AND leak the existence of private pages. This rule is lint-enforced (linkres category). A `wiki-cloud/` page MUST NOT contain a wikilink whose target resolves to a `wiki-local/` page.

## Bad vs. Good Wikilink Examples

```
BAD:  sources: ["[[Vaswani et al]]"]                    (wikilink in frontmatter)
GOOD: sources: [src-2026-03-15-vaswani-attention]       (string ID in frontmatter)

BAD:  [[Attention Mechanism]]                           (bare link -- does not resolve for multi-word titles)
GOOD: [[attention-mechanism|Attention Mechanism]]       (piped: target=id, display=title)

BAD:  [[attention-mechanism|attention]]                 (display text is not the exact canonical title)
GOOD: [[attention-mechanism|Attention Mechanism]]       (display = exact title from page frontmatter)

BAD:  ...[[attention-mechanism|Attention Mechanism]] uses [[attention-mechanism|Attention Mechanism]] weights...  (linked twice)
GOOD: ...[[attention-mechanism|Attention Mechanism]] uses attention weights...  (linked once, plain after)

BAD:  [[<Entity Title> (Parens)]]                       (bare link, parens title, will not resolve)
GOOD: [[<entity-id>|Entity Title (Parens)]]             (piped: id target resolves, parens in display)

BAD:  [[<Concept Titles>]]                              (bare plural link)
GOOD: [[<concept-id>|Concept Titles]]                   (id target resolves; plural cosmetic in display)
```

## Graph View Implications

- Only wikilinks in page body text appear in Obsidian's graph view. Piped links `[[id|Title]]` display the `title` in reading view while forming a graph edge to the `id` target.
- String IDs in frontmatter do NOT create graph edges. This is intentional -- frontmatter holds structured data; body text holds navigable links.
- First-mention linking prevents link noise. A page that mentions a concept many times creates only one graph edge, not many.
- Red links (piped links whose `id` target does not exist yet) appear as unresolved nodes, providing a visual map of knowledge gaps.

## See Also

- [AGENTS.md](../../AGENTS.md) — §8 stub (pointer to this file).
- `schema/reference/page-types.md` — per-type section ordering (relevant for link context).
