#!/usr/bin/env bash
# tests/run-all-suites.sh — FROZEN shared parity runner (D-08; Phase 24 Plan 05).
#
# Usage: WIKI_IMPL=bash bash tests/run-all-suites.sh                              (per-test no-regression vs SUITE_MANIFEST.txt)
#        WIKI_IMPL=bash bash tests/run-all-suites.sh --capture-channels DIR       (exports IT_CAPTURE_DIR=DIR/<suite> per suite; each routed invoke_tool self-records under a collision-proof testbasename+pid+counter key)
#        bash tests/run-all-suites.sh --require-parity BASH_DIR PY_DIR            (PAIRS captures by the pid-STRIPPED <suite>/<testbasename>/<tool>-<NN> identity; FAILS on ANY channel byte-divergence AND on any unpaired key — REVIEWS HIGH#4 / cycle-3 finding #2 / cycle-6 fix #4 / TEST-01)
#        WIKI_IMPL=bash bash tests/run-all-suites.sh --exclude-test test_precommit_hooks.sh   (TEST-level exclusion for Plan 06's hook fallback; phase-24 stays in the suite list — cycle-6 fix #1/#3)
#        WIKI_IMPL=bash bash tests/run-all-suites.sh --capture-channels DIR --only-suite tests/phase-XX-divtest   (run ONLY a caller-supplied suite — incl. a scaffold suite outside the enumerated list — through the LIVE runner; the single mechanism tests/test_routed_parity_divergence.sh uses)
#
# Enumerated suites (NOT a glob — REVIEWS HIGH#5; RB-5 re-derivation: the REAL desktop
# phase-22 + phase-23 suites join, and the new goldens suite is phase-24):
#   09 09.1 10 11 12.1 12.2 13 15 18 20 22 23 24
# Channel capture relies on Plan 03's COLLISION-PROOF key (testbasename+pid+counter) so distinct test files
# in one suite sharing IT_CAPTURE_DIR=<DIR>/<suite> do NOT overwrite each other (cycle-4 finding #1); --require-parity
# STRIPS the -<pid> to pair the two runs' captures (cycle-6 fix #4 — the PIDs differ across the bash and py runs).
# --exclude-test <basename> / WIKI_PARITY_EXCLUDE_TESTS skip specific TEST FILES (NOT whole suites) so Plan 06's
# hook fallback drops ONLY the recursive hook self-tests while keeping every phase-24 golden (cycle-6 fix #1/#3).
# Knob combination: --exclude-test filters per-test-file WITHIN whichever suite set is active — the enumerated
# set by default, or the --only-suite selection when passed (independent axes; combining both is well-defined).
# oracle-exempt paths (machine-readable tests/oracle-exempt.txt) are NOT parity-verifiable — skipped/annotated
# with an EXEMPT line (cycle-3 finding #1 ripple + cycle-6 MEDIUM b).
# The plain (knob-free) CI matrix run executes the FULL enumerated set — exclusions are NEVER applied there.
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

SUITES=(09 09.1 10 11 12.1 12.2 13 15 18 20 22 23 24)
MANIFEST="$REPO_ROOT/tests/SUITE_MANIFEST.txt"
EXEMPT_TXT="$REPO_ROOT/tests/oracle-exempt.txt"

CAPTURE_DIR=""
REQUIRE_PARITY=0
PARITY_BASH_DIR=""
PARITY_PY_DIR=""
EXCLUDE_TESTS="${WIKI_PARITY_EXCLUDE_TESTS:-}"
ONLY_SUITES="${WIKI_PARITY_ONLY_SUITES:-}"

while [ "$#" -gt 0 ]; do
    case "$1" in
        --capture-channels)
            [ "$#" -ge 2 ] || { echo "ERROR: --capture-channels requires a dir" >&2; exit 1; }
            CAPTURE_DIR="$2"; shift 2 ;;
        --require-parity)
            [ "$#" -ge 3 ] || { echo "ERROR: --require-parity requires BASH_DIR PY_DIR" >&2; exit 1; }
            REQUIRE_PARITY=1; PARITY_BASH_DIR="$2"; PARITY_PY_DIR="$3"; shift 3 ;;
        --exclude-test)
            [ "$#" -ge 2 ] || { echo "ERROR: --exclude-test requires a basename" >&2; exit 1; }
            EXCLUDE_TESTS="$EXCLUDE_TESTS $2"; shift 2 ;;
        --only-suite)
            [ "$#" -ge 2 ] || { echo "ERROR: --only-suite requires a suite dir or name" >&2; exit 1; }
            ONLY_SUITES="$ONLY_SUITES $2"; shift 2 ;;
        --help|-h) sed -n '2,25p' "$0"; exit 0 ;;
        *) echo "ERROR: unknown option: $1" >&2; exit 1 ;;
    esac
