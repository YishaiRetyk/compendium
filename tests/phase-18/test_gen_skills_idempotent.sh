#!/usr/bin/env bash
# Covers: SKILL-01 idempotency (content checksum, not git diff -- avoids vacuous pass)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
[ -f "$REPO_ROOT/bin/gen-skills.sh" ] || { echo "SKIP (generator not implemented)"; exit 1; }
bash "$REPO_ROOT/bin/gen-skills.sh"
# Snapshot per-file checksums after the first run.
sums1=$(cd "$REPO_ROOT" && find .claude/skills -name SKILL.md | sort | xargs shasum 2>/dev/null || \
        find .claude/skills -name SKILL.md | sort | xargs sha256sum)
bash "$REPO_ROOT/bin/gen-skills.sh"
sums2=$(cd "$REPO_ROOT" && find .claude/skills -name SKILL.md | sort | xargs shasum 2>/dev/null || \
        find .claude/skills -name SKILL.md | sort | xargs sha256sum)
[ "$sums1" = "$sums2" ] || { echo "FAIL: second run changed file content"; echo "before: $sums1"; echo "after:  $sums2"; exit 1; }
echo "PASS: idempotent (byte-identical across runs)"
