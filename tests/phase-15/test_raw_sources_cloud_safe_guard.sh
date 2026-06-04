#!/usr/bin/env bash
# PRIV-03 (cycle-2 HIGH — raw sources/ outside the privacy boundary):
# FAIL-CLOSED raw-source cloud-safe guard. Asserts:
# (i) a tree where all raw sources/ are cloud-safe -> guard exits 0
# (ii) a tree where a raw source carries 'privacy: local_only' -> guard exits NON-zero
# (iii) a tree where a sources/local-only/ directory exists -> guard exits NON-zero
# (iv) static: docs/reference/privacy-model.md documents the sources-local/ forward-reference
# Today this FAILS (no such guard exists; the deny-profile covers only wiki-local/).
# NOTE for Wave-1/2 executor: the guard's exact home is executor discretion -- standalone
# bin/check-sources-cloud-safe.sh, folded into check-privacy.sh, or a lint drift check.
# This test pins the BEHAVIOR (fail-closed on non-cloud-safe raw source), not the implementation.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

FAIL=0

# Helper: find the guard command (checks known candidate locations)
find_guard() {
    local root="$1"
    # Candidate 1: standalone script
    if [ -f "$REPO_ROOT/bin/check-sources-cloud-safe.sh" ]; then
        echo "bash $REPO_ROOT/bin/check-sources-cloud-safe.sh --root $root"
        return
    fi
    # Candidate 2: folded into check-privacy.sh (accepts --sources-check flag)
    # Candidate 3: a lint.sh drift check (--category drift-sources)
    # If none found, return empty (test will fail with appropriate message)
    echo ""
}

GUARD_CMD="$(find_guard "$REPO_ROOT")"
if [ -z "$GUARD_CMD" ]; then
    echo "FAIL: no raw-source cloud-safe guard found (check bin/check-sources-cloud-safe.sh, " \
         "bin/check-privacy.sh --sources-check, or bin/lint.sh drift category) (PRIV-03 cycle-2 HIGH)" >&2
    FAIL=1
fi

if [ -n "$GUARD_CMD" ]; then
    # --- Test (i): all raw sources cloud-safe -> guard exits 0 ---
    repo_clean="$(make_bare_repo)"
    mkdir -p "$repo_clean/sources/2026/2026-06"
    cat > "$repo_clean/sources/2026/2026-06/cloud-source.md" <<'EOF'
---
title: "Cloud Source"
privacy: cloud_safe
---

# Cloud Source

This is a cloud-safe raw source.
EOF

    GUARD_CLEAN="${GUARD_CMD/$REPO_ROOT\//$repo_clean/}"
    # Reconstruct for the clean repo
    set +e
    out_i="$( bash $REPO_ROOT/bin/check-sources-cloud-safe.sh --root "$repo_clean" 2>&1 )"
    rc_i=$?
    set -e
    cleanup_fixture_repo "$repo_clean"

    if [ "$rc_i" -ne 0 ]; then
        echo "FAIL (i): clean sources/ (all cloud-safe) should exit 0, got exit=$rc_i" >&2
        echo "output: $out_i" >&2
        FAIL=1
    fi

    # --- Test (ii): raw source carries 'privacy: local_only' -> guard exits NON-zero ---
    repo_local="$(make_bare_repo)"
    mkdir -p "$repo_local/sources/2026/2026-06"
    cat > "$repo_local/sources/2026/2026-06/local-source.md" <<'EOF'
---
title: "Local Source"
privacy: local_only
---

# Local Source

This is a local-only raw source -- should fail the guard.
EOF

    set +e
    out_ii="$( bash $REPO_ROOT/bin/check-sources-cloud-safe.sh --root "$repo_local" 2>&1 )"
    rc_ii=$?
    set -e
    cleanup_fixture_repo "$repo_local"

    if [ "$rc_ii" -eq 0 ]; then
        echo "FAIL (ii): raw source with 'privacy: local_only' should fail guard (exit != 0), got exit=0" >&2
        echo "FAIL-CLOSED: guard must prevent silent cloud leak of local raw sources (PRIV-03 cycle-2 HIGH)" >&2
        FAIL=1
    fi

    # --- Test (iii): sources/local-only/ tier exists -> guard exits NON-zero ---
    repo_tier="$(make_bare_repo)"
    mkdir -p "$repo_tier/sources/local-only"
    cat > "$repo_tier/sources/local-only/private.md" <<'EOF'
---
title: "Private Source"
---

# Private Source

Raw source in sources/local-only/ tier.
EOF

    set +e
    out_iii="$( bash $REPO_ROOT/bin/check-sources-cloud-safe.sh --root "$repo_tier" 2>&1 )"
    rc_iii=$?
    set -e
    cleanup_fixture_repo "$repo_tier"

    if [ "$rc_iii" -eq 0 ]; then
        echo "FAIL (iii): sources/local-only/ tier existence should fail guard (exit != 0), got exit=0" >&2
        echo "FAIL-CLOSED: guard must force adopter onto sources-local/ structural tier (PRIV-03 cycle-2 HIGH)" >&2
        FAIL=1
    fi
fi

# --- Test (iv): static — docs/reference/privacy-model.md documents sources-local/ forward-reference ---
PRIVACY_MODEL="$REPO_ROOT/docs/reference/privacy-model.md"
if [ ! -f "$PRIVACY_MODEL" ]; then
    echo "FAIL (iv): docs/reference/privacy-model.md does not exist (sources-local/ forward-ref missing)" >&2
    FAIL=1
else
    if ! grep -qiE 'raw.*sources.*cloud|sources-local' "$PRIVACY_MODEL" 2>/dev/null; then
        echo "FAIL (iv): docs/reference/privacy-model.md does not document 'raw sources cloud-safe' rule or 'sources-local' tier (PRIV-03 cycle-2 HIGH)" >&2
        FAIL=1
    fi
fi

if [ "$FAIL" -eq 1 ]; then
    exit 1
fi

echo "PASS: FAIL-CLOSED raw-source cloud-safe guard + sources-local/ forward-ref documented (PRIV-03)"
