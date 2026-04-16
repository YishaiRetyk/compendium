---
phase: 08-two-track-setup-wizard-manual
plan: 03
subsystem: wizard-side-effects
tags:
  - wizard
  - side-effects
  - staging-dir
  - atomic-promote
  - decision-record
  - sync-claude
  - index-md
requires:
  - 08-02 (bin/init-wizard.sh Plan 02 core: preflight + validator + render + --dry-run + --render-to + idempotency + exit-2 gate)
  - bin/sync-claude.sh (Phase 07 TMPL-10, 35 lines, AGENTS.md -> CLAUDE.md byte copy)
  - wiki/index.md (Phase 07 TMPL-05 skeleton)
  - schema/AGENTS.template.md §4.6 (decision record schema)
  - schema/fixtures/canonical-answers.yaml + canonical-AGENTS.md (Plan 01 byte-equality reference)
provides:
  - bin/init-wizard.sh (full real-run write path: 5-artifact staging-dir render + atomic promote + update_index_md guardrails + sync-claude invoke + template_sha fallback chain)
  - 5 phase-08 test scripts (test_wizard_answers_yaml, _decision_record, _sync_claude, _index_md, _partial_failure)
affects:
  - Plan 05 (ci-byte-equality) consumes WIZARD_GENERATED_AT + WIZARD_TEMPLATE_SHA env vars for deterministic fixture regeneration in CI
  - Plan 04 (manual-track) already finalized; its Section 8 inlined the same decision record heredoc + wiki/index.md append (review concern #4 parity)
tech-stack:
  added: []
  patterns:
    - "Staging-dir render + atomic mv: tempfile.mkdtemp(dir=REPO_ROOT, prefix='.wizard-stage-') keeps staging on same filesystem as repo-root for atomic shutil.move rename (review concern #8)"
    - "Narrow update_index_md() helper with 3 explicit guardrails (idempotency, duplicate-header, malformed) behind one function (review concern #2)"
    - "template_sha resolution chain: WIZARD_TEMPLATE_SHA env > git log -1 --format=%H schema/AGENTS.template.md > literal <unresolved> (review concern #9)"
    - "Determinism env vars (WIZARD_GENERATED_AT + WIZARD_TEMPLATE_SHA) enable byte-identical fixture re-renders for CI (validated via two-render cmp -s)"
    - "atomic_write via tempfile.mkstemp + os.replace (POSIX rename atomicity; RESEARCH.md Example 1)"
    - "sync-claude invocation cd's to REPO_ROOT so AGENTS.md / CLAUDE.md resolve regardless of caller cwd"
key-files:
  created:
    - tests/phase-08/test_wizard_answers_yaml.sh
    - tests/phase-08/test_wizard_decision_record.sh
    - tests/phase-08/test_wizard_sync_claude.sh
    - tests/phase-08/test_wizard_index_md.sh
    - tests/phase-08/test_wizard_partial_failure.sh
  modified:
    - bin/init-wizard.sh (added 580 insertions / 155 deletions: staging-dir render + atomic promote + 5-artifact write path + update_index_md + sync-claude invoke + template_sha fallback chain; removed exit-2 gate)
  deleted:
    - tests/phase-08/test_wizard_not_yet_implemented.sh (exit-2 gate no longer exists)
decisions:
  - "Idempotency guard (D-03/D-04) retained its Plan 02 semantics: triggers for BOTH real-run AND --render-to when .wizard-answers.yaml exists at REPO_ROOT; --dry-run (D-06) always bypasses. Rationale: test_wizard_idempotent.sh expected guard to apply to --render-to too; narrowing the guard to real-run-only would have regressed that contract."
  - "update_index_md() append-into-existing-section logic preserves existing section body + appends new entry at end (before next `## ` heading or EOF). Entry format matches AGENTS.md §12 index convention: `- [[dr-<today>-initial-setup|Initial Wizard Setup -- <primary_domain>]] -- Wizard-driven template personalization (wiki-infrastructure, <today>)`."
  - "Decision record Alternatives Considered section enumerates the OTHER allowed values for prompts 2-5 using sorted set difference (so output is deterministic even when WIZARD_GENERATED_AT is injected)."
  - "Python3 inline block now receives 8 env vars (WZRD_AGENT, WZRD_MAINTAINER_NAME, WZRD_OBSIDIAN added on top of Plan 02's) to make the side-effect renders self-contained without round-tripping through bash again."
  - "datetime.utcnow() deprecation (Python 3.12+) worked around via try/except fallback so wizard runs cleanly on both 3.11 and 3.12."
  - "Plan wrote '13/13' for test count but actual aggregator reports 20/20 (13 wizard + 7 manual-setup from Plan 04). Same convention as Plan 02 single-plan-view vs combined-run-view."
metrics:
  duration_minutes: 8
  tasks_completed: 2
  files_created: 5
  files_modified: 1
  files_deleted: 1
  lines_net: 772  # 976 insertions - 204 deletions
  completed: 2026-04-16
---

# Phase 8 Plan 3: Wizard Side-Effects Summary

**One-liner:** Wires real-run side-effects into `bin/init-wizard.sh` (staging-dir render + atomic promote for 5 artifacts, narrow `update_index_md()` helper with 3 guardrails, `bin/sync-claude.sh` invoke, `template_sha` fallback chain) and ships 5 new phase-08 tests (`PHASE 08 TESTS: 20/20`); Plan 02's exit-2 "not yet implemented" gate removed; byte-equality with `schema/fixtures/canonical-AGENTS.md` preserved end-to-end.

## Exit-Code Allocation (updated)

| Code | Meaning                                             | Change from Plan 02                        |
|------|-----------------------------------------------------|--------------------------------------------|
| 0    | success                                             | --                                         |
| 1    | generic failure (bad arg, write error, guardrail)   | **expanded** to cover duplicate-header / missing-index / staging-validation failures |
| 2    | (removed)                                           | **Plan 02 exit-2 gate deleted**            |
| 3    | pre-flight failure (missing bash/git/python3)       | --                                         |
| 4    | refused (already initialized)                       | --                                         |
| 5    | validation failure (invalid --answers-file content) | --                                         |

## 5-Artifact Write Inventory

Real-run mode (or `--render-to`) writes exactly 5 files to the target root:

| # | Path                                              | Renderer                     | Source of truth                                               |
|---|---------------------------------------------------|------------------------------|---------------------------------------------------------------|
| 1 | `AGENTS.md`                                       | `render_agents_md()`         | `schema/AGENTS.template.md` with 4-token substitution         |
| 2 | `CLAUDE.md`                                       | `shutil.copyfile(AGENTS.md)` | byte-identical to AGENTS.md (sync-claude invariant)          |
| 3 | `.wizard-answers.yaml`                            | `render_answers_yaml()`      | RESEARCH.md Example 2 shape                                   |
| 4 | `wiki/decisions/dr-<TODAY>-initial-setup.md`      | `render_decision_record()`   | AGENTS.md §4.6 schema + RESEARCH.md Example 5 skeleton        |
| 5 | `wiki/index.md`                                   | `update_index_md()`          | existing file + appended Decisions subsection                 |

## Staging-Dir Pattern (Review Concern #8)

Real-run flow:

1. Create staging dir: `mkdtemp(dir=REPO_ROOT, prefix='.wizard-stage-')` — same filesystem as repo root for atomic rename.
2. Render all 5 artifacts INTO staging dir.
3. Validate: assert all 5 files exist, no `{{...}}` leftovers, `## Decisions` heading appears exactly once in staged `wiki/index.md`.
4. Promote: `shutil.move(staged, repo_root)` per artifact — rename is atomic on same filesystem.
5. Cleanup: `rmtree(staging_dir, ignore_errors=True)` in `finally` block.
6. On any step 2/3 failure: print error with "Repo root untouched" marker, exit 1; staging cleaned by finally.

Verified by `test_wizard_partial_failure.sh`: malformed `wiki/index.md` (2 `## Decisions` headings) triggers validation failure AFTER AGENTS.md/CLAUDE.md are rendered into staging; repo-root stays clean; staging dir is cleaned up.

## update_index_md() — 3 Guardrails (Review Concern #2)

Narrow helper responsible for ONE thing: appending `dr-<today>-initial-setup` wikilink to wiki/index.md Decisions subsection.

| Guardrail          | Trigger                                              | Behavior                                                                                  |
|--------------------|------------------------------------------------------|-------------------------------------------------------------------------------------------|
| 1. Idempotency     | exact wikilink entry already in file                 | return content unchanged (no-op)                                                          |
| 2. Duplicate-header | `## Decisions` appears > 1 times                    | raise RuntimeError with recovery message; staging validator re-runs this check            |
| 3. Malformed       | file missing/unreadable                              | raise RuntimeError with clear pointer-to-manual-recovery message                          |

Plus:
- 0 headings → creates new `## Decisions` section at EOF with the entry.
- 1 heading → inserts entry at end of existing section (before next `## ` heading or EOF).

All 3 guardrails explicitly tested by `test_wizard_index_md.sh`.

## template_sha Resolution Chain (Review Concern #9)

First-match-wins:

1. `WIZARD_TEMPLATE_SHA` env var — authoritative when set (CI + tests).
2. `git log -1 --format=%H schema/AGENTS.template.md` with `cwd=REPO_ROOT` — best-effort for interactive runs.
3. Literal `"<unresolved>"` — final fallback (no `fetch-depth: 2` reliance).

All three tokens grep-verifiable in `bin/init-wizard.sh`.

## Determinism Contract

With `WIZARD_GENERATED_AT=2026-04-16T00:00:00Z` + `WIZARD_TEMPLATE_SHA=test-sha`, two consecutive `--render-to <dir>` invocations into different tmpdirs produce byte-identical output for ALL 5 artifacts:

```
$ WIZARD_GENERATED_AT=2026-04-16T00:00:00Z WIZARD_TEMPLATE_SHA=test-sha bash bin/init-wizard.sh --answers-file schema/fixtures/canonical-answers.yaml --render-to /tmp/wz-a
$ WIZARD_GENERATED_AT=2026-04-16T00:00:00Z WIZARD_TEMPLATE_SHA=test-sha bash bin/init-wizard.sh --answers-file schema/fixtures/canonical-answers.yaml --render-to /tmp/wz-b
$ cmp -s /tmp/wz-a/.wizard-answers.yaml /tmp/wz-b/.wizard-answers.yaml && echo BYTE_EQUAL                      # EXIT 0
$ cmp -s /tmp/wz-a/wiki/decisions/dr-2026-04-16-initial-setup.md /tmp/wz-b/wiki/decisions/...                  # EXIT 0
$ cmp -s /tmp/wz-a/AGENTS.md schema/fixtures/canonical-AGENTS.md && echo CANONICAL_EQUAL                       # EXIT 0
$ cmp -s /tmp/wz-a/AGENTS.md /tmp/wz-a/CLAUDE.md && echo SYNC_CLAUDE_EQUAL                                     # EXIT 0
```

## 5 Test Files

| # | Test file                            | Covers                                                      | Status |
|---|--------------------------------------|-------------------------------------------------------------|--------|
| 1 | test_wizard_answers_yaml.sh          | WZRD-03 + WZRD-06 (shape + determinism)                     | PASS   |
| 2 | test_wizard_decision_record.sh       | WZRD-10 (7 sections + frontmatter conformance)              | PASS   |
| 3 | test_wizard_sync_claude.sh           | Open Q4 + WZRD-06 cross-cut (AGENTS.md == CLAUDE.md)        | PASS   |
| 4 | test_wizard_index_md.sh              | Open Q1 + review concern #2 (3 guardrails)                  | PASS   |
| 5 | test_wizard_partial_failure.sh       | Review concern #8 (staging-dir recovery)                    | PASS   |

Aggregator: `PHASE 08 TESTS: 20/20` (8 kept Plan 02 wizard tests + 5 new Plan 03 tests + 7 Plan 04 manual-setup tests; 1 Plan 02 test deleted as obsolete).

## Exit-2 Gate Removal

Plan 02 shipped this deliberate gate to defer repo-root writes to Plan 03:

```
bin/init-wizard.sh: not yet implemented — Plan 03 pending.
Use --dry-run to preview the rendered output, or --render-to <dir> for CI testing.
```

Plan 03 removed it. Verified by:
- `! grep -q 'not yet implemented — Plan 03 pending' bin/init-wizard.sh` → exit 0
- `tests/phase-08/test_wizard_not_yet_implemented.sh` deleted from disk
- Real-run mode (no `--render-to`, no `--dry-run`) now proceeds through the staging-dir write path end-to-end.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 — Blocker] Idempotency guard scope**
- **Found during:** Task 1 self-test (`bash tests/phase-08/test_wizard_idempotent.sh`).
- **Issue:** Initial implementation narrowed the idempotency guard to real-run-only (`[ -z "$RENDER_TO" ]`). This regressed `test_wizard_idempotent.sh` which expected the guard to fire even when `--render-to` was passed (Plan 02 semantics).
- **Fix:** Reverted guard to Plan 02 scope — triggers for both real-run AND `--render-to` when `.wizard-answers.yaml` exists at `REPO_ROOT`; `--dry-run` (D-06) always bypasses.
- **Files modified:** `bin/init-wizard.sh`
- **Verified:** `test_wizard_idempotent.sh` PASS.

