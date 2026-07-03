---
gsd_state_version: 1.0
milestone: v1.5
milestone_name: Python Migration
status: In progress
stopped_at: Phase 25 Wave 1 executing — 25-01 brownfield flipped (first live py parity leg); D-09 seam rebase landed (10afda6, re-pinned 83ca728)
last_updated: 2026-07-04T01:30:00.000Z
last_activity: 2026-07-04 — 25-01 complete; 6/6 cluster drafts done (parallel agents); harness gap found+fixed at first live channel comparison
progress:
  total_phases: 3
  completed_phases: 1
  total_plans: 13
  completed_plans: 6
  percent: 46
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-07-03)

**Core value:** The wiki is a persistent, compounding artifact -- cross-references are already there, contradictions already flagged, synthesis already reflects everything ingested.
**Current focus:** **v1.5 Python Migration** (Phases 24–26) — started 2026-07-03. Re-platform `bin/` from Bash to Python behind `.sh` exec-shims: package skeleton + frozen `common/` + `WIKI_IMPL=bash|py` parity oracle first (Phase 24, the one hard serialization point), then parallel cluster ports + cutover (Phase 25), then the deferrable CLI→pytest conversion (Phase 26). Behavior parity is the acceptance bar throughout.

## Current Position

Phase: 25 — Parallel Migration + Cutover (IN PROGRESS; decomposed 2026-07-03)
Plan: 7 plans in `.planning/phases/25-parallel-migration-cutover/` — Wave 1 sequential order: 25-01 brownfield (MIG-01, template) → 25-02 checkers (MIG-03) → 25-03 setup/release trio (MIG-04a) → 25-04 wiki-ops + retirements (MIG-05/06) → 25-05 init-wizard (MIG-04b) → 25-06 lint+audit (MIG-02, long pole); Wave 2: 25-07 cutover (CUT-01). TEST-06 grown per plan. Executed sequentially on main (single-agent; worktree isolation deliberately dropped — see 25-CONTEXT.md)
Status: The frozen foundation is live: 16-stub package, frozen common/ (6 modules), WIKI_IMPL seam + worktree oracle pinned at phase-24-freeze (= 9905bf0), 38 golden case dirs, 228 call sites seam-routed, per-test manifest (209 rows), CI matrix + local freeze/parity gates in the (now actually installed) pre-commit hook
Last activity: 2026-07-03

### v1.5 Phase Map

| Phase | Name | Requirements | Status |
|-------|------|--------------|--------|
| 24 | Foundation: Skeleton + Frozen Core + Parity Oracle | PKG-01..04, TEST-01..05 (9 reqs) | ✓ Complete (2026-07-03) |
| 25 | Parallel Migration + Cutover | MIG-01..06, CUT-01, TEST-06 (8 reqs) | Pending (plans TBD) |
| 26 | Wholesale CLI→Pytest Conversion | CUT-02 (1 req) | Pending (terminal, deferrable) |

**Total:** 18 requirements across 3 phases (REQUIREMENTS.md promoted from staged 2026-07-03).

## Deferred Items

Carried forward from the v1.4 close (2026-07-03):

| Category | Item | Status |
|----------|------|--------|
| v1.4-future | CCD (content-change detection beyond reachability); IPR (`#issue:`/`#pr:` locators) | Named in `milestones/v1.4-REQUIREMENTS.md` Future Requirements |
| noise-refinement | doi.org-style permanent-redirector skip-list for the `moved` info | Noted in `dr-2026-07-03-external-source-drift` Consequences |
| tech-debt | Cross-phase test-aggregator (run.sh) copy divergence + tests-lib duplication | Naturally superseded by v1.5's pytest conversion (CUT-02); see 22-REVIEW deferred items |
| backlog | 999.3 (template placeholder system + Phase D `WIZ`), 999.6 (observed GTD review patterns) | In `.planning/ROADMAP.md` Backlog |
| v1.2-deferred | Obsidian plugin distribution; one-command installer; hosted docs site; brownfield `--apply` mode | Carried forward per PROJECT.md |
| tech-debt (pre-existing) | 3 unsummarized Kahneman raw sources (DRFT-01); brownfield WR-*/IN-* nits; Phase 11 human-UAT visual items; stale §11.x prior-phase tests | Non-blocking; the stale-test class shrinks at v1.5 (pytest conversion) |
| v1.5-future | LIBSWAP (native-lib re-platforming), SHIMOUT (shim retirement) | Named in REQUIREMENTS.md Future Requirements |
