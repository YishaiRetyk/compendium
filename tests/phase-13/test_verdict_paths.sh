#!/usr/bin/env bash
# FAITH-02: each of supports/weak/contradicts/insufficient reproduces via the fake
# verifier, and carries the correct severity (contradicts->warning, else info).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

run_one() {
    local verdict="$1" expected_sev="$2"
    local REPO; REPO="$(make_bare_repo)"
    local SEED; SEED="$(cd "$REPO" && git rev-parse HEAD)"
    write_page "$REPO" "wiki-cloud/sources/src-v.md" <<'EOF'
---
id: src-v
title: "V"
type: source
status: active
path: sources/2026/2026-04/v/source.md
content_hash: "sha256:aaaa"
compiled_against_hash: "sha256:aaaa"
ingested_at: 2026-04-15
source_type: paper
privacy: cloud_safe
---
EOF
    write_page "$REPO" "sources/2026/2026-04/v/source.md" <<'EOF'
## Introduction

VERDICT_PASSAGE content.
EOF
    write_page "$REPO" "wiki-cloud/concepts/v.md" <<'EOF'
---
id: vc
title: "Vc"
type: concept
status: active
privacy: cloud_safe
---
A claim [prov:src-v#sec:introduction|direct|2026-04-15]
EOF
    local VERIFIER; VERIFIER="$(make_fake_verifier "$REPO" "$verdict" "rationale-$verdict")"
    (cd "$REPO" && git add -A && git -c commit.gpgsign=false commit -q -m fixture)
    set +e
    local out; out="$(cd "$REPO" && AUDIT_REPO_ROOT="$REPO" bash "$REPO_ROOT/bin/audit-claims.sh" --verifier "$VERIFIER" --since "$SEED" --format json 2>/dev/null)"
    local rc=$?; set -e
    assert_exit_code 0 "$rc" "verdict $verdict run" || { echo "$out" >&2; cleanup_fixture_repo "$REPO"; return 1; }
    local got_sev; got_sev="$(printf '%s' "$out" | python3 -c "import json,sys; d=json.load(sys.stdin); m=[f for f in d if f.get('source_id')=='src-v' and f.get('verdict')=='$verdict']; print(m[0]['severity'] if m else 'MISSING')")"
    cleanup_fixture_repo "$REPO"
    if [ "$got_sev" != "$expected_sev" ]; then
        echo "FAIL: verdict=$verdict expected severity=$expected_sev got=$got_sev" >&2; return 1
    fi
    echo "  ok: $verdict -> $expected_sev"
}

run_one supports info
run_one weak info
run_one contradicts warning
run_one insufficient info

echo "PASS: all four verdicts reproduce with correct severities (contradicts=warning, else info)"
