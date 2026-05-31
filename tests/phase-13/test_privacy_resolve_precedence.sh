#!/usr/bin/env bash
# FAITH-04 / §13: resolve_source_privacy across the Privacy Decision Table:
# frontmatter-explicit, dir-default, system-default, and a frontmatter-vs-dir
# conflict resolving to the stricter local_only. Pure-function unit test (no
# audit run needed) -- exercises bin/lib/privacy_resolve.py directly.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

python3 - "$REPO_ROOT" <<'PY'
import sys
sys.path.insert(0, sys.argv[1] + '/bin/lib')
from privacy_resolve import resolve_source_privacy as r

# Row 1: both agree cloud_safe
assert r({'privacy': 'cloud_safe'}, 'sources/cloud-safe/x.md') == 'cloud_safe', 'row1'
# Row 2: frontmatter local_only stricter wins over cloud-safe dir
assert r({'privacy': 'local_only'}, 'sources/cloud-safe/x.md') == 'local_only', 'row2'
# Row 3: cloud_safe frontmatter vs local-only dir -> stricter local_only wins
assert r({'privacy': 'cloud_safe'}, 'sources/local-only/x.md') == 'local_only', 'row3'
# Row 4: no frontmatter, dir provides cloud_safe
assert r({}, 'sources/cloud-safe/x.md') == 'cloud_safe', 'row4'
# Row 5: no frontmatter, no privacy-dir signal -> system default local_only
assert r({}, 'sources/2026/2026-04/x.md') == 'local_only', 'row5'
# Row 6: nothing at all -> fail-closed local_only
assert r(None, '') == 'local_only', 'row6'
# Row 7: explicit local_only confirmed
assert r({'privacy': 'local_only'}, 'sources/2026/x.md') == 'local_only', 'row7'
# Unknown enum value -> fail-closed local_only
assert r({'privacy': 'bogus'}, 'sources/2026/x.md') == 'local_only', 'unknown-enum'
print('OK')
PY

echo "PASS: resolve_source_privacy honors §13 three-level precedence + stricter-wins"
