---
phase: 08-two-track-setup-wizard-manual
plan: 05
subsystem: ci-byte-equality
tags:
  - ci
  - github-actions
  - byte-equality
  - drift-prevention
  - wizard
  - manual-track
  - manual-06
requires:
  - 08-01 (schema/fixtures/canonical-answers.yaml + canonical-AGENTS.md byte-frozen pair; tests/phase-08/lib.sh helpers; tests/phase-08/run.sh aggregator)
  - 08-03 (bin/init-wizard.sh staging-dir render + atomic promote + 5-artifact write path + template_sha fallback chain; determinism env vars WIZARD_GENERATED_AT + WIZARD_TEMPLATE_SHA)
  - 08-04 (docs/manual-setup.md equivalence contract — manual track reaches same canonical fixture)
provides:
  - ".github/workflows/setup-parity.yml (MANUAL-06 CI gate — wizard vs fixture byte-equality; PR hard gate + push advisory; required check name `setup-parity`)"
  - "tests/phase-08/test_canonical_byte_equality.sh (MANUAL-06 byte-equality test; standalone runnable AND included in aggregator via tests/phase-08/test_*.sh glob)"
  - "Phase 08 aggregator count: PHASE 08 TESTS: 21/21 (13 wizard + 7 manual-setup + 1 new byte-equality)"
affects:
  - Phase 9 docs/reference/ci.md may cite setup-parity as the MANUAL-06 enforcement mechanism (currently stubbed per 07-04)
  - Public template repo operator must add `setup-parity` to branch-protection required-status-checks (one-time GitHub UI action; same model as `neutrality`)
tech-stack:
  added: []
  patterns:
    - "CI gate workflow mirrors .github/workflows/neutrality.yml enforcement model: pull_request = hard gate, push = advisory (required check enforced via branch protection, not workflow file)"
    - "Aggregator-only CI invocation: workflow runs `bash tests/phase-08/run.sh` once; individual tests are picked up via glob. No duplicate invocation (review concern #7)"
    - "Determinism env vars at job level (WIZARD_GENERATED_AT + WIZARD_TEMPLATE_SHA) make wizard git-log template_sha fallback unnecessary — no shallow-clone depth manipulation required (review concerns #9 + #10)"
    - "Byte-equality failure message embeds the regeneration command + path to schema/fixtures/README.md for one-step contributor recovery"
key-files:
  created:
    - tests/phase-08/test_canonical_byte_equality.sh
    - .github/workflows/setup-parity.yml
  modified: []
decisions:
  - "Workflow comments deliberately avoid the literal strings `fetch-depth` and `test_canonical_byte_equality.sh` so the plan's strict `! grep -q` acceptance checks remain mechanical single-pattern greps rather than requiring context-sensitive filtering. Replaced with `shallow-clone depth` / `MANUAL-06 byte-equality test` phrasing; semantics identical."
  - "Aggregator arithmetic reconciled per review concern #7: 13 wizard tests (Plan 02 + Plan 03 retained/added) + 7 manual-setup tests (Plan 04) + 1 new byte-equality test (Plan 05) = 21/21. The Plan 02 `test_wizard_not_yet_implemented.sh` was already deleted in Plan 03 so it does NOT count toward the total."
  - "Required check name fixed as `setup-parity` (matches `jobs.setup-parity:` key). Operator adds this to branch-protection required-status-checks list on the public template repo — same model as Phase 7's `neutrality` check."
metrics:
  duration_minutes: 2
  tasks_completed: 1
  files_created: 2
  files_modified: 0
  completed: 2026-04-16
---

# Phase 08 Plan 05: CI Byte-Equality Summary

**MANUAL-06 drift-prevention gate landed: `.github/workflows/setup-parity.yml` runs the Phase 8 aggregator (which now includes `tests/phase-08/test_canonical_byte_equality.sh` via glob) on every PR, asserting the wizard's render of `schema/fixtures/canonical-answers.yaml` is byte-equal to `schema/fixtures/canonical-AGENTS.md`; `PHASE 08 TESTS: 21/21` reconciled, no duplicate invocation, no shallow-clone depth manipulation.**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-04-16T04:22:13Z
- **Completed:** 2026-04-16T04:24:23Z
- **Tasks:** 1
- **Files created:** 2

## What Shipped

### 1. `tests/phase-08/test_canonical_byte_equality.sh`

Standalone-runnable bash test (LF line endings, executable). Sourced from `tests/phase-08/lib.sh`; uses `mktemp_repo` + `assert_byte_equal` + `assert_file_exists` + `assert_grep` helpers. Test flow:

