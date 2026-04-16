#!/usr/bin/env bash
# tests/phase-08/test_wizard_partial_failure.sh -- review concern #8:
# Simulates a mid-init failure and verifies the staging-dir pattern leaves
# repo-root untouched. Induction: pre-populate wiki/index.md with TWO
# `## Decisions` headings so the duplicate-header guard fires during
# staging validation (AFTER AGENTS.md / CLAUDE.md are rendered into staging
# but BEFORE the atomic promote to repo root).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

CANONICAL_ANSWERS="$REPO_ROOT/schema/fixtures/canonical-answers.yaml"

echo "TEST: staging-dir recovery -- partial failure leaves repo-root untouched (review #8)"

# Build a minimal fake repo skeleton so we can run the wizard in real-run
# mode (no --render-to) without polluting the real REPO_ROOT.
WORK="$(mktemp_repo)"
mkdir -p "$WORK/bin" "$WORK/schema" "$WORK/wiki/decisions"
cp "$REPO_ROOT/bin/init-wizard.sh" "$WORK/bin/init-wizard.sh"
cp "$REPO_ROOT/bin/sync-claude.sh" "$WORK/bin/sync-claude.sh"
cp "$REPO_ROOT/schema/AGENTS.template.md" "$WORK/schema/AGENTS.template.md"
chmod +x "$WORK/bin/init-wizard.sh" "$WORK/bin/sync-claude.sh"

# Induce mid-init failure: wiki/index.md with TWO `## Decisions` headings.
cat >"$WORK/wiki/index.md" <<'EOF'
---
id: index
title: Index
type: overview
status: active
summary: "Malformed skeleton."
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

- previous entry.

## Decisions

- duplicate heading (simulated malformed state).
EOF

WIZARD="$WORK/bin/init-wizard.sh"
STDERR_FILE="$WORK/stderr.log"

# Real-run mode: no --render-to, no --dry-run. Must exit non-zero due to
# duplicate-header guard firing during staging validation.
set +e
WIZARD_GENERATED_AT=2026-04-16T00:00:00Z WIZARD_TEMPLATE_SHA=fixed-sha \
    bash "$WIZARD" --answers-file "$CANONICAL_ANSWERS" 2>"$STDERR_FILE" >/dev/null
RC=$?
set -e

if [ "$RC" -eq 0 ]; then
    echo "ASSERT FAIL: expected non-zero exit on duplicate-header; got 0" >&2
    cat "$STDERR_FILE" >&2
    exit 1
fi

# Verify stderr contains the "Repo root untouched" recovery message.
if ! grep -qE 'Repo root untouched' "$STDERR_FILE"; then
    echo "ASSERT FAIL: stderr must contain 'Repo root untouched' recovery message" >&2
    cat "$STDERR_FILE" >&2
    exit 1
fi

# Verify repo-root stays untouched: no promoted artifacts should appear.
if [ -f "$WORK/AGENTS.md" ]; then
    echo "ASSERT FAIL: $WORK/AGENTS.md written despite staging-dir recovery" >&2
    exit 1
fi
if [ -f "$WORK/CLAUDE.md" ]; then
    echo "ASSERT FAIL: $WORK/CLAUDE.md written despite staging-dir recovery" >&2
    exit 1
fi
if [ -f "$WORK/.wizard-answers.yaml" ]; then
    echo "ASSERT FAIL: $WORK/.wizard-answers.yaml written despite staging-dir recovery" >&2
    exit 1
fi

# wiki/decisions/ should remain empty (no dr-*-initial-setup.md written).
if ls "$WORK/wiki/decisions/"dr-*-initial-setup.md 2>/dev/null | grep -q .; then
    echo "ASSERT FAIL: wiki/decisions/dr-*-initial-setup.md written despite staging-dir recovery" >&2
    ls "$WORK/wiki/decisions/" >&2
    exit 1
fi

# Verify staging dir was cleaned up (no .wizard-stage-* directories remain).
if ls -d "$WORK"/.wizard-stage-* 2>/dev/null | grep -q .; then
    echo "ASSERT FAIL: .wizard-stage-* directory not cleaned up" >&2
    ls -d "$WORK"/.wizard-stage-* >&2
    exit 1
fi

echo "PASS: staging-dir recovery verified -- repo-root untouched, staging cleaned up, error message clear"
exit 0
