# Reflect Workflow

> Agent-authoritative reference for the reflect workflow: the three-tier decision-record model, the reflect checkpoint, and the periodic backfill procedure.
> The AGENTS.md routing table points here. If you find a discrepancy between this file and AGENTS.md, this file wins.

The reflect workflow creates decision records (see `schema/reference/page-types.md` decision page type) that capture why structural changes were made to the wiki. It operates through three tiers, from automatic to manual.

```
Trigger:  After structural operations, on workflow recommendation, or periodically
Inputs:   Recent changes (from wiki-cloud/log.md and git history), reflect checkpoint state
Outputs:  Decision record page(s) in wiki-cloud/decisions/, updated index/log, advanced checkpoint
Commit:   reflect(<scope>): <one-line summary>
```

## Three-Tier Reflect Model

**Tier 1 -- Inline creation:** MERGE, SUPERSEDE, splits, domain reorganization, schema updates, and recognized reframings produce decision records as part of the operation commit. No separate reflect pass needed. The agent creating the structural change also creates the decision record in the same commit. See the MERGE/SUPERSEDE inline-DR hooks in `schema/workflows/structured-operations.md`.

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

## Reflect Checkpoint

The reflect checkpoint lives at `wiki-cloud/maintenance/reflect-state.md`. It tracks where the last reflect pass ended so subsequent passes resume from the correct position, even when a pass produces no decision records.

Fields (in frontmatter):
- `last_reflect_log_entry`: The full heading line of the last log entry scanned (e.g., `"## [2026-04-14] lint | wiki health check"`)
- `last_reflect_commit`: The short SHA of the last git commit inspected (e.g., `"abc1234"`)
- `last_reflect_at`: ISO 8601 date of the last reflect pass (e.g., `2026-04-14`)

`wiki-cloud/maintenance/` is a control-plane directory for cloud-tier infrastructure. Files here (lint-report.md, reflect-state.md) are NOT listed in wiki-cloud/index.md -- they are infrastructure, not content. `wiki-local/maintenance/` holds the audit control-plane (audit-report.md, audit-state.md).

## Periodic Reflect Procedure (Tier 3)

1. Read the reflect checkpoint from `wiki-cloud/maintenance/reflect-state.md`.
2. Scan `wiki-cloud/log.md` for entries after `last_reflect_log_entry`. Identify:
   - Structural operations: MERGE, SUPERSEDE, ARCHIVE entries
   - Schema changes: entries referencing AGENTS.md modifications
   - Workflow recommendations: lines matching `reflect recommended: [trigger_type] -- [reason]`
3. Inspect `git log --oneline` for commits after `last_reflect_commit`. Look for structural file changes: new/deleted/renamed pages, template modifications, AGENTS.md updates, directory reorganizations. **Deduplication rule:** If both log.md and git show the same event, use the log.md entry as the primary trigger (it has intent). Git-only changes (no log entry) indicate unrecorded structural work and should be investigated.
4. For each identified structural change that lacks a corresponding decision record:
   a. Create a decision record page in `wiki-cloud/decisions/` using the decision template (see `schema/reference/page-types.md` decision page type).
   b. Set `trigger_type` to the most appropriate value from the six allowed types.
   c. Set `affected_pages` to the IDs of pages touched by the change.
   d. Fill all 7 required sections with real content (not placeholders). The "Why" section must state what framing was adopted and what it replaced. "Alternatives Considered" must list at least one alternative.
   e. Add the decision record ID to `decision_history` on each affected page's frontmatter (only when meaningful per D-05).
5. Update `wiki-cloud/index.md` with new decision record entries under the Decisions category.
6. Append entry to `wiki-cloud/log.md`: `## [YYYY-MM-DD] reflect | <scope>` with a summary of how many decision records were created, or "no structural changes detected" if none.
7. Advance the reflect checkpoint: update `last_reflect_log_entry` to the most recent log entry heading, `last_reflect_commit` to current HEAD short SHA, `last_reflect_at` to today's date. **A reflect run that produces no decision records still advances the checkpoint.**
8. Commit: `reflect(<scope>): <one-line summary>`

## Abort Conditions

- No structural changes detected since the last checkpoint AND no pending workflow recommendations. Advance the checkpoint (step 7) and skip record creation. Log: `## [YYYY-MM-DD] reflect | no structural changes detected`.
- Log entry for a structural operation already has a corresponding decision record in `wiki-cloud/decisions/` (check by date + scope match). Skip that event -- already recorded.

## Unifying Principle

Create a decision record when future-you would reasonably ask "why is the wiki shaped this way?" When in doubt, record. A redundant record is retrievable; a missing record is lost context.

## See Also

- [AGENTS.md](../../AGENTS.md) — routing-table stub (reflect workflow pointer to this file).
- `schema/workflows/structured-operations.md` — MERGE/SUPERSEDE inline decision-record hooks (Tier 1).
- `schema/reference/page-types.md` — decision record page type (section ordering, frontmatter fields).
