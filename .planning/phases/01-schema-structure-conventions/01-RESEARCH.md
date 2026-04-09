# Phase 1: Schema, Structure & Conventions - Research

**Researched:** 2026-04-08
**Domain:** Obsidian vault schema design, AGENTS.md specification, YAML frontmatter conventions, Dataview compatibility
**Confidence:** HIGH

## Summary

Phase 1 is a documentation-and-structure phase. No code is written -- the deliverables are: (1) the AGENTS.md schema document, (2) the directory skeleton (`sources/`, `wiki/`, optional `schema/`), (3) git setup with commit conventions. The primary technical constraints come from Obsidian compatibility (wikilinks, Dataview-compatible YAML frontmatter, graph view), not from any programming framework.

The user has made extensive locked decisions (35 decisions in CONTEXT.md) covering schema outline, directory layout, frontmatter fields, provenance syntax, progressive disclosure format, commit conventions, scaling heuristics, and privacy routing. Research focuses on validating these decisions against Obsidian/Dataview technical realities, identifying pitfalls, and filling in the discretion areas (template format, source registry implementation, exact wording).

**Primary recommendation:** Write AGENTS.md as the single authoritative spec following the 16-section outline (D-35). Use snake_case for all frontmatter field names for Dataview compatibility. Keep wikilinks in page body only (not frontmatter) to guarantee graph view integration. Use plain string IDs in frontmatter `sources` fields, with wikilinks in the body's Sources section.

<user_constraints>

## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Single monolithic AGENTS.md file at repo root containing all rules, conventions, and workflows. Optional supporting files for templates/examples in schema/ directory.
- **D-02:** Named AGENTS.md (not CLAUDE.md) -- agent-agnostic so any LLM can discover and follow it.
- **D-03:** Prescriptive step-by-step workflows in the schema itself. The schema is the sole authoritative source -- no dependency on external skills or tool-specific wrappers.
- **D-04:** All four workflows (ingest, query, lint, reflect) defined in Phase 1 even though they aren't built until later phases. The schema is the spec -- complete upfront.
- **D-05:** Three siblings at root: `sources/`, `wiki/`, and `AGENTS.md`. Optional `schema/` for templates/examples.
- **D-06:** Wiki organized by page type subdirectories: `wiki/entities/`, `wiki/concepts/`, `wiki/sources/`, `wiki/comparisons/`, `wiki/overviews/`. Categories/topics represented via frontmatter fields (tags, domains), wikilinks, and Dataview views -- not filesystem hierarchy.
- **D-07:** `index.md` and `log.md` live inside `wiki/` (they are LLM-maintained wiki-layer artifacts).
- **D-08:** Sources organized chronologically with directory nesting: `sources/YYYY/YYYY-MM/YYYY-MM-DD-slug/`. Per-source bundle folder when assets exist (source.md + attachments together). Single file for text-only sources. Optional global `sources/assets/` only for genuinely shared or tool-managed assets.
- **D-09:** Source metadata (type, topic, privacy) stored as metadata in the source file, not as primary directory structure.
- **D-10:** Required base frontmatter fields for every wiki page: `id`, `title`, `type`, `status`, `summary`, `created_at`, `updated_at`, `sources`, `epistemic_status`, `tags`, `domains`, `supersedes`, `superseded_by`, `privacy`. These cover identity, lifecycle, summary, source linkage, and retrieval.
- **D-11:** No `confidence` field -- `epistemic_status` (sourced, mixed, tentative, stale) is sufficient at page level.
- **D-12:** Detailed provenance blobs, relation fields, decay settings, decision metadata, comparison dimensions, and source URLs belong in type-specific schemas, not the base.
- **D-13:** Inline provenance syntax: `[prov:<source_id>#<locator>]`. Extended form: `[prov:<source_id>#<locator>|<support_type>|<checked_at>]`.
- **D-14:** Locator types: `#p12-14` (page range), `#sec:introduction` (section), `#para3` (paragraph), `#t00:12:10-00:12:48` (timestamp for transcripts), `#img2` (image reference).
- **D-15:** Support types: `direct`, `inferred`, `tentative`, `derived` (optional, for synthesis distinct from weaker inference).
- **D-16:** `checked_at` / `verified_at` field (not generic date) -- records when the provenance link was last verified.
- **D-17:** Source registry (frontmatter or sidecar file) mapping source IDs to: `source_id`, `path`, `title`, `source_type`, `url` (if applicable), `content_hash`, `ingested_at`.
- **D-18:** Validation rules: every `prov:` reference must resolve to a known source; every locator must be syntactically valid; optional stronger check -- if source `content_hash` has changed, mark linked claims stale.
- **D-19:** Standard shallow-to-deep section order for all pages. Top optimized for fast scanning, bottom for verification.
- **D-20:** Entity/concept pages: `## TL;DR` -> `## Key Facts` -> `## Detail` -> `## Related Pages` -> `## Sources`.
- **D-21:** Source summary pages: TL;DR -> Key Takeaways -> Extracted Claims -> Notes -> Source Metadata.
- **D-22:** Comparison pages: TL;DR -> Bottom Line -> Comparison Table -> Detailed Comparison -> Sources.
- **D-23:** Decision pages: TL;DR -> Decision -> Why -> Alternatives Considered -> Consequences -> Sources.
- **D-24:** TL;DR must be short enough that an LLM can scan many pages quickly. Key Facts must be skimmable and citation-friendly. Nuance and long prose go in Detail. Sources at the bottom.
- **D-25:** Conventional commit format with wiki operation types: `ingest(source-slug):`, `query(topic):`, `lint(scope):`, `reflect(scope):`, `schema:`.
- **D-26:** One commit per logical operation (not per file, not per pipeline pass). A single ingest touching 10-15 files is one commit. Rule: if the change answers "what happened?" with one sentence, it's one commit.
- **D-27:** Named tiers with approximate heuristics, explicitly labeled as heuristics not hard boundaries. Signal-based language alongside approximate numbers.
- **D-28:** Approximate starting heuristics: split index around a few hundred pages; incremental lint when full lint discourages use; DB-backed metadata when provenance/search/concurrency become awkward in markdown.
- **D-29:** Layered privacy model with fail-closed semantics. Three-level precedence: (1) explicit frontmatter on the item, (2) enclosing directory default, (3) system default = `local_only`.
- **D-30:** Directory-level defaults for operational convenience (e.g., `sources/local-only/`, `sources/cloud-safe/`). Frontmatter is the authoritative item-level declaration when present. If directory and frontmatter conflict, prefer the stricter setting.
- **D-31:** Routing logic must never send `local_only` content to cloud models. Unresolved items default to `local_only`.
- **D-32:** Link on first mention per page. Subsequent mentions are plain text. Standard wiki convention.
- **D-33:** Red links allowed -- link to pages that don't exist yet. Obsidian shows these as unresolved; lint workflow uses them to detect knowledge gaps (GAP-01).
- **D-34:** Exact title match for wikilinks -- `[[Attention Mechanism]]` not `[[Attention Mechanism|attention]]`. Use `aliases` frontmatter field for alternate names that Obsidian resolves automatically.
- **D-35:** AGENTS.md follows a 16-section outline (see CONTEXT.md for full list).

