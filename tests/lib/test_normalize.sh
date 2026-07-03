#!/usr/bin/env bash
# Seam self-test: normalize() redaction set pinned + WRONG contractual values NOT masked
# (cycle-1 HIGH#2 resolution preserved: time-bearing timestamps + tmp/fixture paths ONLY).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/normalize.sh"

fail() { echo "FAIL: $1" >&2; exit 1; }

# 1. Time-bearing timestamp -> <TS>; /tmp path -> <TMP>.
out="$(printf 'run at 2026-07-03T01:02:03Z in /tmp/workdir42\n' | normalize)"
echo "$out" | grep -q '<TS>' || fail "T-timestamp not redacted: $out"
echo "$out" | grep -q '<TMP>' || fail "/tmp path not redacted: $out"
echo "$out" | grep -q '2026-07-03T' && fail "timestamp survived: $out"

# 2. Bare contractual date PRESERVED; a WRONG date is NOT masked (diffs from the right one).
right="$(printf 'created: 2024-03-15\n' | normalize)"
wrong="$(printf 'created: 2024-03-16\n' | normalize)"
[ "$right" = "created: 2024-03-15" ] || fail "bare date was altered: $right"
[ "$right" != "$wrong" ] || fail "wrong bare date masked into equality (false parity risk)"

# 3. Contractual ID/hash tokens PRESERVED; wrong ones differ after normalization.
h_right="$(printf 'sha256:0123abcd0123abcd\n' | normalize)"
h_wrong="$(printf 'sha256:0123abcd0123abce\n' | normalize)"
[ "$h_right" = "sha256:0123abcd0123abcd" ] || fail "hash token altered: $h_right"
[ "$h_right" != "$h_wrong" ] || fail "wrong hash masked into equality"
id_right="$(printf 'dr-2024-03-15-slug\n' | normalize)"
[ "$id_right" = "dr-2024-03-15-slug" ] || fail "ID token altered: $id_right"

# 4. A lint-style JSON array is NOT reordered.
json='[
  {"severity": "error", "message": "first"},
  {"severity": "error", "message": "second"}
]'
out="$(printf '%s\n' "$json" | normalize)"
[ "$out" = "$json" ] || fail "normalize altered/reordered JSON: $out"
first_line_no="$(printf '%s\n' "$out" | grep -n '"first"' | cut -d: -f1)"
second_line_no="$(printf '%s\n' "$out" | grep -n '"second"' | cut -d: -f1)"
[ "$first_line_no" -lt "$second_line_no" ] || fail "JSON order changed"

echo "PASS: normalize redaction pinned; wrong contractual values not masked; order preserved"
