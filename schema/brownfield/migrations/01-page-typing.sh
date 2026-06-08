#!/usr/bin/env bash
# 01-page-typing.sh — Apply-class migration script (Phase 11 Plan 11-03)
# Class:  apply
# Scope:  Reads .brownfield/page-typing-decisions.yaml (AUTHORITATIVE policy)
#         AND .brownfield/page-typing-candidates.yaml (cluster-membership
#         lookup) as PAIRED IMMUTABLE INPUTS (review item 2 contract).
#         Mutates wiki page `type:` frontmatter via ruamel.yaml round-trip.
#         Does NOT re-classify at apply time.
# Design principle: Review may be interactive and AI-guided; apply must always be deterministic.
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: 01-page-typing.sh [--dry-run|--apply|--help]

Apply-class migration: reads .brownfield/page-typing-decisions.yaml
(AUTHORITATIVE — decision/resolved_label/overrides) AND
.brownfield/page-typing-candidates.yaml (cluster-member -> page-list lookup)
as PAIRED IMMUTABLE INPUTS. Mutates wiki page `type:` frontmatter
deterministically. Does NOT re-classify at apply time.

Design principle: Review may be interactive and AI-guided; apply must always be deterministic.

--dry-run  Default. Print plan; no mutations.
--apply    Execute mutations; append one block to .brownfield/applied.log.
--help     Print this help and exit 0.
EOF
}

# Flag parse
APPLY=0
while [ "$#" -gt 0 ]; do
    case "$1" in
        --apply)   APPLY=1; shift ;;
        --dry-run) APPLY=0; shift ;;
        --help|-h) usage; exit 0 ;;
        *) echo "ERROR: unknown argument: $1" >&2; usage >&2; exit 1 ;;
    esac
done

# --- Root resolution (review item 1 fix) ---
# Derive BROWNFIELD_ROOT from THIS SCRIPT'S location, not from $(pwd).
# Script lives at .brownfield/migrations/<script>.sh; vault root is .brownfield/'s parent.
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

# Locate bin/lib.  Resolution order:
#   1. Explicit env-var BROWNFIELD_LIB_DIR wins (tests + advanced users).
#   2. .brownfield/.brownfield-env breadcrumb written by suggest at copy time.
#   3. Fallback: walk upward from vault root looking for bin/lib/brownfield_yaml.py.
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
    echo "ERROR: cannot locate bin/lib/brownfield_yaml.py. Set BROWNFIELD_LIB_DIR or run from a repo-rooted vault." >&2
    exit 1
fi

DECISIONS_FILE="$BF_DIR/page-typing-decisions.yaml"
CANDIDATES_FILE="$BF_DIR/page-typing-candidates.yaml"
APPLIED_LOG="$BF_DIR/applied.log"

# Item 2: BOTH files required (paired immutable inputs)
if [ ! -f "$DECISIONS_FILE" ]; then
    echo "ERROR: $DECISIONS_FILE not found. Run \`bin/brownfield.sh suggest\` first." >&2
    exit 1
fi
if [ ! -f "$CANDIDATES_FILE" ]; then
    echo "ERROR: $CANDIDATES_FILE not found (required for cluster-membership lookup — paired immutable inputs per item 2). Run \`bin/brownfield.sh suggest\` first." >&2
    exit 1
fi

# Extract op_hash from this script's own header (injected by suggest at copy time per D-10)
OP_HASH="$(awk '/^# op_hash: sha256:/ {sub(/^# op_hash: /, ""); print; exit}' "${BASH_SOURCE[0]}")"
if [ -z "$OP_HASH" ]; then
    echo "ERROR: op_hash header missing from this script — was it installed via suggest?" >&2
    exit 1
fi

# applied.log append helper (RESEARCH Q8 — inline)
append_applied_log_block() {
    local block_file="$1"
    mkdir -p "$(dirname "$APPLIED_LOG")"
    cat "$block_file" >> "$APPLIED_LOG"
    printf '\n' >> "$APPLIED_LOG"
}

# Item 8: SHA-256 input hashes via Python hashlib (portable across macOS/Linux) — pre-flight one-shot
HASH_LINES=$(python3 - "$CANDIDATES_FILE" "$DECISIONS_FILE" <<'PYHASH'
import sys, hashlib, pathlib
for label, path in (('CAND_HASH', sys.argv[1]), ('DEC_HASH', sys.argv[2])):
    b = pathlib.Path(path).read_bytes()
    print(f"{label}=sha256:{hashlib.sha256(b).hexdigest()}")
PYHASH
)
eval "$HASH_LINES"   # sets CAND_HASH and DEC_HASH in current shell

export BROWNFIELD_ROOT BROWNFIELD_LIB_DIR DECISIONS_FILE CANDIDATES_FILE APPLY OP_HASH CAND_HASH DEC_HASH

python3 <<'PYEOF'
import os, sys, pathlib, datetime
sys.path.insert(0, os.environ['BROWNFIELD_LIB_DIR'])
from ruamel.yaml import YAML
from brownfield_yaml import read_fm_body, write_roundtrip, VALID_ENUMS

yaml = YAML(typ='rt')
ROOT = os.environ['BROWNFIELD_ROOT']
APPLY = os.environ['APPLY'] == '1'
decisions_path = os.environ['DECISIONS_FILE']
candidates_path = os.environ['CANDIDATES_FILE']

