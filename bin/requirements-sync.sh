#!/usr/bin/env bash
# bin/requirements-sync.sh -- DEBT-03: mechanical traceability check.
# Compares REQUIREMENTS.md status checkboxes against per-phase VERIFICATION.md truths.
# Advisory default (exit 0); --strict exits 2 on drift.
#
# Zero LLM/API calls. Deterministic, file-based checks only.
# Requires: python3.
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: bin/requirements-sync.sh [OPTIONS]

DEBT-03: Compares REQUIREMENTS.md status vs phase VERIFICATION.md truths.
Emits a markdown table (default) or JSON array.

Options:
  --help, -h              Show this help message
  --format <text|json>    Output format (default: text)
  --strict                Exit 2 on any drift row (default: advisory, exit 0)
  --phase N               Restrict to REQ-IDs mapped to Phase N in REQUIREMENTS.md
  --root DIR              Override default root (.planning/); REQUIREMENTS.md is
                          read from <root>/REQUIREMENTS.md and VERIFICATION.md
                          files are discovered via find -maxdepth 3.

Exit codes:
  0   Success (advisory mode, or strict with no drift)
  1   Script failure (missing files, bad flags, python error)
  2   Strict mode found drift rows

Examples:
  bash bin/requirements-sync.sh
  bash bin/requirements-sync.sh --phase 7 --strict
  bash bin/requirements-sync.sh --format json | jq '.[] | select(.drift)'
  bash bin/requirements-sync.sh --root tests/phase-07/fixtures/requirements-sync
EOF
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

FORMAT="text"
STRICT=0
PHASE_FILTER=""
ROOT=".planning"

while [ "$#" -gt 0 ]; do
    case "$1" in
        --help|-h) usage; exit 0 ;;
        --format)
            if [ "$#" -lt 2 ]; then echo "ERROR: --format requires a value" >&2; exit 1; fi
            FORMAT="$2"; shift 2 ;;
        --strict) STRICT=1; shift ;;
        --phase)
            if [ "$#" -lt 2 ]; then echo "ERROR: --phase requires a value" >&2; exit 1; fi
            PHASE_FILTER="$2"; shift 2 ;;
        --root)
            if [ "$#" -lt 2 ]; then echo "ERROR: --root requires a value" >&2; exit 1; fi
            ROOT="$2"; shift 2 ;;
        -*) echo "ERROR: Unknown option: $1" >&2; usage >&2; exit 1 ;;
        *) echo "ERROR: Unexpected positional arg: $1" >&2; exit 1 ;;
    esac
done

if [ "$FORMAT" != "text" ] && [ "$FORMAT" != "json" ]; then
    echo "ERROR: --format must be 'text' or 'json'" >&2; exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo "ERROR: python3 is required but not found" >&2; exit 1
fi

REQ_FILE="$ROOT/REQUIREMENTS.md"
if [ ! -f "$REQ_FILE" ]; then
    echo "ERROR: REQUIREMENTS.md not found at $REQ_FILE" >&2; exit 1
fi

# Discover VERIFICATION.md files (maxdepth 3 handles both fixture flat layout
# and real .planning/phases/XX/XX-VERIFICATION.md layout).
VERIF_LIST=$(find "$ROOT" -maxdepth 3 -name '*VERIFICATION.md' -type f 2>/dev/null | LC_ALL=C sort || true)

# ---------------------------------------------------------------------------
# Core work in python3 heredoc
# ---------------------------------------------------------------------------

SENTINEL=$(mktemp)
trap 'rm -f "$SENTINEL"' EXIT

REQ_FILE="$REQ_FILE" \
VERIF_LIST="$VERIF_LIST" \
FORMAT="$FORMAT" \
STRICT="$STRICT" \
PHASE_FILTER="$PHASE_FILTER" \
SENTINEL="$SENTINEL" \
python3 - <<'PY'
import json, os, re, sys

req_file = os.environ["REQ_FILE"]
verif_list = [p for p in os.environ["VERIF_LIST"].split("\n") if p.strip()]
fmt = os.environ["FORMAT"]
strict = os.environ["STRICT"] == "1"
phase_filter = os.environ.get("PHASE_FILTER", "")
sentinel = os.environ["SENTINEL"]

