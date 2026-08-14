#!/usr/bin/env bash
# bin/search.sh — exec-shim (Phase 25 MIG-05; contract: docs/reference/python-shim-contract.md §1)
# Self-bootstrapping: resolve REPO_ROOT, prepend src/ to PYTHONPATH so `import compendium`
# works on a bare checkout (no `pip install -e .` required).
_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PYTHONPATH="${_REPO_ROOT}/src${PYTHONPATH:+:$PYTHONPATH}"
# search resolves wiki paths against cwd. Pick the wiki root in priority order:
# an explicit override, then a wiki in the caller's own cwd, then this checkout.
# The unconditional `cd "$_REPO_ROOT"` this replaces fixed C-8 callers (gtd-seam
# invokes from an arbitrary directory) but made every OTHER vault unsearchable —
# it silently redirected the search to this checkout's wiki and answered
# "No results found" with exit 0, which is a false negative, not an error.
if [ -n "${COMPENDIUM_WIKI_ROOT:-}" ]; then
    cd "$COMPENDIUM_WIKI_ROOT" || { echo "ERROR: COMPENDIUM_WIKI_ROOT not a directory: $COMPENDIUM_WIKI_ROOT" >&2; exit 1; }
elif [ ! -f "$PWD/wiki-cloud/index.md" ]; then
    cd "$_REPO_ROOT" || exit 1
fi
exec python3 -m compendium.search "$@"
