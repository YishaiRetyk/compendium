---
phase: 17
reviewers: [codex, claude]
reviewed_at: 2026-06-05
review_cycle: 4
plans_reviewed: [17-01-PLAN.md, 17-02-PLAN.md, 17-03-PLAN.md, 17-04-PLAN.md]
---

# Cross-AI Plan Review — Phase 17 (Cycle 4)

> Reviewer set: Codex (independent) + Claude (separate session) + orchestrator direct
> repo verification. This is CYCLE 4: the plans were revised (commit 07855aa) to resolve
> the 3 remaining cycle-3 HIGHs by (NEW-C) merging the duplicate `lint.md` routing rows
> into ONE combined row — replacing the pre-existing decay row rather than adding a second;
> (NEW-D) adding the `> ` blockquote prefix to every inserted routing-row example in Plans
> 02/03; (NEW-A) closes once NEW-C lands. Every verdict below was re-checked against the
> revised plan text AND the live repo (CLAUDE.md routing-row format at L41–60, the lint.md
> decay row at L46, Plan 02/03 row-insertion strings and acceptance assertions).

## Cycle-3 HIGH Resolution Audit (orchestrator-verified)

| # | Cycle-3 HIGH | Verdict | Evidence |
|---|--------------|---------|----------|
| NEW-C | `lint.md` would carry TWO routing-table rows (pre-existing decay row L46 + new Lint-workflow row); Plan 03 `-eq 1` assertion fails for `lint` | **RESOLVED** | Plan 03 Task 4 (17-03 L417–423) now explicitly REPLACES the L46 decay row with ONE combined row `> \| Lint workflow + decay/staleness auto-fix math + CI severity/JSON contract \| \`schema/workflows/lint.md\` \|`, and the acceptance block (L474, L479) asserts BOTH that the standalone decay-only row count is 0 (`grep -c '^> \| Decay table / staleness auto-fix math \|' … -eq 0`) AND exactly one lint.md routing row remains (`-eq 1`). Self-enforcing in both directions: failing to replace → 2 rows → `-eq 1` fails; adding instead of replacing → decay-`-eq 0` catches the survivor. Orchestrator-confirmed live L46 decay row exists today and the scaffold Lint stub at L59 (`…lint.md\`; full procedure…`) is NOT matched by the cell-boundary regex (closing backtick followed by `;` not ` \|`) and is deleted with the scaffold block anyway. |
| NEW-D | Inserted rows in Plans 02/03 lacked the `> ` blockquote prefix → broke blockquote, failed `^> \|` assertion, tripped Plan 04 orphan guard | **RESOLVED** | All inserted rows now carry the leading `> ` (17-02 L236–237 for ingest/query; 17-03 L422/426/429–433 for lint/reflect/structured-ops/brownfield/release/audit/log-format). Plan 02 L231–234 and Plan 03 carry explicit BLOCKQUOTE-PREFIX callouts. Mechanically enforced, not merely documented: a row pasted without `> ` fails the `^> \|.*\`path\` \|` anchor → `-eq 1` count returns 0 → assertion fails (17-02 L246/253, 17-03 L474/480/481). An executor who ignores the prose still cannot land a non-prefixed row. |
| NEW-A | (carried) Plan 03 `-eq 1` one-row assertion unsatisfiable until NEW-C lands | **RESOLVED** | Mechanically dependent on NEW-C. With the single combined row, lint.md's routing-row count is exactly 1; the §-stub arrow (`→ See …`, not `> \|`-prefixed) is correctly excluded by the cell-boundary regex. The one-row invariant (17-03 L481, byte-identical regex to Plan 04's orphan guard at 17-04 L161/L172) is now satisfiable for every file in the loop (`structured-operations ingest query lint reflect brownfield release audit` + `log-format`). |

**All 3 cycle-3 HIGHs FULLY RESOLVED.** Both independent reviewers (Codex, Claude) and the
orchestrator concur. The resolutions are self-checking via the existing acceptance assertions
rather than relying on executor discipline.

## Codex Review (verbatim)