# --- Parse REQUIREMENTS.md traceability table ---
# Rows: | REQ-ID | Phase N | Status |
req_row_re = re.compile(
    r'^\|\s*([A-Z]+-\d+)\s*\|\s*Phase\s*(\d+)\s*\|\s*(\w[\w ]*?)\s*\|'
)
requirements = []  # list of (req_id, phase_int, status)
with open(req_file, encoding="utf-8") as f:
    for line in f:
        m = req_row_re.match(line)
        if m:
            requirements.append((m.group(1), int(m.group(2)), m.group(3)))

# --- Parse VERIFICATION.md files (lexicographic order, last-write-wins) ---
# Strip checkbox / emoji / bold prefixes before REQ-ID, then capture status after colon.
LEADING_JUNK = re.compile(
    r'^\s*-\s*(?:\[[ xX]\]\s*)?(?:[^\w\s]+\s*)?(?:\*\*)?'
)
REQ_STATUS = re.compile(
    r'([A-Z]+-\d+)(?:\*\*)?\s*:\s*(.+?)\s*$'
)

def normalize(status):
    s = status.strip().lower()
    if s in ("complete", "done", "pass", "passing"):
        return "Complete"
    if s in ("pending", "todo", "in progress", "blocked"):
        return "Pending"
    return status.strip() or "Unknown"

verif_map = {}   # req_id -> (normalized_status, raw_status, file_path)
seen_before = {}  # req_id -> earlier file path
warnings = []

for vf in verif_list:
    try:
        with open(vf, encoding="utf-8") as f:
            content = f.read()
    except OSError:
        continue
    for line in content.splitlines():
        stripped = LEADING_JUNK.sub("", line)
        m = REQ_STATUS.match(stripped)
        if not m:
            continue
        rid = m.group(1)
        raw = m.group(2)
        norm = normalize(raw)
        if rid in verif_map:
            earlier = verif_map[rid][2]
            warnings.append(
                f"WARN: duplicate REQ-ID {rid} seen in {earlier}; using {vf} per last-write-wins"
            )
        verif_map[rid] = (norm, raw, vf)

for w in warnings:
    print(w, file=sys.stderr)

# --- Build findings ---
findings = []
drift_count = 0

for rid, phase, req_status in requirements:
    if phase_filter and str(phase) != str(phase_filter):
        continue
    req_norm = normalize(req_status)
    if rid in verif_map:
        v_norm, v_raw, _ = verif_map[rid]
        if v_norm == "Unknown":
            drift = False
            note = f"Unknown status token in VERIFICATION: {v_raw!r}"
        else:
            drift = (req_norm != v_norm)
            note = "DRIFT" if drift else "OK"
        verif_cell = v_norm
    else:
        v_norm = "(not found)"
        drift = False
        note = "OK - Phase not yet run"
        verif_cell = v_norm

    if drift:
        drift_count += 1

    findings.append({
        "req_id": rid,
        "requirements_md": req_norm,
        "verification_md": verif_cell,
        "drift": drift,
        "note": note,
        "phase": phase,
    })

# --- Emit output ---
if fmt == "json":
    print(json.dumps(findings, indent=2))
else:
    print("Advisory mode — active-phase drift expected. Pass --strict at milestone close.")
    print("")
    print("| REQ-ID    | REQUIREMENTS.md | VERIFICATION.md | Drift | Note |")
    print("|-----------|-----------------|-----------------|-------|------|")
    for row in findings:
        drift_cell = "DRIFT" if row["drift"] else "ok"
        print(f"| {row['req_id']:<9} | {row['requirements_md']:<15} | {row['verification_md']:<15} | {drift_cell:<5} | {row['note']} |")
    print("")
    print(f"# {drift_count} drift row(s) of {len(findings)} total.")

print(f"Drift rows: {drift_count} / {len(findings)}", file=sys.stderr)

# Write drift count to sentinel file for bash to consume.
with open(sentinel, "w") as f:
    f.write(str(drift_count))
PY

PY_RC=$?
if [ "$PY_RC" -ne 0 ]; then
    echo "ERROR: python3 parser failed (rc=$PY_RC)" >&2
    exit 1
fi

DRIFT_COUNT=$(cat "$SENTINEL" 2>/dev/null || echo 0)

if [ "$STRICT" -eq 1 ] && [ "$DRIFT_COUNT" -gt 0 ]; then
    exit 2
fi
exit 0
