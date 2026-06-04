#!/usr/bin/env bash
# bin/migrate-privacy-dirs.sh -- ONE-OFF Phase 15 migration helper.
# Converts the per-page privacy model to the asymmetric two-directory model.
#
# Pass 0: clean-tree precheck (ignores this file itself)
# Pass A: ROUTE -- git mv each wiki/**/*.md to wiki-cloud/ or wiki-local/ by privacy value
# Pass B: STRIP -- remove the `privacy` frontmatter field from all moved pages (ruamel)
# Pass C: MANIFEST-DRIVEN FIXTURE RE-KEY -- classify and re-key 94 .sh files across 9 phase dirs
#
# Usage: bash bin/migrate-privacy-dirs.sh [--dry-run]
#
# D-02: this script is designed to be run ONCE; all changes accumulate in the
# working tree and will be committed in the single security-atomic commit.
# D-03: route THEN strip -- never strip blind.
# D-04: use ruamel (via brownfield_yaml.py) for frontmatter mutation, never sed.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

echo "=== Phase 15 migration helper ==="
echo "REPO_ROOT: $REPO_ROOT"
[[ "$DRY_RUN" -eq 1 ]] && echo "(DRY-RUN mode)" || echo "(APPLY mode)"

# ---------------------------------------------------------------------------
# Pass 0: clean-tree precheck (D-02 ordering per cycle-2 MEDIUM)
# Ignore this helper itself (Pass 0 option b: filter own path)
# ---------------------------------------------------------------------------
echo ""
echo "--- Pass 0: clean-tree precheck ---"
DIRTY=$(git -C "$REPO_ROOT" status --porcelain | grep -v 'bin/migrate-privacy-dirs.sh' || true)
if [ -n "$DIRTY" ]; then
    echo "ERROR: working tree is not clean (ignoring this file):" >&2
    echo "$DIRTY" >&2
    exit 1
fi
HEAD_SHA=$(git -C "$REPO_ROOT" rev-parse --short HEAD)
echo "Clean tree. HEAD: $HEAD_SHA"

# ---------------------------------------------------------------------------
# Pass A: ROUTE -- git mv by privacy value
# ---------------------------------------------------------------------------
echo ""
echo "--- Pass A: ROUTE wiki/**/*.md to wiki-cloud/ or wiki-local/ ---"

WIKI_DIR="$REPO_ROOT/wiki"
if [ ! -d "$WIKI_DIR" ]; then
    echo "ERROR: wiki/ directory not found at $WIKI_DIR" >&2
    exit 1
fi

# Python helper: read privacy field from frontmatter generically
read_privacy() {
    local path="$1"
    python3 - "$path" <<'PYEOF'
import sys, re
path = sys.argv[1]
with open(path, encoding='utf-8', errors='replace') as f:
    text = f.read()
if not text.startswith('---'):
    print('cloud_safe')
    sys.exit(0)
parts = text.split('---', 2)
if len(parts) < 3:
    print('cloud_safe')
    sys.exit(0)
fm_text = parts[1]
for line in fm_text.splitlines():
    m = re.match(r'^privacy:\s*(\S+)', line.strip())
    if m:
        print(m.group(1).rstrip())
        sys.exit(0)
print('cloud_safe')
PYEOF
}

# Count stats
CLOUD_COUNT=0
LOCAL_COUNT=0

