---
gsd_state_version: 1.0
milestone: v1.5
milestone_name: Python Migration
status: In progress
stopped_at: Phase 25 COMPLETE (7/7 plans, 8/8 requirements) + xhigh review applied; Phase 26 (CUT-02, terminal/deferrable) is all that remains
last_updated: 2026-07-03T18:00:00.000Z
last_activity: 2026-07-03 — Phase 25 shipped: all 16 tools on Python behind shims; 15-finding review applied (headline: greenfield ruamel-block fixed); baseline re-pinned at bb5ba7f
progress:
  total_phases: 3
  completed_phases: 2
  total_plans: 13
  completed_plans: 13
  percent: 94
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-07-03)

**Core value:** The wiki is a persistent, compounding artifact -- cross-references are already there, contradictions already flagged, synthesis already reflects everything ingested.
**Current focus:** **v1.5 Python Migration** (Phases 24–26) — started 2026-07-03. Re-platform `bin/` from Bash to Python behind `.sh` exec-shims: package skeleton + frozen `common/` + `WIKI_IMPL=bash|py` parity oracle first (Phase 24, the one hard serialization point), then parallel cluster ports + cutover (Phase 25), then the deferrable CLI→pytest conversion (Phase 26). Behavior parity is the acceptance bar throughout.

## Current Position

Phase: 25 — COMPLETE (2026-07-03). Next: Phase 26 — Wholesale CLI→Pytest Conversion (DECOMPOSED + baked in for turnkey kickoff; the LAST v1.5 phase)
Plan: all 7 Phase-25 plans complete (25-01…25-07; SUMMARYs) + 25-VERIFICATION.md (8/8 reqs) + 25-REVIEW.md (15-finding xhigh review). All 16 tools run Python behind `.sh` exec-shims; migrate-privacy-dirs retired; migration DR authored (dr-2026-07-03-python-migration).

>>> KICKOFF: "kick off phase 26" → read `.planning/phases/26-cli-pytest-conversion/26-CONTEXT.md` (strategy + the exact lint-clobber-fix spec + the bridge decision D-26-01 + milestone-close checklist), then execute 26-01 → 26-02 → 26-03 → 26-04 in order to v1.5 milestone completion. Order is load-bearing: 26-02 retires the parity oracle, which is what frees the lint-clobber fix in 26-03 (collision-proof). Bridge, not wholesale rewrite (D-26-01). Preserve the user's concurrent ingest work — stage only phase-26 paths by pathspec.
Status: Certified post-migration baseline pinned at phase-24-freeze = bb5ba7f. Full three-leg parity green (238 pairs byte-identical); pytest 149 green; freeze guard clean. 5 D-09 rebases over the phase (3 harness gaps at first live channel comparison + review C1/D6), each re-pinned. Known deferred: search/validate/audit faithful-bash divergences, the hook lint-clobber bug (todo), and the cleanup/altitude/efficiency ledger in 25-REVIEW.md.
Last activity: 2026-07-03

### v1.5 Phase Map

| Phase | Name | Requirements | Status |
|-------|------|--------------|--------|
| 24 | Foundation: Skeleton + Frozen Core + Parity Oracle | PKG-01..04, TEST-01..05 (9 reqs) | ✓ Complete (2026-07-03) |
| 25 | Parallel Migration + Cutover | MIG-01..06, CUT-01, TEST-06 (8 reqs) | ✓ Complete (2026-07-03) |
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
