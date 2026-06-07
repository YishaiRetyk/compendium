# LLM Wiki Compiler Schema

> **This file is the authoritative router for the LLM Wiki Compiler spec.**
> Any LLM agent maintaining this wiki MUST read and follow this document.
> This file is the router; each linked file listed in the routing table is authoritative for its own sections.

## 1. Overview and Principles

The LLM Wiki Compiler is a personal knowledge management system with three layers:

1. **Raw sources** (`sources/`) -- Immutable input documents (articles, papers, transcripts, journal entries, images). The human curates this layer. Sources are never modified after ingestion.
2. **The wiki** (`wiki-cloud/` + `wiki-local/`) -- LLM-generated and maintained markdown pages. This is the compiled artifact: summaries, entity pages, concept pages, comparisons, overviews, an index, and an activity log. `wiki-cloud/` is the cloud-safe tier; `wiki-local/` is the local-only tier.
3. **The schema** (this file + `schema/`) -- The specification that governs LLM behavior. This file routes to reference files under `schema/reference/` and `schema/workflows/`; each is authoritative for its own sections.

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

Workflows for each operation are defined in the workflow files under `schema/workflows/` (see the routing table).

These four operations are the wiki's mutation vocabulary. Layered on top is the **Audit** -- a review-only diagnostic workflow (`bin/audit-claims.sh`, see `schema/workflows/audit.md`) that checks whether sampled claims semantically follow from the source passage they cite. The Audit never mutates a wiki page; like Lint, it is a workflow, not one of the four mutation operations, so the four-operation framing is preserved.

This file (`{{AGENT_FILENAME}}`) is the canonical agent spec; the wizard selects `AGENTS.md` or `CLAUDE.md` per the user's agent choice.
> **IMPORTANT — Reference Routing Table**
>
> This file is the router. Each linked file is authoritative for its own sections (D-09).
> Read the target file before acting — do not rely on the stub alone.
>
> **Resolvable references** (the target file exists — read it before acting):
>
> | When you need this | Go to |
> |-------------------|-------|
> | Authoring a wiki page (type rules, section order) | `schema/reference/page-types.md` |
> | Checking required frontmatter fields | `schema/reference/frontmatter.md` |
> | Adding `[prov:]` or `[epistemic::]` markers | `schema/reference/provenance.md` |
> | Lint workflow + decay/staleness auto-fix math + CI severity/JSON contract | `schema/workflows/lint.md` |
> | Creating cross-references (wikilinks) | `schema/reference/wikilinks.md` |
> | Determining `wiki-cloud/` vs `wiki-local/` placement | `schema/reference/privacy.md` |
> | Wiki capacity / scaling signals | `docs/reference/scaling.md` |
> | Obsidian, Git, and optional tools | `docs/reference/tooling.md` |
> | Ingesting a new source (classify → extract → merge) | `schema/workflows/ingest.md` |
> | Answering a question + write-back rules | `schema/workflows/query.md` |
> | Reflect workflow (decision records) | `schema/workflows/reflect.md` |
> | Structured operations (UPDATE/MERGE/SUPERSEDE/ARCHIVE) | `schema/workflows/structured-operations.md` |
> | Brownfield vault onboarding | `schema/workflows/brownfield.md` |
> | Orphan-branch template release | `schema/workflows/release.md` |
> | Claim-faithfulness audit | `schema/workflows/audit.md` |
> | Index / log entry formats | `schema/reference/log-format.md` |

## 2. Directory Structure

