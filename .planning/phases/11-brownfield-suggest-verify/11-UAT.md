---
status: complete
phase: 11-brownfield-suggest-verify
source: [11-VERIFICATION.md]
started: 2026-04-20T13:00:00Z
updated: 2026-04-30T08:00:00Z
---

## Current Test

[testing complete]

## Tests

### 1. TTY small-batch review-typing interactive loop UX
expected: |
  CLR_DIM signals + CLR_BOLD header render. Single-letter primitives (a/r/i/o/s) work. Invalid override label rejected with `invalid label: '<x>'; must be one of [...]. Override discarded.` and re-prompts. Loop exits cleanly and writes valid decisions.yaml.
result: pass
notes: |
  Verified against ~/uat-small (small-vault-ambiguous fixture). 4 clusters; cluster_1 auto-approved; user inspected cluster_2, attempted invalid override `xyz` on cluster_3 (correctly rejected with canonical message and re-prompted), then approved all clusters. Final decisions.yaml resolved cluster_1=concept, cluster_2=entity, cluster_3=overview, cluster_4=concept. No invalid label persisted. Required `ruamel.yaml` to be installed via uv into Python user-site (pre-existing Phase 10 env gap documented in deferred-items.md).

### 2. Large-batch AI-handoff prompt usability
expected: |
  Run review-typing against a fixture with >=20 pending clusters OR with non-TTY stdout. `.brownfield/review-typing-prompt.md` is written with cluster signals + decision schema usable as a self-contained AI handoff prompt.
result: pass
notes: |
  Verified against ~/uat-large (large-vault-ambiguous, 25 pages, 8 pending clusters). Triggered via non-TTY stdout (stdin redirected from /dev/null). Generated prompt.md is 1727 bytes, points at both candidates.yaml (read-only) and decisions.yaml (edit target), lists the 6 legal labels, explains override structure, closes with the apply command, and includes the architectural boundary statement ("Review may be AI-guided; apply must always be deterministic"). Prompt is self-contained and pasteable.

### 3. verify --promote on a real bootstrapped vault
expected: |
  Run verify --promote on a bootstrapped vault. Only pages passing all 5 gates flip bootstrap_stage: bootstrapped → verified. Summary lists promoted + blocked counts with reasons. Pending-cluster pages are NOT promoted (gate 5 blocks them).
result: pass
notes: |
  Verified against ~/uat-small after Test 1 completed. After 01-page-typing.sh --apply, all 4 pages had type: set per resolved labels. verify (read-only) reported: 0 errors, 0 warnings, 0 stale artifacts. verify --promote flipped all 4 pages to bootstrap_stage: verified with per-page [promoted] lines + summary count. CAVEAT: this fixture had all-passing pages so the blocked counts/reasons path was not exercised manually — but test_verify_promote_5_gates.sh in the automated suite covers each gate's failure mode.

## Summary

total: 3
passed: 3
issues: 0
pending: 0
skipped: 0

## Gaps

[none — all 3 human-verification UX items confirmed]

## Environment Note

`bin/brownfield.sh` requires `ruamel.yaml` Python module at runtime. Not installed by default on Ubuntu 24.04 with Python 3.12.3. Installed via:

  uv pip install --target=$(python3 -c 'import site; print(site.USER_SITE)') ruamel.yaml

This is the same `ruamel.yaml` env gap documented in `deferred-items.md` (Phase 10 backlog). The Phase 11 code is correct; the missing dep is an environment/packaging concern that should be addressed by a follow-up phase (e.g., add an install-deps helper or a clearer error message pointing to the install command).
