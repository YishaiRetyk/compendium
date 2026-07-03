---
phase: 26-cli-pytest-conversion
plan: 02
type: execute
wave: 1
depends_on: [01]
requirements: [CUT-02]
files_modified:
  - .githooks/pre-commit (drop parity + freeze gates; add pytest smoke)
  - tests/run-all-suites.sh (DELETE)
  - tests/lib/invoke_tool.sh (simplify to direct-run, or DELETE if the bridge is self-contained)
  - tests/lib/oracle-worktree.sh, normalize.sh, no-direct-bin-calls.sh (DELETE the oracle-specific ones)
  - tests/ported.manifest, tests/freeze-baseline.sha, tests/oracle-exempt.{md,txt} (DELETE)
  - bin/check-staged-parity.sh, bin/check-common-freeze.sh (DELETE)
  - .github/workflows/parity.yml (DELETE or convert to a `pytest -n auto` job)
  - src/compendium/*.py (drop the NOT_IMPLEMENTED stub sentinel comments if any remain)
autonomous: true
---

<objective>
Retire the frozen-bash parity oracle and its enforcement — the machinery whose only
purpose was catching py-vs-bash divergence DURING the migration. The migration is
certified done; going forward the pytest suite (26-01) is the regression net. Removing
this apparatus is what FREES post-migration behavior fixes (26-03).
</objective>

<context>
- What the apparatus is: the `WIKI_IMPL=bash|py` seam + git-worktree oracle at
  phase-24-freeze + `run-all-suites.sh --require-parity` + `check-staged-parity.sh` +
  `check-common-freeze.sh` + the freeze baseline/tag + `ported.manifest` +
  `oracle-exempt.*` + `parity.yml`. All of it exists to diff two implementations; there
  is now only one (Python).
- The pre-commit hook currently: sync-claude → gen-skills → check-common-freeze →
  check-staged-parity → lint --staged. Replace the two parity/freeze steps with a fast
  `pytest` smoke over the touched-tool suites (or drop entirely and rely on CI). KEEP
  sync-claude, gen-skills, lint --staged (they are real gates, not parity).
- The bash test files still call `invoke_tool`/`invoke_tool_compat`. Two options:
  (a) simplify tests/lib/invoke_tool.sh to a thin "run bin/<tool>.sh directly, capture
  exit" (no oracle, no WIKI_IMPL, no capture/parity), keeping the test files working; or
  (b) if 26-01's bridge runs test files without the seam, delete the seam. Pick (a) if
  the test files depend on invoke_tool semantics (they do — 228 sites). Preserve
  observable test behavior; the pinned SUITE_MANIFEST baseline must not move.
- FROZEN surface no longer exists after this plan — that concept was migration-scoped.
- The `phase-24-freeze` tag is LOCAL-ONLY: `git tag -d phase-24-freeze`. Never pushed,
  nothing to clean remotely.
- PKG-04 required CI checks (lint, privacy-leak, strict, skills-check, neutrality,
  setup-parity) must stay green with unchanged names. Only the ADDED parity jobs go away.
</context>

<tasks>
1. Rewrite `.githooks/pre-commit`: remove the check-common-freeze + check-staged-parity
   steps; keep sync-claude/gen-skills/lint --staged; optionally add a scoped `pytest -n
   auto -k <touched>` smoke. Update the phase-18 hook-ordering test to the new shape.
2. Delete the oracle machinery (files above). Simplify or delete tests/lib/invoke_tool.sh
   per the note. Update/delete the suite-24 parity self-tests that now test nothing.
   Update tests/impl-assertion-inventory.md guard (the inventory concept is migration-
   scoped — retire the guard or convert it to a doc).
3. Delete parity.yml (or convert its jobs to a single `pytest -n auto` CI job with a NEW
   name — do NOT touch the 6 required-check names).
4. `git tag -d phase-24-freeze`. Remove freeze-baseline.sha + ported.manifest.
5. Run `pytest -n auto` green (manifest baseline holds); run the 6 required-check scripts
   locally green. Make a trivial commit and confirm the new (lighter) hook passes fast.
6. Commit `refactor(26): retire the frozen-bash parity oracle + freeze machinery
   (post-migration; single impl remains)`. Multiple logical deletions that are ONE
   operation ("dismantle the migration scaffolding"). SUMMARY records exactly what was
   removed and the new hook/CI shape.
</tasks>

<acceptance>
- No `WIKI_IMPL`, worktree oracle, `--require-parity`, check-staged-parity,
  check-common-freeze, run-all-suites, ported.manifest, freeze-baseline, or
  phase-24-freeze tag remains. `pytest -n auto` is the whole net and is green.
- pre-commit hook is sync-claude/gen-skills/lint(+optional pytest smoke); a bin/src
  commit no longer runs a ~50-min gate.
- The 6 required CI checks keep their names and pass; the added parity jobs are gone.
</acceptance>
