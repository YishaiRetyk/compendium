#!/usr/bin/env bash
# CI-01: .github/workflows/lint.yml exists with three parallel jobs;
# uses v6 actions + ubuntu-latest; strict job has fetch-depth: 0 + draft-skip.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

WF="$REPO_ROOT/.github/workflows/lint.yml"
test -f "$WF" || { echo "FAIL: $WF missing" >&2; exit 1; }

# YAML parse
WF_PATH="$WF" python3 - <<'PYEOF'
import os, yaml
wf = os.environ["WF_PATH"]
y = yaml.safe_load(open(wf))
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
cond = strict.get('if', '') or ''
assert 'draft' in cond and 'pull_request' in cond and 'push' in cond, \
    f"strict job must have draft-skip conditional: {cond}"
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
