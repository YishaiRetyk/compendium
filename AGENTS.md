# LLM Wiki Compiler Schema

> **This is the sole authoritative specification for the LLM Wiki Compiler.**
> Any LLM agent maintaining this wiki MUST read and follow this document.
> No other file contains conventions, rules, or workflow definitions.

## 1. Overview and Principles

The LLM Wiki Compiler is a personal knowledge management system with three layers:

1. **Raw sources** (`sources/`) -- Immutable input documents (articles, papers, transcripts, journal entries, images). The human curates this layer. Sources are never modified after ingestion.
2. **The wiki** (`wiki/`) -- LLM-generated and maintained markdown pages. This is the compiled artifact: summaries, entity pages, concept pages, comparisons, overviews, an index, and an activity log.
3. **The schema** (this file + `schema/`) -- The specification that governs LLM behavior. This file is the sole source of truth.

**Core principle:** The wiki is a persistent, compounding artifact. Cross-references are already there, contradictions already flagged, synthesis already reflects everything ingested. Knowledge accumulates rather than being re-derived.

**Role division:**
- The **human** curates sources and asks questions.
- The **LLM** writes and maintains the wiki: summarizing, cross-referencing, filing, and ensuring consistency.

**Four operations** govern all wiki activity:

| Operation | Purpose |
|-----------|---------|
| **Ingest** | Process a new source into wiki pages |
| **Query** | Answer a question using the wiki, optionally compiling new pages |
| **Lint** | Detect contradictions, stale claims, orphan pages, missing cross-references |
| **Reflect** | Structural reasoning, decision records, reframing history |

Workflows for each operation are defined in Section 11 of this document.

## 2. Directory Structure

```
life/                               # repo root
├── AGENTS.md                       # This file (sole authority)
├── sources/                        # Raw immutable sources
│   ├── YYYY/                       # Year grouping
│   │   └── YYYY-MM/               # Month grouping
│   │       ├── YYYY-MM-DD-slug/   # Bundle: source.md + assets
│   │       │   ├── source.md
│   │       │   └── figure1.png
│   │       └── YYYY-MM-DD-slug.md # Single file (no assets)
│   └── assets/                     # Optional: shared/tool-managed assets only
├── wiki/                           # LLM-maintained pages
│   ├── entities/                   # People, tools, organizations
│   ├── concepts/                   # Ideas, theories, frameworks
│   ├── sources/                    # Source summary pages (one per ingested source)
│   ├── comparisons/                # Comparison pages
│   ├── overviews/                  # High-level topic summaries
│   ├── index.md                    # Content catalog (master page list)
│   └── log.md                      # Chronological activity log
├── schema/                         # Templates + AGENTS.template.md wizard source
│   ├── AGENTS.template.md          # Wizard source ({{PRIMARY_DOMAIN}} etc.)
│   └── templates/                  # Page templates per type
├── examples/                       # Reference-only filled-in clusters (e.g., examples/kahneman/)
├── docs/                           # User-facing docs (quickstart, guided setup, manual setup, reference)
├── .github/                        # CI workflows, issue templates
├── bin/                            # Helper scripts (lint.sh, ingest.sh, sync-claude.sh, etc.)
└── .githooks/                      # Repo-local git hooks (e.g., pre-commit sync check)
```

**Permitted top-level directories:** `sources/`, `wiki/`, `schema/`, `examples/`, `docs/`, `.github/`, `bin/`, `.githooks/`. Content in `examples/` is reference-only (see `example: true` in Section 5); it is skipped by lint and excluded from the published wiki.

**Source directory rules:**
- Sources use chronological nesting: `YYYY/YYYY-MM/YYYY-MM-DD-slug/`
- When a source has assets (images, figures, attachments): create a bundle directory with `source.md` as the main file and assets co-located alongside it.
- When a source is text-only: use a single file `YYYY-MM-DD-slug.md` (no bundle directory needed).
- Source metadata (type, topic, privacy) is stored in the source file's frontmatter, not encoded in the directory structure.

**Wiki directory rules:**
- Pages are organized by type subdirectory: `entities/`, `concepts/`, `sources/`, `comparisons/`, `overviews/`.
- Topics and categories are represented via frontmatter fields (`tags`, `domains`), NOT via filesystem hierarchy.
- `wiki/index.md` and `wiki/log.md` live directly inside `wiki/` (they are wiki-layer artifacts).

**Schema directory rules:**
- `schema/` is optional and holds templates and examples.
- It does NOT contain rules or conventions -- those live only in this file.

## 3. Global Rules

### Date Format

All dates use ISO 8601 format: `YYYY-MM-DD` or `YYYY-MM-DDTHH:mm:ss`. No exceptions. This ensures Dataview can parse and sort dates correctly.

### Frontmatter Field Names

All frontmatter field names use `snake_case`. This prevents Dataview field name sanitization issues (Dataview converts spaces and special characters, creating mismatches between YAML keys and query field names).

### Commit Conventions

All commits use conventional commit format with wiki operation types:

| Type | When | Example |
|------|------|---------|
| `ingest(source-slug):` | Processing a new source | `ingest(hinton-interview): add source summary and update entity pages` |
| `query(topic):` | Answering a question, synthesizing pages | `query(attention-mechanisms): synthesize comparison of attention variants` |
| `lint(scope):` | Fixing detected issues | `lint(wiki): fix 3 orphan pages and 2 broken provenance references` |
| `reflect(scope):` | Structural reasoning, decision records | `reflect(q1-review): restructure AI safety domain after new sources` |
| `schema:` | Updating this document or templates | `schema: define base frontmatter fields and page type conventions` |

**One commit per logical operation.** A single ingest that touches 15 files is one commit. Rule: if the change answers "what happened?" with one sentence, it is one commit.

### LLM Navigation Rule

When searching for information in the wiki:

1. Read `wiki/index.md` FIRST to find relevant pages.
2. Scan `## TL;DR` and `## Key Facts` sections of relevant pages BEFORE reading Detail sections.
3. Only read `## Detail` and `## Sources` sections when shallow sections are insufficient.

This progressive disclosure navigation minimizes context window consumption.

### Red Links

Red links (wikilinks to non-existent pages) are allowed and intentional. They signal knowledge gaps that the lint workflow tracks. Do not remove red links unless creating the target page or confirming the gap is irrelevant.

### What Agents Must NOT Do

- DO NOT create topic-based directories (e.g., `wiki/machine-learning/`). Use frontmatter `domains` field and Dataview queries instead.
- DO NOT put conventions or rules in any file other than AGENTS.md. This is the sole source of truth.
- DO NOT put wikilinks in YAML frontmatter. Use string IDs in frontmatter, wikilinks in body text.
- DO NOT use display aliases in wikilinks: write `[[Attention Mechanism]]` not `[[Attention Mechanism|attention]]`.
- DO NOT put provenance blobs, relation arrays, or decay settings in base frontmatter. Those belong in type-specific fields.
- DO NOT delete or move files when archiving. Set `status: archived` and remove from index active listings.
- DO NOT read the entire wiki when answering a query. Read index first, then TL;DR/Key Facts of relevant pages, then Detail only when needed.
- DO NOT create multiple commits for a single logical operation. One ingest = one commit, even if it touches 15 files.
- DO NOT send `local_only` content to cloud LLM APIs under any circumstances.
- DO NOT link to the same page more than once in a single page body. Link on first mention only.

## 4. Page Types and Templates

Six page types exist. Each has a defined purpose, section order, and frontmatter requirements.

### 4.1 Entity (`type: entity`)

**Purpose:** People, tools, organizations, specific named things.

**Section order:** TL;DR -> Key Facts -> Detail -> Related Pages -> Sources

**When to use:** The subject has a proper name and is a concrete thing (not an abstract idea).

**Example:** Geoffrey Hinton. Demonstrates minimal aliases (single "Geoff Hinton"), mixed-locator Key Facts (bare `sec:`, `sec:` + `direct`, and `sec:` + `direct` + `checked_at`), and the Related-Pages link-on-first-mention convention.

See: schema/examples/entity.md for a concrete filled-in instance.

### 4.2 Concept (`type: concept`)

**Purpose:** Ideas, theories, frameworks, abstract topics.

**Section order:** TL;DR -> Key Facts -> Detail -> Related Pages -> Sources

**When to use:** The subject is an abstract idea, theory, methodology, or framework -- not a specific named entity.

**Example:** Attention Mechanism. Demonstrates multi-source sourced claims (two sources in frontmatter), three-locator-shape Key Facts (`sec:introduction`, `sec:self-attention`, `p5`), and Related-Pages cross-referencing to entity and concept siblings.

See: schema/examples/concept.md for a concrete filled-in instance.

### 4.3 Source Summary (`type: source`)

**Purpose:** One summary page per ingested source document. Links the raw source to the wiki.

**Section order:** TL;DR -> Key Takeaways -> Extracted Claims -> Notes -> Source Metadata

**When to use:** Every time a source is ingested, a source summary page is created in `wiki/sources/`.

**Additional frontmatter fields** (beyond the base set):

| Field | Type | Description |
|-------|------|-------------|
| `path` | string | Path to raw source file in `sources/` |
| `url` | string | Original URL if applicable |
| `content_hash` | string | SHA-256 hash for staleness detection |
| `ingested_at` | date | When the source was processed |
| `source_type` | enum | `article`, `paper`, `transcript`, `journal`, `data`, `image` |

**Example:** "Vaswani et al. - Attention Is All You Need" (`type: source`, `source_type: paper`; filename `schema/examples/source-summary.md` matches the `schema/templates/` sibling — readers should NOT expect `schema/examples/source.md`). Demonstrates full population of `path` / `url` / `content_hash` / `ingested_at` / `source_type`, Extracted Claims with direct-quote provenance, and the Source Metadata authors / published block.

See: schema/examples/source-summary.md for a concrete filled-in instance.

### 4.4 Comparison (`type: comparison`)

**Purpose:** Contrasting sources, viewpoints, approaches, or technologies.

**Section order:** TL;DR -> Bottom Line -> Comparison Table -> Detailed Comparison -> Sources

**When to use:** When two or more subjects need structured side-by-side analysis.

**Example:** RNNs vs Transformers. Demonstrates the Bottom Line + Comparison Table + Detailed Comparison three-tier structure, mixed-source `sources` list in frontmatter, and domain-spanning dimension rows.

See: schema/examples/comparison.md for a concrete filled-in instance.

### 4.5 Overview (`type: overview`)

**Purpose:** High-level topic summaries that synthesize across multiple sources and pages.

**Section order:** TL;DR -> Key Facts -> Detail -> Related Pages -> Sources

**When to use:** When a broad topic needs a synthesis page that ties together multiple entities, concepts, and sources.

**Example:** Deep Learning. Demonstrates synthesis across 3 sources (frontmatter list + body provenance), four-claim Key Facts with domain-internal wikilinks to entity and concept siblings, and Related-Pages as a navigation hub.

See: schema/examples/overview.md for a concrete filled-in instance.

### 4.6 Decision (`type: decision`)

Decision records capture why structural changes were made to the wiki. They answer the question: "Why is the wiki shaped this way?" Create a decision record when future-you would reasonably ask that question.

**When to use:**

- Page merges or splits
- Schema updates (new fields, changed conventions)
- Domain reorganization (moving pages between categories)
- Significant reframing of a concept or topic
- Major supersession (SUPERSEDE of a key page or concept)
- Contradiction-resolution decisions (structural resolution, not the contradiction itself)

