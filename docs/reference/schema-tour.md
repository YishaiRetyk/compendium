# Schema Tour

> Reference documentation for the wiki page schema: the frontmatter base fields, per-type additions, the validation checklist, and how individual claims cite their sources.

## TL;DR

Every wiki page is a markdown file with a YAML frontmatter header and a fixed section order. The frontmatter carries machine-readable metadata (id, type, status, provenance pointers, privacy tier); the body carries human-readable synthesis with inline provenance markers tying each factual claim back to a specific locator in a raw source. This page walks the schema surface top to bottom and shows the claim-citation grammar.

> **Source of truth:** The authoritative schema lives in [AGENTS.md §5](../../AGENTS.md) (frontmatter) and [§6](../../AGENTS.md) (provenance, epistemics, staleness). This page reproduces it for ergonomic, progressive-disclosure reading — if you find a discrepancy, §5/§6 wins and this page is the bug.

## Page types

Six page types exist, each with a defined purpose and section order (AGENTS.md §4):

| Type | Purpose | Section order |
|------|---------|---------------|
| `entity` | People, tools, organizations, named things | TL;DR → Key Facts → Detail → Related Pages → Sources |
| `concept` | Ideas, theories, frameworks, abstract topics | TL;DR → Key Facts → Detail → Related Pages → Sources |
| `source` | One summary page per ingested source | TL;DR → Key Takeaways → Extracted Claims → Notes → Source Metadata |
| `comparison` | Side-by-side analysis of 2+ subjects | TL;DR → Bottom Line → Comparison Table → Detailed Comparison → Sources |
| `overview` | High-level synthesis across many pages | TL;DR → Key Facts → Detail → Related Pages → Sources |
| `decision` | Why a structural change was made | TL;DR → Decision → Why → Alternatives → Consequences → Affected Pages → Sources |

The section order is load-bearing: the top of each page is optimized for fast LLM scanning, the bottom for human verification (progressive disclosure, AGENTS.md §7).

## Base frontmatter fields

Every wiki page carries this base set (AGENTS.md §5). Field names are `snake_case` and dates are ISO 8601 (`YYYY-MM-DD`) — both are hard requirements for Dataview compatibility.

```yaml
---
id: <page-slug>                    # kebab-case, MUST match filename without .md
title: "<Human Readable Title>"    # wikilinks resolve to this value
type: entity|concept|source|comparison|overview|decision
status: active|stale|superseded|archived
summary: "One-sentence description for index scanning."
created_at: <YYYY-MM-DD>
updated_at: <YYYY-MM-DD>
sources:                           # list of source IDs (strings, NOT wikilinks)
  - <source-id>
epistemic_status: sourced|mixed|tentative|stale
tags:                              # flat list for Dataview queries
  - <tag>
domains:                           # topic/category classification
  - <domain>
supersedes:                        # ID of page this replaces (if any)
superseded_by:                     # ID of page that replaces this (if any)
privacy: local_only|cloud_safe     # privacy routing tier
aliases:                           # alternative names for Obsidian resolution
  - <Alternate Name>
has_contradictions: false          # true when body carries [contradiction:...] markers
knowledge_domain: ""               # decay-rate bucket (Section 6 decay table)
example: false                     # true for reference-only pages (lint skips these)
---
```

Two field distinctions are easy to miss:

- **`domains` vs `knowledge_domain`** — `domains` is a topical-classification *list* (`[<domain-a>, <domain-b>]`); `knowledge_domain` is a single staleness-policy *bucket* (`software`, `science`, `biography`, `personal-goals`, or a custom value) that selects the decay rate. A page may have two topical domains but one decay bucket.
- **`status` vs `epistemic_status`** — `status` is the lifecycle state (`active` / `stale` / `superseded` / `archived`); `epistemic_status` is the evidence quality (`sourced` / `mixed` / `tentative` / `stale`). They move independently.

## Per-type frontmatter additions

Two page types extend the base set:

**Source summary pages (`type: source`)** add a source tail and compilation-tracking fields:

```yaml
path: sources/<YYYY>/<YYYY-MM>/<YYYY-MM-DD-slug>/source.md
url: "https://..."                 # original URL if applicable
content_hash: "sha256:..."         # SHA-256 for staleness detection
ingested_at: <YYYY-MM-DD>
source_type: article|paper|book-chapter|transcript|journal|data|image
compilation_status: pending        # pending | partial | compiled | stale
compiled_against_hash: ""          # content_hash at last compilation
compiled_targets: []               # wiki page IDs that received compiled claims
```

**Decision record pages (`type: decision`)** add `trigger_type` (`merge` / `split` / `schema-update` / `domain-reorg` / `reframing` / `contradiction-resolution`) and `affected_pages` (a list of affected page IDs). Decision pages also ship two non-empty defaults: `epistemic_status: sourced` and `privacy: cloud_safe`. Any page referenced by a decision may gain an optional `decision_history` back-link list — this is NOT a base field, so its absence is valid.

