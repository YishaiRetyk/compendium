---
phase: 08-two-track-setup-wizard-manual
plan: 05
type: execute
wave: 3
depends_on:
  - 08-03-wizard-side-effects-PLAN.md
  - 08-04-manual-track-and-docs-PLAN.md
files_modified:
  - .github/workflows/setup-parity.yml
  - tests/phase-08/test_canonical_byte_equality.sh
autonomous: true
requirements:
  - MANUAL-06
must_haves:
  truths:
    - "tests/phase-08/test_canonical_byte_equality.sh exists under tests/phase-08/test_*.sh naming so it is picked up by the aggregator, and verifies wizard --render-to output is byte-equal to schema/fixtures/canonical-AGENTS.md"
    - ".github/workflows/setup-parity.yml runs on PR + push to main, executing the Phase 08 aggregator (which INCLUDES test_canonical_byte_equality.sh) on ubuntu-latest with python3 + PyYAML installed"
    - "Workflow runs the aggregator ONLY — not both the aggregator AND the byte-equality test separately (review concern #7: no duplicate invocation)"
    - "Aggregator count after Plan 05 lands: PHASE 08 TESTS: 21/21 (13 from Plan 03 + 7 from Plan 04 + 1 new byte-equality test = 21) per review concern #7"
    - "Workflow does NOT rely on fetch-depth: 2 for git log -1 template_sha resolution (review concerns #9 + #10): env var WIZARD_TEMPLATE_SHA is set explicitly in the workflow, making the git-history fallback unnecessary. Default fetch-depth is used."
    - "Determinism env vars (WIZARD_GENERATED_AT, WIZARD_TEMPLATE_SHA) are set in the workflow to freeze the .wizard-answers.yaml fixture comparison"
    - "Workflow emits a concise failure-recovery message on byte-equality drift pointing contributors at schema/fixtures/README.md's regeneration command"
  artifacts:
    - path: .github/workflows/setup-parity.yml
      provides: "GitHub Actions workflow gating wizard/manual byte-equality"
      contains: "actions/checkout@v6"
    - path: tests/phase-08/test_canonical_byte_equality.sh
      provides: "MANUAL-06 byte-equality test (included in aggregator; also runnable standalone)"
  key_links:
    - from: .github/workflows/setup-parity.yml
      to: tests/phase-08/run.sh
      via: "workflow invokes the aggregator (which includes test_canonical_byte_equality.sh)"
      pattern: "tests/phase-08/run\\.sh"
    - from: tests/phase-08/test_canonical_byte_equality.sh
      to: schema/fixtures/canonical-AGENTS.md
      via: "cmp -s wizard render against fixture"
      pattern: "canonical-AGENTS\\.md"
---

<objective>
Land the MANUAL-06 byte-equality CI test and its dedicated GitHub Actions workflow. This is the mechanical drift-prevention gate (M-1/M-3 per RESEARCH.md): every PR runs the wizard against `schema/fixtures/canonical-answers.yaml` and `cmp -s` the rendered AGENTS.md against the committed `schema/fixtures/canonical-AGENTS.md`. Drift = red CI = blocked PR.

Purpose: Closes the Phase 8 success criteria. Without this gate, the wizard and manual-setup.md can silently diverge; with it, any change to `schema/AGENTS.template.md`, the wizard, or the canonical fixtures forces a deliberate fixture regeneration commit (see schema/fixtures/README.md for the regeneration command).

Output: 1 GitHub Actions workflow + 1 phase-08 test (included in the aggregator, not run separately).
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/STATE.md
@.planning/phases/08-two-track-setup-wizard-manual/08-CONTEXT.md
@.planning/phases/08-two-track-setup-wizard-manual/08-RESEARCH.md
@.planning/phases/08-two-track-setup-wizard-manual/08-01-test-harness-and-fixtures-PLAN.md
@.planning/phases/08-two-track-setup-wizard-manual/08-03-wizard-side-effects-PLAN.md
@.planning/phases/08-two-track-setup-wizard-manual/08-04-manual-track-and-docs-PLAN.md
@.github/workflows/neutrality.yml
@bin/init-wizard.sh
@bin/sync-claude.sh
@schema/fixtures/canonical-answers.yaml
@schema/fixtures/canonical-AGENTS.md
@schema/fixtures/README.md
@tests/phase-08/lib.sh
@tests/phase-08/run.sh

