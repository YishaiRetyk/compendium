# Phase 2: Page Types, Examples & Navigation - Research

**Researched:** 2026-04-09
**Domain:** Obsidian-compatible markdown wiki content (templates, examples, index, log, epistemic conventions)
**Confidence:** HIGH

## Summary

Phase 2 is pure content creation within an already-established schema. Phase 1 delivered AGENTS.md with worked examples for all 5 page types (sections 4.1-4.5), frontmatter schema (section 5), provenance syntax (section 6), progressive disclosure rules (section 7), and index/log conventions (section 12). The directory structure exists with empty subdirectories and stub files for index.md and log.md.

This phase creates: (1) five template files in `schema/templates/`, (2) five example pages in `wiki/` subdirectories using the Kahneman/cognitive-biases domain, (3) populated index.md and log.md, and (4) an AGENTS.md update documenting the mixed inline grammar (`[prov:...]` + `[epistemic:: ...]`). No external tools, libraries, or services are involved -- this is markdown authoring governed by an existing specification.

**Primary recommendation:** Work template-first (they define the skeleton), then example pages (which flesh out the templates with real content and cross-references), then index/log (which reference the example pages), and finally the AGENTS.md grammar documentation. This ordering minimizes rework since each layer builds on the previous.

<user_constraints>

## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Example pages use famous thinkers/ideas domain: Daniel Kahneman (entity), Cognitive Biases (concept), a chapter from Thinking Fast and Slow (source summary), System 1 vs System 2 (comparison), Decision Making (overview).
- **D-02:** Examples must cross-reference each other to demonstrate graph view value.
- **D-03:** Example pages serve double duty: satisfy EXMP requirements AND act as companion exemplars for templates.
- **D-04:** Per-claim epistemic markers use Dataview inline field syntax: `[epistemic:: sourced]`, `[epistemic:: inferred]`, `[epistemic:: tentative]`, `[epistemic:: stale]`.
- **D-05:** Provenance stays in custom `[prov:...]` syntax (NOT Dataview). Different purposes, different tools.
- **D-06:** Mixed inline grammar must be documented explicitly in AGENTS.md section 6.
- **D-07:** Page-level epistemic status stays in frontmatter (`epistemic_status` field). Inline markers are for claim-level granularity.
- **D-08:** Inline pattern: `Claim text. [prov:source_id#locator|support_type] [epistemic:: status]`
- **D-09:** index.md uses manual curated list, NOT Dataview queries.
- **D-10:** Lint rule (Phase 5) to detect index drift -- deferred to Phase 5.
- **D-11:** Each index entry: wikilink + one-line summary. Organized by category sections matching page types.
- **D-12:** Two-layer pattern: primary templates (skeleton + comments) in `schema/templates/`, companion exemplars are the example pages in `wiki/`.
- **D-13:** Templates are operational -- copy, fill, done. Skeleton with section headings, placeholder frontmatter, brief comments. No example content that could leak.
- **D-14:** Example pages are reference material -- demonstrate "good" with real density, provenance chains, epistemic markers.
- **D-15:** One template per page type: `schema/templates/entity.md`, `concept.md`, `source-summary.md`, `comparison.md`, `overview.md`.
- **D-16:** Log format: parseable with ISO timestamps and operation types matching AGENTS.md workflow names. Append-only, most recent first.

### Claude's Discretion
- Exact example page content (specific claims, facts, provenance markers) -- as long as they demonstrate all conventions and cross-reference each other
- Template comment wording and helper text
- Log entry exact format details
- Whether to update AGENTS.md section 6 inline or add a subsection for the mixed grammar documentation

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope.

</user_constraints>

