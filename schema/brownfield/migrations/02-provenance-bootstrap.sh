#!/usr/bin/env bash
# 02-provenance-bootstrap.sh — Apply-class migration script
# Class:  apply (direct — no candidate inputs; walks the vault)
# Scope:  Marks eligible top-level bullets in ## TL;DR and ## Key Facts with
#         [epistemic:: inferred].  State-based soft prereq (D-12): WARN if
#         majority of bootstrapped pages still have empty `type:`.
# Design principle: Review may be interactive and AI-guided; apply must always be deterministic.
# Filled in by Phase 11 Plan 11-03.
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: 02-provenance-bootstrap.sh [--dry-run|--apply|--help]

Apply-class migration. Marks top-level bullets under `## TL;DR` and `## Key Facts`
with [epistemic:: inferred] when the bullet looks claim-like, is not already
tagged, and is not a link-only, source-list, question, task, or placeholder
bullet. Never touches Detail. Reports honestly when no eligible bullets are found.

Design principle: Review may be interactive and AI-guided; apply must always be deterministic.

--dry-run  Default. Print plan; no mutations.
--apply    Execute mutations.
--help     Print this help and exit 0.
EOF
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then usage; exit 0; fi
echo "ERROR: 02-provenance-bootstrap.sh not yet implemented — Plan 11-03 pending" >&2
exit 2