<interfaces>
<!-- Workflow contract (mirrors .github/workflows/neutrality.yml structure) -->
- name: "Setup Parity (Wizard ↔ Manual Byte-Equality)"
- triggers: pull_request, push to main (advisory on push, hard gate on PR per Phase 7's enforcement model)
- job: setup-parity, runs-on: ubuntu-latest
- steps:
  1. actions/checkout@v6 (default fetch-depth; review concerns #9/#10 — env var is authoritative, no fetch-depth manipulation needed)
  2. actions/setup-python@v6 with python-version: '3.12'
  3. pip install pyyaml
  4. Set WIZARD_GENERATED_AT + WIZARD_TEMPLATE_SHA env vars (determinism; makes the wizard's git-log template_sha fallback unnecessary)
  5. Run full Phase 8 aggregator (includes test_canonical_byte_equality.sh): `bash tests/phase-08/run.sh`
     — NOTE (review concern #7): the workflow runs the aggregator ONLY. It does NOT separately run test_canonical_byte_equality.sh after the aggregator; the aggregator already picks it up via the tests/phase-08/test_*.sh glob.
  6. Run Phase 7 aggregator (regression): `bash tests/phase-07/run.sh`
  7. Run Neutrality gate (regression): `bash bin/check-neutrality.sh`

<!-- Test contract -->
tests/phase-08/test_canonical_byte_equality.sh:
- Uses mktemp_repo from lib.sh
- Sets WIZARD_GENERATED_AT=2026-04-16T00:00:00Z + WIZARD_TEMPLATE_SHA=<frozen-fixture> (matching canonical-answers.yaml's template_sha)
- Invokes: bash bin/init-wizard.sh --answers-file schema/fixtures/canonical-answers.yaml --render-to "$WORK"
- Asserts: cmp -s "$WORK/AGENTS.md" schema/fixtures/canonical-AGENTS.md (byte-equal)
- Asserts: cmp -s "$WORK/AGENTS.md" "$WORK/CLAUDE.md" (sync byte-equal)
- Asserts: existence of $WORK/.wizard-answers.yaml + $WORK/wiki/decisions/dr-2026-04-16-initial-setup.md
- On failure: prints clear message pointing at schema/fixtures/README.md's regeneration command
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Write tests/phase-08/test_canonical_byte_equality.sh and .github/workflows/setup-parity.yml</name>
  <files>tests/phase-08/test_canonical_byte_equality.sh, .github/workflows/setup-parity.yml</files>
  <read_first>
    - .github/workflows/neutrality.yml (full file — workflow structure to mirror, including the enforcement-model comment block)
    - tests/phase-08/lib.sh
    - bin/init-wizard.sh (verify --render-to + WIZARD_GENERATED_AT env var contract from Plan 03)
    - schema/fixtures/canonical-answers.yaml (verify the template_sha value to use as WIZARD_TEMPLATE_SHA)
    - schema/fixtures/canonical-AGENTS.md (the byte-frozen target)
    - schema/fixtures/README.md (Plan 01 — the regeneration command to reference in failure messages)
    - .planning/phases/08-two-track-setup-wizard-manual/08-RESEARCH.md §Open Question Q3 + §Pitfall 8
  </read_first>
  <behavior>
    - Local invocation `bash tests/phase-08/test_canonical_byte_equality.sh` exits 0 with the wizard's render byte-equal to the canonical fixture.
    - GitHub Actions workflow `.github/workflows/setup-parity.yml` runs on PR + push to main, sets up python3 3.12 + PyYAML, sets determinism env vars, and executes the Phase 7 + Phase 8 aggregators (Phase 8 aggregator includes test_canonical_byte_equality.sh).
    - Workflow does NOT manipulate fetch-depth; env var WIZARD_TEMPLATE_SHA is authoritative (review concerns #9 + #10).
    - Workflow runs the aggregator ONLY, no duplicate invocation of test_canonical_byte_equality.sh (review concern #7).
    - Aggregator final count: `PHASE 08 TESTS: 21/21` (13 from Plan 03 + 7 from Plan 04 + 1 from this plan = 21).
  </behavior>
  <action>

### 1. tests/phase-08/test_canonical_byte_equality.sh

Write this exact test (LF line endings, executable). The file name follows the `test_*.sh` convention so `tests/phase-08/run.sh`'s glob picks it up — no separate invocation needed (review concern #7):

```bash
#!/usr/bin/env bash
# tests/phase-08/test_canonical_byte_equality.sh -- MANUAL-06
# Renders bin/init-wizard.sh against schema/fixtures/canonical-answers.yaml and
# asserts byte-equality vs schema/fixtures/canonical-AGENTS.md.
# This is THE drift-prevention gate (M-1/M-3 mitigation per RESEARCH.md Pitfall 1).
#
# On failure, regenerate the fixture via the wizard's render routine:
#   bash bin/init-wizard.sh --answers-file schema/fixtures/canonical-answers.yaml --render-to /tmp/wz-regen
#   cp /tmp/wz-regen/AGENTS.md schema/fixtures/canonical-AGENTS.md
# See schema/fixtures/README.md for the full regeneration procedure.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

echo "TEST: MANUAL-06 wizard ↔ canonical-AGENTS.md byte-equality"

WORK="$(mktemp_repo)"

# Freeze time + template SHA so .wizard-answers.yaml is reproducible.
# Values must match schema/fixtures/canonical-answers.yaml metadata.
export WIZARD_GENERATED_AT="2026-04-16T00:00:00Z"
export WIZARD_TEMPLATE_SHA="<frozen-fixture>"

bash "$REPO_ROOT/bin/init-wizard.sh" \
    --answers-file "$REPO_ROOT/schema/fixtures/canonical-answers.yaml" \
    --render-to "$WORK"

# 1. AGENTS.md byte-equal to fixture
if ! cmp -s "$WORK/AGENTS.md" "$REPO_ROOT/schema/fixtures/canonical-AGENTS.md"; then
    echo "FAIL: canonical-AGENTS.md drift detected." >&2
    echo "" >&2
    echo "To regenerate the fixture (intentional drift after template change):" >&2
    echo "  bash bin/init-wizard.sh --answers-file schema/fixtures/canonical-answers.yaml --render-to /tmp/wz-regen" >&2
    echo "  cp /tmp/wz-regen/AGENTS.md schema/fixtures/canonical-AGENTS.md" >&2
    echo "  git add schema/fixtures/canonical-AGENTS.md && git commit -m 'fixtures: regenerate canonical-AGENTS.md after template change'" >&2
    echo "" >&2
    echo "See schema/fixtures/README.md for details." >&2
    echo "" >&2
    echo "Diff (first 50 lines):" >&2
    diff -u "$REPO_ROOT/schema/fixtures/canonical-AGENTS.md" "$WORK/AGENTS.md" | head -50 >&2
    exit 1
fi

# 2. CLAUDE.md byte-equal to AGENTS.md (sync-claude contract)
assert_byte_equal "$WORK/AGENTS.md" "$WORK/CLAUDE.md"

# 3. .wizard-answers.yaml exists and has the 6 expected keys
assert_file_exists "$WORK/.wizard-answers.yaml"
python3 -c "
import yaml, sys
d = yaml.safe_load(open('$WORK/.wizard-answers.yaml'))
expected = {'maintainer_name', 'primary_domain', 'agent', 'default_privacy', 'decay_profile', 'obsidian'}
got = set(d.get('answers', {}).keys())
if got != expected:
    print(f'FAIL: answer keys mismatch. expected={expected} got={got}', file=sys.stderr)
    sys.exit(1)
"

# 4. Decision record exists at deterministic path
assert_file_exists "$WORK/wiki/decisions/dr-2026-04-16-initial-setup.md"

# 5. wiki/index.md edited with exactly one ## Decisions heading
assert_file_exists "$WORK/wiki/index.md"
assert_grep '^## Decisions$' "$WORK/wiki/index.md" "Decisions subsection in index.md"
[ "$(grep -c '^## Decisions$' "$WORK/wiki/index.md")" -eq 1 ] || { echo "FAIL: expected exactly one ## Decisions heading"; exit 1; }

echo "PASS: MANUAL-06 byte-equality"
exit 0
```

`chmod +x tests/phase-08/test_canonical_byte_equality.sh`.

### 2. .github/workflows/setup-parity.yml

Write this exact workflow file (mirroring neutrality.yml's structure). Review concerns #7, #9, #10 addressed: no duplicate invocation of the byte-equality test, no `fetch-depth: 2`, env var WIZARD_TEMPLATE_SHA is authoritative:

```yaml
# Phase 8 MANUAL-06: wizard ↔ manual-setup.md byte-equality CI gate.
#
# ENFORCEMENT MODEL (mirrors .github/workflows/neutrality.yml):
#   - `pull_request` is the HARD GATE. Branch protection rules on the public
#     repo MUST require passing runs of this workflow on PR before merging.
#     Required check name: `setup-parity`.
#   - `push` to `main` is ADVISORY ONLY (post-merge visibility).
#
# What this gates:
#   The wizard (bin/init-wizard.sh) and the manual track (docs/manual-setup.md)
#   MUST produce a byte-identical AGENTS.md when fed the canonical answer set
#   (schema/fixtures/canonical-answers.yaml). Drift = red CI = blocked PR.
#   On drift, regenerate the fixture: see schema/fixtures/README.md.
#
# Determinism:
#   WIZARD_TEMPLATE_SHA env var is authoritative — the wizard's internal
#   git-log fallback is therefore unused, so no fetch-depth manipulation needed.
name: Setup Parity (Wizard ↔ Manual Byte-Equality)

on:
  pull_request:
  # Advisory only -- see enforcement model note above.
  push:
    branches: [main]

jobs:
  setup-parity:
    runs-on: ubuntu-latest
    env:
      # Freeze time + template SHA so the test's .wizard-answers.yaml comparison
      # is reproducible. These match schema/fixtures/canonical-answers.yaml.
      WIZARD_GENERATED_AT: "2026-04-16T00:00:00Z"
      WIZARD_TEMPLATE_SHA: "<frozen-fixture>"
    steps:
      - uses: actions/checkout@v6
        # Default fetch-depth. WIZARD_TEMPLATE_SHA env var makes the wizard's
        # git-log template_sha fallback unnecessary, so no fetch-depth: 2
        # manipulation is needed.
      - uses: actions/setup-python@v6
        with:
          python-version: '3.12'
      - name: Install PyYAML
        run: pip install pyyaml
      - name: Verify wizard exists + executable
        run: test -x bin/init-wizard.sh
      - name: Phase 8 full test suite (includes test_canonical_byte_equality.sh)
        # NOTE: The aggregator picks up tests/phase-08/test_*.sh via glob,
        # so test_canonical_byte_equality.sh runs as part of this invocation.
        # Do NOT run it separately — that would duplicate the work and confuse
        # failure attribution.
        run: bash tests/phase-08/run.sh
      - name: Phase 7 regression test suite
        run: bash tests/phase-07/run.sh
      - name: Neutrality gate (regression)
        run: bash bin/check-neutrality.sh
```

### 3. Verify

- `bash tests/phase-08/run.sh` exits 0 with `PHASE 08 TESTS: 21/21`.
- `bash tests/phase-08/test_canonical_byte_equality.sh` exits 0 standalone (also works independently for local debugging).
- `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/setup-parity.yml'))"` exits 0 (valid YAML).
- `grep -q 'setup-parity' .github/workflows/setup-parity.yml` (job name matches required-check expectation).
- `! grep -q 'fetch-depth' .github/workflows/setup-parity.yml` (review concerns #9 + #10 — no fetch-depth manipulation).
- Workflow has exactly ONE invocation of `tests/phase-08/test_canonical_byte_equality.sh` (via the aggregator glob) — i.e., the literal path string does not appear as a workflow run step: `! grep -q 'test_canonical_byte_equality\.sh' .github/workflows/setup-parity.yml` (review concern #7).
- `bash bin/check-neutrality.sh && bash tests/phase-07/run.sh` exit 0.

### 4. Note for execute-phase summary

After this plan completes, the operator must (manually, in GitHub UI) add `setup-parity` to the public repo's branch-protection required-status-checks list — same model as Phase 7's `neutrality` check. This is a one-time GitHub UI action; flag in the SUMMARY.md.
  </action>
  <verify>
    <automated>bash tests/phase-08/test_canonical_byte_equality.sh && bash tests/phase-08/run.sh && bash tests/phase-08/run.sh 2>&1 | grep -qE 'PHASE 08 TESTS: 21/21' && python3 -c "import yaml; yaml.safe_load(open('.github/workflows/setup-parity.yml'))" && ! grep -q 'fetch-depth' .github/workflows/setup-parity.yml && ! grep -q 'test_canonical_byte_equality\.sh' .github/workflows/setup-parity.yml && grep -q 'name: Setup Parity' .github/workflows/setup-parity.yml && bash bin/check-neutrality.sh && bash tests/phase-07/run.sh</automated>
  </verify>
  <acceptance_criteria>
    - `tests/phase-08/test_canonical_byte_equality.sh` exists, executable, exits 0 standalone with `PASS: MANUAL-06 byte-equality` in stdout.
    - The dedicated test's failure message (when the fixture drifts) includes literal `schema/fixtures/README.md` and a `bin/init-wizard.sh --answers-file ... --render-to` command for easy recovery.
    - `bash tests/phase-08/run.sh` exits 0 with `PHASE 08 TESTS: 21/21` in stdout (reconciled per review concern #7: 13 from Plan 03 + 7 from Plan 04 + 1 from this plan).
    - `.github/workflows/setup-parity.yml` exists, parses as valid YAML, contains `name: Setup Parity`, `runs-on: ubuntu-latest`, `actions/checkout@v6`, `actions/setup-python@v6`, env vars `WIZARD_GENERATED_AT` and `WIZARD_TEMPLATE_SHA`, and a single step invoking `bash tests/phase-08/run.sh`.
    - **Review concern #7:** the workflow does NOT separately invoke `tests/phase-08/test_canonical_byte_equality.sh` — the aggregator picks it up via glob. Verify: `! grep -q 'test_canonical_byte_equality\.sh' .github/workflows/setup-parity.yml`.
    - **Review concerns #9 + #10:** workflow does NOT contain `fetch-depth`. Verify: `! grep -q 'fetch-depth' .github/workflows/setup-parity.yml`.
    - Workflow's `on:` triggers include both `pull_request` and `push` (with `branches: [main]`).
    - `bash bin/check-neutrality.sh` exits 0 (no Kahneman tokens in workflow or test).
    - `bash tests/phase-07/run.sh` exits 0 (no regression).
  </acceptance_criteria>
  <done>MANUAL-06 byte-equality test landed under tests/phase-08/test_*.sh (picked up by aggregator, NOT invoked separately per review concern #7); dedicated CI workflow committed without fetch-depth manipulation (review concerns #9 + #10); Phase 8 aggregator at 21/21 (reconciled per review concern #7); ready for branch-protection wiring on the public template repo.</done>
</task>

</tasks>

<verification>
1. `bash tests/phase-08/test_canonical_byte_equality.sh` exits 0 standalone.
2. `bash tests/phase-08/run.sh` exits 0 with `PHASE 08 TESTS: 21/21`.
3. `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/setup-parity.yml'))"` exits 0.
4. `! grep -q 'fetch-depth' .github/workflows/setup-parity.yml` (review concerns #9 + #10).
5. `! grep -q 'test_canonical_byte_equality\.sh' .github/workflows/setup-parity.yml` (review concern #7 — no duplicate invocation).
6. Workflow file structurally mirrors `.github/workflows/neutrality.yml`'s enforcement model (PR hard gate + push advisory).
7. `bash bin/check-neutrality.sh && bash tests/phase-07/run.sh` exit 0.
</verification>

<success_criteria>
- MANUAL-06 byte-equality test in place; CI gate active on PRs.
- Phase 8 aggregator at 21/21 reconciled count (review concern #7 addressed: 13 + 7 + 1).
- Workflow runs aggregator ONLY (no duplicate test invocation per review concern #7).
- Workflow avoids fetch-depth manipulation; env var WIZARD_TEMPLATE_SHA is authoritative (review concerns #9 + #10).
- Byte-equality failure message points contributors at the regeneration command in schema/fixtures/README.md.
- Operator next step (branch-protection wiring) flagged in summary.
- Zero new runtime dependencies; no Kahneman regression.
</success_criteria>

<output>
After completion, create `.planning/phases/08-two-track-setup-wizard-manual/08-05-SUMMARY.md` capturing: the test invocation flags, the workflow's required-check name (`setup-parity`), the operator action needed (add `setup-parity` to branch-protection required checks on the public repo), final aggregator count `PHASE 08 TESTS: 21/21`, the requirement coverage summary (WZRD-01..11 + MANUAL-01..06 all green), and the review-concern resolution summary (#7 aggregator math + no duplicate invocation, #9 + #10 no fetch-depth).
</output>