<phase_requirements>

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PAGE-01 | Entity page template with type-specific sections | Template at `schema/templates/entity.md` following AGENTS.md 4.1 section order |
| PAGE-02 | Concept page template for ideas, theories, frameworks | Template at `schema/templates/concept.md` following AGENTS.md 4.2 section order |
| PAGE-03 | Source summary template with extraction and provenance | Template at `schema/templates/source-summary.md` following AGENTS.md 4.3 section order + additional frontmatter |
| PAGE-04 | Comparison page template for contrasting sources | Template at `schema/templates/comparison.md` following AGENTS.md 4.4 section order |
| PAGE-05 | Overview/synthesis page template for high-level summaries | Template at `schema/templates/overview.md` following AGENTS.md 4.5 section order |
| PAGE-06 | All templates include frontmatter schema | Base 16 fields from AGENTS.md section 5 + type-specific fields |
| PAGE-07 | All templates use progressive disclosure | TL;DR -> depth ordering per AGENTS.md section 7 |
| EPST-01 | Per-claim epistemic markers: sourced, inferred, tentative, stale | Dataview inline field syntax `[epistemic:: status]` per D-04 |
| EPST-02 | Markers visible in page content, not just frontmatter | Inline in body text per D-07/D-08 |
| EPST-03 | Epistemic conventions documented in schema | AGENTS.md section 6 update per D-06 |
| EXMP-01 | Example entity page demonstrating all conventions | Daniel Kahneman page per D-01 |
| EXMP-02 | Example concept page with cross-references and epistemic markers | Cognitive Biases page per D-01 |
| EXMP-03 | Example source summary with provenance chain | Thinking Fast and Slow chapter per D-01 |
| EXMP-04 | Example comparison page contrasting multiple sources | System 1 vs System 2 per D-01 |
| EXMP-05 | Example populated index and log files | Populated index.md and log.md stubs |
| INDX-01 | Content index cataloging all wiki pages with links, summaries, metadata | Curated manual list per D-09/D-11 |
| INDX-02 | Index organized by category | Category sections matching page types per D-11 |
| INDX-03 | Index updated on every ingest operation | Convention already in AGENTS.md section 12; example shows initial population |
| LOG-01 | Chronological activity log recording all operations | Populated log.md with initial entries |
| LOG-02 | Log entries parseable with consistent prefix format | Format per AGENTS.md section 12 + D-16 |
| LOG-03 | Log covers operational events, not structural reasoning | Per AGENTS.md section 12 separation |

</phase_requirements>

## Architecture Patterns

### Recommended Deliverable Structure

```
schema/
└── templates/
    ├── entity.md              # PAGE-01
    ├── concept.md             # PAGE-02
    ├── source-summary.md      # PAGE-03
    ├── comparison.md          # PAGE-04
    └── overview.md            # PAGE-05

wiki/
├── entities/
│   └── daniel-kahneman.md    # EXMP-01
├── concepts/
│   └── cognitive-biases.md   # EXMP-02
├── sources/
│   └── src-thinking-fast-and-slow-ch1.md  # EXMP-03
├── comparisons/
│   └── system-1-vs-system-2.md  # EXMP-04
├── overviews/
│   └── decision-making.md    # EXMP-05 (overview example)
├── index.md                  # EXMP-05, INDX-01/02/03
└── log.md                    # LOG-01/02/03

AGENTS.md                     # EPST-03 (section 6 update)
```

### Pattern 1: Template Structure (D-12, D-13)

**What:** Templates are operational skeletons -- copy, fill, done. Comments explain constraints but contain no example content.

**When to use:** Every template file in `schema/templates/`.

**Structure for each template:**

```markdown
---
id: 
title: 
type: <page_type>
status: active
summary: ""
created_at: 
updated_at: 
sources: []
epistemic_status: 
tags: []
domains: []
supersedes:
superseded_by:
privacy: 
aliases: []
---

## TL;DR

<!-- 1 short paragraph or 2-4 bullets. Must be scannable in seconds. -->

## Key Facts

<!-- Compact bullets with inline provenance. Format:
     - Claim text [prov:source_id#locator|support_type] [epistemic:: status] -->

## Detail

<!-- Full narrative, synthesis, caveats. Long prose goes here. -->

## Related Pages

<!-- Wikilinks to connected pages. Link on first mention only. -->

## Sources

<!-- Human-readable source list with wikilinks to source summary pages.
     Format: - [[src-YYYY-MM-DD-slug]]: "Title" (date) -->
```

