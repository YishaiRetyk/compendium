#!/usr/bin/env bash
# bin/ingest.sh — LLM Wiki Compiler source ingest helper
#
# Scope (per D-11/D-12/D-13): file-system bookkeeping only. No LLM API calls.
# Requires: standard POSIX shell tools with `sha256sum` OR `shasum -a 256` available.
#
# Date policy: UTC (date -u +%Y-%m-%d). UTC is intentional for deterministic
# directory paths that do not shift based on the operator's local timezone.
# Two operators in different time zones ingesting the same source on the same
# calendar day should land in the same directory.
#
# Collision policy: if the destination directory already exists, the script
# fails with a clear error unless --force is passed. --force overwrites files
# in the existing directory without deleting it first.
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: bin/ingest.sh <source-file> [--slug <slug>] [--asset <path>] [--force] [--contributor <handle>]

Scaffolds source ingestion by:
  1. Creating dated directory structure in sources/ (UTC date)
  2. Copying the source file into place
  3. Computing content_hash (SHA-256)
  4. Printing ready-to-ingest instructions for the LLM agent

Options:
  --slug <slug>           Custom slug for the source directory (default: derived from filename)
  --asset <path>          Co-locate a bundle asset (e.g. the original PDF,
                          <path>/original.pdf) alongside source.md in the same
                          dated bundle dir.
  --force                 Overwrite files in an existing destination directory
  --contributor <handle>  Explicit contributor @handle for the log entry.
                          Auto-detects from git config user.email +
                          .git-author-map.txt if omitted. Single-author
                          repos auto-omit the field.
  --help, -h              Show this help message

Notes:
  - Dates are UTC (date -u) so paths are deterministic across time zones.
  - Requires sha256sum or shasum -a 256.
  - If --slug is omitted and sanitization of the filename yields an empty
    slug, the script fails with a clear error.
EOF
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

sanitize_slug() {
    local raw="$1"
    local s
    s=$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]')
    s=$(printf '%s' "$s" | sed -E 's/\.[^.]+$//')      # strip extension
    s=$(printf '%s' "$s" | sed -E 's/[^a-z0-9]+/-/g')  # non-alnum -> hyphen
    s=$(printf '%s' "$s" | sed -E 's/-+/-/g')          # collapse hyphens
    s=$(printf '%s' "$s" | sed -E 's/^-+|-+$//g')      # trim hyphens
    printf '%s' "$s"
}

compute_hash() {
    local file="$1"
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$file" | cut -d' ' -f1
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$file" | cut -d' ' -f1
    else
        echo "ERROR: No SHA-256 tool found. Install sha256sum or shasum." >&2
        exit 1
    fi
}

