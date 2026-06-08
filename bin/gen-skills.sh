#!/usr/bin/env bash
# bin/gen-skills.sh -- Phase 18 / SKILL-01+SKILL-02: deterministic skill generator + --check drift gate.
#
# Artifact SOT: this script (body template + per-op description data, D-01/D-02).
# Behavioral SOT: schema/workflows/{op}.md (each SKILL.md body points there).
# DO NOT hand-edit .claude/skills/{op}/SKILL.md files -- they are derived copies.
#   Hand-edits are caught by --check and rejected.
#
# D-01: all inputs inline in this file (description strings + body template).
# D-02: fixed op quartet (ingest query lint reflect); adding/removing ops = code edit.
# D-05: exit 0=OK, 1=drift. Note: sync-claude.sh exits 2 on drift; gen-skills.sh
#   uses exit 1 per SPEC requirement 2. Behavior is otherwise identical.
# D-06: --check performs BOTH regenerate-diff AND independent structural assertions.
# D-07: structural assertions are NOT redundant with the regenerate-diff check.
#   A fattened template still passes diff (committed == fattened-template); the
#   independent assertions (<=3 body lines, dir-purity, no first-person pronoun, no
#   disable-model-invocation:true) are the real guard that the template stays thin.
#   Never remove these assertions as "redundant with diff".
#
# Bash 3.2 compat note: D-01 shows declare -A DESC; macOS ships bash 3.2 which
# lacks associative arrays. Using case-based get_desc() instead -- same inline,
# zero-dep, single-file intent, broader portability.
set -euo pipefail

OPS=(ingest query lint reflect)
CHECK_ONLY=0

get_desc() {
    local op="$1"
    case "$op" in
        ingest)
            # what+when, not how (REVIEWS.md MEDIUM: keep descriptions to what/when; do not
            # encode the classify-extract-merge-lint pipeline -- that is behavior owned by the
            # workflow file, and putting it in always-loaded L1 metadata duplicates behavior).
            echo "Processes a new source document into wiki pages. Invoke when asked to ingest, add, or process a new source into the wiki."
            ;;
        query)
            echo "Answers a question using the wiki and compiles any novel synthesis back into wiki pages. Invoke when asked to look up, explain, or synthesize wiki content."
            ;;
        lint)
            # Avoid the word "audit" (REVIEWS.md MEDIUM: Audit is a DISTINCT workflow in this
            # project -- bin/audit-claims.sh / schema/workflows/audit.md -- so naming it here
            # would mislead model invocation toward the wrong operation).
            echo "Detects and reports wiki quality issues including orphan pages, stale claims, broken provenance markers, and missing cross-references. Invoke when asked to lint or health-check the wiki."
            ;;
        reflect)
            echo "Performs structural reasoning over wiki history and authors decision records for significant schema or organizational changes. Invoke when asked to reflect, review, or record a decision."
            ;;
        *)
            echo "ERROR: unknown op: $op" >&2; exit 1
            ;;
    esac
}

