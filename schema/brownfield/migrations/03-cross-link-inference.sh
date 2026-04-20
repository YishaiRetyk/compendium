#!/usr/bin/env bash
# 03-cross-link-inference.sh — Advisory-only migration script
# Class:  advisory-only (no --apply; writes .brownfield/cross-link-candidates.yaml + REPORT.md section)
# Scope:  Scans vault for exact-title + alias mentions; emits candidate wikilinks
#         for human/AI review.  Never mutates vault pages.
# Design principle: Review may be interactive and AI-guided; apply must always be deterministic.
# Filled in by Phase 11 Plan 11-03.
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: 03-cross-link-inference.sh [--help]

Advisory-only: scans vault for exact-title + alias mentions; writes
.brownfield/cross-link-candidates.yaml + ## Cross-link candidates section in
REPORT.md. No --apply path.

Design principle: Review may be interactive and AI-guided; apply must always be deterministic.

--help     Print this help and exit 0.
EOF
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then usage; exit 0; fi
echo "ERROR: 03-cross-link-inference.sh not yet implemented — Plan 11-03 pending" >&2
exit 2