**Directory:** `wiki/decisions/`

**File naming:** `dr-YYYY-MM-DD-slug.md`. The `dr-` prefix prevents ID collisions with other page types. The date provides natural chronological sorting. The slug provides human readability.

**ID convention:** Same as filename without `.md` extension: `dr-YYYY-MM-DD-slug`. Use lowercase, hyphen-separated slugs. The ID is used in `decision_history` on affected pages.

**Frontmatter (in addition to base fields):**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `trigger_type` | enum | Yes | One of: `merge`, `split`, `schema-update`, `domain-reorg`, `reframing`, `contradiction-resolution` |
| `affected_pages` | list | Yes | YAML list of page IDs (the `id` field value) of pages affected by this decision. Empty list `[]` is valid for inaugural or infrastructure-only records. |

**Section ordering (all required):**

1. ## TL;DR
2. ## Decision
3. ## Why -- Must state what framing was adopted and what it replaced.
4. ## Alternatives Considered -- Must list alternatives and why they were rejected.
5. ## Consequences
6. ## Affected Pages -- Wikilinks to affected pages with how each was affected.
7. ## Sources

**Epistemic pattern:** Decision records use `epistemic_status: sourced` (the decision itself is the source of truth). They do NOT participate in staleness tracking or contradiction detection -- a decision is a historical fact, not a claim that can become stale.

**`decision_history` back-link:** Pages affected by a decision gain a `decision_history` field in their frontmatter -- a YAML list of decision record IDs. This field is optional (not part of BASE_FIELDS); it is added when the first decision references a page. A visible "Decision History" section in the page body is optional -- include only when the history is meaningful for readers.

**Example:** Introduce Decision Record Page Type (`dr-2026-04-14-phase6-decision-type`). Demonstrates `trigger_type: schema-update` classification, empty `affected_pages: []` for an infrastructure record, and the Why-section-names-replaced-framing pattern.

See: schema/examples/decision.md for a concrete filled-in instance.

## 5. Frontmatter Schema

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
privacy: local_only|cloud_safe     # Privacy routing tier
aliases:                           # Alternative names for Obsidian resolution
  - Alternate Name
has_contradictions: false       # true when page contains [contradiction:...] markers
knowledge_domain: ""            # Primary decay-rate bucket (maps to Section 6 decay table)
example: false                  # Optional; true for reference-only pages (examples/). Lint skips these.
---
```

### Field Descriptions

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Unique identifier in kebab-case. Used in `sources` lists and `[prov:]` markers. Must match the filename (without `.md`). |
| `title` | string | Human-readable canonical title. Wikilinks resolve to this value. |
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
| `privacy` | enum | `local_only` (never send to cloud APIs) or `cloud_safe` (can be sent to cloud APIs). |
| `aliases` | list | Alternative names for Obsidian automatic resolution. Obsidian resolves `[[Alias]]` to the canonical page. |
| `has_contradictions` | boolean | `true` when any claim on the page has a `[contradiction:...]` marker. Independent of `epistemic_status` -- a `sourced` page can have contradictions. May be set by lint workflow OR by any workflow that inserts contradiction markers (ingest, query). The lint mechanically syncs this field: if `[contradiction:]` markers exist in the body, `has_contradictions` MUST be `true`; if no markers exist, it MUST be `false`. |
| `example` | boolean | Optional (default `false`). When `true`, the page is a reference-only example (e.g., pages under `examples/kahneman/`). Lint MUST skip these pages for health checks so illustrative content does not trigger warnings. Applies anywhere in the tree, not just under `examples/`. |
| `knowledge_domain` | string | Primary knowledge domain for staleness decay rate calculation. This is the **staleness policy bucket**, distinct from the `domains` field which is a topical classification list. A page may have `domains: [psychology, economics]` but `knowledge_domain: science` because both topics decay at the science rate. Maps to the decay rate table in Section 6. One of: `software`, `science`, `biography`, `personal-goals`, or a custom domain. Empty string if not yet classified. |
| `bootstrap_stage` | enum | Brownfield onboarding sentinel. Values: `raw | bootstrapped | verified`. Page-level marker tracking migration state from pre-existing Obsidian vault content into the schema. **NOT a substitute for claim-level provenance (see §6 PROV-01..05)** — the authoritative provenance mechanism remains claim-level `[prov::...]` markers + source summary pages. Written by `bin/brownfield.sh bootstrap` (Phase 10); stripped by `bin/ingest.sh` on normal ingest to prevent pollution. Absent from greenfield pages. See `§11.5 Brownfield Workflow` (populated in Phase 11). |
| `bootstrap_date` | date | ISO 8601 `YYYY-MM-DD` stamp (UTC) recording when `bin/brownfield.sh bootstrap` injected `bootstrap_stage: bootstrapped` on this page. Read by `bin/lint.sh` `brownfield` category for the 30-day staleness warning (BRWN-09). Written alongside `bootstrap_stage`; stripped by `bin/ingest.sh` on normal ingest. |

### Source Summary Additional Fields

Source summary pages (`type: source`) include these additional frontmatter fields:

```yaml
path: sources/YYYY/YYYY-MM/YYYY-MM-DD-slug/source.md
url: "https://..."                  # Original URL if applicable
content_hash: "sha256:abc123..."    # SHA-256 hash for staleness detection
ingested_at: YYYY-MM-DD            # When source was processed
source_type: article|paper|transcript|journal|data|image

