#!/usr/bin/env bash
# bin/init-wizard.sh — preflight-preserving exec-shim (Phase 25 MIG-04).
# Deliberately NOT the canonical 7-line shim: per the LOCKED contract
# (docs/reference/python-shim-contract.md §4) the exit-3 pre-flight is a
# dependency-PRESENCE check and stays IN THE SHIM — a Python port cannot detect
# "python3 missing" from inside python3. Enforced by
# tests/phase-24/test_shim_preflight_exit3.sh (manifest-driven loop).
# Known narrow divergence vs the retired bash body: bash parsed --help BEFORE
# pre-flight; the shim pre-flights first, so --help on a dependency-less machine
# exits 3 instead of printing usage (the usage text lives in the Python module).
set -euo pipefail

# --- Pre-flight (D-15; verbatim from the retired bash body) — exit 3 BEFORE Python.
preflight() {
    local errors=()

    if (( BASH_VERSINFO[0] < 4 )); then
        errors+=("bash: need >= 4.0, have ${BASH_VERSION}")
    fi

    if ! command -v git >/dev/null 2>&1; then
        errors+=("git: not found in PATH")
    fi

    if ! command -v python3 >/dev/null 2>&1; then
        errors+=("python3: not found in PATH")
    fi

    if (( ${#errors[@]} > 0 )); then
        printf 'ERROR: pre-flight failed:\n' >&2
        printf '  - %s\n' "${errors[@]}" >&2
        printf 'See: docs/reference/setup-prerequisites.md for install instructions.\n' >&2
        exit 3
    fi
}
preflight

# Self-bootstrapping PYTHONPATH (canonical form; contract §1).
_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PYTHONPATH="${_REPO_ROOT}/src${PYTHONPATH:+:$PYTHONPATH}"
exec python3 -m compendium.init_wizard "$@"
