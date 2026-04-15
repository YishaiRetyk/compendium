#!/usr/bin/env bash
# test_neutrality_gate.sh -- Phase 07 Plan 05 (NEUT-06 + NEUT-08).
# Asserts bin/check-neutrality.sh: clean, Kahneman leak, examples exempt,
# case-insensitive, deterministic --suggest-denylist, missing denylist,
# help documents sources/rule, --show-stopwords.
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
cd "$REPO_ROOT"

FIX_DIR="tests/phase-07/fixtures/neutrality"
SCRIPT="bin/check-neutrality.sh"

PASS=0
FAIL=0
report() {
  if [ "$2" -eq 0 ]; then echo "PASS $1"; PASS=$((PASS+1));
  else echo "FAIL $1"; FAIL=$((FAIL+1)); fi
}

run_rc() {
  # $1 = fixture subdir (relative to FIX_DIR), rest = extra args
  local sub="$1"; shift
  set +e
  bash "$SCRIPT" --root "$FIX_DIR/$sub" --denylist "$FIX_DIR/$sub/denylist.txt" "$@" >/dev/null 2>&1
  local rc=$?
  set -e
  echo "$rc"
}

# N1: clean fixture -> exit 0
rc=$(run_rc clean); [ "$rc" -eq 0 ] && report N1_clean 0 || report N1_clean 1

# N2: Kahneman leak -> exit 2 (stderr names path + term)
set +e
OUT=$(bash "$SCRIPT" --root "$FIX_DIR/leak-kahneman" --denylist "$FIX_DIR/leak-kahneman/denylist.txt" 2>&1)
RC=$?
set -e
if [ "$RC" -eq 2 ] && echo "$OUT" | grep -qi 'kahneman' && echo "$OUT" | grep -q 'AGENTS.md'; then
  report N2_leak_kahneman 0
else
  report N2_leak_kahneman 1
fi

# N4: examples dir is exempt -> exit 0 even with kahneman content
rc=$(run_rc example-ok); [ "$rc" -eq 0 ] && report N4_examples_exempt 0 || report N4_examples_exempt 1

# N5: case-insensitive (fixture content "Daniel Kahneman", denylist "kahneman")
# Uppercase test: inject uppercase content into a temp fixture
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
cp -a "$FIX_DIR/leak-kahneman/." "$TMP/"
printf '# README\nKAHNEMAN ALL CAPS.\n' > "$TMP/README.md"
set +e
bash "$SCRIPT" --root "$TMP" --denylist "$TMP/denylist.txt" >/dev/null 2>&1
RC=$?
set -e
[ "$RC" -eq 2 ] && report N5_case_insensitive 0 || report N5_case_insensitive 1

# N6: --suggest-denylist is deterministic (byte-identical on two back-to-back runs)
# Use the leak-personal fixture as a stand-in corpus; write a synthesized .planning/notes
TMP2=$(mktemp -d)
mkdir -p "$TMP2/.planning/notes"
printf -- '---\nprivacy: local_only\n---\nNotes about kahneman and loss-aversion.\n' > "$TMP2/.planning/notes/note1.md"
printf 'Another personal-term-xyz reference.\n' >> "$TMP2/.planning/notes/note1.md"
O1=$(bash "$SCRIPT" --suggest-denylist --root "$TMP2" 2>/dev/null)
O2=$(bash "$SCRIPT" --suggest-denylist --root "$TMP2" 2>/dev/null)
rm -rf "$TMP2"
if [ "$O1" = "$O2" ] && [ -n "$O1" ]; then
  report N6_suggest_deterministic 0
else
  report N6_suggest_deterministic 1
fi

# N8: missing denylist (non-suggest mode) -> exit 1
TMP3=$(mktemp -d)
mkdir -p "$TMP3"
printf 'clean\n' > "$TMP3/README.md"
set +e
bash "$SCRIPT" --root "$TMP3" --denylist "$TMP3/nonexistent.txt" >/dev/null 2>&1
RC=$?
set -e
rm -rf "$TMP3"
[ "$RC" -eq 1 ] && report N8_missing_denylist 0 || report N8_missing_denylist 1

# N9: help documents suggest-mode sources + extraction rule
HELP=$(bash "$SCRIPT" --help 2>&1)
if echo "$HELP" | grep -q 'Suggest-mode input sources' && echo "$HELP" | grep -q 'Extraction rule'; then
  report N9_help_documents 0
else
  report N9_help_documents 1
fi

# N10: --show-stopwords prints embedded list with common + domain words
SW=$(bash "$SCRIPT" --show-stopwords 2>&1)
if echo "$SW" | grep -q '^the$' && echo "$SW" | grep -q '^decision$'; then
  report N10_show_stopwords 0
else
  report N10_show_stopwords 1
fi

echo ""
echo "test_neutrality_gate: $PASS pass / $FAIL fail"
[ "$FAIL" -eq 0 ]
