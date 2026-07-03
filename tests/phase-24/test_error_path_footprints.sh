#!/usr/bin/env bash
# Phase 24 (TEST-03, D-17 + REVIEWS cycle-3 finding #1 + cycle-4 finding #2a):
# characterization footprints for EVERY genuinely-divergent exit code.
#   - Happy/read-only paths run THROUGH the worktree oracle (Plan 03).
#   - STATE-DEPENDENT error paths the frozen/shared worktree CANNOT reach
#     (init-wizard exit 4 [$0-relative REPO_ROOT + untracked .wizard-answers.yaml],
#     gen-skills DRIFT exit 1 [a pristine checkout is always in-sync]) are driven
#     from a WRITABLE EXTRACTED TREE (git archive <baseline> | tar -x) the driver
#     CAN seed — NOT the inert cd-into-fixture PWD driver (init-wizard is NOT
#     PWD-based). Their tree channel is a fixed placeholder (the full repo tree
#     varies with the baseline ref; the LOAD-BEARING channel is the exit file).
#   - init-wizard exit 3 strips PYTHON3 ONLY (a bash+git+coreutils PATH farm keeps
#     the harness alive) — not PATH=/nonexistent, which would break the seam itself.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

GOLD="$REPO_ROOT/tests/goldens"
RC=0

# Manual 4-channel writer for extracted-tree cases (tree = fixed placeholder).
write_channels_manual() {
    local casedir="$1" out="$2" err="$3" rc="$4"
    mkdir -p "$casedir"
    normalize < "$out" > "$casedir/stdout"
    normalize < "$err" > "$casedir/stderr"
    printf '%s\n' "$rc" > "$casedir/exit"
    printf 'tree channel not captured: extracted-tree case (full-repo tree varies with the baseline ref; exit/stdout/stderr are the load-bearing channels)\n' > "$casedir/tree"
}

# --- sync-claude --check on a DRIFTED pair (cwd-based tool -> through the oracle) -> exit 2
sync_claude_drift() {
    local fixture; fixture="$(mktemp -d)"
    (
        cd "$fixture"
        printf '# Agent rules\nline A\n' > AGENTS.md
        printf '# Agent rules\nline B (drifted)\n' > CLAUDE.md
        chmod 644 AGENTS.md CLAUDE.md
        invoke_tool sync-claude --check
        actual="$(mktemp -d)/case"
        capture_footprint "$PWD" "$actual"
        golden_check_or_freeze "$GOLD/sync-claude/check-drift" "$actual"
        assert_exit_code 2 "$(cat "$GOLD/sync-claude/check-drift/exit")" "sync-claude --check drift golden"
    ) || return 1
    rm -rf "$fixture"
}

# --- gen-skills --check IN-SYNC through the worktree oracle -> exit 0 (HIGH#1 ripple:
#     proves the oracle does not report false drift from a wrong tree)
gen_skills_in_sync() {
    local fixture; fixture="$(mktemp -d)"
    (
        cd "$fixture"
        invoke_tool gen-skills --check
        actual="$(mktemp -d)/case"
        capture_footprint "$PWD" "$actual"
        golden_check_or_freeze "$GOLD/gen-skills/check-in-sync" "$actual"
        assert_exit_code 0 "$(cat "$GOLD/gen-skills/check-in-sync/exit")" "gen-skills --check in-sync golden"
    ) || return 1
    rm -rf "$fixture"
}

# --- gen-skills --check DRIFT -> exit 1 (MANDATORY — cycle-4 finding #2a; NOT droppable).
#     The frozen worktree is always in-sync, so this is driven from a writable extracted tree.
gen_skills_drift() {
    local ext out err rc skill
    ext="$(extract_writable_tree)"
    skill="$(ls -d "$ext"/.claude/skills/*/ | head -1)SKILL.md"
    printf '\ndrift-injected line\n' >> "$skill"
    out="$(mktemp)"; err="$(mktemp)"
    if bash "$ext/bin/gen-skills.sh" --check >"$out" 2>"$err"; then rc=0; else rc=$?; fi
    local actual="$(mktemp -d)/case"
    write_channels_manual "$actual" "$out" "$err" "$rc"
    golden_check_or_freeze "$GOLD/gen-skills/check-drift" "$actual" || return 1
    assert_exit_code 1 "$(cat "$GOLD/gen-skills/check-drift/exit")" "gen-skills --check DRIFT golden (MANDATORY)" || return 1
    rm -rf "$ext"
}