done

is_excluded() {   # basename (with or without .sh) in the exclusion union?
    local base="$1" e
    for e in ${EXCLUDE_TESTS//:/ }; do
        [ "$base" = "$e" ] || [ "$base" = "${e%.sh}.sh" ] || [ "${base%.sh}" = "$e" ] && return 0
    done
    return 1
}

# ---------------------------------------------------------------------------
# --require-parity: cross-impl CHANNEL byte-comparison with PID-INDEPENDENT pairing
# (REVIEWS HIGH#4 / cycle-3 finding #2 / CYCLE-6 fix #4 / TEST-01).
# ---------------------------------------------------------------------------
if [ "$REQUIRE_PARITY" = "1" ]; then
    exempt_reason() {   # match a tool name / pairing key against tests/oracle-exempt.txt patterns
        local tool="$1" key="$2" pat reason
        [ -f "$EXEMPT_TXT" ] || return 1
        while IFS=$'\t' read -r pat reason; do
            case "$pat" in \#*|"") continue ;; esac
            # shellcheck disable=SC2254
            case "$tool" in $pat) printf '%s\n' "${reason:-exempt}"; return 0 ;; esac
            case "$key" in $pat) printf '%s\n' "${reason:-exempt}"; return 0 ;; esac
        done < "$EXEMPT_TXT"
        return 1
    }
    # Build the pid-stripped pairing map for one side: emits "pairkey<TAB>dir" lines.
    build_pairs() {
        local side="$1" suite testdir tool_dir seg pairseg
        ( cd "$side" && find . -mindepth 3 -maxdepth 3 -type d | sort ) | while IFS= read -r d; do
            d="${d#./}"
            suite="${d%%/*}"; rest="${d#*/}"
            seg="${rest%%/*}"; tool_dir="${rest#*/}"
            pairseg="$(printf '%s\n' "$seg" | sed -E 's/-[0-9]+$//')"
            printf '%s/%s/%s\t%s\n' "$suite" "$pairseg" "$tool_dir" "$side/$d"
        done
    }
    A="$(mktemp)"; B="$(mktemp)"
    build_pairs "$PARITY_BASH_DIR" > "$A"
    build_pairs "$PARITY_PY_DIR"  > "$B"
    total_a="$(wc -l < "$A")"; total_b="$(wc -l < "$B")"
    if [ "$total_a" = "0" ] && [ "$total_b" = "0" ]; then
        echo "PARITY FAIL: zero captured channels on BOTH sides — a zero-pairs walk is a FAILURE, not a pass (cycle-6 fix #4)" >&2
        exit 1
    fi
    rc=0; pairs=0
    # union of pairing keys
    while IFS= read -r key; do
        da="$(awk -F'\t' -v k="$key" '$1==k{print $2; exit}' "$A")"
        db="$(awk -F'\t' -v k="$key" '$1==k{print $2; exit}' "$B")"
        tool_seg="${key##*/}"; tool_name="$(printf '%s\n' "$tool_seg" | sed -E 's/-[0-9]+$//')"
        if reason="$(exempt_reason "$tool_name" "$key")"; then
            echo "EXEMPT: $key ($reason)"
            continue
        fi
        if [ -z "$da" ] || [ -z "$db" ]; then
            echo "PARITY FAIL: unpaired key $key (present on one side only — bash:'${da:-∅}' py:'${db:-∅}')" >&2
            rc=1
            continue
        fi
        pairs=$((pairs + 1))
        for ch in stdout stderr exit tree; do
            if ! cmp -s "$da/$ch" "$db/$ch"; then
                echo "PARITY FAIL ($ch): $key" >&2
                diff "$da/$ch" "$db/$ch" | head -10 >&2 || true
                rc=1
            fi
        done
    done < <(cat "$A" "$B" | cut -f1 | sort -u)
    if [ "$pairs" = "0" ] && [ "$rc" = "0" ]; then
        echo "PARITY FAIL: no pairs compared over a non-empty capture set (vacuous walk — cycle-6 fix #4)" >&2
        exit 1
    fi
    [ "$rc" = "0" ] && echo "PARITY OK: $pairs paired routed calls byte-identical across impls (4 channels each)"
    exit "$rc"
fi

