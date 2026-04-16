#!/usr/bin/env bash
# bin/sync-claude.sh -- TMPL-10, D-03: AGENTS.md -> CLAUDE.md byte copy.
# Idempotent. Zero deps.
set -euo pipefail

SRC="AGENTS.md"
DST="CLAUDE.md"
CHECK_ONLY=0

while [ "$#" -gt 0 ]; do
    case "$1" in
        --help|-h) echo "Usage: bin/sync-claude.sh [--check]"; exit 0 ;;
        --check) CHECK_ONLY=1; shift ;;
        *) echo "ERROR: unknown arg: $1" >&2; exit 1 ;;
    esac
done

[ -f "$SRC" ] || { echo "ERROR: $SRC missing" >&2; exit 1; }

if [ "$CHECK_ONLY" -eq 1 ]; then
    if [ ! -f "$DST" ]; then
        echo "DRIFT: $DST missing" >&2; exit 2
    fi
    if ! cmp -s "$SRC" "$DST"; then
        echo "DRIFT: $DST differs from $SRC. Run: bash bin/sync-claude.sh && git add $DST" >&2
        exit 2
    fi
    echo "OK: $SRC == $DST"
    exit 0
fi

cp "$SRC" "$DST"
cmp -s "$SRC" "$DST" || { echo "ERROR: post-copy byte-mismatch (should be impossible)" >&2; exit 1; }
echo "Synced $SRC -> $DST"
