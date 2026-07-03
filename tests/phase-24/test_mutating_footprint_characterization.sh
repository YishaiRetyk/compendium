#!/usr/bin/env bash
# Phase 24 (TEST-03, D-11 + REVIEWS L-1): a MUTATING-tool golden where the file-tree
# channel is the load-bearing signal — proves the 4-channel design on the case it
# exists for. Tool: ingest (writes a dated source file + appends to wiki-cloud/log.md).
# Determinism: ingest derives its date from `date -u` — a PATH-injected `date` shim
# pins a frozen now (case-specific, per the D-12 policy: never widen the shared
# normalizer); --contributor is passed explicitly so no machine git config leaks in.
# L-1: captured TWICE and the tree channels cmp'd before asserting the golden.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

GOLD="$REPO_ROOT/tests/goldens/ingest/mutating-scaffold"

# Frozen-`date` shim farm (prepended to PATH for the ingest invocations only).
FARM="$(mktemp -d)"
cat > "$FARM/date" <<'EOF'
#!/usr/bin/env bash
exec /usr/bin/date -d "2026-01-02 00:00:00 UTC" "$@"
EOF
chmod +x "$FARM/date"
trap 'rm -rf "$FARM"' EXIT

run_capture() {
    local casedir="$1"
    local fixture; fixture="$(mktemp -d)"
    (
        cd "$fixture"
        mkdir -p wiki-cloud
        printf '# Log\n' > wiki-cloud/log.md
        printf 'A tiny deterministic source note.\n' > note.md
        chmod 644 wiki-cloud/log.md note.md
        PATH="$FARM:$PATH" invoke_tool ingest note.md --slug sample-note --contributor @fixture
        capture_footprint "$PWD" "$casedir"
    )
    rm -rf "$fixture"
}

A="$(mktemp -d)/case"
B="$(mktemp -d)/case"
run_capture "$A"
run_capture "$B"

# L-1 determinism check: two independent captures must be byte-identical on ALL channels.
assert_parity "$A" "$B" || { echo "FAIL: mutating capture not deterministic across two runs" >&2; exit 1; }

# The tree channel must be LOAD-BEARING: it records the dated source file ingest wrote.
grep -q 'sources/2026/2026-01/2026-01-02-sample-note' "$A/tree" || {
    echo "FAIL: tree channel does not record the ingested source (mutation not captured)" >&2
    cat "$A/tree" >&2
    exit 1
}

golden_check_or_freeze "$GOLD" "$A"
grep -qx '0' "$GOLD/exit" || { echo "FAIL: ingest mutating golden exit != 0" >&2; exit 1; }

echo "PASS: mutating-tool golden (ingest; deterministic; tree channel load-bearing)"