```
life/                               # repo root
├── AGENTS.md                       # This file (router; see routing table)
├── sources/                        # Raw immutable sources (cloud-safe-only; see `schema/reference/privacy.md`)
│   ├── YYYY/                       # Year grouping
│   │   └── YYYY-MM/               # Month grouping
│   │       ├── YYYY-MM-DD-slug/   # Bundle: source.md + assets
│   │       │   ├── source.md
│   │       │   └── figure1.png
│   │       └── YYYY-MM-DD-slug.md # Single file (no assets)
│   └── assets/                     # Optional: shared/tool-managed assets only
├── wiki-cloud/                     # Cloud-safe tier: LLM-maintained pages (readable by cloud sessions)
│   ├── entities/                   # People, tools, organizations
│   ├── concepts/                   # Ideas, theories, frameworks
│   ├── sources/                    # Source summary pages (one per ingested source)
│   ├── comparisons/                # Comparison pages
│   ├── overviews/                  # High-level topic summaries
│   ├── decisions/                  # Decision record pages
│   ├── maintenance/                # Control-plane files (lint-report.md)
│   ├── index.md                    # Cloud-tier content catalog
│   └── log.md                      # Cloud-tier chronological activity log
├── wiki-local/                     # Local-only tier: mirrors wiki-cloud/ convention; created on demand
│   ├── maintenance/                # Audit control-plane (audit-report.md, audit-state.md)
│   └── [entities|concepts|sources|comparisons|overviews|decisions]/  # created when first local page exists
├── schema/                         # Templates + AGENTS.template.md wizard source
│   ├── AGENTS.template.md          # Wizard source ({{PRIMARY_DOMAIN}} etc.)
│   └── templates/                  # Page templates per type
├── examples/                       # Reference-only filled-in clusters (e.g., examples/kahneman/)
├── docs/                           # User-facing docs (quickstart, guided setup, manual setup, reference)
├── .github/                        # CI workflows, issue templates
├── bin/                            # Helper scripts (lint.sh, ingest.sh, sync-claude.sh, etc.)
└── .githooks/                      # Repo-local git hooks (e.g., pre-commit sync check)
```

**Permitted top-level directories:** `sources/`, `wiki-cloud/`, `wiki-local/`, `schema/`, `examples/`, `docs/`, `.github/`, `bin/`, `.githooks/`. Content in `examples/` is reference-only (see `example: true` in `schema/reference/frontmatter.md`); it is skipped by lint and excluded from the published wiki.

**Source directory rules:**
- Sources use chronological nesting: `YYYY/YYYY-MM/YYYY-MM-DD-slug/`
- When a source has assets (images, figures, attachments): create a bundle directory with `source.md` as the main file and assets co-located alongside it.
- When a source is text-only: use a single file `YYYY-MM-DD-slug.md` (no bundle directory needed).
- `sources/` is cloud-safe-only. A source that must be local lives as its source-summary page under `wiki-local/sources/` (the resolver keys off the summary page tier, not the raw source path).

**Wiki directory rules:**
- `wiki-cloud/` is the cloud-safe tier. `wiki-local/` is the local-only tier. Both use the same six page-type subdirectories (`entities/`, `concepts/`, `sources/`, `comparisons/`, `overviews/`, `decisions/`).
- `wiki-local/` subdirs are created on demand (D-06) -- no pre-created empty dirs. The schema documents the convention so agents know `wiki-local/entities/` is the right home before it exists.
- `wiki-cloud/index.md` and `wiki-cloud/log.md` are the cloud-tier navigation artifacts. A local `wiki-local/index.md` and `wiki-local/log.md` are created lazily when the first navigable local content beyond the 2 control-plane files is added (D-07 partition -- forced by the model: cloud cannot list local page existence).
- Topics and categories are represented via frontmatter fields (`tags`, `domains`), NOT via filesystem hierarchy.
- `wiki-local/maintenance/` holds the audit control-plane (`audit-report.md`, `audit-state.md`). `wiki-cloud/maintenance/` holds `lint-report.md`.

**Schema directory rules:**
- `schema/reference/` and `schema/workflows/` hold authoritative reference content the router links to; `schema/templates/` holds blank templates.

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

1. Read `wiki-cloud/index.md` FIRST to find relevant pages.
2. Scan `## TL;DR` and `## Key Facts` sections of relevant pages BEFORE reading Detail sections.
3. Only read `## Detail` and `## Sources` sections when shallow sections are insufficient.