### Pattern 2: Example Page Density (D-14)

**What:** Example pages demonstrate real content density -- multiple provenance chains, varied epistemic markers, cross-references forming a connected graph.

**When to use:** All five example pages.

**Key conventions to demonstrate:**
- Multiple `[prov:...]` markers with different locator types
- Mixed `[epistemic:: ...]` statuses within a single page (some claims sourced, others inferred)
- Cross-references via `[[wikilinks]]` linking to other example pages
- Complete frontmatter with all 16 base fields filled correctly
- Page-level `epistemic_status` in frontmatter distinct from claim-level inline markers

### Pattern 3: Mixed Inline Grammar (D-04, D-05, D-08)

**What:** Two distinct inline syntaxes coexist intentionally:
- `[prov:source_id#locator|support_type]` -- portable, grep/script-parseable, for traceability
- `[epistemic:: status]` -- Dataview inline field, queryable, for discovery

**Canonical inline pattern:**
```
Claim text. [prov:source_id#locator|support_type] [epistemic:: sourced]
```

**Why two syntaxes:** Provenance needs to be parseable by scripts and grep for validation (Phase 5 lint). Epistemic status needs to be queryable by Dataview for "find all tentative claims" queries. Different tools, different syntax. This must be documented in AGENTS.md section 6 per D-06.

### Pattern 4: Index Entry Format (D-09, D-11)

**What:** Manual curated list (no Dataview), one entry per page.

**Format per AGENTS.md section 12:**
```markdown
- [[Page Title]] -- <one-line summary> (<epistemic_status>, <updated_at>)
```

**Organized by sections:** Entities, Concepts, Sources, Comparisons, Overviews.

### Pattern 5: Log Entry Format (D-16, AGENTS.md Section 12)

**What:** Parseable entries with ISO timestamps and operation types.

**Format from AGENTS.md section 12:**
```markdown
## [YYYY-MM-DD] <operation_type> | <description>

<what was done, which pages were affected, brief rationale>
```

**IMPORTANT -- Log ordering conflict:** CONTEXT.md D-16 says "most recent first" while AGENTS.md section 12 says "newest entries at the bottom." Since AGENTS.md is the authoritative spec and was written in Phase 1 before this context discussion, the planner must resolve this. Recommendation: follow AGENTS.md (append-only, newest at bottom) since it is the established convention and matches Unix log conventions. If the user intended reverse-chronological, AGENTS.md should be updated first.

### Anti-Patterns to Avoid

- **Dataview queries in index.md:** D-09 explicitly prohibits this. Index is manual curated list.
- **Example content in templates:** D-13 prohibits this. Templates have comments explaining constraints, not sample text.
- **Wikilinks in frontmatter:** AGENTS.md section 3 prohibits this. Use string IDs only.
- **Display aliases in wikilinks:** Write `[[Daniel Kahneman]]` not `[[Daniel Kahneman|Kahneman]]`.
- **Linking same page twice:** Link on first mention only per page body.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Epistemic queryability | Custom parsing scripts | Dataview inline fields `[epistemic:: status]` | Dataview already understands this syntax natively |
| Source metadata queries | Separate registry file | Source summary page frontmatter + Dataview | AGENTS.md section 6 established source pages AS the registry |
| Dynamic index | Dataview TABLE queries | Manual curated list in index.md | D-09: curated lists are higher signal, portable, LLM-comprehensible |

## Common Pitfalls

### Pitfall 1: Inconsistent Frontmatter Between Templates and Examples
**What goes wrong:** Template defines fields one way, example page fills them differently.
**Why it happens:** Templates and examples written independently without cross-checking.
**How to avoid:** Write templates first, then create examples by literally copying the template and filling it in. Verify all 16 base fields match AGENTS.md section 5 schema exactly.
**Warning signs:** Field names differ, field ordering differs, missing fields.

