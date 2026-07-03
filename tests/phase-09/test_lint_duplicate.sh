#!/usr/bin/env bash
# Quick task 260602-d6a: `duplicate` lexical near-duplicate-page lint category.
# Self-contained (no git needed -- the duplicate check is pure file inspection).
# Asserts: positive finding (near-duplicate same-type pair, survivor = higher
# inbound-link count), negative zero (distinct same-type pages), and exclusion
# (example:true / archived pages produce no finding).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$REPO_ROOT/tests/lib/invoke_tool.sh"   # Phase 24 Plan 05: the frozen parity seam

TMP="$(mktemp -d -t lint-duplicate-XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

WIKI="$TMP/wiki"
mkdir -p "$WIKI/entities"
cat > "$WIKI/index.md" <<'IDX'
# Index
IDX
cat > "$WIKI/log.md" <<'LOG'
# Log
LOG

# Minimal base frontmatter helper inlined per page (only fields the duplicate
# check reads -- id, title, type, status, aliases -- plus a body for linking).

# --- Positive fixture: two near-duplicate entity pages ---
# "Geoff Hinton" vs "Geoffrey Hinton": Levenshtein("geoff hinton","geoffrey
# hinton") = 3 ... not < 3. But "Geoff Hinton" IS a substring of nothing here,
# so use a substring-containment trigger instead to keep the predicate robust:
# title "Geoffrey Hinton" contains alias "Geoffrey" of the other? No. Use the
# substring rule directly: page B aliases include "Geoff Hinton" (substring of
# "Geoffrey Hinton"? no). Cleanest deterministic trigger: alias overlap via
# substring -- give page A title "Geoff Hinton" and page B an alias "Geoff
# Hinton Sr" so "geoff hinton" (len 12 > 5) is a substring of "geoff hinton sr".
cat > "$WIKI/entities/geoff-hinton.md" <<'PA'
---
id: geoff-hinton
title: "Geoff Hinton"
type: entity
status: active
summary: "Deep learning researcher (variant A)."
created_at: 2026-06-02
updated_at: 2026-06-02
sources: []
epistemic_status: sourced
tags: [ai]
domains: [ai]
supersedes:
superseded_by:
privacy: cloud_safe
aliases: []
has_contradictions: false
knowledge_domain: science
example: false
---
# Geoff Hinton
Body.
PA

cat > "$WIKI/entities/geoffrey-hinton.md" <<'PB'
---
id: geoffrey-hinton
title: "Geoffrey Hinton Sr"
type: entity
status: active
summary: "Deep learning researcher (variant B)."
created_at: 2026-06-02
updated_at: 2026-06-02
sources: []
epistemic_status: sourced
tags: [ai]
domains: [ai]
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - Geoff Hinton Sr
has_contradictions: false
knowledge_domain: science
example: false
---
# Geoffrey Hinton Sr
Body. References [[Geoffrey Hinton Sr]] context (self-link ignored).
PB

# Give geoffrey-hinton MORE inbound links so it is the deterministic survivor.
mkdir -p "$WIKI/concepts"
cat > "$WIKI/concepts/backprop.md" <<'PC'
---
id: backprop
title: "Backpropagation"
type: concept
status: active
summary: "Training algorithm."
created_at: 2026-06-02
updated_at: 2026-06-02
sources: []
epistemic_status: sourced
tags: [ai]
domains: [ai]
supersedes:
superseded_by:
privacy: cloud_safe
aliases: []
has_contradictions: false
knowledge_domain: science
example: false
---
# Backpropagation
Co-invented by [[Geoffrey Hinton Sr]] and discussed alongside [[Geoff Hinton]].
PC
cat > "$WIKI/concepts/dropout.md" <<'PD'
---
id: dropout
title: "Dropout"
type: concept
status: active
summary: "Regularization technique."
created_at: 2026-06-02
updated_at: 2026-06-02
sources: []
epistemic_status: sourced
tags: [ai]
domains: [ai]
supersedes:
superseded_by:
privacy: cloud_safe
aliases: []
has_contradictions: false
knowledge_domain: science
example: false
---
# Dropout
Introduced by [[Geoffrey Hinton Sr]].
PD