### Claude's Discretion

- Template file format and exact content within schema/ directory
- Exact wording of scaling tier descriptions
- Internal structure of workflow subsections (as long as they are prescriptive step-by-step)
- Source registry implementation detail (frontmatter vs sidecar file -- pick based on what works best with Dataview)

### Deferred Ideas (OUT OF SCOPE)

None -- discussion stayed within phase scope.

</user_constraints>

<phase_requirements>

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SCHM-01 | Agent-agnostic schema document (AGENTS.md) that tells any LLM how to maintain the wiki | AGENTS.md spec is a flexible markdown format (no rigid structure required); D-02 locks the filename; D-35 locks the 16-section outline |
| SCHM-02 | Schema covers all workflows: ingest, query, lint, reflect | D-04 requires all four defined upfront; workflow subsection structure is Claude's discretion |
| SCHM-03 | Schema defines page type conventions and when to use each type | D-06 locks five page types; D-20 through D-23 lock section orders per type |
| SCHM-04 | Schema defines frontmatter fields and their semantics | D-10 locks base fields; Dataview compatibility research constrains field naming (snake_case, ISO dates) |
| SCHM-05 | Schema defines structured operations vocabulary (UPDATE, MERGE, SUPERSEDE, ARCHIVE) | Operations spec only -- implementation is Phase 4 |
| DIRS-01 | Raw sources directory for immutable input documents | D-05 locks `sources/` at root; D-08 locks chronological nesting |
| DIRS-02 | Wiki directory for LLM-maintained markdown pages | D-05 locks `wiki/` at root; D-06 locks type subdirectories |
| DIRS-03 | Clear separation between source layer and wiki layer | D-05 locks three siblings structure |
| DIRS-04 | Git-tracked repository with meaningful commit conventions | D-25 and D-26 lock conventional commit format and granularity |
| OBSD-01 | All wiki pages use valid Obsidian wikilinks for cross-references | D-32, D-33, D-34 lock wikilink conventions; research confirms `[[Title]]` format works with Obsidian graph |
| OBSD-02 | All wiki pages have Dataview-compatible YAML frontmatter | Research confirms Dataview auto-reads all YAML frontmatter; snake_case naming, ISO 8601 dates, YAML lists for multi-value |
| OBSD-03 | Wiki structure is graph-view friendly (meaningful links, not noise) | D-32 (first-mention linking) prevents noise; body-only links guarantee graph integration |
| OBSD-04 | Frontmatter supports Dataview queries for dynamic tables and lists | Dataview supports TABLE/LIST queries over all frontmatter fields; `tags`, `domains`, `type`, `status` are all queryable |
| PROG-01 | All wiki pages start with TL;DR / key facts section | D-19, D-20 lock progressive disclosure order |
| PROG-02 | Detail sections follow progressive depth (summary -> analysis -> raw data/sources) | D-20 through D-24 lock per-type section ordering |
| PROG-03 | Schema instructs LLM to read shallow summaries first, drill down only where needed | Must be explicit instruction in AGENTS.md Section 7 (Progressive Disclosure) |
| BNDY-01 | Schema distinguishes markdown-first baseline (v1) from optional scale upgrades | D-27, D-28 lock signal-based heuristic approach |
| BNDY-02 | Privacy-tiered routing: schema supports marking sources/pages as local-only vs. cloud-safe | D-29, D-30, D-31 lock layered fail-closed privacy model |
| BNDY-03 | Scaling boundary documented as provisional heuristics | D-27 explicitly labels heuristics, not hard boundaries |

