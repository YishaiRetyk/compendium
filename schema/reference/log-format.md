# Index and Log Format

> Agent-authoritative reference for `wiki-cloud/index.md` and `wiki-cloud/log.md` formats: the content-index entry shape, the chronological activity-log entry format, the structured-operation extended log entries, and the contributor inline field.
> The AGENTS.md routing table points here. If you find a discrepancy between this file and AGENTS.md, this file wins.

## index.md (Content Index)

- Lives at `wiki-cloud/index.md`.
- Organized by page type: Entities, Concepts, Sources, Comparisons, Overviews, Decisions.
- Each entry follows the format: `- [[Page Title]] -- <one-line summary> (<epistemic_status>, <updated_at>)`
- Updated on every ingest and every query that creates or modifies pages.
- The LLM reads this FIRST when searching for information (read the index first when searching, per the LLM Navigation Rule in `AGENTS.md`). A `wiki-local/index.md` is created lazily for local-only navigable content (D-07).
- Archived pages are listed separately under an "Archived" heading if any exist.
- The index is the primary navigation mechanism for both LLMs and humans browsing the wiki.

## log.md (Activity Log)

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
- Structural reasoning and decision analysis belong in decision record pages (`schema/workflows/reflect.md`), NOT in the log. The log records WHAT happened; decision records explain WHY.

## Structured Operation Log Entries

When logging individual structured operations (UPDATE, MERGE, SUPERSEDE, ARCHIVE), use this extended format:

> **Canonical shape.** This multi-line `source:` / `result:` / `reason:` form is the ONE canonical
> structured-operation log entry. The compact one-line form shown in the core `## 9. Structured Operations`
> dispatch stub (`## [date] OP | page` + a single combined `source: … | result: … | reason: …` line) is a
> dispatch summary of THIS entry, not a competing standard — the two never diverge.

```markdown
## [YYYY-MM-DD] OPERATION | target_page

source: source_id
result: what changed (e.g., "added 3 claims, refreshed TL;DR")
reason: one-line rationale
```

This format extends the base log entry format with structured sub-fields for machine-parseability. It applies to individual operations, NOT to workflow-level entries. Workflow-level entries (ingest, query, lint, reflect) use the base format with their own sub-fields as defined in the per-workflow files.

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

## Contributor inline field (COLAB-03, Phase 9)

Log entries may carry an optional `contributor:: @github-handle` Dataview inline body field immediately below the entry header:

```markdown
## [YYYY-MM-DD] ingest | <description>

contributor:: @octocat

<rationale and affected pages>
```

**Rules:**

- `contributor::` is a **Dataview inline body field** (per the inline-field syntax precedent in `schema/reference/provenance.md`). It MUST NOT be placed in YAML frontmatter (the no-wikilinks-in-frontmatter prohibition in `AGENTS.md` Global Rules also covers inline Dataview fields in frontmatter).
- Handle format: `@github-handle` -- leading `@` required. `bin/search.sh --contributor` accepts both `@octocat` and `octocat` forms (leading `@` stripped internally).
- **Single-author repos omit the field entirely** -- `bin/ingest.sh` auto-detects via `git log --all --format='%ae' | sort -u | wc -l == 1` (see `schema/workflows/ingest.md` step 9a).
- **Git commit authorship is the attribution source of truth** (COLAB-05). The `contributor::` field is a Dataview convenience index for filtering log history by contributor (`bin/search.sh --contributor @alice`); it is NOT authoritative.
- Handle-to-email resolution lives in `.git-author-map.txt` at the repo root (committed, human-curated, `email  ->  @handle` format; `#` comments; case-insensitive email match).
- `bin/lint.sh` category `contributor` (severity `warning`) catches `@handle` values in `wiki-cloud/log.md` whose `.git-author-map.txt` email does NOT appear in `git log --all --format='%ae'` -- non-blocking consistency check. Skipped on single-author repos.

**Queryable via Dataview:**

```dataview
LIST
FROM "wiki-cloud/log.md"
WHERE contains(file.lists.text, "contributor:: @octocat")
```

## See Also

- [AGENTS.md](../../AGENTS.md) — routing-table stub (index/log format pointer to this file).
- `schema/workflows/reflect.md` — decision record pages referenced from the log (structural reasoning lives in decisions, not log entries).
- `schema/workflows/ingest.md` — ingest log entry format (bare workflow-level shape).
- `schema/workflows/query.md` — query log entry format (includes `write_back:` and `delta_compiled:` fields).
- `schema/workflows/lint.md` — lint log entry format.
