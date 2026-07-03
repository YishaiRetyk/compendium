#!/usr/bin/env bash
# WGATE-02 / D-20 scenario 5: new wiki-cloud/decisions/dr-2026-05-04-test.md with
# type: decision and zero [prov:] markers -> exempt; bin/lint.sh --strict
# --staged --category provenance exits 0.
#
# Note: wiki-cloud/decisions/ is NOT one of the four PROVENANCE_REQUIRED_TYPES dirs,
# so this scenario also confirms the path-prefix gate runs before the
# type-frontmatter gate (D-15 ordering).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

REPO="$(make_bare_repo)"
trap 'cleanup_fixture_repo "$REPO"' EXIT

write_page "$REPO" "wiki-cloud/decisions/dr-2026-05-04-test.md" <<'EOF'
---
id: dr-2026-05-04-test
title: "Test Decision Record"
type: decision
status: active
summary: "Test decision record exempt from provenance gate."
created_at: 2026-05-04
updated_at: 2026-05-04
sources: []
epistemic_status: sourced
tags: []
domains: []
supersedes:
superseded_by:
privacy: cloud_safe
aliases: []
has_contradictions: false
knowledge_domain: ""
trigger_type: schema-update
affected_pages: []
---

## TL;DR

Test decision record body with no [prov:] markers.

## Decision

Test decision text.

## Why

Replaces no prior framing; this is an inaugural test record.

## Alternatives Considered

None for this test fixture.

## Consequences

None for this test fixture.

## Affected Pages

None.

## Sources

None.
EOF
(cd "$REPO" && git add wiki-cloud/decisions/dr-2026-05-04-test.md)

set +e
(cd "$REPO" && invoke_tool_compat lint --strict --staged --category provenance "$REPO/wiki-cloud/" >/tmp/wgate-out.$$ 2>/tmp/wgate-err.$$)
rc=$?
set -e

if ! assert_exit_code 0 "$rc" "exempt: type: decision page without [prov:]"; then
    cat /tmp/wgate-out.$$ /tmp/wgate-err.$$ >&2 || true
    rm -f /tmp/wgate-out.$$ /tmp/wgate-err.$$
    exit 1
fi
rm -f /tmp/wgate-out.$$ /tmp/wgate-err.$$
echo "PASS: exempt: type: decision page without [prov:]"
