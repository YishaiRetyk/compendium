#!/usr/bin/env bash
# REPO-03: bin/repo-snapshot.sh emits a snapshot skeleton from a local fixture
# git repo (no network): metadata (40-hex sha, branch, license, language),
# README body, empty Excerpts scaffold; --dest writes <dir>/source.md.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

TMP="$(mktemp -d -t phase22-snap-XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

# --- Fixture upstream repo ---
UP="$TMP/upstream"
mkdir -p "$UP"
(cd "$UP" && git init -q -b main && \
    git config user.email "fixture@example.com" && git config user.name "Fixture")
cat > "$UP/README.md" <<'EOF'
# Fixture Project

UNIQUE_README_MARKER — a neutral fixture readme.
EOF
cat > "$UP/LICENSE" <<'EOF'
MIT License

Permission is hereby granted, free of charge...
EOF
mkdir -p "$UP/src"
printf 'def main():\n    return 42\n' > "$UP/src/alpha.py"
printf 'def helper():\n    return 1\n' > "$UP/src/beta.py"
(cd "$UP" && git add -A && git -c commit.gpgsign=false commit -q -m "fixture")
EXPECT_SHA="$(git -C "$UP" rev-parse HEAD)"

# --- Run with --dest ---
bash "$REPO_ROOT/bin/repo-snapshot.sh" "file://$UP" --dest "$TMP/bundle" 2>/dev/null

OUT="$TMP/bundle/source.md"
[ -f "$OUT" ] || { echo "FAIL T1: --dest did not write source.md" >&2; exit 1; }
echo "PASS T1: --dest writes <dir>/source.md"

grep -q "^- Commit: $EXPECT_SHA$" "$OUT" || {
    echo "FAIL T2: metadata missing full 40-hex commit sha" >&2; cat "$OUT" >&2; exit 1; }
grep -q "^- Default branch: main$" "$OUT" || {
    echo "FAIL T2: metadata missing default branch" >&2; exit 1; }
grep -q "^- License: MIT$" "$OUT" || {
    echo "FAIL T2: license heuristic did not detect MIT" >&2; exit 1; }
grep -q "^- Primary language: Python$" "$OUT" || {
    echo "FAIL T2: language heuristic did not detect Python" >&2; exit 1; }
echo "PASS T2: Snapshot Metadata harvested (sha, branch, MIT, Python)"

grep -q 'UNIQUE_README_MARKER' "$OUT" || {
    echo "FAIL T3: README body not embedded" >&2; exit 1; }
echo "PASS T3: README body embedded under ## README"

grep -q '^## Excerpts$' "$OUT" || {
    echo "FAIL T4: missing ## Excerpts scaffold" >&2; exit 1; }
echo "PASS T4: empty ## Excerpts scaffold present"

# T5: stdout mode (no --dest) emits the same skeleton
# (capture first: `cmd | grep -q` under pipefail dies of SIGPIPE on early match)
STDOUT_RUN="$(bash "$REPO_ROOT/bin/repo-snapshot.sh" "file://$UP" 2>/dev/null)"
printf '%s' "$STDOUT_RUN" | grep -q '^## Snapshot Metadata$' || {
    echo "FAIL T5: stdout mode did not emit the skeleton" >&2; exit 1; }
echo "PASS T5: stdout mode works without --dest"

echo "PASS: test_repo_snapshot -- all 5 cases passed"
