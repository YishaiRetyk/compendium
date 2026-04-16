---
phase: 09-collaborative-pr-workflow-ci-lint-gate
plan: 05
type: execute
wave: 3
depends_on: [09-02, 09-03, 09-04]
files_modified:
  - .github/workflows/lint.yml
  - .github/scripts/json-to-annotations.py
  - .github/pull_request_template.md
  - AGENTS.md
  - CLAUDE.md
  - tests/phase-09/test_lint_workflow.sh
  - tests/phase-09/test_annotation_shim.sh
  - tests/phase-09/test_pr_template.sh
  - tests/phase-09/test_agents_section_11_1.sh
  - tests/phase-09/test_agents_section_11_3.sh
  - tests/phase-09/test_agents_section_12.sh
autonomous: true
requirements:
  - CI-01
  - CI-05
  - COLAB-02
  - COLAB-03

must_haves:
  truths:
    - "`.github/workflows/lint.yml` exists with three independent parallel jobs (`lint`, `privacy-leak`, `strict`); each uses `actions/checkout@v6` + `actions/setup-python@v6` + `pip install pyyaml` on `ubuntu-latest` (matches Phase 7/8 baseline)."
    - "The `strict` job runs with `fetch-depth: 0` on checkout (D-10 / CI-06 needs full history for `git diff origin/main...HEAD`) and uses `if: github.event.pull_request.draft == false || github.event_name == 'push'` (D-07 draft-skip)."
    - "The `lint` job runs `bash bin/lint.sh --require-version 1.1.0 --ci --format json > /tmp/lint.json`, then converts JSON to `::error file=...,line=...::` / `::warning` / `::notice` annotations via `.github/scripts/json-to-annotations.py`, then fails if the lint step recorded an error (continue-on-error pattern)."
    - "The `privacy-leak` job runs `bash bin/check-privacy.sh` as its sole step; exits 2 blocks the PR (CI-07)."
    - "`.github/pull_request_template.md` has 6 sections per D-29 structure: `## Summary`, `## Ingest type` (checkboxes), `## Source attribution`, `## Privacy review`, `## Lint` (with collapsible output block), `## Expected findings (optional)`."
    - "AGENTS.md §11.1 (ingest workflow) is amended with a `--contributor` auto-detect step referencing `.git-author-map.txt`. AGENTS.md §11.3 (lint workflow) gains a `CI mode` subsection documenting `--ci`, `--format json`, `--strict`, the escape-hatch marker syntax, and `--require-version`. AGENTS.md §12 gains documentation of the `contributor:: @handle` Dataview inline field (COLAB-03)."
    - "CLAUDE.md is byte-identical to AGENTS.md after amendments (Phase 7 pre-commit hook enforces; `bash bin/sync-claude.sh --check` exits 0)."
    - "The annotation shim emits `::notice` for `info` severity (not `::info` — GitHub's workflow commands use `notice` as the lowest tier)."
  artifacts:
    - path: ".github/workflows/lint.yml"
      provides: "CI workflow with three parallel jobs; enforcement-model comment block matching neutrality.yml"
      contains: "jobs:"
    - path: ".github/scripts/json-to-annotations.py"
      provides: "JSON → GitHub annotations shim (CI-05)"
      contains: "::error"
    - path: ".github/pull_request_template.md"
      provides: "COLAB-02 6-section PR template"
      contains: "## Summary"
    - path: "AGENTS.md"
      provides: "§11.1 --contributor amendment; §11.3 CI-mode subsection; §12 contributor:: inline field documentation"
      contains: "contributor::"
    - path: "CLAUDE.md"
      provides: "Byte-identical sync after AGENTS.md amendments"
      contains: "contributor::"
  key_links:
    - from: ".github/workflows/lint.yml lint job"
      to: "bin/lint.sh --require-version 1.1.0 --ci --format json"
      via: "bash step invocation"
      pattern: "bin/lint\\.sh"
    - from: ".github/workflows/lint.yml privacy-leak job"
      to: "bin/check-privacy.sh"
      via: "bash step invocation"
      pattern: "bin/check-privacy\\.sh"
    - from: ".github/workflows/lint.yml strict job"
      to: "bin/lint.sh --require-version 1.1.0 --strict"
      via: "bash step invocation (fetch-depth: 0 required)"
      pattern: "fetch-depth: 0"
    - from: ".github/scripts/json-to-annotations.py"
      to: "/tmp/lint.json produced by lint step"
      via: "python3 stdin argv[1] read"
      pattern: "::error|::warning|::notice"
    - from: "AGENTS.md §12"
      to: "CLAUDE.md §12"
      via: "bin/sync-claude.sh byte-identical copy (Phase 7 pre-commit hook)"
      pattern: "contributor::"
---

<objective>
Ship the **integration layer** that wires Plans 02/03/04's primitives into a working CI gate:

1. **`.github/workflows/lint.yml`** — three parallel jobs (`lint`, `privacy-leak`, `strict`) calling the scripts Plans 02–04 built. Pattern-twin of Phase 7 `neutrality.yml` + Phase 8 `setup-parity.yml`.
2. **`.github/scripts/json-to-annotations.py`** — JSON → `::error file=...::` annotation shim (CI-05).
3. **`.github/pull_request_template.md`** — D-29 6-section PR template (COLAB-02).
4. **AGENTS.md §§11.1/11.3/12 amendments** — canonical schema documentation for `--contributor` (§11.1), CI mode + escape-hatch markers (§11.3), and `contributor:: @handle` inline field (§12 / COLAB-03). CLAUDE.md auto-syncs via `bin/sync-claude.sh` (Phase 7 hook).

Purpose: Plans 02/03/04 built the **mechanisms**; this plan turns those mechanisms into a live CI gate and documents the schema decisions in AGENTS.md so agents of any flavor (Claude, Codex, Gemini) follow the same rules. Without Plan 05, the scripts exist but the required-check names (`lint`, `privacy-leak`, `strict`) don't fire on PR.

Output: CI workflow + annotation script + PR template + AGENTS.md/CLAUDE.md amendments + 6 tests. Plan 06 then documents these from the user's POV (CONTRIBUTING.md + docs/reference/ci.md).

Out of scope: CONTRIBUTING.md (Plan 06), docs/reference/ci.md full populate (Plan 06), multi-provider CI equivalents (Plan 06).
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-CONTEXT.md
@.planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-RESEARCH.md
@.planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-02-SUMMARY.md
@.planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-03-SUMMARY.md
@.planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-04-SUMMARY.md
@.github/workflows/neutrality.yml
@.github/workflows/setup-parity.yml
@AGENTS.md
@CLAUDE.md
@bin/sync-claude.sh

<interfaces>
From RESEARCH.md Code Example #7 (canonical workflow skeleton — copy verbatim, adjust step names as needed):

