#!/usr/bin/env bash
# CI-07: privacy: local_only in docs/ (public path) frontmatter -> exit 2.
# Prose-body mention in docs/ -> exit 0 (frontmatter-only rule, D-14).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

FIXTURE="$(make_fixture_repo privacy-leak-public)"
trap 'cleanup_fixture_repo "$FIXTURE"' EXIT

# 1. Leak case: exit 2 with stderr path:line:
set +e
bash "$REPO_ROOT/bin/check-privacy.sh" --root "$FIXTURE" 2>/tmp/pv-err >/dev/null
RC=$?
set -e
if [ "$RC" = "0" ]; then
    echo "FAIL: privacy: local_only in docs/ frontmatter should exit 2" >&2
    exit 1
fi
if [ "$RC" != "2" ]; then
    echo "FAIL: expected exit 2, got $RC" >&2
    cat /tmp/pv-err >&2
    exit 1
fi
grep -q "docs/sample.md" /tmp/pv-err \
    || { echo "FAIL: stderr should name docs/sample.md: $(cat /tmp/pv-err)" >&2; exit 1; }
grep -qE "docs/sample.md:[0-9]+:" /tmp/pv-err \
    || { echo "FAIL: stderr should include path:line: format" >&2; exit 1; }

# 2. Body-text mention does NOT trigger (D-14 frontmatter-only)
cat > "$FIXTURE/docs/prose-mention.md" <<'BODY'
---
id: prose-mention
title: Prose Mention
type: concept
privacy: cloud_safe
---

This paragraph discusses the `privacy: local_only` tier in prose.
It is NOT a frontmatter leak and MUST NOT trigger the guard.
BODY
# Remove the actual leak so we're only testing the prose case
rm "$FIXTURE/docs/sample.md"

bash "$REPO_ROOT/bin/check-privacy.sh" --root "$FIXTURE" 2>/dev/null \
    || { echo "FAIL: prose-only mention should NOT trigger guard (D-14)" >&2; exit 1; }

echo "PASS: check-privacy leak detection + frontmatter-only rule"
