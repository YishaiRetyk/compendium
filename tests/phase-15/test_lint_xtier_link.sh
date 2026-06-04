#!/usr/bin/env bash
# PRIV-05: A wiki-cloud/ page linking to a wiki-local/ page must be a 'linkres'
# error when bin/lint.sh runs with --ci --category linkres. The D-09 asymmetric
# cross-tier link check does not exist yet, so this test is RED today.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

repo="$(make_bare_repo)"

# Write a wiki-cloud/ page that links to a wiki-local/ page
write_page "$repo" "wiki-cloud/concepts/foo.md" <<'EOF'
---
id: foo
title: "Foo Concept"
type: concept
status: active
summary: "A cloud-side concept that links to a local page."
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

# Foo Concept

This page links to [[bar|Bar Page]] which lives in wiki-local/.
EOF

# Write a wiki-local/ page as the link target
write_page "$repo" "wiki-local/concepts/bar.md" <<'EOF'
---
id: bar
title: "Bar Page"
type: concept
status: active
summary: "A local-only concept page."
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

# Bar Page

Local content.
EOF

# Run lint on the wiki-cloud/ fixture; expect exit 1 (error found) for the cloud->local link
# The D-09 check should emit a linkres error when a cloud page links to a local page.
# Today this test is RED because the D-09 check does not exist yet -- lint either passes
# (no error) or errors for a different reason.
set +e
LINT_OUT="$( cd "$repo" && WIKI_ROOT="wiki-cloud/" "$REPO_ROOT/bin/lint.sh" --ci --category linkres 2>&1 )"
rc=$?
set -e

# The test passes (GREEN) when:
# 1. lint exits 1 (error found), AND
# 2. the output mentions cloud->local or D-09
if [ "$rc" -ne 1 ]; then
    echo "FAIL: expected lint to exit 1 for cloud->local link, got exit=$rc" >&2
    echo "lint output:" >&2
    echo "$LINT_OUT" >&2
    cleanup_fixture_repo "$repo"
    exit 1
fi

# Also verify the error message mentions the cloud->local direction or D-09
if ! echo "$LINT_OUT" | grep -qiE 'cloud.local|D-09|cross.tier|wiki-local'; then
    echo "FAIL: lint did exit 1 but output does not mention cloud->local/D-09 direction" >&2
    echo "lint output:" >&2
    echo "$LINT_OUT" >&2
    cleanup_fixture_repo "$repo"
    exit 1
fi

cleanup_fixture_repo "$repo"
echo "PASS: lint exits 1 with cloud->local linkres error (D-09) (PRIV-05)"
