#!/usr/bin/env bash
# bin/search.sh — LLM Wiki Compiler search helper
#
# Scope (per D-12): file-system search only. No LLM API calls. Agent-agnostic.
# Provides index-based and full-text search across the wiki, plus a query mode
# that scaffolds LLM prompts with relevant page paths.
#
# Output contracts are deterministic and machine-parseable per mode.
# See usage() for full documentation.
set -euo pipefail

WIKI_INDEX="wiki/index.md"
WIKI_DIR="wiki"

usage() {
    cat <<'EOF'
Usage: bin/search.sh [OPTIONS] <keyword>
       bin/search.sh --query "question"

Search wiki pages by keyword with deterministic output per mode.

Modes:
  Default                 Index lookup with TL;DR snippets
  --paths-only            Output file paths only (no headers, no TL;DR)
  --fulltext              Also search wiki/ body text (default: index-only)
  --query "Q"             Generate an LLM-ready prompt from a question
  --contributor <handle>  Filter wiki/log.md entries by contributor @handle.
                          Accepts both @octocat and octocat (leading @ optional).

Options:
  --help, -h              Show this help message

Output Contracts:
  Default mode:
    === Search Results ===
    wiki/<subdir>/<slug>.md -- <TL;DR first line>
    === N result(s) ===

  --paths-only mode:
    wiki/<subdir>/<slug>.md
    (bare paths, one per line, no headers)

  --query mode:
    === Query Prompt ===
    ... structured prompt ...
    === End Query Prompt ===

  No results (any mode):
    No results found for "<keyword>"

Exit codes:
  0  Success (including no results — that is informational, not an error)
  1  Error (no arguments, missing index, invalid flag)
EOF
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

extract_tldr() {
    local file="$1"
    sed -n '/^## TL;DR/,/^## /{/^## TL;DR/d;/^## /d;/^$/d;p;}' "$file" | head -1
}

resolve_page_path() {
    local title="$1"
    local slug
    slug=$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')
    for dir in "$WIKI_DIR"/entities "$WIKI_DIR"/concepts "$WIKI_DIR"/sources "$WIKI_DIR"/comparisons "$WIKI_DIR"/overviews; do
        if [ -f "$dir/$slug.md" ]; then
            echo "$dir/$slug.md"
            return 0
        fi
    done
    # Fallback: grep for matching title in all wiki files
    grep -rl "^title:.*$title" "$WIKI_DIR"/ 2>/dev/null | head -1
}

search_index() {
    local query="$1"
    # Match index lines that are list entries with wikilinks, case-insensitive
    grep -i "$query" "$WIKI_INDEX" | grep -E '^\- \[\[' || true
}

search_fulltext() {
    local query="$1"
    # Search body text of wiki pages, excluding index.md and log.md
    grep -ril "$query" "$WIKI_DIR"/ 2>/dev/null \
        | grep -v "$WIKI_INDEX" \
        | grep -v "$WIKI_DIR/log.md" \
        || true
}

format_result_line() {
    local path="$1"
    local tldr
    tldr=$(extract_tldr "$path")
    if [ -n "$tldr" ]; then
        echo "$path -- $tldr"
    else
        echo "$path -- (no TL;DR)"
    fi
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

if [ "$#" -eq 0 ]; then
    usage >&2
    exit 1
fi

KEYWORD=""
QUERY=""
PATHS_ONLY=0
FULLTEXT=0
CONTRIBUTOR_FILTER=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        --help|-h)
            usage
            exit 0
            ;;
        --query)
            if [ "$#" -lt 2 ]; then
                echo "ERROR: --query requires a value" >&2
                exit 1
            fi
            QUERY="$2"
            shift 2
            ;;
        --contributor)
            if [ "$#" -lt 2 ]; then
                echo "ERROR: --contributor requires a value (e.g., @octocat)" >&2
                exit 1
            fi
            CONTRIBUTOR_FILTER="$2"
            # Strip leading @ for internal matching (accept both forms)
            case "$CONTRIBUTOR_FILTER" in
                @*) CONTRIBUTOR_FILTER="${CONTRIBUTOR_FILTER#@}" ;;
            esac
            shift 2
            ;;
        --paths-only)
            PATHS_ONLY=1
            shift
            ;;
        --fulltext)
            FULLTEXT=1
            shift
            ;;
        -*)
            echo "ERROR: Unknown option: $1" >&2
            exit 1
            ;;
        *)
            if [ -z "$KEYWORD" ]; then
                KEYWORD="$1"
            else
                echo "ERROR: Unexpected positional argument: $1" >&2
                exit 1
            fi
            shift
            ;;
    esac
done

# ---------------------------------------------------------------------------
# Contributor filter mode (COLAB-07)
# ---------------------------------------------------------------------------

if [ -n "$CONTRIBUTOR_FILTER" ]; then
    LOG="$WIKI_DIR/log.md"
    if [ ! -f "$LOG" ]; then
        echo "No results found for \"@$CONTRIBUTOR_FILTER\"" >&2
        exit 0
    fi
    # Extract log entries (separated by `## [YYYY-MM-DD]` headers) whose body
    # contains `contributor:: @<filter>` (case-sensitive; handles are case-sensitive).
    python3 - "$LOG" "$CONTRIBUTOR_FILTER" <<'PYEOF'
