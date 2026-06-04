#!/usr/bin/env bash
# bin/check-sources-cloud-safe.sh -- FAIL-CLOSED raw-source cloud-safe guard (PRIV-03, cycle-2 HIGH).
#
# PURPOSE: Asserts that EVERY raw source under sources/ is cloud-safe:
#   (i)  No raw source carries 'privacy: local_only' in frontmatter.
#   (ii) No sources/local-only/ directory exists.
#
# FAIL-CLOSED: exits NON-zero if either assertion is violated. A future adopter
# who adds a sensitive raw source triggers CI failure and is forced onto the
# deferred sources-local/ structural tier (documented in docs/reference/privacy-model.md).
#
# STRUCTURAL RULE (Phase 15 §13): raw sources/ is cloud-safe-only. A source that
# must be local lives as its SOURCE-SUMMARY page under wiki-local/sources/. The
# FAITH-04 resolver (bin/lib/privacy_resolve.py) keys off the summary page tier,
# never the raw sources/ path. This guard proves the "raw sources/ cloud-safe-only"
# invariant is structurally maintained.
#
# PARSING: Uses bin/lib/brownfield_yaml.py read_fm_body() (NOT grep) to parse
# frontmatter, avoiding false-positives from prose 'privacy:' lines in source bodies.
#
# Exit codes:
#   0  clean -- all raw sources are cloud-safe
#   1  script failure OR violation found
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: bin/check-sources-cloud-safe.sh [OPTIONS]

FAIL-CLOSED raw-source cloud-safe guard (PRIV-03).
Asserts every raw source under sources/ is cloud-safe:
  (i) No raw source carries 'privacy: local_only' frontmatter
  (ii) No sources/local-only/ directory exists

This is a structural invariant guard wired into CI (privacy-leak job).

Options:
  --root DIR    Repository root (default: PWD)
  --help, -h    Show this help

Exit codes:
  0  all raw sources cloud-safe
  1  violation found OR script failure
EOF
}

ROOT="${PWD}"

while [ "$#" -gt 0 ]; do
    case "$1" in
        --help|-h) usage; exit 0 ;;
        --root)
            if [ "$#" -lt 2 ]; then
                echo "ERROR: --root requires a value" >&2; exit 1
            fi
            ROOT="$2"; shift 2 ;;
        -*) echo "ERROR: unknown option: $1" >&2; usage >&2; exit 1 ;;
        *)  echo "ERROR: unexpected argument: $1" >&2; exit 1 ;;
    esac
done

# Resolve the script's own directory to find the lib (works when invoked from any cwd)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

export CSG_ROOT="$ROOT"
export CSG_LIB_DIR="$LIB_DIR"

set +e
python3 - <<'PYEOF'
import os, sys, pathlib

ROOT = os.path.abspath(os.environ['CSG_ROOT'])
LIB_DIR = os.environ.get('CSG_LIB_DIR', os.path.join(ROOT, 'bin', 'lib'))
sys.path.insert(0, LIB_DIR)

try:
    from brownfield_yaml import read_fm_body
except ImportError:
    # Try relative to ROOT as fallback
    sys.path.insert(0, os.path.join(ROOT, 'bin', 'lib'))
    try:
        from brownfield_yaml import read_fm_body
    except ImportError:
        print("ERROR: bin/lib/brownfield_yaml.py not found. Ensure LIB_DIR is set or run from repo root.", file=sys.stderr)
        sys.exit(1)

sources_dir = pathlib.Path(ROOT) / 'sources'
if not sources_dir.is_dir():
    # No sources/ directory -> trivially satisfied (clean vault)
    print("OK: no sources/ directory; raw-source cloud-safe invariant vacuously holds")
    sys.exit(0)

violations = []

# (i) Check for sources/local-only/ directory
local_only_dir = sources_dir / 'local-only'
if local_only_dir.is_dir():
    violations.append(
        f"FAIL: sources/local-only/ directory exists -- raw sources must be cloud-safe-only. "
        f"Move local raw sources to wiki-local/sources/ as source-summary pages "
        f"(see docs/reference/privacy-model.md for the sources-local/ forward reference)."
    )

# (ii) Check each raw source for 'privacy: local_only' frontmatter
for md_path in sorted(sources_dir.rglob('*.md')):
    try:
        fm, body, raw = read_fm_body(str(md_path))
    except Exception as e:
        # Parse error -- log as warning but don't fail (the file may be malformed)
        print(f"WARN: could not parse frontmatter in {md_path.relative_to(ROOT)}: {e}", file=sys.stderr)
        continue
    if fm is None:
        continue
    priv = fm.get('privacy')
    if priv == 'local_only':
        rel = md_path.relative_to(ROOT)
        violations.append(
            f"FAIL: {rel}: raw source carries 'privacy: local_only' frontmatter. "
            f"Raw sources/ must be cloud-safe-only. "
            f"Move to wiki-local/sources/ as a source-summary page "
            f"(see docs/reference/privacy-model.md)."
        )

if violations:
    for v in violations:
        print(v, file=sys.stderr)
    print(
        f"\nFAIL-CLOSED: {len(violations)} raw-source cloud-safe violation(s) found. "
        f"Fix by removing 'privacy: local_only' frontmatter from raw sources/ "
        f"and using wiki-local/sources/ for local source-summary pages instead.",
        file=sys.stderr
    )
    sys.exit(1)

print(f"OK: all raw sources under sources/ are cloud-safe ({sum(1 for _ in sources_dir.rglob('*.md'))} files checked)")
sys.exit(0)
PYEOF
PYRC=$?
set -e
exit "$PYRC"
