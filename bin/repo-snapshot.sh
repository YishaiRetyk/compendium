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
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: bin/repo-snapshot.sh <repo-url> [--dest <bundle-dir>] [--force]

Mechanical half of the repository acquisition runbook
(schema/reference/repository-ingestion.md): shallow-clone, harvest snapshot
metadata (commit SHA, default branch, license, dominant language), emit a
snapshot source.md SKELETON (metadata + README + empty Excerpts scaffold).
Curation stays human/agent judgment and happens AFTER this script.

  <repo-url>        e.g. https://github.com/<owner>/<repo>
  --dest <dir>      write <dir>/source.md (creates <dir>); default: stdout.
                    Refuses to overwrite an existing source.md (a curated
                    bundle) unless --force is given.
  --force           allow --dest to overwrite an existing source.md
EOF
}

REPO_URL=""
DEST=""
FORCE=0
while [ "$#" -gt 0 ]; do
    case "$1" in
        --help|-h) usage; exit 0 ;;
        --dest)
            [ "$#" -ge 2 ] || { echo "ERROR: --dest requires a value" >&2; exit 1; }
            DEST="$2"; shift 2 ;;
        --force) FORCE=1; shift ;;
        -*) echo "ERROR: unknown option: $1" >&2; exit 1 ;;
        *)
            [ -z "$REPO_URL" ] || { echo "ERROR: multiple repo URLs given" >&2; exit 1; }
            REPO_URL="$1"; shift ;;
    esac
done
[ -n "$REPO_URL" ] || { usage >&2; exit 1; }
if [ -n "$DEST" ] && [ -f "$DEST/source.md" ] && [ "$FORCE" -ne 1 ]; then
    echo "ERROR: $DEST/source.md already exists (curated bundle?) — re-running" >&2
    echo "would clobber curation. Pass --force to overwrite deliberately." >&2
    exit 1
fi

command -v git >/dev/null || { echo "ERROR: git not found" >&2; exit 1; }

TMP="$(mktemp -d -t repo-snapshot-XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

echo "Cloning (depth 1): $REPO_URL" >&2
git clone --quiet --depth 1 "$REPO_URL" "$TMP/repo"

COMMIT_SHA="$(git -C "$TMP/repo" rev-parse HEAD)"
DEFAULT_BRANCH="$(git -C "$TMP/repo" symbolic-ref --short HEAD 2>/dev/null || echo unknown)"
RETRIEVED="$(date -u +%Y-%m-%d)"
REPO_NAME="$(basename "$REPO_URL" .git)"

# --- License heuristic: first recognizable license family in a LICENSE file.
# Order is load-bearing (Phase 22 review): MPL/LGPL/AGPL license texts CITE the
# GNU GPL, so the more specific families must be checked BEFORE the GPL phrase.
LICENSE="unknown"
for f in LICENSE LICENSE.md LICENSE.txt LICENSE-MIT COPYING COPYING.md; do
    p="$TMP/repo/$f"
    [ -f "$p" ] || continue
    if grep -qi 'MIT License' "$p"; then LICENSE="MIT"
    elif grep -qi 'Apache License' "$p"; then LICENSE="Apache-2.0"
    elif grep -qi 'Mozilla Public License' "$p"; then LICENSE="MPL-2.0"
    elif grep -qi 'GNU LESSER GENERAL PUBLIC' "$p"; then LICENSE="LGPL"
    elif grep -qi 'GNU AFFERO GENERAL PUBLIC' "$p"; then LICENSE="AGPL-3.0"
    elif grep -qi 'GNU GENERAL PUBLIC LICENSE' "$p"; then
        if grep -qi 'Version 3' "$p"; then LICENSE="GPL-3.0"; else LICENSE="GPL"; fi
    elif grep -qi 'BSD' "$p"; then LICENSE="BSD"
    elif grep -qi 'unlicense' "$p"; then LICENSE="Unlicense"
    else LICENSE="present (unclassified)"
    fi
    break
done

# --- Dominant-language heuristic: most frequent implementation-file extension.
# The inner `|| true` guards keep a find traversal error or head-induced
# SIGPIPE from aborting the whole script under set -euo pipefail (the [ -n ]
# fallback below could otherwise never run — Phase 22 review).
PRIMARY_LANGUAGE="$(
    { find "$TMP/repo" -type f -not -path '*/.git/*' \
        \( -name '*.py' -o -name '*.js' -o -name '*.cjs' -o -name '*.mjs' \
           -o -name '*.ts' -o -name '*.tsx' -o -name '*.go' -o -name '*.rs' \
           -o -name '*.rb' -o -name '*.java' -o -name '*.c' -o -name '*.cpp' \
           -o -name '*.h' -o -name '*.sh' -o -name '*.lua' -o -name '*.swift' \
           -o -name '*.kt' -o -name '*.php' \) \
        2>/dev/null || true; } | { sed 's/.*\.//' | sort | uniq -c | sort -rn | head -1 || true; } |
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
        # Comment out the README's own H1 title lines: an embedded '# Title'
        # (level 1 <= 2) would immediately terminate the '## README' section
        # slice, making '#sec:readme' resolve to a hollow passage (Phase 22
        # review — found live on the first ingest). The title text is
        # preserved inside the comment; all '## ' subsections stay live H2
        # anchors for #sec: claims.
        sed 's/^# \(.*\)$/<!-- readme H1 demoted at snapshot: \1 -->/' "$README_PATH"
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