```yaml
# ENFORCEMENT MODEL (mirrors .github/workflows/neutrality.yml):
#   - pull_request is HARD GATE (branch protection required check).
#   - push to main is ADVISORY ONLY (post-merge visibility).
#
# Required check names (operator sets in Settings → Branches):
#   lint, privacy-leak, strict (alongside existing neutrality, setup-parity)

name: Lint + Privacy + Strict
on:
  pull_request:
  push:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: actions/setup-python@v6
        with: { python-version: '3.12' }
      - run: pip install pyyaml
      - name: Lint (CI mode + JSON, pinned version)
        id: lint_run
        run: bash bin/lint.sh --require-version 1.1.0 --ci --format json > /tmp/lint.json
        continue-on-error: true
      - name: Convert JSON findings to GitHub annotations
        run: python3 .github/scripts/json-to-annotations.py /tmp/lint.json
      - name: Fail on error-severity findings
        if: steps.lint_run.outcome == 'failure'
        run: exit 1

  privacy-leak:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: actions/setup-python@v6
        with: { python-version: '3.12' }
      - run: pip install pyyaml
      - name: Privacy-leak guard (CI-07)
        run: bash bin/check-privacy.sh

  strict:
    if: github.event.pull_request.draft == false || github.event_name == 'push'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
        with:
          fetch-depth: 0
      - uses: actions/setup-python@v6
        with: { python-version: '3.12' }
      - run: pip install pyyaml
      - name: Strict quality ratchet (CI-06)
        run: bash bin/lint.sh --require-version 1.1.0 --strict
```

From RESEARCH.md Code Example #2 (annotation shim — logic to inline in Python script):

```python
# Severity mapping: error, warning, info → GitHub workflow commands: error, warning, notice
cmd = {'error': 'error', 'warning': 'warning', 'info': 'notice'}.get(sev, 'notice')
parts = [f"file={item['path']}"]
if 'line' in item and item['line']:
    parts.append(f"line={item['line']}")
attrs = ','.join(parts)
msg = item['message'].replace('\r', '%0D').replace('\n', '%0A')
print(f"::{cmd} {attrs}::{msg}")
```