# D-19..D-21: resolve contributor handle.
# Order:
#   1. If --contributor <handle> provided, use it verbatim.
#   2. Else if single-author (git log --all --format='%ae' | sort -u | wc -l == 1), omit field.
#   3. Else look up `git config user.email` in .git-author-map.txt (case-insensitive).
#   4. On map hit, use mapped @handle.
#   5. On map miss, warn stderr + OMIT field (D-21: never write bare email).
resolve_contributor() {
    local repo_root="${1:-$PWD}"
    local explicit="$CONTRIBUTOR"
    if [ -n "$explicit" ]; then
        printf '%s' "$explicit"
        return 0
    fi
    # D-20 single-author detection
    local author_count
    author_count="$(cd "$repo_root" && git log --all --format='%ae' 2>/dev/null | sort -u | wc -l | tr -d ' ')"
    if [ "${author_count:-0}" -le 1 ]; then
        # Single-author: omit
        return 0
    fi
    # Multi-author: look up email in map
    local email
    email="$(cd "$repo_root" && git config user.email 2>/dev/null || true)"
    if [ -z "$email" ]; then
        echo "WARN: no git config user.email; omitting contributor:: field" >&2
        echo "      Set with: git config user.email <your-email>" >&2
        echo "      Or use: bin/ingest.sh --contributor @your-handle ..." >&2
        return 0
    fi
    local email_lc
    email_lc="$(printf '%s' "$email" | tr '[:upper:]' '[:lower:]')"
    local map="$repo_root/.git-author-map.txt"
    if [ ! -f "$map" ]; then
        echo "WARN: no .git-author-map.txt at repo root; cannot resolve $email to @handle" >&2
        echo "      Omitting contributor:: field." >&2
        echo "      Fix: add line '$email  ->  @your-handle' to .git-author-map.txt" >&2
        echo "      Or: re-run with --contributor @your-handle" >&2
        return 0
    fi
    local handle=""
    local line left right left_lc right_trimmed
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip comments and blank lines
        case "$line" in
            ''|\#*) continue ;;
        esac
        # Accept separator "  ->  " or tab
        if [[ "$line" == *"  ->  "* ]]; then
            left="${line%%  ->  *}"
            right="${line##*  ->  }"
        elif [[ "$line" == *$'\t'* ]]; then
            left="${line%%$'\t'*}"
            right="${line##*$'\t'}"
        else
            continue
        fi
        left_lc="$(printf '%s' "$left" | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
        right_trimmed="$(printf '%s' "$right" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
        if [ "$left_lc" = "$email_lc" ]; then
            handle="$right_trimmed"
            break
        fi
    done < "$map"
    if [ -n "$handle" ]; then
        printf '%s' "$handle"
        return 0
    fi
    # D-21 Pitfall 5 guard: NEVER write bare email
    echo "WARN: no mapping for $email in .git-author-map.txt; omitting contributor:: field" >&2
    echo "      Fix: add line '$email  ->  @your-handle' to .git-author-map.txt" >&2
    echo "      Or: re-run with --contributor @your-handle" >&2
    return 0
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

if [ "$#" -eq 0 ]; then
    usage
    exit 1
fi

SOURCE_FILE=""
SLUG_OVERRIDE=""
SLUG_PROVIDED=0
FORCE=0
CONTRIBUTOR=""
ASSET_FILE=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        --help|-h)
            usage
            exit 0
            ;;
        --slug)
            if [ "$#" -lt 2 ]; then
                echo "ERROR: --slug requires a value" >&2
                exit 1
            fi
            SLUG_OVERRIDE="$2"
            SLUG_PROVIDED=1
            shift 2
            ;;
        --asset)
            if [ "$#" -lt 2 ]; then
                echo "ERROR: --asset requires a value (path to the bundle asset, e.g. original.pdf)" >&2
                exit 1
            fi
            ASSET_FILE="$2"
            shift 2
            ;;
        --force)
            FORCE=1
            shift
            ;;
        --contributor)
            if [ "$#" -lt 2 ]; then
                echo "ERROR: --contributor requires a value (e.g., @octocat)" >&2
                exit 1
            fi
            CONTRIBUTOR="$2"
            # Normalize: ensure leading @
            case "$CONTRIBUTOR" in
                @*) : ;;
                *)  CONTRIBUTOR="@$CONTRIBUTOR" ;;
            esac
            shift 2
            ;;
        --)
            shift
            if [ "$#" -gt 0 ] && [ -z "${SOURCE_FILE}" ]; then
                SOURCE_FILE="$1"
                shift
            fi
            ;;
        -*)
            echo "ERROR: Unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
        *)
            if [ -z "${SOURCE_FILE}" ]; then
                SOURCE_FILE="$1"
            else
                echo "ERROR: Unexpected positional argument: $1" >&2
                usage >&2
                exit 1
            fi
            shift
            ;;
    esac
done

if [ -z "${SOURCE_FILE}" ]; then
    echo "ERROR: Missing <source-file> argument" >&2
    usage >&2
    exit 1
fi

if [ ! -f "${SOURCE_FILE}" ]; then
    echo "ERROR: Source file does not exist: ${SOURCE_FILE}" >&2
    exit 1
fi

if [ ! -r "${SOURCE_FILE}" ]; then
    echo "ERROR: Source file is not readable: ${SOURCE_FILE}" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Slug derivation and validation
# ---------------------------------------------------------------------------

BASENAME=$(basename -- "${SOURCE_FILE}")

if [ "${SLUG_PROVIDED}" -eq 1 ]; then
    SLUG=$(sanitize_slug "${SLUG_OVERRIDE}")
