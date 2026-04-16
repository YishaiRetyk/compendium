#!/usr/bin/env bash
# I-1 + I-2: AGENTS.md ≡ CLAUDE.md (byte-equality); schema/fixtures/canonical-AGENTS.md matches
# the python3 str.replace render of schema/AGENTS.template.md (Phase-08 canonical fixture gate).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

# I-1: AGENTS.md ≡ CLAUDE.md
cmp -s "$REPO_ROOT/AGENTS.md" "$REPO_ROOT/CLAUDE.md" \
    || { echo "FAIL: AGENTS.md and CLAUDE.md are not byte-equal (run bin/sync-claude.sh)" >&2; exit 1; }

# I-2: canonical-AGENTS.md matches Phase-08 byte-equality test
(cd "$REPO_ROOT" && bash tests/phase-08/test_canonical_byte_equality.sh) \
    || { echo "FAIL: Phase-08 canonical byte-equality test failed (schema/AGENTS.template.md drift)" >&2; exit 1; }

echo "PASS: byte-equality (AGENTS.md ≡ CLAUDE.md; canonical fixture matches template render)"