</phase_requirements>

## Standard Stack

This phase has no software dependencies. It produces markdown files and a git repository.

### Core

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| Obsidian | 1.7+ | Human reading/browsing interface | User's chosen interface; Properties system (1.4+) supports typed frontmatter |
| Dataview plugin | 0.5+ | Dynamic queries over frontmatter | De facto standard for structured Obsidian queries; reads all YAML frontmatter automatically |
| Git | 2.x | Version control | Required by D-04; provides history and collaboration for free |

### Supporting

| Tool | Purpose | When to Use |
|------|---------|-------------|
| Obsidian Graph View | Visualize wiki link structure | Built-in; validates OBSD-03 (meaningful links) |
| Obsidian Aliases | Alternative names for pages | Built-in; supports D-34 (exact title match + aliases) |

No `npm install` or package setup is needed. This is a documentation-and-structure phase.

## Architecture Patterns

### Recommended Project Structure

```
life/                           # repo root
├── AGENTS.md                   # The schema (sole authority)
├── sources/                    # Raw immutable sources
│   ├── YYYY/                   # Year grouping
│   │   └── YYYY-MM/            # Month grouping
│   │       ├── YYYY-MM-DD-slug/  # Bundle: source.md + assets
│   │       │   ├── source.md
│   │       │   └── figure1.png
│   │       └── YYYY-MM-DD-slug.md  # Single file (no assets)
│   └── assets/                 # Optional: shared/tool-managed assets only
├── wiki/                       # LLM-maintained pages
│   ├── entities/               # People, tools, organizations
│   ├── concepts/               # Ideas, theories, frameworks
│   ├── sources/                # Source summary pages
│   ├── comparisons/            # Comparison pages
│   ├── overviews/              # High-level topic summaries
│   ├── index.md                # Content catalog
│   └── log.md                  # Chronological activity log
├── schema/                     # Optional: templates, examples
│   └── templates/              # Page templates per type
└── .planning/                  # GSD planning artifacts (not wiki content)
```

### Pattern 1: Single-Authority Schema

**What:** AGENTS.md is the sole authoritative document for all conventions, workflows, and rules. No secondary sources of truth.
**When to use:** Always -- this is locked by D-01 and D-03.
**Key constraint:** The document must be self-contained enough that an LLM with no prior context can read it and operate correctly.

### Pattern 2: Frontmatter-Driven Taxonomy