# Load both paired inputs (item 2) — candidates.yaml is READ for cluster-member
# lookup, NOT re-classified. Decisions.yaml is the AUTHORITATIVE policy source.
# WR-04: fall back to empty-dict when yaml.load returns None (empty/whitespace
# YAML is valid and parses to None; without the fallback, candidates.get(...)
# and decisions.get(...) below raise AttributeError on NoneType).
with open(decisions_path) as fh:
    decisions = yaml.load(fh) or {}
with open(candidates_path) as fh:
    candidates = yaml.load(fh) or {}
if not decisions.get('clusters') or not candidates.get('clusters'):
    sys.stderr.write(
        "ERROR: decisions or candidates YAML is empty — "
        "re-run `bin/brownfield.sh suggest` to regenerate.\n")
    sys.exit(1)

# Build cluster_id -> member-page list from candidates.yaml
cid_to_pages = {c['cluster_id']: list(c['pages']) for c in (candidates.get('clusters') or [])}

# Build path -> resolved_label from decisions (approved clusters + overrides)
path_to_label = {}
approved_clusters = 0
overridden_pages = 0
rejected_clusters = 0
pending_clusters = 0
for cluster_dec in (decisions.get('clusters') or []):
    cid = cluster_dec['cluster_id']
    decision = cluster_dec.get('decision', 'pending')
    resolved = cluster_dec.get('resolved_label')
    if decision == 'approve':
        approved_clusters += 1
        for p in cid_to_pages.get(cid, []):
            if resolved is not None:
                path_to_label[p] = resolved
    elif decision == 'reject':
        rejected_clusters += 1
    else:
        pending_clusters += 1
    # Apply overrides AFTER cluster-wide decisions (per-page wins)
    for ov in (cluster_dec.get('overrides') or []):
        path_to_label[ov['path']] = ov['label']
        overridden_pages += 1

valid_types_set = VALID_ENUMS.get('type', {'entity', 'concept', 'source', 'comparison', 'overview', 'decision'})
# Empty string is the D-14 sentinel — we MUST allow writing to pages with type: '' but
# we should not accept '' as a RESOLVED label (that would be a no-op).
valid_label_set = {t for t in valid_types_set if t != ''}

changes = []      # list of (path, before, after)
skipped = []      # list of (path, reason)
touched = 0
updated = 0
for path, label in sorted(path_to_label.items()):
    if not label:
        skipped.append((path, 'resolved_label is null/empty'))
        continue
    if label not in valid_label_set:
        skipped.append((path, f'label {label!r} not a valid type enum'))
        continue
    full = os.path.join(ROOT, path)
    if not os.path.isfile(full):
        skipped.append((path, 'file not found'))
        continue
    fm, body, raw = read_fm_body(full)
    if fm is None:
        skipped.append((path, 'unparseable frontmatter'))
        continue
    current = fm.get('type', '')
    if current == label:
        skipped.append((path, f'already type={label!r} (idempotent skip)'))
        continue
    if APPLY:
        fm['type'] = label
        write_roundtrip(full, fm, body, raw)
        updated += 1
    touched += 1
    changes.append((path, current if current else '""', label))

# Print plan (dry-run) OR confirmation (apply)
if not APPLY:
    sys.stderr.write(f"01-page-typing.sh (dry-run): would update {touched} pages ({len(skipped)} skipped)\n")
    for path, before, after in changes[:20]:
        sys.stderr.write(f"  - {path} | {before} -> {after}\n")
    if len(changes) > 20:
        sys.stderr.write(f"  ... and {len(changes) - 20} more\n")
    sys.stderr.write("Run with --apply to execute.\n")
    sys.exit(0)

sys.stderr.write(f"01-page-typing.sh --apply: updated {updated} pages; skipped {len(skipped)}\n")

# Emit applied-log block — Item 10 contract: 2-line `inputs:` (paired)
block_path = os.path.join(ROOT, '.brownfield', '_apply_block.tmp')
ts = os.environ.get('BROWNFIELD_FIXTURE_TODAY')
if ts:
    ts = f"{ts}T00:00:00Z"
else:
    ts = datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
with open(block_path, 'w') as fh:
    fh.write(f"## 01-page-typing.sh @ {ts}\n")
    fh.write("mode: apply\n")
    fh.write(f"op_hash: {os.environ['OP_HASH']}\n")
    fh.write("exit_code: 0\n")
    fh.write("prereq_check: pass\n")
    fh.write("inputs:\n")
    fh.write(f"- .brownfield/page-typing-candidates.yaml @ {os.environ['CAND_HASH']}\n")
    fh.write(f"- .brownfield/page-typing-decisions.yaml @ {os.environ['DEC_HASH']}\n")
    fh.write(f"files_touched: {touched}\n")
    fh.write("files_created: 0\n")
    fh.write(f"files_updated: {updated}\n")
    fh.write(f"files_skipped: {len(skipped)}\n")
    fh.write("changes:\n")
    for path, before, after in changes:
        fh.write(f"- {path} | updated | type: {before} -> {after}\n")
    fh.write("summary:\n")
    fh.write(f"- approved_clusters: {approved_clusters}\n")
    fh.write(f"- overridden_pages: {overridden_pages}\n")
    fh.write(f"- pending_pages_remaining: {pending_clusters}\n")
PYEOF

if [ "$APPLY" = "1" ]; then
    append_applied_log_block "$BF_DIR/_apply_block.tmp"
    rm -f "$BF_DIR/_apply_block.tmp"
fi

exit 0
