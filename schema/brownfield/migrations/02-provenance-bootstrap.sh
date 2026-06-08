#!/usr/bin/env bash
# 02-provenance-bootstrap.sh — Apply-class migration script (Phase 11 Plan 11-03)
# Class:  apply
# Scope:  Appends [epistemic:: inferred] to eligible TOP-LEVEL bullets under
#         ## TL;DR and ## Key Facts sections (item 5 — nested bullets never
#         tagged); frontmatter untouched.
# BRWN-15 hard-lock: ONLY [epistemic:: inferred]. NO magic strings.
# Contract phrase (verbatim from CONTEXT.md D-05 / specifics):
#   "Marks top-level bullets under `## TL;DR` and `## Key Facts` with
#    [epistemic:: inferred] when the bullet looks claim-like, is not already
#    tagged, and is not a link-only, source-list, question, task, or
#    placeholder bullet. Never touches Detail. Reports honestly when no
#    eligible bullets are found."
# Design principle: Review may be interactive and AI-guided; apply must always be deterministic.
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: 02-provenance-bootstrap.sh [--dry-run|--apply|--help]

Marks TOP-LEVEL bullets (column 0 `-` only; nested bullets rejected per
review item 5) under `## TL;DR` and `## Key Facts` with [epistemic:: inferred]
when the bullet looks claim-like, is not already tagged, and is not a
link-only, source-list, question, task, or placeholder bullet. Never touches
Detail. Reports honestly when no eligible bullets are found.

--dry-run  Default. Print plan; no mutations.
--apply    Execute; append block to applied.log (mode: apply; inputs: 1-line
           advisory — 02 is direct-apply, no candidate inputs).
--help     Print this help and exit 0.

Soft prereq: if the majority of bootstrapped pages have empty type:, a WARN
is printed to stderr, but the script proceeds anyway (readiness not history).
EOF
}

APPLY=0
while [ "$#" -gt 0 ]; do
    case "$1" in
        --apply)   APPLY=1; shift ;;
        --dry-run) APPLY=0; shift ;;
        --help|-h) usage; exit 0 ;;
        *) echo "ERROR: unknown argument: $1" >&2; usage >&2; exit 1 ;;
    esac
done

# --- Root resolution (review item 1 fix — VERBATIM from 01) ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BF_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BROWNFIELD_ROOT="${BROWNFIELD_ROOT:-$(cd "$BF_DIR/.." && pwd)}"
if [ -z "$BROWNFIELD_ROOT" ] || [ ! -d "$BROWNFIELD_ROOT" ]; then
    echo "ERROR: cannot resolve vault root from script location ($0). Set BROWNFIELD_ROOT explicitly." >&2
    exit 1
fi
if [ "$(basename "$(dirname "$SCRIPT_DIR")")" != ".brownfield" ]; then
    echo "ERROR: this script must be invoked from .brownfield/migrations/, not from schema/brownfield/migrations/." >&2
    echo "Run \`bin/brownfield.sh suggest --root <vault>\` first." >&2
    exit 1
fi

# Locate bin/lib (env > .brownfield-env breadcrumb > upward walk)
BROWNFIELD_LIB_DIR="${BROWNFIELD_LIB_DIR:-}"
if [ -z "$BROWNFIELD_LIB_DIR" ] && [ -f "$BF_DIR/.brownfield-env" ]; then
    # shellcheck disable=SC1090
    . "$BF_DIR/.brownfield-env"
fi
if [ -z "$BROWNFIELD_LIB_DIR" ]; then
    _cand="$BROWNFIELD_ROOT"
    while [ "$_cand" != "/" ]; do
        if [ -f "$_cand/bin/lib/brownfield_yaml.py" ]; then
            BROWNFIELD_LIB_DIR="$_cand/bin/lib"
            break
        fi
        _cand="$(dirname "$_cand")"
    done
fi
if [ -z "$BROWNFIELD_LIB_DIR" ] || [ ! -f "$BROWNFIELD_LIB_DIR/brownfield_yaml.py" ]; then
    echo "ERROR: cannot locate bin/lib/brownfield_yaml.py." >&2
    exit 1
fi
if [ ! -f "$BROWNFIELD_LIB_DIR/brownfield_provenance.py" ]; then
    echo "ERROR: bin/lib/brownfield_provenance.py missing (Plan 11-03 Task 1 output)." >&2
    exit 1
fi
if [ ! -f "$BROWNFIELD_LIB_DIR/brownfield_walk.py" ]; then
    echo "ERROR: bin/lib/brownfield_walk.py missing (Plan 11-02 Task 2a output)." >&2
    exit 1
fi

# Extract op_hash from this script's own header (prepended by suggest at copy time per D-10).
OP_HASH="$(awk '/^# op_hash: sha256:/ {sub(/^# op_hash: /, ""); print; exit}' "${BASH_SOURCE[0]}")"
if [ -z "$OP_HASH" ]; then
    echo "ERROR: op_hash header missing from this script — was it installed via suggest?" >&2
    exit 1
fi

APPLIED_LOG="$BF_DIR/applied.log"

