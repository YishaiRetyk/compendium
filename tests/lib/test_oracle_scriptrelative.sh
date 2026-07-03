#!/usr/bin/env bash
# Seam self-test (REVIEWS HIGH#1 keystone + cycle-3 finding #1 refinement, PRE-FIX-FAILING):
# the script-relative long-pole tools (audit-claims, brownfield, gen-skills) run THROUGH the
# worktree oracle via SUBCOMMANDS THAT REACH lib/REPO_ROOT resolution — NOT --help, which exits
# during arg-parse before the resolution lines and is VACUOUS for HIGH#1. Against the old
# cp-into-flat-dir oracle these abort resolving <flat-dir>/lib under set -euo pipefail.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$REPO_ROOT/tests/lib/invoke_tool.sh"

fail() { echo "FAIL: $1" >&2; exit 1; }

# 1. audit-claims via a real read-only invocation that reaches AUDIT_LIB_DIR (:123).
#    (--help exits at :83 BEFORE :123 — deliberately NOT used here.)
FIX="$(mktemp -d)"; trap 'rm -rf "$FIX"' EXIT
(
  cd "$FIX"
  git init -q -b main
  git config user.email "fixture@example.com"
  git config user.name "Fixture"
  mkdir -p wiki-cloud/concepts
  printf -- '---\nid: sample-concept\ntitle: Sample Concept\ntype: concept\n---\n\n## TL;DR\n\n- A claim [prov:src-2026-01-01-sample#sec:intro]\n' \
      > wiki-cloud/concepts/sample-concept.md
  printf '# Index\n' > wiki-cloud/index.md
  git add -A
  git -c commit.gpgsign=false commit -qm seed
)
(
  cd "$FIX"
  invoke_tool audit-claims --sample 3 --format json
  [ "$IT_EXIT" = "0" ] || { echo "FAIL: audit-claims IT_EXIT=$IT_EXIT (expected 0, not a lib-resolution abort)" >&2; cat "$IT_STDERR" >&2; exit 1; }
  if grep -q 'No such file or directory' "$IT_STDERR"; then echo "FAIL: audit-claims aborted resolving libs" >&2; exit 1; fi
  head -c1 "$IT_STDOUT" | grep -q '\[' || { echo "FAIL: audit-claims did not emit JSON (lib resolution broken?)" >&2; exit 1; }
) || exit 1
echo "ok: audit-claims reached lib resolution through the worktree oracle"

# 2. brownfield via `scan --root <fixture>` (reaches SG_REPO_ROOT at :730; --help exits at :65).
VAULT="$(mktemp -d)"
printf -- '---\ntitle: A Note\n---\n\nSome text.\n' > "$VAULT/note-one.md"
printf '# Another\n\nMore text.\n' > "$VAULT/note-two.md"
invoke_tool brownfield scan --root "$VAULT"
[ "$IT_EXIT" = "0" ] || fail "brownfield scan IT_EXIT=$IT_EXIT (expected 0, not a \$0-relative abort)"
# The scan banner is a diagnostic -> stderr (stdout stays payload-clean).
grep -q 'Brownfield Scan Results' "$IT_STDERR" || fail "brownfield scan output missing (wrong tree resolved?)"
if grep -q 'No such file or directory' "$IT_STDERR"; then fail "brownfield aborted resolving its tree"; fi
rm -rf "$VAULT" .brownfield 2>/dev/null || true
echo "ok: brownfield scan reached SG_REPO_ROOT through the worktree oracle"

# 3. gen-skills --check (reaches SCRIPT_DIR/.. + cd REPO_ROOT; reads the WORKTREE's schema/).
invoke_tool gen-skills --check
[ "$IT_EXIT" = "0" ] || fail "gen-skills --check IT_EXIT=$IT_EXIT (expected 0 in a pristine worktree — wrong tree read?)"
if grep -q 'No such file or directory' "$IT_STDERR"; then fail "gen-skills aborted resolving its tree"; fi
echo "ok: gen-skills --check resolved the worktree tree"

echo "PASS: script-relative tools resolve their real libs through the worktree oracle"