**2. [Rule 1 — Bug] `datetime.utcnow()` deprecation warning**
- **Found during:** Task 1 self-test on Python 3.12 (test_wizard_template_render.sh noisy stderr).
- **Issue:** `datetime.datetime.utcnow()` emits DeprecationWarning starting in 3.12.
- **Fix:** Use `datetime.datetime.now(datetime.timezone.utc)` with try/except fallback to `utcnow()` for pre-3.3 compatibility.
- **Files modified:** `bin/init-wizard.sh`

### Deferred / Out of Scope

None. Plan 03 scope was tightly bounded to the 4 additional writes + the exit-2 gate removal.

### Parallel-Execution Coordination

Plan 03 is Wave 2 with `depends_on: [08-02]`. Plan 02 (Wave 1) already landed before execution; Plan 04 (manual-track) had also merged, which is why the aggregator reports 20/20 not 13/13 (13 wizard + 7 manual-setup). This is the same convention as Plan 02's summary: plan's single-plan view (13) vs combined-run view (20).

### Test Count Intent vs Reality

The plan's automated verification `grep -qE 'PHASE 08 TESTS: 13/13'` would fail against the actual 20/20 count because Plan 04's 7 manual-setup tests are in the same `tests/phase-08/` directory. Per the Plan 02 precedent, this is expected in parallel-execution mode and not a deviation from plan intent. All new and retained wizard tests pass.