```
Cycle-3 HIGHs
- NEW-C: RESOLVED. Plan 03 now explicitly replaces the existing decay-only lint.md row
  instead of adding a second row: lines 417-423. Acceptance also checks the old row is gone
  and exactly one lint.md routing-table row remains: line 481.
- NEW-D: RESOLVED. Plan 02 requires "> " blockquote prefixes and gives prefixed Ingest/Query
  rows: lines 229-237. Plan 03 repeats the blockquote-prefix requirement and all added rows
  are prefixed: lines 410-433. Acceptance calls this out directly: line 482.
- NEW-A: RESOLVED, contingent on Plan 03 landing as written. The one-row invariant is now
  scoped to routing-table rows, not raw path occurrences: Plan 03 lines 438-449. The
  assertions use ^> \|.*`path` \|, so stub arrows do not count: Plan 03 lines 476 and 483;
  Plan 02 line 247 for ingest/query.

New Concerns
- No new HIGHs found.
- MEDIUM: Plan 04's green-path verification can pass even with orphan warnings, because
  ORPHAN is intentionally warning severity and `bash bin/lint.sh --category routing` only
  asserts exit 0. ORPHAN is warning by design at Plan 04 lines 159-172 and severity is
  preserved at lines 173-180, but the verify/acceptance relies on exit 0 at lines 198 and
  202. Add a JSON assertion over the real tree that there are no routing findings, or at
  least no ORPHAN: findings, if the acceptance criterion means "no orphan files" rather
  than merely "non-gating."
- LOW: The inserted row examples are represented as inline-code snippets with escaped inner
  backticks in the plan prose. The automated ^> \| assertions should catch bad literal
  pastes, so this is not a blocker.
```

## Claude Review (verbatim)

```
Cycle-3 HIGHs
- NEW-C (duplicate lint.md routing rows) — RESOLVED. Live CLAUDE.md L46 confirms the
  pre-existing decay row. Plan 03 now REPLACES it rather than adding a second row (17-03
  L418-422). Self-enforcing in both directions: non-replacement (two rows) fails the -eq 1
  loop (L474); adding a second row instead of replacing is caught by the decay-row -eq 0
  check (L474). The scaffold Lint row (live L26) also contains the lint.md path but its
  closing backtick is followed by ';' not ' |', so it does NOT match the row regex — no
  spurious double-count — and it's deleted with the scaffold block anyway. Clean.
- NEW-D (missing "> " blockquote prefix) — RESOLVED. All inserted rows in both plans now
  carry the leading "> " (17-02 L236-237, 17-03 L422/426/429-433). Mechanically enforced:
  a row without "> " fails the ^> \| anchor → -eq 1 count returns 0 → assertion fails. Even
  an executor who ignores the prose cannot land a non-prefixed row. Strong.
- NEW-A (carried) — RESOLVED. Mechanically dependent on NEW-C. With the single combined
  row, lint.md's row count is exactly 1, and the §-stub arrow is correctly excluded.

No new HIGHs introduced. Checked Plan 02↔03 ordering on the lint row (no assertion window
where the count is 0 or 2), table column integrity (no literal | inside any new cell text),
and Plan 04 orphan/forward definitions (still single routing-table-row definition,
consistent with Plan 03; negative test de-rows audit.md while leaving its stub, correctly
proving stub arrows ≠ reachability). All sound.

Lower-severity:
- MEDIUM (carried, not new) — §N-sweep enumeration vs catch-all. Plan 03's CORE §N SWEEP
  lists 4 specific conversions but the true gate is the catch-all ! grep -qE '§[0-9]'
  CLAUDE.md. The core §9 stub / §10 one-line remnant Plan 01 leaves resident aren't
  explicitly swept by the enumerated 4; they'll be caught by the catch-all if present, so
  worst case is a late assertion failure (executor surprise), not a silent defect. Suggest
  rewording the enumerated list as "known examples — convert every grep hit, not only these."
- LOW — combined cell verbosity (cosmetic; satisfies all asserts).
- LOW — Plan 02 leaves the live scaffold Lint row pointing at lint.md during the interval
  between Plan 02 and Plan 03. Harmless (not a matching routing row; Plan 02 doesn't assert
  lint; Plan 03 deletes the whole scaffold).

Verdict: All three cycle-3 HIGHs RESOLVED, resolutions self-checking via existing
assertions. No newly-introduced HIGHs.
```