**What:** Categories, topics, and classification live in YAML frontmatter fields (`type`, `tags`, `domains`, `status`, `privacy`), not in directory hierarchy. Directories separate by page type (structural), not by topic (semantic).
**When to use:** Always for wiki pages. Source directories use chronological structure instead.
**Why:** Enables Dataview queries across any dimension without filesystem reorganization. A page about "Attention Mechanism" tagged `[machine-learning, neuroscience]` appears in both topic views via Dataview, not by duplicating files.

### Pattern 3: Body Links, Frontmatter IDs

**What:** Wikilinks (`[[Page Title]]`) go in the markdown body. Frontmatter stores string identifiers (source IDs, page IDs) not wikilink syntax.
**When to use:** Always. This is the safest pattern for combined Obsidian + Dataview + graph view compatibility.
**Why:** See Pitfall 1 below -- frontmatter wikilinks have uncertain graph view integration.

### Anti-Patterns to Avoid

- **Topic-based directory hierarchy:** Do NOT create `wiki/machine-learning/`, `wiki/health/` etc. Use frontmatter `domains` field and Dataview queries instead. Locked by D-06.
- **Multiple sources of truth:** Do NOT put conventions in CLAUDE.md, README, or scattered comments. AGENTS.md is the one source. Locked by D-01, D-03.
- **Overcomplicated frontmatter:** Do NOT put provenance blobs, relation arrays, or decay settings in base frontmatter. Those belong in type-specific schemas per D-12.
- **Wikilinks with display aliases in body text:** Use `[[Attention Mechanism]]` not `[[Attention Mechanism|attention]]` per D-34. Let the `aliases` frontmatter field handle alternative names.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Dynamic page listings by type/tag/status | Custom index scripts | Dataview TABLE/LIST queries | Dataview reads YAML frontmatter natively; auto-updates |
| Page name resolution with aliases | Custom link resolution | Obsidian `aliases` frontmatter property | Built-in; autocomplete resolves aliases to canonical `[[Title]]` links |
| Frontmatter type validation | Custom YAML parser | Obsidian Properties system (1.4+) | Obsidian enforces types (text, list, date, number, checkbox) in the Properties editor |
| Graph visualization | Custom graph rendering | Obsidian Graph View | Built-in; shows link structure, orphans, clusters |

**Key insight:** Phase 1 produces only markdown and YAML. All the "tooling" is Obsidian itself plus its Dataview plugin. The schema document tells LLMs what to write; Obsidian and Dataview handle rendering and querying.

## Common Pitfalls

### Pitfall 1: Frontmatter Wikilinks and Graph View

**What goes wrong:** Putting `[[Page Title]]` wikilinks in YAML frontmatter fields (e.g., `sources: ["[[Source Page]]"]`). These may not appear in Obsidian's graph view or backlinks panel.
**Why it happens:** YAML requires quoting wikilinks (`"[[Link]]"`). Obsidian's Properties system (v1.4+) made links in text/list properties clickable, but graph view integration for frontmatter links has been inconsistent across versions and is not reliably documented.
**How to avoid:** Store plain string IDs in frontmatter (`sources: [src-2026-04-08-attention]`). Put human-readable wikilinks in the body's `## Sources` or `## Related Pages` sections where they reliably appear in graph view and backlinks.
**Warning signs:** Pages that should be connected appear isolated in graph view despite having frontmatter references.

### Pitfall 2: Frontmatter Field Naming

**What goes wrong:** Using spaces, capitals, or special characters in frontmatter field names. Dataview sanitizes these (e.g., `Basic Field` becomes `basic-field`), creating confusion between the YAML key and the Dataview query field name.
**Why it happens:** YAML allows almost any string as a key.
**How to avoid:** Use `snake_case` for all field names (`created_at`, `epistemic_status`, `source_type`). This matches what D-10 already specifies. Snake_case is valid YAML, valid Dataview, and unambiguous.
**Warning signs:** Dataview queries returning empty results for fields that visibly have values.

### Pitfall 3: Date Format Inconsistency

**What goes wrong:** Mixing date formats (e.g., `2026-04-08`, `April 8, 2026`, `04/08/2026`). Dataview only auto-parses ISO 8601 dates (`YYYY-MM-DD` or `YYYY-MM-DDTHH:mm:ss`).
**Why it happens:** Humans naturally write dates in various formats.
**How to avoid:** Mandate ISO 8601 in the schema for all date fields: `created_at`, `updated_at`, `ingested_at`, `checked_at`. Example: `created_at: 2026-04-08`.
**Warning signs:** Dataview date sorting/filtering produces unexpected results.

