# Phase 26 Review — xhigh adversarial review

**Reviewed:** 2026-07-03 by an independent subagent (fresh context) over the full Phase-26
diff (`f62bec5..HEAD` — 74aff85 / a8df146 / cf1d6fa), review-only, ~23 min, 60+ probing runs.
**Verdict:** **Safe to ship Phase 26 as v1.5.** The three deliverables (pytest bridge, oracle
retirement, lint clobber fix) are correct, non-vacuous, and parallel-stable.

## Findings & disposition

### F1 — phase-08 wizard test corrupts the LIVE repo + self-fails — CONFIRMED, HIGH-as-bug / **FIXED (follow-up, at user request — commit after this close)**

`tests/phase-08/test_wizard_partial_failure.sh` builds a scaffold that copies in
`bin/init-wizard.sh` but NOT `src/compendium/`, so the shim's `PYTHONPATH=$WORK/src` is empty
and `python3 -m compendium.init_wizard` silently imports the **LIVE** module, which resolves
`REPO_ROOT` from its own `__file__` to the real repo — ignoring the scaffold's malformed
`index.md`, reading the live one, and completing a **real promote into the live tree**
(rewrites `AGENTS.md`/`CLAUDE.md`/`wiki-cloud/index.md`, creates `.wizard-answers.yaml` +
`wiki-cloud/decisions/dr-2026-04-16-initial-setup.md`). The test then self-fails (exit 0 ≠
expected non-zero). This is the same pollution I cleaned up during 26-04 verification
(the `setup-parity` local run).

**Why not fixed here:** it is PRE-EXISTING (introduced by the Phase-25 migration, not in the
Phase-26 diff), phase-08 is deliberately NOT in the bridge's `SUITES` so `pytest` never runs
it, and its CI runner `setup-parity.yml` is untouched by Phase 26. Bundling a phase-08 fix
into the milestone-close commit would violate one-commit-per-logical-operation.

**Resolution (fixed at user request, separate `fix(tests)` commit):** the two real-run
scaffold tests now copy `src/compendium/__init__.py` + `init_wizard.py` (+ a `wiki-cloud/index.md`
seed) into `$WORK/src`, so the shim resolves the SCAFFOLD module → `REPO_ROOT=$WORK` and the
malformed-index guard fires against the fixture, not the live tree. This also fixed a hidden
cascade: `test_wizard_partial_failure`'s corruption had been leaving `.wizard-answers.yaml` in
the live repo, which is the only reason `test_wizard_idempotent` (same scaffold bug) and the
`--render-to` tests appeared to pass — with the corruption gone, `idempotent` was fixed the same
way, and a separately-stale `test_wizard_sync_claude` grep (pointed at the thin shim instead of
the ported module) was repointed at `init_wizard.py`. **phase-08 is now 21/21 green with zero
live-tree mutation** (verified). The other pre-existing phase-08/07 nits (non-hermetic-by-design
+ the content-neutralization assertions that flag the user's live wiki vs the template) remain a
v1.6 test-hygiene item.

### F2 — dead `_NORM_EXEC_ROOTS` normalization path — CONFIRMED, LOW / **RETAINED (defensive)**

`tests/lib/normalize.sh:28-35` still consumes `_NORM_EXEC_ROOTS`, which the simplified seam no
longer sets (the oracle-worktree/staged-index/repo path-unification it served is gone with the
oracle). Not a live defect — all 132 committed goldens pass unchanged (a single-impl run emits
no oracle-worktree paths; per-test tmp paths are normalized by an always-on rule). Retained
rather than removed: it is harmless and defensive — if a future golden captures a tool that
echoes an absolute exec-root path, re-activating it is a one-line seam change. No edit.

### F3 — stale `SUITE_MANIFEST.txt` header comments — CONFIRMED, LOW-MEDIUM (doc) / **FIXED**

The header described `run-all-suites.sh` semantics ("fails ONLY on a NEW failing test…") and
"Measured under `WIKI_IMPL=bash`" as if current — both retired. Rewritten to describe the
bridge's actual (stricter) contract: exact per-row PASS / `xfail(strict=True)`, so a FAIL row
that starts passing fails as an XPASS.

### F4 — pre-commit smoke dep-probe incomplete — CONFIRMED, LOW / **FIXED**

`.githooks/pre-commit` probed `import pytest` but not `xdist`; since `addopts` pins `-n auto`,
a contributor with pytest but without pytest-xdist would get "unrecognized arguments: -n" and a
misleading "smoke failed — fix the regression" message. Probe changed to `import pytest, xdist`
so the smoke skips gracefully when the parallel plugin is absent (a missing dep, not a regression).

### F5 — bridge forces `PDF_EXTRACT_SKIP_LIVE=1` — INFORMATIONAL / no action

phase-20's live render→OCR→marker assertions don't run under `pytest` (same as the retired
runner). The static + local-stub behavioral assertions DO run ("OK: local-stub behavior
assertion" fires) — not vacuous-green, no regression.

## Areas the reviewer verified correct (no defect)

- **Lint clobber fix (26-03):** `write_report = not dry_run and not STAGED_MODE and not CI_MODE`
  gates BOTH the report write and the `log.md` append; `report_msg` in scope; `STAGED_MODE`/
  `CI_MODE` never undefined; no over-suppression (interactive `lint`/`--fix` still write);
  `--ci`/`--format json` behavior preserved. Correctly ends the clobber.
- **Manifest→xfail mapping:** only FAIL→xfail-strict; PASS must exit 0; 205↔205 bijection both ways.
- **SERIAL_SUITES (12.2/18/24):** empirically sufficient — 60+ clean parallel runs, tree clean.
- **Oracle-retirement teardown:** no surviving RUNTIME reference to any deleted file/function.
- **CI contract:** all 6 required checks still protected; `tests.yml` valid, installs `.[dev]`,
  runs pytest; the new `tests` job is not one of the 6, so branch protection is undisturbed.
- **phase-24 goldens:** loud-fail on missing golden; 132 byte-asserted; `git archive HEAD`
  correct; 4-channel capture semantics preserved; `shim_preflight_exit3` case (c) non-vacuous.
- **Hook order:** sync-claude → gen-skills → lint `--staged` → scoped smoke; only freeze/parity dropped.

## Fixes applied in this plan

F3 (`SUITE_MANIFEST.txt` header) + F4 (`.githooks/pre-commit` dep-probe). Re-verified:
`pytest -n auto` = 348 passed, 10 xfailed. F1 ledgered (out-of-scope, flagged for a v1.6
test-hygiene follow-on); F2 retained defensively; F5 informational.
