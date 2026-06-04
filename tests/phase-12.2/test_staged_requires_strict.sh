#!/usr/bin/env bash
# WGATE-02 / D-05 contract: --staged without --strict either no-ops (does not
# fire the gate; exit 0) OR short-errors with a usage hint (exit 1). Both are
# acceptable per D-05 -- the test accepts either.
#
# Recommended assertion: stage a wiki-cloud/concepts/foo.md with zero [prov:],
# run --staged WITHOUT --strict, assert that the gate did NOT fire (exit 0).
# That is the no-op-without-strict contract.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

REPO="$(make_bare_repo)"
trap 'cleanup_fixture_repo "$REPO"' EXIT

write_page "$REPO" "wiki-cloud/concepts/foo.md" <<'EOF'
---
id: foo
title: "Foo"
type: concept
status: active
summary: "Staged-requires-strict contract test."
created_at: 2026-05-04
updated_at: 2026-05-04
sources: []
epistemic_status: tentative
tags: []
domains: []
supersedes:
superseded_by:
privacy: cloud_safe
aliases: []
has_contradictions: false
knowledge_domain: ""
---

Body without [prov:] markers; --staged without --strict must not fire the gate.
EOF
(cd "$REPO" && git add wiki-cloud/concepts/foo.md)

set +e
(cd "$REPO" && bash "$REPO_ROOT/bin/lint.sh" --staged --category provenance "$REPO/wiki-cloud/" >/tmp/wgate-out.$$ 2>/tmp/wgate-err.$$)
rc=$?
set -e

# Per D-05, --staged without --strict is a no-op. Recommended assertion:
# exit 0 (no gate fired). Implementation may instead short-error (exit 1
# with usage hint) -- both are acceptable per the contract.
if ! assert_exit_code 0 "$rc" "--staged without --strict no-ops (exit 0)"; then
    cat /tmp/wgate-out.$$ /tmp/wgate-err.$$ >&2 || true
    rm -f /tmp/wgate-out.$$ /tmp/wgate-err.$$
    exit 1
fi
rm -f /tmp/wgate-out.$$ /tmp/wgate-err.$$
echo "PASS: --staged without --strict no-ops (exit 0)"
