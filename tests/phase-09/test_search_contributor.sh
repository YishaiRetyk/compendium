#!/usr/bin/env bash
# COLAB-07: --contributor filters wiki-cloud/log.md; accepts @handle or bare.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

# Build a tiny temp wiki with a log.md containing two contributor entries
TMP="$(mktemp -d -t srch-ctrb-XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/wiki-cloud"
# search.sh resolves WIKI_INDEX; seed an empty index
echo "# Index" > "$TMP/wiki-cloud/index.md"

cat > "$TMP/wiki-cloud/log.md" <<'LOG'
# Activity Log

## [2026-04-16] ingest | alice-work

contributor:: @alice

Alice ingested a source.

## [2026-04-16] ingest | bob-work

contributor:: @bob

Bob ingested a source.
LOG

pushd "$TMP" >/dev/null

# 1. @alice -> only alice entry
OUT1="$(invoke_tool_compat search --contributor @alice 2>&1)"
if ! echo "$OUT1" | grep -q "alice-work"; then
    echo "FAIL: --contributor @alice should find alice-work" >&2
    echo "$OUT1" >&2
    popd >/dev/null
    exit 1
fi
if echo "$OUT1" | grep -q "bob-work"; then
    echo "FAIL: --contributor @alice should NOT match bob-work" >&2
    popd >/dev/null
    exit 1
fi

# 2. bare `alice` (no @) -> same result
OUT2="$(invoke_tool_compat search --contributor alice 2>&1)"
if ! echo "$OUT2" | grep -q "alice-work"; then
    echo "FAIL: bare handle 'alice' should match same as '@alice'" >&2
    popd >/dev/null
    exit 1
fi

# 3. @nonexistent -> no results (exit 0 per search.sh convention)
OUT3="$(invoke_tool_compat search --contributor @nonexistent 2>&1 || true)"
if ! echo "$OUT3" | grep -qi "No results found"; then
    echo "FAIL: empty-result message missing" >&2
    echo "$OUT3" >&2
    popd >/dev/null
    exit 1
fi

popd >/dev/null
echo "PASS: --contributor filter (leading @ optional, no-match graceful)"