# --- init-wizard exit 4 (already-initialized, source :221) from a WRITABLE EXTRACTED TREE:
#     .wizard-answers.yaml is NOT git-tracked (absent from any frozen worktree, which also
#     cannot be seeded); REPO_ROOT is $0-relative (:55), so seed the EXTRACTED tree's root
#     and run WITHOUT --dry-run so the :195 guard fires.
init_wizard_exit4() {
    local ext out err rc
    ext="$(extract_writable_tree)"
    printf 'x\n' > "$ext/.wizard-answers.yaml"
    # The already-initialized message embeds the answers file's MTIME as the setup
    # date — freeze it (case-specific frozen `now`, per the D-12 normalizer policy:
    # never widen the shared normalizer for a single tool's date).
    touch -d '2026-01-02 00:00:00 UTC' "$ext/.wizard-answers.yaml"
    out="$(mktemp)"; err="$(mktemp)"
    if bash "$ext/bin/init-wizard.sh" </dev/null >"$out" 2>"$err"; then rc=0; else rc=$?; fi
    local actual="$(mktemp -d)/case"
    write_channels_manual "$actual" "$out" "$err" "$rc"
    golden_check_or_freeze "$GOLD/init-wizard/already-initialized" "$actual" || return 1
    assert_exit_code 4 "$(cat "$GOLD/init-wizard/already-initialized/exit")" "init-wizard already-initialized golden" || return 1
    rm -rf "$ext"
}

# --- init-wizard exit 3 (pre-flight, source :165): strip PYTHON3 ONLY via a symlink farm
#     (bash/git/coreutils present so the wrapper + preflight itself still run).
init_wizard_exit3() {
    local ext out err rc farm t
    ext="$(extract_writable_tree)"
    farm="$(mktemp -d)"
    for t in bash sh git grep sed awk cat mkdir mktemp dirname basename readlink \
             cut tr sort find date stat cp mv rm ls chmod head tail wc env cmp diff \
             sha256sum tar uname; do
        p="$(command -v "$t" 2>/dev/null || true)"
        [ -n "$p" ] && ln -s "$p" "$farm/$t"
    done
    [ ! -e "$farm/python3" ] || { echo "FAIL: farm must NOT contain python3" >&2; return 1; }
    out="$(mktemp)"; err="$(mktemp)"
    set +e
    ( PATH="$farm"; export PATH; bash "$ext/bin/init-wizard.sh" --dry-run </dev/null >"$out" 2>"$err" )
    rc=$?
    set -e
    local actual="$(mktemp -d)/case"
    write_channels_manual "$actual" "$out" "$err" "$rc"
    golden_check_or_freeze "$GOLD/init-wizard/preflight-missing-dep" "$actual" || return 1
    assert_exit_code 3 "$(cat "$GOLD/init-wizard/preflight-missing-dep/exit")" "init-wizard pre-flight golden" || return 1
    grep -q 'python3' "$GOLD/init-wizard/preflight-missing-dep/stderr" || { echo "FAIL: preflight stderr does not name python3" >&2; return 1; }
    rm -rf "$ext" "$farm"
}

# --- a checker on a violating fixture -> exit 2 (through the oracle; --root fixture)
checker_violation() {
    local fixture; fixture="$(mktemp -d)"
    mkdir -p "$fixture/docs/wiki-local"
    printf 'leaked local path\n' > "$fixture/docs/wiki-local/leak.md"
    chmod 644 "$fixture/docs/wiki-local/leak.md"
    invoke_tool check-privacy --root "$fixture"
    local actual="$(mktemp -d)/case"
    capture_footprint "$fixture" "$actual"
    golden_check_or_freeze "$GOLD/checkers/check-privacy-violation" "$actual" || return 1
    assert_exit_code 2 "$(cat "$GOLD/checkers/check-privacy-violation/exit")" "check-privacy violation golden" || return 1
    rm -rf "$fixture"
}

# --- lint dual-mode exits + the malformed-YAML path (through the oracle).
#     Fixture holds ONLY a malformed page (no parseable frontmatter -> no decay/staleness
#     date math -> deterministic across days).
lint_dual_mode() {
    local mode="$1" case_name="$2"
    local fixture; fixture="$(mktemp -d)"
    (
        cd "$fixture"
        mkdir -p wiki-cloud/concepts
        printf -- '---\nid: broken\ntitle: [unclosed\n---\n\nbody\n' > wiki-cloud/concepts/broken.md
        chmod 644 wiki-cloud/concepts/broken.md
        if [ "$mode" = "json" ]; then
            invoke_tool lint --ci --format json
        else
            invoke_tool lint
        fi
        actual="$(mktemp -d)/case"
        capture_footprint "$PWD" "$actual"
        golden_check_or_freeze "$GOLD/lint/$case_name" "$actual"
    ) || return 1
    rm -rf "$fixture"
}

sync_claude_drift      || { echo "FAIL: sync-claude drift case" >&2; RC=1; }
gen_skills_in_sync     || { echo "FAIL: gen-skills in-sync case" >&2; RC=1; }
gen_skills_drift       || { echo "FAIL: gen-skills DRIFT case (MANDATORY)" >&2; RC=1; }
init_wizard_exit4      || { echo "FAIL: init-wizard exit-4 case" >&2; RC=1; }
init_wizard_exit3      || { echo "FAIL: init-wizard exit-3 case" >&2; RC=1; }
checker_violation      || { echo "FAIL: checker violation case" >&2; RC=1; }
lint_dual_mode json ci-json-malformed || { echo "FAIL: lint --ci json case" >&2; RC=1; }
lint_dual_mode text text-malformed    || { echo "FAIL: lint text case" >&2; RC=1; }

[ "$RC" = "0" ] && echo "PASS: error-path footprints (8 cases; exit-file goldens committed)"
exit "$RC"
