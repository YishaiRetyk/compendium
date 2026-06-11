#!/usr/bin/env bash
# bin/pdf-extract.sh -- PDF->Markdown acquisition glue (Phase 20).
# Renders each PDF page to PNG (pdftoppm), OCRs it via a local Ollama VLM, and
# assembles <!-- page: N --> page markers. The FIRST repo script that invokes a
# local model: bin/ingest.sh's "no LLM calls" charter is per-script, not repo-wide.
set -euo pipefail

EXTRACT_VERSION="0.1.0"

# Defaults (overridable by env or flag). Env names are NAMESPACED (PDF_EXTRACT_*)
# because bare MODEL/DPI/PROMPT are collision-prone in CI/agent environments and
# would silently change behavior.
MODEL="${PDF_EXTRACT_MODEL:-richardyoung/olmocr2:7b-q8}"
DPI="${PDF_EXTRACT_DPI:-150}"
OLLAMA_URL="${OLLAMA_URL:-http://localhost:11434}"
PROMPT="${PDF_EXTRACT_PROMPT:-Extract all text from this document page as Markdown, preserving structure.}"
# Per-page curl --max-time bound (seconds): a wedged Ollama server or a cold model
# load must not hang the script, the live test, and the suite indefinitely. The
# /api/tags preflight cannot protect against a mid-generation hang.
PAGE_TIMEOUT="${PDF_EXTRACT_TIMEOUT:-300}"
# Optional model-options hook, e.g. '{"num_ctx":8192}' for dense pages. When
# non-empty it is validated with jq at preflight and merged into the request.
OLLAMA_OPTIONS_JSON="${OLLAMA_OPTIONS_JSON:-}"

OUT=""
PDF=""

usage() {
    cat <<EOF
Usage: pdf-extract.sh [--dpi N] [--model TAG] [--out FILE] <input.pdf>

PDF->Markdown acquisition glue: renders each page to PNG (pdftoppm), OCRs it via
a local Ollama VLM, and assembles one <!-- page: N --> marker per 1-based page so
the output is ready for standard ingest.

Arguments:
  <input.pdf>        Path to the input PDF (positional, required).

Options:
  --dpi N            Render resolution (default: ${DPI}).
  --model TAG        Ollama model tag (default: ${MODEL}).
  --out FILE         Output Markdown path (default: <input>.md).
  --help, -h         Show this help.

Requires: poppler (pdftoppm, pdfinfo), a reachable Ollama server, jq, base64, curl.

Env overrides:
  PDF_EXTRACT_MODEL          Model tag (same as --model).
  PDF_EXTRACT_DPI            Render DPI (same as --dpi).
  PDF_EXTRACT_PROMPT         OCR prompt sent with each page image.
  PDF_EXTRACT_TIMEOUT        Per-page curl timeout in SECONDS (default ${PAGE_TIMEOUT}).
                             NOTE: the FIRST page's call includes the model
                             cold-load (a ~9.5 GB model), so on a slow or
                             memory-pressured host page 1 may need a higher value.
                             A page-1 "timed out" error usually means raise this
                             override, not a hang.
  OLLAMA_URL                 Ollama server base URL (default ${OLLAMA_URL}).
  OLLAMA_OPTIONS_JSON        Optional JSON model-options blob (e.g. '{"num_ctx":8192}').

Output contract: one <!-- page: N --> marker per page, on its own line, where N
is the 1-based page number that begins below the marker.
EOF
}

# --- Arg parse (while/case, mirrors bin/ingest.sh) -----------------------------
while [ "$#" -gt 0 ]; do
    case "$1" in
        --help|-h)
            usage
            exit 0
            ;;
        --dpi)
            if [ "$#" -lt 2 ]; then
                echo "ERROR: --dpi requires a value" >&2
                exit 1
            fi
            DPI="$2"
            shift 2
            ;;
        --model)
            if [ "$#" -lt 2 ]; then
                echo "ERROR: --model requires a value" >&2
                exit 1
            fi
            MODEL="$2"
            shift 2
            ;;
        --out)
            if [ "$#" -lt 2 ]; then
                echo "ERROR: --out requires a value" >&2
                exit 1
            fi
            OUT="$2"
            shift 2
            ;;
        --)
            shift
            if [ "$#" -gt 0 ] && [ -z "${PDF}" ]; then
                PDF="$1"
                shift
            fi
            ;;
        -*)
            echo "ERROR: Unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
        *)
            if [ -z "${PDF}" ]; then
                PDF="$1"
            else
                echo "ERROR: Unexpected positional argument: $1" >&2
                usage >&2
                exit 1
            fi
            shift
            ;;
    esac
done

if [ -z "${PDF}" ]; then
    echo "ERROR: no input PDF given" >&2
    usage >&2
    exit 1
fi

# --- Preflight checks (fail loud) ----------------------------------------------
for cmd in pdftoppm pdfinfo jq base64 curl; do
    command -v "$cmd" >/dev/null 2>&1 || {
        echo "ERROR: required command not found: $cmd" >&2
        exit 1
    }
done

[ -f "$PDF" ] || { echo "ERROR: input PDF not found: $PDF" >&2; exit 1; }