### Pitfall 2: Broken Cross-References in Example Pages
**What goes wrong:** Wikilinks in example pages point to pages that don't exist or use wrong titles.
**Why it happens:** Example pages reference each other but filenames/titles aren't coordinated.
**How to avoid:** Define all 5 example page IDs and titles before writing any content. Use a reference list: `daniel-kahneman` -> "Daniel Kahneman", `cognitive-biases` -> "Cognitive Biases", etc. Red links to non-example pages are fine (expected).
**Warning signs:** Obsidian graph shows disconnected nodes among example pages.

### Pitfall 3: Source IDs in Examples Don't Follow Convention
**What goes wrong:** Example source summary page uses an inconsistent source ID format.
**Why it happens:** The source ID convention is `src-YYYY-MM-DD-slug` but for a book chapter the date mapping isn't obvious.
**How to avoid:** Pick a plausible ingest date for the example (e.g., `src-2026-04-09-thinking-fast-and-slow-ch1`). The date is ingestion date, not publication date. Document this clearly.
**Warning signs:** `[prov:]` markers in other example pages can't resolve to the source summary page ID.

### Pitfall 4: Epistemic Inline Syntax Rendered as Literal Text
**What goes wrong:** `[epistemic:: sourced]` shows as raw text in Obsidian instead of creating a Dataview inline field.
**Why it happens:** Incorrect syntax. Dataview inline fields require the exact format `[key:: value]` with double colon and space.
**How to avoid:** Verify syntax: `[epistemic:: sourced]` (note: double colon, space before value). Test in Obsidian with a Dataview query: `TABLE epistemic FROM "wiki"` to confirm fields are recognized.
**Warning signs:** Dataview queries return empty results for epistemic fields.

### Pitfall 5: Index Doesn't Match Actual Files
**What goes wrong:** index.md lists pages that don't exist, or omits pages that do.
**Why it happens:** Index populated separately from page creation.
**How to avoid:** Populate index.md AFTER all example pages are created. Cross-check each entry's wikilink against the actual file in `wiki/`.
**Warning signs:** Obsidian shows unresolved links in index.md for pages that should exist.

### Pitfall 6: Log Ordering Ambiguity
**What goes wrong:** Log entries written in wrong order, confusing downstream consumers.
**Why it happens:** D-16 says "most recent first" but AGENTS.md section 12 says "newest at the bottom."
**How to avoid:** Planner must resolve this before implementation. See Architecture Patterns section above.
**Warning signs:** Log format doesn't match what `grep "^## \[" wiki/log.md | tail -5` expects.

## Code Examples

### Example: Complete Frontmatter for Entity Template
Source: AGENTS.md section 4.1 + section 5

```yaml
---
id: 
title: 
type: entity
status: active
summary: ""
created_at: 
updated_at: 
sources: []
epistemic_status: 
tags: []
domains: []
supersedes:
superseded_by:
privacy: 
aliases: []
---
```

### Example: Source Summary Additional Frontmatter
Source: AGENTS.md section 5

```yaml
# Additional fields for type: source (beyond base 16)
path: 
url: ""
content_hash: ""
ingested_at: 
source_type: 
```

### Example: Mixed Inline Grammar in Practice
Source: D-04, D-05, D-08

```markdown
## Key Facts

- Kahneman demonstrated that human judgment relies on heuristics that produce systematic biases [prov:src-2026-04-09-thinking-fast-and-slow-ch1#sec:introduction|direct] [epistemic:: sourced]
- The anchoring effect may be stronger in high-stakes financial decisions [prov:src-2026-04-09-thinking-fast-and-slow-ch1#p42|inferred] [epistemic:: inferred]
- Some researchers question whether heuristics are always irrational [epistemic:: tentative]
```

### Example: Index Entry Format
Source: AGENTS.md section 12

```markdown
## Entities

- [[Daniel Kahneman]] -- Israeli-American psychologist, pioneer of behavioral economics (sourced, 2026-04-09)

## Concepts

- [[Cognitive Biases]] -- Systematic patterns of deviation from norm or rationality in judgment (sourced, 2026-04-09)
```

### Example: Log Entry Format
Source: AGENTS.md section 12

