# tests/lib/template_guard.sh — shared "template-only" test guard.
#
# A few setup/skeleton tests (e.g. tests/phase-07/test_wiki_skeleton.sh) assert invariants of
# the RELEASED, neutralized TEMPLATE — an empty wiki-cloud/ skeleton, a short index.md, no
# accumulated content — that by design do NOT hold on a populated dev vault. Such a test must
# still gate the template (the setup-parity CI job runs against a released tree) yet must not
# false-fail on the dev repo where real content legitimately exists. Source this near the top
# (after REPO_ROOT is set) and call skip_if_dev_vault:
#
#     SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
#     REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
#     source "$REPO_ROOT/tests/lib/template_guard.sh"
#     skip_if_dev_vault "test_wiki_skeleton" "empty wiki-cloud/ skeleton (TMPL-05)"
#
# Discriminator: `.planning/` exists in the dev repo but is NEVER in the released template
# (excluded from the release allowlist — src/compendium/release.py). Its presence ⇒ dev vault
# ⇒ SKIP; its ABSENCE ⇒ a template/release checkout ⇒ RUN the assertions, so template
# pollution is still caught. (A content-heuristic skip — "wiki-cloud/ has content subdirs" —
# would wrongly PASS a POLLUTED template, the exact failure this guard is meant to catch.)

# is_dev_vault [<repo-root>] — returns 0/true on the dev repo, 1/false on a template checkout.
# Defaults to $REPO_ROOT (every consumer sets it before sourcing), then $PWD.
is_dev_vault() {
    local root="${1:-${REPO_ROOT:-$PWD}}"
    [ -d "$root/.planning" ]
}

# skip_if_dev_vault <test-name> [<reason>] — on the dev vault, print a SKIP line and exit 0
# (a skipped template-only test is a pass, not a failure, for the run.sh aggregators); on a
# template checkout this is a no-op (return 0) so the caller's assertions run and gate release.
skip_if_dev_vault() {
    local name="$1" reason="${2:-template-only invariant}"
    if is_dev_vault; then
        echo "SKIP: $name is template-only ($reason)."
        echo "      .planning/ present ⇒ dev vault, not a release checkout — the empty-template"
        echo "      assertions apply only to the released template (the setup-parity CI tree)."
        echo "$name: skipped (template-only, N/A on the dev vault)"
        exit 0
    fi
    return 0
}
