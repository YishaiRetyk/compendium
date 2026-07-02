# Provenance, Epistemics, and Contradiction

> Agent-authoritative reference for inline provenance markers `[prov:...]`, epistemic status markers `[epistemic::]`, and contradiction markers `[contradiction:...]`.
> The AGENTS.md routing table points here (syntax/epistemics portion).

Every factual claim MUST have an inline provenance marker — see the syntax below.

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
| Reference | `#r<number>` | `#r7` | research-report bibliography entries |
| File path | `#path:<file>[:L<n>[-L<m>]]` | `#path:src/parser.py:L10-L25` | repository code/files (line numbers are relative to the source's `commit_sha`; resolves against the snapshot's `## Excerpts` registry) |
| Commit | `#commit:<sha>` | `#commit:4f2a91c` | repository snapshot-commit claims (≥7 hex chars; must prefix-match the source's `commit_sha`) |

### Page-marker convention

Markdown-native raw sources lose the page boundaries a PDF carries, so a `#p<n>` locator has nothing to bound against. The OPTIONAL `<!-- page: N -->` HTML-comment marker, hand-inserted in the raw source at each page break, makes `#p` resolvable where authors opt in. It is Obsidian-invisible (an HTML comment does not render in reading view), grep-able, and requires NO change to the `[prov:]` grammar -- `#p` already exists in the Locator Types table above.

**Marker syntax:** insert `<!-- page: N -->` on its own line in the raw source file (the file at the source page's `path:`) at each page boundary, where `N` is the page number that begins below the marker:

```markdown
<!-- page: 7 -->
...the text of page 7...

<!-- page: 8 -->
...the text of page 8...

<!-- page: 9 -->
...the text of page 9...
```

**Slice semantics:** `#p8` resolves from the `<!-- page: 8 -->` marker to the line before `<!-- page: 9 -->`; `#p12-14` spans the `<!-- page: 12 -->` marker to the `<!-- page: 15 -->` marker (exclusive upper bound -- the slice ends just before the `page: 15` marker, so the range covers pages 12, 13, and 14). The lower marker is inclusive, the next-page marker is exclusive.

**Optional, with a documented fallback:** markers are never required. When present, `#p` resolves to a bounded passage; when absent, a `#p` locator degrades to the audit's first-class `insufficient-locator` verdict (NOT an error). This is additive -- it imposes nothing on existing sources, and unmarked paginated sources are not errors (D-06). The fallback nudges authors toward `#sec:`/`#para` locators for markdown-native sources that have no real pages.

**Graceful degradation for `#r<n>`:** When a source has no bibliography section, `#r<n>` resolves to `insufficient-locator` (NOT an error), matching the `#p` page-marker precedent. Authors citing sources without bibliographies should prefer `#sec:` or `#para` locators instead.

**Document-now / helper-later (D-07):** the curator hand-marks sources today; any auto-insertion helper (e.g. PDF-to-markdown page-break detection at ingest) is deferred to a later version. The audit consumes the markers read-only; ingest gains zero new logic from this convention.

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
- Research synthesis claim: `[prov:<report-slug>#r7|derived|<date>]`
- Repository code claim: `[prov:<repo-source-slug>#path:src/parser.py:L10-L25|direct|<date>]`
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

Each source summary page in `wiki-cloud/sources/` (or `wiki-local/sources/` for local-only sources) serves as the registry entry for that source. Its frontmatter contains: `id` (the source_id), `path`, `title`, `source_type`, `url`, `content_hash`, `ingested_at`.

This is the Dataview-native approach -- query source metadata with:

```dataview
TABLE source_type, ingested_at, content_hash
FROM "wiki-cloud/sources"
WHERE status = "active"
SORT ingested_at DESC
```

No separate registry file is needed. Source summary pages ARE the registry.

### Provenance Validation Rules

1. Every `[prov:...]` reference MUST resolve to a known source ID in `wiki-cloud/sources/` or `wiki-local/sources/`.
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
FROM "wiki-cloud"
FLATTEN file.lists.text as item
WHERE contains(item, "[epistemic:: tentative]")
```

### Page-Level vs Claim-Level Epistemic Status

- **Page-level:** `epistemic_status` frontmatter field (`schema/reference/frontmatter.md`). Reflects overall page evidence quality: `sourced`, `mixed`, `tentative`, or `stale`.
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
- Both source references in the contradiction marker MUST resolve to known sources in `wiki-cloud/sources/` or `wiki-local/sources/`
- The lint does NOT decide which source is correct -- it surfaces the disagreement
- Pages with any contradiction marker must have `has_contradictions: true` in frontmatter (lint syncs this mechanically)
- Contradictions are severity: **warning** (source disagreement is expected in scholarship)
- Semantic conflicts without provenance grounding are out of scope for v1 (per D-02)

See: examples/kahneman/concepts/loss-aversion.md for a concrete filled-in instance.

## See Also

- [AGENTS.md](../../AGENTS.md) — routing-table stub (pointer to this file and to `schema/workflows/lint.md` for decay math).
- `schema/workflows/lint.md` — decay rate table, epistemic modifiers, staleness auto-fix rules.
- `schema/reference/frontmatter.md` — frontmatter fields including `epistemic_status`.
