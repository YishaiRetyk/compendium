#!/usr/bin/env bash
# tests/phase-12.1/test_neut08_live_denylist_contract.sh -- Phase 12.1 (NEUT-08).
# Any-NEUT-08-term contract per CONTEXT.md D-06 + SPEC #3 fidelity: parse live
# .neutrality-denylist.txt for first term under the Phase-12.1 unified header,
# seed it in a hermetic public-path fixture, assert gate fires (exit 2 + hit);
# negative-control: remove term, assert exit 0. Wave 0 RED until Plan 03 lands.
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
cd "$REPO_ROOT"

DENYLIST=".neutrality-denylist.txt"
SCRIPT="bin/check-neutrality.sh"

# 1. Locate anchor: first non-comment, non-empty line under the Phase-12.1
#    unified header literal. STRICT match — NO fallback to broad NEUT-08
#    substring. Fallback would silently pick the Phase-7 starter category's
#    `personal-decision-patterns` term, violating SPEC #3 ("a term promoted
#    in this phase"). Wave 0 RED is the desired state until Plan 03 commits
#    the unified header.
#    Anchor literal: # Category: Personal-vault terms expanded curation (NEUT-08, 2026-05-02)
#    (parens escaped in the awk regex below; awk pattern is functionally
#    equivalent to a literal-substring match on the header line.)
ANCHOR=$(awk '
  /^# *Category:.*Personal-vault terms expanded curation \(NEUT-08, 2026-05-02\)/ { in_block=1; next }
  in_block && /^# *Category:/  { exit }
  in_block && /^[[:space:]]*$/ { next }
  in_block && /^#/             { next }
  in_block && NF               { print; exit }
' "$DENYLIST")

# 2. Vacuous-pass guard (Pitfall 4): distinct exit-1 message when the
#    Phase-12.1 unified header is absent or empty. Substring
#    "Phase 12.1 curation has not landed yet" is the contributor-facing
#    RED-state hint per LOW #5 — anyone running the full phase suite
#    between Plan 01 commit and Plan 03 commit sees this directly.
if [ -z "$ANCHOR" ]; then
  echo "FAIL: no term found under '# Category: Personal-vault terms expanded curation (NEUT-08, 2026-05-02)' header in $DENYLIST — Phase 12.1 curation has not landed yet (or header was renamed)" >&2
  exit 1
fi
echo "anchor term: $ANCHOR"

# 3. Build hermetic fixture root with the anchor seeded in a public-path file.
#    --root is hermetic (mktemp -d); --denylist is LIVE (REPO_ROOT path) —
#    this is the Phase 12.1 critical delta vs Phase 7 N3 fixture-local denylist.
FIX=$(mktemp -d)
trap 'rm -rf "$FIX"' EXIT
mkdir -p "$FIX/wiki-cloud" "$FIX/docs"
printf '# Test fixture\nThis page contains the term %s for leak testing.\n' "$ANCHOR" > "$FIX/wiki-cloud/leak.md"

# 4. Positive case: gate must fire (exit 2 + grep -F hit on anchor).
#    grep -qF (fixed-string) is mandatory because future curated anchors
#    may contain regex metacharacters (`.`, `[`, `]`, `*`, `\`, `|`, `&`).
set +e
OUT=$(bash "$SCRIPT" --root "$FIX" --denylist "$REPO_ROOT/$DENYLIST" 2>&1)
RC=$?
set -e
if [ "$RC" -ne 2 ] || ! printf '%s' "$OUT" | grep -qF "$ANCHOR"; then
  echo "FAIL positive: expected exit 2 with hit on '$ANCHOR'; got exit $RC" >&2
  echo "$OUT" >&2
  exit 1
fi
echo "PASS positive: gate fires on '$ANCHOR'"

# 5. Negative-control: replace anchor with REDACTED via Python `str.replace()`
#    (literal-substring semantics). NOT sed — sed is regex-based and would
#    corrupt substitution semantics for any anchor containing regex metachars
#    (HIGH #1 fix from REVIEWS.md).
python3 - "$ANCHOR" "$FIX/wiki-cloud/leak.md" <<'PY'
import sys
anchor, path = sys.argv[1], sys.argv[2]
text = open(path, encoding="utf-8").read()
open(path, "w", encoding="utf-8").write(text.replace(anchor, "REDACTED"))
PY
set +e
OUT2=$(bash "$SCRIPT" --root "$FIX" --denylist "$REPO_ROOT/$DENYLIST" 2>&1)
RC2=$?
set -e
if [ "$RC2" -ne 0 ]; then
  echo "FAIL negative-control: expected exit 0 after removal; got exit $RC2" >&2
  echo "$OUT2" >&2
  exit 1
fi
echo "PASS negative-control: gate clean after removal"

echo "test_neut08_live_denylist_contract: 2 pass / 0 fail"
