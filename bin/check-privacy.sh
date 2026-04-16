#!/usr/bin/env bash
# bin/check-privacy.sh -- CI-07 privacy-leak guard.
# Scans YAML frontmatter under PUBLIC_PATHS for `privacy: local_only`.
# Pattern-twin of bin/check-neutrality.sh (Phase 7 NEUT-06).
#
# Rationale: `local_only` is a valid user-content tier inside `wiki/**`
# (AGENTS.md §13). This guard prevents it from LEAKING into public-facing
# surfaces that ship in the template repo. Changing PUBLIC_PATHS requires
# a PR -- the correct review loop for scope changes.
#
# Full-tree scan (D-13) -- no diff-only mode. Catches pre-existing leaks.
# Frontmatter-only (D-14) -- prose mentions in body text are not flagged.
#
# Exit codes:
#   0  clean -- no leaks
#   1  script failure (missing python3, bad args)
#   2  privacy-leak found
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: bin/check-privacy.sh [OPTIONS]

Scans public control-plane paths for `privacy: local_only` frontmatter leaks.

Options:
  --root DIR              Scan root (default: PWD)
  --format text|json      Output format (default: text; json -> stdout array)
  --help, -h              Show this help

Scope (D-15):
  PUBLIC_PATHS scanned: examples/, docs/, AGENTS.md, CLAUDE.md, README.md, PRIVACY.md, .github/
  EXPLICITLY EXCLUDED:  wiki/** (local_only is valid user content per AGENTS.md §13)

Exit codes:
  0  clean
  1  script failure
  2  privacy-leak found
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

# D-15: hardcoded PUBLIC_PATHS. wiki/** EXCLUDED.
# PRIVACY.md included (Gemini LOW review fix, 2026-04-16) -- parity with bin/check-neutrality.sh;
# PRIVACY.md exists at repo root as a top-level public doc.
# Changing this array requires a PR (intentional review lever).
PUBLIC_PATHS=(examples docs AGENTS.md CLAUDE.md README.md PRIVACY.md .github)

# Export env for python3 heredoc (no jq dependency, consistent with Phase 7/8 pattern)
export CP_ROOT="$ROOT"
export CP_FORMAT="$FORMAT"
export CP_PUBLIC_PATHS="$(IFS=:; echo "${PUBLIC_PATHS[*]}")"

set +e
python3 - <<'PYEOF'
import os, re, sys, json

ROOT = os.path.abspath(os.environ['CP_ROOT'])
FORMAT = os.environ.get('CP_FORMAT', 'text')
PUBLIC_PATHS = os.environ['CP_PUBLIC_PATHS'].split(':')

# D-14: match `privacy: local_only` ONLY within `^---...^---` frontmatter block
PRIVACY_LOCAL_ONLY_RE = re.compile(r'^privacy:\s*local_only\s*$', re.M)

def parse_frontmatter_block(text):
    """Return frontmatter text between first two `^---` markers, or None."""
    if not text.startswith('---'):
        return None
    # Find closing `---` on its own line
    m = re.search(r'\n---\s*$|\n---\s*\n', text, re.M)
    if not m:
        return None
    return text[3:m.start()]

def scan():
    hits = []
    for rel in PUBLIC_PATHS:
        full = os.path.join(ROOT, rel)
        if not os.path.exists(full):
            continue
        targets = []
        if os.path.isfile(full):
            if full.endswith('.md'):
                targets.append(full)
        else:
            for dirpath, dirnames, files in os.walk(full):
                # Prune common junk
                dirnames[:] = [d for d in dirnames if d not in ('.git', 'node_modules')]
                for fn in files:
                    if fn.endswith('.md'):
                        targets.append(os.path.join(dirpath, fn))
        for t in targets:
            try:
                content = open(t, encoding='utf-8', errors='replace').read()
            except OSError:
                continue
            fm = parse_frontmatter_block(content)
            if fm is None:
                continue
            m = PRIVACY_LOCAL_ONLY_RE.search(fm)
            if not m:
                continue
            # Compute line number within frontmatter block (add 1 for opening ---, +1 for 1-indexed)
            line_within_fm = fm[:m.start()].count('\n') + 1
            abs_line = line_within_fm + 1  # +1 for opening `---` line
            hits.append({
                'path': os.path.relpath(t, ROOT),
                'line': abs_line,
                'message': 'privacy: local_only in public path (CI-07)',
            })
    hits.sort(key=lambda h: (h['path'], h['line']))
    if FORMAT == 'json':
        print(json.dumps(hits, indent=2))
    else:
        for h in hits:
            print(f"{h['path']}:{h['line']}: privacy: local_only leaked into public path", file=sys.stderr)
    sys.exit(2 if hits else 0)

scan()
PYEOF
PYRC=$?
set -e
exit "$PYRC"
