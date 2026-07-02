---
phase: 23-external-source-drift
verified: 2026-07-03T00:00:00Z
status: passed
score: 5/5
overrides_applied: 0
---

# Phase 23: External Source Drift Detection — Verification Report

**Phase Goal:** The wiki can tell when its URL-backed and repository sources have moved or died upstream — opt-in, review-only, with no new mandatory network dependency anywhere in the core workflows.
**Verified:** 2026-07-03 | **Status:** PASSED

## Success Criteria

1. **Opt-in + no-flag identity + CI skip (DRIFT-01)** — PASS. `--network` gates all network I/O behind `LINT_NETWORK=1` (structurally: the check block is a no-op without it). Live no-flag run: 0 network findings. Test T1 (no-flag zero findings) + T6 (`--ci --network` still default-skips `drift-external`) green. LINT_VERSION 1.12.0.
2. **Repository HEAD drift (DRIFT-02)** — PASS. `git ls-remote refs/heads/<default_branch>` vs `commit_sha`: T2 covers drifted→warning / current→silence / unreachable→warning against local `file://` fixture upstreams (real code path, network-free).
3. **URL reachability + registry link-rot (DRIFT-03)** — PASS. T3 (dead→warning, moved→info, fine→silence, via PATH-injected curl stub) + T5 (2/4 sampled registry URLs dead → warning with ratio). Deterministic first-10 sampling.
4. **Review-only + video exclusion + docs + DR (DRIFT-04)** — PASS. Severity ceiling warning; nothing mutates; `schema/workflows/lint.md` External Source Drift section carries families/thresholds/stance/follow-up guidance; videos excluded (T4: dead-url video source silent); DR `dr-2026-07-03-external-source-drift` records the surface-don't-mark narrowing vs the 999.5 sketch. The Phase-22 registry row's forward reference to lint.md external checks is now accurate.
5. **Real-run validation (DRIFT-05)** — PASS. `--dry-run --network --category drift` over the live wiki: repository source verified CURRENT (upstream `next` HEAD `69fef7c0` == snapshot commit — independently confirmed by direct ls-remote, a true negative not a vacuous pass); 2 benign `moved` infos (GitHub repo-rename redirect; doi.org by-design redirect); 0 dead URLs; 0 registry rot. Triage logged in `wiki-cloud/log.md`.

## Gates

- tests/phase-23: 1/1 suite (6 cases), network-free.
- tests/phase-22 3/3, tests/phase-13 31/33 (baseline-identical), tests/phase-09 25/31 (baseline-identical) + `test_lint_version.sh` green at 1.12.0.
- lint --dry-run 0 errors; sync-claude --check, check-neutrality, gen-skills --check green.

## Requirements Status

- DRIFT-01: Complete
- DRIFT-02: Complete
- DRIFT-03: Complete
- DRIFT-04: Complete
- DRIFT-05: Complete