This progressive disclosure navigation minimizes context window consumption.

### Red Links

→ See `schema/reference/wikilinks.md` (red links section).

### What Agents Must NOT Do

- DO NOT create topic-based directories (e.g., `wiki-cloud/machine-learning/`). Use frontmatter `domains` field and Dataview queries instead.
- DO NOT put conventions or rules in any file other than AGENTS.md or the files listed in the routing table. AGENTS.md is the router; each linked file is authoritative for its own sections.
- DO NOT put wikilinks in YAML frontmatter. Use string IDs in frontmatter, wikilinks in body text.
- DO NOT write bare `[[Title]]` wikilinks. ALWAYS write `[[id|Exact Title]]` (target = page `id`; display = exact canonical `title`). Bare links without a pipe do not reliably resolve for multi-word-title pages in Obsidian (which resolves by filename/path ONLY, never by `aliases`).
- DO NOT put provenance blobs, relation arrays, or decay settings in base frontmatter. Those belong in type-specific fields.
- DO NOT delete or move files when archiving. Set `status: archived` and remove from index active listings.
- DO NOT read the entire wiki when answering a query. Read index first, then TL;DR/Key Facts of relevant pages, then Detail only when needed.
- DO NOT create multiple commits for a single logical operation. One ingest = one commit, even if it touches 15 files.
- DO NOT read `wiki-local/` from a cloud session -- the tier boundary is structural (directory + harness permission), not a per-turn rule. local→cloud is the forbidden leak direction.
- DO NOT link to the same page more than once in a single page body. Link on first mention only.
- DO NOT use real slugs, page IDs, or terms drawn from the user's private wiki content (under `examples/`, archived sources, or any `wiki-local/` page) when authoring or editing **template-public files**: `AGENTS.md`, `CLAUDE.md`, `README.md`, `PRIVACY.md`, `docs/`, `.github/`, `wiki-cloud/` scaffolding (`index.md`, `log.md`, `maintenance/`), and `bin/`. Use abstract placeholders instead — `<concept-slug>`, `<source-id>`, `<page-title>`, `<entity-name>`, `<YYYY-MM-DD-slug>`, `<term>`. The `bin/check-neutrality.sh` denylist gate is a backstop, not the primary defense; prevent leaks at write-time. This rule applies to examples in schema docs, illustrative snippets, sample commands, test fixtures shipped to public paths, and any narrative that would benefit from a "concrete example" -- pick a placeholder, not a real vault term.

## 4. Page Types and Templates

Six page types: **entity**, **concept**, **source**, **comparison**, **overview**, **decision**.

→ See `schema/reference/page-types.md` for section ordering, authoring conventions, and full type details.

## 5. Frontmatter Schema

→ Full frontmatter schema and validation checklist in `schema/reference/frontmatter.md`.

## 6. Provenance, Epistemics, and Staleness

Every factual claim MUST have an inline provenance marker `[prov:source_id#locator]`.

→ Syntax, locator types, epistemic markers, and contradiction markers: `schema/reference/provenance.md`.
→ Decay table and staleness auto-fix: `schema/workflows/lint.md`.

## 8. Wikilink and Graph Conventions

Use `[[id|Title]]` for ALL intra-wiki links — see `schema/reference/wikilinks.md`.

## 9. Structured Operations and Executor Model

All wiki mutations use a formal operations vocabulary. Raw file rewrites are prohibited -- every change goes through one of these four operations with mandatory logging.

| Operation    | Verb    | What It Does                                       |
|-------------|---------|---------------------------------------------------|
| **UPDATE**  | Modify  | Add new information to an existing page            |
| **MERGE**   | Combine | Unify two pages covering the same concept          |
| **SUPERSEDE** | Replace | Mark a page/claim as replaced by newer information |
| **ARCHIVE** | Retire  | Move outdated content out of active wiki           |

