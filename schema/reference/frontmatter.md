# Frontmatter Schema

> Agent-authoritative reference for all wiki page frontmatter fields, types, validation rules, and compilation tracking.
> The AGENTS.md routing table points here.

### Base Fields (Required on Every Wiki Page)

```yaml
---
id: slug-style-identifier          # Unique page ID, kebab-case
title: "Human Readable Title"      # Canonical page title
type: entity|concept|source|comparison|overview|decision
status: active|stale|superseded|archived
summary: "One-sentence description for index scanning."
created_at: YYYY-MM-DD            # ISO 8601
updated_at: YYYY-MM-DD            # ISO 8601
sources:                           # List of source IDs (strings, NOT wikilinks)
  - src-YYYY-MM-DD-slug
epistemic_status: sourced|mixed|tentative|stale
tags:                              # Flat list for Dataview queries
  - tag-name
domains:                           # Topic/category classification
  - domain-name
supersedes:                        # ID of page this replaces (if any)
superseded_by:                     # ID of page that replaces this (if any)
aliases:                           # Alternative names for Obsidian resolution
  - Alternate Name
has_contradictions: false       # true when page contains [contradiction:...] markers
knowledge_domain: ""            # Primary decay-rate bucket (maps to the decay table in `schema/workflows/lint.md`)
example: false                  # Optional; true for reference-only pages (examples/). Lint skips these.
---
```

### Field Descriptions

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Unique identifier in kebab-case. Used in `sources` lists and `[prov:]` markers. Must match the filename (without `.md`). |
| `title` | string | Human-readable canonical title. Used in page headings and as the display text in piped links `[[id|Title]]`. Obsidian resolves `[[X]]` by **filename/path ONLY** — never by this field and never by `aliases`. |
| `type` | enum | Page type: `entity`, `concept`, `source`, `comparison`, `overview`, `decision`. Determines section structure. |
| `status` | enum | Lifecycle state: `active` (current), `stale` (may be outdated), `superseded` (replaced by another page), `archived` (no longer relevant). |
| `summary` | string | One sentence. Used for index scanning and Dataview table previews. Must be a single quoted string, not multi-line. |
| `created_at` | date | ISO 8601 date when the page was first created. |
| `updated_at` | date | ISO 8601 date when the page was last modified. |
| `sources` | list | YAML list of source IDs (strings). References raw sources this page draws from. NOT wikilinks. |
| `epistemic_status` | enum | Evidence quality: `sourced` (directly from source), `mixed` (some sourced + some inferred), `tentative` (weak evidence), `stale` (likely outdated). |
| `tags` | list | YAML list of lowercase kebab-case strings. Used for Dataview queries and filtering. |
| `domains` | list | YAML list of topic/category classifications in kebab-case. Used for cross-domain Dataview queries. |
| `supersedes` | string | ID of the page this one replaces. Null if not applicable. |
| `superseded_by` | string | ID of the page that replaces this one. Null if not applicable. |
| `aliases` | list | OPTIONAL. Genuine alternate names (e.g. common abbreviations). Obsidian uses these for Quick Switcher / autocomplete and as display text in piped links `[[file|Alias]]`. They do NOT affect bare `[[X]]` resolution — that is always filename/path only. |
| `has_contradictions` | boolean | `true` when any claim on the page has a `[contradiction:...]` marker. Independent of `epistemic_status` -- a `sourced` page can have contradictions. May be set by lint workflow OR by any workflow that inserts contradiction markers (ingest, query). The lint mechanically syncs this field: if `[contradiction:]` markers exist in the body, `has_contradictions` MUST be `true`; if no markers exist, it MUST be `false`. |
| `example` | boolean | Optional (default `false`). When `true`, the page is a reference-only example (e.g., pages under `examples/kahneman/`). Lint MUST skip these pages for health checks so illustrative content does not trigger warnings. Applies anywhere in the tree, not just under `examples/`. |
| `knowledge_domain` | string | Primary knowledge domain for staleness decay rate calculation. This is the **staleness policy bucket**, distinct from the `domains` field which is a topical classification list. A page may have `domains: [psychology, economics]` but `knowledge_domain: science` because both topics decay at the science rate. Maps to the decay table in `schema/workflows/lint.md`. One of: `software`, `science`, `biography`, `personal-goals`, or a custom domain. Empty string if not yet classified. |
| `bootstrap_stage` | enum | Brownfield onboarding sentinel. Values: `raw | bootstrapped | verified`. Page-level marker tracking migration state from pre-existing Obsidian vault content into the schema. **NOT a substitute for claim-level provenance (see `schema/reference/provenance.md` PROV-01..05)** -- the authoritative provenance mechanism remains claim-level `[prov::...]` markers + source summary pages. Written by `bin/brownfield.sh bootstrap` (Phase 10); stripped by `bin/ingest.sh` on normal ingest to prevent pollution. Absent from greenfield pages. See `schema/workflows/brownfield.md` (populated in Phase 11). |
| `bootstrap_date` | date | ISO 8601 `YYYY-MM-DD` stamp (UTC) recording when `bin/brownfield.sh bootstrap` injected `bootstrap_stage: bootstrapped` on this page. Read by `bin/lint.sh` `brownfield` category for the 30-day staleness warning (BRWN-09). Written alongside `bootstrap_stage`; stripped by `bin/ingest.sh` on normal ingest. |

### Source Summary Additional Fields

Source summary pages (`type: source`) include these additional frontmatter fields:

```yaml
path: sources/YYYY/YYYY-MM/YYYY-MM-DD-slug/source.md
url: "https://..."                  # Original URL if applicable
content_hash: "sha256:abc123..."    # SHA-256 hash for staleness detection
ingested_at: YYYY-MM-DD            # When source was processed
source_type: article|paper|transcript|journal|data|image|research-report

# Compilation tracking
compilation_status: pending         # pending | partial | compiled | stale
compiled_against_hash: ""           # SHA-256 of source content at last compilation
compiled_targets: []                # Wiki page IDs that received compiled claims
```

Semantics for each `source_type` value and the extension decision rule → `schema/reference/source-types.md`.

### Compilation Tracking Fields (Source Summary Pages)

Source summary pages carry three additional fields that track whether their extracted claims have been compiled into topic pages. These fields enable delta compilation (compiling only new or changed sources) and stale-source detection.

| Field | Type | Description |
|-------|------|-------------|
| `compilation_status` | enum | Compilation lifecycle: `pending` (new, uncompiled), `partial` (some claims merged), `compiled` (all claims merged into topic pages), `stale` (source content changed since last compilation) |
| `compiled_against_hash` | string | SHA-256 hash of source content at time of last compilation. Copied from `content_hash` when compilation completes. When `content_hash` changes on re-ingest and no longer matches `compiled_against_hash`, status resets to `stale`. |
| `compiled_targets` | list | YAML list of wiki page IDs (the `id` field value, not file paths) that received claims from this source during compilation. Example: `[<concept-slug>, <concept-slug-2>, <entity-slug>]` |

#### Compilation Status Transition Rules

The following transitions are the ONLY valid state changes. Any other transition is a bug.

| From | To | Trigger | Who Sets It |
|------|----|---------|-------------|
| (new source) | `pending` | Source ingested, before merge pass | Ingest workflow step 5 (extract) |
| `pending` | `compiled` | All extracted claims merged into topic pages | Ingest workflow step 6a |
| `pending` | `partial` | Some claims merged, others deferred | Ingest workflow step 6a |
| `partial` | `compiled` | Remaining claims compiled (via query delta or manual) | Query workflow step 6 or follow-up ingest |
| `compiled` | `stale` | `content_hash` changed on re-ingest (no longer matches `compiled_against_hash`) | Ingest workflow on re-ingest detection |
| `stale` | `compiled` | Re-compilation completed against new content | Query workflow step 6 or follow-up ingest |
| `stale` | `partial` | Partial re-compilation completed | Query workflow step 6 |

**Invariants:**
- `compiled_against_hash` is ALWAYS equal to `content_hash` when `compilation_status` is `compiled`.
- `compiled_against_hash` differs from `content_hash` when `compilation_status` is `stale`.
- `compiled_targets` is empty ONLY when `compilation_status` is `pending`.
- Pages missing `compilation_status` (pre-Phase-4 legacy) are treated as `compiled` by tooling.

### Decision Record Additional Fields

Decision record pages (`type: decision`) include these additional frontmatter fields:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `trigger_type` | enum | Yes | What prompted this decision: `merge`, `split`, `schema-update`, `domain-reorg`, `reframing`, `contradiction-resolution` |
| `affected_pages` | list | Yes | YAML list of page IDs affected by this decision. Used for bidirectional navigation via `decision_history` on those pages. |

### Optional Back-Link Field

Any page type may include this field when referenced by a decision record:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `decision_history` | list | No | YAML list of decision record IDs (e.g., `[dr-2026-04-14-slug]`). Added when a decision record lists this page in `affected_pages`. NOT a base field -- absence is valid. When present, must be a YAML list of strings. |

### Frontmatter Validation Checklist

When creating or updating any wiki page, verify:

1. All base fields are present (id, title, type, status, summary, created_at, updated_at, sources, epistemic_status, tags, domains, supersedes, superseded_by, aliases)
2. `type` is one of: `entity`, `concept`, `source`, `comparison`, `overview`, `decision`
3. `status` is one of: `active`, `stale`, `superseded`, `archived`
4. `epistemic_status` is one of: `sourced`, `mixed`, `tentative`, `stale`
5. `created_at` and `updated_at` match ISO 8601 pattern `YYYY-MM-DD`
6. `sources` is a YAML list of string IDs, NOT wikilinks
7. `tags` and `domains` are YAML lists of lowercase kebab-case strings
8. `summary` is a single quoted string, not multi-line
9. `id` matches the filename (without `.md` extension)
10. For `type: source` pages: `path`, `content_hash`, `ingested_at`, and `source_type` are present
11. For `type: source` pages: `compilation_status` is one of: `pending`, `partial`, `compiled`, `stale`
12. `has_contradictions` is a boolean (`true` or `false`)
13. `knowledge_domain` is a non-empty string for pages with provenance-backed claims
14. For `type: decision` pages: `trigger_type` is one of: `merge`, `split`, `schema-update`, `domain-reorg`, `reframing`, `contradiction-resolution`
15. For `type: decision` pages: `affected_pages` is present and is a YAML list of string IDs
16. If `decision_history` is present on any page: it is a YAML list of string IDs
17. Every intra-wiki body link MUST use the piped form `[[id|Exact Title]]` — target is the page `id` (= filename stem, always resolves in Obsidian); display is the exact canonical `title`. Bare `[[Title]]` links are a convention error.

---

## See Also

- [AGENTS.md](../../AGENTS.md) -- routing-table stub (pointer to this file).
- `schema/reference/page-types.md` -- per-type section ordering and authoring conventions.