### Pitfall 4: AGENTS.md Growing Too Large

**What goes wrong:** A monolithic schema document becomes unwieldy for LLMs to parse when it exceeds ~2000 lines. Context window consumption becomes a concern.
**Why it happens:** D-04 requires all four workflows defined upfront, plus 16 sections with prescriptive detail.
**How to avoid:** Keep the main AGENTS.md focused and authoritative but concise. Use the optional `schema/` directory for verbose examples and full templates that the LLM can load on-demand. Target AGENTS.md at 800-1200 lines for the core spec, with templates in separate files.
**Warning signs:** LLM agents truncating or ignoring later sections of the schema.

### Pitfall 5: Provenance Syntax Conflicting with Markdown

**What goes wrong:** The `[prov:source_id#locator]` syntax looks like a markdown link and could be misinterpreted by renderers or parsers.
**Why it happens:** Square brackets are used for both markdown links and the custom provenance syntax.
**How to avoid:** The `prov:` prefix disambiguates from standard markdown links (which require `[text](url)` or `[[wikilink]]` format). Document this explicitly in the schema. Obsidian will render `[prov:...]` as plain text (not a link) since it lacks the `(url)` component. However, ensure no Obsidian plugins try to parse bracket-enclosed text.
**Warning signs:** Provenance markers rendering as broken links or being stripped by plugins.

### Pitfall 6: Red Links (Unresolved Wikilinks) Creating Noise

**What goes wrong:** Excessive red links make the graph view cluttered and the vault feel broken.
**Why it happens:** D-33 allows red links as knowledge gap indicators, but without discipline this creates noise.
**How to avoid:** The schema should establish that red links are intentional signals used by the lint workflow (GAP-01) and should be limited to genuinely anticipated pages, not speculative references.
**Warning signs:** More unresolved links than resolved ones; graph view dominated by gray/unresolved nodes.

## Code Examples

### Base Frontmatter (All Wiki Pages)

```yaml
---
id: attention-mechanism
title: Attention Mechanism
type: concept
status: active
summary: "A neural network component that allows models to focus on relevant parts of the input sequence."
created_at: 2026-04-08
updated_at: 2026-04-08
sources:
  - src-2026-03-15-vaswani-attention
  - src-2026-04-01-bahdanau-alignment
epistemic_status: sourced
tags:
  - machine-learning
  - transformers
  - deep-learning
domains:
  - ai-research
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - Attention
  - Self-Attention
---
```

### Entity Page Structure (Progressive Disclosure)

```markdown
---
id: geoffrey-hinton
title: Geoffrey Hinton
type: entity
status: active
summary: "British-Canadian computer scientist, pioneer of deep learning and neural networks."
created_at: 2026-04-08
updated_at: 2026-04-08
sources:
  - src-2026-03-20-hinton-interview
epistemic_status: sourced
tags:
  - researcher
  - deep-learning
domains:
  - ai-research
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - Geoff Hinton
---

## TL;DR

Geoffrey Hinton is a pioneer of [[Deep Learning]] and co-inventor of [[Backpropagation]]. He shared the 2018 Turing Award with [[Yoshua Bengio]] and [[Yann LeCun]].

## Key Facts

- Co-invented backpropagation algorithm for training neural networks [prov:src-2026-03-20-hinton-interview#sec:early-work]
- Pioneered deep belief networks and restricted Boltzmann machines [prov:src-2026-03-20-hinton-interview#sec:contributions|direct]
- Left Google in 2023 citing concerns about AI safety [prov:src-2026-03-20-hinton-interview#sec:google-departure|direct|2026-04-08]

## Detail

[Full narrative, synthesis, caveats...]

## Related Pages

- [[Deep Learning]]
- [[Backpropagation]]
- [[Neural Networks]]

## Sources

- src-2026-03-20-hinton-interview: "Geoffrey Hinton Interview on AI Safety" (2026-03-20)
```

### Source Registry Entry (Frontmatter Approach)

For source summary pages in `wiki/sources/`, the frontmatter serves as the registry:

