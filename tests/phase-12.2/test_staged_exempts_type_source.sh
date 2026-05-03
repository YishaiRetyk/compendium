#!/usr/bin/env bash
# WGATE-02 / D-20 scenario 4: new wiki/sources/foo.md with type: source
# (plus SOURCE_EXTRA_FIELDS) and zero [prov:] markers -> exempt by type;
# bin/lint.sh --strict --staged --category provenance exits 0.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

REPO="$(make_bare_repo)"
trap 'cleanup_fixture_repo "$REPO"' EXIT

write_page "$REPO" "wiki/sources/foo.md" <<'EOF'
---
id: foo
title: "Foo Source"
type: source
status: active
summary: "Test source page exempt from provenance gate."
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
path: sources/foo.md
content_hash: "sha256:fixture"
ingested_at: 2026-05-04
source_type: paper
compilation_status: compiled
---

Source body with no [prov:] markers; exempt because type: source.
EOF
# Raw source file (DRFT-02 check requires the file at `path` to exist).
mkdir -p "$REPO/sources"
echo "fixture" > "$REPO/sources/foo.md"

(cd "$REPO" && git add wiki/sources/foo.md sources/foo.md)

set +e
(cd "$REPO" && bash "$REPO_ROOT/bin/lint.sh" --strict --staged --category provenance "$REPO/wiki/" >/tmp/wgate-out.$$ 2>/tmp/wgate-err.$$)
rc=$?
set -e

if ! assert_exit_code 0 "$rc" "exempt: type: source page without [prov:]"; then
    cat /tmp/wgate-out.$$ /tmp/wgate-err.$$ >&2 || true
    rm -f /tmp/wgate-out.$$ /tmp/wgate-err.$$
    exit 1
fi
rm -f /tmp/wgate-out.$$ /tmp/wgate-err.$$
echo "PASS: exempt: type: source page without [prov:]"
