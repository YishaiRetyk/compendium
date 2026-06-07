# Page Types and Templates

> Agent-authoritative reference for wiki page types, section ordering, and authoring conventions.
> The AGENTS.md routing table points here. If you find a discrepancy between this file and AGENTS.md, this file wins.

## Page Types (dispatch vocabulary)

Six types exist: **entity**, **concept**, **source**, **comparison**, **overview**, **decision**.

---

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

**When to use:** Every time a source is ingested, a source summary page is created in `wiki-cloud/sources/` (or `wiki-local/sources/` for local-only content).

**Additional frontmatter fields** (beyond the base set):

| Field | Type | Description |
|-------|------|-------------|
| `path` | string | Path to raw source file in `sources/` |
| `url` | string | Original URL if applicable |
| `content_hash` | string | SHA-256 hash for staleness detection |
| `ingested_at` | date | When the source was processed |
| `source_type` | enum | `article`, `paper`, `transcript`, `journal`, `data`, `image` |

**Example:** "Vaswani et al. - Attention Is All You Need" (`type: source`, `source_type: paper`; filename `schema/examples/source-summary.md` matches the `schema/templates/` sibling -- readers should NOT expect `schema/examples/source.md`). Demonstrates full population of `path` / `url` / `content_hash` / `ingested_at` / `source_type`, Extracted Claims with direct-quote provenance, and the Source Metadata authors / published block.

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

**Directory:** `wiki-cloud/decisions/`

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

---

## Per-Type Section Ordering

| Page Type | Section Order |
|-----------|--------------|
| Entity | TL;DR -> Key Facts -> Detail -> Related Pages -> Sources |
| Concept | TL;DR -> Key Facts -> Detail -> Related Pages -> Sources |
| Source Summary | TL;DR -> Key Takeaways -> Extracted Claims -> Notes -> Source Metadata |
| Comparison | TL;DR -> Bottom Line -> Comparison Table -> Detailed Comparison -> Sources |
| Overview | TL;DR -> Key Facts -> Detail -> Related Pages -> Sources |
| Decision | TL;DR -> Decision -> Why -> Alternatives Considered -> Consequences -> Affected Pages -> Sources |

### Authoring Conventions

- **TL;DR** MUST be 1 short paragraph or 2-4 bullets.
- **Key Facts** MUST be compact bullets with inline provenance markers.
- **Detail** contains full narrative, synthesis, caveats, and nuance.
- **Sources** at the bottom lists human-readable source references with wikilinks to source summary pages.

---

## See Also

- [AGENTS.md](../../AGENTS.md) -- routing-table stub (dispatch pointer to this file).
- `schema/reference/frontmatter.md` -- frontmatter validation checklist.
- `schema/templates/` -- blank page templates per type.
