#!/usr/bin/env bash
# CI-03: --ci severity remap + exit-1-on-error; without --ci, text mode unchanged.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

FIXTURE="$(make_fixture_repo ci-lint-json)"
trap 'cleanup_fixture_repo "$FIXTURE"' EXIT

# Seed a minimal wiki skeleton
mkdir -p "$FIXTURE/wiki-cloud"
cat > "$FIXTURE/wiki-cloud/index.md" <<'IDX'
# Index
IDX
cat > "$FIXTURE/wiki-cloud/log.md" <<'LOG'
# Log
LOG

# Seed a page with broken YAML frontmatter to trigger a `yaml` category finding.
# Use printf so the heredoc doesn't accidentally conflict with markdown rendering.
mkdir -p "$FIXTURE/wiki-cloud/concepts"
python3 - "$FIXTURE/wiki-cloud/concepts/broken.md" <<'PY'
import sys
# Write a page with invalid yaml inside the frontmatter block
content = """---
id: broken
title: Broken
type: concept
invalid yaml: here: with: too: many: colons
---

# Broken
"""
open(sys.argv[1], 'w').write(content)
PY

pushd "$FIXTURE" >/dev/null

# 1. --ci --format json on dirty wiki: exit 1 + yaml error finding
if bash "$REPO_ROOT/bin/lint.sh" --ci --format json wiki-cloud/ > /tmp/lint-ci.json 2>/dev/null; then
    echo "FAIL: --ci on broken yaml should exit 1" >&2
    popd >/dev/null; exit 1
fi
assert_json_has_finding /tmp/lint-ci.json yaml error || { popd >/dev/null; exit 1; }

# 2. Without --ci on same wiki: exit 0 (no CI remap, so no error-severity exit)
bash "$REPO_ROOT/bin/lint.sh" --format json wiki-cloud/ > /tmp/lint-nonci.json 2>/dev/null \
    || { echo "FAIL: non-ci mode should exit 0 regardless of findings" >&2; popd >/dev/null; exit 1; }

# 3. --ci on clean wiki (remove broken.md): exit 0
rm wiki-cloud/concepts/broken.md
bash "$REPO_ROOT/bin/lint.sh" --ci --format json wiki-cloud/ > /tmp/lint-clean.json 2>/dev/null \
    || { echo "FAIL: --ci on clean wiki should exit 0" >&2; popd >/dev/null; exit 1; }

popd >/dev/null
echo "PASS: --ci severity remap + exit-code policy"