# Collect all .md files under wiki/
while IFS= read -r -d '' fpath; do
    # Get relative path from wiki/ root
    rel="${fpath#$WIKI_DIR/}"
    priv="$(read_privacy "$fpath")"

    if [[ "$priv" == "local_only" ]]; then
        dest_dir="$REPO_ROOT/wiki-local/$(dirname "$rel")"
        dest="$REPO_ROOT/wiki-local/$rel"
        LOCAL_COUNT=$((LOCAL_COUNT + 1))
    else
        dest_dir="$REPO_ROOT/wiki-cloud/$(dirname "$rel")"
        dest="$REPO_ROOT/wiki-cloud/$rel"
        CLOUD_COUNT=$((CLOUD_COUNT + 1))
    fi

    echo "  [$([ "$priv" = "local_only" ] && echo "LOCAL" || echo "CLOUD")] wiki/$rel -> $([ "$priv" = "local_only" ] && echo "wiki-local" || echo "wiki-cloud")/$rel"

    if [[ "$DRY_RUN" -eq 0 ]]; then
        mkdir -p "$dest_dir"
        git -C "$REPO_ROOT" mv "$WIKI_DIR/$rel" "$dest"
    fi
done < <(find "$WIKI_DIR" -name "*.md" -print0 | sort -z)

echo ""
echo "Pass A complete: $CLOUD_COUNT -> wiki-cloud/, $LOCAL_COUNT -> wiki-local/"

# Verify wiki/ is now empty (should be just empty dirs)
if [[ "$DRY_RUN" -eq 0 ]]; then
    remaining=$(find "$WIKI_DIR" -name "*.md" 2>/dev/null | wc -l)
    if [[ "$remaining" -gt 0 ]]; then
        echo "ERROR: $remaining .md files still under wiki/ after Pass A" >&2
        exit 1
    fi
    # Remove empty wiki/ dir
    find "$WIKI_DIR" -type d -empty -delete 2>/dev/null || true
    if [ -d "$WIKI_DIR" ]; then
        rmdir "$WIKI_DIR" 2>/dev/null || true
    fi
fi

# ---------------------------------------------------------------------------
# Pass B: STRIP privacy field from all moved pages (ruamel, NOT sed)
# ---------------------------------------------------------------------------
echo ""
echo "--- Pass B: STRIP privacy: field from moved pages ---"

STRIP_COUNT=0
SKIP_COUNT=0

python3 - "$REPO_ROOT" "$DRY_RUN" <<'PYEOF'
import sys, os, glob
sys.path.insert(0, os.path.join(sys.argv[1], 'bin', 'lib'))
from brownfield_yaml import read_fm_body, write_roundtrip

repo_root = sys.argv[1]
dry_run = sys.argv[2] == '1'

strip_count = 0
skip_count = 0

for tier in ('wiki-cloud', 'wiki-local'):
    tier_dir = os.path.join(repo_root, tier)
    if not os.path.isdir(tier_dir):
        continue
    for dirpath, dirs, files in os.walk(tier_dir):
        for fn in sorted(files):
            if not fn.endswith('.md'):
                continue
            fpath = os.path.join(dirpath, fn)
            rel = os.path.relpath(fpath, repo_root)
            try:
                fm, body, raw = read_fm_body(fpath)
            except Exception as e:
                print(f"  WARN: could not parse {rel}: {e}", flush=True)
                continue
            if fm is None:
                skip_count += 1
                continue
            if 'privacy' not in fm:
                skip_count += 1
                continue
            # Strip privacy field
            del fm['privacy']
            if not dry_run:
                write_roundtrip(fpath, fm, body, raw)
            print(f"  STRIPPED: {rel}", flush=True)
            strip_count += 1

print(f"\nPass B complete: {strip_count} stripped, {skip_count} skipped (no privacy field)")
PYEOF

# ---------------------------------------------------------------------------
# Pass C: MANIFEST-DRIVEN FIXTURE RE-KEY (all 9 phase dirs, 94 .sh files)
# ---------------------------------------------------------------------------
echo ""
echo "--- Pass C: MANIFEST-DRIVEN fixture re-key (9 phase dirs) ---"

MANIFEST="$REPO_ROOT/.planning/phases/15-privacy-architecture/pass-c-manifest.tsv"

