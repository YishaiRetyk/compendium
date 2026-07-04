#!/usr/bin/env bash
# test_kahneman_moved.sh — Phase 07 Plan 02
# Asserts Kahneman cluster relocated to examples/; wiki-cloud/ content dirs kahneman-free;
# local_only creator content and wiki-cloud/maintenance/ deleted; wikilinks resolve.
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

# 2. Scoped leak check: DISTINCTIVE Kahneman-cluster markers must not appear in wiki-cloud/
#    content dirs. Generic terms the live vault legitimately uses in unrelated real pages
#    (`decision-making` — e.g. "decision-making culture"; `cognitive-biases`) are NOT
#    distinctive leak signals and are excluded — a genuine cluster-page leak still carries
#    `kahneman` + the distinctive concept names. (check-neutrality.sh is the primary guard.)
KAHN_RE='kahneman|prospect-theory|loss-aversion|system-1-vs-system-2|thinking-fast'
HITS=""
for d in wiki-cloud/entities wiki-cloud/concepts wiki-cloud/comparisons wiki-cloud/overviews wiki-cloud/sources; do
  if [ -d "$d" ]; then
    m=$(find "$d" -name '*.md' -print0 2>/dev/null | xargs -0 -r grep -lEi "$KAHN_RE" 2>/dev/null || true)
    if [ -n "$m" ]; then HITS="$HITS $m"; fi
  fi
done
if [ -z "$HITS" ]; then
  pass "no Kahneman strings in wiki-cloud/ content dirs"
else
  fail "Kahneman strings found in wiki-cloud/ content dirs:$HITS"
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
        # amos-tversky / bounded-rationality are INTENTIONAL red-links: real referents in
        # Kahneman's world (his lifelong collaborator; a related concept) that the example
        # deliberately references without expanding into their own pages. Red-links are a
        # documented feature (schema/reference/wikilinks.md); the check still catches any
        # OTHER (typo'd / unexpected) unresolved in-cluster link.
        if target not in slugs and target not in {"index", "log", "amos-tversky", "bounded-rationality"}:
            bad.append((str(p), target))
if bad:
    for b in bad: print("UNRESOLVED:", b, file=sys.stderr)
    sys.exit(1)
PY
then pass "in-cluster wikilinks resolve"
else fail "some in-cluster wikilinks unresolved"
fi

# 4. local_only personal content deleted.
for f in wiki-cloud/overviews/personal-decision-patterns.md wiki-cloud/sources/src-2026-04-10-personal-decision-journal.md; do
  if [ ! -e "$f" ]; then pass "deleted: $f"; else fail "still exists (must be deleted): $f"; fi
done

# 5. wiki-cloud/maintenance/ may exist (it holds lint-report.md per Phase 15 design);
# assert audit control-plane files are NOT in wiki-cloud/maintenance/ (they're in wiki-local/).
for audit_file in wiki-cloud/maintenance/audit-report.md wiki-cloud/maintenance/audit-state.md; do
  if [ ! -e "$audit_file" ]; then pass "audit file correctly absent from cloud tier: $audit_file"
  else fail "audit file should be in wiki-local/maintenance/, not wiki-cloud/: $audit_file"; fi
done

echo
echo "test_kahneman_moved: $PASS pass / $FAIL fail"
[ "$FAIL" -eq 0 ]
