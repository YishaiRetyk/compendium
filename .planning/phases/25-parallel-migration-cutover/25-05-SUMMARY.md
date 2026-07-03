# 25-05 SUMMARY — init-wizard port (MIG-04 complete)

**Status:** Complete (2026-07-04)

## What shipped

- `src/compendium/init_wizard.py`: the riskiest port — interactive prompt contract
  replicated byte-for-byte (prompts to STDERR via unbuffered writes, `read -r` twin
  empirically pinned: delimiter strip + space/tab-only trim, internal runs and `\r`
  preserved, EOF-with-partial-line discards to `""` exactly like bash); the three
  heredocs lifted verbatim; the `while IFS='=' read` answers handoff emulated via
  `partition('=')` incl. unterminated-final-line drop; exit-4 already-initialized
  guard IN the module with byte-identical diagnostics.
- **The exit-3 preflight stays in the SHIM** (LOCKED contract §4): `bin/init-wizard.sh`
  is the one non-canonical shim — it keeps the bash dependency-presence preflight
  (bash≥4 / git / python3 → exit 3) verbatim BEFORE the PYTHONPATH bootstrap + exec.
  `tests/phase-24/test_shim_preflight_exit3.sh` green unmodified.
- Manifest append `init-wizard` (parity-exempt per oracle-exempt.txt — the $0-relative
  exit-4 and preflight classes are not python-module parity-verifiable; the committed
  goldens + phase-08 suites own its behavior).
- TEST-06: `tests/test_init_wizard_unit.py` (14 tests).
- Port-agent self-verification: 41 four-channel cases + 3 manual (pty color run with
  6 ANSI escapes byte-equal; leading-space WIZARD_GENERATED_AT divergence replicated;
  unfrozen wall-clock + git-log SHA fallback), 0 diffs; py exit-4 stderr byte-equals
  the committed golden; **setup-parity property verified** (module render of canonical
  answers byte-equals `schema/fixtures/canonical-AGENTS.md`); phase-08 suite 21/21.

## Execution error (recorded honestly)

During flip smokes the coordinator ran `bash bin/init-wizard.sh </dev/null` against
the LIVE repo expecting the exit-4 already-initialized guard — but that guard keys
off the UNTRACKED `.wizard-answers.yaml` (exactly as tests/oracle-exempt.md
documents), so the wizard performed a REAL default initialization: AGENTS.md /
CLAUDE.md / wiki-cloud/index.md re-rendered, a setup DR page + answers file created.
All restored via `git checkout` + artifact deletion within minutes (AGENTS≡CLAUDE
byte-equality re-verified). Lesson: wizard smokes belong in throwaway copies or
`--dry-run` ONLY. Incidental value: the Python wizard completed a real end-to-end
initialization (render → DR → index/log → sync) with exit 0 on the first try.

## Notes

- Unreachable divergences (documented, no suite coverage): uncaught-exception
  tracebacks name the module file vs `<stdin>`; SIGINT-at-prompt (tty-only) raises
  KeyboardInterrupt where bash's INT trap EOF-continues; non-UTF-8 stdin bytes may
  raise where bash passes through.
- The bash BSD-stat fallback in the setup-date pipeline is dead code (pipeline exit
  is cut's) — replicated as documented dead code.
