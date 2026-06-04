#!/usr/bin/env bash
# tests/phase-10/test_ingest_strip_bootstrap_stage.sh
# Phase 10 Plan 04 (BRWN-10) — asserts bin/ingest.sh strips `bootstrap_stage`
# and `bootstrap_date` from the DEST_FILE when the source carries them in its
# YAML frontmatter, and emits a one-line D-21 stderr warning per field.
#
# W-6 strictening: the D-21 template MUST appear on a SINGLE line per field.
# We assert this via a combined-line grep (prefix + parenthetical suffix on
# one line) in addition to the two substring greps kept for defense-in-depth.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

tmp="$(mktemp -d -t phase10-ingest-XXXXXX)"
cd "$tmp"
git init -q -b main
git -c commit.gpgsign=false -c user.email='fixture@example.com' -c user.name='Fixture' \
    commit --allow-empty -q -m 'fixture seed'

mkdir -p inbox
cp "$REPO_ROOT/tests/phase-10/fixtures/bootstrapped-vault/wiki-cloud/entities/ingest-target.md" inbox/source.md

# Run ingest and capture stderr.
stderr_out="$(bash "$REPO_ROOT/bin/ingest.sh" inbox/source.md 2>&1 >/dev/null || true)"

# Persist stderr for full-line grep (W-6: single grep binds both halves).
stderr_file="$tmp/stderr.log"
printf '%s\n' "$stderr_out" > "$stderr_file"

# 1a) Substring grep — D-21 prefix for bootstrap_stage.
echo "$stderr_out" | grep -qF "Note: stripped bootstrap_stage=bootstrapped" \
    || { echo "FAIL: missing D-21 stderr template prefix for bootstrap_stage" >&2; echo "stderr was: $stderr_out" >&2; exit 1; }

# 1b) Substring grep — parenthetical suffix present.
echo "$stderr_out" | grep -qF "brownfield-scoped field; see AGENTS.md §5)." \
    || { echo "FAIL: D-21 stderr template missing parenthetical suffix" >&2; exit 1; }

# 1c) W-6 STRICTENING: combined-line grep binds both halves into a single-line match.
#     Guards against regression where the two halves are emitted on separate lines.
grep -qE "Note: stripped bootstrap_stage=[^ ]+ from .* during ingest \(brownfield-scoped field; see AGENTS\.md §5\)\." "$stderr_file" \
    || { echo "FAIL: D-21 stderr template did not appear as a single line (W-6 combined-line check)" >&2; echo "stderr was:" >&2; cat "$stderr_file" >&2; exit 1; }

# 2) D-21 for bootstrap_date — same substring + single-line checks.
echo "$stderr_out" | grep -qF "Note: stripped bootstrap_date=" \
    || { echo "FAIL: missing D-21 stderr template for bootstrap_date" >&2; exit 1; }
grep -qE "Note: stripped bootstrap_date=[^ ]+ from .* during ingest \(brownfield-scoped field; see AGENTS\.md §5\)\." "$stderr_file" \
    || { echo "FAIL: D-21 bootstrap_date stderr did not appear as a single line (W-6 combined-line check)" >&2; exit 1; }

# 3) DEST_FILE (under tmp/sources/...) does NOT contain bootstrap_stage or bootstrap_date.
dest="$(find sources -type f -name source.md | head -1)"
[ -n "$dest" ] || { echo "FAIL: ingest did not write DEST_FILE" >&2; exit 1; }
! grep -q '^bootstrap_stage:' "$dest" \
    || { echo "FAIL: bootstrap_stage not stripped from $dest" >&2; exit 1; }
! grep -q '^bootstrap_date:' "$dest" \
    || { echo "FAIL: bootstrap_date not stripped from $dest" >&2; exit 1; }

# 4) Body preserved verbatim: the fixture's "Entity body" line must survive.
grep -q 'Entity body' "$dest" \
    || { echo "FAIL: body was lost during strip" >&2; exit 1; }

cd - >/dev/null
rm -rf "$tmp"
echo "PASS: ingest.sh strips bootstrap_stage + bootstrap_date with D-21 stderr (single-line)"