append_applied_log_block() {
    local block_file="$1"
    mkdir -p "$(dirname "$APPLIED_LOG")"
    cat "$block_file" >> "$APPLIED_LOG"
    printf '\n' >> "$APPLIED_LOG"
}

export BROWNFIELD_ROOT BROWNFIELD_LIB_DIR APPLY OP_HASH

python3 <<'PYEOF'
import os, sys, datetime
sys.path.insert(0, os.environ['BROWNFIELD_LIB_DIR'])
from brownfield_yaml import read_fm_body, write_roundtrip
from brownfield_provenance import is_eligible_claim_bullet, section_scan   # item 5 enforced in helper
from brownfield_walk import walk_vault_respecting_ignore   # item 3 reuse

ROOT = os.environ['BROWNFIELD_ROOT']
APPLY = os.environ['APPLY'] == '1'

# ===== Soft state-based prereq WARN (D-12) =====
bootstrapped_pages = []
untyped = 0
for p in walk_vault_respecting_ignore(ROOT):
    try:
        fm, body, raw = read_fm_body(p)
    except Exception:
        continue
    if not fm or fm.get('bootstrap_stage') != 'bootstrapped':
        continue
    bootstrapped_pages.append((p, fm, body, raw))
    if not fm.get('type'):
        untyped += 1

total = len(bootstrapped_pages)
prereq_check = 'pass'
if total > 0 and untyped > total / 2:
    # Verbatim D-12 phrasing
    sys.stderr.write(
        f"WARN: {untyped} bootstrapped pages still have empty type:. "
        f"02-provenance-bootstrap works best after page typing review or on pages "
        f"with existing valid type. Proceeding anyway.\n"
    )
    prereq_check = 'warn'

# ===== Eligibility scan (top-level-only per item 5) + apply =====
pages_eligible = []
pages_no_eligible = []
for p, fm, body, raw in bootstrapped_pages:
    eligible = section_scan(body or '', ['TL;DR', 'Key Facts'])
    if eligible:
        pages_eligible.append((p, fm, body, raw, eligible))
    else:
        pages_no_eligible.append(p)

files_touched = 0
files_updated = 0
changes = []
for p, fm, body, raw, eligible in pages_eligible:
    lines = body.splitlines(keepends=True)
    mutated = False
    mutated_count = 0
    for lineno, _ in eligible:
        idx = lineno - 1
        if idx < 0 or idx >= len(lines):
            continue
        current = lines[idx]
        if '[epistemic::' in current:
            continue   # already tagged (defensive; section_scan should have excluded)
        if current.endswith('\r\n'):
            new = current[:-2] + ' [epistemic:: inferred]\r\n'
        elif current.endswith('\n'):
            new = current[:-1] + ' [epistemic:: inferred]\n'
        else:
            new = current + ' [epistemic:: inferred]'
        if new != current:
            lines[idx] = new
            mutated = True
            mutated_count += 1
    if mutated and APPLY:
        new_body = ''.join(lines)
        write_roundtrip(p, fm, new_body, raw)
        files_updated += 1
    if mutated:
        files_touched += 1
        changes.append((os.path.relpath(p, ROOT), mutated_count))

mode = 'apply' if APPLY else 'dry-run'
sys.stderr.write(
    f"02-provenance-bootstrap.sh ({mode}): {files_touched} pages with eligible bullets; "
    f"{len(pages_no_eligible)} pages had no eligible bullets\n"
)

if not APPLY:
    sys.exit(0)

# Emit applied.log apply-block — Item 10 contract: 1-line `inputs:` literal advisory
ts = os.environ.get('BROWNFIELD_FIXTURE_TODAY')
if ts:
    ts = f"{ts}T00:00:00Z"
else:
    ts = datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
block_path = os.path.join(ROOT, '.brownfield', '_apply_block.tmp')
with open(block_path, 'w') as fh:
    fh.write(f"## 02-provenance-bootstrap.sh @ {ts}\n")
    fh.write("mode: apply\n")
    fh.write(f"op_hash: {os.environ['OP_HASH']}\n")
    fh.write("exit_code: 0\n")
    fh.write(f"prereq_check: {prereq_check}\n")
    fh.write("inputs:\n")
    fh.write("- (vault walk — no candidate inputs; 02 is direct-apply)\n")   # item 10
    fh.write(f"files_touched: {files_touched}\n")
    fh.write("files_created: 0\n")
    fh.write(f"files_updated: {files_updated}\n")
    fh.write(f"files_skipped: {len(pages_no_eligible)}\n")
    fh.write("changes:\n")
    for rel, n in changes:
        fh.write(f"- {rel} | updated | tagged {n} bullets with [epistemic:: inferred]\n")
    fh.write("summary:\n")
    fh.write(f"- pages_with_eligible_bullets: {files_touched}\n")
    fh.write(f"- pages_with_no_eligible_bullets: {len(pages_no_eligible)}\n")
PYEOF

if [ "$APPLY" = "1" ]; then
    append_applied_log_block "$BF_DIR/_apply_block.tmp"
    rm -f "$BF_DIR/_apply_block.tmp"
fi

exit 0