# The 3 phase-13 resolver tests that must NOT be mechanically re-keyed (bucket-3)
RESOLVER_TESTS=(
    "tests/phase-13/test_privacy_resolve_precedence.sh"
    "tests/phase-13/test_claim_page_privacy.sh"
    "tests/phase-13/test_raw_source_privacy.sh"
)

python3 - "$REPO_ROOT" "$DRY_RUN" "$MANIFEST" "${RESOLVER_TESTS[@]}" <<'PYEOF'
import sys, os, re, csv

repo_root = sys.argv[1]
dry_run = sys.argv[2] == '1'
manifest_path = sys.argv[3]
resolver_tests = set(sys.argv[4:])

phase_dirs = [
    'tests/phase-07',
    'tests/phase-08',
    'tests/phase-09',
    'tests/phase-09.1',
    'tests/phase-10',
    'tests/phase-11',
    'tests/phase-12.1',
    'tests/phase-12.2',
    'tests/phase-13',
]

# Patterns for classification
# Audit maintenance paths (bucket 2 -> wiki-local/maintenance/)
AUDIT_MAINT_RE = re.compile(r'wiki/maintenance/audit-(report|state)\.md')
# Git-history paths (via git log/git show) -- keep literal wiki/ (bucket 4)
GIT_HISTORY_RE = re.compile(r'git\s+(log|show)\s+', re.IGNORECASE)

# We need per-OCCURRENCE classification. Each line of each file is processed.
manifest_rows = []  # (file, line_num, occurrence_text, bucket, action)
edits = {}  # file_path -> list of (old_line, new_line)

def classify_occurrence(filepath, line_num, line_text, bare_wiki_match):
    """Classify a single bare wiki/ occurrence in a shell file."""
    rel_path = os.path.relpath(filepath, repo_root)

    # Bucket 3: phase-13 resolver tests -- Task 5 owns structural rewrite
    if rel_path in resolver_tests:
        return '3-resolver-test', 'skip'

    # Bucket 4: git-history literal paths (git log --all / git show HEAD:)
    # Check if the OCCURRENCE is in a git show/log command context
    # Look at the broader line context
    stripped = line_text.strip()
    if (re.search(r'git\s+(log|show)\s+', line_text) or
            re.search(r'git\s+show\s+HEAD:', line_text) or
            re.search(r'git\s+log\s+', line_text)):
        return '4-git-history', 'skip'

    # Also catch git diff -- wiki/ pattern (bucket 4 - historical diff)
    # but NOT simple wiki/ path references that happen to be after 'diff'
    if re.search(r"'--'\s*,\s*'wiki/", line_text) or re.search(r'"--"\s+"wiki/', line_text):
        # These are git diff scopes in bin/ scripts -- handled separately (Task 3)
        # In TESTS, these likely reference old commit data
        if re.search(r'git\s+diff', line_text):
            return '4-git-history', 'skip'

    match_text = bare_wiki_match

    # Bucket 2: local audit control-plane (audit-report, audit-state -> wiki-local/maintenance/)
    if AUDIT_MAINT_RE.search(match_text):
        return '2-local-maint', 'wiki-local/maintenance/'

    # Bucket 1: cloud page references -> wiki-cloud/
    # This covers: wiki/concepts/, wiki/index.md, wiki/decisions/, wiki/entities/,
    # wiki/sources/, wiki/overviews/, wiki/comparisons/, wiki/log.md,
    # wiki/maintenance/lint-report.md, wiki/maintenance/ (lint-report stays cloud)
    return '1-cloud', 'wiki-cloud/'


# Process each file
total_processed = 0
total_rekeyed = 0

