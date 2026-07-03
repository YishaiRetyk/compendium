---
phase: 25-parallel-migration-cutover
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - src/compendium/brownfield.py
  - bin/brownfield.sh
  - tests/ported.manifest
  - tests/test_brownfield_unit.py
autonomous: true
requirements: [MIG-01]
---

<objective>
Port the brownfield cluster — `bin/brownfield.sh` (2,259 lines, 8 python3 heredocs, 5
subcommands: scan / bootstrap / suggest / review-typing / verify) — onto
`compendium.common`, flip its shim, and prove parity across the phase-10/11 suites
(88 seam-routed invocations, 56 files calling `invoke_tool_compat brownfield`).
This is MIG-01: the lowest-risk LARGE script and the architectural template every later
plan copies (module layout, heredoc extraction style, subcommand dispatch, unit-test
shape, flip-and-parity flow).
</objective>

<context>
- The 5 `bin/lib/*.py` modules are ALREADY lifted verbatim into `common/` (Phase 24:
  privacy.py, yaml_rt.py, walk.py, classify.py, provenance.py). The port imports
  `compendium.common` and NEVER `bin/lib/` — but `bin/lib/` is NOT deleted (the frozen
  bash oracle worktree still imports it; deletion is post-cutover at the earliest).
- The `make_yaml` canonicalization chokepoint (common/yaml_rt.py) is the byte-exactness
  crux for YAML/REPORT fixture output (MIG-01's explicit bar).
- OUT OF SCOPE: `schema/brownfield/migrations/*.sh` stay bash (they ride the
  suggest/verify op-hash byte-copy contract — REQUIREMENTS.md Out of Scope).
- Inventory rows in play: `test_hashlib_not_sha256sum.sh` was ALREADY rewritten to a
  behavioral op_hash-value assertion (done, Phase 24) — the port must emit the identical
  `# op_hash: sha256:<64hex>` line 2 on suggest-generated migration copies.
- Known stderr surface: the brownfield banner prints to stderr (Phase-24 observation) —
  preserve stream placement exactly.
- Pinned FAILs that must STAY failing: phase-10/test_agents_section_5_bootstrap_stage,
  phase-11/test_agents_section_11_5 (stale AGENTS-section tests, not tool behavior).
</context>

<tasks>
1. Baseline: run phase-10 + phase-11 suites both legs at HEAD; confirm 31/32 and 47/48
   per SUITE_MANIFEST.txt. Read `bin/brownfield.sh` fully; map each subcommand's bash
   orchestration vs heredoc payloads; list every emitted file shape (`.brownfield/`
   report, applied.log per-script shapes, migration copies, bootstrap_stage lifecycle
   writes).
2. Port to `src/compendium/brownfield.py`: argparse-free manual argv dispatch (byte-parity
   of usage/error text beats argparse convenience — copy the bash `usage()` text and
   unknown-arg error strings verbatim, including exit codes). Heredoc Python lifted
   near-verbatim into module functions; bash glue (find/git/sed pipelines) translated to
   os/subprocess/pathlib equivalents with identical observable output. Imports:
   `from compendium.common import ...` only.
3. TEST-06: `tests/test_brownfield_unit.py` — direct module-level tests for ≥4 pure
   seams (e.g. plan computation, report rendering, op_hash canonicalization input
   construction, bootstrap_stage transition logic) using the pytest harness fixtures.
4. Flip: `bin/brownfield.sh` → canonical shim (contract §1, target
   `compendium.brownfield`); append `brownfield` to `tests/ported.manifest`.
5. Parity per the recipe (25-CONTEXT §recipe step 5): three legs green, per-test results
   match the manifest on both legs. Iterate on divergences via the capture dirs
   (`--require-parity` names the diverging key + channel).
6. Commit `feat(25): port brownfield cluster to python (MIG-01)` (backgrounded; gate now
   runs the py leg live for brownfield). Restore hook-clobbered wiki files. Write
   25-01-SUMMARY.md recording the template decisions later plans copy.
</tasks>

<acceptance>
- `bash bin/brownfield.sh scan --help`-class smoke identical to oracle output.
- Full three-leg parity run exits 0/0/0; SUITE_MANIFEST match on both legs.
- suggest-generated migration copy line 2 = `# op_hash: sha256:<64hex>` matching the
  reference computation (the rewritten phase-11 test passes on the py leg).
- `pytest tests/test_brownfield_unit.py` green; no frozen-surface diffs
  (`bash bin/check-common-freeze.sh` exits 0).
</acceptance>
