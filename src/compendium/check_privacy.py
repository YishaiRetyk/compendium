# src/compendium/check_privacy.py -- Phase 15 structural privacy PATH guard (CI-07, re-keyed).
# Phase 25 MIG-03 byte-parity port of bin/check-privacy.sh: main() replicates the
# bash arg loop exactly (same error strings/streams/exit codes, usage text verbatim),
# exports the same CP_* env keys, then run() executes the bash python3-heredoc body
# verbatim. Do NOT "improve" observable behavior -- the parity oracle diffs
# stdout/stderr/exit against the frozen bash implementation.
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
#   1  script failure (bad args)
#   2  wiki-local/ path found in a PUBLIC_PATH (leak detected)
import json
import os
import sys

# Usage text extracted VERBATIM from the bin/check-privacy.sh usage() heredoc.
USAGE = """Usage: bin/check-privacy.sh [OPTIONS]

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
"""

# PUBLIC_PATHS: files/dirs that ship in the public release template.
# Changing this array requires a PR (intentional review lever).
PUBLIC_PATHS_DEFAULT = [
    "examples", "docs", "AGENTS.md", "CLAUDE.md", "README.md",
    "PRIVACY.md", ".github", "schema",
]

# ---------------------------------------------------------------------------
# Heredoc body (ported verbatim from the bin/check-privacy.sh python3 heredoc).
# The CP_*-derived configuration globals are read by run().
# ---------------------------------------------------------------------------

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


def run():
    """Execute the heredoc body: read CP_* env config, then scan().

    sys.exit(N) propagates out of main() naturally -- this matches the bash
    `set +e` / `PYRC=$?` / `exit $PYRC` re-raise of the heredoc's exit code.
    """
    global ROOT, FORMAT, PUBLIC_PATHS
    ROOT = os.path.abspath(os.environ['CP_ROOT'])
    FORMAT = os.environ.get('CP_FORMAT', 'text')
    PUBLIC_PATHS = os.environ['CP_PUBLIC_PATHS'].split(':')

    scan()


def main(argv=None):
    # Replicates the bin/check-privacy.sh bash arg loop EXACTLY (same error
    # strings to the same streams, same exit codes).
    if argv is None:
        argv = sys.argv[1:]
    args = list(argv)

    root = os.getcwd()
    fmt = "text"

    i = 0
    while i < len(args):
        a = args[i]
        if a in ("--help", "-h"):
            sys.stdout.write(USAGE)
            return 0
        elif a == "--root":
            if len(args) - i < 2:
                print("ERROR: --root requires a value", file=sys.stderr)
                return 1
            root = args[i + 1]
            i += 2
        elif a == "--format":
            if len(args) - i < 2:
                print("ERROR: --format requires a value (text or json)", file=sys.stderr)
                return 1
            if args[i + 1] in ("text", "json"):
                fmt = args[i + 1]
            else:
                print("ERROR: --format must be 'text' or 'json'", file=sys.stderr)
                return 1
            i += 2
        elif a.startswith("-"):
            print(f"ERROR: unknown option: {a}", file=sys.stderr)
            sys.stderr.write(USAGE)
            return 1
        else:
            print(f"ERROR: unexpected argument: {a}", file=sys.stderr)
            return 1

    # Export env for the heredoc body (no jq dependency)
    os.environ["CP_ROOT"] = root
    os.environ["CP_FORMAT"] = fmt
    os.environ["CP_PUBLIC_PATHS"] = ":".join(PUBLIC_PATHS_DEFAULT)

    run()
    return 0


if __name__ == "__main__":          # enables `python3 -m compendium.check_privacy`
    sys.exit(main(sys.argv[1:]))
