# Phase 25 Context — Parallel Migration + Cutover

**Decomposed:** 2026-07-03 (plan-phase, executed manually per the standing no-gsd-tooling directive).
**Requirements:** MIG-01..06, CUT-01, TEST-06 (see `.planning/REQUIREMENTS.md`).
**Authoritative upstream:** `.planning/milestones/v1.5-MILESTONE-BRIEF.md` §Phase 25;
`.planning/phases/24-.../24-REBASELINE.md` (RB-1..RB-7) for every concrete count;
`docs/reference/python-shim-contract.md` (LOCKED — the shim target form + seam semantics);
`tests/impl-assertion-inventory.md` (MANDATORY consult before each port).

## Plan structure (7 plans, 2 waves)

| Plan | Cluster | Tools | Req | Bash lines |
|------|---------|-------|-----|------------|
| 25-01 | brownfield (architectural template) | brownfield | MIG-01 | 2,259 (+8 heredocs) |
| 25-02 | checkers | check-neutrality, check-privacy, check-sources-cloud-safe | MIG-03 | 694 |
| 25-03 | setup/release (non-wizard) | gen-skills, release, sync-claude | MIG-04 (partial) | 442 |
| 25-04 | wiki-ops + retirements | ingest, validate-op, search, requirements-sync, pdf-extract, repo-snapshot | MIG-05, MIG-06 | 1,902 |
| 25-05 | init-wizard (riskiest port) | init-wizard | MIG-04 (rest) | 1,144 (+9 heredocs) |
| 25-06 | lint + audit-claims (long pole) | lint, audit-claims | MIG-02 | 4,270 (+9 heredocs) |
| 25-07 | cutover fan-in (wave 2) | — | CUT-01 | — |

TEST-06 spans plans 01–06: each plan lands `tests/test_<cluster>_unit.py` pytest unit
coverage for its module's pure functions (grown per cluster, per the brief).

**Execution-order rationale (deliberate deviation, recorded):** the brief designed Wave 1
for concurrent GSD agents in isolated worktrees; this milestone is executed by a single
agent sequentially, so worktree isolation buys nothing and plans run in numbered order on
`main` — one commit per plan. Order: brownfield first (MIG-01 is the named architectural
template), then ascending-risk (checkers → pure-bash setup trio → wiki-ops → init-wizard →
lint+audit) so the two hardest ports inherit maximal porting experience. In parallel-land
the long pole goes first; in sequential-land total time is the sum and order optimizes for
learning, not critical path.

## The port recipe (shared by plans 01–06)

1. **Baseline:** run the cluster's phase suites at HEAD on both legs (`WIKI_IMPL=bash`,
   `WIKI_IMPL=py` — py falls through while unported) and confirm they match
   `tests/SUITE_MANIFEST.txt`. Consult `tests/impl-assertion-inventory.md` for the
   cluster's rows; do the mandated rewrites IN THIS PLAN (details per plan doc).
2. **Port:** fill `src/compendium/<tool>.py` (replacing the `NOT_IMPLEMENTED_EXIT=70`
   stub body; keep `main(argv=None)` + the `__main__` block). Extract heredoc Python
   verbatim where possible; translate bash orchestration. Import from `compendium.common`
   (READ-ONLY — frozen). External boundaries (git, poppler, Ollama HTTP, curl) stay
   subprocess/HTTP calls (LIBSWAP is out of scope).
3. **Unit layer (TEST-06):** add `tests/test_<cluster>_unit.py` covering the module's
   pure functions via the Phase-24 pytest harness (`tests/conftest.py` fixtures).
4. **Flip:** rewrite `bin/<tool>.sh` to the canonical shim (contract §1 — PYTHONPATH
   self-bootstrap + `exec python3 -m compendium.<tool_module>`); append the tool name to
   `tests/ported.manifest` (the sanctioned controlled mutation; one bare name per line).
5. **Parity (the acceptance bar):** full enumerated run on both legs + channel compare:
   ```
   WIKI_IMPL=bash bash tests/run-all-suites.sh --capture-channels /tmp/B
   WIKI_IMPL=py   bash tests/run-all-suites.sh --capture-channels /tmp/P
   bash tests/run-all-suites.sh --require-parity /tmp/B /tmp/P
   ```
   All three exit 0. Per-test results match SUITE_MANIFEST.txt on both legs (the 10
   pinned FAILs stay FAIL — no-regression means MATCH, not all-green). NEVER set
   GOLDEN_FREEZE during a port.
6. **Commit:** one commit per plan — `feat(25): port <cluster> to python (MIG-0x)`.
   The pre-commit gate re-runs the three legs against the STAGED index (~20+ min once
   the manifest is non-empty) — run commits in the background with a long timeout.
   After each commit: `git checkout -- wiki-cloud/log.md wiki-cloud/maintenance/` (the
   hook lint step clobbers them — filed todo 2026-07-03-hook-lint-clobbers-wiki-report).
7. **SUMMARY:** write `25-0N-SUMMARY.md` (deviations, escape-hatch use per N-7, unit-test
   inventory).

## Standing landmines (all plans)

- **Byte-parity includes stderr.** The 4-channel compare covers stdout, stderr, exit code,
  and file tree for EVERY routed invocation in EVERY suite. Python ports must reproduce
  diagnostic text, ordering, and trailing newlines exactly as the frozen bash oracle
  (worktree at `phase-24-freeze` = 9905bf0) emits them.
- **Frozen surface is read-only:** `src/compendium/common/`, `pyproject.toml`,
  `tests/lib/`, `tests/run-all-suites.sh`, `tests/SUITE_MANIFEST.txt`, `tests/conftest.py`,
  `tests/goldens/`, manifest format. A `common/` gap mid-port → D-09 ownership-rebase
  (FREEZE_ALLOW_REBASE commit + baseline re-pin follow-up commit, recorded in SUMMARY).
- **Bugs are ported faithfully.** Known: `search.sh` keyword/query modes broken on piped
  indexes since Phase 14 (goldens pin the broken behavior). The Python port reproduces it;
  the fix is the post-migration todo. Same principle for any oddity a port uncovers:
  freeze first, file a todo, never fix mid-parity.
- **Stubs exit 70.** A tool listed in `ported.manifest` whose module still returns
  NOT_IMPLEMENTED_EXIT fails loudly on the py leg — append to the manifest only in the
  same change that fills the module.
- **Module names use underscores** (`compendium.audit_claims` for `audit-claims.sh`);
  the shim's `-m` target must match the Phase-24 stub name exactly (console_scripts in
  the frozen pyproject.toml already pin them).
- **Oracle-exempt tests** (`tests/oracle-exempt.md`): the gen-skills quartet (+ other
  `$0`-relative live-repo tests) call tools DIRECTLY — after a flip they exercise the py
  impl through the shim with no bash pairing; they must simply PASS.
- **Hook hot path goes live progressively:** once plan 25-03 flips sync-claude/gen-skills
  and 25-06 flips lint, every local commit's pre-commit chain runs the Python ports for
  real. A bricked hook = `git checkout <baseline> -- bin/<tool>.sh` to restore, fix, retry.
- Python: brew 3.14.5 (`python3` on PATH), PyYAML 6.0.3, ruamel.yaml 0.19.1 (RB-2).
