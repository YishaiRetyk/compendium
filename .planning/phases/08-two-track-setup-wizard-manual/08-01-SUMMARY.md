---
phase: 08-two-track-setup-wizard-manual
plan: 01
subsystem: testing
tags: [bash, python3, byte-equality, fixtures, gitattributes, wizard, manual-track]

requires:
  - phase: 07-neutral-template-foundation
    provides: "tests/phase-07/run.sh aggregator contract; schema/AGENTS.template.md with 4 wizard placeholders; bin/release.sh privacy-leak regex; bin/check-neutrality.sh"

provides:
  - "tests/phase-08/run.sh aggregator (Phase 08 parity with Phase 07 contract)"
  - "tests/phase-08/lib.sh (7 shared bash helpers: mktemp_repo, cleanup_tempdirs, assert_eq, assert_grep, assert_no_grep, assert_file_exists, assert_byte_equal)"
  - "schema/fixtures/canonical-answers.yaml (6-answer canonical input set)"
  - "schema/fixtures/canonical-AGENTS.md (byte-frozen render target; 1723 lines, 0 leftover placeholders)"
  - "schema/fixtures/README.md (cloud_safe deviation + regeneration rule documented)"
  - ".gitattributes entries pinning the 3 fixture files to eol=lf (M-2 mitigation)"

affects: [08-02-init-wizard-core, 08-03-wizard-side-effects, 08-04-manual-track-and-docs, 08-05-ci-byte-equality]

tech-stack:
  added: []
  patterns:
    - "Byte-equality fixture contract: wizard + manual track render outputs must cmp -s against schema/fixtures/canonical-AGENTS.md"
    - "Semantic parity over line-count parity: phase-NN/run.sh aggregators diff only on header/usage/phase-number strings (no exact line-count pin per review concern #12)"
    - "LF-pinned fixture files in .gitattributes as cross-platform byte-drift mitigation"
    - "Python3 deterministic str.replace render routine as reference for Plan 02 wizard's render logic"

key-files:
  created:
    - tests/phase-08/run.sh
    - tests/phase-08/lib.sh
    - tests/phase-08/fixtures/.gitkeep
    - schema/fixtures/canonical-answers.yaml
    - schema/fixtures/canonical-AGENTS.md
    - schema/fixtures/README.md
  modified:
    - .gitattributes

key-decisions:
  - "default_privacy=cloud_safe in canonical-answers.yaml (not local_only) — deliberate deviation from wizard default to pass bin/release.sh's '^privacy:[[:space:]]*local_only' public-leak regex (review concern #1)"
  - "Render routine at Plan 01 is a one-shot python3 str.replace block; Plan 02's bin/init-wizard.sh MUST implement byte-identical routine or CI byte-equality fails — fixture acts as drift detector (review concern #13)"
  - "Semantic parity between phase-07/run.sh and phase-08/run.sh: diff filtered for (phase-07|phase-08|PHASE 07|PHASE 08) tokens returns 0 unexpected lines — no exact line-count pin (review concern #12)"
  - "mktemp_repo + cleanup_tempdirs trap pattern in lib.sh gives Plans 02–05 a shared safe tempdir workflow without worktree mutation risk"

patterns-established:
  - "Byte-frozen fixture pair pattern: canonical inputs YAML + canonical rendered target, both LF-pinned, with README documenting regeneration rule"
  - "Test harness aggregator contract shared across phases: tests/phase-NN/run.sh with shopt -s nullglob loop and PHASE NN TESTS: P/T footer"

requirements-completed: [WZRD-01, WZRD-07, MANUAL-06]

duration: 3min
completed: 2026-04-16
---

# Phase 08 Plan 01: Test Harness and Fixtures Summary