Plus annotation cap handling (research Open Question #2): sort errors first, trailing "N more" notice if over the cap.

From CONTEXT.md D-29 PR template structure (6 sections listed verbatim).

From AGENTS.md current state (to amend):
- §11.1 Ingest Workflow (around line 1175-1206) — current steps 1-10
- §11.3 Lint Workflow (around line 1319-1368) — current text
- §12 Index and Log (around line 1446-1516) — current log entry format section
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Create .github/workflows/lint.yml (3 parallel jobs) + .github/scripts/json-to-annotations.py shim + workflow/annotation tests</name>
  <files>.github/workflows/lint.yml, .github/scripts/json-to-annotations.py, tests/phase-09/test_lint_workflow.sh, tests/phase-09/test_annotation_shim.sh</files>
  <read_first>
    - .github/workflows/neutrality.yml — enforcement-model comment block (verbatim reference for header)
    - .github/workflows/setup-parity.yml — three-step scaffold pattern
    - .planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-CONTEXT.md — D-16 (three jobs, no needs: edges), D-17 (required-check names), D-18 (push advisory), D-07 (strict draft-skip)
    - .planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-RESEARCH.md — §"Code Examples" #7 (full workflow skeleton), Open Question #2 (annotation cap handling)
    - tests/phase-09/lib.sh
  </read_first>
  <behavior>
    - Test A (test_lint_workflow.sh): File `.github/workflows/lint.yml` exists; YAML parses cleanly; contains exactly three top-level jobs named `lint`, `privacy-leak`, `strict`; each job uses `runs-on: ubuntu-latest`; each job has `actions/checkout@v6` and `actions/setup-python@v6` with `python-version: '3.12'`; `pip install pyyaml` step present in all three; `strict` job contains `fetch-depth: 0`; `strict` job has `if:` expression containing `github.event.pull_request.draft` and `github.event_name`.
    - Test B (test_lint_workflow.sh — enforcement model): Workflow header contains the words `pull_request`, `HARD GATE`, `push`, `ADVISORY` (enforcement-model block matches neutrality.yml conventions).
    - Test C (test_annotation_shim.sh, error): Given a JSON file with one `error` severity finding, `python3 .github/scripts/json-to-annotations.py <json>` prints a line starting with `::error file=` and containing `line=` if the input has a line number.
    - Test D (test_annotation_shim.sh, warning): `warning` severity → `::warning`.
    - Test E (test_annotation_shim.sh, info): `info` severity → `::notice` (NOT `::info` — GitHub uses `notice` as lowest tier).
    - Test F (test_annotation_shim.sh, cap): On a JSON with 15 `error` findings, shim emits no more than 10 `::error` lines AND emits a trailing `::notice` with content containing "more" (cap handling per research Open Q2).
    - Test G (test_annotation_shim.sh, missing file): Running shim with non-existent input file exits 1 with a clear stderr error (not a python stack trace).
  </behavior>
  <action>
**Step 1: Create `.github/workflows/lint.yml`.**

Paste the workflow skeleton from RESEARCH.md Code Example #7, with these refinements:

- Header comment block (lines 1-20) verbatim following `neutrality.yml` style: enforcement-model explanation, operator-action guidance, required-check names.
- Add the cap-handling note to the `lint` job if `json-to-annotations.py` handles it internally (our implementation does; see Task 1 Step 2).
- Name the workflow: `Lint + Privacy + Strict`.

Full file content:

```yaml
# .github/workflows/lint.yml
#
# Phase 9 CI gate: lint + privacy-leak + strict quality ratchet (CI-01).
# Pattern-twin of .github/workflows/neutrality.yml + .github/workflows/setup-parity.yml.
#
# ENFORCEMENT MODEL (mirrors neutrality.yml):
#   - `pull_request` is the HARD GATE. Branch protection rules on the public
#     repo MUST require passing runs of this workflow on PR before merging.
#     This is the actual enforcement lever; the workflow itself only reports.
#     Required check names: `lint`, `privacy-leak`, `strict`.
#   - `push` to `main` is ADVISORY ONLY. Post-merge visibility; cannot prevent
#     bad code from reaching main — branch protection does that.
#
# Operator action required on the public remote:
#   Settings -> Branches -> Branch protection rule for `main`:
#     [x] Require status checks to pass before merging
#     [x] Require branches to be up to date before merging
#         Required checks: lint, privacy-leak, strict
#         (alongside existing neutrality, setup-parity)
#
# See: docs/reference/ci.md for the full severity policy, JSON output schema,
# multi-provider equivalents (GitLab / Gitea / Codeberg), privacy-leak guard
# explainer, escape-hatch marker docs, and --require-version pinning.

name: Lint + Privacy + Strict

on:
  pull_request:
  push:
    branches: [main]

jobs:
  lint:
    # CI-02 / CI-03: bin/lint.sh --ci --format json with severity remap.
    # Annotations via .github/scripts/json-to-annotations.py (CI-05).
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: actions/setup-python@v6
        with:
          python-version: '3.12'
      - name: Install PyYAML
        run: pip install pyyaml
      - name: Lint (CI mode + JSON, pinned version)
        id: lint_run
        run: bash bin/lint.sh --require-version 1.1.0 --ci --format json > /tmp/lint.json
        continue-on-error: true
      - name: Convert JSON findings to GitHub annotations
        run: python3 .github/scripts/json-to-annotations.py /tmp/lint.json
      - name: Fail on error-severity findings
        if: steps.lint_run.outcome == 'failure'
        run: exit 1

  privacy-leak:
    # CI-07: bin/check-privacy.sh scans PUBLIC_PATHS frontmatter for privacy: local_only.
    # wiki/** is excluded (valid user content per AGENTS.md §13).
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: actions/setup-python@v6
        with:
          python-version: '3.12'
      - name: Install PyYAML
        run: pip install pyyaml
      - name: Privacy-leak guard (CI-07)
        run: bash bin/check-privacy.sh

  strict:
    # CI-06: --strict quality ratchet.
    # D-07: skip on draft PRs; run on ready-for-review PRs + push to main.
    # D-10: fetch-depth: 0 for `git diff origin/main...HEAD` status-A detection.
    if: github.event.pull_request.draft == false || github.event_name == 'push'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
        with:
          fetch-depth: 0
      - uses: actions/setup-python@v6
        with:
          python-version: '3.12'
      - name: Install PyYAML
        run: pip install pyyaml
      - name: Strict quality ratchet (CI-06)
        run: bash bin/lint.sh --require-version 1.1.0 --strict
```

**Step 2: Create `.github/scripts/json-to-annotations.py`.**

```python
#!/usr/bin/env python3
# .github/scripts/json-to-annotations.py
# CI-05: convert bin/lint.sh --format json output to GitHub Actions workflow commands.
#
# Severity → command:
#   error    → ::error
#   warning  → ::warning
#   info     → ::notice      (GitHub uses 'notice' as the lowest tier, NOT 'info')
#
# Annotation cap (GitHub Docs 2026):
#   10 error + 10 warning + 50 total per job. Findings beyond the cap are
#   silently dropped from the PR UI. We sort errors first and emit a trailing
#   ::notice "N more findings — see lint.json in workflow logs" when capped.
#
# Usage: python3 .github/scripts/json-to-annotations.py <json-file>
import json
import sys

SEVERITY_CMD = {'error': 'error', 'warning': 'warning', 'info': 'notice'}
CAP_ERROR = 10
CAP_WARNING = 10
CAP_TOTAL = 50

def escape(s):
    """Per GitHub Actions: %0D for CR, %0A for LF, %25 for %."""
    return str(s).replace('%', '%25').replace('\r', '%0D').replace('\n', '%0A')

def main():
    if len(sys.argv) != 2:
        print("Usage: json-to-annotations.py <json-file>", file=sys.stderr)
        sys.exit(1)
    path = sys.argv[1]
    try:
        data = json.load(open(path))
    except FileNotFoundError:
        print(f"ERROR: findings file not found: {path}", file=sys.stderr)
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"ERROR: findings file is not valid JSON: {e}", file=sys.stderr)
        sys.exit(1)
    if not isinstance(data, list):
        print(f"ERROR: findings file must be a JSON array, got {type(data).__name__}", file=sys.stderr)
        sys.exit(1)

    # Sort: errors first, then warnings, then info — preserves most-important
    # findings when annotations are capped.
    severity_order = {'error': 0, 'warning': 1, 'info': 2}
    data.sort(key=lambda i: severity_order.get(i.get('severity', 'info'), 3))

    emitted_error = 0
    emitted_warning = 0
    emitted_total = 0
    dropped = 0
    for item in data:
        sev = item.get('severity', 'info')
        cmd = SEVERITY_CMD.get(sev, 'notice')
        # Per-severity caps
        if sev == 'error' and emitted_error >= CAP_ERROR:
            dropped += 1; continue
        if sev == 'warning' and emitted_warning >= CAP_WARNING:
            dropped += 1; continue
        if emitted_total >= CAP_TOTAL:
            dropped += 1; continue
        parts = []
        if item.get('path'):
            parts.append(f"file={escape(item['path'])}")
        if item.get('line'):
            parts.append(f"line={escape(item['line'])}")
        attrs = ','.join(parts)
        msg = escape(item.get('message', ''))
        # Include category in message for reviewer context
        cat = item.get('category', '')
        if cat:
            msg = f"[{cat}] {msg}"
        print(f"::{cmd} {attrs}::{msg}")
        if sev == 'error': emitted_error += 1
        elif sev == 'warning': emitted_warning += 1
        emitted_total += 1
    if dropped > 0:
        print(f"::notice::{dropped} more findings dropped from PR annotations (GitHub cap: "
              f"{CAP_ERROR} error + {CAP_WARNING} warning + {CAP_TOTAL} total per job). "
              f"See full lint output in workflow logs.")

if __name__ == '__main__':
    main()
```

Mark executable: `chmod +x .github/scripts/json-to-annotations.py`.

**Step 3: Write two tests.**

`tests/phase-09/test_lint_workflow.sh`:

```bash
#!/usr/bin/env bash
# CI-01: .github/workflows/lint.yml exists with three parallel jobs;
# uses v6 actions + ubuntu-latest; strict job has fetch-depth: 0 + draft-skip.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

WF="$REPO_ROOT/.github/workflows/lint.yml"
test -f "$WF" || { echo "FAIL: $WF missing" >&2; exit 1; }

# YAML parse
python3 - <<PYEOF
import yaml
y = yaml.safe_load(open("$WF"))
assert isinstance(y, dict), "workflow must be a dict"
jobs = y.get('jobs', {})
assert set(jobs.keys()) == {'lint', 'privacy-leak', 'strict'}, f"expected exactly 3 jobs, got {sorted(jobs.keys())}"
for name, spec in jobs.items():
    assert spec.get('runs-on') == 'ubuntu-latest', f"{name}: runs-on must be ubuntu-latest"
    steps = spec.get('steps', [])
    step_uses = [s.get('uses', '') for s in steps]
    assert any('actions/checkout@v6' in u for u in step_uses), f"{name}: missing actions/checkout@v6"
    assert any('actions/setup-python@v6' in u for u in step_uses), f"{name}: missing actions/setup-python@v6"
    step_runs = [s.get('run', '') for s in steps]
    assert any('pip install pyyaml' in r for r in step_runs), f"{name}: missing pip install pyyaml"
# strict-specific: fetch-depth: 0 + draft-skip conditional
strict = jobs['strict']
assert 'if' in strict and 'draft' in strict['if'] and 'pull_request' in strict['if'] and 'push' in strict['if'], \
    f"strict job must have draft-skip conditional: {strict.get('if')}"
checkout_step = next(s for s in strict['steps'] if 'checkout' in s.get('uses', ''))
assert checkout_step.get('with', {}).get('fetch-depth') == 0, "strict checkout must have fetch-depth: 0"
# Lint job: bin/lint.sh --require-version 1.1.0 --ci --format json
lint_steps = jobs['lint']['steps']
assert any('bin/lint.sh' in s.get('run', '') and '--ci' in s.get('run', '') and '--format json' in s.get('run', '')
           for s in lint_steps), "lint job missing bin/lint.sh --ci --format json invocation"
# privacy-leak job
pl_steps = jobs['privacy-leak']['steps']
assert any('bin/check-privacy.sh' in s.get('run', '') for s in pl_steps), "privacy-leak missing bin/check-privacy.sh"
# strict job
s_steps = jobs['strict']['steps']
assert any('bin/lint.sh' in s.get('run', '') and '--strict' in s.get('run', '') for s in s_steps), \
    "strict job missing bin/lint.sh --strict"
print("PASS: workflow YAML structure valid")
PYEOF

# Enforcement-model comment block
grep -q "HARD GATE" "$WF" || { echo "FAIL: header missing 'HARD GATE'" >&2; exit 1; }
grep -q "ADVISORY" "$WF" || { echo "FAIL: header missing 'ADVISORY'" >&2; exit 1; }
grep -q "pull_request" "$WF" || { echo "FAIL: header missing 'pull_request'" >&2; exit 1; }

echo "PASS: lint.yml structure + enforcement-model comment"
```

`tests/phase-09/test_annotation_shim.sh`:

```bash
#!/usr/bin/env bash
# CI-05: JSON → GitHub annotations shim.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

SHIM="$REPO_ROOT/.github/scripts/json-to-annotations.py"
test -x "$SHIM" || { echo "FAIL: shim not executable" >&2; exit 1; }

# 1. Error finding → ::error
cat > /tmp/ann1.json <<'J'
[{"severity":"error","category":"yaml","path":"wiki/x.md","line":5,"message":"bad YAML"}]
J
OUT="$(python3 "$SHIM" /tmp/ann1.json)"
echo "$OUT" | grep -q "^::error file=wiki/x.md" \
    || { echo "FAIL: expected ::error file=wiki/x.md in: $OUT" >&2; exit 1; }
echo "$OUT" | grep -q "line=5" || { echo "FAIL: expected line=5" >&2; exit 1; }

# 2. Warning → ::warning
cat > /tmp/ann2.json <<'J'
[{"severity":"warning","category":"stale","path":"wiki/y.md","message":"stale claim"}]
J
OUT2="$(python3 "$SHIM" /tmp/ann2.json)"
echo "$OUT2" | grep -q "^::warning file=wiki/y.md" \
    || { echo "FAIL: expected ::warning in: $OUT2" >&2; exit 1; }

# 3. Info → ::notice (NOT ::info)
cat > /tmp/ann3.json <<'J'
[{"severity":"info","category":"skip-count","path":"wiki/z.md","message":"exempted"}]
J
OUT3="$(python3 "$SHIM" /tmp/ann3.json)"
echo "$OUT3" | grep -q "^::notice file=wiki/z.md" \
    || { echo "FAIL: info must map to ::notice, not ::info. Got: $OUT3" >&2; exit 1; }
if echo "$OUT3" | grep -q "^::info"; then
    echo "FAIL: ::info is not a valid GitHub workflow command" >&2; exit 1
fi

# 4. Annotation cap: 15 errors → 10 ::error lines + 1 trailing ::notice "more"
python3 - <<'PY' > /tmp/ann4.json
import json
data = [{"severity":"error","category":"yaml","path":f"wiki/f{i}.md","line":i+1,"message":f"err {i}"} for i in range(15)]
json.dump(data, open("/tmp/ann4.json", "w"))
PY
OUT4="$(python3 "$SHIM" /tmp/ann4.json)"
COUNT_ERR="$(echo "$OUT4" | grep -c '^::error' || true)"
if [ "$COUNT_ERR" -gt 10 ]; then
    echo "FAIL: expected <= 10 ::error lines, got $COUNT_ERR" >&2; exit 1
fi
echo "$OUT4" | grep -q "more" || { echo "FAIL: missing 'N more' trailing notice" >&2; exit 1; }

# 5. Missing file → exit 1 with clear stderr, not stack trace
if python3 "$SHIM" /tmp/does-not-exist.json 2>/tmp/ann5.err; then
    echo "FAIL: missing input file should exit 1" >&2; exit 1
fi
grep -q "not found" /tmp/ann5.err \
    || { echo "FAIL: stderr missing 'not found': $(cat /tmp/ann5.err)" >&2; exit 1; }
if grep -q "Traceback" /tmp/ann5.err; then
    echo "FAIL: should not emit python Traceback" >&2; exit 1
fi

echo "PASS: annotation shim (error/warning/notice mapping + cap + error handling)"
```

Both tests executable.
  </action>
  <verify>
    <automated>bash tests/phase-09/test_lint_workflow.sh && bash tests/phase-09/test_annotation_shim.sh</automated>
  </verify>
  <acceptance_criteria>
    - `test -f .github/workflows/lint.yml`
    - `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/lint.yml'))"` succeeds (YAML parses)
    - YAML has exactly 3 jobs: `lint`, `privacy-leak`, `strict`
    - All 3 jobs use `actions/checkout@v6` and `actions/setup-python@v6` with `python-version: '3.12'`
    - All 3 jobs have `pip install pyyaml` step
    - `lint` job invokes `bash bin/lint.sh --require-version 1.1.0 --ci --format json`
    - `privacy-leak` job invokes `bash bin/check-privacy.sh`
    - `strict` job invokes `bash bin/lint.sh --require-version 1.1.0 --strict`
    - `strict` job checkout step has `fetch-depth: 0`
    - `strict` job has `if: github.event.pull_request.draft == false || github.event_name == 'push'`
    - Header comment contains `HARD GATE`, `ADVISORY`, `pull_request`
    - `.github/scripts/json-to-annotations.py` exists, executable
    - Shim emits `::error` for error, `::warning` for warning, `::notice` (NOT `::info`) for info
    - Annotation cap handling: ≤10 error, ≤10 warning, ≤50 total; emits trailing `::notice` with `more` on cap hit
    - Missing-file error path exits 1 with clear stderr (no Python traceback)
    - Both tests exit 0
  </acceptance_criteria>
  <done>
    CI workflow exists with three independent parallel jobs. Annotation shim converts Plan 02/03's JSON output to GitHub inline PR annotations with correct severity mapping and cap handling. Operator sets branch-protection required checks (`lint`, `privacy-leak`, `strict`) — the enforcement-model header documents the one-time action.
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Create .github/pull_request_template.md (D-29 6-section structure) + PR template test</name>
  <files>.github/pull_request_template.md, tests/phase-09/test_pr_template.sh</files>
  <read_first>
    - .planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-CONTEXT.md — D-29 (6-section structure verbatim) + D-30 (terse/mechanical tone)
    - .planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-RESEARCH.md — §"Code Examples" #8 (exact template markdown)
    - tests/phase-09/lib.sh
  </read_first>
  <behavior>
    - Test H (test_pr_template.sh): File exists at `.github/pull_request_template.md`. Contains all 6 section headers (exact strings): `## Summary`, `## Ingest type`, `## Source attribution`, `## Privacy review`, `## Lint`, `## Expected findings`. The Ingest-type section has 6 checkbox items: `new source`, `update existing page`, `merge pages`, `supersede page`, `docs-only`, `other`. Privacy review section has a single checkbox referencing `PRIVACY.md`. Lint section has a collapsible `<details>` block with a `<summary>` of `lint output`. Expected-findings section mentions `lint:expect-inferred` or `lint:expect-tentative`.
  </behavior>
  <action>
Create `.github/pull_request_template.md` matching RESEARCH.md Code Example #8 verbatim:

```markdown
## Summary

<!-- 1-2 sentences. What does this PR do? -->

## Ingest type

- [ ] new source
- [ ] update existing page(s)
- [ ] merge pages
- [ ] supersede page
- [ ] docs-only
- [ ] other (describe in Summary)

## Source attribution

<!-- URL or citation of the source being ingested. May be left blank for docs-only PRs. -->

## Privacy review

- [ ] I confirm no `privacy: local_only` frontmatter appears in public paths (examples/, docs/, AGENTS.md, CLAUDE.md, README.md, .github/). See [PRIVACY.md](../PRIVACY.md).

## Lint

- [ ] `bin/lint.sh` passes locally.

<details>
<summary>lint output</summary>

```text
<!-- paste bin/lint.sh output here -->
```

</details>

## Expected findings (optional)

<!--
Intentional [inferred] or [tentative] claims or contradictions introduced
by this PR? Add escape-hatch markers on the line ABOVE the claim:

  <!-- lint:expect-inferred id=<page-id> reason="why this is inferred" -->
  - Claim text here [prov:...] [epistemic:: inferred]

See docs/reference/ci.md (section: escape-hatch markers).
-->
```

Write `tests/phase-09/test_pr_template.sh`:

```bash
#!/usr/bin/env bash
# COLAB-02: PR template has D-29 6-section structure.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

T="$REPO_ROOT/.github/pull_request_template.md"
test -f "$T" || { echo "FAIL: $T missing" >&2; exit 1; }

# All 6 sections
grep -q "^## Summary$" "$T" || { echo "FAIL: missing ## Summary" >&2; exit 1; }
grep -q "^## Ingest type$" "$T" || { echo "FAIL: missing ## Ingest type" >&2; exit 1; }
grep -q "^## Source attribution$" "$T" || { echo "FAIL: missing ## Source attribution" >&2; exit 1; }
grep -q "^## Privacy review$" "$T" || { echo "FAIL: missing ## Privacy review" >&2; exit 1; }
grep -q "^## Lint$" "$T" || { echo "FAIL: missing ## Lint" >&2; exit 1; }
grep -q "^## Expected findings" "$T" || { echo "FAIL: missing ## Expected findings" >&2; exit 1; }

# Ingest type has 6 checkbox items
for item in "new source" "update existing page" "merge pages" "supersede page" "docs-only" "other"; do
    grep -q "\- \[ \] $item" "$T" || { echo "FAIL: Ingest type missing '$item' checkbox" >&2; exit 1; }
done

# Privacy review references PRIVACY.md
grep -q "PRIVACY.md" "$T" || { echo "FAIL: Privacy review missing PRIVACY.md link" >&2; exit 1; }
grep -qE "\- \[ \] I confirm" "$T" || { echo "FAIL: Privacy review missing single checkbox" >&2; exit 1; }

# Lint has collapsible details block
grep -q "<details>" "$T" || { echo "FAIL: Lint missing <details>" >&2; exit 1; }
grep -q "<summary>lint output</summary>" "$T" || { echo "FAIL: Lint missing <summary>lint output</summary>" >&2; exit 1; }

# Expected findings mentions escape-hatch marker
grep -q "lint:expect-inferred" "$T" || { echo "FAIL: Expected findings missing lint:expect-inferred pointer" >&2; exit 1; }

echo "PASS: PR template 6-section structure"
```

Mark executable.
  </action>
  <verify>
    <automated>bash tests/phase-09/test_pr_template.sh</automated>
  </verify>
  <acceptance_criteria>
    - `test -f .github/pull_request_template.md`
    - All 6 section headers present (exact `^## ...$` matches)
    - All 6 Ingest-type checkboxes present
    - Privacy-review section references `PRIVACY.md`
    - Lint section contains `<details>...<summary>lint output</summary>...</details>`
    - Expected-findings section mentions `lint:expect-inferred` (D-09 pointer)
    - Test exits 0
    - Template tone: no governance language, no CoC, no release cadence (D-23/D-30 terse/mechanical)
  </acceptance_criteria>
  <done>
    When a contributor opens a PR on the public repo, GitHub auto-populates the PR body with this 6-section structure. Reviewers see a consistent, mechanical checklist.
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 3: Amend AGENTS.md §§11.1/11.3/12 + re-sync CLAUDE.md + add 3 section tests (COLAB-03 documentation)</name>
  <files>AGENTS.md, CLAUDE.md, tests/phase-09/test_agents_section_11_1.sh, tests/phase-09/test_agents_section_11_3.sh, tests/phase-09/test_agents_section_12.sh</files>
  <read_first>
    - AGENTS.md — FULL file; specifically §11.1 (ingest workflow around line 1175+), §11.3 (lint workflow around line 1319+), §12 (index and log around line 1446+)
    - .planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-CONTEXT.md — D-01..D-09 (documents all the behavior to canonicalize in AGENTS.md)
    - bin/sync-claude.sh — the hook script; confirm it byte-compares AGENTS.md ↔ CLAUDE.md
    - .githooks/pre-commit — Phase 7 hook that auto-syncs on drift
  </read_first>
  <behavior>
    - Test I (test_agents_section_11_1.sh): AGENTS.md §11.1 contains a new step (or sub-step) documenting: `bin/ingest.sh --contributor <handle>` auto-detects from `git config user.email` via `.git-author-map.txt`; on single-author detection omits field; on map miss warns + omits (never bare email). Contains the string `contributor::`.
    - Test J (test_agents_section_11_3.sh): AGENTS.md §11.3 has a new subsection titled `CI mode` (or similar) documenting: `--ci` flag applies severity remap (yaml/orphan/crossref/provenance → error; stale/gap/contradiction → warning); `--format json` emits stdout-only structured findings; `--strict` quality ratchet with escape-hatch marker syntax `<!-- lint:expect-inferred id=X reason="Y" -->` (line immediately above claim); `--require-version X.Y.Z` minimum-version pinning.
    - Test K (test_agents_section_12.sh): AGENTS.md §12 documents the `contributor:: @handle` Dataview inline body field (COLAB-03). Explicit: inline body (NOT frontmatter per §3 "DO NOT put wikilinks/inline fields in YAML frontmatter"); handle format `@github-handle`; single-author repos omit field entirely.
    - Test (all three): `bash bin/sync-claude.sh --check` exits 0 after amendments (CLAUDE.md byte-identical to AGENTS.md).
  </behavior>
  <action>
**Step 1: Amend AGENTS.md §11.1 (Ingest Workflow).**

Find the existing §11.1 ingest workflow steps (currently 1-10). Add a new sub-step (probably between current steps 5 and 6, or as a dedicated bullet inside step 9 "Append entry to wiki/log.md"). The exact insertion point is the log-entry-append step.

Candidate amendment (insert after the step that appends to log.md, before step 10 "Commit"):

```markdown
9a. **Contributor attribution (COLAB-03, COLAB-04):** If the log entry is produced via `bin/ingest.sh`, the helper resolves a contributor handle via the following order:
    1. Explicit `--contributor @handle` flag wins (forces emission even on single-author repos).
    2. On single-author repos (`git log --all --format='%ae' | sort -u | wc -l == 1`), the field is omitted entirely.
    3. Otherwise, look up `git config user.email` in `.git-author-map.txt` at the repo root (case-insensitive; format `email  ->  @handle`, `#` comments allowed). On hit, emit `contributor:: @handle` as a Dataview inline body field directly below the `## [YYYY-MM-DD]` log-entry header (see §12).
    4. On map miss, warn to stderr (actionable: suggest `--contributor @handle` or adding the mapping) and OMIT the field. Never write a bare email into the `contributor::` field (privacy hygiene + parser consistency).
    Git commit authorship remains the attribution source of truth; `contributor::` is a Dataview convenience index.
```

**Step 2: Amend AGENTS.md §11.3 (Lint Workflow) — add `CI mode` subsection.**

Find §11.3 and the "Severity Tiers" / "Auto-Fix Boundary" tables. After those, add:

```markdown
#### CI mode (Phase 9)

> **Source of truth for Phase 9 CI contracts.** This section is the authoritative specification for: (a) the severity-remap dispatch table, (b) the `--format json` output schema, (c) the escape-hatch marker contract, and (d) the `--require-version` semantics. Other docs (`docs/reference/ci.md`, `CONTRIBUTING.md`, `.github/workflows/lint.yml` comments) MUST link here rather than restating the policy. Drift between this section and the shipped code is a Phase 9 regression.

`bin/lint.sh` supports a CI operating profile via three independent, orthogonal flags:

| Flag | Effect |
|------|--------|
| `--format json` | Emit JSON array `[{severity, category, path, line?, message}]` to stdout; do NOT write `lint-report.md`. |
| `--ci` | Apply severity-remap dispatch table: `yaml`/`orphan`/`crossref`/`provenance` → `error`; `stale`/`gap`/`contradiction`/`contradiction-sync`/`drift`/`contributor` → `warning`; `autofix`/`skip-count` → `info`. Default-skip `drift-external` category. Exit 1 iff any post-remap finding has severity `error`. |
| `--skip-category <cat>` | Exclude one category. Repeatable. Inverse of `--category`. |
| `--strict` | Quality ratchet: fail on (a) new `[epistemic:: inferred]` / `[epistemic:: tentative]` claims without a matching decision record whose `affected_pages` frontmatter contains the page ID; (b) new (git-diff status `A`) pages of type `entity`/`concept`/`overview`/`comparison` with zero `[prov:` markers. Source pages and decision records are exempt by design. |
| `--require-version X.Y.Z` | Minimum-version pin. Fails if `LINT_VERSION < X.Y.Z`. Semver tuple comparison, not string. |
| `--version` | Print `LINT_VERSION` and exit 0. |
| `--count-skips` | Enumerate every `<!-- lint:expect-* -->` escape-hatch marker. Emits one `info`/`skip-count` finding per marker (human-review aid). |

**Escape-hatch marker syntax (`--strict` exemption):**

```
<!-- lint:expect-inferred id=<page-id> reason="<one line>" -->
<!-- lint:expect-tentative id=<page-id> reason="<one line>" -->
```

Placement rules (strict):

1. Marker MUST appear on the line IMMEDIATELY above the claim line — no blank line between.
2. `id` MUST match the containing page's frontmatter `id` field.
3. `reason` is required and non-empty.
4. Exempted claims are emitted as severity `info`, category `skip-count` (visible in PR annotations as `::notice`, non-blocking).

**CI workflow reference:** `.github/workflows/lint.yml` invokes three jobs in parallel — `lint`, `privacy-leak`, `strict` — each a required check in branch protection. See `docs/reference/ci.md`.
```

**Step 3: Amend AGENTS.md §12 (Index and Log) — document `contributor::` inline field.**

Find §12 "log.md (Activity Log)" and the entry-format subsection. After the existing entry-format block, add:

```markdown
#### Contributor inline field (COLAB-03, Phase 9)

Log entries may carry an optional `contributor:: @github-handle` Dataview inline body field immediately below the entry header:

```markdown
## [YYYY-MM-DD] ingest | <description>

contributor:: @octocat

<rationale and affected pages>
```

**Rules:**

- `contributor::` is a **Dataview inline body field** (per AGENTS.md §6 inline syntax precedent). It MUST NOT be placed in YAML frontmatter (§3 prohibition).
- Handle format: `@github-handle` — leading `@` required. `bin/search.sh --contributor` accepts both `@octocat` and `octocat` forms (leading `@` stripped internally).
- **Single-author repos omit the field entirely** — `bin/ingest.sh` auto-detects via `git log --all --format='%ae' | sort -u | wc -l == 1` (see §11.1 step 9a).
- **Git commit authorship is the attribution source of truth** (COLAB-05). The `contributor::` field is a Dataview convenience index for filtering log history by contributor (`bin/search.sh --contributor @alice`); it is NOT authoritative.
- Handle-to-email resolution lives in `.git-author-map.txt` at the repo root (committed, human-curated, `email  ->  @handle` format; `#` comments; case-insensitive email match).
- `bin/lint.sh` category `contributor` (severity `warning`) catches `@handle` values in `wiki/log.md` whose `.git-author-map.txt` email does NOT appear in `git log --all --format='%ae'` — non-blocking consistency check. Skipped on single-author repos.

**Queryable via Dataview:**

```dataview
LIST
FROM "wiki/log.md"
WHERE contains(file.lists.text, "contributor:: @octocat")
```
```

**Step 4: Re-sync CLAUDE.md.**

```bash
bash bin/sync-claude.sh
# or equivalent — check bin/sync-claude.sh's --apply flag name
```

Verify byte-equality: `bash bin/sync-claude.sh --check` exits 0.

**Step 5: Write three section tests.**

`tests/phase-09/test_agents_section_11_1.sh`:

```bash
#!/usr/bin/env bash
# COLAB-04 doc: AGENTS.md §11.1 documents --contributor auto-detect flow.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

A="$REPO_ROOT/AGENTS.md"

# Extract §11.1 section body (from "### 11.1" to next "### ")
SECTION="$(awk '/^### 11\.1/,/^### 11\.[0-9]/' "$A" | head -n -1)"
echo "$SECTION" | grep -q -- "--contributor" \
    || { echo "FAIL: §11.1 missing --contributor documentation" >&2; exit 1; }
echo "$SECTION" | grep -q "\.git-author-map\.txt" \
    || { echo "FAIL: §11.1 missing .git-author-map.txt reference" >&2; exit 1; }
echo "$SECTION" | grep -qi "single.author" \
    || { echo "FAIL: §11.1 missing single-author detection note" >&2; exit 1; }
echo "$SECTION" | grep -q "contributor::" \
    || { echo "FAIL: §11.1 missing contributor:: field name" >&2; exit 1; }
echo "$SECTION" | grep -qi "never.*bare.*email\|never.*email.*bare\|NEVER.*bare" \
    || { echo "FAIL: §11.1 missing 'never bare email' rule" >&2; exit 1; }

echo "PASS: AGENTS.md §11.1 documents --contributor flow"
```

`tests/phase-09/test_agents_section_11_3.sh`:

```bash
#!/usr/bin/env bash
# AGENTS.md §11.3 has CI-mode subsection documenting all new flags + escape-hatch.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

A="$REPO_ROOT/AGENTS.md"
SECTION="$(awk '/^### 11\.3/,/^### 11\.[0-9]/' "$A" | head -n -1)"

# CI mode subsection present
echo "$SECTION" | grep -qi "CI mode" \
    || { echo "FAIL: §11.3 missing 'CI mode' subsection" >&2; exit 1; }

# All new flags documented
for flag in -- --format --ci --strict --skip-category --require-version --version --count-skips; do
    # skip bare --
    [ "$flag" = "--" ] && continue
    echo "$SECTION" | grep -q -- "$flag" \
        || { echo "FAIL: §11.3 missing flag '$flag'" >&2; exit 1; }
done

# Escape-hatch marker documented
echo "$SECTION" | grep -q "lint:expect-inferred" \
    || { echo "FAIL: §11.3 missing lint:expect-inferred marker doc" >&2; exit 1; }
echo "$SECTION" | grep -q "lint:expect-tentative" \
    || { echo "FAIL: §11.3 missing lint:expect-tentative marker doc" >&2; exit 1; }
# Immediately-above-line rule
echo "$SECTION" | grep -qi "immediately above\|line above\|line immediately" \
    || { echo "FAIL: §11.3 missing adjacency rule (immediately above)" >&2; exit 1; }

# Severity remap table (at least 3 of the known categories)
for cat in yaml orphan provenance stale gap contradiction; do
    echo "$SECTION" | grep -q "$cat" \
        || { echo "FAIL: §11.3 severity remap missing category '$cat'" >&2; exit 1; }
done

# Source-of-truth designation (per Codex MEDIUM review — prevents spec duplication drift)
echo "$SECTION" | grep -qi "source of truth\|authoritative specification" \
    || { echo "FAIL: §11.3 CI mode should designate itself as source of truth for CI contracts" >&2; exit 1; }

echo "PASS: AGENTS.md §11.3 CI-mode subsection complete"
```

`tests/phase-09/test_agents_section_12.sh`:

```bash
#!/usr/bin/env bash
# COLAB-03: AGENTS.md §12 documents contributor:: @handle inline body field.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

A="$REPO_ROOT/AGENTS.md"
SECTION="$(awk '/^## 12\./,/^## 13\./' "$A" | head -n -1)"

echo "$SECTION" | grep -q "contributor::" \
    || { echo "FAIL: §12 missing contributor:: field" >&2; exit 1; }
echo "$SECTION" | grep -qi "@github-handle\|@handle\|github handle" \
    || { echo "FAIL: §12 missing @handle format doc" >&2; exit 1; }
echo "$SECTION" | grep -qi "inline body\|body field\|Dataview inline" \
    || { echo "FAIL: §12 missing 'inline body field' distinction (not frontmatter)" >&2; exit 1; }
echo "$SECTION" | grep -qi "source of truth\|authoritative" \
    || { echo "FAIL: §12 missing git-authorship-source-of-truth statement" >&2; exit 1; }
echo "$SECTION" | grep -qi "single.author.*omit\|omit.*single.author" \
    || { echo "FAIL: §12 missing single-author omission rule" >&2; exit 1; }
echo "$SECTION" | grep -q "\.git-author-map\.txt" \
    || { echo "FAIL: §12 missing .git-author-map.txt reference" >&2; exit 1; }

# CLAUDE.md byte-equality still holds
bash "$REPO_ROOT/bin/sync-claude.sh" --check \
    || { echo "FAIL: CLAUDE.md drifted from AGENTS.md after amendments" >&2; exit 1; }

echo "PASS: AGENTS.md §12 + CLAUDE.md sync"
```

All tests executable.

Run `bash bin/sync-claude.sh` (or its apply flag) to re-sync CLAUDE.md after AGENTS.md edits. Confirm pre-commit hook works: `bash .githooks/pre-commit` (if it exists as standalone), or simply `bash bin/sync-claude.sh --check` exits 0.

Be aware: since CLAUDE.md is auto-synced via pre-commit hook (Phase 7 TMPL-10/D-03), committing AGENTS.md changes WILL automatically re-stage CLAUDE.md. Tests assert both files are in sync via `--check`.
  </action>
  <verify>
    <automated>bash tests/phase-09/test_agents_section_11_1.sh && bash tests/phase-09/test_agents_section_11_3.sh && bash tests/phase-09/test_agents_section_12.sh && bash bin/sync-claude.sh --check</automated>
  </verify>
  <acceptance_criteria>
    - AGENTS.md §11.1 contains `--contributor`, `.git-author-map.txt`, `contributor::`, "single-author" or "single author", and a "never bare email" rule
    - AGENTS.md §11.3 has a `CI mode` subsection listing all new flags: `--format`, `--ci`, `--strict`, `--skip-category`, `--require-version`, `--version`, `--count-skips`
    - AGENTS.md §11.3 documents the escape-hatch marker with strictness rules (immediately above, id match, reason required)
    - AGENTS.md §11.3 severity remap table covers at least: yaml, orphan, crossref, provenance (errors); stale, gap, contradiction (warnings)
    - AGENTS.md §11.3 CI mode subsection contains the phrase "source of truth" or "authoritative specification" (per Codex MEDIUM review — prevents spec duplication drift across docs/reference/ci.md, CONTRIBUTING.md, workflow comments)
    - AGENTS.md §12 documents `contributor:: @handle` as inline body field (NOT frontmatter)
    - AGENTS.md §12 states git commit authorship is source of truth
    - AGENTS.md §12 documents single-author omission rule + `.git-author-map.txt`
    - `bash bin/sync-claude.sh --check` exits 0 (CLAUDE.md byte-identical to AGENTS.md)
    - All 3 tests exit 0
    - Regression: `bash tests/phase-07/run.sh` still exits 0 (sync-claude test still passes post-amendments)
  </acceptance_criteria>
  <done>
    AGENTS.md is the canonical spec; §11.1/§11.3/§12 reflect Phase 9's new surface. CLAUDE.md is byte-identical (Phase 7 pre-commit hook enforces). Any agent (Claude, Codex, Gemini) reading AGENTS.md now knows the Phase 9 conventions — no code/spec drift.
  </done>
</task>

</tasks>

<verification>
- `.github/workflows/lint.yml` has 3 parallel jobs; YAML parses; all jobs use v6 actions + ubuntu-latest + pyyaml install.
- `strict` job has fetch-depth:0 + draft-skip conditional.
- `.github/scripts/json-to-annotations.py` maps `error→::error`, `warning→::warning`, `info→::notice`; honors 10/10/50 caps with trailing "more" notice.
- `.github/pull_request_template.md` has 6 sections per D-29; terse/mechanical tone.
- AGENTS.md §§11.1/11.3/12 amended with Phase 9 surface; CLAUDE.md byte-identical.
- All 6 new tests (`test_lint_workflow.sh`, `test_annotation_shim.sh`, `test_pr_template.sh`, `test_agents_section_11_1.sh`, `test_agents_section_11_3.sh`, `test_agents_section_12.sh`) exit 0.
- `bash tests/phase-09/run.sh` tail line shows PHASE 09 TESTS: N/M with N == M.
- Regression: `bash tests/phase-07/run.sh && bash tests/phase-08/run.sh` exit 0.
</verification>

<success_criteria>
When the operator pushes the Phase 9 branch to the public repo's GitHub and opens a PR, three jobs (`lint`, `privacy-leak`, `strict`) fire in parallel on `ubuntu-latest`. Lint findings surface as inline annotations via the JSON→`::error` shim. Privacy-leak attempts fail the PR. Strict ratchet catches unmatched `[inferred]` claims and new-page-without-provenance. The PR body auto-populates with D-29's 6-section checklist. AGENTS.md and CLAUDE.md are byte-identical with Phase 9's surface documented.
</success_criteria>

<output>
After completion, create `.planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-05-SUMMARY.md` documenting: workflow YAML final structure (3 jobs + enforcement-model comment block), annotation shim severity mapping + cap handling decisions, PR template final section list, AGENTS.md amendment locations (line numbers after edit), CLAUDE.md sync confirmation, and the 6 test files.
</output>

## Review Response

This plan was revised on 2026-04-16 in response to cross-AI review feedback (see `09-REVIEWS.md`).

### Accepted

| Reviewer | Severity | Concern | How Addressed |
|----------|----------|---------|---------------|
| Codex | MEDIUM | Spec duplication risk: severity policy, JSON schema, and provider equivalents could drift across AGENTS.md §11.3, `docs/reference/ci.md`, `.github/workflows/lint.yml`, and `CONTRIBUTING.md`. No single source of truth designated. | Amended Task 3's AGENTS.md §11.3 CI-mode subsection to open with a blockquote designating itself as the **source of truth for Phase 9 CI contracts** (severity policy, JSON schema, escape-hatch contract, `--require-version` semantics). `docs/reference/ci.md` and `CONTRIBUTING.md` (Plan 06) now link to §11.3 rather than restate the policy. `test_agents_section_11_3.sh` asserts the "source of truth" / "authoritative specification" string is present. |

### Rejected

None for this plan.

### Deferred

| Reviewer | Severity | Concern | Deferral Reason |
|----------|----------|---------|-----------------|
| Codex | MEDIUM | Workflow `continue-on-error: true` + `steps.lint_run.outcome == 'failure'` couples "lint error" to "step failure" — script-runtime failures and error findings are conflated. | Acknowledged. Current design: script runtime failure (missing python3, etc.) → non-zero exit → step outcome `failure` → fail step. Error findings under `--ci` → non-zero exit → same. Both paths block PR, which is the intended behavior. Distinguishing them is a Phase 10+ refinement if needed. |
| Codex | MEDIUM | Workflow does not upload `lint.json` as an artifact; large PRs hitting annotation cap lose findings in the PR UI. | Valid concern; annotations shim emits a trailing "N more findings — see lint.json in workflow logs" notice when capped. Uploading as artifact is a nice-to-have deferred to a follow-up (not a Phase 9 requirement). |
| Codex | MEDIUM | Plan diverges from earlier context ("no separate shim script") by creating `.github/scripts/json-to-annotations.py`. | Justified in-plan: testability of cap-handling logic + reusability across workflows. Earlier context was a soft preference, not a locked decision. |
| Codex | LOW | `pip install pyyaml` in the `privacy-leak` job may be unnecessary (script may not import PyYAML). | Consistent with baseline pattern; `bin/check-privacy.sh` uses regex-only parsing but `pip install pyyaml` is cheap (<2s) and keeps all three jobs uniform. No change. |
| Codex | LOW | PR template links to `../PRIVACY.md`; relative links in PR templates can be awkward. | GitHub renders PR template relative links from repo root. Tested pattern (`../PRIVACY.md` → resolves to `<repo>/PRIVACY.md`). No change. |
| Codex | LOW | AGENTS section tests use text matching rather than structure-aware validation. | Grep-based assertions are fast and debuggable. Structure-aware YAML/AST parsing of markdown is out of scope. No change. |

