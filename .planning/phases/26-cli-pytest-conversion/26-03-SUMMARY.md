# 26-03 SUMMARY — lint --staged/--ci are read-only; the pre-commit clobber ends

**Status:** Complete (2026-07-03)

## The fix (the user's headline concern)

`src/compendium/lint.py` unconditionally rewrote `wiki-cloud/maintenance/lint-report.md`
and appended a `## [date] lint | wiki-cloud health check` entry to `wiki-cloud/log.md` on
every non-`--dry-run`, non-JSON run — INCLUDING the pre-commit hook's
`lint --strict --staged`. So every commit clobbered the wiki-health report (overwriting the
real findings with a 0-finding staged-scope report) and spammed the log (25-REVIEW F15 /
the `2026-07-03-hook-lint-clobbers-wiki-report` todo).

The report+log write block is now gated on a `write_report` flag:

```python
write_report = not dry_run and not STAGED_MODE and not CI_MODE
if write_report:
    ...  # write lint-report.md + append to log.md
```

A non-interactive VALIDATION run — the pre-commit `--staged` write-gate and the `--ci` CI
gate — is read-only; only a plain interactive maintenance `lint` writes. (`--format json`
already skipped the report; this closes the text-mode `--staged`/`--ci` path.) The summary
line's `report_msg` follows the same flag so it no longer claims a report was written on a
read-only run. This is a sanctioned behavior change — the migration parity bar that forbade
it was retired in 26-02 — and the correct design regardless of parity.

## audit_claims.py — checked, no analogous fix needed

The spec asked to mirror the guard IF audit has an analogous checkpoint-write on a
validation path. It does not: `audit-claims` is never run by the pre-commit hook or any CI
workflow, has no `--staged`/`--ci`/`--dry-run`, and deliberately advances its rotating
checkpoint (`audit-state.md`) + writes `audit-report.md` on EVERY run "so the run is
auditable" (all three modes — worklist, `--format json`, default — write). Those are the
intended output of an on-demand audit, not a per-commit clobber. Left unchanged (the
audit's behavior-nuanced items are explicitly deferred by the CONTEXT).

## Tests

`tests/test_lint_readonly_modes.py` (3 cases) pins BOTH directions against `bin/lint.sh`
over a git-staged fixture wiki:
- plain `lint wiki-cloud/` — report + log ARE (re)written (the maintenance path stays alive);
- `lint --ci wiki-cloud/` — both files byte-UNCHANGED;
- `lint --strict --staged --category provenance` — both files byte-UNCHANGED.

## Acceptance proof

This plan's own commit touches `src/compendium/lint.py`, so the pre-commit hook ran
`lint --strict --staged` with the fix in place. After the commit, `git status` showed NO
change to `wiki-cloud/log.md` or `wiki-cloud/maintenance/lint-report.md` — the clobber is
gone and the `git checkout -- wiki-cloud/...` strip dance is retired (contrast 26-01/26-02,
which each needed the strip). Full `pytest -n auto`: 348 passed, 10 xfailed.

## Deferred (per CONTEXT — do NOT over-reach)

The optional cheap 25-REVIEW faithful-bash items were NOT bundled here:
- `open(..., encoding='utf-8')` at the validate_op / check_privacy read sites (C-locale
  crash guard) — low-risk but speculative without a triggering test;
- the release.py SIGTERM staging-cleanup handler — behavior-nuanced signal work.
Both, plus the search byte-vs-char and audit except→None items, are left to a dedicated
behavior pass (a v1.6 test-hygiene / behavior-fix follow-on).

## Memory

The `precommit-appends-lint-log-entry` operational memory is now RESOLVED by this fix
(settled in 26-04's memory pass alongside the parity-gate memory).
