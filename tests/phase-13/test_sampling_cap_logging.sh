#!/usr/bin/env bash
# FAITH-01 / D-09: priority-rank union capped at --sample, with a no-silent-caps
# `selected=N skipped=M` info finding.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

REPO="$(make_bare_repo)"
trap 'cleanup_fixture_repo "$REPO"' EXIT

write_page "$REPO" "wiki-cloud/sources/src-c.md" <<'EOF'
---
id: src-c
title: "C"
type: source
status: active
path: sources/2026/2026-04/c/source.md
content_hash: "sha256:aaaa"
compiled_against_hash: "sha256:aaaa"
ingested_at: 2026-04-15
source_type: paper
privacy: cloud_safe
---
EOF
write_page "$REPO" "sources/2026/2026-04/c/source.md" <<'EOF'
## Introduction

Body text.
EOF

# A page with 5 inferred claims; cap at --sample 2 -> selected=2 skipped=3.
write_page "$REPO" "wiki-cloud/concepts/many.md" <<'EOF'
---
id: many
title: "Many"
type: concept
status: active
---
Claim one [prov:src-c#sec:introduction|inferred|2026-04-15] [epistemic:: inferred]
Claim two [prov:src-c#sec:introduction|inferred|2026-04-15] [epistemic:: inferred]
Claim three [prov:src-c#sec:introduction|inferred|2026-04-15] [epistemic:: inferred]
Claim four [prov:src-c#sec:introduction|inferred|2026-04-15] [epistemic:: inferred]
Claim five [prov:src-c#sec:introduction|inferred|2026-04-15] [epistemic:: inferred]
EOF

set +e
out="$(cd "$REPO" && AUDIT_REPO_ROOT="$REPO" bash "$REPO_ROOT/bin/audit-claims.sh" --select epistemic --sample 2 --format json 2>/dev/null)"
rc=$?
set -e
assert_exit_code 0 "$rc" "cap logging run" || { echo "$out" >&2; exit 1; }

if ! printf '%s' "$out" | grep -q 'selected=2 skipped=3'; then
    echo "FAIL: expected 'selected=2 skipped=3' no-silent-caps log line" >&2
    echo "$out" >&2; exit 1
fi
echo "PASS: priority-rank union capped at --sample with honest selected/skipped log"
