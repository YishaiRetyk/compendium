#!/usr/bin/env bash
# PRIV-05: bin/check-privacy.sh re-keyed structural behavior.
# After re-key: check-privacy is a PATH/release-allowlist guard (not a content-equivalence
# scanner). Tests:
# (a) clean tree with no wiki-local/ path under PUBLIC_PATHS -> exit 0
# (b) tree where a wiki-local/ PATH is copied into a PUBLIC_PATH (docs/wiki-local/leak.md) -> exit 2
# Note: this test does NOT assert that arbitrary copied CONTENT trips check-privacy --
# content-leak scanning belongs to check-neutrality.sh (asserted by test_neutrality_leak_source_rekey.sh).
# Today this FAILS because check-privacy keys on 'privacy: local_only' frontmatter, not
# on the wiki-local/ path appearing under a PUBLIC_PATH.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

repo="$(make_bare_repo)"

# --- Test (a): clean tree, no wiki-local/ path under PUBLIC_PATHS -> exit 0 ---
# Create a wiki-local/ directory that is NOT under any PUBLIC_PATH
mkdir -p "$repo/wiki-local/concepts"
cat > "$repo/wiki-local/concepts/local-page.md" <<'EOF'
---
id: local-page
title: "Local Page"
type: concept
status: active
summary: "A local-only page."
created_at: 2026-06-04
updated_at: 2026-06-04
sources: []
epistemic_status: sourced
tags: []
domains: []
supersedes:
superseded_by:
aliases: []
has_contradictions: false
knowledge_domain: software
---

# Local Page

Local content.
EOF

# Create a docs/ directory with cloud-safe content only
mkdir -p "$repo/docs"
cat > "$repo/docs/readme.md" <<'EOF'
# Docs

Some cloud-safe documentation.
EOF

set +e
out_a="$( "$REPO_ROOT/bin/check-privacy.sh" --root "$repo" 2>&1 )"
rc_a=$?
set -e

if [ "$rc_a" -ne 0 ]; then
    echo "FAIL (test a): clean tree should exit 0; got exit=$rc_a" >&2
    echo "output: $out_a" >&2
    cleanup_fixture_repo "$repo"
    exit 1
fi

# --- Test (b): wiki-local/ PATH appears under docs/ PUBLIC_PATH -> exit 2 ---
# The re-keyed check-privacy detects that a wiki-local/ PATH has leaked into a PUBLIC_PATH.
# Specifically: a file at docs/wiki-local/leak.md (path contains wiki-local/) -> leak.
mkdir -p "$repo/docs/wiki-local"
cat > "$repo/docs/wiki-local/leak.md" <<'EOF'
---
id: leak
title: "Leaked Local Page"
type: concept
status: active
summary: "This page should not be in docs/."
created_at: 2026-06-04
updated_at: 2026-06-04
sources: []
epistemic_status: sourced
tags: []
domains: []
supersedes:
superseded_by:
aliases: []
has_contradictions: false
knowledge_domain: software
---

# Leaked Local Page

This wiki-local/ content has been copied into a public path.
EOF

set +e
out_b="$( "$REPO_ROOT/bin/check-privacy.sh" --root "$repo" 2>&1 )"
rc_b=$?
set -e

if [ "$rc_b" -ne 2 ]; then
    echo "FAIL (test b): tree with docs/wiki-local/leak.md should exit 2 (leak); got exit=$rc_b" >&2
    echo "output: $out_b" >&2
    cleanup_fixture_repo "$repo"
    exit 1
fi

cleanup_fixture_repo "$repo"
echo "PASS: check-privacy re-keyed structural path guard (clean=0, wiki-local-under-public=2) (PRIV-05)"