**Wave-0 Phase 08 test harness (aggregator + 7 bash helpers) plus the byte-frozen canonical fixture pair (answers.yaml + rendered AGENTS.md) that locks the wizard/manual-track drift contract for Plans 02–05.**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-04-16T03:53:57Z
- **Completed:** 2026-04-16T03:56:22Z
- **Tasks:** 2
- **Files created:** 6 (tests/phase-08/run.sh, tests/phase-08/lib.sh, tests/phase-08/fixtures/.gitkeep, schema/fixtures/canonical-answers.yaml, schema/fixtures/canonical-AGENTS.md, schema/fixtures/README.md)
- **Files modified:** 1 (.gitattributes)

## Accomplishments

- Phase 08 test aggregator created with semantic parity to `tests/phase-07/run.sh` (only header comment, usage string, and final `PHASE 0N TESTS:` footer differ — filtered diff returns 0 unexpected lines).
- Shared bash helper library with 7 exported functions + `EXIT|INT|TERM` cleanup trap ready for Plans 02–05 test authoring.
- Byte-frozen `canonical-AGENTS.md` rendered from `schema/AGENTS.template.md` via deterministic python3 `str.replace` block with the 4 wizard substitutions:
  - Line 32: `{{AGENT_FILENAME}}` → `CLAUDE.md` → `This file (\`CLAUDE.md\`) is the canonical agent spec`
  - Line 56: `{{PRIMARY_DOMAIN}}` → `personal-knowledge` → `AGENTS.template.md  # Wizard source (personal-knowledge etc.)`
  - Line 588: `{{PRIMARY_DOMAIN}}` → `personal-knowledge` → `knowledge_domain: "personal-knowledge"`
  - Line 589: `{{DEFAULT_PRIVACY}}` → `cloud_safe` → `privacy_default: cloud_safe`
  - Line 848: `{{DECAY_PROFILE}}` → `default` → `The default staleness decay profile is \`default\``
