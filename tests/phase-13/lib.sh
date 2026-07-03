#!/usr/bin/env bash
# tests/phase-13/lib.sh -- Phase 13 test helpers.
# The four core helpers (make_bare_repo, assert_exit_code, cleanup_fixture_repo,
# write_page) are copied VERBATIM from tests/phase-12.2/lib.sh (mktemp prefix
# bumped to phase13-). The three verifier helpers (make_fake_verifier,
# make_recording_verifier, make_argv_verifier) are NEW: they encode the D-01
# verifier subprocess contract so the non-deterministic (LLM) verdict step can be
# stubbed deterministically in downstream test_*.sh.
#
# Source this from tests/phase-13/test_*.sh:
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "$SCRIPT_DIR/lib.sh"

set -euo pipefail

# Repo root (run-from-anywhere-safe). Lets tests invoke $REPO_ROOT/bin/audit-claims.sh.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/tests/lib/invoke_tool.sh"   # Phase 24 Plan 05: the frozen parity seam

# Deterministic fixture commits (Phase 25 25-01 gate finding): audit-state.md embeds
# the fixture repo's HEAD SHA (last_audit_commit) — without pinned commit dates that
# SHA is runtime-born and the cross-run tree comparison can never byte-match.
export GIT_AUTHOR_DATE="2026-01-02T00:00:00Z" GIT_COMMITTER_DATE="2026-01-02T00:00:00Z"

# make_bare_repo  -> prints path to a fresh temp repo seeded with one empty commit.
# Tests build their fixture page-shape inline via write_page (no fixtures/ dir needed).
make_bare_repo() {
    local tmp
    tmp="$(mktemp -d -t phase13-XXXXXX)"
    (cd "$tmp" && git init -q -b main && \
        git config user.email "fixture@example.com" && \
        git config user.name "Fixture" && \
        git -c commit.gpgsign=false commit -q --allow-empty -m "seed")
    echo "$tmp"
}

# assert_exit_code <expected> <actual> <description>
assert_exit_code() {
    local expected="$1" actual="$2" desc="$3"
    if [ "$expected" != "$actual" ]; then
        echo "FAIL: $desc (expected exit=$expected, got $actual)" >&2
        return 1
    fi
}

# cleanup_fixture_repo <path>  -- safe rm -rf of a mktemp dir
cleanup_fixture_repo() {
    local path="$1"
    if [ -n "$path" ] && [ -d "$path" ] && [[ "$path" == /tmp/* ]]; then
        rm -rf "$path"
    fi
}

# write_page <repo> <relpath>
# Reads body from stdin (heredoc), creates parent dirs, writes to "$repo/$relpath".
# Used to build fixtures inline: BOTH the wiki-cloud/sources/<id>.md summary AND the raw
# sources/**/source.md file (self-contained fixtures -- see fixtures/README.md).
write_page() {
    local repo="$1" relpath="$2"
    local dir="$repo/$(dirname "$relpath")"
    mkdir -p "$dir"
    # Body is read from stdin (heredoc).
    cat > "$repo/$relpath"
}

# make_fake_verifier <repo> <verdict> <rationale> -> echoes path to the stub.
# Honors the D-01 contract: reads {claim,passage,support_type} on stdin, emits a
# canned {verdict,rationale,sub_claims} on stdout. IGNORES argv -- makes the whole
# pipeline reproducible by replacing the non-deterministic LLM verdict step.
make_fake_verifier() {
    cat > "$1/fake-verifier.sh" <<EOF
#!/usr/bin/env bash
read -r _input
printf '{"verdict":"%s","rationale":"%s","sub_claims":[]}\n' "$2" "$3"
EOF
    chmod +x "$1/fake-verifier.sh"; echo "$1/fake-verifier.sh"
}

# make_recording_verifier <repo> <verdict> -> echoes path to a verifier that
# APPENDS every stdin payload to "$repo/verifier-saw.log" before replying.
# Used by the load-bearing fail-closed partition negative test (D-02): assert
# the log NEVER contains the local_only source's distinctive passage text.
# NOTE the "$(cat)" form (not a single `read -r` line) so a MULTI-LINE JSON
# passage is captured intact in the sentinel log.
make_recording_verifier() {
    # Log path resolved from the script's OWN location, not baked in absolute
    # (Phase 25 25-01 gate finding): tests `git add -A` these generated scripts,
    # and an embedded mktemp path made the committed tree — and therefore the
    # HEAD SHA that audit-state records — vary per run.
    cat > "$1/recording-verifier.sh" <<'EOF'
#!/usr/bin/env bash
_here="$(cd "$(dirname "$0")" && pwd)"
_input="$(cat)"
printf '%s\n' "$_input" >> "$_here/verifier-saw.log"
EOF
    cat >> "$1/recording-verifier.sh" <<EOF
printf '{"verdict":"%s","rationale":"recorded","sub_claims":[]}\n' "$2"
EOF
    chmod +x "$1/recording-verifier.sh"; echo "$1/recording-verifier.sh"
}

# make_argv_verifier <repo> <verdict> -> echoes path to a verifier that proves
# the shlex.split / shell=False contract (REVIEW MEDIUM / LOW): it dumps its FULL
# argv ("$@") to "$repo/verifier-argv.log" and reads (then discards) stdin, then
# replies with <verdict> and a rationale echoing its $1 arg. The stdin-only-payload
# test (Plan 03 test_verifier_with_args.sh) asserts verifier-argv.log CONTAINS the
# passed --tag arg but NOT the claim/passage text. Kept SEPARATE from
# make_fake_verifier (which ignores argv) so no helper is overloaded -- this resolves
# the cycle-2 LOW: Plan 03 points test_verifier_with_args.sh at THIS helper, not the
# argv-ignoring make_fake_verifier.
make_argv_verifier() {
    # Same path-independence rationale as make_recording_verifier above.
    cat > "$1/argv-verifier.sh" <<'EOF'
#!/usr/bin/env bash
_here="$(cd "$(dirname "$0")" && pwd)"
printf '%s\n' "$*" >> "$_here/verifier-argv.log"
cat >/dev/null   # consume stdin, never echo it to argv
EOF
    cat >> "$1/argv-verifier.sh" <<EOF
printf '{"verdict":"%s","rationale":"arg=%s","sub_claims":[]}\n' "$2" "\$1"
EOF
    chmod +x "$1/argv-verifier.sh"; echo "$1/argv-verifier.sh"
}

export -f make_bare_repo assert_exit_code cleanup_fixture_repo write_page \
    make_fake_verifier make_recording_verifier make_argv_verifier