## Validation checklist

Before creating or updating any page, verify (AGENTS.md §5 checklist):

1. All base fields present.
2. `type`, `status`, `epistemic_status`, `privacy` hold valid enum values.
3. `created_at` / `updated_at` match `YYYY-MM-DD`.
4. `sources`, `tags`, `domains` are YAML lists of strings (NOT wikilinks; `tags`/`domains` lowercase kebab-case).
5. `summary` is a single quoted string, not multi-line.
6. `id` matches the filename (without `.md`).
7. For `type: source`: `path`, `content_hash`, `ingested_at`, `source_type`, and a valid `compilation_status` are present.
8. For `type: decision`: `trigger_type` is a valid enum and `affected_pages` is a list.
9. `has_contradictions` is a boolean that matches whether `[contradiction:...]` markers exist in the body.

`bin/lint.sh` mechanically enforces the structural subset of this checklist (category `yaml`); see [ci.md](ci.md) for how it runs in CI.

## How claims cite their sources

Every factual claim in a wiki body SHOULD carry an inline provenance marker linking it to a specific location in a source (AGENTS.md §6).

**Grammar:**

```
[prov:<source-id>#<locator>]                          # basic form
[prov:<source-id>#<locator>|<support_type>|<checked_at>]   # extended form
```

**Locator types:**

| Locator | Format | Use for |
|---------|--------|---------|
| Page range | `#p<start>-<end>` or `#p<page>` | PDFs, papers |
| Section | `#sec:<name>` | markdown sections |
| Paragraph | `#para<number>` | specific paragraphs |
| Timestamp | `#t<start>-<end>` | audio/video transcripts |
| Image | `#img<number>` | figures, diagrams |

**Support types:** `direct` (stated in source), `inferred` (logically derived), `tentative` (weak evidence), `derived` (synthesized across parts/sources).

**`checked_at`** records the ISO 8601 date the link was last verified against the source; it drives staleness detection together with the source's `content_hash`.

A claim using placeholders looks like:

```markdown
- <Concept> lets the model focus on the relevant input tokens [prov:<source-id>#sec:introduction|direct|<YYYY-MM-DD>]
```

A worked, real example lives in the sanctioned reference cluster — see the claim markers throughout the `examples/kahneman/concepts/` pages (3 concept pages) and `examples/kahneman/sources/` summaries.

### Page-marker convention for `#p` locators

Markdown-native sources have no intrinsic page boundaries, so a `#p<n>` locator needs an anchor. The optional `<!-- page: N -->` HTML comment, hand-inserted at each page break in the raw source, makes `#p` resolvable. It is invisible in Obsidian reading view, grep-able, and additive (it changes nothing about the `[prov:]` grammar). When absent, a `#p` locator degrades to the audit's `insufficient-locator` verdict rather than an error — prefer `#sec:` / `#para` locators for markdown-native sources that have no real pages.

## Claim-level epistemic markers

Separate from provenance, per-claim confidence uses Dataview inline-field syntax: `[epistemic:: sourced|inferred|tentative|stale]`. Provenance (`[prov:...]`) is for traceability (grep/scripts); epistemic markers are for confidence discovery (Dataview). They coexist intentionally and are NOT normalized to one syntax. A combined claim:

```markdown
Claim text. [prov:<source-id>#<locator>|<support_type>] [epistemic:: inferred]
```

New `[epistemic:: inferred]` / `[epistemic:: tentative]` claims are gated by `bin/lint.sh --strict` unless a matching decision record lists the page in `affected_pages`, or an `<!-- lint:expect-inferred ... -->` escape-hatch marker exempts the claim — see [ci.md](ci.md).

## Staleness

Claims inherit temporal relevance from their source dates. Different `knowledge_domain` buckets decay at different rates (AGENTS.md §6): `software` 180 days, `science` 730 days, `biography` 1825 days, `personal-goals` 90 days, default 365 days. Epistemic status modifies the rate (`tentative` decays twice as fast). A `content_hash` mismatch between a source page and its `compiled_against_hash` makes all dependent claims immediately stale regardless of the decay window. `bin/lint.sh` surfaces stale claims (category `stale`) and can mechanically append `[epistemic:: stale]` markers.

## See also

- [AGENTS.md](../../AGENTS.md) — §5 frontmatter schema, §6 provenance/epistemics/staleness, §7 progressive disclosure.
- [privacy-model.md](privacy-model.md) — the `privacy` field and routing rules in depth.
- [examples.md](examples.md) — the `example: true` reference clusters that demonstrate this schema filled in.
- [ci.md](ci.md) — how `bin/lint.sh` enforces the structural schema subset.
- [../README.md](../README.md)
- [index.md](index.md)