1. Set determinism env vars `WIZARD_GENERATED_AT=2026-04-16T00:00:00Z` + `WIZARD_TEMPLATE_SHA=<frozen-fixture>` (matching `schema/fixtures/canonical-answers.yaml` metadata).
2. Invoke `bash bin/init-wizard.sh --answers-file schema/fixtures/canonical-answers.yaml --render-to "$WORK"`.
3. Assert `cmp -s "$WORK/AGENTS.md" schema/fixtures/canonical-AGENTS.md` — drift-prevention contract.
4. Assert `cmp -s "$WORK/AGENTS.md" "$WORK/CLAUDE.md"` — sync-claude invariant.
5. Assert `.wizard-answers.yaml` exists with the expected 6-key answer set.
6. Assert `wiki/decisions/dr-2026-04-16-initial-setup.md` exists.
7. Assert `wiki/index.md` has exactly ONE `## Decisions` heading.

On failure, the test prints the regeneration command + the path to `schema/fixtures/README.md` + the first 50 lines of diff output for fast contributor recovery.

### 2. `.github/workflows/setup-parity.yml`

GitHub Actions workflow. Structure mirrors `.github/workflows/neutrality.yml` (Phase 07 Plan 05 precedent):

| Element | Value |
|---------|-------|
| `name` | `Setup Parity (Wizard <-> Manual Byte-Equality)` |
| `on` | `pull_request` (hard gate) + `push: branches: [main]` (advisory) |
| `job` | `setup-parity` (required-check name for branch protection) |
| `runs-on` | `ubuntu-latest` |
| env vars | `WIZARD_GENERATED_AT`, `WIZARD_TEMPLATE_SHA` (frozen) |
| Steps | 1. `actions/checkout@v6` (default depth) → 2. `actions/setup-python@v6` 3.12 → 3. `pip install pyyaml` → 4. `test -x bin/init-wizard.sh` → 5. `bash tests/phase-08/run.sh` (aggregator — includes the byte-equality test via glob) → 6. `bash tests/phase-07/run.sh` (regression) → 7. `bash bin/check-neutrality.sh` (regression) |

## Review-Concern Resolution

| Review # | Concern | Resolution |
|----------|---------|------------|
| **#7** | Aggregator math + no duplicate invocation | Aggregator final count reconciled: 13 wizard + 7 manual-setup + 1 new byte-equality = **21/21**. Workflow invokes the byte-equality test EXACTLY ONCE via the aggregator glob — the literal string `test_canonical_byte_equality.sh` does NOT appear in `.github/workflows/setup-parity.yml` (comment phrasing uses `MANUAL-06 byte-equality test` instead). Mechanical proof: `! grep -q 'test_canonical_byte_equality\.sh' .github/workflows/setup-parity.yml` exit 0. |
| **#9** | No reliance on `fetch-depth: 2` for `git log -1` template_sha fallback | Env var `WIZARD_TEMPLATE_SHA` is authoritative at the job level (`env:` block). The wizard's `template_sha` resolution chain short-circuits on step 1 (env var) so the git-log fallback at step 2 is never triggered in CI. Default shallow-clone depth is used; no manipulation needed. Mechanical proof: `! grep -q 'fetch-depth' .github/workflows/setup-parity.yml` exit 0 (literal string not present anywhere — comment phrasing uses `shallow-clone depth` instead). |
| **#10** | Same as #9 — avoid reliance on 2-commit checkout for first-commit edge case | Resolved identically to #9: the `WIZARD_TEMPLATE_SHA` env var removes the need for any git-history introspection at all. |

## Verification

Full automated verification from the plan's `<verify><automated>` block passed on first run:

```
$ bash tests/phase-08/test_canonical_byte_equality.sh
PASS: MANUAL-06 byte-equality

$ bash tests/phase-08/run.sh 2>&1 | grep -qE 'PHASE 08 TESTS: 21/21'
(exit 0)

$ python3 -c "import yaml; yaml.safe_load(open('.github/workflows/setup-parity.yml'))"
(exit 0)

$ ! grep -q 'fetch-depth' .github/workflows/setup-parity.yml
(exit 0)

$ ! grep -q 'test_canonical_byte_equality\.sh' .github/workflows/setup-parity.yml
(exit 0)

$ grep -q 'name: Setup Parity' .github/workflows/setup-parity.yml
(exit 0)

$ bash bin/check-neutrality.sh
(exit 0)

$ bash tests/phase-07/run.sh 2>&1 | tail -1
PHASE 07 TESTS: 22/22
```

All 9 checks pass.

## Task Commits

1. **Task 1: MANUAL-06 byte-equality test + setup-parity CI workflow** — `5458bea` (feat)

## Requirements Coverage (Phase 8 end-state)

With Plan 05 landed, all Phase 8 wizard + manual-track requirements are complete:

