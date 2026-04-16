#!/usr/bin/env bash
# CI-06 / D-08: --strict fails on PR-ADDED [inferred] without matching DR;
# passes with matching DR; DOES NOT fail on pre-existing debt (PR-diff scope).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

# ---------------------------------------------------------------------------
# Test A: PR-ADDED [inferred] without DR → --strict fails
# ---------------------------------------------------------------------------

FIXTURE="$(make_fixture_repo strict-missing-dr)"
trap 'cleanup_fixture_repo "$FIXTURE"' EXIT
pushd "$FIXTURE" >/dev/null

# The seed commit already contains the [inferred] claim. To simulate "PR adds the
# claim", we need origin/main to point at a commit BEFORE the claim existed.
# Strategy: (a) on main, remove the claim line; (b) checkout feature branch from
# the pre-seed state; (c) add the claim back; (d) seed_origin_main_ref pins
# origin/main at the "claim-free" commit.
git branch pre-claim  # marker before we mutate
# Remove the epistemic line on main to create a "pre-PR" main
python3 - <<'PYEOF'
p = "wiki/concepts/attention.md"
text = open(p).read().splitlines()
kept = [ln for ln in text if 'epistemic:: inferred' not in ln]
open(p, 'w').write('\n'.join(kept) + '\n')
PYEOF
git add -A
git -c commit.gpgsign=false commit -q -m "main: remove inferred claim"
# Now main has NO inferred claim. Create feature branch that RE-ADDS it.
git checkout -q -b feature
# Restore the file from the pre-claim snapshot (which still had the claim)
git checkout pre-claim -- wiki/concepts/attention.md
git add -A
git -c commit.gpgsign=false commit -q -m "feature: add inferred claim"
# Pin origin/main at main (the "PR base")
git checkout -q main
seed_origin_main_ref "$FIXTURE"
git checkout -q feature

# Sanity check: origin/main should NOT have the claim line; HEAD should.
if git show origin/main:wiki/concepts/attention.md 2>/dev/null | grep -q 'epistemic:: inferred'; then
    echo "FAIL: origin/main unexpectedly has the inferred claim" >&2
    popd >/dev/null; exit 1
fi
grep -q 'epistemic:: inferred' wiki/concepts/attention.md \
    || { echo "FAIL: HEAD missing the inferred claim (fixture setup broken)" >&2; popd >/dev/null; exit 1; }

# --strict should fail: the claim is PR-added and has no matching DR
if bash "$REPO_ROOT/bin/lint.sh" --strict wiki/ > /tmp/strict-out 2> /tmp/strict-err; then
    echo "FAIL: --strict should fail on PR-added [inferred] without DR" >&2
    cat /tmp/strict-out /tmp/strict-err >&2
    popd >/dev/null; exit 1
fi

# ---------------------------------------------------------------------------
# Test B: adding matching DR → passes
# ---------------------------------------------------------------------------

mkdir -p wiki/decisions
python3 - <<'PYEOF'
# Use python3 heredoc to avoid shell YAML delimiter (---) escaping pain
content = """---
id: dr-2026-04-16-attention
title: "Attention inference justification"
type: decision
status: active
summary: "Justifies [inferred] claim on attention."
created_at: 2026-04-16
updated_at: 2026-04-16
sources: []
epistemic_status: sourced
tags: [test]
domains: [test]
supersedes:
superseded_by:
privacy: cloud_safe
aliases: []
has_contradictions: false
knowledge_domain: science
example: false
trigger_type: reframing
affected_pages: [attention]
---

## TL;DR

Justifies inferred claim.

## Decision

Inferred claim approved.

## Why

Test fixture.

## Alternatives Considered

N/A.

## Consequences

None.

## Affected Pages

- [[Attention]]

## Sources

None.
"""
open("wiki/decisions/dr-2026-04-16-attention.md", "w").write(content)
PYEOF

git add . && git -c commit.gpgsign=false commit -q -m "feature: add DR"

bash "$REPO_ROOT/bin/lint.sh" --strict wiki/ >/dev/null 2>&1 \
    || { echo "FAIL: --strict should pass with matching DR" >&2; popd >/dev/null; exit 1; }

popd >/dev/null
cleanup_fixture_repo "$FIXTURE"
trap - EXIT

# ---------------------------------------------------------------------------
# Test B2: PR-scope guard — pre-existing debt does NOT fail --strict
# The critical scope test addressing Codex HIGH review concern.
# ---------------------------------------------------------------------------

FIXTURE2="$(make_fixture_repo strict-missing-dr)"
trap 'cleanup_fixture_repo "$FIXTURE2"' EXIT
pushd "$FIXTURE2" >/dev/null

# Seed commit ALREADY has the [inferred] claim. Pin origin/main at the seed
# commit directly. Then create an UNRELATED change on feature branch (no
# epistemic changes).
seed_origin_main_ref "$FIXTURE2"
git checkout -q -b feature
echo "# unrelated" > unrelated.md
git add unrelated.md
git -c commit.gpgsign=false commit -q -m "feature: unrelated change"

# The pre-existing [inferred] claim should NOT cause --strict to fail.
if ! bash "$REPO_ROOT/bin/lint.sh" --strict wiki/ >/dev/null 2>&1; then
    echo "FAIL: --strict must NOT fail on pre-existing [inferred] debt (D-08 PR-diff scope)" >&2
    popd >/dev/null; exit 1
fi

popd >/dev/null
cleanup_fixture_repo "$FIXTURE2"
trap - EXIT

# ---------------------------------------------------------------------------
# Test B3: fallback when no origin/main — stderr WARN + loose scan
# ---------------------------------------------------------------------------

FIXTURE3="$(make_fixture_repo strict-missing-dr)"
trap 'cleanup_fixture_repo "$FIXTURE3"' EXIT
pushd "$FIXTURE3" >/dev/null

# Explicitly DELETE origin/main ref if present (make_fixture_repo doesn't seed it,
# but guard against future harness changes).
git update-ref -d refs/remotes/origin/main 2>/dev/null || true
git update-ref -d refs/remotes/origin/HEAD 2>/dev/null || true

# Run --strict; capture stderr
bash "$REPO_ROOT/bin/lint.sh" --strict wiki/ > /tmp/fb-out 2> /tmp/fb-err || true
grep -q "WARN: no origin/main" /tmp/fb-err \
    || { echo "FAIL: missing 'WARN: no origin/main' stderr line" >&2; cat /tmp/fb-err >&2; popd >/dev/null; exit 1; }

popd >/dev/null
echo "PASS: --strict DR-match (PR-scoped + pre-existing-debt safe + origin/main fallback WARN)"
