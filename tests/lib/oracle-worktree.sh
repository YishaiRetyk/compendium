# tests/lib/oracle-worktree.sh — FROZEN shared seam (D-08).
# REVIEWS HIGH#1 KEYSTONE: the bash oracle runs <worktree>/bin/<tool>.sh, where <worktree> is a FULL
# checkout at the pinned baseline ref. This preserves the bin/-relative layout, so audit-claims.sh
# (unconditional AUDIT_LIB_DIR=$(dirname BASH_SOURCE)/lib), brownfield.sh ($(dirname $0)/..),
# and gen-skills.sh ($SCRIPT_DIR/..) resolve their REAL libs/REPO_ROOT and do NOT abort under set -e.
# A flat `cp bin/x.sh tests/lib/oracle/x.sh` would resolve tests/lib/oracle/lib (nonexistent) -> abort.

# PER-LANE ROOT KNOBS (REVIEWS cycle-6 fix #1 + #2 — the freeze/interface deadlock + the staged-index split).
# The seam previously bound a SINGLE $REPO_ROOT to BOTH the py-lane shim body/src AND the oracle's git commands.
# Plan 06's staged-parity gate needs the py leg to read the MATERIALIZED STAGED tree (no .git) while the oracle's
# `git worktree add`/`rev-parse` run against the REAL repo (.git intact). So there are now TWO independently-set roots:
#   WIKI_EXEC_ROOT       = where the py-lane shim body / src / ported.manifest are read (the EXEC root).
#   WIKI_ORACLE_GIT_ROOT = where the bash-oracle git commands + tests/freeze-baseline.sha resolve (the GIT root; MUST have .git).
# BOTH default to $REPO_ROOT, so the normal single-repo lane is byte-identical to before. The staged gate sets
# WIKI_EXEC_ROOT=<staged index, no .git> and WIKI_ORACLE_GIT_ROOT=<real repo>. These knobs are part of the FROZEN
# contract surface (D-08) — Plan 06 CONSUMES them (sets the env vars), it never edits this seam.
_oracle_exec_root() { printf '%s\n' "${WIKI_EXEC_ROOT:-$REPO_ROOT}"; }
_oracle_git_root()  { printf '%s\n' "${WIKI_ORACLE_GIT_ROOT:-$REPO_ROOT}"; }

# Is tests/ported.manifest non-empty (any non-comment, non-blank line)?  (N-4 silent-HEAD-fallback guard)
_oracle_manifest_nonempty() {
    local mf="$(_oracle_exec_root)/tests/ported.manifest"
    [ -f "$mf" ] || return 1
    grep -qvE '^[[:space:]]*#|^[[:space:]]*$' "$mf"
}

# Resolve the baseline ref the oracle checks out (see ORACLE-FREEZE ORDER in Plan 03):
#   phase-24-freeze^{commit} (tag, if reachable) -> tests/freeze-baseline.sha (committed SHA, if reachable) -> HEAD.
# N-4: if BOTH the tag and the committed SHA exist, REQUIRE they are equal (a stale tag must not silently
#      override a bumped committed SHA) — fail loudly on mismatch.
# N-4: if resolution would fall through to HEAD WHILE ported.manifest is non-empty, FAIL loudly — a silent
#      HEAD fallback while a tool is ported runs the python shim at HEAD on BOTH legs -> false-green collapse.
_oracle_baseline_ref() {
    local tag_sha="" file_sha=""
    local gr; gr="$(_oracle_git_root)"
    if tag_sha="$(git -C "$gr" rev-parse -q --verify 'phase-24-freeze^{commit}' 2>/dev/null)"; then :; else tag_sha=""; fi
    if [ -f "$gr/tests/freeze-baseline.sha" ]; then
        file_sha="$(tr -d '[:space:]' < "$gr/tests/freeze-baseline.sha")"
        if [ -n "$file_sha" ] && git -C "$gr" rev-parse -q --verify "${file_sha}^{commit}" >/dev/null 2>&1; then :; else file_sha=""; fi
    fi
    # N-4 tag-vs-SHA equality: if both resolve, they MUST be equal (a stale tag must not override).
    if [ -n "$tag_sha" ] && [ -n "$file_sha" ] && [ "$tag_sha" != "$file_sha" ]; then
        echo "ORACLE FATAL: phase-24-freeze^{commit} ($tag_sha) != tests/freeze-baseline.sha ($file_sha)." >&2
        echo "  A stale tag must not override a bumped committed SHA. Re-tag with 'git tag -f phase-24-freeze' or fix the file." >&2
        return 1
    fi
    if [ -n "$tag_sha" ]; then printf '%s\n' "$tag_sha"; return 0; fi
    if [ -n "$file_sha" ]; then printf '%s\n' "$file_sha"; return 0; fi
    # N-4 loud HEAD-fallthrough guard: HEAD is only safe when nothing is ported.
    if _oracle_manifest_nonempty; then
        echo "ORACLE FATAL: no reachable freeze baseline (tag/tests/freeze-baseline.sha) but tests/ported.manifest" >&2
        echo "  is NON-EMPTY. Falling back to HEAD would run the python shim on the WIKI_IMPL=bash leg too" >&2
        echo "  (both legs python) -> false-green. Pin the freeze baseline (Plan 06) before porting." >&2
        return 1
    fi
    git -C "$gr" rev-parse -q --verify 'HEAD^{commit}'   # Phase-24 fallback: HEAD is all-bash, manifest empty
}

