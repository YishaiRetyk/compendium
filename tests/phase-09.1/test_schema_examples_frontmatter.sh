#!/usr/bin/env bash
# I-5: Each schema/examples/<type>.md has valid YAML frontmatter with example: true,
# privacy: cloud_safe, and matching type: enum.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

cd "$REPO_ROOT"

python3 - <<'PYEOF'
import pathlib, sys
try:
    import yaml
except ImportError:
    sys.exit("FAIL: python3-yaml missing; tests/phase-08 pins this dependency")

EXPECTED_TYPES = {
    "entity.md": "entity",
    "concept.md": "concept",
    "source-summary.md": "source",   # filename uses hyphen, type enum is `source` (RESEARCH §2.3)
    "comparison.md": "comparison",
    "overview.md": "overview",
    "decision.md": "decision",
}

root = pathlib.Path("schema/examples")
if not root.is_dir():
    sys.exit("FAIL: schema/examples/ directory missing")

errors = []
for name, expected_type in EXPECTED_TYPES.items():
    p = root / name
    if not p.is_file():
        errors.append(f"{p}: missing"); continue
    parts = p.read_text().split("---", 2)
    if len(parts) < 3:
        errors.append(f"{p}: malformed frontmatter"); continue
    try:
        fm = yaml.safe_load(parts[1])
    except yaml.YAMLError as e:
        errors.append(f"{p}: YAML parse error -- {e}"); continue
    if fm.get("type") != expected_type:
        errors.append(f"{p}: type={fm.get('type')!r}, expected {expected_type!r}")
    if fm.get("example") is not True:
        errors.append(f"{p}: example != True (got {fm.get('example')!r})")
    if fm.get("privacy") != "cloud_safe":
        errors.append(f"{p}: privacy != cloud_safe (got {fm.get('privacy')!r})")

if errors:
    for e in errors: print("FAIL:", e, file=sys.stderr)
    sys.exit(1)
print("PASS: schema/examples/ frontmatter valid")
PYEOF