```markdown
## [2026-04-09] schema | Create page type templates and example pages

Created 5 templates in schema/templates/. Created 5 example pages demonstrating
all conventions: Daniel Kahneman (entity), Cognitive Biases (concept), Thinking
Fast and Slow Ch.1 (source summary), System 1 vs System 2 (comparison), Decision
Making (overview). Populated index.md and log.md. Updated AGENTS.md section 6 with
mixed inline grammar documentation.
```

### Example: Dataview Query to Verify Epistemic Fields
For manual verification in Obsidian:

```dataview
TABLE epistemic
FROM "wiki"
FLATTEN file.lists.text as item
WHERE contains(item, "[epistemic::")
```

## Cross-Reference Map for Example Pages

The five example pages must form a connected cluster per D-02. Planned link structure:

| Page | Links TO | Linked FROM |
|------|----------|-------------|
| Daniel Kahneman (entity) | Cognitive Biases, Thinking Fast and Slow (source), Decision Making | Cognitive Biases, Source Summary, Comparison, Overview |
| Cognitive Biases (concept) | Daniel Kahneman, System 1 vs System 2, Decision Making | Entity, Source Summary, Comparison, Overview |
| TFaS Ch.1 (source summary) | Daniel Kahneman, Cognitive Biases, System 1 vs System 2 | Entity, Concept, Comparison |
| System 1 vs System 2 (comparison) | Daniel Kahneman, Cognitive Biases, TFaS source, Decision Making | Concept, Source Summary, Overview |
| Decision Making (overview) | Daniel Kahneman, Cognitive Biases, System 1 vs System 2, TFaS source | Entity, Comparison |

Every page links to at least 3 others. The graph should show a fully connected cluster of 5 nodes.

## AGENTS.md Section 6 Update Scope

AGENTS.md section 6 currently documents provenance syntax only. It does NOT contain:
- Inline epistemic markers (`[epistemic:: status]`)
- The dual-syntax rationale (provenance for scripts, epistemic for Dataview)
- The combined inline pattern from D-08

Per D-06, section 6 needs a new subsection documenting:
1. The `[epistemic:: status]` syntax and its four valid values
2. Why this is Dataview syntax while `[prov:]` is not (intentional design choice)
3. The combined inline pattern: `Claim text. [prov:source_id#locator|support_type] [epistemic:: status]`
4. The distinction between page-level `epistemic_status` (frontmatter) and claim-level `[epistemic:: ]` (inline)

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Shell scripts (bash) + manual Obsidian verification |
| Config file | None -- ad hoc validation |
| Quick run command | `grep -r "^---" wiki/ schema/templates/ \| head -20` |
| Full suite command | Manual checklist + Obsidian visual inspection |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PAGE-01 | Entity template exists with correct sections | smoke | `head -30 schema/templates/entity.md` | Wave 0 |
| PAGE-02 | Concept template exists with correct sections | smoke | `head -30 schema/templates/concept.md` | Wave 0 |
| PAGE-03 | Source summary template exists with additional fields | smoke | `head -35 schema/templates/source-summary.md` | Wave 0 |
| PAGE-04 | Comparison template exists with correct sections | smoke | `head -30 schema/templates/comparison.md` | Wave 0 |
| PAGE-05 | Overview template exists with correct sections | smoke | `head -30 schema/templates/overview.md` | Wave 0 |
| PAGE-06 | All templates have complete frontmatter | smoke | `grep -c "^---" schema/templates/*.md` (each should return 2) | Wave 0 |
| PAGE-07 | All templates use progressive disclosure ordering | manual | Visual inspection of section order | N/A |
| EPST-01 | Inline epistemic markers present in example pages | smoke | `grep -r "epistemic::" wiki/` | Wave 0 |
| EPST-02 | Markers visible in page content | smoke | `grep -r "epistemic::" wiki/ \| grep -v "^---"` | Wave 0 |
| EPST-03 | Conventions documented in AGENTS.md | smoke | `grep "epistemic::" AGENTS.md` | Wave 0 |
| EXMP-01 | Entity example page exists | smoke | `test -f wiki/entities/daniel-kahneman.md` | Wave 0 |
| EXMP-02 | Concept example with cross-refs + epistemic | smoke | `grep -c "\[\[" wiki/concepts/cognitive-biases.md` | Wave 0 |
| EXMP-03 | Source summary with provenance chain | smoke | `grep -c "\[prov:" wiki/sources/src-*.md` | Wave 0 |
| EXMP-04 | Comparison example page exists | smoke | `test -f wiki/comparisons/system-1-vs-system-2.md` | Wave 0 |
| EXMP-05 | Index and log populated | smoke | `grep -c "\[\[" wiki/index.md` (should be >= 5) | Wave 0 |
| INDX-01 | Index has links, summaries, metadata | smoke | `grep -P "^\- \[\[.+\]\] --" wiki/index.md` | Wave 0 |
| INDX-02 | Index organized by category | smoke | `grep "^## " wiki/index.md` | Wave 0 |
| INDX-03 | Index updated convention | manual | Convention check | N/A |
| LOG-01 | Log has entries | smoke | `grep "^## \[" wiki/log.md` | Wave 0 |
| LOG-02 | Parseable format | smoke | `grep "^## \[" wiki/log.md \| head -1` matches pattern | Wave 0 |
| LOG-03 | Operational events only | manual | Content review | N/A |

