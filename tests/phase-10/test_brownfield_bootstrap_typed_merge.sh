#!/usr/bin/env bash
# Plan 10-03 Task 2: D-02 typed-merge Class A (tags) + Class B (type, privacy) preserved.
# Custom one-off vault — doesn't use the canonical fixture set.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
export BROWNFIELD_FIXTURE_TODAY="2026-04-17"

vault=$(mktemp -d -t phase10-typed-merge-XXXXXX)
trap '[ -n "${vault:-}" ] && [ -d "$vault" ] && rm -rf "$vault"' EXIT

cat > "$vault/page.md" <<'EOF'
---
type: concept
tags:
  - manual
privacy: cloud_safe
---

Body.
EOF

bash "$REPO_ROOT/bin/brownfield.sh" bootstrap --apply --root "$vault" >/dev/null 2>&1

# Class B: existing values preserved (never overwritten).
grep -qF "type: concept"        "$vault/page.md" \
    || { echo "FAIL: Class B 'type' was overwritten" >&2; cat "$vault/page.md" >&2; exit 1; }
grep -qF "privacy: cloud_safe"  "$vault/page.md" \
    || { echo "FAIL: Class B 'privacy' was overwritten" >&2; cat "$vault/page.md" >&2; exit 1; }

# Class A: existing non-empty tags preserved (not overwritten by sentinel `[]`).
# Use `--` to protect grep from treating the leading '-' as a flag.
grep -qF -- "- manual"          "$vault/page.md" \
    || { echo "FAIL: Class A 'tags' existing value lost" >&2; cat "$vault/page.md" >&2; exit 1; }

# Brownfield sentinels injected.
grep -qF "bootstrap_stage: bootstrapped" "$vault/page.md" \
    || { echo "FAIL: bootstrap_stage not injected" >&2; cat "$vault/page.md" >&2; exit 1; }
grep -qF "bootstrap_date: 2026-04-17"    "$vault/page.md" \
    || { echo "FAIL: bootstrap_date not injected" >&2; cat "$vault/page.md" >&2; exit 1; }

report="$vault/.brownfield/REPORT.md"
assert_file_exists "$report" "REPORT.md missing"

# REPORT.md must record a collision for the Class-A 'tags' field.
grep -qF "## Preserved collision" "$report" \
    || { echo "FAIL: REPORT.md missing '## Preserved collision' block" >&2; cat "$report" >&2; exit 1; }
# The collision block must reference `tags`.
awk '/## Preserved collision/{flag=1} flag && /^- field: tags/{found=1; exit} END{exit !found}' "$report" \
    || { echo "FAIL: REPORT.md 'Preserved collision' block does not reference tags" >&2; cat "$report" >&2; exit 1; }

# REPORT.md must NOT contain a schema-warning for 'type' (value 'concept' is canonical).
if awk '/## Preserved schema-authoritative field/{flag=1} flag && /^- field: type/{found=1; exit} END{exit !found}' "$report"; then
    echo "FAIL: REPORT.md contains an unwarranted schema warning for 'type' (value was canonical)" >&2
    cat "$report" >&2
    exit 1
fi

echo "PASS: typed-merge Class A/B preservation + REPORT.md shape"