import sys, re
log_path = sys.argv[1]
handle = sys.argv[2]
content = open(log_path, encoding='utf-8').read()
# Split into entries at `## [` headers; keep the header with each entry
parts = re.split(r'(?m)^(?=## \[)', content)
matches = []
for p in parts:
    if not p.strip().startswith('## ['):
        continue
    if re.search(r'contributor::\s*@' + re.escape(handle) + r'\b', p):
        matches.append(p.rstrip())
if not matches:
    print(f'No results found for "@{handle}"', file=sys.stderr)
    sys.exit(0)
print("=== Contributor Results ===")
for m in matches:
    print(m)
    print("---")
print(f"=== {len(matches)} result(s) ===")
PYEOF
    exit 0
fi

# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------

if [ ! -f "$WIKI_INDEX" ]; then
    echo "ERROR: $WIKI_INDEX not found" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Query mode
# ---------------------------------------------------------------------------

if [ -n "$QUERY" ]; then
    # Split question into words longer than 3 chars, search each
    RESULT_PATHS=()
    declare -A SEEN_PATHS

    for word in $QUERY; do
        # Skip short words (articles, prepositions)
        if [ "${#word}" -le 3 ]; then
            continue
        fi
        # Strip punctuation from word
        clean_word=$(echo "$word" | sed -E 's/[^a-zA-Z0-9]//g')
        if [ -z "$clean_word" ]; then
            continue
        fi

        index_lines=$(search_index "$clean_word")
        if [ -n "$index_lines" ]; then
            while IFS= read -r line; do
                title=$(echo "$line" | sed -E 's/.*\[\[([^]]+)\]\].*/\1/')
                path=$(resolve_page_path "$title")
                if [ -n "$path" ] && [ -z "${SEEN_PATHS[$path]+x}" ]; then
                    SEEN_PATHS["$path"]=1
                    RESULT_PATHS+=("$path")
                fi
            done <<< "$index_lines"
        fi
    done

    if [ ${#RESULT_PATHS[@]} -eq 0 ]; then
        echo "No results found for \"$QUERY\""
        exit 0
    fi

    echo "=== Query Prompt ==="
    echo ""
    echo "Question: $QUERY"
    echo ""
    echo "Relevant wiki pages (read in this order, TL;DR first, drill into Detail only if needed):"
    echo ""
    count=1
    for path in "${RESULT_PATHS[@]}"; do
        tldr=$(extract_tldr "$path")
        if [ -n "$tldr" ]; then
            echo "$count. $path -- $tldr"
        else
            echo "$count. $path -- (no TL;DR)"
        fi
        count=$((count + 1))
    done
    echo ""
    echo "Instructions:"
    echo "- Read TL;DR and Key Facts sections first (progressive disclosure)."
    echo "- Read Detail sections only where shallow content is insufficient."
    echo "- Cite specific wiki pages and provenance markers in your answer."
    echo "- If the answer produces novel synthesis, write it back to the wiki per AGENTS.md section 11.2."
    echo "=== End Query Prompt ==="
    exit 0
fi

# ---------------------------------------------------------------------------
# Keyword mode (default or --paths-only)
# ---------------------------------------------------------------------------

if [ -z "$KEYWORD" ]; then
    echo "ERROR: No keyword provided. Use <keyword> or --query \"question\"" >&2
    usage >&2
    exit 1
fi

# Collect results: deduplicated file paths
declare -A RESULT_MAP
RESULT_ORDER=()

# 1. Index search
index_lines=$(search_index "$KEYWORD")
if [ -n "$index_lines" ]; then
    while IFS= read -r line; do
        title=$(echo "$line" | sed -E 's/.*\[\[([^]]+)\]\].*/\1/')
        path=$(resolve_page_path "$title")
        if [ -n "$path" ] && [ -z "${RESULT_MAP[$path]+x}" ]; then
            RESULT_MAP["$path"]=1
            RESULT_ORDER+=("$path")
        fi
    done <<< "$index_lines"
fi

# 2. Full-text search (if --fulltext)
if [ "$FULLTEXT" -eq 1 ]; then
    ft_results=$(search_fulltext "$KEYWORD")
    if [ -n "$ft_results" ]; then
        while IFS= read -r path; do
            if [ -n "$path" ] && [ -z "${RESULT_MAP[$path]+x}" ]; then
                RESULT_MAP["$path"]=1
                RESULT_ORDER+=("$path")
            fi
        done <<< "$ft_results"
    fi
fi

# No results
if [ ${#RESULT_ORDER[@]} -eq 0 ]; then
    echo "No results found for \"$KEYWORD\""
    exit 0
fi

# Output
if [ "$PATHS_ONLY" -eq 1 ]; then
    for path in "${RESULT_ORDER[@]}"; do
        echo "$path"
    done
else
    echo "=== Search Results ==="
    for path in "${RESULT_ORDER[@]}"; do
        format_result_line "$path"
    done
    echo "=== ${#RESULT_ORDER[@]} result(s) ==="
fi
