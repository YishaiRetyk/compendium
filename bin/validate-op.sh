#!/usr/bin/env bash
# bin/validate-op.sh — Deterministic enforcement layer for structured operations (AGENTS.md section 9).
#
# Performs 5 mechanical checks with per-operation rules. No LLM calls, no content evaluation.
# Two-layer enforcement per D-16: AGENTS.md rules as policy, this script as deterministic enforcement.
#
# Requires: python3 with PyYAML (pyyaml) for YAML parsing.
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: bin/validate-op.sh <OPERATION> <target-path> [second-path]

Validates a structured wiki operation before it is applied.

Operations:
  UPDATE    <path>          Validate updating an existing page
  MERGE     <path-a> <path-b>  Validate merging two pages
  SUPERSEDE <path>          Validate superseding a page
  ARCHIVE   <path>          Validate archiving a page

Checks performed (5 mechanical checks per AGENTS.md section 9):
  [1/5] Target page(s) exist
  [2/5] YAML frontmatter parses and satisfies schema (enum values, required fields)
  [3/5] Provenance references resolve to known source IDs in wiki/sources/
  [4/5] Privacy flags respected (inheritance: strictest source tier wins)
  [5/5] MERGE-specific: both pages exist and are distinct

Per-operation rules:
  - ARCHIVE rejects already-archived pages
  - SUPERSEDE rejects already-superseded pages

Exit codes:
  0  All checks PASS
  1  One or more checks FAIL, or usage error

Options:
  --help, -h    Show this help message
EOF
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

