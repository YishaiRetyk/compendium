#!/usr/bin/env bash
# bin/check-privacy.sh -- Phase 15 structural privacy PATH guard (CI-07, re-keyed).
#
# PURPOSE: Detect wiki-local/ PATH leaks into public-facing surfaces (docs/, examples/,
# AGENTS.md, CLAUDE.md, README.md, etc.). This is a PATH/release-allowlist guard, NOT
# a content-equivalence scanner -- it catches cases where a file's path contains
# 'wiki-local/' within a PUBLIC_PATH tree. Content-term leaks belong to bin/check-neutrality.sh.
#
# LIMITATION (Phase 15 MEDIUM #2): This guard catches docs/wiki-local/... paths but NOT
# arbitrary local content pasted into docs/private.md without a wiki-local/ path component.
# The content-leak surface is covered by check-neutrality.sh (term-scan of wiki-local/ tokens
# against public paths). Do NOT over-promise: check-privacy is a path/release guard only.
#
# Full-tree scan (D-13) -- no diff-only mode. Catches pre-existing leaks.
#
# Exit codes:
#   0  clean -- no wiki-local/ paths in public surfaces
#   1  script failure (missing python3, bad args)
#   2  wiki-local/ path found in a PUBLIC_PATH (leak detected)
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: bin/check-privacy.sh [OPTIONS]

Phase 15 structural privacy PATH guard.
Scans PUBLIC_PATHS for files whose path contains 'wiki-local/'
(i.e., wiki-local/ content copied into a public-facing surface).

This is a PATH guard (not a content-equivalence scanner).
Content-term leaks are covered by bin/check-neutrality.sh.

Options:
  --root DIR              Scan root (default: PWD)
  --format text|json      Output format (default: text; json -> stdout array)
  --help, -h              Show this help

Scope:
  PUBLIC_PATHS scanned: examples/, docs/, AGENTS.md, CLAUDE.md, README.md, PRIVACY.md, .github/, schema/
  TRIGGER:              Any file whose path component contains 'wiki-local/'

Exit codes:
  0  clean
  1  script failure
  2  wiki-local/ path found in public surface (leak)
EOF
}

ROOT="${PWD}"
FORMAT="text"

while [ "$#" -gt 0 ]; do
    case "$1" in
        --help|-h) usage; exit 0 ;;
        --root)
            if [ "$#" -lt 2 ]; then
                echo "ERROR: --root requires a value" >&2; exit 1
            fi
            ROOT="$2"; shift 2 ;;
        --format)
            if [ "$#" -lt 2 ]; then
                echo "ERROR: --format requires a value (text or json)" >&2; exit 1
            fi
            case "$2" in
                text|json) FORMAT="$2" ;;
                *) echo "ERROR: --format must be 'text' or 'json'" >&2; exit 1 ;;
            esac
            shift 2 ;;
        -*) echo "ERROR: unknown option: $1" >&2; usage >&2; exit 1 ;;
        *)  echo "ERROR: unexpected argument: $1" >&2; exit 1 ;;
    esac
done

# PUBLIC_PATHS: files/dirs that ship in the public release template.
# Changing this array requires a PR (intentional review lever).
PUBLIC_PATHS=(examples docs AGENTS.md CLAUDE.md README.md PRIVACY.md .github schema)

# Export env for python3 heredoc (no jq dependency)
export CP_ROOT="$ROOT"
export CP_FORMAT="$FORMAT"
export CP_PUBLIC_PATHS="$(IFS=:; echo "${PUBLIC_PATHS[*]}")"

set +e
python3 - <<'PYEOF'
import os, sys, json

ROOT = os.path.abspath(os.environ['CP_ROOT'])
FORMAT = os.environ.get('CP_FORMAT', 'text')
PUBLIC_PATHS = os.environ['CP_PUBLIC_PATHS'].split(':')

WIKI_LOCAL_TOKEN = 'wiki-local'

def path_contains_wiki_local(rel_path):
    """Return True iff the relative path contains a 'wiki-local' path component."""
    parts = rel_path.replace('\\', '/').split('/')
    return WIKI_LOCAL_TOKEN in parts

def scan():
    hits = []
    for rel in PUBLIC_PATHS:
        full = os.path.join(ROOT, rel)
        if not os.path.exists(full):
            continue
        targets = []
        if os.path.isfile(full):
            targets.append(full)
        else:
            for dirpath, dirnames, files in os.walk(full):
                dirnames[:] = [d for d in dirnames if d not in ('.git', 'node_modules')]
                for fn in files:
                    targets.append(os.path.join(dirpath, fn))
        for t in targets:
            rel_path = os.path.relpath(t, ROOT)
            if path_contains_wiki_local(rel_path):
                hits.append({
                    'path': rel_path,
                    'line': 0,
                    'message': f"wiki-local/ path component found in public surface '{rel}' (structural privacy leak, CI-07)",
                })
    hits.sort(key=lambda h: h['path'])
    if FORMAT == 'json':
        print(json.dumps(hits, indent=2))
    else:
        for h in hits:
            print(f"{h['path']}: wiki-local/ content in public path (structural privacy leak)", file=sys.stderr)
    sys.exit(2 if hits else 0)

scan()
PYEOF
PYRC=$?
set -e
exit "$PYRC"
