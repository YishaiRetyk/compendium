---
phase: 08-two-track-setup-wizard-manual
plan: 02
subsystem: wizard-core
tags:
  - wizard
  - template-render
  - cli
  - tdd
requires:
  - 08-01 (tests/phase-08/lib.sh aggregator, schema/fixtures/canonical-answers.yaml, schema/fixtures/canonical-AGENTS.md)
  - schema/AGENTS.template.md (4 tokens at lines 32, 56, 588, 589, 848)
  - bin/release.sh (flag-parsing idiom), bin/check-neutrality.sh (python3 inline-block pattern), bin/ingest.sh (slug regex reference)
provides:
  - bin/init-wizard.sh (core: preflight + validator + render + --dry-run + --render-to + idempotency + not-yet-implemented gate)
  - 9 phase-08 test scripts under tests/phase-08/test_wizard_*.sh
affects:
  - Plan 03 (wizard-side-effects) will remove the exit-2 gate and add the 4 additional writes (.wizard-answers.yaml, CLAUDE.md sync, decision record, wiki/index.md edit)
  - Plan 05 (ci-byte-equality) consumes bin/init-wizard.sh --render-to as the CI render routine for MANUAL-06 drift prevention
tech-stack:
  added: []
  patterns:
    - "python3 inline block invoked from bash with env vars (mirrors bin/check-neutrality.sh)"
    - "Shared validator (D-14) with identical D-17 error shape for interactive fail-fast + --answers-file collect-all"
    - "Pure-bash parameter-expansion dirname to survive preflight PATH stripping in tests"
    - "Prompt + explainer text routed to stderr so stdout captures only validated answer values (fixes a latent capture-pollution bug discovered during interactive byte-equality testing)"
key-files:
  created:
    - bin/init-wizard.sh
    - tests/phase-08/test_wizard_exists.sh
    - tests/phase-08/test_wizard_preflight.sh
    - tests/phase-08/test_wizard_validation.sh
    - tests/phase-08/test_wizard_template_render.sh
    - tests/phase-08/test_wizard_dryrun.sh
    - tests/phase-08/test_wizard_idempotent.sh
    - tests/phase-08/test_wizard_summary.sh
    - tests/phase-08/test_wizard_semantic_groups.sh
    - tests/phase-08/test_wizard_not_yet_implemented.sh
  modified: []
decisions:
  - "Routed interactive prompt + explainer text to stderr (not stdout) so command-substitution captures only validated values. Without this the interactive render was injecting prompt echoes into rendered AGENTS.md (caught in self-test before commit)."
  - "Used pure-bash parameter expansion ('${var%/*}') for SCRIPT_DIR resolution instead of 'dirname' so pre-flight (WZRD-09 test PATH-stripping path) doesn't emit a spurious 'dirname: command not found' before our own preflight error block."
  - "Added --help/-h to the usage text (originally omitted) after test_wizard_exists grep uncovered the gap. Plan's Task 2 test spec required this."
  - "Implemented exit-code-2 'not yet implemented — Plan 03 pending' gate (review concern #6) as an explicit branch before any write. Plan 03 will delete it."
  - "Em-dash (U+2014) used for 'internal — CI/testing only' and 'not yet implemented — Plan 03 pending' to match the plan's exact grep strings in tests."
metrics:
  duration_minutes: 12
  tasks_completed: 2
  files_created: 10
  lines_added: 715  # wizard + tests combined is larger; this figure is just bin/init-wizard.sh
  completed: 2026-04-16
---

# Phase 8 Plan 2: Init Wizard Core Summary

**One-liner:** Ships `bin/init-wizard.sh` (715 lines) with preflight + validator + 4-token template render + --dry-run + --render-to + idempotency + explicit exit-2 gate for Plan 03 deferral; 9 phase-08 tests cover WZRD-01/02/04/05/07/08/09/11 + the gate; fixture byte-equality verified.

## Exit-Code Allocation

| Code | Meaning                                             | Plan 02 scope              |
|------|-----------------------------------------------------|----------------------------|
| 0    | success                                             | --help, --dry-run, --render-to, validation-passed paths |
| 1    | generic failure (bad arg, write error)              | unknown flag, missing flag value |
| 2    | not yet implemented — Plan 03 pending               | **NEW in Plan 02** — real-run without --render-to/--dry-run; removed in Plan 03 |
| 3    | pre-flight failure (missing bash >= 4 / git / python3) | WZRD-09 gate              |
| 4    | refused (already initialized; .wizard-answers.yaml present and not --dry-run) | WZRD-05 gate |
| 5    | validation failure (invalid input or --answers-file errors) | WZRD-04 gate          |

## Fixture Byte-Equality Verified

```
$ bash bin/init-wizard.sh --answers-file schema/fixtures/canonical-answers.yaml --render-to /tmp/wz-final
$ cmp -s /tmp/wz-final/AGENTS.md schema/fixtures/canonical-AGENTS.md && echo "BYTE EQUAL"
BYTE EQUAL
```

Interactive path also verified byte-equal (caught a capture-pollution bug and fixed before commit):

```
$ NO_COLOR=1 printf 'Template Maintainer\npersonal-knowledge\nclaude-code\ncloud_safe\ndefault\ny\n' \
  | bash bin/init-wizard.sh --render-to /tmp/wz-inter >/dev/null 2>&1
$ cmp -s /tmp/wz-inter/AGENTS.md schema/fixtures/canonical-AGENTS.md && echo "BYTE EQUAL"
BYTE EQUAL
```

## 9 Test Files