Before applying ANY operation, run `bin/validate-op.sh <OPERATION> <target_path> [<second_path>]` — it mechanically enforces the 5 executor checks (target exists, both-pages-distinct for MERGE, provenance resolves, frontmatter valid, privacy respected). If it returns FAIL, do NOT apply the operation.

**Solo-op log shape (compact dispatch form).** A standalone structured op (not wrapped in a workflow) logs to `wiki-cloud/log.md` as:
```
## [YYYY-MM-DD] OPERATION | target_page

source: source_id | result: what changed | reason: one-line rationale
```
The canonical multi-line structured-operation log entry (the `source:` / `result:` / `reason:` three-line form) lives in `schema/reference/log-format.md`; the compact one-liner above is a dispatch summary of it, not a competing standard.

**Solo-op commit prefix (Open Q9 / D-01).** A *solo* structured op gets its own lowercased per-op commit prefix, symmetric with the workflow prefixes: `update(<page>): …` / `merge(<page>): …` / `supersede(<page>): …` / `archive(<page>): …`. Within a workflow, ops roll up under the workflow prefix instead (D-02) — only a standalone structural action gets its own per-op prefix.

→ Full operation definitions, executor model, batch validation, and per-op preconditions/postconditions: `schema/workflows/structured-operations.md`.

## 10. Compiler Pipeline (Conceptual Model)

```
Source -> [Classify] -> [Diff] -> [Extract] -> [Merge] -> [Lint] -> Wiki
```

→ Claim-granularity rules and the Append-Then-Synthesize incremental-update policy live in `schema/workflows/ingest.md`. Each pass is implemented by the corresponding workflow (see the routing table).

## 11. Workflows

These are the operator procedures that implement the conceptual pipeline (see the routing table above). Each workflow is a complete recipe an LLM agent follows step-by-step.

### 11.1 Ingest Workflow

→ See `schema/workflows/ingest.md` for the full ingest procedure (classify, diff, extract with provenance, merge, lint, log, commit) and the claim-granularity rules.

### 11.2 Query Workflow

**Write-back is mandatory** when a query produces novel or durable synthesis — a new claim, a new connection, a meaningful reframing, or a reusable artifact MUST be compiled back into the wiki (it is not optional).

→ See `schema/workflows/query.md` for the full query procedure, write-back rules, privacy-tier routing, and delta compilation.

### 11.3 Lint Workflow

→ See `schema/workflows/lint.md` for the lint workflow, severity tiers, the CI-mode contract (source of truth for CI severity/JSON/escape-hatch/staged-gate policy), and the 15-step procedure.

### 11.4 Reflect Workflow

→ See `schema/workflows/reflect.md` for the three-tier reflect model, reflect checkpoint, periodic reflect procedure, and decision record authoring.

### 11.5 Brownfield Workflow

→ See `schema/workflows/brownfield.md` for the brownfield vault onboarding workflow: scan, bootstrap, suggest, review-typing, verify subcommands, the `bootstrap_stage` lifecycle, and the `applied.log` per-script shapes.

### 11.6 Release Workflow (Orphan-Branch Publish)

→ See `schema/workflows/release.md` for the orphan-branch template release workflow.

### 11.7 Audit Workflow

→ See `schema/workflows/audit.md` for the review-only claim-faithfulness audit: `bin/audit-claims.sh`, the privacy-partitioned verifier model (FAITH-04), and the audit checkpoint.

## 12. Index and Log

→ See `schema/reference/log-format.md` for the `index.md` content-index entry shape, the `log.md` chronological activity-log format, the structured-operation extended log entries (UPDATE/MERGE/SUPERSEDE/ARCHIVE), and the contributor inline field.

## 13. Privacy Routing

→ See `schema/reference/privacy.md` for the agent-facing tier rules.
  For the full human-facing model: `docs/reference/privacy-model.md`.

## 14. Scaling Boundaries

→ See `docs/reference/scaling.md` for scaling tier heuristics.

## 15. Tooling and Integrations

→ See `docs/reference/tooling.md` for Obsidian, Git, and optional tooling notes.

