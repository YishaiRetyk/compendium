# Examples Directory

> Reference documentation for the `examples/` tree: how reference clusters work, the `example: true` lint-skip convention, the corrected `.obsidianignore` behavior, and the `examples/dataview-fixtures/` render-fixture set with its expected per-query row counts.

## TL;DR

`examples/` holds reference-only content that demonstrates the wiki schema without being part of the active wiki. Pages there carry `example: true`, which makes `bin/lint.sh` skip them and excludes them from the published wiki. The `examples/dataview-fixtures/` subtree is a purpose-built set of render fixtures with deterministic, documented row counts for the five canonical Dataview queries.

## How `examples/` works

The `examples/` tree is reference material, not active wiki content (AGENTS.md §2). It is excluded from the published wiki and skipped by lint health checks. Two clusters live here:

- `examples/kahneman/` — a complete, internally consistent worked instance of the full schema surface (entity / concept / comparison / overview / source-summary pages plus an index and log). Live composition (page-type subdirectories only): **1 entity, 3 concepts, 1 comparison, 1 overview, 2 sources**. (`README.md` and `log.md` carry `type: overview` in their own frontmatter but are NOT wiki pages — they are never counted.)
- `examples/dataview-fixtures/` — synthetic, neutrality-clean fixtures for exercising Dataview rendering (documented below).

### The `example: true` lint-skip convention

Any page with `example: true` in its frontmatter is reference-only (AGENTS.md §5). `bin/lint.sh` MUST skip these pages for health checks so illustrative content never triggers warnings. The marker applies anywhere in the tree, not just under `examples/`. In practice the `examples/` path prefix is also a lint `EXCLUDE_DIRS` entry, so the fixtures are skipped both by path and by the `example: true` marker.

## The `.obsidianignore` correction

`.obsidianignore` is **NOT an Obsidian-native feature.** Obsidian has no built-in support for a `.obsidianignore` file, so it does not hide anything from indexing. The live vault's `.obsidian/app.json` is `{}` (no `userIgnoreFilters` set), which means Obsidian and the Dataview plugin **index `examples/` today**.

Treat `.obsidianignore` instead as a **release-manifest + graph-hygiene convention**: a plain-text list consumed by `bin/release.sh` and the docs to decide what a published template snapshot should exclude. It is a tooling convention, not an Obsidian-enforced indexing exclusion.

The real Obsidian exclusion mechanism is **Settings → Files & Links → Excluded files** (persisted as `userIgnoreFilters` in `app.json`). If you want to hide `examples/` from the Obsidian graph, add it there — but do NOT add `examples/` (or `examples/dataview-fixtures/`) to Excluded files when you want the fixtures below to render, or the Dataview queries will return 0 rows.

## `examples/dataview-fixtures/` inventory + expected counts

`examples/dataview-fixtures/` contains 10 `example: true` fixture pages spanning page types, statuses, domains, and privacy presence. The composition is mechanically derived so that each canonical Dataview query returns a non-trivial, re-derivable count. At least 2 fixtures carry `bootstrap_stage` so a single Obsidian open exercises both fresh-starter and post-bootstrap rendering.

The counts below are **STATIC GREP-PROXIES** of the live-Dataview render. They are the expected values the live render (Phase 13.2 DEBT-01) should reproduce. Each query is the fixture-scoped (`FROM "examples/dataview-fixtures"`) variant of the corresponding canonical query in [dataview-queries.md](dataview-queries.md).

**Active entity pages — expected count: 3**

```dataview
TABLE summary, epistemic_status, updated_at
FROM "examples/dataview-fixtures"
WHERE type = "entity" AND status = "active"
SORT updated_at DESC
```

**Sources in domain `alpha` — expected count: 2**

```dataview
TABLE source_type, ingested_at, content_hash
FROM "examples/dataview-fixtures"
WHERE type = "source" AND contains(domains, "alpha")
SORT ingested_at DESC
```

**Stale pages — expected count: 2**

```dataview
LIST
FROM "examples/dataview-fixtures"
WHERE epistemic_status = "stale"
SORT updated_at ASC
```

**Pages missing privacy classification — expected count: 2**

```dataview
LIST
FROM "examples/dataview-fixtures"
WHERE !privacy
```

**Active pages in domain `alpha` — expected count: 5**

```dataview
TABLE title, type, epistemic_status
FROM "examples/dataview-fixtures"
WHERE contains(domains, "alpha") AND status = "active"
SORT type ASC
```

### Dataview-vs-grep divergence notes (watch at live render)

The expected counts are grep-proxies; two known divergences between grep and live Obsidian Dataview must be confirmed at the Phase 13.2 live-render step:

1. **`WHERE !privacy`** matches BOTH an omitted `privacy` key AND a present-but-null `privacy:` (a key with no value), whereas a `grep -L '^privacy:'` proxy only catches OMISSION. Every fixture here either sets `privacy: cloud_safe` (a value) or omits the line entirely — none use a bare null — so the proxy and Dataview agree for this set. Expected: 2.
2. **`contains(domains, "alpha")`** requires `domains` to be a YAML **list**. Every fixture uses block-form lists, so the predicate resolves. A scalar `domains: alpha` would silently fail the Dataview predicate.

### Re-deriving a count from the live fixtures

The expected counts are not author-tallied; they are mechanically re-derivable. For example, the active-entities count:

```sh
grep -l '^type: entity' examples/dataview-fixtures/*.md | xargs grep -l '^status: active' | wc -l
# => 3  (matches the active-entities query block above)
```

## Copying example pages into `wiki/`

The `examples/` clusters are frozen reference material — do not edit them in place. To adapt a pattern, copy the page shape into the appropriate `wiki/` subdirectory, then drop `example: true`, replace placeholder content with real provenance-backed claims, and run `bin/lint.sh` over the new page. A copied page is no longer reference-only, so it is gated by lint like any other wiki content.

## See also

- [AGENTS.md](../../AGENTS.md) — §2 directory structure, §5 `example: true` field.
- [dataview-queries.md](dataview-queries.md) — the five canonical queries these fixtures exercise.
- [agent-parity.md](agent-parity.md) — uses the `examples/kahneman/` cluster as the golden for structural-equivalence diffing.
- [release.md](release.md) — `bin/release.sh` and the release-manifest convention.
- [../README.md](../README.md)
- [index.md](index.md)
