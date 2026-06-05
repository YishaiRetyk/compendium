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

Workflows for each operation are defined in Section 11 of this document.

These four operations are the wiki's mutation vocabulary. Layered on top is the **Audit** -- a review-only diagnostic workflow (`bin/audit-claims.sh`, Section 11.7) that checks whether sampled claims semantically follow from the source passage they cite. The Audit never mutates a wiki page; like Lint, it is a workflow, not one of the four mutation operations, so the four-operation framing is preserved.

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
> | Decay table / staleness auto-fix math | `schema/workflows/lint.md` |
> | Creating cross-references (wikilinks) | `schema/reference/wikilinks.md` |
> | Determining `wiki-cloud/` vs `wiki-local/` placement | `schema/reference/privacy.md` |
> | Wiki capacity / scaling signals | `docs/reference/scaling.md` |
> | Obsidian, Git, and optional tools | `docs/reference/tooling.md` |
>
> **Workflows — STILL INLINE in §11 until Phase 17. Do NOT dereference these paths yet;**
> **the authoritative content is §11 below until the file is created in Phase 17.**
>
> | Workflow | Where it lives NOW |
> |----------|--------------------|
> | Ingest | §11.1 (inline). Future home: `schema/workflows/ingest.md` *(Phase 17)* |
> | Query | §11.2 (inline). Future home: `schema/workflows/query.md` *(Phase 17)* |
> | Lint | §11.3 (inline). Decay math already at `schema/workflows/lint.md`; full procedure *(Phase 17)* |
> | Reflect | §11.4 (inline). Future home: `schema/workflows/reflect.md` *(Phase 17)* |

## 2. Directory Structure

