# Scaling Boundaries

> Informational reference for wiki scaling heuristics: when to upgrade from single index to split indexes, incremental lint, and DB-backed metadata. Not normative — these are provisional signals to watch.

**Important:** These are provisional heuristics, not hard boundaries. They are starting points derived from reasoning about likely pain points. Validate and adjust through actual use. The numbers below are approximate -- the real signals are behavioral (the wiki becomes awkward to use in specific ways).

These tiers are additive. Each builds on the previous rather than replacing it.

### Tier 1: Markdown-First Baseline (v1)

This is the starting configuration. Everything is markdown files and YAML frontmatter.

- **Navigation:** `wiki-cloud/index.md` is the primary navigation mechanism. The LLM reads it to find pages.
- **Lint:** Full lint scans all pages in the wiki-cloud/ tree.
- **Agent behavior:** Read the full index, scan all pages during lint.
- **Approximate capacity:** Up to ~100-200 wiki pages, ~50-100 ingested sources.
- **Pain points at limit:** `wiki-cloud/index.md` becomes slow to navigate. The LLM's context window fills up scanning the full index. Full lint takes multiple passes or minutes.
- **Signal you are outgrowing this tier:** `wiki-cloud/index.md` exceeds ~500 lines. The LLM frequently retrieves pages irrelevant to the query because the index is too dense to scan efficiently.

### Tier 2: Split Index

When the single index becomes unwieldy (approximately a few hundred wiki pages).

- **Change:** Split `wiki-cloud/index.md` into per-type or per-domain sub-indexes: `wiki-cloud/index-entities.md`, `wiki/index-concepts.md`, `wiki/index-sources.md`, etc. The main `wiki-cloud/index.md` becomes a meta-index pointing to sub-indexes.
- **Agent behavior:** Read the meta-index to determine which sub-index is relevant, then read only that sub-index.
- **Approximate capacity:** Up to ~500-1000 wiki pages.
- **Pain points at limit:** Even sub-indexes become large. Cross-type queries require reading multiple sub-indexes. The meta-index itself grows.
- **Signal to upgrade:** Sub-indexes exceed ~200 entries each. Cross-domain queries are slow because the LLM must read multiple sub-indexes.

### Tier 3: Incremental Lint

When full lint becomes too expensive to run routinely.

- **Change:** Track which pages changed since the last lint (via `git diff` or `wiki-cloud/log.md` timestamps). Only lint changed pages and their direct neighbors (pages they link to or are linked from).
- **Agent behavior:** Run `git diff --name-only <last-lint-commit>` to scope the lint to changed files. Expand scope to include pages linked to/from changed pages.
- **Approximate capacity:** Any size where full lint is impractical.
- **Pain points at limit:** Neighbor expansion can still be large in highly connected wikis. Deep dependency chains may be missed by incremental lint.
- **Signal to upgrade:** Lint takes so long that you stop running it, or incremental lint misses issues that a full lint would catch.

### Tier 4: DB-Backed Metadata

When provenance queries, search, or concurrency become awkward in pure markdown.

- **Change:** Add SQLite (or similar lightweight database) for metadata: source registry, provenance index, search index, wikilink graph. Markdown pages remain the human-facing artifact; the database is an acceleration layer.
- **Agent behavior:** Query the database for source and provenance lookups instead of scanning markdown files. Use the database for search instead of grep.
- **Approximate capacity:** Thousands of pages and sources.
- **Pain points:** Requires maintaining synchronization between the database and markdown files. Adds a tooling dependency beyond plain markdown.
- **Signal to upgrade:** Provenance validation is slow because it requires scanning many files. Search needs more than grep. Multiple agents need concurrent access to the wiki.

## See Also

- [AGENTS.md](../../AGENTS.md) — §14 stub (pointer to this file).
- [docs/reference/index.md](index.md)
