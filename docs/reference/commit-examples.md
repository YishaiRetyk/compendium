# Commit Message Examples

> Reference documentation for representative commit messages per wiki workflow type. Extracted from AGENTS.md §16 Appendix B for progressive-disclosure readability.

## TL;DR

All wiki commits use conventional-commit format with a workflow-type prefix: `schema`, `ingest(<source-slug>)`, `query(<topic>)`, `lint(<scope>)`, or `reflect(<scope>)`. See [AGENTS.md §3](../../AGENTS.md) for the full commit-convention rules and the one-commit-per-logical-operation discipline.

## Examples

```
schema: define base frontmatter fields and page type conventions
ingest(hinton-interview): add source summary and update entity pages
ingest(vaswani-attention): create source summary with 3 extracted claims, update attention mechanism page
query(attention-mechanisms): synthesize comparison of attention variants
query(ai-safety-timeline): create overview page from 4 existing sources
lint(wiki): fix 3 orphan pages and 2 broken provenance references
lint(entities): update 5 stale epistemic_status markers
reflect(q1-review): restructure AI safety domain after new sources
reflect(domain-split): separate neuroscience from ai-research domain
```

## See also

- [AGENTS.md](../../AGENTS.md)
- [../README.md](../README.md)
