# Plan 24-06 Summary — Freeze guard + staged-parity gate + baseline pin (wave 5)

**Executed:** 2026-07-03. **Requirements:** PKG-04, TEST-02. **Status:** Complete.

## What shipped

- `bin/check-common-freeze.sh` — the D-07/D-08 guard: explicit frozen surface
  (`src/compendium/common/`, `pyproject.toml`, the four `tests/lib/` seam files,
  `tests/conftest.py`, `tests/goldens/`, `tests/SUITE_MANIFEST.txt`,
  `tests/run-all-suites.sh`; `tests/ported.manifest` + self-tests + inventory/exempt
  registries deliberately EXCLUDED with the L-2 escape-hatch note); baseline resolution
  `phase-24-freeze^{commit}` → `tests/freeze-baseline.sha` with the N-4 tag-vs-SHA
  equality FATAL; drift → exit 2; unreachable → SKIP exit 3 (never 0); stderr never
  swallowed; `--staged` mode; `FREEZE_ALLOW_REBASE` escape hatch (D-09/N-7).
- `tests/freeze-baseline.sha` = **`6a97e877d9d48b4def8021f1a8c88c7f35ae3c9a`** — the
  PRE-Plan-06 HEAD (end of wave 4 = the final frozen surface; non-circular: every
  Plan-06 file is outside the frozen paths, and the guard runs clean at post-Plan-06
  HEAD against it).
- `tests/phase-24/test_freeze_guard.sh` — 7 behaviors in an isolated scratch repo:
  clean=0, drift=2, escape-hatch=0, non-frozen=0, unreachable=3, tag-deref=0,
  tag-vs-SHA-mismatch=2 (N-4). Green.
- `bin/check-staged-parity.sh` — the LOCAL parity gate (HIGH#6): fast-skips
  non-migration commits; on staged `bin/`/`src/compendium/`/`ported.manifest` it
  materializes the STAGED INDEX (`git checkout-index`, no `.git`, trap cleanup) and runs
  both legs + `--require-parity` by CONSUMING the frozen seam knobs
  (`WIKI_EXEC_ROOT=$STAGED_EXEC_ROOT` for the py leg, `WIKI_ORACLE_GIT_ROOT=$ORACLE_GIT_ROOT`
  for the oracle git — cycle-6 #1/#2; the cycle-5 placeholder is gone); excludes ONLY the
  two recursive hook self-tests via `--exclude-test` (phase-24 stays in the run —
  cycle-6 #3); `WIKI_PARITY_GATE_ACTIVE` re-entrancy bound; `PARITY_GATE_SKIP` WIP hatch
  (N-7); correct `if cmd; then rc=0; else rc=$?; fi` captures (HIGH#2).
- `tests/phase-24/test_precommit_hooks.sh` — BEHAVIOR-level: exit-3 skip branch REACHED
  (commit allowed) on an unreachable baseline; staged frozen drift BLOCKS; the parity
  gate EXECUTES materialize+compare on a staged `src/compendium` change (non-vacuous —
  no re-entry/fast-skip branch taken); non-migration commits fast-skip. Green.
- `tests/phase-24/test_staged_parity_index.sh` — the keystone negative: STAGED-broken +
  WORKING-good is **BLOCKED** with a SEEDED manifest entry (the Python leg genuinely ran
  — cycle-4 #4); staged-good passes; `timeout 120` bounded-termination of the
  recursion-prone path (rc 0, not 124 — cycle-3 #5). Green.
- `.githooks/pre-commit` — freeze (staged mode, exit-3 skip live) + parity gate wired
  between gen-skills and lint --staged, both with the non-`!` capture idiom.
- `parity.yml` — `common-freeze` CI job (fetch-depth 0; exit-3 = logged neutral skip);
  no required-check name touched.
- **`phase-24-freeze` annotated tag created at `6a97e87…` (LOCAL-ONLY — never push to
  origin, the public template)**; `git rev-parse phase-24-freeze^{commit}` ==
  `tests/freeze-baseline.sha` (N-4). From here the worktree oracle checks out the FROZEN
  ref — `WIKI_IMPL=bash` keeps running this bash even after Phase 25 flips shims.

## Verification

Phase-24 suite 10/10 (incl. the three new self-tests); all plan acceptance greps pass
(incl. the negatives: no `if !` freeze capture, no stash mechanism, no whole-suite
exclusion, no cycle-5 placeholder); hook `bash -n` clean; parity.yml parses with the
required-name-leak check; guard clean at the pinned baseline post-tag.

## Escape-hatch use (N-7 ledger)

- `PARITY_GATE_SKIP`: **not used**. This plan's own commit (stages `bin/`) ran the full
  staged-parity gate live — the two-leg capture + channel byte-comparison served as the
  Phase-24 end-to-end parity-equivalence validation (green-by-fallthrough as designed).
- `FREEZE_ALLOW_REBASE`: not used.