## Authentication Gates

None.

## Self-Check

Verified via:
- `bash tests/phase-08/run.sh` → `PHASE 08 TESTS: 20/20`
- `bash tests/phase-07/run.sh` → `PHASE 07 TESTS: 22/22` (regression clean)
- `bash bin/check-neutrality.sh` → exit 0
- `cmp -s /tmp/wz-final/AGENTS.md schema/fixtures/canonical-AGENTS.md` → exit 0
- `cmp -s /tmp/wz-final/AGENTS.md /tmp/wz-final/CLAUDE.md` → exit 0
- `grep -c '^## Decisions$' /tmp/wz-final/wiki/index.md` → 1
- `grep -cE '^## (TL;DR|Decision|Why|Alternatives Considered|Consequences|Affected Pages|Sources)$' /tmp/wz-final/wiki/decisions/dr-2026-04-16-initial-setup.md` → 7
- `grep -q 'trigger_type: schema-update' /tmp/wz-final/wiki/decisions/dr-2026-04-16-initial-setup.md` → exit 0
- `! grep -qE '\{\{[A-Z_]+\}\}' /tmp/wz-final/wiki/decisions/dr-2026-04-16-initial-setup.md` → exit 0
- `! grep -q 'not yet implemented — Plan 03 pending' bin/init-wizard.sh` → exit 0
- `! [ -f tests/phase-08/test_wizard_not_yet_implemented.sh ]` → exit 0
- Commit `35dfb4c` (feat(08-03): wire real-run side-effects): FOUND
- Commit `a0bab62` (test(08-03): add 5 side-effect tests + delete not-yet-implemented gate test): FOUND

## Self-Check: PASSED
