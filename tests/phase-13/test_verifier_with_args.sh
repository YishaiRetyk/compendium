#!/usr/bin/env bash
# REVIEW MEDIUM: a --verifier command WITH an argument parses via shlex.split and
# runs with shell=False; the arg reaches argv, the claim/passage do NOT (stdin-only).
# Uses make_argv_verifier (dumps "$@" to verifier-argv.log, discards stdin).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

REPO="$(make_bare_repo)"
trap 'cleanup_fixture_repo "$REPO"' EXIT
SEED="$(cd "$REPO" && git rev-parse HEAD)"

write_page "$REPO" "wiki/sources/src-w.md" <<'EOF'
---
id: src-w
title: "W"
type: source
status: active
path: sources/2026/2026-04/w/source.md
content_hash: "sha256:aaaa"
compiled_against_hash: "sha256:aaaa"
ingested_at: 2026-04-15
source_type: paper
privacy: cloud_safe
---
EOF
write_page "$REPO" "sources/2026/2026-04/w/source.md" <<'EOF'
## Introduction

ARGTEST_PASSAGE content.
EOF
write_page "$REPO" "wiki/concepts/w.md" <<'EOF'
---
id: wc
title: "Wc"
type: concept
status: active
privacy: cloud_safe
---
ARGTEST_CLAIM here [prov:src-w#sec:introduction|direct|2026-04-15]
EOF

ARGV_VERIFIER="$(make_argv_verifier "$REPO" supports)"
(cd "$REPO" && git add -A && git -c commit.gpgsign=false commit -q -m fixture)

set +e
out="$(cd "$REPO" && AUDIT_REPO_ROOT="$REPO" bash "$REPO_ROOT/bin/audit-claims.sh" --verifier "$ARGV_VERIFIER --tag XYZ" --since "$SEED" --format json 2>/dev/null)"
rc=$?; set -e
assert_exit_code 0 "$rc" "verifier-with-args run" || { echo "$out" >&2; exit 1; }

# Verdict produced (proves shlex.split parsed the multi-token command, arg reached subprocess).
v="$(printf '%s' "$out" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(sum(1 for f in d if f.get("source_id")=="src-w" and f.get("verdict")=="supports"))')"
[ "$v" -ge 1 ] || { echo "FAIL: command-with-args did not produce a verdict" >&2; echo "$out" >&2; exit 1; }

# argv log CONTAINS --tag XYZ but NOT the claim/passage text (payload is stdin-only).
[ -f "$REPO/verifier-argv.log" ] || { echo "FAIL: argv log not written" >&2; exit 1; }
grep -q -- '--tag XYZ' "$REPO/verifier-argv.log" || { echo "FAIL: --tag XYZ did not reach argv" >&2; cat "$REPO/verifier-argv.log" >&2; exit 1; }
if grep -qE 'ARGTEST_CLAIM|ARGTEST_PASSAGE' "$REPO/verifier-argv.log"; then
    echo "FAIL: claim/passage leaked into argv (must be stdin-only)" >&2; cat "$REPO/verifier-argv.log" >&2; exit 1; fi

echo "PASS: --verifier with args parses via shlex.split/shell=False; payload stays stdin-only"
