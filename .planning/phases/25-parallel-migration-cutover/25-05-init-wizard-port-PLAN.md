---
phase: 25-parallel-migration-cutover
plan: 05
type: execute
wave: 1
depends_on: [01]
files_modified:
  - src/compendium/init_wizard.py
  - bin/init-wizard.sh
  - tests/ported.manifest
  - tests/test_init_wizard_unit.py
autonomous: true
requirements: [MIG-04]
---

<objective>
Port `bin/init-wizard.sh` (1,144 lines, 9 heredocs) — the riskiest port, isolated as its
own plan per the milestone brief: interactive prompt contract + the wizard-vs-manual
byte-equality CI gate (`setup-parity`) + the shim-owned exit-3 preflight COMPAT BOUNDARY.
Completes MIG-04 (started in 25-03).
</objective>

<context>
- **THE EXIT-3 PREFLIGHT STAYS IN THE SHIM** (shim-contract §4, LOCKED): the preflight is
  a dependency-PRESENCE check — a Python port cannot detect "python3 missing" from inside
  python3. `bin/init-wizard.sh` is therefore NOT the canonical 7-line shim: it keeps the
  bash preflight block (current :146–169, `exit 3` at :165) BEFORE the PYTHONPATH
  bootstrap + exec. `tests/phase-24/test_shim_preflight_exit3.sh` enforces this shape —
  it must stay green unmodified.
- Exit **4** = already-initialized (guard at :195, exit at :221) — moves INTO the Python
  module (it's a state check, not a dependency check).
- **Interactive contract:** prompts (text, ordering, defaults, re-prompt-on-invalid) are
  driven by tests via piped stdin. Byte-parity covers the prompt text on its exact stream.
  Python `input()` echoes differently than bash `read -p` under pipes — verify stream
  and echo behavior against the oracle captures early (this is the port's #1 divergence
  risk; resolve with direct sys.stdin reads + explicit prompt writes to match).
- **setup-parity CI gate:** wizard-rendered output must remain byte-equal to the
  documented manual setup path (AGENTS.template.md placeholder substitution —
  {{AGENT_FILENAME}}, {{DECAY_PROFILE}}, {{DEFAULT_PRIVACY}}, {{PRIMARY_DOMAIN}}).
- init-wizard goldens exist (Phase 24); REPO_ROOT resolves from `$0` (:55) — the module
  must resolve the equivalent from its own location semantics via the shim's cwd/argv
  contract, not hardcoded paths.
</context>

<tasks>
1. Baseline both legs (phase-08 wizard suites + setup-parity workflow logic + goldens).
   Read the full script; table of prompts (text/default/validation), heredoc payloads,
   rendered outputs.
2. Port to `init_wizard.py`: prompt loop matching read -p byte behavior under pipes;
   template rendering verbatim; exit-4 guard in module; NO preflight in module.
3. Rewrite `bin/init-wizard.sh` as preflight-plus-exec shim: keep the existing preflight
   block verbatim (exit 3 semantics untouched), then the canonical bootstrap + exec.
4. TEST-06: `tests/test_init_wizard_unit.py` — placeholder substitution, answer
   validation, already-initialized detection.
5. Manifest append; three-leg parity (wizard tests drive stdin through the seam — watch
   the stderr channel for prompt-echo divergence); commit
   `feat(25): port init-wizard to python behind preflight shim (MIG-04 complete)`; SUMMARY.
</tasks>

<acceptance>
- `test_shim_preflight_exit3.sh` green UNMODIFIED (shim keeps bash preflight).
- Simulated missing-dependency run exits 3 from the shim before Python starts;
  already-initialized run exits 4 from the module — diagnostics byte-identical.
- Wizard-vs-manual outputs byte-equal (setup-parity logic run locally); wizard goldens
  byte-match on the py leg.
- Three-leg parity 0/0/0; SUITE_MANIFEST match; freeze guard clean; unit file green.
</acceptance>
