# Ingest Workflow

> Agent-authoritative reference for the ingest workflow: classifying a source, extracting claims with provenance, and merging into the wiki.
> The AGENTS.md routing table points here. If you find a discrepancy between this file and AGENTS.md, this file wins.

> **Note:** The step-by-step ingest procedure is added by Plan 02. This file currently holds the two reference blocks folded in from the former Compiler Pipeline section of AGENTS.md (claim-granularity + incremental-update policy).

## Claim Granularity Rules

Source classification drives extraction depth. The guiding heuristic: **"the smallest unit that preserves meaningful provenance without making the page unreadable."**

| Source Type | Default Granularity | Guidance |
|-------------|-------------------|----------|
| article, paper, report, technical doc | Atomic claims | One provenance marker per distinct assertion. Split when a paragraph contains multiple independently important assertions. |
| book-chapter, essay | Atomic for factual/conceptual claims; paragraph-level for broader interpretive passages | Important factual claims get individual provenance. Interpretive or argumentative passages that form a single coherent point stay grouped. |
| transcript, meeting notes, journal entry | Paragraph-level or utterance-level clusters | Group by natural conversation turns or reflection units. Individual sentences rarely stand alone as claims. |
| image-heavy, mixed media | Tied to specific image, caption, or observation | Each image or visual element that contributes a distinct claim gets its own provenance marker referencing the image locator. |

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
