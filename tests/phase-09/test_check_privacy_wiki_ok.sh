#!/usr/bin/env bash
# CI-07: wiki/** local_only IS valid user content (AGENTS.md §13); exit 0.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

FIXTURE="$(make_fixture_repo privacy-ok-wiki)"
trap 'cleanup_fixture_repo "$FIXTURE"' EXIT

bash "$REPO_ROOT/bin/check-privacy.sh" --root "$FIXTURE" \
    || { echo "FAIL: wiki/** privacy: local_only should be exempt (D-15)" >&2; exit 1; }

echo "PASS: check-privacy exempts wiki/** (D-15)"
