#!/usr/bin/env bash
# I-12: wiki-cloud/decisions/dr-2026-04-16-progressive-disclosure-extraction.md exists with
# trigger_type: schema-update, affected_pages: [], and all 7 required sections
# (TL;DR, Decision, Why, Alternatives Considered, Consequences, Affected Pages, Sources).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

DR="$REPO_ROOT/wiki-cloud/decisions/dr-2026-04-16-progressive-disclosure-extraction.md"
test -f "$DR" || { echo "FAIL: $DR missing" >&2; exit 1; }

# Frontmatter: type, trigger_type, affected_pages
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
# R3 review consensus: require affected_pages: [] EXACTLY (D-14). No None fallback.
if ap != []:
    errors.append(f"affected_pages != [] exactly (got {ap!r}); D-14 requires empty list")
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
        || { echo "FAIL: DR missing section matching '$section'" >&2; exit 1; }
done

# Why section must state adopted framing AND what it replaced (AGENTS.md §4.6 line 511 requirement)
# Mechanical proxy: require at least one "replaced" or "replacing" or "prior" or "previously" token
# in the body of the Why section.
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

# Alternatives Considered must list >=1 alternative
python3 - "$DR" <<'PYEOF'
import sys, pathlib, re
text = pathlib.Path(sys.argv[1]).read_text()
m = re.search(r'^## Alternatives Considered\s*\n(.*?)(?=^## )', text, flags=re.DOTALL | re.MULTILINE)
if not m:
    sys.exit("FAIL: DR ## Alternatives Considered section empty or unbounded")
body = m.group(1)
# Require >=1 bulleted alternative
bullets = [ln for ln in body.splitlines() if re.match(r'^\s*-\s', ln)]
if len(bullets) < 1:
    sys.exit("FAIL: DR ## Alternatives Considered must list >=1 alternative (AGENTS.md §4.6 requirement)")
PYEOF

echo "PASS: wiki-cloud/decisions/dr-2026-04-16-progressive-disclosure-extraction.md valid"
