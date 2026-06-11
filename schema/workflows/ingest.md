# Ingest Workflow

> Agent-authoritative reference for the ingest workflow: classifying a source, extracting claims with provenance, and merging into the wiki.
> The AGENTS.md routing table points here. If you find a discrepancy between this file and AGENTS.md, this file wins.

```
Trigger:  User places a new source document and requests ingestion
Inputs:   Source file at sources/YYYY/YYYY-MM/YYYY-MM-DD-slug/ (bundle) or .md (single file)
Outputs:  Source summary page, updated wiki pages, updated index, updated log
Commit:   ingest(<source-slug>): <one-line summary>
```

**Steps:**

1. User places source document in `sources/YYYY/YYYY-MM/YYYY-MM-DD-slug/` (bundle with `source.md` + assets) or `sources/YYYY/YYYY-MM/YYYY-MM-DD-slug.md` (single file).
2. LLM reads the source document completely.
3. **Classify** (Pipeline Pass 0): Determine source type -- article, paper, transcript, journal entry, data file, image-heavy, or research-report. See `schema/reference/source-types.md` for type definitions and the extension decision rule.
   - **research-report:** AI-synthesized or third-party aggregated reports (Claude / ChatGPT / Perplexity / similar). These are secondary sources — ALL claims use `support_type: derived` (NEVER `direct`) and a lower epistemic default (`mixed`). See `schema/reference/source-types.md`.
4. **Diff** (Pipeline Pass 1): Read `wiki-cloud/index.md`, identify related existing pages, read their TL;DR and Key Facts sections. Determine what this source adds that the wiki does not already cover.
5. **Extract** (Pipeline Pass 2): Extract claims with provenance locators, applying the claim granularity rules in this file (see Claim Granularity Rules below) based on the source type classified in step 3. Create source summary page at `wiki-cloud/sources/<source_id>.md` (or `wiki-local/sources/` if content derives from a local source -- see `schema/reference/privacy.md`) with full frontmatter including `path`, `content_hash`, `ingested_at`, and `source_type`.
6. **Merge** (Pipeline Pass 3): Update or create entity/concept/overview pages using UPDATE operations (see `schema/workflows/structured-operations.md`) and the append-then-synthesize policy (see Incremental Update Policy below). Generate wikilinks on first mention (see `schema/reference/wikilinks.md`). MERGE pages if the source reveals duplicates.
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
        3. Otherwise, look up `git config user.email` in `.git-author-map.txt` at the repo root (case-insensitive; format `email  ->  @handle`, `#` comments allowed). On hit, emit `contributor:: @handle` as a Dataview inline body field directly below the `## [YYYY-MM-DD]` log-entry header (see `schema/reference/log-format.md`).
        4. On map miss, warn to stderr (actionable: suggest `--contributor @handle` or adding the mapping) and OMIT the field. NEVER write a bare email into the `contributor::` field (privacy hygiene + parser consistency).
      Git commit authorship remains the attribution source of truth; `contributor::` is a Dataview convenience index.
10. Commit: `ingest(<source-slug>): <one-line summary>`

**Abort conditions:**

- Source is unreadable or corrupted. Log failure in `wiki-cloud/log.md`, do NOT create partial wiki pages.
- Source duplicates an already-ingested source (check `content_hash` against existing source summary pages). Log the duplicate detection, do NOT re-ingest.
- Privacy tier cannot be determined. Default to `wiki-local/` placement and log the classification gap.

## Claim Granularity Rules

Source classification drives extraction depth. The guiding heuristic: **"the smallest unit that preserves meaningful provenance without making the page unreadable."**

| Source Type | Default Granularity | Guidance |
|-------------|-------------------|----------|
| article, paper, report, technical doc — sub-cases of `article` or `paper` | Atomic claims | One provenance marker per distinct assertion. Split when a paragraph contains multiple independently important assertions. |
| book-chapter, essay — sub-cases of `article` or `paper` | Atomic for factual/conceptual claims; paragraph-level for broader interpretive passages | Important factual claims get individual provenance. Interpretive or argumentative passages that form a single coherent point stay grouped. |
| transcript, meeting notes, journal entry | Paragraph-level or utterance-level clusters | Group by natural conversation turns or reflection units. Individual sentences rarely stand alone as claims. |
| image-heavy, mixed media | Tied to specific image, caption, or observation | Each image or visual element that contributes a distinct claim gets its own provenance marker referencing the image locator. |
| research-report | Atomic claims, but every claim MUST carry `support_type: derived`; the report's synthesized conclusions are extracted, not its internal sources. | Never use `direct` — the report is a secondary source. Exception: the report's own source summary page self-cites with `direct` (see the self-citation exception in `schema/reference/source-types.md`). Locators: `#r<n>` for bibliography-specific claims; `#sec:` or `#para` for body claims. |

**Bias toward atomic:** Across all source types, prefer atomic granularity for durable factual and conceptual claims. The split/group decision:
- **Split** when a paragraph contains multiple independently important assertions that future readers might cite separately.
- **Keep grouped** when a passage is only useful as one bundled observation and splitting would lose context.

## Incremental Update Policy: Append-Then-Synthesize

The default policy for living wiki pages (entities, concepts, overviews, comparisons):

1. **Append in the detail layer:** Add new claims into the appropriate detail sections, preserving all existing material. Never silently delete existing claims. Insert new claims at the end of the relevant section with their provenance markers.
2. **Mark superseded or stale claims per current schema conventions:** When new information contradicts or replaces an existing claim, mark the old claim as superseded or stale using the epistemic and provenance syntax currently documented in the schema (see `schema/reference/provenance.md`), and add a short note pointing to the superseding claim. Never remove the old claim -- the provenance trail must remain visible. Phase 5 will formalize the exact contradiction and staleness semantics; until then, follow current schema conventions and keep the old claim visible.
3. **Re-synthesize the summary layer:** After appending new detail, rewrite the TL;DR and Key Facts sections so they reflect the complete current state of the page -- all claims, old and new. This is the only place where rewriting is expected on every update.
4. **Record framing shifts:** If new material fundamentally changes a page's framing or interpretation, record the shift in a decision/reflection entry (see `schema/workflows/reflect.md`) rather than hiding it inside prose edits.

**Exceptions:**
- **Logs and source summary pages:** Strict append-only. These are records, not living synthesis. Never rewrite existing log entries or source summary content.
- **Full section rewrite:** Reserved for exceptional cases only -- severe page drift, extensive duplication, or fundamentally broken earlier structure. When performed, log the rationale as a decision record.

**Mantra:** "Append in the detail layer, synthesize in the summary layer, supersede explicitly when needed."

## See Also

- [AGENTS.md](../../AGENTS.md) — routing-table stub (dispatch pointer to this file).
- `schema/workflows/structured-operations.md` — the UPDATE/MERGE operations the merge step invokes.
- `schema/reference/provenance.md` — provenance marker syntax used during extraction.
- `schema/reference/log-format.md` — consolidated log entry format reference.
