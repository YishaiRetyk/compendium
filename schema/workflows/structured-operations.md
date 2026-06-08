# Structured Operations and Executor Model

> Agent-authoritative reference for the four mutation operations (UPDATE / MERGE / SUPERSEDE / ARCHIVE), the executor validation model, and deterministic enforcement.
> The AGENTS.md routing table points here. If you find a discrepancy between this file and AGENTS.md, this file wins.

### Operation Definitions

**UPDATE** -- Modify an existing page with new information.

1. Add new claims with provenance markers to the appropriate section of the existing page.
2. Preserve all existing provenance markers -- do not remove or overwrite them.
3. Add new source IDs to the `sources` list in frontmatter.
4. Update `updated_at` in frontmatter to today's date.
5. If new claims change the evidence balance, update `epistemic_status` accordingly.
6. Log: `"UPDATE <page_id>: <one-line rationale>"`

For the full incremental update policy governing how new claims integrate with existing content during ingestion, see `schema/workflows/ingest.md` (Append-Then-Synthesize).

**MERGE** -- Combine two pages covering the same concept.

1. Create a new merged page with the union of claims from both pages, preserving all provenance markers.
2. Set `supersedes` on the new page to list both merged page IDs.
3. Set `superseded_by` on both old pages to point to the new page ID.
4. Set `status: superseded` on both old pages.
5. Replace the body of both old pages with a brief redirect note: `> This page has been merged into [[New Page Title]].`
6. Update `wiki-cloud/index.md`: add the new page, move old pages to "Archived" section (if one exists) or remove them from active listings.
7. Log: `"MERGE <page_a> + <page_b> -> <new_page>: <rationale>"`
7a. **Decision record (inline -- Tier 1):** If this merge represents a significant structural choice -- combining two established pages, resolving a long-standing organizational ambiguity, or eliminating a redundant page that multiple other pages linked to -- create a decision record page in `wiki-cloud/decisions/` with `trigger_type: merge` and `affected_pages` listing both original page IDs and the new merged page ID. Add the new decision record to `wiki-cloud/index.md` under Decisions. Commit the decision record as part of this same commit. **Skip for trivial cleanup merges** (e.g., merging a stub into its parent when the stub has no unique claims). See `schema/workflows/reflect.md`, Tier 1.

**SUPERSEDE** -- Mark a page or claim as replaced by newer information.

1. Set `superseded_by` on the old page to the replacing page's ID.
2. Set `status: superseded` on the old page.
3. Add a note at the top of the old page body: `> This page has been superseded by [[New Page Title]].`
4. On the new page, set `supersedes` to the old page's ID.
5. Update `wiki-cloud/index.md`: move the old page to "Archived" section or remove from active listings.
6. Log: `"SUPERSEDE <old_page> -> <new_page>: <rationale>"`
6a. **Decision record (inline -- Tier 1):** If this supersession replaces a key page or represents a significant editorial judgment -- the new page substantially reframes the concept, or the superseded page was widely linked -- create a decision record page in `wiki-cloud/decisions/` with `trigger_type: reframing` (if the new page reframes the concept) or `trigger_type: merge` (if consolidating). Set `affected_pages` to include both old and new page IDs. Add to `wiki-cloud/index.md` under Decisions. Commit as part of this same commit. **Skip for routine stale-claim supersessions** (e.g., updating a fact to a newer version without reframing). See `schema/workflows/reflect.md`, Tier 1.

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
4. **Frontmatter is valid:** All required base fields are present and correctly typed (see `schema/reference/frontmatter.md` validation checklist).
5. **Privacy is respected:** No `wiki-local/` content is included in operations that will be sent to cloud APIs (see `schema/reference/privacy.md` asymmetric model).

If validation fails, the LLM MUST NOT apply the operation. Instead, log the validation failure and report it to the user.

Every operation MUST be logged in `wiki-cloud/log.md` with: timestamp, operation type, affected page(s), and rationale. See `schema/reference/log-format.md` for log format.

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
- Privacy tier: If new content derives from `wiki-local/` sources but target is in `wiki-cloud/`, STOP — see `schema/reference/privacy.md` and the query workflow at `schema/workflows/query.md` privacy rules.

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

## See Also

- [AGENTS.md](../../AGENTS.md) — routing-table stub (ops-vocab table + validate-op.sh pointer + solo-op log/commit shapes).
- `schema/workflows/ingest.md` — the Append-Then-Synthesize incremental-update policy invoked by UPDATE.
- `schema/workflows/reflect.md` — Tier-1 inline decision-record hooks invoked by MERGE/SUPERSEDE.
- `schema/reference/log-format.md` — structured-operation log entry format.