All phase-08 tests run green: `PHASE 08 TESTS: 16/16` (7 manual-setup tests from Plan 04 + 9 new wizard tests from this plan).

| # | Test file | Covers | Status |
|---|-----------|--------|--------|
| 1 | test_wizard_exists.sh               | WZRD-01 + review #5 (internal marker) | PASS |
| 2 | test_wizard_preflight.sh            | WZRD-09 (git/python3 stripped → exit 3) | PASS |
| 3 | test_wizard_validation.sh           | WZRD-04 (D-17 shape on 3 bad fields → exit 5) | PASS |
| 4 | test_wizard_template_render.sh      | WZRD-07 (canonical render byte-equal) | PASS |
| 5 | test_wizard_dryrun.sh               | WZRD-11 (diff headers + no mutation) | PASS |
| 6 | test_wizard_idempotent.sh           | WZRD-05 (exit 4 + D-06 bypass) | PASS |
| 7 | test_wizard_summary.sh              | WZRD-08 (Wrote + byte count line) | PASS |
| 8 | test_wizard_semantic_groups.sh      | WZRD-02 (5 D-13 explainers) | PASS |
| 9 | test_wizard_not_yet_implemented.sh  | review #6 (exit 2 + 'not yet implemented' message) | PASS |

## Explicit Exit-2 Gate (Removed in Plan 03)

Real-run mode — no `--render-to` AND no `--dry-run` AND (interactive OR `--answers-file`) — exits with code 2 and prints to stderr:

```
bin/init-wizard.sh: not yet implemented — Plan 03 pending.
Use --dry-run to preview the rendered output, or --render-to <dir> for CI testing.
```

**No files are written.** This gate is explicit and testable (test_wizard_not_yet_implemented.sh). Plan 03 removes it once real-run repo-root writes are wired (the 4 additional files: CLAUDE.md sync via bin/sync-claude.sh, .wizard-answers.yaml, wiki/decisions/dr-YYYY-MM-DD-initial-setup.md, wiki/index.md edit).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug] Prompt text leaking into captured stdout**

- **Found during:** Task 1 interactive byte-equality self-test (before commit).
- **Issue:** `prompt_once` printed `[Default: X]:` prompts to stdout. When invoked via `value=$(prompt_once ...)` the captured value included the entire prompt echo (`primary_domain [Default: personal-knowledge]: personal-knowledge`), which then flowed into the rendered AGENTS.md and broke byte-equality with the canonical fixture.
- **Fix:** Routed all prompt text AND semantic-group headers/explainers to stderr (`>&2`). Stdout now contains only the validated answer value.
- **Files modified:** `bin/init-wizard.sh`
- **Verified:** interactive `printf ... | wizard --render-to $tmp` now byte-equals `schema/fixtures/canonical-AGENTS.md`.

**2. [Rule 3 — Blocker] --help flag omitted from usage text**

- **Found during:** Task 2 `test_wizard_exists.sh` (grep for `--help` in usage output failed).
- **Issue:** Usage text enumerated 3 flags but didn't list `--help/-h`, even though the flag-parsing branch handled it. The plan's test spec required `bash init-wizard.sh --help | grep -qE -- '--help'` to match.
- **Fix:** Added `--help, -h              Show this help and exit.` line to the Modes block.
- **Files modified:** `bin/init-wizard.sh`

**3. [Rule 1 — Bug] `dirname: command not found` noise during PATH-stripped preflight**

- **Found during:** test_wizard_preflight.sh self-test.
- **Issue:** SCRIPT_DIR resolution called `dirname` via command substitution, which emitted `line 40: dirname: command not found` to stderr BEFORE preflight fired. This polluted stderr and could confuse `grep` assertions even though exit 3 was correct.
- **Fix:** Replaced `$(dirname "${BASH_SOURCE[0]}")` with pure-bash parameter expansion `${BASH_SOURCE[0]%/*}` with fallback logic for the no-slash edge case.
- **Files modified:** `bin/init-wizard.sh`

### Deferred / Out of Scope

None. Plan 02 scope was tightly bounded to the deterministic core (no repo-root mutation).

### Parallel-Execution Coordination

Plan 02 is Wave 1 with `depends_on: [08-01]`. At execution start 08-01 Task 1 had committed `tests/phase-08/run.sh`, `lib.sh`, and `fixtures/.gitkeep`, but Task 2 (the canonical fixtures) was still in-flight. I waited for 08-01 to commit `b94c984 feat(08-01): add canonical byte-equality fixtures + .gitattributes EOL pin` before running my tests. In the meantime Plan 04 (Wave 1) also landed 7 manual-setup tests. Net: phase-08 aggregator now reports 16/16 (not 9/9) because of the merged test set — plan's `PHASE 08 TESTS: 9/9` was intent for a single-plan view; the combined-run figure is expected in parallel-execution mode.

## Authentication Gates

None.

## Self-Check: PASSED

- `bin/init-wizard.sh` exists and is executable: FOUND
- 9 test files under `tests/phase-08/test_wizard_*.sh`: FOUND (all 9)
- Commit `194b050` (feat(08-02): add bin/init-wizard.sh core): FOUND
- Commit `23ae9b5` (test(08-02): add 9 phase-08 tests): FOUND
- `PHASE 08 TESTS: 16/16` aggregator output: VERIFIED
- Fixture byte-equality (`cmp -s /tmp/wz-final/AGENTS.md schema/fixtures/canonical-AGENTS.md`): EXIT 0
- Phase-07 regression (`bash tests/phase-07/run.sh`): PHASE 07 TESTS: 22/22
- Neutrality check (`bash bin/check-neutrality.sh`): EXIT 0
