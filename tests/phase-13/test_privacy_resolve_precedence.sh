#!/usr/bin/env bash
# Phase 15 structural path-prefix contract for resolve_source_privacy.
# The §13 three-level frontmatter precedence ladder is GONE.
# The new contract: source SUMMARY path under wiki-local/ -> local_only; else cloud_safe.
# (Previously asserted the 7-row Privacy Decision Table; now asserts the structural predicate.)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

python3 - "$REPO_ROOT" <<'PY'
import sys
sys.path.insert(0, sys.argv[1] + '/bin/lib')
from privacy_resolve import resolve_source_privacy as r

# Structural contract: summary path under wiki-local/ -> local_only
assert r('wiki-local/sources/src-2026-04-10-personal.md') == 'local_only', \
    'summary under wiki-local/sources/ must resolve local_only'

# Structural contract: summary path under wiki-cloud/ -> cloud_safe
assert r('wiki-cloud/sources/src-2026-03-15-vaswani.md') == 'cloud_safe', \
    'summary under wiki-cloud/sources/ must resolve cloud_safe'

# Structural contract: raw sources/ path is NEVER the signal (sources/ is cloud-safe-only)
# A raw sources/ path resolves cloud_safe (it is NOT under wiki-local/)
assert r('sources/2026/2026-04/personal/source.md') == 'cloud_safe', \
    'raw sources/ path resolves cloud_safe (sources/ is cloud-safe-only; use wiki-local/sources/ for local summaries)'

# Empty/None -> cloud_safe (no wiki-local/ prefix -> not local)
assert r('') == 'cloud_safe', 'empty path -> cloud_safe'
assert r(None) == 'cloud_safe', 'None path -> cloud_safe'

# wiki-local/ subdir variations
assert r('wiki-local/concepts/personal-goals.md') == 'local_only', 'wiki-local/concepts/ is local'
assert r('wiki-local/maintenance/audit-state.md') == 'local_only', 'wiki-local/maintenance/ is local'

print('OK: structural path-prefix contract verified')
PY

echo "PASS: resolve_source_privacy honors §13 structural wiki-local/ path-prefix predicate (Phase 15)"