## Consensus Summary

The cycle-4 revision (commit 07855aa) **fully resolves all three cycle-3 HIGHs**, and both
independent reviewers plus the orchestrator agree the resolutions are *mechanically
self-enforcing* — the existing acceptance assertions catch any deviation, so correctness
does not depend on executor discipline:

- **NEW-C** (lint.md double row): the decay row is REPLACED with one combined row, and the
  acceptance block asserts both the decay-only-row count is 0 and the lint.md routing-row
  count is exactly 1.
- **NEW-D** (missing `> ` prefix): every inserted row carries `> `, and the `^> \|` anchor
  in every `-eq 1` assertion rejects any non-prefixed paste.
- **NEW-A** (carried `-eq 1` unsatisfiable): resolved transitively by NEW-C; the one-row
  invariant is now satisfiable for all nine extracted files, and the row-count regex is
  byte-identical between Plan 03's one-row assertion and Plan 04's orphan guard.

**No newly-introduced HIGHs.** Both reviewers explicitly checked the interactions the
cycle-4 edits could have disturbed (Plan 02↔03 lint-row ordering, table column integrity,
Plan 04 orphan/forward definitions) and found them sound.

### Agreed Strengths
- The lint.md dedup is self-enforcing in BOTH directions (two-row → `-eq 1` fails;
  add-not-replace → decay-`-eq 0` catches the survivor) — verified by both reviewers.
- The `> ` blockquote prefix is enforced by the same `^> \|` anchor the one-row assertion
  uses, so a non-prefixed paste fails fast rather than silently corrupting the table.
- The scaffold Lint stub (live L59/L26) does NOT spuriously match the row regex (closing
  backtick followed by `;`, not ` |`) AND is deleted with the scaffold block — confirmed by
  both reviewers and the orchestrator.
- Plan 03's one-row regex and Plan 04's orphan-guard regex are byte-identical, keeping the
  two surfaces consistent.

### Agreed Concerns (non-HIGH — do not block phase close)
1. **[MEDIUM — Codex] Plan 04 positive-path doesn't assert zero orphan findings.**
   `bash bin/lint.sh --category routing` exits 0 even with ORPHAN warnings (ORPHAN is
   warning-severity, non-gating), so the criterion's parenthetical "(no orphan files)" is
   aspirational, not asserted over the real tree. The negative test (17-04 L212) proves the
   ORPHAN mechanism fires correctly; the gap is only that the *positive* path could green
   with a stray orphan. Low real risk (Plans 02/03 fully row every extracted file), but a
   one-line JSON assertion "no `ORPHAN:` routing findings over the extracted tree" would
   make the criterion match its stated intent. Orchestrator-confirmed at 17-04 L208.
2. **[MEDIUM — Claude, carried] §N-sweep enumeration vs catch-all.** Plan 03's CORE §N SWEEP
   lists 4 named conversions; the true gate is the catch-all `! grep -qE '§[0-9]' CLAUDE.md`.
   The core §9 stub / §10 remnant Plan 01 leaves resident aren't in the enumerated 4 — they'll
   be caught by the catch-all if present (late assertion failure, not silent defect). Reword
   the list as "known examples — convert every grep hit, not only these four."

### Divergent Views
- None of substance. Codex's MEDIUM (Plan 04 positive-path) and Claude's MEDIUM (§N-sweep
  enumeration) are different, non-overlapping observations; each reviewer found one the other
  did not, and both are non-blocking. Both reviewers AND the orchestrator independently
  reached the SAME core verdict: all three cycle-3 HIGHs RESOLVED, zero new HIGHs.

### Recommended next step
No HIGH concerns remain. The plan set is ready to execute from the routing-mechanism
standpoint. Optionally fold the two MEDIUMs into a final touch-up before execution:
(1) add a positive-path "no ORPHAN findings over the extracted tree" JSON assertion to
Plan 04 Task 1; (2) reword Plan 03's §N-sweep enumeration to "convert every grep hit, not
only these four." Neither blocks phase close.
