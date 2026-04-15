# Phase 1: Schema, Structure & Conventions - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-09
**Phase:** 01-schema-structure-conventions
**Areas discussed:** Schema document shape, Directory layout, Frontmatter & provenance syntax, Progressive disclosure format, Commit conventions, Scaling boundary heuristics, Wikilink & graph conventions, Schema document outline

---

## Schema Document Shape

### Schema file structure

| Option | Description | Selected |
|--------|-------------|----------|
| Single file | One AGENTS.md with everything. Simpler for LLMs to load. | ✓ |
| Split by concern | Separate files for conventions, workflows, page schemas, operations. | |
| Single file + appendices | Core schema in one file, detailed reference in separate files. | |

**User's choice:** Single file for rules, optional supporting files for templates/examples. Coherence without turning the schema into a dump.

### Schema file naming

| Option | Description | Selected |
|--------|-------------|----------|
| AGENTS.md | Agent-agnostic name. Any LLM can be told to look for it. | ✓ |
| CLAUDE.md | Claude Code auto-discovers this. Ties project to one vendor. | |
| Both | AGENTS.md as real file, CLAUDE.md as pointer. | |

**User's choice:** AGENTS.md — agent-agnostic.

### Schema prescriptiveness

| Option | Description | Selected |
|--------|-------------|----------|
| Prescriptive steps | Explicit numbered steps for each workflow. | ✓ |
| Intent-based | Describe what workflows achieve, let LLM decide steps. | |
| Hybrid | Prescriptive for critical path, intent-based for judgment calls. | |

**User's choice:** Prescriptive in schema. User explicitly asked about skills as an alternative — rejected because skills are Claude Code specific and would break agent-agnosticism. Workflows must live in the schema.

### Schema scope

| Option | Description | Selected |
|--------|-------------|----------|
| All workflows now | Define all four workflows in Phase 1. Schema is the spec. | ✓ |
| Incremental | Each phase adds its workflow section when capability is built. | |
| Stubs + full conventions | Full conventions now, workflow stubs marked TBD. | |

**User's choice:** All workflows now — complete upfront.

---

## Directory Layout

### Top-level structure

| Option | Description | Selected |
|--------|-------------|----------|
| Three siblings | sources/, wiki/, AGENTS.md at root. | ✓ |
| Nested under docs/ | Everything under docs/. | |
| Obsidian vault = root | Entire repo is the vault. | |

**User's choice:** Three siblings.

### Wiki directory depth

| Option | Description | Selected |
|--------|-------------|----------|
| Flat | All wiki pages at one level, type in frontmatter. | |
| By page type | Subdirectories: entities/, concepts/, sources/, comparisons/, overviews/. | ✓ |
| By topic/category | Subdirectories by knowledge domain. | |

**User's choice:** By page type. Categories/topics represented via frontmatter fields, wikilinks, and Dataview views — not filesystem hierarchy.

### Index and log location

| Option | Description | Selected |
|--------|-------------|----------|
| Inside wiki/ | index.md and log.md are wiki-layer artifacts. | ✓ |
| At repo root | Top-level for easy access. | |

**User's choice:** Inside wiki/.

### Source organization

| Option | Description | Selected |
|--------|-------------|----------|
| Flat with naming convention | All in sources/ with YYYY-MM-DD-slug naming. | |
| By source type | Subdirectories: articles/, papers/, journals/, etc. | |
| By topic | Subdirectories by knowledge domain. | |

**User's choice:** Initially selected flat, then refined to chronological directory nesting: `YYYY/YYYY-MM/YYYY-MM-DD-slug/`.
**Notes:** Source metadata (type, topic, privacy) stored as metadata, not directory structure.

### Source assets

**User's choice (free text — user preempted the question):** Per-source bundle folder when assets exist. Single file for text-only sources. Optional global sources/assets/ only for genuinely shared or tool-managed assets.
**Rationale:** Provenance is cleaner (assets obviously part of the source bundle), self-contained for moving/archiving/auditing, avoids a giant global assets/ bucket.

---

## Frontmatter & Provenance Syntax

### Claim-level provenance syntax

| Option | Description | Selected |
|--------|-------------|----------|
| Dataview inline fields | `[source:: src-id]` or `[source:: src-id, p.12]` | |
| Footnote-style citations | Academic footnotes with provenance section at bottom. | |
| Hybrid | Status as inline Dataview, citations as footnotes. | |