```
life/                               # repo root
├── AGENTS.md                       # This file (router; see routing table)
├── sources/                        # Raw immutable sources (cloud-safe-only; see §13)
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

**Permitted top-level directories:** `sources/`, `wiki-cloud/`, `wiki-local/`, `schema/`, `examples/`, `docs/`, `.github/`, `bin/`, `.githooks/`. Content in `examples/` is reference-only (see `example: true` in Section 5); it is skipped by lint and excluded from the published wiki.

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
6. Update `wiki-cloud/index.md`: add the new page, move old pages to "Archived" section (if one exists) or remove them from active listings.
7. Log: `"MERGE <page_a> + <page_b> -> <new_page>: <rationale>"`
7a. **Decision record (inline -- Tier 1):** If this merge represents a significant structural choice -- combining two established pages, resolving a long-standing organizational ambiguity, or eliminating a redundant page that multiple other pages linked to -- create a decision record page in `wiki-cloud/decisions/` with `trigger_type: merge` and `affected_pages` listing both original page IDs and the new merged page ID. Add the new decision record to `wiki-cloud/index.md` under Decisions. Commit the decision record as part of this same commit. **Skip for trivial cleanup merges** (e.g., merging a stub into its parent when the stub has no unique claims). See Section 11.4, Tier 1.

**SUPERSEDE** -- Mark a page or claim as replaced by newer information.

1. Set `superseded_by` on the old page to the replacing page's ID.
2. Set `status: superseded` on the old page.
3. Add a note at the top of the old page body: `> This page has been superseded by [[New Page Title]].`
4. On the new page, set `supersedes` to the old page's ID.
5. Update `wiki-cloud/index.md`: move the old page to "Archived" section or remove from active listings.
6. Log: `"SUPERSEDE <old_page> -> <new_page>: <rationale>"`
6a. **Decision record (inline -- Tier 1):** If this supersession replaces a key page or represents a significant editorial judgment -- the new page substantially reframes the concept, or the superseded page was widely linked -- create a decision record page in `wiki-cloud/decisions/` with `trigger_type: reframing` (if the new page reframes the concept) or `trigger_type: merge` (if consolidating). Set `affected_pages` to include both old and new page IDs. Add to `wiki-cloud/index.md` under Decisions. Commit as part of this same commit. **Skip for routine stale-claim supersessions** (e.g., updating a fact to a newer version without reframing). See Section 11.4, Tier 1.

**ARCHIVE** -- Move outdated content out of active wiki.

1. Set `status: archived` on the page.
2. Remove the page from `wiki-cloud/index.md` active listings (move to an "Archived" section if one exists).
3. The page remains in its directory -- do NOT delete or move files.
4. Log: `"ARCHIVE <page_id>: <rationale>"`

### Executor Model

The LLM proposes operations. Before applying any operation, it MUST validate:

1. **Target exists:** For UPDATE, SUPERSEDE, and ARCHIVE, the target page must exist.
2. **Both pages exist and are distinct:** For MERGE, both source pages must exist and must not be the same page.
3. **Provenance resolves:** All `[prov:...]` references in new content must resolve to known source IDs in `wiki-cloud/sources/` or `wiki-local/sources/`.
4. **Frontmatter is valid:** All required base fields are present and correctly typed (see Section 5 validation checklist).
5. **Privacy is respected:** No `wiki-local/` content is included in operations that will be sent to cloud APIs (§13 asymmetric model).

If validation fails, the LLM MUST NOT apply the operation. Instead, log the validation failure and report it to the user.

Every operation MUST be logged in `wiki-cloud/log.md` with: timestamp, operation type, affected page(s), and rationale. See Section 12 for log format.

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
- Privacy tier: If new content derives from `wiki-local/` sources but target is in `wiki-cloud/`, STOP — see Section 13 and query workflow Section 11.2 privacy rules.

**MERGE**
- Precondition: Both pages exist, are distinct, and both have `status: active`.
- Postcondition: One surviving page contains the combined content. The other page has `status: superseded` and `superseded_by` set to the surviving page's ID. `sources` lists from both pages are merged (union). All provenance markers from both pages are preserved.
- Privacy tier: If either source page is under `wiki-local/`, the surviving page MUST remain under `wiki-local/`.

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

- **Input:** Source document + current wiki state (via `wiki-cloud/index.md`).
- **Process:** Read `wiki-cloud/index.md` to identify existing pages on related topics. Read the TL;DR and Key Facts of those related pages. Determine what the new source adds that the wiki does not already cover.
- **Output:** A mental model of new vs. existing knowledge. This is not a file -- it is the LLM's internal understanding of the delta.

### Pass 2: Extract

Pull structured knowledge from the source.

- **Input:** Source document + type classification from Pass 0.
- **Process:** Apply type-appropriate extraction. Papers get abstract, methodology, results, and conclusions. Transcripts get timestamped claims. Journal entries get reflections and decisions. Extract claims, entities, and relationships, each with a provenance locator (`[prov:source_id#locator]`).
- **Output:** A source summary page created in `wiki-cloud/sources/<source_id>.md` with full frontmatter (including `path`, `content_hash`, `ingested_at`, `source_type`) and all extracted claims with provenance.

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
  - Place new pages in `wiki-cloud/` (for cloud-safe content) or `wiki-local/` (for content deriving from local sources -- §13).
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
  - All new `[prov:...]` markers resolve to valid source IDs in `wiki-cloud/sources/` or `wiki-local/sources/`.
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
4. **Diff** (Pipeline Pass 1): Read `wiki-cloud/index.md`, identify related existing pages, read their TL;DR and Key Facts sections. Determine what this source adds that the wiki does not already cover.
5. **Extract** (Pipeline Pass 2): Extract claims with provenance locators, applying the claim granularity rules from Section 10 Pass 2 based on the source type classified in step 3. Create source summary page at `wiki-cloud/sources/<source_id>.md` (or `wiki-local/sources/` if content derives from a local source -- §13) with full frontmatter including `path`, `content_hash`, `ingested_at`, and `source_type`.
6. **Merge** (Pipeline Pass 3): Update or create entity/concept/overview pages using UPDATE operations (Section 9) and the append-then-synthesize policy (Section 10 Pass 3). Generate wikilinks on first mention. MERGE pages if the source reveals duplicates.
   - 6a. After merge is complete, update the source summary page's compilation tracking fields:
     - Set `compilation_status` to `compiled` if all extracted claims were merged into topic pages, or `partial` if some claims were deferred.
     - Set `compiled_against_hash` to the current `content_hash` value.
     - Set `compiled_targets` to the list of wiki page IDs that received claims from this source (page IDs only, not paths).
7. **Lint** (Pipeline Pass 4): Verify all provenance references resolve, wikilinks are valid, frontmatter is complete on all modified pages.
8. Update `wiki-cloud/index.md` (or `wiki-local/index.md` if applicable) with new and modified pages.
9. Append entry to `wiki-cloud/log.md` (or `wiki-local/log.md` if applicable): `## [YYYY-MM-DD] ingest | <source title>` with affected pages and rationale.
    - 9a. **Contributor attribution (COLAB-03, COLAB-04):** If the log entry is produced via `bin/ingest.sh`, the helper resolves a contributor handle via the following order:
        1. Explicit `--contributor @handle` flag wins (forces emission even on single-author repos).
        2. On single-author repos (`git log --all --format='%ae' | sort -u | wc -l == 1`), the field is omitted entirely.
        3. Otherwise, look up `git config user.email` in `.git-author-map.txt` at the repo root (case-insensitive; format `email  ->  @handle`, `#` comments allowed). On hit, emit `contributor:: @handle` as a Dataview inline body field directly below the `## [YYYY-MM-DD]` log-entry header (see §12).
        4. On map miss, warn to stderr (actionable: suggest `--contributor @handle` or adding the mapping) and OMIT the field. NEVER write a bare email into the `contributor::` field (privacy hygiene + parser consistency).
      Git commit authorship remains the attribution source of truth; `contributor::` is a Dataview convenience index.
10. Commit: `ingest(<source-slug>): <one-line summary>`

**Abort conditions:**

- Source is unreadable or corrupted. Log failure in `wiki-cloud/log.md`, do NOT create partial wiki pages.
- Source duplicates an already-ingested source (check `content_hash` against existing source summary pages). Log the duplicate detection, do NOT re-ingest.
- Privacy tier cannot be determined. Default to `wiki-local/` placement and log the classification gap.

### 11.2 Query Workflow

```
Trigger:  User asks a question about the wiki contents
Inputs:   User question (natural language)
Outputs:  Cited answer, optionally new/updated wiki pages, updated index/log
Commit:   query(<topic>): <one-line summary>
```

**Steps:**

1. **Search** -- Read `wiki-cloud/index.md` to find pages relevant to the question. Optionally use `bin/search.sh` to identify candidates.
2. **Shallow read** -- Read TL;DR and Key Facts sections of relevant pages (progressive disclosure -- shallow first).
3. **Deep read** -- Read Detail sections only where shallow content is insufficient to answer the question.
4. **Synthesize** -- Compose answer with citations to specific wiki pages and inline provenance markers.
5. **Write-back decision** -- Determine whether the answer should be written back to the wiki (see Write-Back Rules below).
6. **Delta compilation** -- Check for uncompiled or stale sources relevant to this query (see Delta Compilation below).
7. **Apply write-back** -- If write-back is triggered, apply using structured operations (Section 9). Run `bin/validate-op.sh` before applying each operation.
8. Update `wiki-cloud/index.md` (or `wiki-local/index.md` if applicable) if new pages were created or existing pages were significantly modified.
9. Append entry to `wiki-cloud/log.md` (or `wiki-local/log.md` if applicable) (see Query Log Entry Format below).
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

#### Privacy Tier for Write-Back

**Deterministic structural rule (§13 asymmetric model):** If ANY source contributing to the synthesis lives under `wiki-local/` (its source-summary is in `wiki-local/sources/`), the write-back target page MUST go into `wiki-local/`. A page in `wiki-cloud/` may cite only sources whose summaries are under `wiki-cloud/sources/`. This is a structural check, not a judgment call.

**How to apply:**
1. Collect all source IDs referenced in the synthesized answer (from provenance markers and the `sources` frontmatter list of pages read).
2. Check each source-summary's tier: is the summary page under `wiki-cloud/sources/` or `wiki-local/sources/`?
3. If ANY contributing source summary is under `wiki-local/`, the write-back target belongs in `wiki-local/`.
4. If updating an existing `wiki-cloud/` page with `wiki-local/`-sourced content: STOP. Either (a) create a new page in `wiki-local/` for the sensitive synthesis, or (b) move the existing page to `wiki-local/` if appropriate.
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

Append to `wiki-cloud/log.md`:

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

- No relevant pages exist AND no sources exist on the topic. Inform the user that the wiki has no information on this topic rather than hallucinating an answer. Log the knowledge gap in `wiki-cloud/log.md` so the lint workflow can track it.

#### Worked Example

**Question:** "What <OVERVIEW_NAME> are related to <CONCEPT_NAME_2>?"

1. **Search:** `bin/search.sh "<concept-slug-2>"` returns matching concept and overview pages under `wiki-cloud/concepts/`.
2. **Shallow read:** Read TL;DR of all three pages. `<concept-slug-2>.md` covers the core item. `<overview-slug>.md` lists item families. `<concept-slug>.md` frames the item within the broader concept.
3. **Deep read:** Read Detail section of `<overview-slug>.md` to find family relationships.
4. **Synthesize:** Answer cites all three pages with provenance markers.
5. **Write-back decision:** The answer connects `<concept-slug-2>` to specific families in a way not explicitly articulated in any single page. Trigger: "new connection between existing pages." Decision: UPDATE the relevant concept page to add a new subsection.
6. **Delta compilation:** Check sources. `<source-slug>.md` has `compilation_status: compiled`. No delta needed.
7. **Apply:** Run `bin/validate-op.sh UPDATE wiki-cloud/concepts/<page>.md` -> PASS. Apply UPDATE using append-then-synthesize policy.
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
Inputs:   wiki-cloud/ directory (all pages)
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

> **Source of truth for Phase 9 / Phase 12.2 CI + local-gate contracts.** This section is the authoritative specification for: (a) the severity-remap dispatch table, (b) the `--format json` output schema, (c) the escape-hatch marker contract, (d) the `--require-version` semantics, and (e) the `--staged` local-write-gate contract (Phase 12.2). Other docs (`docs/reference/ci.md`, `CONTRIBUTING.md`, `.github/workflows/lint.yml` comments) MUST link here rather than restating the policy. Drift between this section and the shipped code is a regression.

`bin/lint.sh` supports a CI operating profile via several independent, orthogonal flags:

| Flag | Effect |
|------|--------|
| `--format json` | Emit JSON array `[{severity, category, path, line?, message}]` to stdout; do NOT write `lint-report.md`. |
| `--ci` | Apply severity-remap dispatch table: `yaml`/`orphan`/`crossref`/`provenance`/`linkres` -> `error`; `stale`/`gap`/`contradiction`/`contradiction-sync`/`drift`/`contributor` -> `warning`; `autofix`/`skip-count` -> `info`. Default-skip `drift-external` category. Exit 1 iff any post-remap finding has severity `error`. |
| `--skip-category <cat>` | Exclude one category. Repeatable. Inverse of `--category`. |
| `--strict` | Quality ratchet: fail on (a) new `[epistemic:: inferred]` / `[epistemic:: tentative]` claims without a matching decision record whose `affected_pages` frontmatter contains the page ID; (b) new (git-diff status `A`) pages of type `entity`/`concept`/`overview`/`comparison` with zero `[prov:` markers. Source pages and decision records are exempt by design. |
| `--staged` | Phase 12.2 local-write-gate scope swap. With `--strict`, replaces the diff source from `git diff origin/main...HEAD` to `git diff --cached --name-only --diff-filter=A` and applies D-10 (new-page provenance) ONLY — D-08 (DR-match) stays CI-only. Files are read from the working tree, not from staged blobs. No-op without `--strict`. Used by `.githooks/pre-commit`. See "Staged-mode rules" below. |
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

**Staged-mode rules (`--staged`, Phase 12.2):**

`bin/lint.sh --staged` is the local-write-gate scope swap. The `.githooks/pre-commit` hook invokes `bash bin/lint.sh --strict --staged --category provenance` after the AGENTS.md ↔ CLAUDE.md sync check. Rules:

1. **Requires `--strict`.** `--staged` is a no-op without `--strict` (no provenance enforcement; standard categories run as usual). The pre-commit hook always passes both flags together.
2. **Diff source:** `git diff --cached --name-only --diff-filter=A` (status-A entries in the staged index). Files are read from the WORKING TREE, not from staged blobs — pre-commit hooks fire after `git add`, so working-tree content matches the index for the typical add-then-commit flow. If you `git add foo.md && echo extra >> foo.md && git commit`, the gate sees the dirty version (which already contains the staged content); known caveat, not a bug.
3. **Scope:** D-10 (new-page provenance) ONLY. Pages staged as status-A under `wiki-cloud/{entities,concepts,overviews,comparisons}/` must contain at least one `[prov:` marker. D-08 (DR-match for added inferred/tentative claims) stays CI-only — not enforced at commit time.
4. **Exemption ordering** (first match wins):
   1. Path NOT under `wiki-cloud/{entities,concepts,overviews,comparisons}/` — not gated.
   2. Path under `examples/` anywhere in the tree — not gated (path-prefix exemption, mirrors `EXCLUDE_DIRS` for full-lint).
   3. Frontmatter `type: source` — not gated (source pages are themselves the provenance anchors).
   4. Frontmatter `type: decision` — not gated (decision records are the gating mechanism, can't gate on themselves).
   5. Frontmatter `example: true` — not gated (reference content, anywhere in the tree).
   6. Frontmatter `bootstrap_stage: bootstrapped` — not gated (brownfield in-flight; provenance-bootstrap migration `02-provenance-bootstrap.sh` adds markers later).
5. **`bootstrap_stage: verified` is NOT exempt.** Pages promoted through the brownfield 5-gate `verify --promote` flow are first-class wiki content from the gate's perspective — they must carry `[prov:]` markers like any other entity / concept / overview / comparison page.
6. **Exit policy:** reuses `--strict`'s contract — exit 1 iff any post-remap error-severity finding exists. `provenance` already maps to `error` in the severity remap.
7. **Bypass:** `git commit --no-verify` only. No `WGATE_SKIP=1` env var. No per-page `wgate_exempt: true` frontmatter (would create a permanent bypass surface defeating the gate's purpose). Per AGENTS.md §3, `--no-verify` is the operator's escape hatch — use rarely, document the reason in the commit message when used.
8. **Hook activation:** `bash bin/install-hooks.sh` once per clone. The hook composes the existing AGENTS.md ↔ CLAUDE.md sync check (runs first; can re-stage CLAUDE.md) with the new write-gate (runs second; read-only over the staged index).

**Failure UX:** when the gate blocks, `bin/lint.sh` prints per-page `error/provenance/<path>: new <type> page has zero [prov:...] markers (D-10; ...)` lines, and the hook appends a single trailing footer line listing the three actionable paths (add `[prov:source_id#locator]` markers, set `type: source` / `type: decision` in frontmatter if it's not a synthesized page, or `git commit --no-verify` to bypass).

**Steps:**

1. Read `wiki-cloud/index.md` for full page inventory. Build resolution map: for each wiki page, collect filename, id, title, and aliases (case-insensitive matching).
2. **YAML frontmatter validation:** Parse all page frontmatter, check required fields, validate enum values against Section 5 schema. Severity: error for parse failures or missing required fields.
3. **Provenance validation:** Verify all `[prov:]` references resolve to known source IDs in `wiki-cloud/sources/` or `wiki-local/sources/`. Verify locator syntax. Severity: error for broken refs.
4. **Orphan detection:** Find pages with no inbound wikilinks from other wiki pages (using resolution map for alias-aware, case-insensitive matching). Exclude index.md, log.md, lint-report.md. Severity: warning. Report-only.
5. **Missing cross-references:** Identify pages sharing 2+ domains AND 2+ tags that lack mutual wikilinks. Only flag for active pages (not archived/superseded). Severity: warning. Report-only.
6. **Stale claims:** Compute staleness using domain decay rate table (Section 6), epistemic modifier, and hash override. Date fallback chain: `checked_at` -> `ingested_at` -> `updated_at`. Severity: warning. Auto-fix: add/update `[epistemic:: stale]` markers per Staleness Auto-Fix Rules.
7. **Potential contradiction candidates:** Flag wiki page sections where claims carry `[prov:]` markers from 2+ different source_ids AND the section is NOT on a page of type `comparison` or `overview` (these are inherently multi-source by design). Mark as "potential contradiction candidates for agent review." The lint does NOT assert these ARE contradictions -- the LLM agent running the lint workflow reviews flagged sections and promotes confirmed disagreements to `[contradiction:]` inline markers. Severity: warning. Report-only.
8. **`has_contradictions` sync:** Verify that `has_contradictions` frontmatter matches actual presence of `[contradiction:]` markers in the body. Auto-fix: set `true` if markers present, `false` if no markers present.
9. **Knowledge gaps (red links):** Collect unresolved wikilinks. Flag when: appears on 2+ distinct pages, OR appears in TL;DR/Key Facts section of any page (per D-20). Severity: info. Report-only. Suggest investigative question per D-23.
10. **Source coverage gaps:** Compare domain source counts. Flag domains with materially fewer sources than median. Only run when wiki has 5+ distinct knowledge_domain values with at least 3 having 2+ source pages (maturity guardrail per D-22). Use `knowledge_domain` consistently for both page classification and source counting. Severity: info. Report-only. Suggest investigative question per D-23.
11. **Near-duplicate pages (category: `duplicate`):** Flag same-`type` page pairs that are lexical near-duplicates -- candidate iff one page's title/alias contains the other's title/alias as a case-insensitive substring (contained length > 5), OR Levenshtein distance < 3 on titles longer than 5 chars. Survivor = the page with more inbound wikilinks (tie -> lexicographically-first id). One finding per pair. Severity: warning. Report-only -- feeds the human-confirmed MERGE operation (Section 9); never auto-merges. Excludes `EXCLUDE_DIRS`/`examples/`, `example: true`, and archived/superseded pages. Pure-stdlib (no embeddings) -- semantic dedup is a deferred Tier-4 extension.
12. **Drift detection (category: `drift`):** Run cross-system drift checks. These detect misalignment between the wiki layer and its dependencies.
    - **Unrepresented sources (DRFT-01):** Walk `sources/` directory for `.md` files, check each has a corresponding wiki source summary page (matching the `path` field in source page frontmatter). Severity: warning.
    - **Missing source files (DRFT-02):** For each source summary page, verify the raw source file at the `path` frontmatter field exists on disk. Severity: error.
    - **Content-hash drift:** Recompute SHA-256 of the raw source file, compare against `content_hash` in source summary frontmatter. If mismatch: report finding (severity: warning). When `--fix` is passed, auto-fix `compilation_status` to `stale` on the affected source page. See Section 10 compilation status transitions.
    - **Index coverage:** Verify every wiki page (excluding index.md, log.md, and maintenance/ pages) has a wikilink entry in its tier index (`wiki-cloud/index.md` or `wiki-local/index.md`). Severity: warning.
    - **Obsidian vault awareness (DRFT-03):** Verify `.obsidian/` directory exists (info if missing). Check for non-markdown files in `wiki-cloud/` subdirectories (severity: info).
    - **Orphaned operation artifacts (DRFT-04):** Detect operations that finished their file edits but skipped their commit, leaving `wiki-cloud/log.md` asserting `pages_affected` the wiki does not contain as committed files (the failure mode where a later operation's commit flushes the shared append-only `log.md` while the orphaned page/index edits dangle untracked). Read the COMMITTED `log.md` (`git show HEAD:wiki-cloud/log.md`) and, for each `pages_affected:` page ID (excluding the non-page tokens `index`, `log`, `lint-report`, `reflect-state`, `none`), verify a git-tracked wiki page with that `id` exists (resolved against pages' actual `id` frontmatter, not filename stems, so a page whose id ≠ filename — itself a yaml-check error — does not also produce a spurious orphan finding). Reading the committed log — not the working tree — means an in-flight operation whose fresh log entry is itself still uncommitted alongside its page is NOT flagged; only entries already in HEAD are audited. Scope: the machine-parseable `pages_affected:` field (query-workflow format, §11.2 Query Log Entry Format). Severity: warning. Report-only. Requires git; silently skips outside a git repo.
13. Compile findings into `wiki-cloud/maintenance/lint-report.md` organized by severity then category. Findings are grouped with category subsections (e.g., `### Drift` under `## Warnings`). Include total counts and per-category breakdowns.
14. Append entry to `wiki-cloud/log.md`: `## [YYYY-MM-DD] lint | <scope>` with summary of findings counts and auto-fixes applied.
15. Commit: `lint(<scope>): <one-line summary of findings and fixes>`

**Categories** (valid values for `--category` filter): `orphan`, `crossref`, `stale`, `contradiction`, `gap`, `provenance`, `yaml`, `drift`, `duplicate`.

**Abort conditions:**

- Wiki is empty (no pages beyond `index.md` and `log.md`). Report that the wiki is empty and skip the lint. Log this in `wiki-cloud/log.md`.

### 11.4 Reflect Workflow

The reflect workflow creates decision records (see Section 4.6) that capture why structural changes were made to the wiki. It operates through three tiers, from automatic to manual.

```
Trigger:  After structural operations, on workflow recommendation, or periodically
Inputs:   Recent changes (from wiki-cloud/log.md and git history), reflect checkpoint state
Outputs:  Decision record page(s) in wiki-cloud/decisions/, updated index/log, advanced checkpoint
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

This message is appended to the workflow's log entry in `wiki-cloud/log.md`. It is NOT an automatic action. The agent or human decides whether to act on it in a subsequent reflect pass or immediately.

**Tier 3 -- Manual/periodic reflect:** A safety-net pass that scans recent activity and backfills missed decision records. Run periodically (e.g., after several ingests or a batch of structural changes) or when the operator suspects structural decisions went unrecorded.

#### Reflect Checkpoint

The reflect checkpoint lives at `wiki-cloud/maintenance/reflect-state.md`. It tracks where the last reflect pass ended so subsequent passes resume from the correct position, even when a pass produces no decision records.

Fields (in frontmatter):
- `last_reflect_log_entry`: The full heading line of the last log entry scanned (e.g., `"## [2026-04-14] lint | wiki health check"`)
- `last_reflect_commit`: The short SHA of the last git commit inspected (e.g., `"abc1234"`)
- `last_reflect_at`: ISO 8601 date of the last reflect pass (e.g., `2026-04-14`)

`wiki-cloud/maintenance/` is a control-plane directory for cloud-tier infrastructure. Files here (lint-report.md, reflect-state.md) are NOT listed in wiki-cloud/index.md -- they are infrastructure, not content. `wiki-local/maintenance/` holds the audit control-plane (audit-report.md, audit-state.md).

#### Periodic Reflect Procedure (Tier 3)

1. Read the reflect checkpoint from `wiki-cloud/maintenance/reflect-state.md`.
2. Scan `wiki-cloud/log.md` for entries after `last_reflect_log_entry`. Identify:
   - Structural operations: MERGE, SUPERSEDE, ARCHIVE entries
   - Schema changes: entries referencing AGENTS.md modifications
   - Workflow recommendations: lines matching `reflect recommended: [trigger_type] -- [reason]`
3. Inspect `git log --oneline` for commits after `last_reflect_commit`. Look for structural file changes: new/deleted/renamed pages, template modifications, AGENTS.md updates, directory reorganizations. **Deduplication rule:** If both log.md and git show the same event, use the log.md entry as the primary trigger (it has intent). Git-only changes (no log entry) indicate unrecorded structural work and should be investigated.
4. For each identified structural change that lacks a corresponding decision record:
   a. Create a decision record page in `wiki-cloud/decisions/` using the decision template (Section 4.6).
   b. Set `trigger_type` to the most appropriate value from the six allowed types.
   c. Set `affected_pages` to the IDs of pages touched by the change.
   d. Fill all 7 required sections with real content (not placeholders). The "Why" section must state what framing was adopted and what it replaced. "Alternatives Considered" must list at least one alternative.
   e. Add the decision record ID to `decision_history` on each affected page's frontmatter (only when meaningful per D-05).
5. Update `wiki-cloud/index.md` with new decision record entries under the Decisions category.
6. Append entry to `wiki-cloud/log.md`: `## [YYYY-MM-DD] reflect | <scope>` with a summary of how many decision records were created, or "no structural changes detected" if none.
7. Advance the reflect checkpoint: update `last_reflect_log_entry` to the most recent log entry heading, `last_reflect_commit` to current HEAD short SHA, `last_reflect_at` to today's date. **A reflect run that produces no decision records still advances the checkpoint.**
8. Commit: `reflect(<scope>): <one-line summary>`

#### Abort Conditions

- No structural changes detected since the last checkpoint AND no pending workflow recommendations. Advance the checkpoint (step 7) and skip record creation. Log: `## [YYYY-MM-DD] reflect | no structural changes detected`.
- Log entry for a structural operation already has a corresponding decision record in `wiki-cloud/decisions/` (check by date + scope match). Skip that event -- already recorded.

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

Template releases use an orphan-branch workflow that publishes a neutralized snapshot of the repo without the creator's personal `wiki-cloud/` + `wiki-local/` content. See `docs/reference/release.md` for the full runbook.

### 11.7 Audit Workflow

The Audit is a **review-only** diagnostic workflow. It is NOT a fifth top-level operation -- the four-operation framing (Ingest / Query / Lint / Reflect) is preserved (Section 1). The Audit is layered on top, analogous to how Lint is a workflow rather than one of the four mutation operations. It adds no wiki page type.

```
Trigger:  Operator runs bin/audit-claims.sh on-demand; OR a non-binding
          "audit recommended" note surfaces during a lint run.
Inputs:   wiki-cloud/ + wiki-local/ pages with [prov:] claims + the raw sources at their path:.
Outputs:  wiki-local/maintenance/audit-report.md (+ lint-compatible JSON), advanced
          wiki-local/maintenance/audit-state.md checkpoint. NO wiki page is mutated.
Commit:   N/A by default (the audit writes only control-plane artifacts; the
          operator commits the report if they wish to track it).
```

**What it is.** `bin/audit-claims.sh` is a source-grounded, review-only audit. It samples high-risk claims, resolves each `[prov:source_id#locator]` to the cited passage in the **raw** source file at the source page's `path:` (never the source summary's `## Extracted Claims` -- that would be circular), and emits a verdict per claim: `supports` / `weak` / `contradicts` / `insufficient`, plus the operational verdicts `insufficient-locator` (no passage extractable -- e.g. a `#p` locator against an unmarked source per the Section 6 page-marker convention), `skipped-privacy` (withheld for privacy), and `skipped-nontext` (`#img`). Findings extend Lint's `{severity, category, path, message}` tuple with `verdict`, `line`, `source_id`, `locator`, and `rationale`, and are written to `wiki-local/maintenance/audit-report.md` (the pattern-twin of `lint-report.md`), grouped by verdict. The audit NEVER mutates a wiki page, never gates by default (no `error` severity -- `contradicts` maps to `warning`, the rest to `info`), and runs on-demand.

**Cadence.** The primary path is operator-invoked (`bin/audit-claims.sh`). Additionally, the Lint workflow MAY emit a non-binding `audit recommended: <reason>` note (the Section 11.4 Tier-2 recommendation pattern) when high-risk-claim counts cross a threshold -- Lint already computes the stale / epistemic / orphan signals, so it is the cheapest host. This note is **informational only**: it does not run the audit, and the audit is never a CI gate in v1.

**Privacy (the load-bearing FAITH-04 contract).** The audit resolves each claim's **effective claim privacy** via the §13 structural predicate: a claim is effective-`local_only` iff its page OR any contributing source-summary lives under `wiki-local/`. This is NOT "source privacy" alone: the worklist payload carries the wiki page's own claim text, so a page under `wiki-local/` citing a `wiki-cloud/` source must still be withheld. Effective-`local_only` claims are withheld (their claim text AND the resolved passage) from BOTH the verifier subprocess AND the `--emit-worklist` stdout -- the partition gates every passage-bearing egress surface, not just the subprocess. Withheld claims emit a `skipped-privacy` verdict; on a primarily-local vault, a high `skipped-privacy` count is acceptable, expected UX (it satisfies FAITH-04 without forcing a local-model dependency), not a failure to pad around.

On the cloud-facing `--emit-worklist` stdout, a withheld claim's `skipped-privacy` metadata (`source_id` / `path` / `locator`) is redacted to a bare aggregate count; full per-record detail is written only to the local-control-plane `audit-report.md` under `wiki-local/maintenance/`. This keeps even the existence-metadata of local-only claims off the cloud-facing surface.

**Verifier-locality model.** Every `--verifier <cmd>` is treated as cloud / egress **by default**. The audit NEVER infers a verifier's locality from its command -- locality is an operator assertion via a flag, never a guess. An effective-`local_only` passage (from a page or source under `wiki-local/`) is admitted to a verifier ONLY via an explicit `--allow-local` flag (with `--local-verifier <cmd>` documented as sugar for `--verifier <cmd> --allow-local`). The script enforces this mechanically; the docs must never describe a weaker "local verifier auto-detected" behavior.

**The contradicts → marker handoff (D-10).** The audit stays strictly report-only. A human or agent MAY, as a SEPARATE explicit operation, add an `[epistemic:: tentative]` or a `[contradiction:source_a#locator vs source_b#locator]` marker (Section 6) to a claim with a confirmed `contradicts` verdict, then sync `has_contradictions` per the Lint mechanics (Section 11.3). This is **never automatic** -- the audit produces a finding; a subsequent human-approved decision promotes it to a marker.

**Checkpoint.** `wiki-local/maintenance/audit-state.md` (frontmatter `last_audit_commit`, `last_audit_at`, `last_sample_size`) mirrors `reflect-state.md`. It is control-plane (not listed in `wiki-cloud/index.md`) and advances even on a no-finding run.

## 12. Index and Log

### index.md (Content Index)

- Lives at `wiki-cloud/index.md`.
- Organized by page type: Entities, Concepts, Sources, Comparisons, Overviews, Decisions.
- Each entry follows the format: `- [[Page Title]] -- <one-line summary> (<epistemic_status>, <updated_at>)`
- Updated on every ingest and every query that creates or modifies pages.
- The LLM reads this FIRST when searching for information (per Section 3 LLM Navigation Rule). A `wiki-local/index.md` is created lazily for local-only navigable content (D-07).
- Archived pages are listed separately under an "Archived" heading if any exist.
- The index is the primary navigation mechanism for both LLMs and humans browsing the wiki.

### log.md (Activity Log)

- Lives at `wiki-cloud/log.md`.
- Chronological, newest entries at the bottom (append-only).
- Entry format:

```markdown
## [YYYY-MM-DD] <operation_type> | <description>

<what was done, which pages were affected, brief rationale>
```

- Valid operation types: workflow-level (`ingest`, `query`, `lint`, `reflect`) and structured operations (`UPDATE`, `MERGE`, `SUPERSEDE`, `ARCHIVE`). Structured operations use the extended format below.
- Each entry includes: what was done, which pages were affected, and a brief rationale.
- The log is parseable with: `grep "^## \[" wiki-cloud/log.md | tail -5`
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
- `bin/lint.sh` category `contributor` (severity `warning`) catches `@handle` values in `wiki-cloud/log.md` whose `.git-author-map.txt` email does NOT appear in `git log --all --format='%ae'` -- non-blocking consistency check. Skipped on single-author repos.

**Queryable via Dataview:**

```dataview
LIST
FROM "wiki-cloud/log.md"
WHERE contains(file.lists.text, "contributor:: @octocat")
```

## 13. Privacy Routing

→ See `schema/reference/privacy.md` for the agent-facing tier rules.
  For the full human-facing model: `docs/reference/privacy-model.md`.

## 14. Scaling Boundaries

→ See `docs/reference/scaling.md` for scaling tier heuristics.

## 15. Tooling and Integrations

→ See `docs/reference/tooling.md` for Obsidian, Git, and optional tooling notes.