### Sampling Rate
- **Per task commit:** Quick grep checks on created files
- **Per wave merge:** Full checklist verification
- **Phase gate:** Open vault in Obsidian, verify graph view shows connected cluster, wikilinks resolve, Dataview queries work

### Wave 0 Gaps
None -- no test infrastructure needed. Validation is file existence checks and content pattern matching via grep, plus manual Obsidian verification for graph/Dataview behavior.

## Open Questions

1. **Log ordering conflict**
   - What we know: CONTEXT.md D-16 says "most recent first." AGENTS.md section 12 says "newest entries at the bottom."
   - What's unclear: Which is the intended behavior.
   - Recommendation: Follow AGENTS.md (newest at bottom) since it is the authoritative spec established in Phase 1. The grep command in section 12 (`tail -5`) also assumes newest-at-bottom. If the user wants reverse-chronological, update AGENTS.md first.

2. **Source ID for the book example**
   - What we know: Source IDs follow `src-YYYY-MM-DD-slug` format where the date is ingestion date.
   - What's unclear: Whether to use a real chapter or a fictional one, and what slug format for book chapters.
   - Recommendation: Use `src-2026-04-09-thinking-fast-and-slow-part1` or similar. The date is the example's fictional ingest date. Keep it simple and consistent.

3. **Dataview inline field rendering**
   - What we know: Dataview inline fields use `[key:: value]` syntax.
   - What's unclear: Whether `[epistemic:: sourced]` inside a bullet point alongside `[prov:...]` will render correctly or interfere.
   - Recommendation: The two syntaxes are structurally different (`[key:: value]` vs `[prov:...]`) so they should not conflict. But this needs Obsidian testing during verification. Flag as a manual verification step.

## Sources

### Primary (HIGH confidence)
- `AGENTS.md` sections 4.1-4.5, 5, 6, 7, 12 -- All page type specs, frontmatter schema, provenance/epistemic conventions, progressive disclosure rules, index/log format
- `.planning/phases/02-page-types-examples-navigation/02-CONTEXT.md` -- All locked decisions D-01 through D-16
- `.planning/phases/01-schema-structure-conventions/01-CONTEXT.md` -- Phase 1 decisions establishing the foundation

### Secondary (MEDIUM confidence)
- Obsidian Dataview inline field syntax -- based on established Dataview plugin behavior (`[key:: value]` format)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - no external libraries, pure markdown content creation
- Architecture: HIGH - all patterns prescribed by AGENTS.md and CONTEXT.md decisions
- Pitfalls: HIGH - pitfalls derived from direct analysis of spec constraints and cross-referencing requirements

**Research date:** 2026-04-09
**Valid until:** 2026-05-09 (stable -- content creation phase, no moving targets)