# Compilation tracking
compilation_status: pending         # pending | partial | compiled | stale
compiled_against_hash: ""           # SHA-256 of source content at last compilation
compiled_targets: []                # Wiki page IDs that received compiled claims
```

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

1. All base fields are present (id, title, type, status, summary, created_at, updated_at, sources, epistemic_status, tags, domains, supersedes, superseded_by, privacy, aliases)
2. `type` is one of: `entity`, `concept`, `source`, `comparison`, `overview`, `decision`
3. `status` is one of: `active`, `stale`, `superseded`, `archived`
4. `epistemic_status` is one of: `sourced`, `mixed`, `tentative`, `stale`
5. `privacy` is one of: `local_only`, `cloud_safe`
6. `created_at` and `updated_at` match ISO 8601 pattern `YYYY-MM-DD`
7. `sources` is a YAML list of string IDs, NOT wikilinks
8. `tags` and `domains` are YAML lists of lowercase kebab-case strings
9. `summary` is a single quoted string, not multi-line
10. `id` matches the filename (without `.md` extension)
11. For `type: source` pages: `path`, `content_hash`, `ingested_at`, and `source_type` are present
12. For `type: source` pages: `compilation_status` is one of: `pending`, `partial`, `compiled`, `stale`
13. `has_contradictions` is a boolean (`true` or `false`)
14. `knowledge_domain` is a non-empty string for pages with provenance-backed claims
15. For `type: decision` pages: `trigger_type` is one of: `merge`, `split`, `schema-update`, `domain-reorg`, `reframing`, `contradiction-resolution`
16. For `type: decision` pages: `affected_pages` is present and is a YAML list of string IDs
17. If `decision_history` is present on any page: it is a YAML list of string IDs

## 6. Provenance, Epistemics, and Staleness

### Inline Provenance Syntax

Every factual claim in wiki pages SHOULD have an inline provenance marker linking it to a specific location in a source.

**Basic form:**

```
[prov:<source_id>#<locator>]
```

**Extended form (with support type and verification date):**

```
[prov:<source_id>#<locator>|<support_type>|<checked_at>]
```

### Locator Types

| Locator | Format | Example | Use for |
|---------|--------|---------|---------|
| Page range | `#p<start>-<end>` or `#p<page>` | `#p12-14`, `#p8` | PDFs, papers |
| Section | `#sec:<name>` | `#sec:introduction` | Markdown sections |
| Paragraph | `#para<number>` | `#para3` | Specific paragraphs |
| Timestamp | `#t<start>-<end>` | `#t00:12:10-00:12:48` | Audio/video transcripts |
| Image | `#img<number>` | `#img2` | Figures, diagrams |

### Support Types

| Type | Meaning |
|------|---------|
| `direct` | Claim is directly stated in the source |
| `inferred` | Claim is logically inferred from source content |
| `tentative` | Weak evidence; claim may not hold |
| `derived` | Synthesized from multiple parts of the source or across sources |

### Checked At

The `checked_at` field records the ISO 8601 date when the provenance link was last verified against the source. This enables staleness detection: if the source's `content_hash` has changed since `checked_at`, the claim should be reviewed.

### Examples in Context

```markdown
- Attention mechanisms allow models to focus on relevant input tokens [prov:src-2026-03-15-vaswani-attention#sec:introduction|direct|2026-04-08]
- The model achieves 28.4 BLEU on WMT 2014 English-to-German [prov:src-2026-03-15-vaswani-attention#p8|direct|2026-04-08]
- Hinton expressed concerns about AI safety risks [prov:src-2026-03-20-hinton-interview#t00:12:10-00:12:48|direct|2026-04-08]
- The learning rate schedule uses warmup followed by inverse square root decay [prov:src-2026-03-15-vaswani-attention#sec:training|direct|2026-04-08]
- RNNs struggle with long-range dependencies due to vanishing gradients [prov:src-2026-04-02-lstm-survey#sec:limitations|direct|2026-04-08]
```

### Bad vs. Good Provenance Examples

```
BAD:  Attention is important.
GOOD: Attention mechanisms allow models to focus on relevant input tokens [prov:src-2026-03-15-vaswani-attention#sec:introduction|direct|2026-04-08]

BAD:  [prov:vaswani] (missing locator, wrong source ID format)
GOOD: [prov:src-2026-03-15-vaswani-attention#sec:introduction]

BAD:  [prov:src-2026-03-15-vaswani-attention#page8] (invalid locator format)
GOOD: [prov:src-2026-03-15-vaswani-attention#p8] (correct: #p prefix for pages)

BAD:  [prov:src-2026-03-15-vaswani-attention] (no locator at all)
GOOD: [prov:src-2026-03-15-vaswani-attention#sec:abstract] (always include a locator)
```

### Source Registry

Each source summary page in `wiki/sources/` serves as the registry entry for that source. Its frontmatter contains: `id` (the source_id), `path`, `title`, `source_type`, `url`, `content_hash`, `ingested_at`.

This is the Dataview-native approach -- query source metadata with:

```dataview
TABLE source_type, ingested_at, content_hash
FROM "wiki/sources"
WHERE status = "active"
SORT ingested_at DESC
```

No separate registry file is needed. Source summary pages ARE the registry.

### Provenance Validation Rules

1. Every `[prov:...]` reference MUST resolve to a known source ID in `wiki/sources/`.
2. Every locator MUST be syntactically valid (matches one of the defined patterns above).
3. If a source's `content_hash` has changed since `checked_at`, dependent claims SHOULD be reviewed and the page's `epistemic_status` SHOULD be set to `stale`.
4. The lint workflow checks these rules automatically.

### Inline Epistemic Markers

Per-claim epistemic status uses Dataview inline field syntax, separate from provenance markers.

**Syntax:** `[epistemic:: <status>]`

**Valid statuses:**

| Status | Meaning | When to use |
|--------|---------|-------------|
| `sourced` | Directly from a source | Verbatim or close paraphrase with provenance |
| `inferred` | Synthesized from source(s) | Logical conclusion not explicitly stated in any single source |
| `tentative` | Weak or contested evidence | Claim may not hold; flag for review |
| `stale` | Likely outdated | Source has changed, finding superseded, or claim is time-sensitive |

Queryable via Dataview:

```dataview
TABLE file.name
FROM "wiki"
FLATTEN file.lists.text as item
WHERE contains(item, "[epistemic:: tentative]")
```

### Page-Level vs Claim-Level Epistemic Status

- **Page-level:** `epistemic_status` frontmatter field (Section 5). Reflects overall page evidence quality: `sourced`, `mixed`, `tentative`, or `stale`.
- **Claim-level:** Inline `[epistemic:: <status>]` in body text. Applies to individual claims within a page.

A page with `epistemic_status: sourced` may contain individual `[epistemic:: inferred]` claims if the majority is directly sourced. Use `mixed` when the page has a significant proportion of non-sourced claims.

### Mixed Inline Grammar

Two inline syntaxes coexist intentionally in wiki page bodies. Do NOT normalize to a single syntax.

| Syntax | Purpose | Tool |
|--------|---------|------|
| `[prov:source_id#locator\|support_type]` | Traceability | grep, scripts |
| `[epistemic:: status]` | Confidence discovery | Dataview |

**Combined pattern:** `Claim text. [prov:source_id#locator|support_type] [epistemic:: status]`

Not every claim needs both markers. Provenance is omitted when there is no specific source. Epistemic status is recommended on all factual claims.

### Domain-Based Decay Rate Table

Claims inherit temporal relevance from their source publication dates. Different knowledge domains decay at different rates. The lint workflow uses this table to flag stale claims mechanically.

| Domain | Base Decay Period | Rationale |
|--------|-------------------|-----------|
| `software` | 180 days (6 months) | Libraries, APIs, and tooling change rapidly |
| `science` | 730 days (2 years) | Replication and meta-analysis cycles |
| `biography` | 1825 days (5 years) | Biographical facts change slowly |
| `personal-goals` | 90 days (3 months) | Goals evolve with life circumstances |
| (default) | 365 days (1 year) | Fallback for unclassified domains |

**Epistemic status modifiers** (per D-08): Tentative and inferred claims decay faster than their domain default. Multiply the base decay period by the modifier:

| Epistemic Status | Modifier | Effect |
|------------------|----------|--------|
| `sourced` | 1.0 | Base rate |
| `mixed` | 0.85 | 15% faster decay |
| `inferred` | 0.75 | 33% faster decay |
| `tentative` | 0.5 | Twice as fast decay |

**Hash override** (per D-09): If a source page's `content_hash` differs from `compiled_against_hash`, ALL claims linked to that source via `[prov:]` markers are immediately stale regardless of decay window.

**Date fallback chain** for staleness calculation: When `checked_at` is missing from a provenance marker, use (in order): (1) the source page's `ingested_at` date, (2) the wiki page's `updated_at` date.

### Contradiction Inline Syntax

When two different sources assert conflicting claims about the same subject/attribute (per D-01), the contradiction is flagged inline on the affected claim(s):

```
[contradiction:source_a_id#locator vs source_b_id#locator]
```

Example:

```markdown
<CONCEPT_NAME_2> coefficient is approximately 2.0 [prov:<source-slug>#sec:core-findings|direct|2026-04-10] [contradiction:<source-slug>#sec:core-findings vs <source-slug-2>#sec:results]
```

Rules:
- Contradiction markers sit alongside provenance markers on the affected claim
- Both source references in the contradiction marker MUST resolve to known sources in `wiki/sources/`
- The lint does NOT decide which source is correct -- it surfaces the disagreement
- Pages with any contradiction marker must have `has_contradictions: true` in frontmatter (lint syncs this mechanically)
- Contradictions are severity: **warning** (source disagreement is expected in scholarship)
- Semantic conflicts without provenance grounding are out of scope for v1 (per D-02)

See: examples/kahneman/concepts/loss-aversion.md for a concrete filled-in instance.

### Staleness Auto-Fix Rules

The lint workflow applies mechanical staleness fixes (per D-12):

**Claim-level auto-fix:** When a claim's provenance date exceeds its domain decay threshold (adjusted by epistemic modifier), the lint adds `[epistemic:: stale]` after the claim's provenance marker cluster. Rules for marker placement:
- One `[epistemic:: stale]` marker per claim -- do not duplicate if already present
- Place immediately after the last `[prov:...]` marker on the claim line
- If the claim already has `[epistemic:: sourced]` or `[epistemic:: inferred]`, replace it with `[epistemic:: stale]`
- A "claim" is defined as a single bullet point or paragraph containing `[prov:]` markers
- This operation is deterministic and reversible (removing the stale marker restores prior state)

**Page-level status:** The lint only auto-updates page-level `epistemic_status` to `stale` when the rollup clearly warrants it (per D-13): all material claims are stale, OR the TL;DR/Key Facts section contains materially stale claims. Default: do NOT auto-change page-level status.

**Logging:** All auto-fix staleness changes are logged in `wiki/maintenance/lint-report.md` and `wiki/log.md` (per D-14).

## 7. Progressive Disclosure

**Principle:** All wiki pages are structured shallow-to-deep. The top of every page is optimized for fast LLM scanning; the bottom is for human verification and deep reading.

### Rules for LLM Agents

1. When searching for information, read `wiki/index.md` FIRST.
2. Scan `## TL;DR` and `## Key Facts` sections of relevant pages BEFORE reading `## Detail` sections.
3. Only read `## Detail` and `## Sources` sections when shallow sections are insufficient to answer the question.
4. When creating pages, `## TL;DR` MUST be 1 short paragraph or 2-4 bullets.
5. `## Key Facts` MUST be compact bullets with inline provenance markers.
6. `## Detail` contains full narrative, synthesis, caveats, and nuance.
7. `## Sources` at the bottom lists human-readable source references with wikilinks to source summary pages.

### Per-Type Section Ordering

| Page Type | Section Order |
|-----------|--------------|
| Entity | TL;DR -> Key Facts -> Detail -> Related Pages -> Sources |
| Concept | TL;DR -> Key Facts -> Detail -> Related Pages -> Sources |
| Source Summary | TL;DR -> Key Takeaways -> Extracted Claims -> Notes -> Source Metadata |
| Comparison | TL;DR -> Bottom Line -> Comparison Table -> Detailed Comparison -> Sources |
| Overview | TL;DR -> Key Facts -> Detail -> Related Pages -> Sources |

See Section 4 for fully worked examples of each type.

### Why This Matters

An LLM processing a query about "attention mechanisms" should be able to:
1. Read `wiki/index.md` to find `wiki/concepts/attention-mechanism.md` (seconds)
2. Read its `## TL;DR` to confirm relevance (seconds)
3. Read `## Key Facts` for specific claims with provenance (seconds)
4. Only read `## Detail` if the above is insufficient (more expensive)

This structure means the LLM reads the minimum necessary context for each query, preserving context window for synthesis and reasoning.

## 8. Wikilink and Graph Conventions

### Rules

1. Use `[[Exact Page Title]]` for all cross-references in page body text.
2. Link on FIRST mention only per page. Subsequent mentions are plain text.
3. DO NOT use display aliases: write `[[Attention Mechanism]]` not `[[Attention Mechanism|attention]]`.
4. Use the `aliases` frontmatter field for alternate names. Obsidian resolves aliases to the canonical page automatically.
5. Red links (links to non-existent pages) are ALLOWED and intentional. They signal knowledge gaps for the lint workflow.
6. DO NOT put wikilinks in YAML frontmatter. Use string IDs in frontmatter, wikilinks in body text.
7. The `## Related Pages` section lists explicit wikilinks to connected pages.
8. The `## Sources` section in page body lists human-readable source references with wikilinks to source summary pages.

### Bad vs. Good Wikilink Examples

```
BAD:  sources: ["[[Vaswani et al]]"]           (wikilink in frontmatter)
GOOD: sources: [src-2026-03-15-vaswani-attention]  (string ID in frontmatter)

BAD:  [[Attention Mechanism|attention]]         (display alias -- breaks graph clarity)
GOOD: [[Attention Mechanism]]                   (exact title match)

BAD:  ...the [[Attention Mechanism]] uses [[Attention Mechanism]] weights...  (linked twice)
GOOD: ...the [[Attention Mechanism]] uses attention weights...  (linked once, plain text after)

BAD:  See [[attention]]                         (lowercase, non-canonical title)
GOOD: See [[Attention Mechanism]]               (exact canonical title from page frontmatter)
```

### Graph View Implications

- Only wikilinks in page body text appear reliably in Obsidian's graph view.
- String IDs in frontmatter do NOT create graph edges. This is intentional -- frontmatter holds structured data; body text holds navigable links.
- First-mention linking prevents link noise in the graph. A page that mentions "attention" 20 times creates only one graph edge to `[[Attention Mechanism]]`, not 20.
- Red links appear in the graph as unresolved nodes, providing a visual map of knowledge gaps.

## 9. Structured Operations and Executor Model

All wiki mutations use a formal operations vocabulary. Raw file rewrites are prohibited -- every change goes through one of these four operations with mandatory logging.

### Operations Vocabulary

| Operation    | Verb    | What It Does                                       |
|-------------|---------|---------------------------------------------------|
| **UPDATE**  | Modify  | Add new information to an existing page            |
| **MERGE**   | Combine | Unify two pages covering the same concept          |
| **SUPERSEDE** | Replace | Mark a page/claim as replaced by newer information |
| **ARCHIVE** | Retire  | Move outdated content out of active wiki           |

### Operation Definitions

**UPDATE** -- Modify an existing page with new information.

1. Add new claims with provenance markers to the appropriate section of the existing page.
2. Preserve all existing provenance markers -- do not remove or overwrite them.
3. Add new source IDs to the `sources` list in frontmatter.
4. Update `updated_at` in frontmatter to today's date.
5. If new claims change the evidence balance, update `epistemic_status` accordingly.
6. Log: `"UPDATE <page_id>: <one-line rationale>"`

For the full incremental update policy governing how new claims integrate with existing content during ingestion, see Section 10 Pass 3 (Append-Then-Synthesize).

**MERGE** -- Combine two pages covering the same concept.

1. Create a new merged page with the union of claims from both pages, preserving all provenance markers.
2. Set `supersedes` on the new page to list both merged page IDs.
3. Set `superseded_by` on both old pages to point to the new page ID.
4. Set `status: superseded` on both old pages.
5. Replace the body of both old pages with a brief redirect note: `> This page has been merged into [[New Page Title]].`
6. Update `wiki/index.md`: add the new page, move old pages to "Archived" section (if one exists) or remove them from active listings.
7. Log: `"MERGE <page_a> + <page_b> -> <new_page>: <rationale>"`
7a. **Decision record (inline -- Tier 1):** If this merge represents a significant structural choice -- combining two established pages, resolving a long-standing organizational ambiguity, or eliminating a redundant page that multiple other pages linked to -- create a decision record page in `wiki/decisions/` with `trigger_type: merge` and `affected_pages` listing both original page IDs and the new merged page ID. Add the new decision record to `wiki/index.md` under Decisions. Commit the decision record as part of this same commit. **Skip for trivial cleanup merges** (e.g., merging a stub into its parent when the stub has no unique claims). See Section 11.4, Tier 1.

**SUPERSEDE** -- Mark a page or claim as replaced by newer information.

1. Set `superseded_by` on the old page to the replacing page's ID.
2. Set `status: superseded` on the old page.
3. Add a note at the top of the old page body: `> This page has been superseded by [[New Page Title]].`
4. On the new page, set `supersedes` to the old page's ID.
5. Update `wiki/index.md`: move the old page to "Archived" section or remove from active listings.
6. Log: `"SUPERSEDE <old_page> -> <new_page>: <rationale>"`
6a. **Decision record (inline -- Tier 1):** If this supersession replaces a key page or represents a significant editorial judgment -- the new page substantially reframes the concept, or the superseded page was widely linked -- create a decision record page in `wiki/decisions/` with `trigger_type: reframing` (if the new page reframes the concept) or `trigger_type: merge` (if consolidating). Set `affected_pages` to include both old and new page IDs. Add to `wiki/index.md` under Decisions. Commit as part of this same commit. **Skip for routine stale-claim supersessions** (e.g., updating a fact to a newer version without reframing). See Section 11.4, Tier 1.

**ARCHIVE** -- Move outdated content out of active wiki.

1. Set `status: archived` on the page.
2. Remove the page from `wiki/index.md` active listings (move to an "Archived" section if one exists).
3. The page remains in its directory -- do NOT delete or move files.
4. Log: `"ARCHIVE <page_id>: <rationale>"`

### Executor Model

The LLM proposes operations. Before applying any operation, it MUST validate:

1. **Target exists:** For UPDATE, SUPERSEDE, and ARCHIVE, the target page must exist.
2. **Both pages exist and are distinct:** For MERGE, both source pages must exist and must not be the same page.
3. **Provenance resolves:** All `[prov:...]` references in new content must resolve to known source IDs in `wiki/sources/`.
4. **Frontmatter is valid:** All required base fields are present and correctly typed (see Section 5 validation checklist).
5. **Privacy is respected:** No `local_only` content is included in operations that will be sent to cloud APIs.

If validation fails, the LLM MUST NOT apply the operation. Instead, log the validation failure and report it to the user.

Every operation MUST be logged in `wiki/log.md` with: timestamp, operation type, affected page(s), and rationale. See Section 12 for log format.

#### Deterministic Enforcement

In addition to LLM self-validation, a deterministic bash validator provides mechanical enforcement:

```
bin/validate-op.sh <OPERATION> <target_path> [<second_path>]
```

The LLM MUST run `bin/validate-op.sh` before applying any operation. The validator performs the same 5 checks listed above using file system inspection and YAML parsing — no LLM judgment involved. If the validator returns FAIL, the operation MUST NOT be applied.

**Batch validation:** When a workflow proposes multiple operations (e.g., an ingest that UPDATEs several pages), validate ALL operations before applying ANY. If any single validation fails, abort the entire batch. This prevents partial application of interdependent changes.

#### Per-Operation Preconditions and Postconditions

Each operation type has specific rules beyond the 5 global checks:

**UPDATE**
- Precondition: Target page exists and has `status: active` (do not UPDATE archived or superseded pages — un-archive or un-supersede first).
- Postcondition: `updated_at` field is set to today's date. `sources` list includes any new source IDs. Provenance markers are added for new claims.
- Privacy: If new content derives from `local_only` sources but target is `cloud_safe`, STOP — see Section 13 and query workflow Section 11.2 privacy rules.

**MERGE**
- Precondition: Both pages exist, are distinct, and both have `status: active`.
- Postcondition: One surviving page contains the combined content. The other page has `status: superseded` and `superseded_by` set to the surviving page's ID. `sources` lists from both pages are merged (union). All provenance markers from both pages are preserved.
- Privacy: If either source page is `local_only`, the surviving page MUST be `local_only`.

**SUPERSEDE**
- Precondition: Target page exists, has `status: active`, and `superseded_by` is empty/null.
- Postcondition: Target page has `status: superseded` and `superseded_by` set to the replacing page's ID. The replacing page has `supersedes` set to the target's ID.
- Note: The replacing page must already exist or be created in the same batch.

**ARCHIVE**
- Precondition: Target page exists and has `status: active` (do not archive already-archived pages).
- Postcondition: Target page has `status: archived`. `updated_at` set to today's date. Page remains in its directory but is excluded from active index queries.
- Note: Archive is reversible — change `status` back to `active` to un-archive.

## 10. Compiler Pipeline (Conceptual Model)

This section describes the conceptual compilation model -- the state machine that source material passes through on its way into the wiki. Section 11 (Workflows) provides the step-by-step operator procedures that implement this model.

The pipeline is a multi-pass process for ingesting a source document:

```
Source -> [Classify] -> [Diff] -> [Extract] -> [Merge] -> [Lint] -> Wiki
```

### Pass 0: Classify

Determine the source type before processing.

- **Input:** Raw source document.
- **Types:** article, paper, book-chapter, transcript, journal entry, data file, image-heavy.
- **Note:** `book-chapter` is the canonical source type for book content. Full books MUST be ingested as a sequence of `book-chapter` sources (one per chapter or coherent section). Historical note: some older source summaries used `source_type: book`; that value has been normalized to `book-chapter`. Agents MUST use `book-chapter` going forward; `book` is no longer accepted.
- **Purpose:** Different source types require different extraction logic (e.g., papers have abstract/methodology/results; transcripts have timestamped segments).
- **Output:** Source type classification, passed to Pass 2 for type-appropriate extraction.

### Pass 1: Diff

Compare the new source against current wiki state.

- **Input:** Source document + current wiki state (via `wiki/index.md`).
- **Process:** Read `wiki/index.md` to identify existing pages on related topics. Read the TL;DR and Key Facts of those related pages. Determine what the new source adds that the wiki does not already cover.
- **Output:** A mental model of new vs. existing knowledge. This is not a file -- it is the LLM's internal understanding of the delta.

### Pass 2: Extract

Pull structured knowledge from the source.

- **Input:** Source document + type classification from Pass 0.
- **Process:** Apply type-appropriate extraction. Papers get abstract, methodology, results, and conclusions. Transcripts get timestamped claims. Journal entries get reflections and decisions. Extract claims, entities, and relationships, each with a provenance locator (`[prov:source_id#locator]`).
- **Output:** A source summary page created in `wiki/sources/<source_id>.md` with full frontmatter (including `path`, `content_hash`, `ingested_at`, `source_type`) and all extracted claims with provenance.

#### Claim Granularity Rules

Source classification (Pass 0) drives extraction depth. The guiding heuristic: **"the smallest unit that preserves meaningful provenance without making the page unreadable."**

| Source Type | Default Granularity | Guidance |
|-------------|-------------------|----------|
| article, paper, report, technical doc | Atomic claims | One provenance marker per distinct assertion. Split when a paragraph contains multiple independently important assertions. |
| book-chapter, essay | Atomic for factual/conceptual claims; paragraph-level for broader interpretive passages | Important factual claims get individual provenance. Interpretive or argumentative passages that form a single coherent point stay grouped. |
| transcript, meeting notes, journal entry | Paragraph-level or utterance-level clusters | Group by natural conversation turns or reflection units. Individual sentences rarely stand alone as claims. |
| image-heavy, mixed media | Tied to specific image, caption, or observation | Each image or visual element that contributes a distinct claim gets its own provenance marker referencing the image locator. |

**Bias toward atomic:** Across all source types, prefer atomic granularity for durable factual and conceptual claims. The split/group decision:
- **Split** when a paragraph contains multiple independently important assertions that future readers might cite separately.
- **Keep grouped** when a passage is only useful as one bundled observation and splitting would lose context.

### Pass 3: Merge

Integrate extracted knowledge into the wiki.

- **Input:** Extracted claims + current wiki pages.
- **Process:**
  - UPDATE existing pages with new claims (using the UPDATE operation from Section 9).
  - Create new pages for entities or concepts not yet in the wiki, using the appropriate page type template (Section 4).
  - Generate wikilinks between related pages (first mention only, per Section 8).
  - MERGE pages if the new source reveals that two existing pages cover the same topic (using the MERGE operation from Section 9).
- **Output:** Updated and/or new wiki pages with provenance-tracked claims and cross-references.

#### Incremental Update Policy: Append-Then-Synthesize

The default policy for living wiki pages (entities, concepts, overviews, comparisons):

1. **Append in the detail layer:** Add new claims into the appropriate detail sections, preserving all existing material. Never silently delete existing claims. Insert new claims at the end of the relevant section with their provenance markers.
2. **Mark superseded or stale claims per current schema conventions:** When new information contradicts or replaces an existing claim, mark the old claim as superseded or stale using the epistemic and provenance syntax currently documented in the schema (see Section 6), and add a short note pointing to the superseding claim. Never remove the old claim -- the provenance trail must remain visible. Phase 5 will formalize the exact contradiction and staleness semantics; until then, follow current schema conventions and keep the old claim visible.
3. **Re-synthesize the summary layer:** After appending new detail, rewrite the TL;DR and Key Facts sections so they reflect the complete current state of the page -- all claims, old and new. This is the only place where rewriting is expected on every update.
4. **Record framing shifts:** If new material fundamentally changes a page's framing or interpretation, record the shift in a decision/reflection entry (see Section 11.4) rather than hiding it inside prose edits.

**Exceptions:**
- **Logs and source summary pages:** Strict append-only. These are records, not living synthesis. Never rewrite existing log entries or source summary content.
- **Full section rewrite:** Reserved for exceptional cases only -- severe page drift, extensive duplication, or fundamentally broken earlier structure. When performed, log the rationale as a decision record.

**Mantra:** "Append in the detail layer, synthesize in the summary layer, supersede explicitly when needed."

### Pass 4: Lint

Verify consistency after merge.

- **Input:** All pages modified or created during this ingest.
- **Checks:**
  - All new `[prov:...]` markers resolve to valid source IDs in `wiki/sources/`.
  - All new wikilinks point to existing pages or are intentional red links.
  - Frontmatter is complete and valid on all modified pages (Section 5 checklist).
  - No contradictions between new claims and existing claims on the same topic.
- **Output:** List of issues found (if any). Trivially fixable issues (e.g., missing frontmatter fields) are fixed inline. Non-trivial issues are reported.

### Optional Follow-On Passes

These are not required on every ingest:

- **Summary regeneration:** Rewrite TL;DR and Key Facts sections of affected pages to reflect new information.
- **Image processing:** Extract information from figures, diagrams, or images in the source.
- **Structural reorganization:** Split pages that have grown too large, or reorganize domain sections.

## 11. Workflows

These are the operator procedures that implement the conceptual pipeline (Section 10). Each workflow is a complete recipe an LLM agent follows step-by-step. The pipeline describes WHAT conceptually happens; workflows describe HOW to do it.

### 11.1 Ingest Workflow

```
Trigger:  User places a new source document and requests ingestion
Inputs:   Source file at sources/YYYY/YYYY-MM/YYYY-MM-DD-slug/ (bundle) or .md (single file)
Outputs:  Source summary page, updated wiki pages, updated index, updated log
Commit:   ingest(<source-slug>): <one-line summary>
```

**Steps:**

1. User places source document in `sources/YYYY/YYYY-MM/YYYY-MM-DD-slug/` (bundle with `source.md` + assets) or `sources/YYYY/YYYY-MM/YYYY-MM-DD-slug.md` (single file).
2. LLM reads the source document completely.
3. **Classify** (Pipeline Pass 0): Determine source type -- article, paper, transcript, journal entry, data file, or image-heavy.
4. **Diff** (Pipeline Pass 1): Read `wiki/index.md`, identify related existing pages, read their TL;DR and Key Facts sections. Determine what this source adds that the wiki does not already cover.
5. **Extract** (Pipeline Pass 2): Extract claims with provenance locators, applying the claim granularity rules from Section 10 Pass 2 based on the source type classified in step 3. Create source summary page at `wiki/sources/<source_id>.md` with full frontmatter including `path`, `content_hash`, `ingested_at`, and `source_type`.
6. **Merge** (Pipeline Pass 3): Update or create entity/concept/overview pages using UPDATE operations (Section 9) and the append-then-synthesize policy (Section 10 Pass 3). Generate wikilinks on first mention. MERGE pages if the source reveals duplicates.
   - 6a. After merge is complete, update the source summary page's compilation tracking fields:
     - Set `compilation_status` to `compiled` if all extracted claims were merged into topic pages, or `partial` if some claims were deferred.
     - Set `compiled_against_hash` to the current `content_hash` value.
     - Set `compiled_targets` to the list of wiki page IDs that received claims from this source (page IDs only, not paths).
7. **Lint** (Pipeline Pass 4): Verify all provenance references resolve, wikilinks are valid, frontmatter is complete on all modified pages.
8. Update `wiki/index.md` with new and modified pages.
9. Append entry to `wiki/log.md`: `## [YYYY-MM-DD] ingest | <source title>` with affected pages and rationale.
    - 9a. **Contributor attribution (COLAB-03, COLAB-04):** If the log entry is produced via `bin/ingest.sh`, the helper resolves a contributor handle via the following order:
        1. Explicit `--contributor @handle` flag wins (forces emission even on single-author repos).
        2. On single-author repos (`git log --all --format='%ae' | sort -u | wc -l == 1`), the field is omitted entirely.
        3. Otherwise, look up `git config user.email` in `.git-author-map.txt` at the repo root (case-insensitive; format `email  ->  @handle`, `#` comments allowed). On hit, emit `contributor:: @handle` as a Dataview inline body field directly below the `## [YYYY-MM-DD]` log-entry header (see §12).
        4. On map miss, warn to stderr (actionable: suggest `--contributor @handle` or adding the mapping) and OMIT the field. NEVER write a bare email into the `contributor::` field (privacy hygiene + parser consistency).
      Git commit authorship remains the attribution source of truth; `contributor::` is a Dataview convenience index.
10. Commit: `ingest(<source-slug>): <one-line summary>`

**Abort conditions:**

- Source is unreadable or corrupted. Log failure in `wiki/log.md`, do NOT create partial wiki pages.
- Source duplicates an already-ingested source (check `content_hash` against existing source summary pages). Log the duplicate detection, do NOT re-ingest.
- Privacy classification cannot be determined. Default to `local_only` and log the classification gap.

### 11.2 Query Workflow

```
Trigger:  User asks a question about the wiki contents
Inputs:   User question (natural language)
Outputs:  Cited answer, optionally new/updated wiki pages, updated index/log
Commit:   query(<topic>): <one-line summary>
```

**Steps:**

1. **Search** -- Read `wiki/index.md` to find pages relevant to the question. Optionally use `bin/search.sh` to identify candidates.
2. **Shallow read** -- Read TL;DR and Key Facts sections of relevant pages (progressive disclosure -- shallow first).
3. **Deep read** -- Read Detail sections only where shallow content is insufficient to answer the question.
4. **Synthesize** -- Compose answer with citations to specific wiki pages and inline provenance markers.
5. **Write-back decision** -- Determine whether the answer should be written back to the wiki (see Write-Back Rules below).
6. **Delta compilation** -- Check for uncompiled or stale sources relevant to this query (see Delta Compilation below).
7. **Apply write-back** -- If write-back is triggered, apply using structured operations (Section 9). Run `bin/validate-op.sh` before applying each operation.
8. Update `wiki/index.md` if new pages were created or existing pages were significantly modified.
9. Append entry to `wiki/log.md` (see Query Log Entry Format below).
10. Commit (only if wiki was modified): `query(<topic>): <one-line summary>`

#### Write-Back Rules

Write-back is **mandatory** when the answer produces novel or durable synthesis. It is NOT optional -- queries that produce reusable knowledge MUST contribute back to the wiki.

**Write back when the answer produces at least one of:**
- A new claim not already captured in the wiki
- A new connection between existing pages or sources
- A meaningful reframing or synthesis of existing material
- A reusable artifact (comparison, overview, decision note)
- A correction to an existing page's framing or status

**Do NOT write back for:**
- Pure lookups of facts already present in the wiki
- Reformatted restatements of a single existing page
- Transient conversational answers with no durable value

**Page targeting:** Use page ownership, not query origin.
- If an existing page clearly owns the topic being synthesized, UPDATE that page.
- If no single page cleanly owns the synthesis, or the output is a distinct reusable artifact (comparison, overview, reflection), CREATE a new page.
- New pages are typed by semantic role (entity, concept, comparison, overview) -- NEVER by workflow origin. There is no "query result" page type.

#### Privacy Inheritance for Write-Back

**Deterministic rule (from Section 13, restated here for clarity):** If ANY source contributing to the synthesis has `privacy: local_only`, the write-back target page MUST have `privacy: local_only`. A page is only `cloud_safe` if ALL contributing sources are `cloud_safe`. This is not a judgment call -- it is a mechanical check.

**How to apply:**
1. Collect all source IDs referenced in the synthesized answer (from provenance markers and the `sources` frontmatter list of pages read).
2. Check each source's `privacy` field.
3. If ANY source is `local_only`, the write-back target is `local_only`.
4. If updating an existing `cloud_safe` page with `local_only`-derived content: STOP. Either (a) create a separate `local_only` page for the sensitive synthesis, or (b) change the existing page to `local_only` if appropriate.
5. Run `bin/validate-op.sh` -- it enforces this rule mechanically (Check 4).

#### Delta Compilation

Before or during answer synthesis, check whether relevant sources have uncompiled material:

1. Read source summary pages referenced by or related to the query topic.
2. Check `compilation_status` field (Section 5): if `pending`, `partial`, or `stale`, the source has uncompiled material.
3. **Query-scoped compilation (default):** Compile only claims from uncompiled sources that are relevant to the current question. Log remaining uncompiled material for later pickup.
4. **Full-source compilation (exception):** Only when the source is central to many pages, query-scoped extraction would be wasteful, or the user explicitly requests a fuller refresh.
5. After compiling, update the source summary page: set `compilation_status` to `compiled` (or `partial` if not all claims were compiled), update `compiled_against_hash`, and extend `compiled_targets`.

**Detecting uncompiled material:** Primary mechanism is the `compilation_status` field on source summary pages. Secondary verification: check whether source claims actually appear in target topic pages via provenance markers.

#### Query Log Entry Format

Append to `wiki/log.md`:

```markdown
## [YYYY-MM-DD] query | <question summary>

answer: <one-line summary of the answer>
write_back: <WRITE-BACK: trigger met -> UPDATE/CREATE page_id> OR <NO-WRITE-BACK: reason>
delta_compiled: <source_ids compiled, or "none">
pages_affected: <list of page IDs modified or created, or "none">
```

The write-back decision MUST be logged -- structured and terse, stating which trigger was met or why write-back was skipped. This enables auditing.

**Ordering:** The workflow executes linearly: (1) answer with citations, (2) delta compile if needed, (3) write back results. Write-back happens ONCE at the end, not recursively.

**Abort conditions:**

- No relevant pages exist AND no sources exist on the topic. Inform the user that the wiki has no information on this topic rather than hallucinating an answer. Log the knowledge gap in `wiki/log.md` so the lint workflow can track it.

#### Worked Example

**Question:** "What <OVERVIEW_NAME> are related to <CONCEPT_NAME_2>?"

1. **Search:** `bin/search.sh "<concept-slug-2>"` returns matching concept and overview pages under `wiki/concepts/`.
2. **Shallow read:** Read TL;DR of all three pages. `<concept-slug-2>.md` covers the core item. `<overview-slug>.md` lists item families. `<concept-slug>.md` frames the item within the broader concept.
3. **Deep read:** Read Detail section of `<overview-slug>.md` to find family relationships.
4. **Synthesize:** Answer cites all three pages with provenance markers.
5. **Write-back decision:** The answer connects `<concept-slug-2>` to specific families in a way not explicitly articulated in any single page. Trigger: "new connection between existing pages." Decision: UPDATE the relevant concept page to add a new subsection.
6. **Delta compilation:** Check sources. `<source-slug>.md` has `compilation_status: compiled`. No delta needed.
7. **Apply:** Run `bin/validate-op.sh UPDATE wiki/concepts/<page>.md` -> PASS. Apply UPDATE using append-then-synthesize policy.
8. **Index:** No new pages created, but `<concept-slug-2>.md` summary in index updated to reflect new subsection.
9. **Log:**
   ```
   ## [2026-04-15] query | What <OVERVIEW_NAME> are related to <CONCEPT_NAME_2>?

   answer: <CONCEPT_NAME_2> connects to several related families through shared mechanisms
   write_back: WRITE-BACK: new connection between existing pages -> UPDATE <concept-slug-2>
   delta_compiled: none
   pages_affected: <concept-slug-2>
   ```
10. **Commit:** `query(<concept-slug-2>): add related connections`

See: examples/kahneman/concepts/loss-aversion.md for a concrete filled-in instance.

### 11.3 Lint Workflow

```
Trigger:  User requests a health check, or periodically after several ingests
Inputs:   wiki/ directory (all pages)
Outputs:  Structured findings report, optionally fixed pages, updated log
Commit:   lint(<scope>): <one-line summary>
```

**Severity Tiers** (per D-17):

| Severity | Meaning | Examples |
|----------|---------|----------|
| `error` | Must fix -- broken references, invalid structure | Broken provenance refs, missing source pages, YAML parse failures, invalid frontmatter enum values |
| `warning` | Should fix -- quality degradation | Stale claims, orphan pages, contradictions, missing cross-references |
| `info` | Nice to know -- improvement opportunities | Knowledge gaps, sparse coverage, suggested questions |

**Auto-Fix Boundary** (per D-18, D-19):

Auto-fix (mechanical, deterministic, reversible): updating stale claim markers per decay table, syncing `has_contradictions` frontmatter boolean to match presence of `[contradiction:]` markers in body.

Report-only (no auto-fix): contradictions, knowledge gaps, orphan pages, missing cross-references, page restructuring, any fix requiring judgment.

#### CI mode (Phase 9)

> **Source of truth for Phase 9 CI contracts.** This section is the authoritative specification for: (a) the severity-remap dispatch table, (b) the `--format json` output schema, (c) the escape-hatch marker contract, and (d) the `--require-version` semantics. Other docs (`docs/reference/ci.md`, `CONTRIBUTING.md`, `.github/workflows/lint.yml` comments) MUST link here rather than restating the policy. Drift between this section and the shipped code is a Phase 9 regression.

`bin/lint.sh` supports a CI operating profile via several independent, orthogonal flags:

| Flag | Effect |
|------|--------|
| `--format json` | Emit JSON array `[{severity, category, path, line?, message}]` to stdout; do NOT write `lint-report.md`. |
| `--ci` | Apply severity-remap dispatch table: `yaml`/`orphan`/`crossref`/`provenance` -> `error`; `stale`/`gap`/`contradiction`/`contradiction-sync`/`drift`/`contributor` -> `warning`; `autofix`/`skip-count` -> `info`. Default-skip `drift-external` category. Exit 1 iff any post-remap finding has severity `error`. |
| `--skip-category <cat>` | Exclude one category. Repeatable. Inverse of `--category`. |
| `--strict` | Quality ratchet: fail on (a) new `[epistemic:: inferred]` / `[epistemic:: tentative]` claims without a matching decision record whose `affected_pages` frontmatter contains the page ID; (b) new (git-diff status `A`) pages of type `entity`/`concept`/`overview`/`comparison` with zero `[prov:` markers. Source pages and decision records are exempt by design. |
| `--require-version X.Y.Z` | Minimum-version pin. Fails if `LINT_VERSION < X.Y.Z`. Semver tuple comparison, not string. |
| `--version` | Print `LINT_VERSION` and exit 0. |
| `--count-skips` | Enumerate every `<!-- lint:expect-* -->` escape-hatch marker. Emits one `info`/`skip-count` finding per marker (human-review aid). |

**Escape-hatch marker syntax (`--strict` exemption):**

```
<!-- lint:expect-inferred id=<page-id> reason="<one line>" -->
<!-- lint:expect-tentative id=<page-id> reason="<one line>" -->
```

Placement rules (strict):

1. Marker MUST appear on the line IMMEDIATELY above the claim line -- no blank line between.
2. `id` MUST match the containing page's frontmatter `id` field.
3. `reason` is required and non-empty.
4. Exempted claims are emitted as severity `info`, category `skip-count` (visible in PR annotations as `::notice`, non-blocking).

**CI workflow reference:** `.github/workflows/lint.yml` invokes three jobs in parallel -- `lint`, `privacy-leak`, `strict` -- each a required check in branch protection. See `docs/reference/ci.md`.

**Steps:**

1. Read `wiki/index.md` for full page inventory. Build resolution map: for each wiki page, collect filename, id, title, and aliases (case-insensitive matching).
2. **YAML frontmatter validation:** Parse all page frontmatter, check required fields, validate enum values against Section 5 schema. Severity: error for parse failures or missing required fields.
3. **Provenance validation:** Verify all `[prov:]` references resolve to known source IDs in `wiki/sources/`. Verify locator syntax. Severity: error for broken refs.
4. **Orphan detection:** Find pages with no inbound wikilinks from other wiki pages (using resolution map for alias-aware, case-insensitive matching). Exclude index.md, log.md, lint-report.md. Severity: warning. Report-only.
5. **Missing cross-references:** Identify pages sharing 2+ domains AND 2+ tags that lack mutual wikilinks. Only flag for active pages (not archived/superseded). Severity: warning. Report-only.
6. **Stale claims:** Compute staleness using domain decay rate table (Section 6), epistemic modifier, and hash override. Date fallback chain: `checked_at` -> `ingested_at` -> `updated_at`. Severity: warning. Auto-fix: add/update `[epistemic:: stale]` markers per Staleness Auto-Fix Rules.
7. **Potential contradiction candidates:** Flag wiki page sections where claims carry `[prov:]` markers from 2+ different source_ids AND the section is NOT on a page of type `comparison` or `overview` (these are inherently multi-source by design). Mark as "potential contradiction candidates for agent review." The lint does NOT assert these ARE contradictions -- the LLM agent running the lint workflow reviews flagged sections and promotes confirmed disagreements to `[contradiction:]` inline markers. Severity: warning. Report-only.
8. **`has_contradictions` sync:** Verify that `has_contradictions` frontmatter matches actual presence of `[contradiction:]` markers in the body. Auto-fix: set `true` if markers present, `false` if no markers present.
9. **Knowledge gaps (red links):** Collect unresolved wikilinks. Flag when: appears on 2+ distinct pages, OR appears in TL;DR/Key Facts section of any page (per D-20). Severity: info. Report-only. Suggest investigative question per D-23.
10. **Source coverage gaps:** Compare domain source counts. Flag domains with materially fewer sources than median. Only run when wiki has 5+ distinct knowledge_domain values with at least 3 having 2+ source pages (maturity guardrail per D-22). Use `knowledge_domain` consistently for both page classification and source counting. Severity: info. Report-only. Suggest investigative question per D-23.
11. **Drift detection (category: `drift`):** Run cross-system drift checks. These detect misalignment between the wiki layer and its dependencies.
    - **Unrepresented sources (DRFT-01):** Walk `sources/` directory for `.md` files, check each has a corresponding wiki source summary page (matching the `path` field in source page frontmatter). Severity: warning.
    - **Missing source files (DRFT-02):** For each source summary page, verify the raw source file at the `path` frontmatter field exists on disk. Severity: error.
    - **Content-hash drift:** Recompute SHA-256 of the raw source file, compare against `content_hash` in source summary frontmatter. If mismatch: report finding (severity: warning). When `--fix` is passed, auto-fix `compilation_status` to `stale` on the affected source page. See Section 10 compilation status transitions.
    - **Index coverage:** Verify every wiki page (excluding index.md, log.md, and maintenance/ pages) has a wikilink entry in `wiki/index.md`. Severity: warning.
    - **Obsidian vault awareness (DRFT-03):** Verify `.obsidian/` directory exists (info if missing). Check for non-markdown files in `wiki/` subdirectories (severity: info).
12. Compile findings into `wiki/maintenance/lint-report.md` organized by severity then category. Findings are grouped with category subsections (e.g., `### Drift` under `## Warnings`). Include total counts and per-category breakdowns.
13. Append entry to `wiki/log.md`: `## [YYYY-MM-DD] lint | <scope>` with summary of findings counts and auto-fixes applied.
14. Commit: `lint(<scope>): <one-line summary of findings and fixes>`

**Categories** (valid values for `--category` filter): `orphan`, `crossref`, `stale`, `contradiction`, `gap`, `provenance`, `yaml`, `drift`.

**Abort conditions:**

- Wiki is empty (no pages beyond `index.md` and `log.md`). Report that the wiki is empty and skip the lint. Log this in `wiki/log.md`.

### 11.4 Reflect Workflow

The reflect workflow creates decision records (see Section 4.6) that capture why structural changes were made to the wiki. It operates through three tiers, from automatic to manual.

```
Trigger:  After structural operations, on workflow recommendation, or periodically
Inputs:   Recent changes (from log.md and git history), reflect checkpoint state
Outputs:  Decision record page(s) in wiki/decisions/, updated index/log, advanced checkpoint
Commit:   reflect(<scope>): <one-line summary>
```

#### Three-Tier Reflect Model

**Tier 1 -- Inline creation:** MERGE, SUPERSEDE, splits, domain reorganization, schema updates, and recognized reframings produce decision records as part of the operation commit. No separate reflect pass needed. The agent creating the structural change also creates the decision record in the same commit. See Section 9 operation definitions for inline hooks (steps 7a and 6a).

Inline creation is for operations where the "why" is obvious because the agent is actively making the structural choice. The decision record is a natural byproduct, not extra work.

**Tier 2 -- Workflow recommendations:** Ingest, query, and lint workflows emit a structured recommendation when they detect ambiguous signals that may warrant a decision record but require judgment:

```
reflect recommended: [trigger_type] -- [reason]
```

Signals that trigger recommendations:
- Material framing shifts during ingest (a new source substantially reframes an existing concept)
- Contradiction resolution choices during query write-back (choosing one framing over another)
- Novel synthesis frames created during query compilation (new overview page creates a novel organizing principle)
- Accumulated structural drift detected during lint (3+ related drift findings suggest a systemic issue)

This message is appended to the workflow's log entry in `wiki/log.md`. It is NOT an automatic action. The agent or human decides whether to act on it in a subsequent reflect pass or immediately.

**Tier 3 -- Manual/periodic reflect:** A safety-net pass that scans recent activity and backfills missed decision records. Run periodically (e.g., after several ingests or a batch of structural changes) or when the operator suspects structural decisions went unrecorded.

#### Reflect Checkpoint

The reflect checkpoint lives at `wiki/maintenance/reflect-state.md`. It tracks where the last reflect pass ended so subsequent passes resume from the correct position, even when a pass produces no decision records.

Fields (in frontmatter):
- `last_reflect_log_entry`: The full heading line of the last log entry scanned (e.g., `"## [2026-04-14] lint | wiki health check"`)
- `last_reflect_commit`: The short SHA of the last git commit inspected (e.g., `"abc1234"`)
- `last_reflect_at`: ISO 8601 date of the last reflect pass (e.g., `2026-04-14`)

`wiki/maintenance/` is a control-plane directory. Files here (lint-report.md, reflect-state.md) are NOT listed in wiki/index.md -- they are infrastructure, not content.

#### Periodic Reflect Procedure (Tier 3)

1. Read the reflect checkpoint from `wiki/maintenance/reflect-state.md`.
2. Scan `wiki/log.md` for entries after `last_reflect_log_entry`. Identify:
   - Structural operations: MERGE, SUPERSEDE, ARCHIVE entries
   - Schema changes: entries referencing AGENTS.md modifications
   - Workflow recommendations: lines matching `reflect recommended: [trigger_type] -- [reason]`
3. Inspect `git log --oneline` for commits after `last_reflect_commit`. Look for structural file changes: new/deleted/renamed pages, template modifications, AGENTS.md updates, directory reorganizations. **Deduplication rule:** If both log.md and git show the same event, use the log.md entry as the primary trigger (it has intent). Git-only changes (no log entry) indicate unrecorded structural work and should be investigated.
4. For each identified structural change that lacks a corresponding decision record:
   a. Create a decision record page in `wiki/decisions/` using the decision template (Section 4.6).
   b. Set `trigger_type` to the most appropriate value from the six allowed types.
   c. Set `affected_pages` to the IDs of pages touched by the change.
   d. Fill all 7 required sections with real content (not placeholders). The "Why" section must state what framing was adopted and what it replaced. "Alternatives Considered" must list at least one alternative.
   e. Add the decision record ID to `decision_history` on each affected page's frontmatter (only when meaningful per D-05).
5. Update `wiki/index.md` with new decision record entries under the Decisions category.
6. Append entry to `wiki/log.md`: `## [YYYY-MM-DD] reflect | <scope>` with a summary of how many decision records were created, or "no structural changes detected" if none.
7. Advance the reflect checkpoint: update `last_reflect_log_entry` to the most recent log entry heading, `last_reflect_commit` to current HEAD short SHA, `last_reflect_at` to today's date. **A reflect run that produces no decision records still advances the checkpoint.**
8. Commit: `reflect(<scope>): <one-line summary>`

#### Abort Conditions

- No structural changes detected since the last checkpoint AND no pending workflow recommendations. Advance the checkpoint (step 7) and skip record creation. Log: `## [YYYY-MM-DD] reflect | no structural changes detected`.
- Log entry for a structural operation already has a corresponding decision record in `wiki/decisions/` (check by date + scope match). Skip that event -- already recorded.

#### Unifying Principle

Create a decision record when future-you would reasonably ask "why is the wiki shaped this way?" When in doubt, record. A redundant record is retrievable; a missing record is lost context.

### 11.5 Brownfield Workflow

The brownfield workflow onboards existing Obsidian vaults into the wiki compiler
schema. It is the mechanical counterpart to ingest (§11.1) — where ingest creates
wiki pages from sources, brownfield transforms pre-existing vault pages into
schema-compliant form. The workflow operates through five subcommands plus the
`bootstrap_stage` lifecycle gate.

**Core principle:** *Review may be interactive and AI-guided; apply must always be deterministic.*

**Architectural boundary — apply class vs advisory class:**

| Subcommand / script | Class | What it does |
|---------------------|-------|--------------|
| `bin/brownfield.sh scan` | inventory | Dry-run classification; writes `.brownfield/REPORT.md`; zero vault mutation (Phase 10) |
| `bin/brownfield.sh bootstrap` | apply | Mechanical frontmatter injection with `bootstrap_stage: bootstrapped` (Phase 10) |
| `bin/brownfield.sh suggest` | generator | Byte-copies canonical migration scripts + generates candidate data files |
| `bin/brownfield.sh review-typing` | orchestrator | TTY small-batch cluster prompts OR large-batch AI-handoff via prompt.md |
| `bin/brownfield.sh verify [--promote]` | gate | Read-only lint wrapper + stale-artifact WARN; `--promote` flips `bootstrap_stage` on passing pages |
| `.brownfield/migrations/01-page-typing.sh` | apply | Page typing from paired manifests (candidates + decisions) |
| `.brownfield/migrations/02-provenance-bootstrap.sh` | apply | TL;DR + Key Facts top-level-bullet `[epistemic:: inferred]` tagging |
| `.brownfield/migrations/03-cross-link-inference.sh` | advisory | Cross-link candidates report |
| `.brownfield/migrations/04-privacy-review.sh` | advisory | Privacy-sensitive findings report |

**Root resolution (all four migration scripts):** each script derives its vault
root from its own filesystem location — specifically, the parent of the
`.brownfield/` directory containing the script. Migration scripts do NOT default
to `$(pwd)`; `BROWNFIELD_ROOT` is an explicit env-var override for advanced use.
This prevents cross-tree mutation when a script is invoked via absolute path
from an unrelated cwd.

#### bootstrap_stage Lifecycle

```
(absent) ──[bin/brownfield.sh bootstrap --apply]──> bootstrapped
bootstrapped ──[bin/brownfield.sh verify --promote, passes gate]──> verified
bootstrapped ──[normal ingest via bin/ingest.sh]──> (stripped per BRWN-10)
verified     ──[no automatic downgrade]──> (manual edit only)
raw          ──[reserved for future import workflows]──> (no writer in v1.1)
```

#### 11.5.1 suggest

```
Trigger:  User completes bootstrap and wants to migrate typing / provenance /
          cross-links / privacy.
Inputs:   Vault (current state) + bin/lib/brownfield_classify.py rule set.
Outputs:  .brownfield/migrations/*.sh (byte-copies with op_hash headers on lines
          2 and 3, shebang preserved on line 1),
          .brownfield/*.yaml candidate data files (each opening with a D-09
          metadata header including source_script_hash for stale-artifact
          detection by `verify`),
          REPORT.md advisory sections.
Commit:   N/A (.brownfield/ is gitignored per TMPL-04).
```

**Steps:**

1. Byte-copy canonical scripts from `schema/brownfield/migrations/*.sh` into
   `.brownfield/migrations/*.sh`. Prepend `# op_hash: sha256:<hex>` (line 2) +
   `# op_hash_scope: canonical-script-body + data-schema-version` (line 3),
   preserving the shebang on line 1.
2. Walk vault using `bin/lib/brownfield_walk.py walk_vault_respecting_ignore()` —
   the SAME helper used by `scan`. Honors `.brownfield-ignore` patterns.
3. Cluster classifications via `cluster_by_signals()`. Write
   `.brownfield/page-typing-candidates.yaml` with metadata header per D-09.
4. Write `.brownfield/page-typing-decisions.yaml` with every cluster
   `decision: pending`. High-confidence clusters auto-approve when EITHER the
   frontmatter signal is an explicit valid type enum OR 3+ non-frontmatter
   signals agree with the proposed label (D-03 verbatim).
5. Generate `.brownfield/provenance-bootstrap-report.yaml`,
   `cross-link-candidates.yaml`, `privacy-findings.yaml`.
6. Append `## Cross-link candidates` + `## Privacy review` sections to
   `.brownfield/REPORT.md`.

**Paired immutable inputs contract:** `page-typing-candidates.yaml` (cluster
membership — which pages belong to which cluster) and `page-typing-decisions.yaml`
(policy — which clusters are approved, rejected, or pending, with optional
per-page overrides) are consumed TOGETHER by `01-page-typing.sh --apply`.
`--apply` never re-classifies at apply time; candidates.yaml is read strictly
for the cluster-id → page-list lookup. Both files are required — deleting
either before apply causes a hard error.

**Abort conditions:**

- `schema/brownfield/migrations/` missing from repo.
- Vault root does not exist.

#### 11.5.2 review-typing

```
Trigger:  User resolves pending clusters in page-typing-decisions.yaml.
Inputs:   .brownfield/page-typing-candidates.yaml (read)
          .brownfield/page-typing-decisions.yaml (read+write)
Outputs:  Updated decisions.yaml with resolved decisions; OR
          .brownfield/review-typing-prompt.md (large-batch AI handoff).
Commit:   N/A (.brownfield/ is gitignored).
```

**Steps:**

1. Count pending clusters in decisions.yaml.
2. **If pending count < N (default 20) AND stdout is a TTY:** TTY prompts
   cluster-by-cluster with primitives `approve all / reject all / inspect /
   override / skip`. Override labels are validated against the `type:` enum
   before being persisted to the decisions manifest.
3. **If pending count ≥ N OR non-TTY:** emit `.brownfield/review-typing-prompt.md`
   — directive template pointing at candidates + decisions YAMLs. Tell user to
   open in AI session (Claude Code, Codex, etc.) and edit the decisions manifest.
4. On stdin EOF (e.g., piped `</dev/null`): write back any decisions made so
   far and exit cleanly. Never loop indefinitely.
5. Write decisions.yaml with ruamel.yaml round-trip (preserves user comments).

The CLI never calls an LLM. The AI-handoff template operates on the file
artifact from outside the CLI; the user runs a deterministic apply script afterward.

**Abort conditions:**

- `.brownfield/page-typing-decisions.yaml` not found → run `suggest` first.
- All clusters already resolved → report cleanly and exit 0.

#### 11.5.3 verify [--promote]

```
Trigger:  User checks vault passes lint after migration scripts have run.
Inputs:   Vault + `.brownfield/page-typing-decisions.yaml` (for Gate 5) +
          .brownfield/*.yaml metadata headers (for stale-artifact detection).
Outputs:  stdout summary of blockers + optional WARN on stale candidate
          artifacts; (with --promote) `bootstrap_stage` flips on eligible pages.
Commit:   N/A (frontmatter mutations via ruamel round-trip; user commits separately).
```

**Steps (read-only mode):**

1. For each `.brownfield/*.yaml` candidate file, compare its D-09
   `source_script_hash:` header against the current body-post-op_hash-strip
   sha256 of the corresponding `.brownfield/migrations/*.sh`. Emit a stderr
   WARN for each mismatch (`stale candidate artifact detected: <cand>; re-run
   `bin/brownfield.sh suggest` to refresh`).
2. Run `bin/lint.sh --ci --format json --category yaml,provenance,orphan,crossref,brownfield`.
3. Print summary grouped by severity; list paths blocking promotion.
4. Exit 0 regardless of findings (stale WARN and lint findings are diagnostic,
   not gating).

**Steps (`--promote`):**

1. Run steps 1–3 above (stale-artifact WARN + lint).
2. Read `.brownfield/page-typing-decisions.yaml`; build pending-pages set.
3. Walk vault; for each `bootstrap_stage: bootstrapped` page, apply the 5-gate
   pass-list: (a) currently bootstrapped; (b) `type:` is a valid enum per §4;
   (c) zero error-severity lint findings for the page; (d) type-specific
   required fields present (e.g., `path`, `content_hash`, `ingested_at`,
   `source_type` for `type: source`); (e) not in pending-pages set.
4. If all 5 gates pass: flip `bootstrap_stage: verified` via `write_roundtrip`.
5. Print summary: `N pages promoted; M pages blocked`.

Privacy is not checked here — `bin/check-privacy.sh` handles the public-paths
leak guard (see §13 and Phase 9).

**Abort conditions:**

- `bin/lint.sh` not found or exits with runtime error.
- No `bootstrap_stage: bootstrapped` pages found → nothing to verify.

#### 11.5.4 applied.log per-script shapes

`.brownfield/applied.log` is append-only; one block per meaningful execution.
Apply-class (01, 02) append on `--apply` only (dry-run never appends); advisory-
class (03, 04) append on findings. The block shape is **per-script** — each
script's exact schema is documented verbatim in `schema/brownfield/migrations/README.md`
and summarized here as `applied.log block shapes`:

- **01-page-typing.sh (apply):** `inputs:` is a two-item list — hashed candidates.yaml + hashed decisions.yaml. `summary:` has `approved_clusters`, `overridden_pages`, `pending_pages_remaining`.
- **02-provenance-bootstrap.sh (apply):** `inputs:` is a one-item literal string `- (vault walk — no candidate inputs; 02 is direct-apply)` — 02 is direct-apply, no candidate manifest. `summary:` has `pages_with_eligible_bullets`, `pages_with_no_eligible_bullets`.
- **03-cross-link-inference.sh (advisory):** no `inputs:` field. `mutations: none` + `report_section: REPORT.md#cross-link-candidates`.
- **04-privacy-review.sh (advisory):** no `inputs:` field. `mutations: none` + `report_section: REPORT.md#privacy-review`.

All four share the invariant fields: `## <script> @ <UTC ISO>` header, `mode:`, `op_hash:`, `exit_code:`, `prereq_check:`, `summary:`. Field variance beyond these is intentional and documented (NOT drift).

See: docs/reference/brownfield.md for operator runbook, troubleshooting, and the
full lifecycle walkthrough.

### 11.6 Release Workflow (Orphan-Branch Publish)

Template releases use an orphan-branch workflow that publishes a neutralized snapshot of the repo without the creator's personal `wiki/` content. See `docs/reference/release.md` for the full runbook.

## 12. Index and Log

### index.md (Content Index)

- Lives at `wiki/index.md`.
- Organized by page type: Entities, Concepts, Sources, Comparisons, Overviews, Decisions.
- Each entry follows the format: `- [[Page Title]] -- <one-line summary> (<epistemic_status>, <updated_at>)`
- Updated on every ingest and every query that creates or modifies pages.
- The LLM reads this FIRST when searching for information (per Section 3 and Section 7).
- Archived pages are listed separately under an "Archived" heading if any exist.
- The index is the primary navigation mechanism for both LLMs and humans browsing the wiki.

### log.md (Activity Log)

- Lives at `wiki/log.md`.
- Chronological, newest entries at the bottom (append-only).
- Entry format:

```markdown
## [YYYY-MM-DD] <operation_type> | <description>

<what was done, which pages were affected, brief rationale>
```

- Valid operation types: workflow-level (`ingest`, `query`, `lint`, `reflect`) and structured operations (`UPDATE`, `MERGE`, `SUPERSEDE`, `ARCHIVE`). Structured operations use the extended format below.
- Each entry includes: what was done, which pages were affected, and a brief rationale.
- The log is parseable with: `grep "^## \[" wiki/log.md | tail -5`
- Structural reasoning and decision analysis belong in decision record pages (reflect workflow, Section 11.4), NOT in the log. The log records WHAT happened; decision records explain WHY.

#### Structured Operation Log Entries

When logging individual structured operations (UPDATE, MERGE, SUPERSEDE, ARCHIVE), use this extended format:

```markdown
## [YYYY-MM-DD] OPERATION | target_page

source: source_id
result: what changed (e.g., "added 3 claims, refreshed TL;DR")
reason: one-line rationale
```

This format extends the base log entry format with structured sub-fields for machine-parseability. It applies to individual operations, NOT to workflow-level entries. Workflow-level entries (ingest, query, lint, reflect) use the base format with their own sub-fields as defined in Section 11.

**Examples:**

```markdown
## [2026-04-15] UPDATE | <concept-slug>

source: <source-slug>
result: added 2 claims on a sub-topic, refreshed TL;DR
reason: new source provides empirical evidence for specific parameters
```

```markdown
## [2026-04-15] MERGE | <overview-slug>

source: n/a (structural reorganization)
result: merged <sub-concept-slug> into <overview-slug>, added subsection
reason: <sub-concept-slug> page had <3 claims, better as subsection of parent concept
```

```markdown
## [2026-04-15] SUPERSEDE | old-<entity-slug>-summary

source: <source-slug-2>
result: marked old-<entity-slug>-summary as superseded by <entity-slug>
reason: new comprehensive source makes old summary redundant
```

See: examples/kahneman/concepts/prospect-theory.md for concrete filled-in instances of these operation patterns.

#### Contributor inline field (COLAB-03, Phase 9)

Log entries may carry an optional `contributor:: @github-handle` Dataview inline body field immediately below the entry header:

```markdown
## [YYYY-MM-DD] ingest | <description>

contributor:: @octocat

<rationale and affected pages>
```

**Rules:**

- `contributor::` is a **Dataview inline body field** (per AGENTS.md §6 inline syntax precedent). It MUST NOT be placed in YAML frontmatter (§3 prohibition).
- Handle format: `@github-handle` -- leading `@` required. `bin/search.sh --contributor` accepts both `@octocat` and `octocat` forms (leading `@` stripped internally).
- **Single-author repos omit the field entirely** -- `bin/ingest.sh` auto-detects via `git log --all --format='%ae' | sort -u | wc -l == 1` (see §11.1 step 9a).
- **Git commit authorship is the attribution source of truth** (COLAB-05). The `contributor::` field is a Dataview convenience index for filtering log history by contributor (`bin/search.sh --contributor @alice`); it is NOT authoritative.
- Handle-to-email resolution lives in `.git-author-map.txt` at the repo root (committed, human-curated, `email  ->  @handle` format; `#` comments; case-insensitive email match).
- `bin/lint.sh` category `contributor` (severity `warning`) catches `@handle` values in `wiki/log.md` whose `.git-author-map.txt` email does NOT appear in `git log --all --format='%ae'` -- non-blocking consistency check. Skipped on single-author repos.

**Queryable via Dataview:**

```dataview
LIST
FROM "wiki/log.md"
WHERE contains(file.lists.text, "contributor:: @octocat")
```

## 13. Privacy Routing

All content in the wiki system has a privacy classification that determines whether it may be sent to cloud LLM APIs. The system uses fail-closed semantics: when in doubt, the answer is `local_only`. It is better to under-share than to accidentally send private content to a cloud API.

### Privacy Tiers

- **`local_only`** -- NEVER sent to cloud LLM APIs. Processed only by local models or local tooling.
- **`cloud_safe`** -- May be sent to cloud LLM APIs for processing.

### Three-Level Precedence

Privacy classification is resolved using a three-level precedence hierarchy (most specific wins):

1. **Explicit `privacy` field in item frontmatter** -- This is the authoritative declaration. If present, it is always respected.
2. **Enclosing directory default** -- Provides operational convenience. Directories like `sources/local-only/` imply `local_only`; directories like `sources/cloud-safe/` imply `cloud_safe`.
3. **System default: `local_only`** -- If neither frontmatter nor directory provides a signal, the item is classified as `local_only` (fail-closed).

### Conflict Resolution

If the frontmatter and directory disagree, the **stricter** setting wins. Since `local_only` is always stricter than `cloud_safe`, any conflict resolves to `local_only`. This ensures that an item explicitly marked `local_only` cannot be overridden by a permissive directory, and a restrictive directory cannot be overridden by a permissive frontmatter field.

### Privacy Decision Table

| # | Frontmatter `privacy` | Directory               | Result       | Why                                                    |
|---|----------------------|-------------------------|-------------|--------------------------------------------------------|
| 1 | `cloud_safe`         | `sources/cloud-safe/`   | `cloud_safe` | Both agree: cloud_safe                                 |
| 2 | `local_only`         | `sources/cloud-safe/`   | `local_only` | Frontmatter is stricter, stricter wins                 |
| 3 | `cloud_safe`         | `sources/local-only/`   | `local_only` | Directory is stricter, stricter wins                   |
| 4 | (not set)            | `sources/cloud-safe/`   | `cloud_safe` | No frontmatter, directory provides signal              |
| 5 | (not set)            | `sources/2026/2026-04/` | `local_only` | No frontmatter, no privacy directory signal, system default |
| 6 | (not set)            | (no directory signal)   | `local_only` | Fail-closed: unknown = local_only                      |
| 7 | `local_only`         | (no directory signal)   | `local_only` | Explicit local_only confirmed                          |

### Rules for LLM Agents

1. The LLM MUST check privacy classification before sending any content to a cloud API.
2. If classification cannot be determined, treat as `local_only`.
3. Never send `local_only` content to cloud LLM APIs under any circumstances.
4. When creating wiki pages, set the `privacy` field in frontmatter based on the sources used.

### Wiki Page Privacy Inheritance

When a wiki page cites sources with mixed privacy tiers (e.g., one `local_only` source and one `cloud_safe` source), the wiki page inherits `local_only` -- the strictest tier among its contributing sources. A page is only `cloud_safe` if ALL of its contributing sources are `cloud_safe`.

## 14. Scaling Boundaries

**Important:** These are provisional heuristics, not hard boundaries. They are starting points derived from reasoning about likely pain points. Validate and adjust through actual use. The numbers below are approximate -- the real signals are behavioral (the wiki becomes awkward to use in specific ways).

These tiers are additive. Each builds on the previous rather than replacing it.

### Tier 1: Markdown-First Baseline (v1)

This is the starting configuration. Everything is markdown files and YAML frontmatter.

- **Navigation:** `wiki/index.md` is the primary navigation mechanism. The LLM reads it to find pages.
- **Lint:** Full lint scans all pages in the wiki.
- **Agent behavior:** Read the full index, scan all pages during lint.
- **Approximate capacity:** Up to ~100-200 wiki pages, ~50-100 ingested sources.
- **Pain points at limit:** `index.md` becomes slow to navigate. The LLM's context window fills up scanning the full index. Full lint takes multiple passes or minutes.
- **Signal you are outgrowing this tier:** `index.md` exceeds ~500 lines. The LLM frequently retrieves pages irrelevant to the query because the index is too dense to scan efficiently.

### Tier 2: Split Index

When the single index becomes unwieldy (approximately a few hundred wiki pages).

- **Change:** Split `wiki/index.md` into per-type or per-domain sub-indexes: `wiki/index-entities.md`, `wiki/index-concepts.md`, `wiki/index-sources.md`, etc. The main `wiki/index.md` becomes a meta-index pointing to sub-indexes.
- **Agent behavior:** Read the meta-index to determine which sub-index is relevant, then read only that sub-index.
- **Approximate capacity:** Up to ~500-1000 wiki pages.
- **Pain points at limit:** Even sub-indexes become large. Cross-type queries require reading multiple sub-indexes. The meta-index itself grows.
- **Signal to upgrade:** Sub-indexes exceed ~200 entries each. Cross-domain queries are slow because the LLM must read multiple sub-indexes.

### Tier 3: Incremental Lint

When full lint becomes too expensive to run routinely.

- **Change:** Track which pages changed since the last lint (via `git diff` or `log.md` timestamps). Only lint changed pages and their direct neighbors (pages they link to or are linked from).
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

## 15. Tooling and Integrations

> This section is informational, not normative. It describes tools the wiki is designed to work with, but does not mandate their installation. The wiki functions as plain markdown files in a git repo regardless of tooling.

### Obsidian (Primary Human Interface)

- **Graph View:** Visualize the wiki's link structure. Only meaningful links appear because Section 8 enforces first-mention linking and prohibits display aliases.
- **Dataview plugin:** Query frontmatter fields with TABLE/LIST/TASK syntax. All frontmatter fields defined in Section 5 are queryable. Example: `TABLE summary, epistemic_status FROM "wiki/entities" WHERE status = "active"`.
- **Properties:** Obsidian 1.4+ supports typed frontmatter editing. All base fields render as editable properties in the sidebar.
- **Aliases:** The `aliases` frontmatter field enables Obsidian to resolve alternative page names automatically, supporting the exact-title wikilink convention (Section 8).
- **Backlinks:** Obsidian's backlinks panel shows all pages that link to the current page, complementing the `## Related Pages` section.

### Git (Version Control)

- All changes are tracked in git with conventional commits (Section 3).
- History provides a full audit trail of wiki evolution.
- Branching is available for experimental restructuring (e.g., major domain reorganization).
- The activity log (`wiki/log.md`) complements git history with human-readable operation summaries.

### Optional Future Tools (Not Required for v1)

- **Local search engine** (e.g., qmd or similar): Hybrid BM25/vector search for faster query workflow when the wiki grows beyond grep's effectiveness.
- **Obsidian Web Clipper:** Source acquisition from the web -- clip articles directly into the `sources/` directory.
- **Marp plugin:** Generate slide decks from wiki content for presentations and reviews.

## 16. Appendices and Examples

### Appendix A: Dataview Query Examples

See `docs/reference/dataview-queries.md` for five Dataview query patterns (active entities, sources by domain, stale pages, missing privacy classification, pages in a domain).

### Appendix B: Commit Message Examples

See `docs/reference/commit-examples.md` for representative commit messages per workflow type (schema/ingest/query/lint/reflect).

### Appendix C: Quick Reference Card

A compact summary of the most critical rules for fast LLM scanning:

1. **Read `wiki/index.md` first, always.** This is the entry point for all wiki operations.
2. **TL;DR and Key Facts before Detail.** Read shallow sections first; drill into Detail only when needed.
3. **`[[Exact Title]]` on first mention only.** No display aliases. No repeated links. No wikilinks in frontmatter.
4. **`[prov:source_id#locator]` for every factual claim.** Every claim needs provenance. No exceptions.
5. **One commit per logical operation.** One ingest = one commit, even if it touches many files.
6. **Privacy default: `local_only`.** When in doubt, do not send to cloud APIs.
7. **All dates: ISO 8601.** `YYYY-MM-DD` or `YYYY-MM-DDTHH:mm:ss`.
8. **All field names: `snake_case`.** For Dataview compatibility.
9. **Operations: UPDATE, MERGE, SUPERSEDE, ARCHIVE.** No raw file rewrites. Log every operation.
10. **See Section 3 "What Agents Must NOT Do"** for the full list of prohibitions.