| REQ-ID | Coverage |
|--------|----------|
| WZRD-01 | Plan 02 — `bin/init-wizard.sh` exists + usage |
| WZRD-02 | Plan 02 — D-13 semantic-group explainers |
| WZRD-03 | Plan 03 — `.wizard-answers.yaml` shape + keys |
| WZRD-04 | Plan 02 — `--answers-file` validation (D-17 error shape) |
| WZRD-05 | Plan 02 — idempotency refusal (exit 4) |
| WZRD-06 | Plan 03 — deterministic re-render (env vars) |
| WZRD-07 | Plan 02 — `--render-to` + canonical byte-equality |
| WZRD-08 | Plan 02 — `--render-to` completion summary |
| WZRD-09 | Plan 02 — pre-flight exit 3 + docs pointer |
| WZRD-10 | Plan 03 — decision record schema conformance |
| WZRD-11 | Plan 02 — `--dry-run` diff output |
| MANUAL-01..05 | Plan 04 — manual-setup.md equivalence, checklist, file list, copy-not-edit, inline templates |
| **MANUAL-06** | **Plan 05 (this plan) — byte-equality CI gate** |

## Operator Action Required (Post-Merge, One-Time)

After this plan is merged to the public template repo, the operator must add `setup-parity` to the branch-protection required-status-checks list:

1. Public repo → **Settings → Branches → Branch protection rule for `main`**
2. Check: `[x] Require status checks to pass before merging`
3. Add: `setup-parity` (appears in the dropdown after the first PR triggers the workflow)

Same mechanism as Phase 7's `neutrality` check. Flagged here per the plan's §4 "Note for execute-phase summary" requirement.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 — Blocker] Literal `fetch-depth` + `test_canonical_byte_equality.sh` tokens in workflow comments broke the plan's acceptance checks**
- **Found during:** Task 1 self-verification (`! grep -q 'fetch-depth' .github/workflows/setup-parity.yml` failed because the plan's sample workflow had `# Default fetch-depth.` and `# Do NOT run it separately …` comments referencing the literal strings).
- **Issue:** The plan's acceptance criteria use strict `! grep -q <literal>` single-pattern checks that treat any occurrence — including comments — as a failure. The plan's own template YAML included both tokens in comments.
- **Fix:** Rewrote the relevant comments to use semantically equivalent phrasing: `shallow-clone depth` instead of `fetch-depth`, and `MANUAL-06 byte-equality test` instead of `test_canonical_byte_equality.sh`. No behavioral change — the workflow runs identically.
- **Files modified:** `.github/workflows/setup-parity.yml`
- **Commit:** `5458bea`
- **Verified:** `! grep -q 'fetch-depth' .github/workflows/setup-parity.yml` exit 0; `! grep -q 'test_canonical_byte_equality\.sh' .github/workflows/setup-parity.yml` exit 0.

### Deferred / Out of Scope

None. Plan 05 scope was tightly bounded to 1 test + 1 workflow.

## Authentication Gates

None.

## Phase 8 Final Status

With Plan 05 complete:

- Wizard track (`bin/init-wizard.sh`): operational, 5-artifact write, staging-dir pattern, 3 guardrails on `update_index_md()`, determinism env vars.
- Manual track (`docs/manual-setup.md`): self-contained, copy-not-edit flow, inline decision-record heredoc, byte-equivalent output claim.
- Byte-equality CI gate (`.github/workflows/setup-parity.yml`): live, PR hard gate + push advisory, required check `setup-parity`.
- Phase 8 aggregator: `PHASE 08 TESTS: 21/21`.
- Phase 7 regression: `PHASE 07 TESTS: 22/22`.
- Neutrality gate: clean.
- Zero new runtime dependencies.

Phase 8 ready for transition/verification; no open blockers; operator branch-protection wiring is the only remaining one-time manual action on the public template repo.

## Self-Check: PASSED

Files verified on disk:
- `tests/phase-08/test_canonical_byte_equality.sh` — FOUND (executable)
- `.github/workflows/setup-parity.yml` — FOUND (valid YAML)

Commit verified in git log:
- `5458bea` (Task 1: MANUAL-06 byte-equality test + setup-parity CI workflow) — FOUND

Final verification commands:
- `bash tests/phase-08/test_canonical_byte_equality.sh` → `PASS: MANUAL-06 byte-equality`, exit 0
- `bash tests/phase-08/run.sh` → `PHASE 08 TESTS: 21/21`, exit 0
- `bash tests/phase-07/run.sh` → `PHASE 07 TESTS: 22/22`, exit 0
- `bash bin/check-neutrality.sh` → exit 0
- `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/setup-parity.yml'))"` → exit 0
- `! grep -q 'fetch-depth' .github/workflows/setup-parity.yml` → exit 0
- `! grep -q 'test_canonical_byte_equality\.sh' .github/workflows/setup-parity.yml` → exit 0

---
*Phase: 08-two-track-setup-wizard-manual*
*Completed: 2026-04-16*
