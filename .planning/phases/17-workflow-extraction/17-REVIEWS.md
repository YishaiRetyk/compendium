---
phase: 17
reviewers: [codex]
reviewed_at: 2026-06-05
review_cycle: 3
plans_reviewed: [17-01-PLAN.md, 17-02-PLAN.md, 17-03-PLAN.md, 17-04-PLAN.md]
---

# Cross-AI Plan Review — Phase 17 (Cycle 3)

> Reviewer set: Codex (independent) + orchestrator direct repo verification. Claude
> self-review skipped for independence (orchestrated from inside Claude Code).
> This is CYCLE 3: the plans were revised (commit a2b2ca3) to resolve the 3 remaining
> cycle-2 HIGHs by adopting ONE canonical definition of "routing reference" — the
> routing-TABLE row (`> | … | \`path\` |` blockquote cell) is the reachability anchor;
> core stub arrows (`→ See`) do NOT count — encoded in Plans 03 and 04, plus a
> reciprocal log-shape note in `log-format.md` (Plan 03 Task 3). Every verdict below was
> re-checked against the revised plan text AND the live repo (CLAUDE.md routing-table
> row format, lint.md existing row, Plan 02/03 row-insertion strings).

## Cycle-2 HIGH Resolution Audit

| # | Cycle-2 HIGH | Verdict | Evidence |
|---|--------------|---------|----------|
| NEW-A | Plan 03 Task 4 "exactly one routing row" assertion unsatisfiable (raw grep counted row + stub = 2) | **PARTIALLY RESOLVED** | The stub-arrow miscount is fixed: Plan 03 Task 4 now defines reachability as the blockquote routing-table row and asserts `grep -cE "^> \|.*\`schema/workflows/$f.md\` \|"` (L458/L463), which matches the real row shape `> | when | \`path\` |` and correctly excludes `→ See` stub arrows. BUT the `-eq 1` assertion is STILL unsatisfiable for `lint.md`: the live table already has `> \| Decay table / staleness auto-fix math \| \`schema/workflows/lint.md\` \|` (CLAUDE.md L46) and Plan 03 L410 ADDS a second `\| Lint workflow + CI severity/JSON contract \| \`schema/workflows/lint.md\` \|` row without instructing deletion/merge of the existing decay row → 2 rows → assertion fails for `lint`. See NEW-HIGH-C. |
| NEW-B | Plan 04 inverse-orphan test couldn't fire (spec "table OR stub" vs test removed only row) | **RESOLVED** | Plan 04 Task 1 step 3 (L160-172) now defines reachability as the routing-table row ALONE; the negative test (L212) deletes ONLY `^> \|.*\`schema/workflows/audit.md\` \|` from the temp AGENTS.md, leaves the `→ See` stub intact, and asserts an `ORPHAN:` warning fires in `--format json`. The test now exercises exactly the intended failure mode — spec and test agree. Orchestrator-confirmed the guard matches `> \|`-prefixed cells. |
| #3 | Plan 03 Task 3 never added the reciprocal log-shape note in `log-format.md` (Plan 01 L302 promise) | **RESOLVED** | Plan 03 Task 3 (a2b2ca3 diff) inserts the reciprocal blockquote immediately above the canonical multi-line structured-op block, and acceptance greps `dispatch summary of THIS entry`. The reconciliation is now bidirectional: core points to `log-format.md` as canonical; `log-format.md` flags the compact core form as its summary. Closes Plan 01 L302's promise. |

**2 of 3 cycle-2 HIGHs FULLY RESOLVED; NEW-A only PARTIALLY RESOLVED (the row-vs-stub
miscount is fixed, but the lint.md double-row makes the SAME `-eq 1` assertion fail for
a different reason).**

## Codex Review (verbatim)

```
NEW-HIGH-A: PARTIALLY RESOLVED — raw-grep stub miscount fixed (blockquote-row regex,
  excludes → See stubs), BUT not satisfiable for lint.md: live table has
  "Decay table / staleness … | schema/workflows/lint.md" and Plan 03 adds a second
  "Lint workflow + CI … | schema/workflows/lint.md" row. Once blockquote-prefixed the
  exact-one assertion counts 2. Fix: replace the decay row with one combined lint.md row.
NEW-HIGH-B: RESOLVED — reachability is row-only; negative test deletes only the
  routing-table row, leaves the stub, asserts ORPHAN warning in JSON. Verifies the
  intended failure mode.
HIGH#3: RESOLVED — Plan 03 Task 3 inserts the reciprocal blockquote above the canonical
  log block; acceptance greps "dispatch summary of THIS entry".

NEW HIGH concerns:
HIGH: lint.md will have TWO routing-table rows (existing decay row + new Lint-workflow
  row); Plan 03's exact-one assertion will count 2 and fail for lint. Replace the existing
  decay row with one combined row; do not add a second lint.md row.
HIGH: Added routing rows in Plans 02 and 03 are written WITHOUT the required "> "
  blockquote prefix (e.g. "| Ingesting … | `schema/workflows/ingest.md` |"). The canonical
  grep requires "^> \|.*`path` \|"; literal insertion would not match the assertion OR
  Plan 04's orphan guard. Fix all row examples to include the "> " prefix.

MEDIUM: Plan 03 and Plan 04 routing-reference definitions are semantically aligned but
  not byte-identical (the brief said "encoded identically"). Copy one paragraph verbatim
  into both, or centralize.
LOW: the row grep searches all of CLAUDE.md, not just the routing-table block; a future
  blockquoted table elsewhere could cause a false duplicate.
```

