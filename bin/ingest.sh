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
Usage: bin/ingest.sh <source-file> [--slug <slug>] [--force]

Scaffolds source ingestion by:
  1. Creating dated directory structure in sources/ (UTC date)
  2. Copying the source file into place
  3. Computing content_hash (SHA-256)
  4. Printing ready-to-ingest instructions for the LLM agent

Options:
  --slug <slug>   Custom slug for the source directory (default: derived from filename)
  --force         Overwrite files in an existing destination directory
  --help, -h      Show this help message

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
        --force)
            FORCE=1
            shift
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

# ---------------------------------------------------------------------------
# Hash computation
# ---------------------------------------------------------------------------

HASH=$(compute_hash "${DEST_FILE}")

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
EOF
