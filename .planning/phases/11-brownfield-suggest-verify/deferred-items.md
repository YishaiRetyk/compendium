# Phase 11 Deferred Items

Issues discovered during Phase 11 execution that are out of scope for Plan 11-05.

## Pre-existing Phase 10 Test Failures (not caused by Plan 11-05)

The following `tests/phase-10/` tests fail in the main working tree due to a
shared `ruamel.yaml` environment / bootstrap-path regression that predates
Plan 11-05:

```
test_brownfield_bootstrap_applied_manifest.sh
test_brownfield_bootstrap_apply_clean.sh
test_brownfield_bootstrap_apply_comments.sh
test_brownfield_bootstrap_apply_crlf.sh
test_brownfield_bootstrap_apply_dataview.sh
test_brownfield_bootstrap_apply_no_fm.sh
test_brownfield_bootstrap_dryrun.sh
test_brownfield_bootstrap_idempotent.sh
test_brownfield_bootstrap_skip_dupkeys.sh
test_brownfield_bootstrap_skip_tabs.sh
test_brownfield_bootstrap_typed_merge.sh
```

Verified via `git stash` + fresh run on the pre-edit tree — all 11 failures are
identical pre- and post-edit. Representative error:

```
ERROR: ruamel.yaml is required for brownfield bootstrap. Install: pip install ruamel.yaml
```

This is a pre-existing tooling/environment issue (ruamel.yaml not on
`PYTHONPATH` when `bin/brownfield.sh bootstrap` is invoked via the Phase-10
fixture harness) — scope boundary per AGENTS.md / SCOPE BOUNDARY in
executor deviation rules. Not in scope for Plan 11-05. A follow-up debt item
should be filed against Phase 10 regression.