```yaml
---
id: src-2026-03-20-hinton-interview
title: "Geoffrey Hinton Interview on AI Safety"
type: source
source_type: transcript
status: active
summary: "Interview covering Hinton's career, contributions to deep learning, and concerns about AI safety."
created_at: 2026-04-08
updated_at: 2026-04-08
sources: []
epistemic_status: sourced
tags:
  - ai-safety
  - interview
domains:
  - ai-research
privacy: cloud_safe
path: sources/2026/2026-03/2026-03-20-hinton-interview/source.md
url: "https://example.com/hinton-interview"
content_hash: "sha256:abc123..."
ingested_at: 2026-04-08
---
```

**Discretion note (D-17 / source registry):** Using frontmatter on wiki source summary pages as the registry is recommended over a separate sidecar file. Rationale: Dataview can query source metadata directly (`TABLE source_type, ingested_at FROM "wiki/sources"`), it keeps source metadata co-located with the summary, and it avoids a separate file that could drift out of sync.

### Dataview Query Examples

```dataview
TABLE summary, epistemic_status, updated_at
FROM "wiki/concepts"
WHERE status = "active"
SORT updated_at DESC
```

```dataview
LIST
FROM "wiki/entities"
WHERE contains(domains, "ai-research")
SORT title ASC
```

### Commit Convention Examples

```
schema: define base frontmatter fields and page type conventions
ingest(hinton-interview): add source summary and update entity pages
query(attention-mechanisms): synthesize comparison of attention variants
lint(wiki): fix 3 orphan pages and 2 broken provenance references
reflect(q1-review): restructure AI safety domain after new sources
```

## State of the Art

| Area | Current Approach | Notes |
|------|------------------|-------|
| AGENTS.md convention | Open format under Linux Foundation (Agentic AI Foundation) | Agent-agnostic; OpenAI Codex, GitHub Copilot, and others auto-discover it |
| Obsidian Properties | Typed frontmatter (v1.4+, current v1.7+) | text, list, number, checkbox, date, date+time types supported |
| Dataview | Mature plugin, reads all YAML frontmatter | Supports TABLE, LIST, TASK, CALENDAR queries |
| Frontmatter links | Clickable in Properties editor (v1.4+) | Graph view integration still uncertain -- use body links as primary |

**Note on AGENTS.md convention:** The AGENTS.md format is now an open standard stewarded by the Agentic AI Foundation under the Linux Foundation. It is intentionally flexible -- standard markdown with no required structure. Our AGENTS.md will be much larger and more prescriptive than the typical software project's AGENTS.md (which targets ~150 lines for build/test/style guidance). This is by design -- our AGENTS.md is a complete wiki maintenance specification, not a coding style guide.

## Open Questions

1. **Frontmatter links in graph view (current Obsidian behavior)**
   - What we know: Obsidian 1.4+ made links in text/list properties clickable. Dataview can query them. The graph view behavior for frontmatter links is not clearly documented and may vary by version.
   - What's unclear: Whether `"[[Page]]"` in frontmatter reliably appears in graph view across current Obsidian versions.
   - Recommendation: Conservative approach -- use string IDs in frontmatter, wikilinks in body. This is safe and works everywhere. If the user later confirms frontmatter links work in graph view in their Obsidian version, the schema can be relaxed.

2. **AGENTS.md size management**
   - What we know: All 16 sections with prescriptive workflows will be substantial. Typical AGENTS.md files are ~150 lines.
   - What's unclear: Exact line count until written. Whether LLMs will parse 1000+ lines reliably.
   - Recommendation: Write the core spec in AGENTS.md, put verbose templates in `schema/templates/`. Include a "Quick Reference" section at the top of AGENTS.md with the most critical rules.

