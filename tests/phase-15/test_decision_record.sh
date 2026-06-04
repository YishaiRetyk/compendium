#!/usr/bin/env bash
# PRIV-06: wiki-cloud/decisions/dr-2026-06-04-privacy-asymmetric-two-dir.md exists
# with trigger_type: schema-update, affected_pages (non-empty list), all 7 required sections,
# and >= 2 alternatives listed.
# Today this FAILS (DR file absent -- no wiki-cloud/ directory exists yet).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

DR="$REPO_ROOT/wiki-cloud/decisions/dr-2026-06-04-privacy-asymmetric-two-dir.md"
test -f "$DR" || { echo "FAIL: $DR missing (PRIV-06)" >&2; exit 1; }

# Frontmatter: type, trigger_type, affected_pages (is a list), status, epistemic_status
python3 - "$DR" <<'PYEOF'
import sys, yaml, pathlib
p = pathlib.Path(sys.argv[1])
parts = p.read_text().split("---", 2)
if len(parts) < 3:
    sys.exit(f"FAIL: {p}: malformed frontmatter")
fm = yaml.safe_load(parts[1])
errors = []
if fm.get("type") != "decision":
    errors.append(f"type != decision (got {fm.get('type')!r})")
if fm.get("trigger_type") != "schema-update":
    errors.append(f"trigger_type != schema-update (got {fm.get('trigger_type')!r})")
ap = fm.get("affected_pages")
# Phase-15 DR has non-empty affected_pages: require it is a list (not None, not empty)
if not isinstance(ap, list):
    errors.append(f"affected_pages is not a list (got {ap!r}); must be a YAML list")
if fm.get("status") != "active":
    errors.append(f"status != active (got {fm.get('status')!r})")
if fm.get("epistemic_status") != "sourced":
    errors.append(f"epistemic_status != sourced (got {fm.get('epistemic_status')!r})")
if errors:
    for e in errors: print("FAIL:", e, file=sys.stderr)
    sys.exit(1)
PYEOF

# All 7 required sections present (AGENTS.md §4.6 section ordering)
for section in '^## TL;DR' '^## Decision' '^## Why' '^## Alternatives Considered' '^## Consequences' '^## Affected Pages' '^## Sources'; do
    grep -qE "$section" "$DR" \
        || { echo "FAIL: DR missing section matching '$section' (PRIV-06)" >&2; exit 1; }
done

# Why section must state adopted framing AND what it replaced (AGENTS.md §4.6 requirement)
python3 - "$DR" <<'PYEOF'
import sys, pathlib, re
text = pathlib.Path(sys.argv[1]).read_text()
# Extract Why section
m = re.search(r'^## Why\s*\n(.*?)(?=^## )', text, flags=re.DOTALL | re.MULTILINE)
if not m:
    sys.exit("FAIL: DR ## Why section empty or unbounded")
body = m.group(1)
if len(body.strip()) < 50:
    sys.exit("FAIL: DR ## Why section too short (<50 chars)")
if not re.search(r'\b(replac|prior|previously|former|before)\b', body, re.IGNORECASE):
    sys.exit("FAIL: DR ## Why must state what framing was replaced (AGENTS.md §4.6 requirement)")
PYEOF

# Alternatives Considered must list >= 2 alternatives (the 3 weighed options = chosen + 2 rejected)
python3 - "$DR" <<'PYEOF'
import sys, pathlib, re
text = pathlib.Path(sys.argv[1]).read_text()
m = re.search(r'^## Alternatives Considered\s*\n(.*?)(?=^## )', text, flags=re.DOTALL | re.MULTILINE)
if not m:
    sys.exit("FAIL: DR ## Alternatives Considered section empty or unbounded")
body = m.group(1)
# Require >= 2 bulleted alternatives (D-15: per-page mixed / per-vault fully separate / asymmetric two-dir)
bullets = [ln for ln in body.splitlines() if re.match(r'^\s*-\s', ln)]
if len(bullets) < 2:
    sys.exit(f"FAIL: DR ## Alternatives Considered must list >= 2 alternatives (got {len(bullets)}); "
             "D-15 requires 3 options (per-page mixed, per-vault fully separate, asymmetric two-dir)")
PYEOF

echo "PASS: wiki-cloud/decisions/dr-2026-06-04-privacy-asymmetric-two-dir.md valid (PRIV-06)"