**User's choice (refined from Dataview selection):** Custom inline syntax: `[prov:<source_id>#<locator>]` with extended form `[prov:<source_id>#<locator>|<support_type>|<checked_at>]`.
**Notes:** User provided detailed specification including locator types (#p12-14, #sec:introduction, #para3, #t00:12:10-00:12:48, #img2), support types (direct, inferred, tentative, derived), checked_at instead of generic date, source registry fields, and validation rules.

### Required frontmatter fields

**User's choice (free text — user preempted the question):** Defined a specific required base field set: id, title, type, status, summary, created_at, updated_at, sources, epistemic_status, tags, domains, supersedes, superseded_by, privacy. Everything else pushed to type-specific schemas.

### Confidence field

| Option | Description | Selected |
|--------|-------------|----------|
| Both fields | epistemic_status + confidence as separate dimensions. | |
| Epistemic status only | One field is enough at page level. | ✓ |

**User's choice:** Epistemic status only — confidence is implicit.

---

## Progressive Disclosure Format

**User's choice (free text — user preempted the question):** Provided a complete specification with a concrete example page showing the section order, per-type variations (entity/concept, source summary, comparison, decision), and design constraints (TL;DR short for fast scanning, Key Facts skimmable with citations, Detail for nuance, Sources at bottom for verification flow).

---

## Commit Conventions

### Commit message format

| Option | Description | Selected |
|--------|-------------|----------|
| Conventional commits | Type-prefixed: ingest(slug):, query(topic):, lint(scope):, etc. | ✓ |
| Free-form with prefix | Operation type prefix, natural language body. | |

**User's choice:** Conventional commits.

### Commit granularity

| Option | Description | Selected |
|--------|-------------|----------|
| One commit per operation | Each ingest/query/lint/reflect is one atomic commit. | ✓ |
| Split by phase | Multi-pass operations get one commit per pass. | |

**User's choice:** One commit per logical operation. Rule: if the change answers "what happened?" with one sentence, it's one commit.

---

## Scaling Boundary Heuristics

### Threshold specificity

| Option | Description | Selected |
|--------|-------------|----------|
| Named tiers with rough numbers | 2-3 scale tiers with approximate page counts. Provisional. | ✓ |
| Trigger-based | Specific trigger conditions, no tiers. | |
| Minimal | Just acknowledge scaling upgrades exist. | |

**User's choice:** Named tiers with approximate heuristics. Signal-based language alongside approximate numbers as starting points. Explicitly labeled as heuristics, not hard architectural boundaries.

### Privacy routing

**User's choice (free text — user preempted the question):** Layered privacy model with fail-closed semantics. Three-level precedence: (1) explicit frontmatter, (2) directory default, (3) system default = local_only. Directory defaults reduce repetitive tagging, frontmatter handles exceptions, fail-closed avoids accidental cloud leakage.

---

## Wikilink & Graph Conventions

### Link density

| Option | Description | Selected |
|--------|-------------|----------|
| Link on first mention per page | Standard wiki convention. Subsequent mentions plain text. | ✓ |
| Link every mention | Maximizes connectivity, clutters reading. | |
| Link only in Key Facts and Related Pages | Sparser, more intentional graph. | |

**User's choice:** Link on first mention per page.

### Red links

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, create red links | Link to pages that should exist but don't. Gap detection. | ✓ |
| Only link existing pages | No dangling links. | |
| Red links in Key Facts only | Controlled gap signaling. | |

**User's choice:** Yes, create red links.

### Link format

| Option | Description | Selected |
|--------|-------------|----------|
| Exact title match | [[Attention Mechanism]] not [[Attention Mechanism\|attention]]. | ✓ |
| Allow display names | [[Page\|display text]] for natural prose. | |

**User's choice:** Exact title match. Use aliases frontmatter for alternate names.

---

## Schema Document Outline

**User's choice (free text — user preempted the question):** 16-section outline: (1) Overview & Principles, (2) Directory Structure, (3) Global Rules, (4) Page Types & Templates, (5) Frontmatter Schema, (6) Provenance, Epistemics, and Staleness, (7) Progressive Disclosure, (8) Wikilink & Graph Conventions, (9) Structured Operations and Executor Model, (10) Compiler Pipeline, (11) Workflows (subsections: Ingest, Query, Lint, Reflect), (12) Index and Log, (13) Privacy Routing, (14) Scaling Boundaries, (15) Tooling / Integrations, (16) Appendices / Examples.

### Workflow subsection structure

| Option | Description | Selected |
|--------|-------------|----------|
| All four as subsections | 11.1 Ingest, 11.2 Query, 11.3 Lint, 11.4 Reflect under Workflows. | ✓ |
| Each workflow top-level | Separate top-level sections. Inflates outline. | |

**User's choice:** All four as subsections of Workflows.

---

## Claude's Discretion

- Template file format and exact content within schema/ directory
- Exact wording of scaling tier descriptions
- Internal structure of workflow subsections
- Source registry implementation detail (frontmatter vs sidecar)

## Deferred Ideas

None — discussion stayed within phase scope.
