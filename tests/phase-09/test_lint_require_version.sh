#!/usr/bin/env bash
# CI-08: --require-version minimum-version semantics + semver tuple ordering.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

LINT="$REPO_ROOT/bin/lint.sh"

# Case 1: exact match passes
bash "$LINT" --require-version 1.1.0 --dry-run >/dev/null 2>&1 \
    || { echo "FAIL: --require-version 1.1.0 should pass when LINT_VERSION=1.1.0" >&2; exit 1; }

# Case 2: older pin passes
bash "$LINT" --require-version 1.0.5 --dry-run >/dev/null 2>&1 \
    || { echo "FAIL: --require-version 1.0.5 should pass when LINT_VERSION=1.1.0" >&2; exit 1; }

# Case 3: newer pin fails with actionable stderr
if bash "$LINT" --require-version 1.2.0 --dry-run 2>/tmp/require-err >/dev/null; then
    echo "FAIL: --require-version 1.2.0 should fail when LINT_VERSION=1.1.0" >&2
    exit 1
fi
grep -q "require-version" /tmp/require-err \
    || { echo "FAIL: stderr missing 'require-version' token: $(cat /tmp/require-err)" >&2; exit 1; }
grep -q "1.2.0" /tmp/require-err \
    || { echo "FAIL: stderr missing '1.2.0' token" >&2; exit 1; }
grep -q "1.1.0" /tmp/require-err \
    || { echo "FAIL: stderr missing '1.1.0' running version" >&2; exit 1; }

# Case 4: semver tuple ordering (1.10.0 > 1.1.0 -- bash string compare would get this wrong)
if bash "$LINT" --require-version 1.10.0 --dry-run >/dev/null 2>&1; then
    echo "FAIL: --require-version 1.10.0 should fail when LINT_VERSION=1.1.0 (semver tuple, not string)" >&2
    exit 1
fi

echo "PASS: --require-version minimum + semver tuple ordering"