else
    SLUG=$(sanitize_slug "${BASENAME}")
fi

if [ -z "${SLUG}" ]; then
    echo "ERROR: Derived or provided slug is empty. Pass --slug <slug> with a non-empty value." >&2
    exit 1
fi

# Defensive: slug must match [a-z0-9-]+ only.
if ! printf '%s' "${SLUG}" | grep -qE '^[a-z0-9-]+$'; then
    echo "ERROR: Slug contains invalid characters (allowed: [a-z0-9-]): ${SLUG}" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Date computation
# ---------------------------------------------------------------------------

# UTC intentionally — see header comment on date policy.
TODAY=$(date -u +%Y-%m-%d)
YEAR=$(date -u +%Y)
MONTH=$(date -u +%Y-%m)

# ---------------------------------------------------------------------------
# Destination directory + collision handling
# ---------------------------------------------------------------------------

DEST_DIR="sources/${YEAR}/${MONTH}/${TODAY}-${SLUG}"

if [ -e "${DEST_DIR}" ]; then
    if [ "${FORCE:-0}" != "1" ]; then
        echo "ERROR: Destination already exists: ${DEST_DIR}" >&2
        echo "Pass --force to overwrite, or choose a different --slug." >&2
        exit 1
    fi
    echo "WARNING: --force specified; overwriting files in ${DEST_DIR}" >&2
fi

# Validate ALL --asset preconditions BEFORE creating the bundle dir or copying
# the source (review round 2): an asset-specific failure detected after source.md
# is written would leave a partial bundle behind. Every check that can fail must
# run while the tree is still untouched.
if [ -n "${ASSET_FILE}" ]; then
    if [ ! -f "${ASSET_FILE}" ]; then
        echo "ERROR: --asset file not found: ${ASSET_FILE}" >&2
        exit 1
    fi
    ASSET_BASE="$(basename "${ASSET_FILE}")"
    if [ "${ASSET_BASE}" = "source.md" ]; then
        echo "ERROR: --asset basename 'source.md' would clobber the ingested source" >&2
        exit 1
    fi
    ASSET_DEST="${DEST_DIR}/${ASSET_BASE}"
    if [ -e "${ASSET_DEST}" ] && [ "${FORCE:-0}" != "1" ]; then
        echo "ERROR: asset destination exists: ${ASSET_DEST} (use --force to overwrite)" >&2
        exit 1
    fi
fi

mkdir -p "${DEST_DIR}"

# ---------------------------------------------------------------------------
# File placement
# ---------------------------------------------------------------------------

# Derive the original extension. For basenames with a dot, take the last
# segment; otherwise, no extension. Markdown files always land as source.md.
case "${BASENAME}" in
    *.*)
        EXT=".${BASENAME##*.}"
        # Lowercase the extension for consistency.
        EXT=$(printf '%s' "${EXT}" | tr '[:upper:]' '[:lower:]')
        ;;
    *)
        EXT=""
        ;;
esac

# Markdown files use source.md by convention; other extensions are preserved.
case "${EXT}" in
    .md|.markdown)
        EXT=".md"
        ;;
esac

DEST_FILE="${DEST_DIR}/source${EXT}"

if [ "${FORCE:-0}" = "1" ]; then
    cp -f "${SOURCE_FILE}" "${DEST_FILE}"
else
    cp "${SOURCE_FILE}" "${DEST_FILE}"
fi

# D-11: co-locate the original asset (e.g. the source PDF) alongside source.md
# in the same dated bundle dir. Pre-validated above (existence, source.md-basename
# guard, no-overwrite-without-force) — pure file I/O here, nothing can fail on a
# precondition. The convention records `original_asset` as a bare co-located
# filename (${ASSET_BASE}), never an absolute path.
if [ -n "${ASSET_FILE}" ]; then
    cp "${ASSET_FILE}" "${ASSET_DEST}"
    echo "Co-located asset: ${ASSET_DEST}" >&2
fi

