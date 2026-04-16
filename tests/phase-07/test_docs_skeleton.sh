#!/usr/bin/env bash
# test_docs_skeleton.sh — asserts docs/ four-track skeleton + Diátaxis mapping + quickstart stub constraints.
set -euo pipefail

FAIL=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAIL=1; }

ROOT="${ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "$ROOT"

# All four top-level docs files exist
for f in docs/README.md docs/quickstart.md docs/guided-setup.md docs/manual-setup.md; do
  if [ -f "$f" ]; then pass "$f exists"; else fail "$f missing"; fi
done

# docs/README.md contains Diátaxis (case-insensitive, allows accented + unaccented)
if grep -qi 'di[aá]taxis' docs/README.md; then
  pass "docs/README.md names Diátaxis"
else
  fail "docs/README.md missing Diátaxis mention"
fi

# docs/README.md links to all four tracks
for link in quickstart.md guided-setup.md manual-setup.md reference; do
  if grep -q "$link" docs/README.md; then
    pass "docs/README.md links to $link"
  else
    fail "docs/README.md missing link to $link"
  fi
done

# Quickstart content markers (updated Phase 8: stubs populated; Phase-8 marker no longer required post-population)
grep -q 'bin/init-wizard.sh' docs/quickstart.md && pass "quickstart.md names bin/init-wizard.sh" || fail "quickstart.md missing bin/init-wizard.sh"
grep -q 'bin/ingest.sh' docs/quickstart.md && pass "quickstart.md names bin/ingest.sh" || fail "quickstart.md missing bin/ingest.sh"
grep -qi 'obsidian' docs/quickstart.md && pass "quickstart.md mentions Obsidian" || fail "quickstart.md missing Obsidian"

# Quickstart size: stub was ≤60 lines per Phase 7 D-11; Phase 8 populates it but still targets ≤80 lines as a tutorial-length cap.
LINES=$(wc -l < docs/quickstart.md)
if [ "$LINES" -le 80 ]; then
  pass "quickstart.md is ≤80 lines ($LINES lines) — populated tutorial within cap"
else
  fail "quickstart.md is $LINES lines (must be ≤80)"
fi

exit "$FAIL"