# ---------------------------------------------------------------------------
# Suite run: per-test no-regression vs the pinned manifest (+ optional channel capture).
# ---------------------------------------------------------------------------
bash "$REPO_ROOT/tests/lib/no-direct-bin-calls.sh" >/dev/null || {
    echo "FATAL: direct bin calls found in the parity suites (seam-routing invariant broken)" >&2
    exit 1
}

declare -A BASELINE
if [ -f "$MANIFEST" ]; then
    while read -r name status; do
        case "$name" in \#*|"") continue ;; esac
        BASELINE["$name"]="$status"
    done < "$MANIFEST"
fi

# Resolve the active suite set: --only-suite selection (paths or bare names) or the enumerated list.
SUITE_DIRS=()
if [ -n "${ONLY_SUITES// /}" ]; then
    for s in ${ONLY_SUITES//:/ }; do
        if [ -d "$s" ]; then SUITE_DIRS+=("$(cd "$s" && pwd)")
        elif [ -d "$REPO_ROOT/$s" ]; then SUITE_DIRS+=("$REPO_ROOT/$s")
        elif [ -d "$REPO_ROOT/tests/phase-$s" ]; then SUITE_DIRS+=("$REPO_ROOT/tests/phase-$s")
        else echo "ERROR: --only-suite: no such suite: $s" >&2; exit 1; fi
    done
else
    for s in "${SUITES[@]}"; do
        d="$REPO_ROOT/tests/phase-$s"
        [ -d "$d" ] || { echo "FATAL: enumerated suite missing: tests/phase-$s (LOUD failure, not a glob skip)" >&2; exit 1; }
        SUITE_DIRS+=("$d")
    done
fi

RC=0
NEW_PASS=()
for d in "${SUITE_DIRS[@]}"; do
    suite="$(basename "$d")"; suite="${suite#phase-}"
    if [ -n "$CAPTURE_DIR" ]; then
        export IT_CAPTURE_DIR="$CAPTURE_DIR/$suite"    # ONE per-suite dir; Plan 03's collision-proof
        mkdir -p "$IT_CAPTURE_DIR"                     # testbasename+pid key prevents cross-test-file overwrite
    fi
    for t in "$d"/test_*.sh; do
        [ -f "$t" ] || continue
        base="$(basename "$t")"
        if is_excluded "$base"; then
            echo "SKIP (excluded): $suite/$base"
            continue
        fi
        name="phase-$suite/${base%.sh}"
        if PDF_EXTRACT_SKIP_LIVE="${PDF_EXTRACT_SKIP_LIVE:-1}" bash "$t" >/dev/null 2>&1; then
            status=PASS
        else
            status=FAIL
        fi
        pinned="${BASELINE[$name]:-}"
        if [ "$status" = "FAIL" ]; then
            if [ "$pinned" = "FAIL" ]; then
                echo "known-FAIL (pinned): $name"
            elif [ -z "$pinned" ] && [ -n "${ONLY_SUITES// /}" ]; then
                echo "FAIL (unpinned, --only-suite scaffold): $name" >&2
                RC=1
            elif [ -z "$pinned" ]; then
                echo "NEW FAILING TEST (absent from manifest): $name" >&2
                RC=1
            else
                echo "REGRESSION (PASS -> FAIL): $name" >&2
                RC=1
            fi
        else
            [ -z "$pinned" ] && NEW_PASS+=("$name")
        fi
    done
    [ -n "$CAPTURE_DIR" ] && unset IT_CAPTURE_DIR
done

if [ "${#NEW_PASS[@]}" -gt 0 ] && [ -z "${ONLY_SUITES// /}" ]; then
    echo "note: ${#NEW_PASS[@]} new passing test(s) not yet in the manifest (append them): ${NEW_PASS[*]}"
fi

# REVIEW FIX: a pinned test whose FILE vanished must not disappear silently — deleting an
# inconvenient parity-carrying test would shrink the net with every gate green. Removing a
# test requires a deliberate manifest edit in the same change. (Skipped under --only-suite.)
if [ -z "${ONLY_SUITES// /}" ] && [ -f "$MANIFEST" ]; then
    while read -r name status; do
        case "$name" in \#*|"") continue ;; esac
        if [ ! -f "$REPO_ROOT/tests/$(dirname "$name")/$(basename "$name").sh" ]; then
            echo "MANIFEST ROW WITHOUT A TEST FILE (deleted test? remove the row deliberately): $name" >&2
            RC=1
        fi
    done < "$MANIFEST"
fi
[ "$RC" = "0" ] && echo "RUN-ALL OK (WIKI_IMPL=${WIKI_IMPL:-bash}): no new per-test regression"
exit "$RC"
