#!/usr/bin/env bash
# bin/requirements-sync.sh — exec-shim (Phase 25 MIG-05; contract: docs/reference/python-shim-contract.md §1)
# Self-bootstrapping: resolve REPO_ROOT, prepend src/ to PYTHONPATH so `import compendium`
# works on a bare checkout (no `pip install -e .` required).
_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PYTHONPATH="${_REPO_ROOT}/src${PYTHONPATH:+:$PYTHONPATH}"
exec python3 -m compendium.requirements_sync "$@"