# ---------------------------------------------------------------------------
# BRWN-10: strip brownfield-scoped fields to prevent pollution
# ---------------------------------------------------------------------------
# If the source file carries `bootstrap_stage` or `bootstrap_date` (from a
# prior `bin/brownfield.sh bootstrap` pass), strip them from the copied
# DEST_FILE and emit a one-line stderr warning per field per D-21.
# Regex-only implementation: keeps bin/ingest.sh free of any preserving-YAML
# runtime dep (round-trip YAML is brownfield-path-only per CONTEXT.md
# §Established-Patterns).

BF_REL_PATH="${DEST_FILE#"$(pwd)/"}"
for BF_FIELD in bootstrap_stage bootstrap_date; do
    # Pre-filter: is the field present anywhere in DEST_FILE? The python3 pass
    # below re-confirms by scoping to the first `---`..`---` frontmatter block
    # so body text containing the token (e.g., inside a code block) is NOT
    # mutated or warned about.
    BF_VALUE_RAW="$(grep -E "^${BF_FIELD}:" "${DEST_FILE}" 2>/dev/null | head -1 || true)"
    if [ -z "${BF_VALUE_RAW}" ]; then
        continue
    fi
    # Extract the value (portion after the first colon, trimmed).
    BF_VALUE="$(printf '%s' "${BF_VALUE_RAW}" | sed -E 's/^[^:]+:[[:space:]]*//' | sed -E 's/[[:space:]]+$//')"
    # Frontmatter-scoped strip via python3; stdout reports whether a strip occurred.
    BF_STRIPPED="$(python3 - "${DEST_FILE}" "${BF_FIELD}" <<'PYSTRIP'
import re, sys
path, field = sys.argv[1], sys.argv[2]
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()
lines = content.splitlines(keepends=True)
# Locate frontmatter block boundaries: first two lines that equal "---".
in_fm = False
fm_end = -1
for i, ln in enumerate(lines):
    stripped = ln.rstrip('\r\n')
    if stripped == '---':
        if not in_fm:
            in_fm = True
        else:
            fm_end = i
            break
if fm_end < 0:
    # No frontmatter or unterminated — do nothing, report no strip.
    print('0')
    sys.exit(0)
pattern = re.compile(r'^' + re.escape(field) + r'\s*:')
new_lines = []
stripped_count = 0
for i, ln in enumerate(lines):
    if i <= fm_end and pattern.match(ln):
        stripped_count += 1
        continue
    new_lines.append(ln)
if stripped_count > 0:
    with open(path, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
print(str(stripped_count))
PYSTRIP
)"
    if [ "${BF_STRIPPED:-0}" != "0" ]; then
        echo "Note: stripped ${BF_FIELD}=${BF_VALUE} from ${BF_REL_PATH} during ingest (brownfield-scoped field; see AGENTS.md §5)." >&2
    fi
done

# ---------------------------------------------------------------------------
# Hash computation
# ---------------------------------------------------------------------------

HASH=$(compute_hash "${DEST_FILE}")

# ---------------------------------------------------------------------------
# Contributor resolution (D-19..D-21)
# ---------------------------------------------------------------------------

RESOLVED_CONTRIBUTOR="$(resolve_contributor "$(pwd)")"

# ---------------------------------------------------------------------------
# Output — scaffold summary and ingest instructions
# ---------------------------------------------------------------------------

cat <<EOF
=== Source Scaffolded ===

  File:    ${DEST_FILE}
  Slug:    ${SLUG}
  Hash:    sha256:${HASH}
  Date:    ${TODAY} (UTC)

=== Ready to Ingest ===

Tell your LLM agent:

  Ingest the source at ${DEST_FILE}

  Source metadata:
    content_hash: "sha256:${HASH}"
    ingested_at: ${TODAY}
    path: ${DEST_FILE}

  Follow the Ingest Workflow in AGENTS.md section 11.1.

=== Log Entry Template (append to wiki-cloud/log.md) ===

## [${TODAY}] ingest | <source title>

EOF

if [ -n "$RESOLVED_CONTRIBUTOR" ]; then
    printf 'contributor:: %s\n\n' "$RESOLVED_CONTRIBUTOR"
fi

cat <<EOF
<what was done, affected pages, rationale>
EOF
