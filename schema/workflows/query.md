# Query Workflow

> Agent-authoritative reference for the query workflow: searching the wiki, synthesizing a cited answer, the mandatory write-back rules, privacy-tier routing, and delta compilation.
> The AGENTS.md routing table points here. If you find a discrepancy between this file and AGENTS.md, this file wins.

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
7. **Apply write-back** -- If write-back is triggered, apply using structured operations (see `schema/workflows/structured-operations.md`). Run `bin/validate-op.sh` before applying each operation.
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

**Deterministic structural rule (see `schema/reference/privacy.md` asymmetric model):** If ANY source contributing to the synthesis lives under `wiki-local/` (its source-summary is in `wiki-local/sources/`), the write-back target page MUST go into `wiki-local/`. A page in `wiki-cloud/` may cite only sources whose summaries are under `wiki-cloud/sources/`. This is a structural check, not a judgment call.

**How to apply:**
1. Collect all source IDs referenced in the synthesized answer (from provenance markers and the `sources` frontmatter list of pages read).
2. Check each source-summary's tier: is the summary page under `wiki-cloud/sources/` or `wiki-local/sources/`?
3. If ANY contributing source summary is under `wiki-local/`, the write-back target belongs in `wiki-local/`.
4. If updating an existing `wiki-cloud/` page with `wiki-local/`-sourced content: STOP. Either (a) create a new page in `wiki-local/` for the sensitive synthesis, or (b) move the existing page to `wiki-local/` if appropriate.
5. Run `bin/validate-op.sh` -- it enforces this rule mechanically (Check 4).

#### Delta Compilation

Before or during answer synthesis, check whether relevant sources have uncompiled material:

1. Read source summary pages referenced by or related to the query topic.
2. Check `compilation_status` field (see `schema/reference/frontmatter.md`): if `pending`, `partial`, or `stale`, the source has uncompiled material.
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

## See Also

- [AGENTS.md](../../AGENTS.md) — routing-table stub (write-back-mandatory residue + routing table).
- `schema/workflows/structured-operations.md` — the UPDATE/CREATE operations write-back invokes.
- `schema/reference/privacy.md` — the asymmetric tier rule governing write-back placement.
- `schema/reference/log-format.md` — consolidated log entry format.