## Newly-Introduced HIGH Concerns (orchestrator-verified)

Both new HIGHs are localized regressions of the SAME cycle-3 fix: the new
"count routing-TABLE rows specifically" mechanism is sound, but its two preconditions —
(1) each path appears in exactly one routing-table row, and (2) inserted rows are
blockquote-prefixed so the canonical grep matches — are each violated by one plan.

### NEW-HIGH-C — `lint.md` will carry TWO routing-table rows; Plan 03's `-eq 1` assertion fails for `lint` (phase-close blocker)

The cycle-3 fix counts routing-TABLE rows specifically. But `lint.md` is referenced by
two DISTINCT routing-table rows after Plan 03 lands:

- **Existing (live today, CLAUDE.md L46):** `> | Decay table / staleness auto-fix math | \`schema/workflows/lint.md\` |` — a genuine "Resolvable references" blockquote row that predates Phase 17 (it points at the Phase-16 decay seed).
- **New (Plan 03 L410):** `| Lint workflow + CI severity/JSON contract | \`schema/workflows/lint.md\` |` — added by Plan 03 Task 4.

Plan 03 Task 4 instructs DELETING the scaffold "Where it lives NOW" block (which contains
the L59 scaffold lint row) but says nothing about the L46 decay row in the *Resolvable
references* table — that row survives. So after the plan, `grep -cE "^> \|.*\`schema/workflows/lint.md\` \|" CLAUDE.md`
returns **2**, and Plan 03's own acceptance loop (L458, `for f in … lint … ; [ … -eq 1 ]`)
**fails for `lint`**. This is the exact same `-eq 1` assertion the cycle-3 fix was meant to
make satisfiable — it now fails for a different reason (genuine duplicate, not stub
miscount). Verified: `grep -nE "^> \|.*schema/workflows/lint.md" CLAUDE.md` → L46 today;
Plan 03 has no "replace/merge the decay row" instruction (`grep -i decay` in Plan 03 shows
only body-ref conversions, no routing-row dedup). **Fix:** in Plan 03 Task 4, REPLACE the
existing L46 decay row with one combined row (e.g. `> | Lint workflow + decay/staleness + CI severity/JSON contract | \`schema/workflows/lint.md\` |`)
rather than adding a second; OR explicitly assert the decay row is removed. Note: Plan 04's
orphan guard is fine with 2 rows (it only needs ≥1), so this is purely a Plan-03-assertion
blocker — but it WILL halt the phase at Plan 03 verify.

### NEW-HIGH-D — Inserted routing rows in Plans 02 & 03 lack the `> ` blockquote prefix the canonical grep (and Plan 04 guard) require

The canonical reachability anchor is the blockquote-prefixed cell `^> \|.*\`path\` \|`.
But every row-insertion string in Plans 02 and 03 is written WITHOUT the `> ` prefix:

- Plan 02 L232-233: `| Ingesting a new source … | \`schema/workflows/ingest.md\` |` / `| Answering a question … | \`schema/workflows/query.md\` |`
- Plan 03 L410-418: `| Lint workflow … |`, `| Reflect workflow … |`, `| Structured operations … |`, `| Brownfield … |`, `| Orphan-branch … |`, `| Claim-faithfulness … |`, `| Index / log entry formats | \`schema/reference/log-format.md\` |`

