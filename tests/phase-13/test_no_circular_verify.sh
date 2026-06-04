#!/usr/bin/env bash
# FAITH-02 / D-11: the resolver reads the RAW path: file, NEVER the summary's
# ## Extracted Claims. Prove by putting DIFFERENT text in each and asserting the
# resolved passage matches the RAW file's text.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

REPO="$(make_bare_repo)"
trap 'cleanup_fixture_repo "$REPO"' EXIT

# Summary body deliberately contains DIVERGENT text under ## Extracted Claims.
write_page "$REPO" "wiki-cloud/sources/src-cv.md" <<'EOF'
---
id: src-cv
title: "CV"
type: source
status: active
path: sources/2026/2026-04/cv/source.md
content_hash: "sha256:aaaa"
compiled_against_hash: "sha256:aaaa"
ingested_at: 2026-04-15
source_type: paper
privacy: cloud_safe
---

## Extracted Claims

## Introduction

SUMMARY_DIVERGENT_TEXT that must NEVER be the resolved passage.
EOF

# RAW file has the REAL text under the same heading.
write_page "$REPO" "sources/2026/2026-04/cv/source.md" <<'EOF'
## Introduction

RAW_TRUTH_TEXT is the only correct resolution target.
EOF

write_page "$REPO" "wiki-cloud/concepts/cv.md" <<'EOF'
---
id: cv
title: "CV"
type: concept
status: active
privacy: cloud_safe
---
A claim [prov:src-cv#sec:introduction|direct|2026-04-15]
EOF

set +e
out="$(cd "$REPO" && AUDIT_REPO_ROOT="$REPO" bash "$REPO_ROOT/bin/audit-claims.sh" --emit-worklist --format json 2>/dev/null)"
rc=$?
set -e
assert_exit_code 0 "$rc" "no-circular run" || { echo "$out" >&2; exit 1; }

if ! printf '%s' "$out" | grep -q 'RAW_TRUTH_TEXT'; then
    echo "FAIL: resolver did not read the raw path: file" >&2; echo "$out" >&2; exit 1
fi
if printf '%s' "$out" | grep -q 'SUMMARY_DIVERGENT_TEXT'; then
    echo "FAIL: resolver read the summary's ## Extracted Claims (circular!)" >&2
    echo "$out" >&2; exit 1
fi
echo "PASS: resolver reads the raw path: file, never the summary (D-11)"