- Rendered fixture: 1723 lines, 0 leftover `{{...}}` tokens, single `0x0a` trailing byte (matches template terminator).
- `.gitattributes` appended with 3 LF-pin entries (idempotent check confirmed missing before append).
- `schema/fixtures/README.md` documents both the `cloud_safe` deviation rationale (review concern #1) and the `bin/init-wizard.sh --answers-file ... --render-to ...` regeneration command for when `schema/AGENTS.template.md` changes (review concern #13).

## Task Commits

1. **Task 1: Phase-08 test harness (run.sh + lib.sh + fixtures/.gitkeep)** — `dbf1409` (feat)
2. **Task 2: Canonical fixtures + README + .gitattributes EOL pin** — `b94c984` (feat)

## Files Created/Modified

- `tests/phase-08/run.sh` — Phase 08 test aggregator; shopt -s nullglob loop over test_*.sh, tallies PASS/FAIL, exits non-zero on any failure; prints `PHASE 08 TESTS: P/T` footer.
- `tests/phase-08/lib.sh` — shared helpers: `mktemp_repo`, `cleanup_tempdirs`, `assert_eq`, `assert_grep`, `assert_no_grep`, `assert_file_exists`, `assert_byte_equal`; cleanup trap registered on `EXIT INT TERM`; `REPO_ROOT` exported for test use.
- `tests/phase-08/fixtures/.gitkeep` — placeholder so git tracks the empty fixture-repo-skeleton directory.
- `schema/fixtures/canonical-answers.yaml` — 6-answer set: `Template Maintainer`, `personal-knowledge`, `claude-code`, `cloud_safe`, `default`, `obsidian: true`.
- `schema/fixtures/canonical-AGENTS.md` — byte-frozen render target (1723 lines). All future wizard/manual-track outputs must `cmp -s` against this.
- `schema/fixtures/README.md` — rationale for `cloud_safe` deviation (references `bin/release.sh` privacy-leak regex at line 160); regeneration command; EOL-pinning note.
- `.gitattributes` — appended Phase 8 block: 3 `text eol=lf` entries under a `# Phase 8 byte-equality fixtures` header.

## Decisions Made

- **`default_privacy: cloud_safe` (not `local_only`):** Deliberate deviation from the wizard's default (`local_only` per D-11). Reason documented in `schema/fixtures/README.md`: the fixture ships publicly via the template release; `bin/release.sh` contains `^privacy:[[:space:]]*local_only[[:space:]]*(#.*)?$` which would reject the fixture if rendered with `local_only`. End users who run the wizard on a private repo keep the wizard's `local_only` default.
- **Regeneration contract (review concern #13):** The inline python3 `str.replace` block used to generate the fixture is a reference implementation of the Plan 02 wizard's render routine. Plan 05's byte-equality CI job will `cmp -s` the fixture against `bin/init-wizard.sh --answers-file schema/fixtures/canonical-answers.yaml --render-to /tmp/wz` output. If the two routines diverge, CI fails and the fixture MUST be regenerated via the wizard (not re-running the inline python3).
- **Semantic parity vs. line-count parity (review concern #12):** `diff tests/phase-07/run.sh tests/phase-08/run.sh | grep -v -E '(phase-07|phase-08|PHASE 07|PHASE 08)' | wc -l` returns 0 — every differing line contains one of the four expected phase-number tokens. No exact line-count pin committed.

## Deviations from Plan

None — plan executed exactly as written. All acceptance criteria in the plan's `<verify>` block passed on first run:

- Phase 08 aggregator: `bash tests/phase-08/run.sh` → `PHASE 08 TESTS: 0/0`, exit 0.
- `bash -n tests/phase-08/lib.sh` exit 0 (7 helpers matched by the plan's grep pattern).
- `tests/phase-08/fixtures/.gitkeep` present.
- Fixture byte-equality: 0 leftover `{{...}}`, no `^privacy:[[:space:]]*local_only` match, line-32 and line-588 substitutions verified, single `\n` terminator (`xxd -p` → `0a`).
- `.gitattributes` contains all 3 LF-pin entries.
- `schema/fixtures/README.md` contains `cloud_safe`, `local_only`, `Regeneration Rule`, `release.sh` literals.
- Regression: `bash bin/check-neutrality.sh` exit 0; `bash tests/phase-07/run.sh` 22/22 PASS.
- Idempotent regen: fresh python3 render against current `schema/AGENTS.template.md` + `cmp -s` against committed fixture → zero diff.

## Issues Encountered

None — all steps deterministic and ran first-try.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

Ready for:
- **Plan 02 (init-wizard-core):** Can author `bin/init-wizard.sh` with `tests/phase-08/lib.sh` helpers and `schema/fixtures/canonical-answers.yaml` as `--answers-file` input. Byte-equality target is `schema/fixtures/canonical-AGENTS.md`.
- **Plan 03 (wizard-side-effects):** Side-effect tests (`.wizard-answers.yaml` write, privacy-file handling) use the same lib.sh + fixtures.
- **Plan 04 (manual-track-and-docs):** `docs/manual-setup.md` byte-equality check against `schema/fixtures/canonical-AGENTS.md`.
- **Plan 05 (ci-byte-equality):** `.github/workflows/setup-parity.yml` wires `cmp -s` across wizard render, manual-track render, and committed fixture.

No blockers or concerns.

## Self-Check: PASSED

Files verified on disk:
- `tests/phase-08/run.sh` — FOUND
- `tests/phase-08/lib.sh` — FOUND
- `tests/phase-08/fixtures/.gitkeep` — FOUND
- `schema/fixtures/canonical-answers.yaml` — FOUND
- `schema/fixtures/canonical-AGENTS.md` — FOUND (1723 lines)
- `schema/fixtures/README.md` — FOUND
- `.gitattributes` — FOUND (with 3 new LF-pin entries)

Commits verified in git log:
- `dbf1409` — Task 1 FOUND
- `b94c984` — Task 2 FOUND

---
*Phase: 08-two-track-setup-wizard-manual*
*Completed: 2026-04-16*
