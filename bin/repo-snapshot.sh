#!/usr/bin/env bash
# bin/repo-snapshot.sh -- mechanical half of the repository acquisition runbook
# (schema/reference/repository-ingestion.md). Shallow-clones a repo to a temp
# dir, harvests snapshot metadata (commit SHA, default branch, license,
# dominant language), and emits a snapshot source.md SKELETON: metadata section
# filled in, README body appended, empty ## Excerpts scaffold.
#
# Curation (trimming the README, choosing docs, selecting excerpts) is
# human/agent judgment and happens AFTER this script -- the mechanical-vs-
# judgment boundary from the brownfield workflow applies here too.
#
# Usage:
#   bin/repo-snapshot.sh <repo-url> [--dest <bundle-dir>]
#
#   <repo-url>        e.g. https://github.com/<owner>/<repo>
#   --dest <dir>      write <dir>/source.md (creates <dir>); default: stdout
set -euo pipefail

usage() { sed -n '2,16p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

REPO_URL=""
DEST=""
while [ "$#" -gt 0 ]; do
    case "$1" in
        --help|-h) usage; exit 0 ;;
        --dest)
            [ "$#" -ge 2 ] || { echo "ERROR: --dest requires a value" >&2; exit 1; }
            DEST="$2"; shift 2 ;;
        -*) echo "ERROR: unknown option: $1" >&2; exit 1 ;;
        *)
            [ -z "$REPO_URL" ] || { echo "ERROR: multiple repo URLs given" >&2; exit 1; }
            REPO_URL="$1"; shift ;;
    esac
done
[ -n "$REPO_URL" ] || { usage >&2; exit 1; }

command -v git >/dev/null || { echo "ERROR: git not found" >&2; exit 1; }

TMP="$(mktemp -d -t repo-snapshot-XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

echo "Cloning (depth 1): $REPO_URL" >&2
git clone --quiet --depth 1 "$REPO_URL" "$TMP/repo"

COMMIT_SHA="$(git -C "$TMP/repo" rev-parse HEAD)"
DEFAULT_BRANCH="$(git -C "$TMP/repo" symbolic-ref --short HEAD 2>/dev/null || echo unknown)"
RETRIEVED="$(date -u +%Y-%m-%d)"
REPO_NAME="$(basename "$REPO_URL" .git)"

# --- License heuristic: first recognizable license family in a LICENSE file ---
LICENSE="unknown"
for f in LICENSE LICENSE.md LICENSE.txt LICENSE-MIT COPYING COPYING.md; do
    p="$TMP/repo/$f"
    [ -f "$p" ] || continue
    if grep -qi 'MIT License' "$p"; then LICENSE="MIT"
    elif grep -qi 'Apache License' "$p"; then LICENSE="Apache-2.0"
    elif grep -qi 'GNU GENERAL PUBLIC LICENSE' "$p"; then
        if grep -qi 'Version 3' "$p"; then LICENSE="GPL-3.0"; else LICENSE="GPL"; fi
    elif grep -qi 'GNU LESSER GENERAL PUBLIC' "$p"; then LICENSE="LGPL"
    elif grep -qi 'Mozilla Public License' "$p"; then LICENSE="MPL-2.0"
    elif grep -qi 'BSD' "$p"; then LICENSE="BSD"
    elif grep -qi 'unlicense' "$p"; then LICENSE="Unlicense"
    else LICENSE="present (unclassified)"
    fi
    break
done

# --- Dominant-language heuristic: most frequent implementation-file extension ---
PRIMARY_LANGUAGE="$(
    find "$TMP/repo" -type f -not -path '*/.git/*' \
        \( -name '*.py' -o -name '*.js' -o -name '*.cjs' -o -name '*.mjs' \
           -o -name '*.ts' -o -name '*.tsx' -o -name '*.go' -o -name '*.rs' \
           -o -name '*.rb' -o -name '*.java' -o -name '*.c' -o -name '*.cpp' \
           -o -name '*.h' -o -name '*.sh' -o -name '*.lua' -o -name '*.swift' \
           -o -name '*.kt' -o -name '*.php' \) \
        2>/dev/null | sed 's/.*\.//' | sort | uniq -c | sort -rn | head -1 |
    awk '{ext=$2}
         END{
           map["py"]="Python"; map["js"]="JavaScript"; map["cjs"]="JavaScript";
           map["mjs"]="JavaScript"; map["ts"]="TypeScript"; map["tsx"]="TypeScript";
           map["go"]="Go"; map["rs"]="Rust"; map["rb"]="Ruby"; map["java"]="Java";
           map["c"]="C"; map["cpp"]="C++"; map["h"]="C"; map["sh"]="Shell";
           map["lua"]="Lua"; map["swift"]="Swift"; map["kt"]="Kotlin"; map["php"]="PHP";
           if (ext in map) print map[ext]; else if (ext != "") print ext; else print "unknown"
         }'
)"
[ -n "$PRIMARY_LANGUAGE" ] || PRIMARY_LANGUAGE="unknown"

# --- README body ---
README_PATH=""
for f in README.md Readme.md readme.md README; do
    [ -f "$TMP/repo/$f" ] && { README_PATH="$TMP/repo/$f"; break; }
done

emit() {
    cat <<EOF
# ${REPO_NAME} — repository snapshot

## Snapshot Metadata

- Repository: ${REPO_URL}
- Commit: ${COMMIT_SHA}
- Default branch: ${DEFAULT_BRANCH}
- License: ${LICENSE}
- Primary language: ${PRIMARY_LANGUAGE}
- Retrieved: ${RETRIEVED}

## README

EOF
    if [ -n "$README_PATH" ]; then
        cat "$README_PATH"
    else
        echo "(no README found at snapshot time)"
    fi
    cat <<'EOF'

## Excerpts

<!-- Curator-selected code excerpts. Each entry heading is '### <path/to/file>'
     or '### <path/to/file>:L<n>-L<m>'; body is a fenced code block quoting the
     lines at the snapshot commit. #path: locators resolve against these
     headings (schema/reference/repository-ingestion.md). If you anchor a claim
     to code, quote the code here. -->
EOF
}

if [ -n "$DEST" ]; then
    mkdir -p "$DEST"
    emit > "$DEST/source.md"
    echo "Wrote $DEST/source.md (commit ${COMMIT_SHA:0:12}, branch ${DEFAULT_BRANCH})" >&2
    echo "Next: curate the README copy, populate ## Excerpts, then ingest." >&2
else
    emit
fi
