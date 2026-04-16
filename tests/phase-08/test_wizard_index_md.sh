#!/usr/bin/env bash
# tests/phase-08/test_wizard_index_md.sh -- Open Q1 + review concern #2:
# wiki/index.md is updated with a `## Decisions` subsection + wikilink entry
# via the narrow update_index_md() helper. Verifies all 3 guardrails:
#   (1) happy path (empty starting index) -> section created + entry appended
#   (2) idempotency (re-run with entry already present) -> no-op, no dup
#   (3) duplicate-header guard (file has 2 `## Decisions` headings) -> fail
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

WIZARD="$REPO_ROOT/bin/init-wizard.sh"
CANONICAL_ANSWERS="$REPO_ROOT/schema/fixtures/canonical-answers.yaml"

echo "TEST: wiki/index.md update_index_md() 3-guardrail contract (Open Q1, review concern #2)"

# ---------------------------------------------------------------------------
# Guardrail 1: happy path (empty starting index -> `## Decisions` created)
# ---------------------------------------------------------------------------
echo "  [1/3] happy path: empty-index starting state"

WORK="$(mktemp_repo)"
mkdir -p "$WORK/wiki"
cp "$REPO_ROOT/wiki/index.md" "$WORK/wiki/index.md"

WIZARD_GENERATED_AT=2026-04-16T12:00:00Z WIZARD_TEMPLATE_SHA=fixed-sha \
    bash "$WIZARD" --answers-file "$CANONICAL_ANSWERS" --render-to "$WORK" >/dev/null

assert_grep '^## Decisions$' "$WORK/wiki/index.md" "Decisions heading must be created"
assert_grep '\[\[dr-2026-04-16-initial-setup\|Initial Wizard Setup -- personal-knowledge\]\]' \
    "$WORK/wiki/index.md" "Decisions wikilink entry must be present"

header_count="$(grep -c '^## Decisions$' "$WORK/wiki/index.md")"
assert_eq 1 "$header_count" "exactly one '## Decisions' heading after happy-path run"

# ---------------------------------------------------------------------------
# Guardrail 2: idempotency (entry already present -> no-op, no duplicates)
# ---------------------------------------------------------------------------
echo "  [2/3] idempotency: re-render with entry already present"

WORK2="$(mktemp_repo)"
mkdir -p "$WORK2/wiki"
# Pre-populate index with the starter skeleton + an already-present Decisions
# section containing the exact wikilink entry the wizard would add.
cat >"$WORK2/wiki/index.md" <<'EOF'
---
id: index
title: Index
type: overview
status: active
summary: "Skeleton index — ingested content will appear here organized by knowledge domain."
created_at: 2026-04-15
updated_at: 2026-04-15
sources: []
epistemic_status: sourced
tags:
  - meta
domains:
  - wiki-infrastructure
privacy: cloud_safe
knowledge_domain: software
---

# Index

This is a skeleton index. Ingested content will appear here organized by knowledge domain.

## Decisions

- [[dr-2026-04-16-initial-setup|Initial Wizard Setup -- personal-knowledge]] -- Wizard-driven template personalization (wiki-infrastructure, 2026-04-16)
EOF

WIZARD_GENERATED_AT=2026-04-16T12:00:00Z WIZARD_TEMPLATE_SHA=fixed-sha \
    bash "$WIZARD" --answers-file "$CANONICAL_ANSWERS" --render-to "$WORK2" >/dev/null

header_count2="$(grep -c '^## Decisions$' "$WORK2/wiki/index.md")"
assert_eq 1 "$header_count2" "idempotent re-run must keep exactly one '## Decisions' heading"

entry_count="$(grep -c 'dr-2026-04-16-initial-setup' "$WORK2/wiki/index.md")"
assert_eq 1 "$entry_count" "idempotent re-run must not duplicate the wikilink entry"

# ---------------------------------------------------------------------------
# Guardrail 3: duplicate-header guard (2 `## Decisions` headings -> refuse)
# ---------------------------------------------------------------------------
echo "  [3/3] duplicate-header guard: 2 Decisions headings -> error"

WORK3="$(mktemp_repo)"
mkdir -p "$WORK3/wiki"
cat >"$WORK3/wiki/index.md" <<'EOF'
---
id: index
title: Index
type: overview
status: active
summary: "Skeleton index."
created_at: 2026-04-15
updated_at: 2026-04-15
sources: []
epistemic_status: sourced
tags:
  - meta
domains:
  - wiki-infrastructure
privacy: cloud_safe
knowledge_domain: software
---

# Index

## Decisions

- [[some-earlier-decision|Earlier]] -- old entry.

## Decisions

- [[another-dup-decision|Another]] -- duplicate heading malformed state.
EOF

STDERR_FILE="$WORK3/stderr.log"
set +e
bash "$WIZARD" --answers-file "$CANONICAL_ANSWERS" --render-to "$WORK3" 2>"$STDERR_FILE" >/dev/null
RC=$?
set -e

assert_eq 1 "$RC" "duplicate-header guard must exit non-zero (generic failure)"
if ! grep -qE "has 2 \`## Decisions\` headings" "$STDERR_FILE"; then
    echo "ASSERT FAIL: stderr must contain 'has 2 \`## Decisions\` headings' recovery message" >&2
    cat "$STDERR_FILE" >&2
    exit 1
fi

echo "PASS: all 3 update_index_md guardrails verified (happy path, idempotency, duplicate-header)"
exit 0
