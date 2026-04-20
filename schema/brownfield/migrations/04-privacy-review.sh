#!/usr/bin/env bash
# 04-privacy-review.sh — Advisory-only migration script
# Class:  advisory-only (no --apply; writes .brownfield/privacy-findings.yaml + REPORT.md section)
# Scope:  Scans vault for PII-like regex matches (email, phone, SSN, etc.);
#         classifies findings for review priority.  Never flips privacy.
# Design principle: Review may be interactive and AI-guided; apply must always be deterministic.
# Filled in by Phase 11 Plan 11-03.
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: 04-privacy-review.sh [--help]

04-privacy-review classifies findings for review priority, not for frontmatter mutation. Fail-closed `privacy: local_only` is preserved; only a human (via frontmatter edit) may downgrade.

Design principle: Review may be interactive and AI-guided; apply must always be deterministic.

--help     Print this help and exit 0.
EOF
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then usage; exit 0; fi
echo "ERROR: 04-privacy-review.sh not yet implemented — Plan 11-03 pending" >&2
exit 2
