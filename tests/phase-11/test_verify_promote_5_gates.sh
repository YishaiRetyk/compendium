#!/usr/bin/env bash
# EXPECTED_BY: 11-04
# tests/phase-11/test_verify_promote_5_gates.sh — D-13: verify --promote
# flips bootstrap_stage to `verified` only when ALL 5 gates pass.
# Fixture: 3 pages — A passes all gates, B fails gate 2 (empty type), C
# fails gate 3 (lint error injected via malformed frontmatter).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
export BROWNFIELD_FIXTURE_TODAY=2026-04-20
export BROWNFIELD_FIXTURE_CREATED_AT=2026-04-20
export BROWNFIELD_TOOL_VERSION=1.1.0
export PYTHONPATH="${PYTHONPATH:-}${PYTHONPATH:+:}$HOME/.local/lib/python3/dist-packages"
NAME="$(basename "${BASH_SOURCE[0]}")"

# Use pre-typed-vault as the starting fixture; it already has some pages
# with valid type: and one with empty type:.  We augment by injecting a
# broken YAML page (gate 3 fail).
TMP=$(make_fixture_repo pre-typed-vault)
trap 'rm -rf "$TMP"' EXIT

# Gate 3 failure: inject a page with a malformed frontmatter line.
mkdir -p "$TMP/wiki/concepts"
cat > "$TMP/wiki/concepts/broken-yaml.md" <<'EOF'
---
id: broken-yaml
title: "Broken YAML"
type: concept
status: active
summary: ""
created_at: 2026-04-20
updated_at: 2026-04-20
sources: []
epistemic_status: tentative
tags: []
domains: []
supersedes:
superseded_by:
privacy: local_only
aliases: []
has_contradictions: false
knowledge_domain: ""
bootstrap_stage: bootstrapped
bootstrap_date: 2026-04-20
INVALID_YAML: [unterminated
---

# Broken YAML

Body content.
EOF

set +e
bash "$REPO_ROOT/bin/brownfield.sh" verify --promote --root "$TMP" >/dev/null 2>stderr.txt
ec=$?
set -e

if grep -q "not yet implemented" stderr.txt 2>/dev/null; then
    rm -f stderr.txt
    echo "FAIL: bin/brownfield.sh verify --promote not yet implemented — Plan 11-04 pending" >&2
    exit 1
fi
rm -f stderr.txt

# Page with valid type + clean lint should be promoted
promoted_count=$(grep -r -l '^bootstrap_stage: verified' "$TMP/wiki/" | wc -l)
if [ "$promoted_count" -lt "1" ]; then
    echo "FAIL: verify --promote did not promote ANY page (expected ≥1)" >&2
    exit 1
fi

# The empty-type page MUST NOT be promoted
if grep -A1 '^id: framing-effect' "$TMP/wiki/concepts/framing-effect.md" | grep -q 'bootstrap_stage: verified'; then
    :
fi
if grep -q '^bootstrap_stage: verified' "$TMP/wiki/concepts/framing-effect.md"; then
    echo "FAIL: framing-effect.md promoted despite empty type: (gate 2 should block)" >&2
    exit 1
fi

# The broken-YAML page MUST NOT be promoted
if grep -q '^bootstrap_stage: verified' "$TMP/wiki/concepts/broken-yaml.md"; then
    echo "FAIL: broken-yaml.md promoted despite malformed frontmatter (gate 3 should block)" >&2
    exit 1
fi

echo "PASS $NAME"; exit 0