# Validate the optional options blob before touching the model.
if [ -n "$OLLAMA_OPTIONS_JSON" ]; then
    echo "$OLLAMA_OPTIONS_JSON" | jq -e . >/dev/null 2>&1 || {
        echo "ERROR: OLLAMA_OPTIONS_JSON is not valid JSON: $OLLAMA_OPTIONS_JSON" >&2
        exit 1
    }
fi

# Server reachable?
curl -sf "$OLLAMA_URL/api/tags" >/dev/null 2>&1 || {
    echo "ERROR: Ollama server not reachable at $OLLAMA_URL" >&2
    exit 1
}

# Model actually pulled? (A reachable server with a missing model otherwise
# yields null text on every page.)
curl -sf "$OLLAMA_URL/api/tags" | jq -e --arg m "$MODEL" '.models[] | select(.name == $m)' >/dev/null || {
    echo "ERROR: model $MODEL not found on Ollama server (ollama pull $MODEL)" >&2
    exit 1
}

# --- Default OUT ---------------------------------------------------------------
OUT="${OUT:-${PDF%.pdf}.md}"

# --- Page count ----------------------------------------------------------------
PAGES=$(pdfinfo "$PDF" | awk '/^Pages:/{print $2}')
[[ "$PAGES" =~ ^[0-9]+$ ]] && [ "$PAGES" -gt 0 ] || {
    echo "ERROR: could not determine page count for $PDF" >&2
    exit 1
}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# Write to a temp output first; move into place only on success so a partial/
# aborted run never leaves a structurally-valid-looking $OUT behind.
OUT_TMP="$TMP/out.md"
: > "$OUT_TMP"

for N in $(seq 1 "$PAGES"); do
    # PER-PAGE output prefix so a stale PNG from a prior iteration can never be
    # picked up if cleanup ever fails or pdftoppm leaves residue.
    pdftoppm -png -r "$DPI" -f "$N" -l "$N" "$PDF" "$TMP/page-$N" >/dev/null

    # Select EXACTLY one render, failing loud on zero or multiple matches.
    PNG_COUNT=$(ls "$TMP/page-$N"-*.png 2>/dev/null | wc -l)
    [ "$PNG_COUNT" -eq 1 ] || {
        echo "ERROR: expected exactly 1 rendered PNG for page $N, found $PNG_COUNT" >&2
        exit 1
    }
    PNG=$(ls "$TMP/page-$N"-*.png)

    # Encode to a FILE, never a shell-var-into-argv: a 150-DPI page PNG base64
    # routinely exceeds Linux's 128 KB per-argument limit.
    base64 -w0 "$PNG" > "$TMP/page.b64"

    # Build the request JSON to a file via --rawfile (file-based I/O end to end).
    if [ -n "$OLLAMA_OPTIONS_JSON" ]; then
        jq -n --arg m "$MODEL" --arg p "$PROMPT" --rawfile img "$TMP/page.b64" \
            --argjson opts "$OLLAMA_OPTIONS_JSON" \
            '{model:$m, prompt:$p, images:[$img], stream:false} + {options:$opts}' > "$TMP/req.json"
    else
        jq -n --arg m "$MODEL" --arg p "$PROMPT" --rawfile img "$TMP/page.b64" \
            '{model:$m, prompt:$p, images:[$img], stream:false}' > "$TMP/req.json"
    fi

    # Capture the FULL response and check it before extracting text. NEVER pipe
    # straight to jq -r '.response' -- a failed call yields the literal string
    # "null" under a valid marker, the worst failure mode for a provenance system.
    RESP=$(curl -fsS --max-time "$PAGE_TIMEOUT" "$OLLAMA_URL/api/generate" -d @"$TMP/req.json") || {
        echo "ERROR: Ollama call failed (or timed out after ${PAGE_TIMEOUT}s) on page $N" >&2
        exit 1
    }
    echo "$RESP" | jq -e 'has("error")' >/dev/null 2>&1 && {
        echo "ERROR: Ollama error on page $N: $(echo "$RESP" | jq -r '.error')" >&2
        exit 1
    }
    echo "$RESP" | jq -e '.response != null' >/dev/null 2>&1 || {
        echo "ERROR: null response on page $N" >&2
        exit 1
    }
    TEXT=$(echo "$RESP" | jq -r '.response')

    # ALWAYS emit the marker even if TEXT is an empty string (a genuinely blank
    # page is legitimate; keeps #p slices aligned). Only null/error responses abort.
    printf '<!-- page: %d -->\n%s\n\n' "$N" "$TEXT" >> "$OUT_TMP"

    rm -f "$PNG" "$TMP/page.b64" "$TMP/req.json"
done

# Sanity-check: count emitted markers. `grep -c` exits 1 on zero matches, which
# would abort under set -e BEFORE the custom error fires -- the `|| true` keeps
# the count-mismatch diagnostic reachable.
MARKERS=$(grep -c '^<!-- page:' "$OUT_TMP" || true)
if [ "$MARKERS" != "$PAGES" ]; then
    echo "ERROR: marker count ($MARKERS) != page count ($PAGES)" >&2
    exit 1
fi

mv "$OUT_TMP" "$OUT"
echo "pdf-extract: wrote $OUT ($PAGES pages)" >&2