3. **Source registry: frontmatter vs sidecar (Claude's discretion)**
   - What we know: Dataview can query frontmatter from wiki source summary pages. A sidecar file (e.g., `schema/source-registry.yaml`) would centralize all source metadata.
   - Recommendation: Use frontmatter on wiki source summary pages. This is the Dataview-native approach, avoids sync issues, and every source already gets a summary page per the ingest workflow.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Manual validation (no code to test) |
| Config file | none |
| Quick run command | Manual review of AGENTS.md and directory structure |
| Full suite command | Checklist-based verification |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SCHM-01 | AGENTS.md exists and is readable by any LLM | manual | `test -f AGENTS.md && wc -l AGENTS.md` | n/a |
| SCHM-02 | All 4 workflows present | manual | `grep -c "## .*Workflow\|### .*Ingest\|### .*Query\|### .*Lint\|### .*Reflect" AGENTS.md` | n/a |
| SCHM-03 | Page type conventions defined | manual | `grep -c "entity\|concept\|source\|comparison\|overview" AGENTS.md` | n/a |
| SCHM-04 | Frontmatter fields defined | manual | Check Section 5 of AGENTS.md | n/a |
| SCHM-05 | Structured operations defined | manual | Check Section 9 of AGENTS.md for UPDATE/MERGE/SUPERSEDE/ARCHIVE | n/a |
| DIRS-01 | sources/ directory exists | smoke | `test -d sources/` | n/a |
| DIRS-02 | wiki/ directory exists with subdirs | smoke | `test -d wiki/entities && test -d wiki/concepts` | n/a |
| DIRS-03 | Separation between sources and wiki | smoke | `ls -d sources/ wiki/` | n/a |
| DIRS-04 | Git-tracked with commit conventions | smoke | `git log --oneline -1` | n/a |
| OBSD-01 | Valid Obsidian wikilinks documented | manual | Check wikilink conventions in AGENTS.md Section 8 | n/a |
| OBSD-02 | Dataview-compatible YAML documented | manual | Check frontmatter schema uses snake_case, ISO dates, YAML lists | n/a |
| OBSD-03 | Graph-friendly structure | manual | Check first-mention linking rule in Section 8 | n/a |
| OBSD-04 | Dataview query support | manual | Check that tags, domains, type, status fields support Dataview queries | n/a |
| PROG-01 | TL;DR section convention | manual | Check progressive disclosure rules in Section 7 | n/a |
| PROG-02 | Progressive depth sections | manual | Check per-type section ordering in Section 4 | n/a |
| PROG-03 | Shallow-first navigation instruction | manual | Check Section 7 for explicit LLM navigation guidance | n/a |
| BNDY-01 | Markdown-first vs scale upgrades | manual | Check Section 14 for tiered approach | n/a |
| BNDY-02 | Privacy-tiered routing | manual | Check Section 13 for local-only/cloud-safe model | n/a |
| BNDY-03 | Provisional heuristics documented | manual | Check Section 14 for "heuristic" language and signal-based triggers | n/a |

### Sampling Rate

- **Per task commit:** Manual review that AGENTS.md sections are present and complete
- **Per wave merge:** Full checklist verification of all 19 requirements
- **Phase gate:** All requirements verified before `/gsd:verify-work`

### Wave 0 Gaps

None -- this phase produces documentation, not code. No test framework installation needed.

## Sources

### Primary (HIGH confidence)

- [Dataview - Adding Metadata](https://blacksmithgu.github.io/obsidian-dataview/annotation/add-metadata/) - YAML frontmatter field naming, sanitization rules, data types
- [Dataview - Types of Metadata](https://blacksmithgu.github.io/obsidian-dataview/annotation/types-of-metadata/) - Eight data types, date parsing (ISO 8601), link quoting requirements, list syntax
- [Obsidian Properties documentation](https://retypeapp.github.io/obsidian/properties/) - Seven property types (text, list, number, checkbox, date, date+time, tags), default properties (tags, aliases, cssclasses)
- [AGENTS.md specification](https://agents.md/) - Open format, no required structure, hierarchical discovery, flexible markdown

### Secondary (MEDIUM confidence)

- [Obsidian Forum - Wikilinks in YAML frontmatter](https://forum.obsidian.md/t/wikilinks-in-yaml-front-matter/10052) - Obsidian v1.4 added link support in Properties; graph view integration still debated
- [GitHub Blog - How to write a great agents.md](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/) - Best practices for AGENTS.md structure

### Tertiary (LOW confidence)

- [Obsidian Rocks - Introduction to Properties](https://obsidian.rocks/an-introduction-to-obsidian-properties/) - Confirms links in properties are clickable; does not confirm graph view integration

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Obsidian and Dataview are well-documented, stable tools
- Architecture: HIGH - Decisions are locked and technically validated against Obsidian capabilities
- Pitfalls: HIGH - Frontmatter link/graph issue is well-documented in community; field naming rules confirmed by official Dataview docs
- Provenance syntax: MEDIUM - Custom syntax is internally consistent but no external validation beyond markdown rendering rules

**Research date:** 2026-04-08
**Valid until:** 2026-05-08 (stable domain -- Obsidian and Dataview change slowly)