# --- Negative fixture: two genuinely distinct same-type pages ---
cat > "$WIKI/entities/openai.md" <<'PE'
---
id: openai
title: "OpenAI"
type: entity
status: active
summary: "AI lab."
created_at: 2026-06-02
updated_at: 2026-06-02
sources: []
epistemic_status: sourced
tags: [ai]
domains: [ai]
supersedes:
superseded_by:
privacy: cloud_safe
aliases: []
has_contradictions: false
knowledge_domain: science
example: false
---
# OpenAI
Body.
PE
cat > "$WIKI/entities/deepmind.md" <<'PF'
---
id: deepmind
title: "DeepMind"
type: entity
status: active
summary: "AI lab."
created_at: 2026-06-02
updated_at: 2026-06-02
sources: []
epistemic_status: sourced
tags: [ai]
domains: [ai]
supersedes:
superseded_by:
privacy: cloud_safe
aliases: []
has_contradictions: false
knowledge_domain: science
example: false
---
# DeepMind
Body.
PF

# --- Exclusion fixtures: example:true and archived near-dupes must NOT fire ---
cat > "$WIKI/entities/openai-example.md" <<'PG'
---
id: openai-example
title: "OpenAI Labs"
type: entity
status: active
summary: "Reference-only example near-dup of OpenAI."
created_at: 2026-06-02
updated_at: 2026-06-02
sources: []
epistemic_status: sourced
tags: [ai]
domains: [ai]
supersedes:
superseded_by:
privacy: cloud_safe
aliases: []
has_contradictions: false
knowledge_domain: science
example: true
---
# OpenAI Labs
Body.
PG
cat > "$WIKI/entities/deepmind-old.md" <<'PH'
---
id: deepmind-old
title: "DeepMind Research"
type: entity
status: archived
summary: "Archived near-dup of DeepMind."
created_at: 2026-06-02
updated_at: 2026-06-02
sources: []
epistemic_status: sourced
tags: [ai]
domains: [ai]
supersedes:
superseded_by:
privacy: cloud_safe
aliases: []
has_contradictions: false
knowledge_domain: science
example: false
---
# DeepMind Research
Body.
PH

# ---------------------------------------------------------------------------
# Run the duplicate check and assert.
# ---------------------------------------------------------------------------
EXIT=0
invoke_tool_compat lint --category duplicate --format json "$WIKI" \
    > "$TMP/out.json" 2>/dev/null || EXIT=$?
if [ "$EXIT" -ne 0 ]; then
    echo "FAIL: lint --category duplicate exited $EXIT (expected 0, report-only)" >&2
    exit 1
fi

WIKI="$WIKI" python3 - "$TMP/out.json" <<'PYEOF'
import json, os, sys
data = json.load(open(sys.argv[1]))

dups = [d for d in data if d['category'] == 'duplicate']

# 1. Positive: exactly one duplicate finding for the geoff/geoffrey pair.
geoff = [d for d in dups
         if 'geoff-hinton' in d['path'] or 'geoffrey-hinton' in d['path']]
assert len(geoff) == 1, f"FAIL: expected exactly 1 geoff/geoffrey duplicate finding, got {len(geoff)}: {geoff}"
f = geoff[0]
assert f['severity'] == 'warning', f"FAIL: expected severity warning, got {f['severity']}"

# Survivor = geoffrey-hinton (2 inbound: backprop, dropout) vs geoff-hinton
# (1 inbound: backprop). Loser path is geoff-hinton; survivor named in message.
assert 'geoff-hinton.md' in f['path'], f"FAIL: loser should be geoff-hinton (fewer inbound), got path {f['path']}"
assert 'geoffrey-hinton' in f['message'], f"FAIL: survivor geoffrey-hinton should be named in message: {f['message']}"
assert 'same type=entity' in f['message'], f"FAIL: message should note same type=entity: {f['message']}"
print("PASS: positive -- one finding, geoffrey-hinton survives (higher inbound)")

# 2. Negative: no finding pairing the distinct openai/deepmind pages.
distinct = [d for d in dups
            if ('openai.md' in d['path'] and 'openai-example' not in d['path'])
            or ('deepmind.md' in d['path'])]
# These distinct entities share no substring/levenshtein-<3 trigger between
# OpenAI and DeepMind, so neither should appear as a duplicate finding.
bad = [d for d in distinct
       if 'openai' in d['message'].lower() or 'deepmind' in d['message'].lower()]
assert not bad, f"FAIL: distinct pages flagged as duplicates: {bad}"
print("PASS: negative -- distinct same-type pages produce no duplicate finding")

# 3. Exclusion: example:true and archived near-dupes never appear.
excluded = [d for d in dups
            if 'openai-example' in d['path'] or 'deepmind-old' in d['path']
            or 'openai labs' in d['message'].lower()
            or 'deepmind research' in d['message'].lower()]
assert not excluded, f"FAIL: example/archived pages flagged: {excluded}"
print("PASS: exclusion -- example:true and archived pages excluded")
PYEOF

echo "PASS: test_lint_duplicate (positive + negative + exclusion)"
