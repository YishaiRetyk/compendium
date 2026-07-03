#!/usr/bin/env bash
# FAITH-01: inferred/tentative epistemic selector picks claims with those markers.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

REPO="$(make_bare_repo)"
trap 'cleanup_fixture_repo "$REPO"' EXIT

write_page "$REPO" "wiki-cloud/sources/src-e.md" <<'EOF'
---
id: src-e
title: "E"
type: source
status: active
path: sources/2026/2026-04/e/source.md
content_hash: "sha256:aaaa"
compiled_against_hash: "sha256:aaaa"
ingested_at: 2026-04-15
source_type: paper
privacy: cloud_safe
---
EOF

write_page "$REPO" "sources/2026/2026-04/e/source.md" <<'EOF'
## Introduction

Body text.
EOF

write_page "$REPO" "wiki-cloud/concepts/epi.md" <<'EOF'
---
id: epi
title: "Epi"
type: concept
status: active
---
A sourced claim [prov:src-e#sec:introduction|direct|2026-04-15] [epistemic:: sourced]
An inferred claim [prov:src-e#sec:introduction|inferred|2026-04-15] [epistemic:: inferred]
EOF

set +e
out="$(cd "$REPO" && AUDIT_REPO_ROOT="$REPO" invoke_tool_compat audit-claims --select epistemic --format json 2>/dev/null)"
rc=$?
set -e
assert_exit_code 0 "$rc" "epistemic selector run" || { echo "$out" >&2; exit 1; }

# Only the inferred claim should be selected (sourced is not high-risk).
if ! printf '%s' "$out" | grep -q 'selected=1'; then
    echo "FAIL: expected exactly the inferred claim selected (selected=1)" >&2
    echo "$out" >&2; exit 1
fi
echo "PASS: epistemic selector picks inferred/tentative claims only"
