# Oracle-Exempt / Parity-Exempt Registry (Phase 24 Plan 04 — REVIEWS cycle-3 finding #1)

> Code paths that CANNOT be verified through the held-fixed worktree oracle and are therefore
> **parity-exempt**: their committed goldens are documentation of the compat boundary, NOT
> bash-vs-py diffs. Plan 05's parity matrix (`run-all-suites.sh --require-parity`) MUST treat
> the paths listed here as exempt (it consumes the machine-readable companion
> `tests/oracle-exempt.txt`) — EXCEPT where a dedicated contract test enforces a compat
> boundary, which is named inline. Keep the two files consistent: this file is the human
> rationale, the `.txt` is the consumed form.

| Exempt path | WHY it is not parity-verifiable through the oracle |
|-------------|-----------------------------------------------------|
| `init-wizard` exit 4 (already-initialized, source :221) | REPO_ROOT is `$0`-relative (:55) = the frozen worktree root when run through the oracle; `.wizard-answers.yaml` is NOT git-tracked, so the frozen worktree never contains it AND (being shared/held-fixed) cannot be seeded. The Phase-25 `WIKI_IMPL=bash` leg ALSO runs from the frozen worktree and ALSO cannot reach exit 4 — there is no bash-vs-py differential to assert. The committed exit-4 golden (`tests/goldens/init-wizard/already-initialized/`, captured from a writable git-archive-extracted tree) freezes the COMPAT BOUNDARY for documentation; it is NOT a parity-checked case. |
| The `$0`-relative-REPO_ROOT STATE-DEPENDENT error class | Any error path gated by a non-tracked file at the script's own REPO_ROOT has the same root cause as exit-4 above: the frozen worktree cannot host the gating state on either leg. |
| `init-wizard` exit 3 (pre-flight python3-missing, source :165) | A dependency-PRESENCE check that MOVES INTO THE SHIM in Phase 25 (a Python port cannot detect "python3 missing" from inside python3). Parity-exempt for the python-MODULE diff — but NOT unenforced: the SHIM-LEVEL preservation of exit 3 is enforced by `tests/phase-24/test_shim_preflight_exit3.sh` (cycle-4 finding #2b + the cycle-6 manifest-driven per-shim loop). Exit-3 is a TESTED compat boundary, not a silent exemption. |
| `gen-skills --check` DRIFT (exit 1) — the oracle leg cannot reach it | The frozen worktree is always in-sync, so the oracle's `gen-skills --check` always exits 0 (that in-sync case IS parity-verifiable and has its golden). The DRIFT exit-1 reference is the MANDATORY committed golden `tests/goldens/gen-skills/check-drift/` captured from a writable extracted tree (cycle-4 finding #2a — NOT dropped, NOT optional); it is a frozen reference, not a parity diff against the in-sync oracle. |

Extracted-tree goldens' `tree` channel holds a fixed placeholder line (the full-repo tree varies
with the baseline ref); their load-bearing channels are `exit` + `stdout`/`stderr`.
