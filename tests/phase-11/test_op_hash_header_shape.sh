#!/usr/bin/env bash
# EXPECTED_BY: 11-02
# tests/phase-11/test_op_hash_header_shape.sh — D-10 header shape + REVIEWS
# item 13 (Gemini): op_hash + op_hash_scope on lines 2+3 immediately after
# the shebang on line 1 for every copied migration script.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
export BROWNFIELD_FIXTURE_TODAY=2026-04-20
export BROWNFIELD_FIXTURE_CREATED_AT=2026-04-20
export BROWNFIELD_TOOL_VERSION=1.1.0
export PYTHONPATH="${PYTHONPATH:-}${PYTHONPATH:+:}$HOME/.local/lib/python3/dist-packages"
NAME="$(basename "${BASH_SOURCE[0]}")"

TMP=$(make_fixture_repo small-vault-ambiguous)
trap 'rm -rf "$TMP"' EXIT

if ! bash "$REPO_ROOT/bin/brownfield.sh" suggest --root "$TMP" >/dev/null 2>&1; then
    echo "FAIL: bin/brownfield.sh suggest not yet implemented — Plan 11-02 pending" >&2
    exit 1
fi

for script in 01-page-typing.sh 02-provenance-bootstrap.sh 03-cross-link-inference.sh 04-privacy-review.sh; do
    path="$TMP/.brownfield/migrations/$script"
    assert_file_exists "$path"

    # Exactly one op_hash + one op_hash_scope line
    hc=$(grep -c '^# op_hash: sha256:' "$path" || true)
    sc=$(grep -c '^# op_hash_scope: canonical-script-body + data-schema-version$' "$path" || true)
    if [ "$hc" != "1" ]; then echo "FAIL: $script has $hc op_hash lines (expected 1)" >&2; exit 1; fi
    if [ "$sc" != "1" ]; then echo "FAIL: $script has $sc op_hash_scope lines (expected 1)" >&2; exit 1; fi

    # Shebang on line 1
    line1="$(sed -n '1p' "$path")"
    if [ "$line1" != "#!/usr/bin/env bash" ]; then
        echo "FAIL: $script line 1 is not the expected shebang: '$line1'" >&2
        exit 1
    fi

    # op_hash on line 2
    line2="$(sed -n '2p' "$path")"
    if ! echo "$line2" | grep -qE '^# op_hash: sha256:[0-9a-f]{64}$'; then
        echo "FAIL: $script line 2 does not match op_hash header: '$line2'" >&2
        exit 1
    fi

    # op_hash_scope on line 3
    line3="$(sed -n '3p' "$path")"
    if [ "$line3" != "# op_hash_scope: canonical-script-body + data-schema-version" ]; then
        echo "FAIL: $script line 3 does not match op_hash_scope: '$line3'" >&2
        exit 1
    fi
done

echo "PASS $NAME"; exit 0