validate_frontmatter() {
    local file="$1"
    local op="$2"
    python3 -c "
import sys, yaml

content = open(sys.argv[1]).read()
op = sys.argv[2]

if not content.startswith('---'):
    print('FAIL: No YAML frontmatter found', file=sys.stderr)
    sys.exit(1)

try:
    end = content.index('---', 3)
    fm = yaml.safe_load(content[3:end])
    if fm is None:
        print('FAIL: Empty frontmatter', file=sys.stderr)
        sys.exit(1)

    # Check required base fields (always required)
    required = ['id','title','type','status','summary','created_at','updated_at',
                'sources','epistemic_status','tags','domains','privacy']
    missing = [f for f in required if f not in fm]
    if missing:
        print(f'FAIL: Missing required fields: {missing}', file=sys.stderr)
        sys.exit(1)

    # Validate enum values
    valid_types = {'entity','concept','source','comparison','overview'}
    if fm['type'] not in valid_types:
        print(f\"FAIL: Invalid type '{fm['type']}', must be one of: {sorted(valid_types)}\", file=sys.stderr)
        sys.exit(1)

    valid_status = {'active','stale','superseded','archived'}
    if fm['status'] not in valid_status:
        print(f\"FAIL: Invalid status '{fm['status']}', must be one of: {sorted(valid_status)}\", file=sys.stderr)
        sys.exit(1)

    valid_epistemic = {'sourced','mixed','tentative','stale'}
    if fm['epistemic_status'] not in valid_epistemic:
        print(f\"FAIL: Invalid epistemic_status '{fm['epistemic_status']}', must be one of: {sorted(valid_epistemic)}\", file=sys.stderr)
        sys.exit(1)

    valid_privacy = {'local_only','cloud_safe'}
    if fm['privacy'] not in valid_privacy:
        print(f\"FAIL: Invalid privacy '{fm['privacy']}', must be one of: {sorted(valid_privacy)}\", file=sys.stderr)
        sys.exit(1)

    # Per-operation checks
    if op == 'ARCHIVE' and fm['status'] == 'archived':
        print('FAIL: Page is already archived', file=sys.stderr)
        sys.exit(1)

    if op == 'SUPERSEDE' and fm.get('superseded_by'):
        print(f\"FAIL: Page already superseded by '{fm['superseded_by']}'\", file=sys.stderr)
        sys.exit(1)

    # Source-type specific: check compilation fields if present
    if fm['type'] == 'source':
        comp_status = fm.get('compilation_status')
        if comp_status and comp_status not in ('pending','partial','compiled','stale'):
            print(f\"FAIL: Invalid compilation_status '{comp_status}'\", file=sys.stderr)
            sys.exit(1)

    print('PASS')

except yaml.YAMLError as e:
    print(f'FAIL: YAML parse error: {e}', file=sys.stderr)
    sys.exit(1)
except ValueError:
    print('FAIL: Unterminated frontmatter (missing closing ---)', file=sys.stderr)
    sys.exit(1)
" "$file" "$op"
}

check_provenance() {
    local file="$1"
    local failed=0
    # Extract all [prov:source_id#...] markers (handles both simple and extended syntax)
    local src_ids
    src_ids=$(grep -oP '\[prov:([^#\]]+)' "$file" 2>/dev/null | sed 's/\[prov://' | sort -u) || true
    if [ -z "$src_ids" ]; then
        echo "PASS (no provenance markers found)"
        return 0
    fi
    while IFS= read -r src_id; do
        if [ ! -f "wiki/sources/${src_id}.md" ]; then
            echo "FAIL: Provenance reference '${src_id}' does not resolve to wiki/sources/${src_id}.md" >&2
            failed=1
        fi
    done <<< "$src_ids"
    if [ "$failed" -eq 0 ]; then
        echo "PASS"
    fi
    return $failed
}

check_privacy() {
    local file="$1"
    local op="$2"
    python3 -c "
import sys, yaml, os

content = open(sys.argv[1]).read()
op = sys.argv[2]

if not content.startswith('---'):
    print('FAIL: No privacy field — no frontmatter found', file=sys.stderr)
    sys.exit(1)

try:
    end = content.index('---', 3)
except ValueError:
    print('FAIL: Unterminated frontmatter', file=sys.stderr)
    sys.exit(1)

fm = yaml.safe_load(content[3:end])
if fm is None:
    print('FAIL: Empty frontmatter', file=sys.stderr)
    sys.exit(1)

page_privacy = fm.get('privacy', 'MISSING')
if page_privacy == 'MISSING':
    print('FAIL: No privacy field in frontmatter', file=sys.stderr)
    sys.exit(1)
if page_privacy not in ('local_only', 'cloud_safe'):
    print(f\"FAIL: Invalid privacy value: {page_privacy}\", file=sys.stderr)
    sys.exit(1)

# Check source privacy inheritance (Section 13 rule)
sources = fm.get('sources', []) or []
local_sources = []
for src_id in sources:
    src_path = f'wiki/sources/{src_id}.md'
    if os.path.exists(src_path):
        src_content = open(src_path).read()
        if src_content.startswith('---'):
            try:
                src_end = src_content.index('---', 3)
                src_fm = yaml.safe_load(src_content[3:src_end])
                if src_fm and src_fm.get('privacy') == 'local_only':
                    local_sources.append(src_id)
            except (ValueError, yaml.YAMLError):
                pass  # Source page has broken frontmatter — not this check's concern

if local_sources and page_privacy == 'cloud_safe':
    print(f\"FAIL: Privacy violation -- page is cloud_safe but source(s) {local_sources} are local_only. Page must be local_only per Section 13 inheritance rule.\", file=sys.stderr)
    sys.exit(1)

print(f'PASS (privacy: {page_privacy})')
" "$file" "$op"
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

if [ "$#" -eq 0 ]; then
    usage
    exit 1
fi

case "$1" in
    --help|-h)
        usage
        exit 0
        ;;
esac

OP="${1:-}"
shift || true

# Validate operation type
case "$OP" in
    UPDATE|MERGE|SUPERSEDE|ARCHIVE) ;;
    *)
        echo "ERROR: Invalid operation type: '${OP}'" >&2
        echo "Must be one of: UPDATE, MERGE, SUPERSEDE, ARCHIVE" >&2
        exit 1
        ;;
esac

# Validate argument count
if [ "$OP" = "MERGE" ]; then
    if [ "$#" -lt 2 ]; then
        echo "ERROR: MERGE requires two target paths" >&2
        echo "Usage: bin/validate-op.sh MERGE <path-a> <path-b>" >&2
        exit 1
    fi
    PATH_A="$1"
    PATH_B="$2"
else
    if [ "$#" -lt 1 ]; then
        echo "ERROR: ${OP} requires a target path" >&2
        echo "Usage: bin/validate-op.sh ${OP} <target-path>" >&2
        exit 1
    fi
    TARGET="$1"
fi

# ---------------------------------------------------------------------------
# Run 5 mechanical checks
# ---------------------------------------------------------------------------

FAILED=0
RESULTS=()

print_check() {
    local num="$1"
    local label="$2"
    local result="$3"
    printf "  [%s/5] %-25s %s\n" "$num" "$label" "$result"
}

if [ "$OP" = "MERGE" ]; then
    echo "=== Validating ${OP} on ${PATH_A} + ${PATH_B} ==="
else
    echo "=== Validating ${OP} on ${TARGET} ==="
fi
echo ""

# --- Check 1: Target page(s) exist ---
if [ "$OP" = "MERGE" ]; then
    if [ ! -f "$PATH_A" ]; then
        print_check 1 "Target exists" "FAIL"
        echo "  FAIL: Target page does not exist: ${PATH_A}" >&2
        FAILED=1
    elif [ ! -f "$PATH_B" ]; then
        print_check 1 "Target exists" "FAIL"
        echo "  FAIL: Target page does not exist: ${PATH_B}" >&2
        FAILED=1
    else
        print_check 1 "Target exists" "PASS"
    fi
else
    if [ -f "$TARGET" ]; then
        print_check 1 "Target exists" "PASS"
    else
        print_check 1 "Target exists" "FAIL"
        echo "  FAIL: Target page does not exist: ${TARGET}" >&2
        FAILED=1
    fi
fi

# --- Check 2: Frontmatter valid (YAML parse + schema) ---
if [ "$FAILED" -eq 0 ]; then
    if [ "$OP" = "MERGE" ]; then
        fm_result_a=$(validate_frontmatter "$PATH_A" "$OP" 2>&1) || true
        fm_result_b=$(validate_frontmatter "$PATH_B" "$OP" 2>&1) || true
        if echo "$fm_result_a" | grep -q "^PASS" && echo "$fm_result_b" | grep -q "^PASS"; then
            print_check 2 "Frontmatter valid" "PASS"
        else
            print_check 2 "Frontmatter valid" "FAIL"
            echo "$fm_result_a" | grep -i "^FAIL" >&2 || true
            echo "$fm_result_b" | grep -i "^FAIL" >&2 || true
            FAILED=1
        fi
    else
        fm_result=$(validate_frontmatter "$TARGET" "$OP" 2>&1) || true
        if echo "$fm_result" | grep -q "^PASS"; then
            print_check 2 "Frontmatter valid" "PASS"
        else
            print_check 2 "Frontmatter valid" "FAIL"
            echo "$fm_result" | grep -i "^FAIL" >&2 || true
            FAILED=1
        fi
    fi
else
    print_check 2 "Frontmatter valid" "SKIP (target missing)"
fi

# --- Check 3: Provenance resolves ---
if [ "$FAILED" -eq 0 ]; then
    if [ "$OP" = "MERGE" ]; then
        prov_a=$(check_provenance "$PATH_A" 2>&1) || true
        prov_b=$(check_provenance "$PATH_B" 2>&1) || true
        if echo "$prov_a" | grep -q "^PASS" && echo "$prov_b" | grep -q "^PASS"; then
            print_check 3 "Provenance resolves" "PASS"
        else
            print_check 3 "Provenance resolves" "FAIL"
            echo "$prov_a" | grep -i "^FAIL" >&2 || true
            echo "$prov_b" | grep -i "^FAIL" >&2 || true
            FAILED=1
        fi
    else
        prov_result=$(check_provenance "$TARGET" 2>&1) || true
        if echo "$prov_result" | grep -q "^PASS"; then
            print_check 3 "Provenance resolves" "$prov_result"
        else
            print_check 3 "Provenance resolves" "FAIL"
            echo "$prov_result" | grep -i "^FAIL" >&2 || true
            FAILED=1
        fi
    fi
else
    print_check 3 "Provenance resolves" "SKIP (prior check failed)"
fi

# --- Check 4: Privacy respected ---
if [ "$FAILED" -eq 0 ]; then
    if [ "$OP" = "MERGE" ]; then
        priv_a=$(check_privacy "$PATH_A" "$OP" 2>&1) || true
        priv_b=$(check_privacy "$PATH_B" "$OP" 2>&1) || true
        if echo "$priv_a" | grep -q "^PASS" && echo "$priv_b" | grep -q "^PASS"; then
            # For MERGE, warn if either page is local_only
            if echo "$priv_a" | grep -q "local_only" || echo "$priv_b" | grep -q "local_only"; then
                print_check 4 "Privacy respected" "PASS (WARN: MERGE includes local_only page -- merged result MUST be local_only)"
            else
                print_check 4 "Privacy respected" "PASS"
            fi
        else
            print_check 4 "Privacy respected" "FAIL"
            echo "$priv_a" | grep -i "^FAIL" >&2 || true
            echo "$priv_b" | grep -i "^FAIL" >&2 || true
            FAILED=1
        fi
    else
        priv_result=$(check_privacy "$TARGET" "$OP" 2>&1) || true
        if echo "$priv_result" | grep -q "^PASS"; then
            print_check 4 "Privacy respected" "$priv_result"
        else
            print_check 4 "Privacy respected" "FAIL"
            echo "$priv_result" | grep -i "^FAIL" >&2 || true
            FAILED=1
        fi
    fi
else
    print_check 4 "Privacy respected" "SKIP (prior check failed)"
fi

# --- Check 5: MERGE distinct pages ---
if [ "$OP" = "MERGE" ]; then
    if [ "$FAILED" -eq 0 ]; then
        real_a=$(realpath "$PATH_A" 2>/dev/null || echo "$PATH_A")
        real_b=$(realpath "$PATH_B" 2>/dev/null || echo "$PATH_B")
        if [ "$real_a" = "$real_b" ]; then
            print_check 5 "MERGE distinct pages" "FAIL"
            echo "  FAIL: MERGE requires two distinct pages, got the same page twice" >&2
            FAILED=1
        else
            print_check 5 "MERGE distinct pages" "PASS"
        fi
    else
        print_check 5 "MERGE distinct pages" "SKIP (prior check failed)"
    fi
else
    print_check 5 "MERGE distinct pages" "SKIP (not MERGE)"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

echo ""
if [ "$FAILED" -eq 0 ]; then
    echo "=== RESULT: PASS ==="
    exit 0
else
    echo "=== RESULT: FAIL ==="
    exit 1
fi