The action text says "promote … INTO the 'Resolvable references' table," and that table
lives inside the `> ` blockquote (CLAUDE.md L41-50). A faithful executor that pastes the
literal row strings produces NON-blockquoted rows that (a) break the routing table's
markdown blockquote rendering, (b) do NOT match Plan 03's canonical assertion
`^> \|.*\`path\` \|` (so the `-eq 1` loop returns 0 for ingest/query/etc.), AND (c) at
runtime are flagged ORPHAN by Plan 04's row-only orphan guard (which also matches
`> \|`-prefixed cells, L171) — a warning storm across all 8 extracted files. The plan's
own acceptance grep and orphan guard would catch this, but the plan instruction is
internally inconsistent with the assertion it must satisfy. **Fix:** prefix every inserted
row example in Plans 02 and 03 with `> ` (e.g. `> | Ingesting a new source … | \`schema/workflows/ingest.md\` |`),
or add an explicit "insert these AS blockquote rows (prepend `> `) to match the table's
`> `-prefixed format" instruction in both plans.

## Consensus Summary

The cycle-3 revision is conceptually correct: it picks ONE canonical definition of
"routing reference" (the blockquote routing-table row), and that definition cleanly
resolves cycle-2's NEW-HIGH-B (Plan 04's orphan test now fires against the right
condition) and HIGH#3 (the reciprocal log-shape note is now present in `log-format.md`,
making the canonical/summary reconciliation bidirectional). **2 of 3 cycle-2 HIGHs are
fully resolved.**

However, cycle 3 surfaces **3 remaining HIGHs**: cycle-2 NEW-A is only PARTIALLY resolved
(the stub-miscount is fixed, but a genuine `lint.md` double-row makes the same `-eq 1`
assertion fail), plus **2 newly-introduced HIGHs** rooted in unmet preconditions of the
new row-counting mechanism — the `lint.md` duplicate row (NEW-HIGH-C, a phase-close
blocker at Plan 03 verify) and the missing `> ` blockquote prefix on all inserted row
examples (NEW-HIGH-D, which would also trigger a Plan-04 orphan warning storm). All three
are localized to Plan 03 Task 4 and Plan 02 Task 3.

### Agreed Strengths
- The single canonical "routing-table row" definition is the right call and is encoded in
  both Plan 03 (one-row assertion) and Plan 04 (orphan guard) — the load-bearing cycle-3 fix.
- Plan 04's inverse-orphan test now deletes ONLY the routing-table row and leaves the stub
  arrow intact, directly proving stub arrows do not satisfy reachability (NEW-HIGH-B closed).
- The reciprocal log-shape note in `log-format.md` (Plan 03 Task 3) closes Plan 01 L302's
  promise; the canonical/summary reconciliation is now bidirectional.
- Plan 04's orphan-guard regex (`> \|`-prefixed cell match, L171) is consistent with Plan
  03's one-row assertion regex — the two grep forms agree (this is what makes NEW-HIGH-D's
  failure mode catchable, but also what makes the missing prefix bite both surfaces).

### Agreed Concerns (highest priority — all orchestrator-verified)
1. **[HIGH, NEW-C] `lint.md` double routing-table row** — existing decay row (CLAUDE.md L46) + new Lint-workflow row (Plan 03 L410) → Plan 03's `-eq 1` assertion fails for `lint`. Phase-close blocker. Replace/merge the decay row; don't add a second lint.md row.
2. **[HIGH, NEW-D] Inserted rows lack the `> ` blockquote prefix** — Plans 02/03 row strings are written as `| … |` not `> | … |`; literal insertion breaks the blockquote, fails the canonical `^> \|` assertion, and trips Plan 04's orphan guard. Prefix every inserted row example with `> `.
3. **[HIGH, carried NEW-A] Plan 03 one-row assertion still not fully satisfiable** — the stub miscount is fixed, but NEW-C (lint.md duplicate) keeps the same `-eq 1` loop failing; this carries until NEW-C lands.

### Divergent Views
- None. Single external reviewer (Codex); every Codex verdict was independently reproduced
  by the orchestrator against the plan text and live repo. Orchestrator nuance: cycle-2
  NEW-A and cycle-3 NEW-C are the SAME assertion failing — NEW-A's stub-miscount cause is
  fixed, but the lint.md duplicate (NEW-C) keeps the `-eq 1` loop red, so NEW-A is scored
  PARTIALLY RESOLVED (counts as unresolved) and NEW-C is logged as the concrete blocker.

### Recommended next step
Feed this review back into planning:

```
/gsd-plan-phase 17 --reviews
```

All three remaining HIGHs are localized to Plan 03 Task 4 + Plan 02 Task 3 and mechanical:
(1) merge the two `lint.md` routing rows into one (NEW-C); (2) prefix every inserted
routing-row example in Plans 02 and 03 with `> ` (NEW-D). Doing both makes Plan 03's
`-eq 1` loop satisfiable for all files (closes the carried NEW-A). Secondary: copy the
routing-reference definition paragraph verbatim into both plans (MEDIUM byte-identity) and
optionally scope the row grep to the routing-table block (LOW).