# Path of the cached oracle worktree (N-5: PER-REPO + PER-BASELINE keyed so Phase-25 parallel clusters in
# separate clones/worktrees do not collide on one shared /tmp path). Derive the key from a hash of
# $REPO_ROOT + the baseline ref; honor an explicit WIKI_ORACLE_WORKTREE override.
_oracle_worktree_dir() {
    if [ -n "${WIKI_ORACLE_WORKTREE:-}" ]; then printf '%s\n' "$WIKI_ORACLE_WORKTREE"; return 0; fi
    local ref key
    ref="$(_oracle_baseline_ref)" || return 1
    key="$(printf '%s\n%s\n' "$(_oracle_git_root)" "$ref" | sha256sum | cut -c1-16)"
    printf '%s\n' "${TMPDIR:-/tmp}/wiki-oracle-worktree-${key}"
}

# Ensure the cached worktree exists at the resolved ref (idempotent; re-points if the ref changed).
# REVIEW FIXES (2026-07-03):
#  - REUSE now requires the cached worktree to be CLEAN (git status --porcelain empty): a tool
#    that mutated the shared worktree (e.g. a $0-relative writer) would otherwise be silently
#    reused as the "held-fixed" oracle by every later run — the corruption is invisible to the
#    HEAD-sha check alone. A dirty cache is recreated.
#  - Stale-registration recovery: a /tmp-cleaned worktree leaves a .git/worktrees registration
#    that makes every future `worktree add` at that path fail; `git worktree prune` runs before add.
#  - `git worktree add` failures are NO LONGER swallowed: the function fails LOUDLY (stderr +
#    return 1) instead of printing a nonexistent path that surfaces as misleading 127s downstream.
ensure_oracle_worktree() {
    local wt ref cur gr
    ref="$(_oracle_baseline_ref)" || return 1
    wt="$(_oracle_worktree_dir)" || return 1
    gr="$(_oracle_git_root)"
    if [ -d "$wt/.git" ] || [ -f "$wt/.git" ]; then
        cur="$(git -C "$wt" rev-parse -q --verify HEAD 2>/dev/null || echo none)"
        if [ "$cur" = "$ref" ] && [ -z "$(git -C "$wt" status --porcelain 2>/dev/null)" ]; then
            printf '%s\n' "$wt"
            return 0
        fi
        git -C "$gr" worktree remove --force "$wt" 2>/dev/null || rm -rf "$wt"
    elif [ -d "$wt" ]; then
        rm -rf "$wt"    # half-populated leftover (crash mid-add) — must not be accepted as the oracle
    fi
    git -C "$gr" worktree prune >/dev/null 2>&1 || true
    if ! git -C "$gr" worktree add --quiet --detach "$wt" "$ref" >/dev/null 2>&1; then
        echo "ORACLE FATAL: 'git worktree add $wt $ref' failed (stale registration? try 'git worktree prune' in $gr)" >&2
        return 1
    fi
    printf '%s\n' "$wt"
}

# Path to the held-fixed bash body for <tool> (inside the worktree -> $0-relative resolution is REAL).
oracle_tool_path() {
    local tool="$1" wt; wt="$(ensure_oracle_worktree)" || return 1
    printf '%s\n' "$wt/bin/${tool}.sh"
}
export -f _oracle_manifest_nonempty _oracle_baseline_ref _oracle_worktree_dir ensure_oracle_worktree oracle_tool_path _oracle_exec_root _oracle_git_root
