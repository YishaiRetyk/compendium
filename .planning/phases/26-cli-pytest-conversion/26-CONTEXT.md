# Phase 26 Context — Wholesale CLI→Pytest Conversion (CUT-02) + post-migration fixes

**Decomposed:** 2026-07-03 (baked in for turnkey execution — a fresh session prompted
"kick off phase 26" executes 26-01 → 26-04 to v1.5 milestone completion).
**Requirement:** CUT-02 (terminal, deferrable). **Milestone:** v1.5 Python Migration —
Phase 26 is the LAST phase; finishing it ships v1.5.
**Upstream:** `.planning/milestones/v1.5-MILESTONE-BRIEF.md` §Phase 26 (3 success
criteria); `.planning/phases/25-parallel-migration-cutover/25-REVIEW.md` (the deferred
ledger this phase draws its behavior fixes from).

## Preconditions (verify at kickoff)

- Phase 25 COMPLETE: all 16 tools run Python behind `.sh` exec-shims; 8/8 reqs Complete;
  certified baseline `phase-24-freeze = bb5ba7f`; `pytest` 149 green; parity 238 pairs.
- `git status` may show the user's concurrent ingest work (agent-skills / Matt Pocock).
  **Do NOT touch it.** Stage only this phase's own paths, explicitly, by pathspec.
- Today's date is derived from the machine clock at execution time (`date -u`), NOT
  hardcoded — Phase 25 shipped a mislabel by assuming; do not repeat it.

## The strategy, and WHY this order

CUT-02 converts the black-box bash suite onto pytest, retires the bash runner, and gives
a single parallel `pytest` entrypoint. Doing that **also dismantles the frozen-bash
parity oracle** — which is exactly what unblocks the post-migration behavior fixes the
parity bar deferred (chief among them the pre-commit lint-clobber the user hit all
through Phase 25). So the sequence is deliberate:

1. **26-01 — pytest bridge (single entrypoint).** No behavior change → cannot collide
   with anything. Delivers success criteria #2 (single parallel entrypoint).
2. **26-02 — retire the parity apparatus.** Removes the frozen-bash oracle, the
   `WIKI_IMPL` seam's bash leg, `--require-parity`, `check-staged-parity` +
   `check-common-freeze` from the hook, `run-all-suites.sh`, the freeze machinery. THIS
   is what frees behavior fixes.
3. **26-03 — the post-migration fixes, now collision-free.** The lint/audit
   read-only-check fix (kills the clobber) + the cheap 25-REVIEW faithful-bash items.
4. **26-04 — milestone close.** CUT-02 verification, adversarial review, v1.5 → SHIPPED.

The lint fix is parity-INVISIBLE in practice (the report/log write is date-bearing and
`normalize.sh` deliberately never redacts dates, yet parity passes → the write is not a
captured surface). So 26-03 would likely pass the gate even before 26-02. But sequencing
it after the oracle retirement makes it collision-proof by construction — no D-09
ceremony, no golden re-freeze. Keep this order.

## DECISION — bridge, not wholesale idiomatic rewrite (D-26-01)

The bash black-box suites ARE the behavioral spec (hundreds of files, thousands of
assertions). 26-01 makes them **pytest-collectable and parallel** — a `conftest.py`
collector parametrizes over the bash test files and runs each against the REAL Python
`bin/` in a worker, asserting the pinned pass/FAIL state (the 10 known-FAILs from
`SUITE_MANIFEST.txt` stay xfail). The bash *runner* (`run-all-suites.sh`) is retired; the
bash test *files* remain as pytest-driven specs. This satisfies CUT-02's three success
criteria (behavioral assertions reproduced — they ARE the assertions; single parallel
`pytest`; CI green) while keeping the risk bounded.

**Escalation (optional, explicitly deferred):** a full file-by-file rewrite of each bash
assertion into idiomatic Python is the gold-plated end state. It is NOT required for
CUT-02 and NOT baked into these plans. If the user wants it, it becomes a follow-on
milestone (v1.6 test-hygiene) — a fresh session should NOT undertake it under "kick off
phase 26" unless the user explicitly asks. The bridge is the sanctioned CUT-02 delivery.

## The lint-clobber fix spec (26-03) — exact, since it's the user's headline concern

`src/compendium/lint.py` ~L2696–2706 writes `wiki-cloud/maintenance/lint-report.md` AND
appends a `## [date] lint | wiki-cloud health check` entry to `wiki-cloud/log.md`
whenever the run is not `--dry-run` and not `--format json`. The pre-commit hook runs
`bin/lint.sh --strict --staged --category provenance` (non-dry-run, text) → it hits this
block → mutates the wiki on **every commit**. A read-only validation check must not
write. **Fix:** gate the report+log write block additionally on `not STAGED_MODE and not
CI_MODE` (both are non-interactive validation modes; only a plain interactive
`bin/lint.sh` maintenance run should write the report/log). Mirror the same guard in
`audit_claims.py` if it has an analogous checkpoint-write on a validation path. Add a
pytest that asserts `lint --staged` and `lint --ci` leave `log.md` + `lint-report.md`
byte-unchanged, and that a plain `lint` run DOES write them (the write path stays alive).
Retire the `2026-07-03-hook-lint-clobbers-wiki-report` todo. This is a deliberate,
now-sanctioned behavior change (the migration parity bar that forbade it has been
retired in 26-02).

## Milestone-close checklist (26-04)

- CUT-02 → Complete in REQUIREMENTS.md (18/18 v1.5 reqs Complete).
- 26-VERIFICATION.md (3 success criteria evidenced) + xhigh adversarial review
  (26-REVIEW.md) at the same discipline as Phases 24/25.
- v1.5 milestone marked SHIPPED: ROADMAP milestone line (🚧→✅ with date), MILESTONES.md,
  a v1.5 milestone-audit/retrospective note.
- STATE.md → milestone complete; ROADMAP Phase 26 ticked.
- The commit-time wiki-clobber dance is GONE (26-03) — commits touching wiki no longer
  need the `git checkout -- wiki-cloud/log.md` strip.
- Update memory: retire/settle the parity-gate + clobber memories (both are resolved by
  this phase); note v1.5 shipped.

## Standing constraints (unchanged from the whole milestone)

- `origin` is the public template — NEVER push local `main`/tags; `phase-24-freeze` is
  local-only (and is DELETED in 26-02, not pushed).
- Template-public files use abstract placeholders, never real vault terms.
- One commit per logical operation; conventional-commit prefixes.
- Do not read `wiki-local/` from a cloud session; sources immutable after ingestion.
