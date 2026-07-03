# Python Shim Contract (LOCKED — v1.5 migration)

> Authoritative contract for the Bash→Python migration's `bin/<tool>.sh` exec-shims and the
> `WIKI_IMPL` parity-oracle seam. Locked in Phase 24 (foundation); Phase 25 ports FILL this
> contract and never renegotiate it. Tooling reference only — not wiki schema.

## 1. The canonical Phase-25 shim target form (checkout-hermetic — NOT applied in Phase 24)

When a tool is ported, its `bin/<tool>.sh` becomes exactly this thin exec-shim:

```bash
#!/usr/bin/env bash
# bin/<tool>.sh  (Phase 25 target form -- NOT applied in Phase 24)
# Self-bootstrapping: resolve REPO_ROOT, prepend src/ to PYTHONPATH so `import compendium`
# works on a bare checkout (no `pip install -e .` required). This keeps install-hooks.sh +
# .githooks/pre-commit + the user shell working unchanged (REVIEWS HIGH#9 — no ModuleNotFoundError).
_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PYTHONPATH="${_REPO_ROOT}/src${PYTHONPATH:+:$PYTHONPATH}"
exec python3 -m compendium.<tool> "$@"
```

This is the SINGLE consistently-applied hermeticity strategy (chosen over "make every caller run
`pip install -e .`"), applied identically across every `bin/<tool>.sh` shim. It requires NO change
to `install-hooks.sh` (stays bash, MIG-06) or `.githooks/pre-commit`. Without the bootstrap, a bare
`exec python3 -m compendium.<tool> "$@"` fails with `ModuleNotFoundError` on any checkout where the
package was never installed (the pre-commit hook, install-hooks.sh, and the user shell do NOT
install it). The pinned runtime deps (PyYAML, ruamel.yaml) are still third-party imports: CI
installs them via `pip install -e .` (Plan 05); the local dev path installs them once into the user
environment or a venv. The `src/`-on-PYTHONPATH bootstrap covers the `compendium` package itself;
the dep install covers the third-party imports.

### 1a. THE SHIM OWNS ITS OWN PYTHONPATH BOOTSTRAP — tested with the seam env CLEARED

LOCKED clause (REVIEWS cycle-4 finding #3 / Codex new-HIGH #2): the `bin/<tool>.sh` shim is
RESPONSIBLE for prepending `src/` to `PYTHONPATH` itself (the `_REPO_ROOT`/`export PYTHONPATH`
lines above) — it must NOT rely on any caller (CI, the parity seam, or the user shell) having set
`PYTHONPATH` for it. The parity seam (Plan 03, `tests/lib/invoke_tool.sh`) ALSO exports
`PYTHONPATH=$REPO_ROOT/src` for the NORMAL parity lane (cycle-1 hermeticity), but that preload
would MASK a shim that is missing its own bootstrap — a bootstrap-free shim would still import
because the seam pre-set the path, and its self-bootstrap would be a coincidence of the seam's
preload rather than a tested contract. Therefore the parity contract REQUIRES that Plan 03's
shim-smoke test (`tests/lib/test_shim_smoke.sh`) runs the shim with the seam's `PYTHONPATH` (and
any other seam-injected env that could mask the bootstrap) UNSET, proving the canonical shim (with
its own bootstrap) SUCCEEDS while a bootstrap-free shim FAILS with `ModuleNotFoundError`. The
seam's `PYTHONPATH` export for the normal lane is NOT removed (the normal lane stays hermetic);
ONLY the dedicated shim-smoke test clears it.

## 2. Why `python3 -m`, not the console_script (D-04)

`python3 -m compendium.<tool>` works whenever `compendium` is importable (guaranteed by the
PYTHONPATH bootstrap), independent of whether any install's `bin/` is on `PATH` — robust across
CI, the pre-commit hot path, and the user's shell. `exec` replaces the bash process, so the exit
code and signal behavior are the Python process's directly, preserving the PKG-03 exit contract.

## 3. The `WIKI_IMPL` parity-oracle mechanism (locked design; Plan 03 implements it)

- **`WIKI_IMPL=bash` ALWAYS executes the held-fixed Phase-24 BASH oracle, NEVER the
  (eventually-python) shim** — invariant across the migration even after a shim flips to python.
- **The held-fixed bash oracle is a GIT WORKTREE checked out at the pinned baseline ref**
  (`tests/lib/oracle-worktree.sh`: `git worktree add --detach <wt> <ref>`, then run
  `<wt>/bin/<tool>.sh`). The worktree preserves the full `bin/`-relative layout, so scripts that
  resolve their libraries relative to `$0`/`${BASH_SOURCE[0]}` (the audit tool's unconditional
  lib-dir export, the brownfield tool's `$(dirname $0)/..`, the skills generator's
  `$SCRIPT_DIR/..`) resolve their REAL `bin/lib` + `schema/`. A flat copy of a single `.sh` into a
  bare directory would break every one of those under `set -euo pipefail`.
- **`WIKI_IMPL=py` runs the `bin/<tool>.sh` SHIM (`bash $REPO_ROOT/bin/<tool>.sh`, which itself
  execs `python3 -m compendium.<tool>`) ON THE PARITY PATH** — NOT `python3 -m compendium.<tool>`
  directly — and ONLY IF the tool is listed in `tests/ported.manifest`; an unported tool falls
  through to the held-fixed bash worktree oracle even under `WIKI_IMPL=py`. Running the actual
  shim on the parity path is what catches a BROKEN shim (bad PYTHONPATH / quoting / module name /
  exec) — the shim is part of the PKG-03 contract and must be exercised, not bypassed. The seam
  still exports the hermetic `PYTHONPATH=$REPO_ROOT/src` + `LC_ALL=C` + `TZ=UTC` for the normal
  lane so the shim inherits the cycle-1 hermeticity; the dedicated shim-smoke test (§1a) is the
  ONLY place that clears the seam `PYTHONPATH`, to prove the shim's own bootstrap is real.
- THIS is what yields a real bash-vs-py differential: for a ported tool, `bash` runs the frozen
  bash worktree oracle and `py` runs the shim→python, and the harness diffs them byte-for-byte
  across 4 channels (stdout, stderr, exit code, resulting file tree).
- In Phase 24 the manifest is empty → both legs run the bash worktree oracle → green-by-fallthrough
  with zero porting.

## 4. The contract each shim preserves byte-for-byte (PKG-03)

Exact argv passthrough (`"$@"` untouched), exact exit-code propagation, stdout-vs-stderr
discipline (diagnostics → stderr, payload → stdout), and cwd. Divergent exit codes that MUST be
preserved:

| Tool | Divergent exit contract |
|------|-------------------------|
| sync-claude | `--check` exits **2** on drift |
| gen-skills | `--check` exits **1** on drift |
| init-wizard | **3** = pre-flight dependency failure; **4** = already-initialized (refused) |
| checkers (neutrality / privacy) | **2** on violation |
| check-sources-cloud-safe | **1** on violation (its own documented contract — corrected at CUT-01; the previous row overgeneralized "2" across all three checkers) |
| lint | dual-mode exit semantics (text vs `--ci --format json`) |

**init-wizard exit 3 is a Phase-25 COMPAT BOUNDARY the `.sh` shim must preserve BEFORE invoking
Python:** the pre-flight is a dependency-PRESENCE check — a Python port cannot detect "python3
missing" from inside python3 — so the shim, not the Python module, owns the exit-3 preflight. The
shim-level preflight-preservation contract test that enforces this lives in Plan 04
(`tests/phase-24/test_shim_preflight_exit3.sh`); the Phase-25 init-wizard port must keep the
preflight in the shim.

## 5. Downstream callers that invoke the shims unchanged

CI workflows, `.githooks/pre-commit` (the `sync-claude → gen-skills → lint` hot path — the REAL
local gate), schema docs, and `.claude/settings.local.json` (which calls
`bash bin/validate-op.sh ...`). All keep invoking `bash bin/<tool>.sh` with no change across the
migration BECAUSE of the PYTHONPATH self-bootstrap.

## 6. Phase-24 invariant

Every `bin/<name>.sh` still runs its ORIGINAL bash body in Phase 24; `WIKI_IMPL=py` falls through
to the bash worktree oracle for every tool because `tests/ported.manifest` is empty. Deleting
`bin/lib/` or editing any bash body in Phase 24 is forbidden.
