#!/usr/bin/env bash
# test_kahneman_moved.sh — Phase 07 Plan 02
# Asserts Kahneman cluster relocated to examples/; wiki/ content dirs kahneman-free;
# local_only creator content and wiki/maintenance/ deleted; wikilinks resolve.
set -euo pipefail

PASS=0
FAIL=0
fail() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }
pass() { echo "PASS: $1"; PASS=$((PASS+1)); }

# Resolve repo root from this script's location.
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
cd "$REPO_ROOT"

# 1. All 7 Kahneman pages + 2 sources exist under examples/kahneman/.
for f in \
  examples/kahneman/entities/daniel-kahneman.md \
  examples/kahneman/concepts/prospect-theory.md \
  examples/kahneman/concepts/loss-aversion.md \
  examples/kahneman/concepts/cognitive-biases.md \
  examples/kahneman/comparisons/system-1-vs-system-2.md \
  examples/kahneman/overviews/decision-making.md \
  examples/kahneman/sources/src-2026-04-09-thinking-fast-and-slow-part1.md \
  examples/kahneman/sources/src-2026-04-10-kahneman-prospect-theory.md; do
  if [ -f "$f" ]; then pass "exists: $f"; else fail "missing: $f"; fi
done

# 2. Scoped Kahneman-string check on wiki/ content dirs (not decisions/, not maintenance/).
KAHN_RE='kahneman|prospect-theory|loss-aversion|cognitive-biases|system-1-vs-system-2|decision-making|thinking-fast'
HITS=""
for d in wiki/entities wiki/concepts wiki/comparisons wiki/overviews wiki/sources; do
  if [ -d "$d" ]; then
    m=$(find "$d" -name '*.md' -print0 2>/dev/null | xargs -0 -r grep -lEi "$KAHN_RE" 2>/dev/null || true)
    if [ -n "$m" ]; then HITS="$HITS $m"; fi
  fi
done
if [ -z "$HITS" ]; then
  pass "no Kahneman strings in wiki/ content dirs"
else
  fail "Kahneman strings found in wiki/ content dirs:$HITS"
fi

# 3. In-cluster wikilinks resolve.
if python3 - <<'PY'
import re, pathlib, sys
root = pathlib.Path("examples/kahneman")
slugs = {p.stem for p in root.rglob("*.md")}
bad = []
for p in root.rglob("*.md"):
    for m in re.finditer(r"\[\[([a-z0-9-]+)(?:\|[^\]]*)?\]\]", p.read_text()):
        target = m.group(1)
        if target not in slugs and target not in {"index","log"}:
            bad.append((str(p), target))
if bad:
    for b in bad: print("UNRESOLVED:", b, file=sys.stderr)
    sys.exit(1)
PY
then pass "in-cluster wikilinks resolve"
else fail "some in-cluster wikilinks unresolved"
fi

# 4. local_only personal content deleted.
for f in wiki/overviews/personal-decision-patterns.md wiki/sources/src-2026-04-10-personal-decision-journal.md; do
  if [ ! -e "$f" ]; then pass "deleted: $f"; else fail "still exists (must be deleted): $f"; fi
done

# 5. wiki/maintenance/ directory does not exist.
if [ ! -d wiki/maintenance ]; then pass "wiki/maintenance/ removed"; else fail "wiki/maintenance/ still exists"; fi

echo
echo "test_kahneman_moved: $PASS pass / $FAIL fail"
[ "$FAIL" -eq 0 ]