for phase_dir in phase_dirs:
    full_phase_dir = os.path.join(repo_root, phase_dir)
    if not os.path.isdir(full_phase_dir):
        print(f"  SKIP: {phase_dir} (not found)", flush=True)
        continue

    for fname in sorted(os.listdir(full_phase_dir)):
        if not fname.endswith('.sh'):
            continue
        fpath = os.path.join(full_phase_dir, fname)
        rel = os.path.relpath(fpath, repo_root)

        with open(fpath, 'r', encoding='utf-8', errors='replace') as f:
            original_lines = f.readlines()

        file_rows = []
        new_lines = list(original_lines)
        file_modified = False

        for i, line in enumerate(original_lines):
            line_num = i + 1
            # Find ALL bare wiki/ occurrences (not already wiki-cloud/ or wiki-local/)
            # Match: 'wiki/' or "wiki/" or wiki/ but NOT wiki-cloud/ or wiki-local/
            # Use a pattern that finds the wiki/ token preceded by quote or space or equals
            pattern = re.compile(r"(?<![a-z-])wiki/(?!(?:cloud|local)/)")
            matches = list(pattern.finditer(line))

            for m in matches:
                occurrence_text = line[m.start():m.start()+20].rstrip()  # context snippet
                bucket, action = classify_occurrence(fpath, line_num, line, occurrence_text)

                row = (rel, str(line_num), occurrence_text.replace('\t', ' '), bucket, action)
                file_rows.append(row)
                manifest_rows.append(row)

                if action == 'skip':
                    continue

                # Apply the re-key to this occurrence
                if not file_modified:
                    pass  # Will apply all at once after collecting

            # Collect all replacements for this line
            if any(r[1] == str(line_num) and r[4] != 'skip' for r in file_rows if r[0] == rel):
                # Apply replacements: bucket-1 -> wiki-cloud/, bucket-2 -> wiki-local/maintenance/
                new_line = line
                # For bucket-2 occurrences, replace audit maintenance paths
                for row in file_rows:
                    if row[0] == rel and row[1] == str(line_num) and row[3] == '2-local-maint':
                        new_line = new_line.replace('wiki/maintenance/audit-report.md',
                                                    'wiki-local/maintenance/audit-report.md')
                        new_line = new_line.replace('wiki/maintenance/audit-state.md',
                                                    'wiki-local/maintenance/audit-state.md')
                # For bucket-1 occurrences, replace bare wiki/ with wiki-cloud/
                for row in file_rows:
                    if row[0] == rel and row[1] == str(line_num) and row[3] == '1-cloud':
                        # Replace wiki/ with wiki-cloud/ (careful: not wiki-cloud/ already)
                        new_line = re.sub(r"(?<![a-z-])wiki/(?!(?:cloud|local)/)",
                                         'wiki-cloud/', new_line)

                if new_line != line:
                    new_lines[i] = new_line
                    file_modified = True

        if file_modified:
            total_rekeyed += 1
            print(f"  REKEYED: {rel}", flush=True)
            if not dry_run:
                with open(fpath, 'w', encoding='utf-8') as f:
                    f.writelines(new_lines)

        total_processed += 1

# Write the manifest TSV
os.makedirs(os.path.dirname(manifest_path), exist_ok=True)
with open(manifest_path, 'w', encoding='utf-8', newline='') as f:
    writer = csv.writer(f, delimiter='\t')
    writer.writerow(['file', 'line', 'occurrence_text', 'bucket', 'action'])
    for row in manifest_rows:
        writer.writerow(row)

print(f"\nPass C complete: {total_processed} files processed, {total_rekeyed} files modified")
print(f"Manifest written: {manifest_path} ({len(manifest_rows)} occurrences)")

# VERIFIER: fail if any occurrence has empty bucket
unclassified = [r for r in manifest_rows if not r[3]]
if unclassified:
    print(f"ERROR: {len(unclassified)} UNCLASSIFIED occurrences in manifest!", file=sys.stderr)
    for r in unclassified[:5]:
        print(f"  {r}", file=sys.stderr)
    sys.exit(1)
print("VERIFIER: all occurrences classified (no empty bucket)")
PYEOF

echo ""
echo "=== Migration helper complete ==="
echo "Next: verify wiki-cloud/ page count and no wiki/ dir exists, then commit all changes together."
