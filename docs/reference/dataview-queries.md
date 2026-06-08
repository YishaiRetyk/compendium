# Dataview Query Examples

> Reference documentation for the five canonical Dataview query patterns used across the wiki. Extracted from AGENTS.md §16 Appendix A for progressive-disclosure readability.

## TL;DR

The wiki uses Dataview to query frontmatter fields across pages. These five patterns cover the common cases: listing active entities, finding sources by domain, surfacing stale pages, spotting missing privacy classification, and enumerating pages in a specific domain. See [AGENTS.md §5](../../AGENTS.md) for the underlying frontmatter schema these queries read.

## Query Patterns

**List all active entity pages:**

```dataview
TABLE summary, epistemic_status, updated_at
FROM "wiki/entities"
WHERE status = "active"
SORT updated_at DESC
```

**List all sources by domain:**

```dataview
TABLE source_type, ingested_at, content_hash
FROM "wiki/sources"
WHERE contains(domains, "ai-research")
SORT ingested_at DESC
```

**List stale pages across the entire wiki:**

```dataview
LIST
FROM "wiki"
WHERE epistemic_status = "stale"
SORT updated_at ASC
```

**Find pages missing privacy classification:**

```dataview
LIST
FROM "wiki"
WHERE !privacy
```

**List all pages in a specific domain:**

```dataview
TABLE title, type, epistemic_status
FROM "wiki"
WHERE contains(domains, "ai-research") AND status = "active"
SORT type ASC
```

## See also

- [AGENTS.md](../../AGENTS.md)
- [../README.md](../README.md)
