---
gsd_state_version: 1.0
milestone: v1.5
milestone_name: Python Migration
status: Complete
stopped_at: v1.5 Python Migration SHIPPED (2026-07-03) — Phases 24–26 complete, 18/18 requirements Complete; single `pytest -n auto` entrypoint, parity oracle retired, pre-commit clobber killed
last_updated: 2026-07-03T21:00:00.000Z
last_activity: 2026-07-03 — Phase 26 closed + v1.5 shipped: pytest bridge (CUT-02), frozen-bash oracle retired (22 files deleted), lint --staged/--ci made read-only (clobber gone), xhigh review applied (26-REVIEW.md)
progress:
  total_phases: 3
  completed_phases: 3
  total_plans: 17
  completed_plans: 17
  percent: 100
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-07-03)

**Core value:** The wiki is a persistent, compounding artifact -- cross-references are already there, contradictions already flagged, synthesis already reflects everything ingested.
**Current focus:** **v1.5 Python Migration SHIPPED (2026-07-03).** `bin/` re-platformed Bash→Python behind `.sh` exec-shims; single parallel `pytest` entrypoint; migration-only parity apparatus retired. No active milestone — next work is the deferred backlog (see below).

## Current Position

Phase: 26 — COMPLETE (2026-07-03). **v1.5 milestone SHIPPED.** No active phase.
Plan: all 4 Phase-26 plans complete (26-01…26-04; SUMMARYs) + 26-VERIFICATION.md (CUT-02, 3 criteria) + 26-REVIEW.md (xhigh adversarial review). `pytest -n auto` = 348 passed / 10 xfailed; `requirements-sync --strict --require-complete` = 18/18 Complete, exit 0.
Status: v1.5 complete. The frozen-bash parity oracle, `run-all-suites.sh`, `check-staged-parity`/`check-common-freeze`, `ported.manifest`, `freeze-baseline`, and the `phase-24-freeze` tag are all retired; the pre-commit hook is light (sync-claude/gen-skills/lint + a scoped unit-test smoke; ~5s on code commits vs the retired ~50-min gate); `lint --staged`/`--ci` are read-only (the wiki-clobber dance is gone). `.github/workflows/tests.yml` (a `pytest` job) replaced `parity.yml`; the 6 required checks keep their names.
Last activity: 2026-07-03

### v1.5 Phase Map

| Phase | Name | Requirements | Status |
|-------|------|--------------|--------|
| 24 | Foundation: Skeleton + Frozen Core + Parity Oracle | PKG-01..04, TEST-01..05 (9 reqs) | ✓ Complete (2026-07-03) |
| 25 | Parallel Migration + Cutover | MIG-01..06, CUT-01, TEST-06 (8 reqs) | ✓ Complete (2026-07-03) |
| 26 | Wholesale CLI→Pytest Conversion | CUT-02 (1 req) | ✓ Complete (2026-07-03) |

**Total:** 18 requirements across 3 phases — 18/18 Complete.

## Next Work (deferred backlog — no active milestone)

| Category | Item | Where |
|----------|------|-------|
| v1.5-future | SHIMOUT (shim retirement — call Python entry points directly), LIBSWAP (native-lib re-platforming) | REQUIREMENTS.md Future Requirements |
| v1.6-candidate | Full file-by-file idiomatic rewrite of the bash suites into Python (beyond the sanctioned bridge, D-26-01); the cheap 25-REVIEW faithful-bash items (validate_op/check_privacy `encoding=`, release.py SIGTERM, search byte-vs-char, audit except→None) | 26-03/26-VERIFICATION deferred notes |
| tech-debt | phase-08 setup-parity test is non-hermetic (writes into the live repo on a local run) | 26-VERIFICATION.md |
| backlog | 999.3 (template placeholder system + Phase D `WIZ`), 999.6 (observed GTD review patterns) | `.planning/ROADMAP.md` Backlog |
| v1.2-deferred | Obsidian plugin distribution; one-command installer; hosted docs site; brownfield `--apply` mode | Carried forward per PROJECT.md |
| tech-debt (pre-existing) | 3 unsummarized Kahneman raw sources (DRFT-01); brownfield WR-*/IN-* nits; Phase 11 human-UAT visual items; stale prior-phase tests (the 10 pinned SUITE_MANIFEST xfails) | Non-blocking |