body_for() {
    local op="$1"
    local desc
    desc="$(get_desc "$op")"
    cat <<EOF
---
name: ${op}
description: ${desc}
---

You have been invoked to ${op}. Read \`schema/workflows/${op}.md\` and follow it verbatim.
EOF
}

usage() {
    echo "Usage: bin/gen-skills.sh [--check]"
    echo ""
    echo "Without --check: write all four SKILL.md files (idempotent)."
    echo "With    --check: regenerate to temp dir, diff vs committed, run structural"
    echo "                 assertions, exit 0=OK / 1=drift."
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --help|-h) usage; exit 0 ;;
        --check) CHECK_ONLY=1; shift ;;
        *) echo "ERROR: unknown arg: $1" >&2; exit 1 ;;
    esac
done

if [ "$CHECK_ONLY" -eq 1 ]; then
    TMPDIR_CHECK="$(mktemp -d)"
    trap 'rm -rf "$TMPDIR_CHECK"' EXIT
    DRIFT=0

    # Step 1: regenerate-diff (D-06 first gate)
    for op in "${OPS[@]}"; do
        body_for "$op" > "$TMPDIR_CHECK/${op}-SKILL.md"
        committed=".claude/skills/${op}/SKILL.md"
        if [ ! -f "$committed" ]; then
            echo "DRIFT: $committed missing" >&2
            DRIFT=1
            continue
        fi
        if ! cmp -s "$TMPDIR_CHECK/${op}-SKILL.md" "$committed"; then
            echo "DRIFT: $committed differs from template. Run: bash bin/gen-skills.sh && git add .claude/skills/" >&2
            DRIFT=1
        fi
    done

    # Step 2: independent structural assertions (D-06/D-07)
    # These are NOT redundant with the regenerate-diff above. A fattened template
    # (with procedural content in the body) still passes diff (committed == fattened-
    # template). The assertions below are the real guard that the TEMPLATE itself
    # stays thin. Never remove these as "redundant with diff" (D-07).
    for op in "${OPS[@]}"; do
        dir=".claude/skills/${op}"
        skill="$dir/SKILL.md"
        [ -f "$skill" ] || continue  # already reported as missing above

        # Assert body <=3 lines (post-frontmatter lines only -- excludes the --- delimiters)
        body_lines=$(awk '/^---/{n++; if(n==2){found=1; next}} found{print}' "$skill" | wc -l)
        if [ "$body_lines" -gt 3 ]; then
            echo "ASSERT FAIL: $skill body has $body_lines lines (max 3)" >&2
            DRIFT=1
        fi

        # Assert the pointer target exists (REVIEWS.md MEDIUM: --check never verified that
        # schema/workflows/{op}.md exists -- a dead pointer would pass diff + line-count).
        if [ ! -f "schema/workflows/${op}.md" ]; then
            echo "ASSERT FAIL: pointer target schema/workflows/${op}.md does not exist (dead $skill pointer)" >&2
            DRIFT=1
        fi

        # Assert the directory contains ONLY SKILL.md (SPEC: each skill dir contains only
        # SKILL.md). Reject ANY top-level entry that is not SKILL.md -- not just extra *.md
        # files (REVIEWS.md Codex HIGH + recommended disposition item 4: a non-md file,
        # or a stray file the pre-commit hook might auto-stage, must also fail the gate). L2
        # loads ALL top-level files in a skill dir, so any stray file inflates context.
        extra=$(find "$dir" -mindepth 1 -maxdepth 1 ! -name "SKILL.md" | wc -l)
        if [ "$extra" -gt 0 ]; then
            echo "ASSERT FAIL: $dir contains $extra entr(y/ies) other than SKILL.md (dir-purity)" >&2
            DRIFT=1
        fi

        # Assert no first-person pronoun in description line. Use \b word boundaries so a
        # trailing pronoun at end-of-line is also caught (REVIEWS.md LOW: the older
        # [[:space:]](I|we)[[:space:]] form is a character-class/space-delimited match that
        # misses end-of-line and contraction edge cases). Case-sensitive on the explicit token
        # list to avoid flagging legitimate lowercase words.
        desc_val=$(grep "^description:" "$skill" || true)
        if echo "$desc_val" | grep -qE "\b(I|we|We|I'll|We'll|I've|We've|I'm|we're|We're)\b"; then
            echo "ASSERT FAIL: $skill description contains first-person pronoun" >&2
            DRIFT=1
        fi

        # Assert the description is a YAML-safe non-empty unquoted scalar (REVIEWS.md MEDIUM:
        # `description: ${desc}` is emitted unquoted; a future ':' or '#' in a description
        # would produce ambiguous/broken frontmatter the gate would otherwise miss). The value
        # after `description: ` must be non-empty and must not contain a colon-space (`: `) or a
        # ` #` that an unquoted YAML scalar would mis-parse.
        desc_payload=$(printf '%s\n' "$desc_val" | sed 's/^description: //')
        if [ -z "${desc_payload// /}" ]; then
            echo "ASSERT FAIL: $skill description is empty" >&2
            DRIFT=1
        elif printf '%s' "$desc_payload" | grep -qE ': | #'; then
            echo "ASSERT FAIL: $skill description has ': ' or ' #' -- breaks unquoted YAML; rephrase or quote in get_desc()" >&2
            DRIFT=1
        fi

        # Assert disable-model-invocation:true is NOT present (model invocation is allowed, D-05)
        if grep -q 'disable-model-invocation: *true' "$skill"; then
            echo "ASSERT FAIL: $skill has disable-model-invocation:true (model invocation is allowed)" >&2
            DRIFT=1
        fi
    done

    if [ "$DRIFT" -eq 0 ]; then
        echo "OK: .claude/skills/ matches template + all structural assertions pass"
        exit 0
    fi
    exit 1
fi

# Generate mode: write all four SKILL.md files (idempotent -- re-run overwrites identically)
for op in "${OPS[@]}"; do
    dir=".claude/skills/${op}"
    mkdir -p "$dir"
    body_for "$op" > "$dir/SKILL.md"
    echo "Generated $dir/SKILL.md"
done
echo "Done. Run 'git add .claude/skills/' to stage."
