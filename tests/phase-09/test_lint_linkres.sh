#!/usr/bin/env bash
# test_lint_linkres.sh -- 11 cases covering LINK-04, LINK-05, LINK-06 (D-01 to D-06)
# Self-contained: builds its own temp wiki inline. No git needed.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

TMP="$(mktemp -d -t lint-linkres-XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

WIKI="$TMP/wiki"
mkdir -p "$WIKI" "$WIKI/concepts" "$WIKI/entities" "$WIKI/sources"

# ---------------------------------------------------------------------------
# Fixture pages (PINNED -- do NOT improvise per plan spec)
# ---------------------------------------------------------------------------

# Page A: my-concept.md -- title-unreachable (aliases empty, stem 'my-concept' != title 'My Concept')
# Used in: Tests 1, 2, 6, 8, 10
cat > "$WIKI/concepts/my-concept.md" <<'EOF'
---
id: my-concept
title: "My Concept"
type: concept
status: active
summary: "A test concept page."
created_at: 2026-06-02
updated_at: 2026-06-02
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
---
# My Concept
Body text.
EOF

# Page B: hack-agentive-stack.md -- SELF-ALIASED so subcheck A is silent for B.
# Title has parens; the alias covers exact title. Body links test parens-stripping.
# Used in: Test 3 (linker page has [[Hack Agentive Stack]] -- no parens)
cat > "$WIKI/entities/hack-agentive-stack.md" <<'EOF'
---
id: hack-agentive-stack
title: "Hack (Agentive Stack)"
type: entity
status: active
summary: "A page with parens in title."
created_at: 2026-06-02
updated_at: 2026-06-02
sources: []
epistemic_status: sourced
tags: [test]
domains: [test]
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - "Hack (Agentive Stack)"
  - "hack-agentive-stack"
has_contradictions: false
knowledge_domain: science
example: false
---
# Hack (Agentive Stack)
Body text.
EOF

# Page C: ctx-one.md -- SELF-ALIASED. Title "Bounded Contexts" (plural).
# Used in: Test 4 (multi-match warning)
cat > "$WIKI/concepts/ctx-one.md" <<'EOF'
---
id: ctx-one
title: "Bounded Contexts"
type: concept
status: active
summary: "Bounded contexts concept."
created_at: 2026-06-02
updated_at: 2026-06-02
sources: []
epistemic_status: sourced
tags: [test]
domains: [test]
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - "Bounded Contexts"
  - "ctx-one"
has_contradictions: false
knowledge_domain: science
example: false
---
# Bounded Contexts
Body text.
EOF

# Page D: ctx-two.md -- SELF-ALIASED. Title "Bounded Context" (singular).
# Used in: Test 4 (multi-match warning)
# normalize_link("Bounded Contexts") -> "bounded context" (contexts->context in plural map)
# normalize_link("Bounded Context") -> "bounded context"
# Both normalize to same string -> multi-match when linked via [[bounded-context]]
cat > "$WIKI/concepts/ctx-two.md" <<'EOF'
---
id: ctx-two
title: "Bounded Context"
type: concept
status: active
summary: "Bounded context (singular) concept."
created_at: 2026-06-02
updated_at: 2026-06-02
sources: []
epistemic_status: sourced
tags: [test]
domains: [test]
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - "Bounded Context"
  - "ctx-two"
has_contradictions: false
knowledge_domain: science
example: false
---
# Bounded Context
Body text.
EOF

# Page E: linker.md -- SELF-ALIASED. Has body links for multiple tests.
# [[My Concept]] -> Test 8 (orphan), Test 10 (index/log scan, resolves after --fix)
# [[Hack Agentive Stack]] -> Test 3 (parens stripped, unique match)
# [[Completely Unknown Page]] -> Test 5 (no match, stays gap)
# [[bounded-context]] -> Test 4 (multi-match warning, not an exact stem/alias of either ctx page)
cat > "$WIKI/concepts/linker.md" <<'EOF'
---
id: linker
title: "Linker"
type: concept
status: active
summary: "A linker page for testing."
created_at: 2026-06-02
updated_at: 2026-06-02
sources: []
epistemic_status: sourced
tags: [test]
domains: [test]
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - "Linker"
  - "linker"
has_contradictions: false
knowledge_domain: science
example: false
---
# Linker
References [[My Concept]] for the main concept.
See also [[Hack Agentive Stack]] for an example.
Does not know about [[Completely Unknown Page]].
Related to [[bounded-context]] domain work.
EOF

# Page F: topic-subtitle.md -- colon-space title, empty aliases.
# Tests that --fix YAML-double-quotes the alias (HIGH BUG #2 canary).
cat > "$WIKI/concepts/topic-subtitle.md" <<'EOF'
---
id: topic-subtitle
title: "Topic: Subtitle"
type: concept
status: active
summary: "Page with colon in title."
created_at: 2026-06-02
updated_at: 2026-06-02
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
---
# Topic: Subtitle
Body text.
EOF

# Page G: provenance-page.md -- SELF-ALIASED, full base frontmatter, has [prov:] marker.
# Used in: Test 7 (--strict green)
cat > "$WIKI/entities/provenance-page.md" <<'EOF'
---
id: provenance-page
title: "Provenance Page"
type: entity
status: active
summary: "A properly formed entity page with provenance."
created_at: 2026-06-02
updated_at: 2026-06-02
sources:
  - src-test-01
epistemic_status: sourced
tags: [test]
domains: [test]
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - "Provenance Page"
  - "provenance-page"
has_contradictions: false
knowledge_domain: science
example: false
---
# Provenance Page
This page has provenance [prov:src-test-01#sec:intro|direct|2026-06-02].
EOF

# Source summary page for Test 7 provenance reference
cat > "$WIKI/sources/src-test-01.md" <<'EOF'
---
id: src-test-01
title: "Source Test 01"
type: source
status: active
summary: "Minimal source summary for testing."
created_at: 2026-06-02
updated_at: 2026-06-02
sources: []
epistemic_status: sourced
tags: [test]
domains: [test]
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - "Source Test 01"
  - "src-test-01"
has_contradictions: false
knowledge_domain: science
path: sources/2026/2026-06/2026-06-02-test-source.md
url: ""
content_hash: "sha256:abc123"
ingested_at: 2026-06-02
source_type: article
compilation_status: compiled
compiled_against_hash: "sha256:abc123"
compiled_targets: []
example: false
---
# Source Test 01
## TL;DR
Test source.
## Key Takeaways
- Test takeaway.
## Extracted Claims
- Test claim.
## Source Metadata
Published: 2026-06-02
EOF

# Page H: lit-concept.md -- id == filename stem, title IS a literal alias, id slug is NOT.
# Obsidian would resolve 'lit-concept' by stem, but the literal id alias is absent.
# Used in: Test 9c (literal-membership CI-enforcement canary)
# MUST produce a linkres error PRE-FIX because id slug is missing from aliases.
cat > "$WIKI/concepts/lit-concept.md" <<'EOF'
---
id: lit-concept
title: "Lit Concept"
type: concept
status: active
summary: "Page where title is a literal alias but id slug is not."
created_at: 2026-06-02
updated_at: 2026-06-02
sources: []
epistemic_status: sourced
tags: [test]
domains: [test]
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - "Lit Concept"
has_contradictions: false
knowledge_domain: science
example: false
---
# Lit Concept
Body text.
EOF

# Index and log stubs with [[My Concept]] body links (Test 10).
# Before --fix, [[My Concept]] is unresolved (Page A has empty aliases,
# so obsidian_map has 'my-concept' as the stem key but NOT 'my concept').
printf '# Index\n\n- [[My Concept]] -- the canonical concept\n' > "$WIKI/index.md"
printf '# Log\n\n## [2026-06-02] note\n\nSee [[My Concept]] for details.\n' > "$WIKI/log.md"

# ---------------------------------------------------------------------------
# Capture PRE-FIX JSON (tests 1, 3, 4, 5, 9c, 10 run against this)
# ---------------------------------------------------------------------------
bash "$REPO_ROOT/bin/lint.sh" --category linkres --format json "$WIKI" \
    > "$TMP/pre-fix.json" 2>/dev/null; PRE_EXIT=$?

# ---------------------------------------------------------------------------
# Tests 1, 3, 4, 5, 9c, 10 -- run on PRE-FIX output
# ---------------------------------------------------------------------------
python3 - "$TMP/pre-fix.json" <<'PYEOF'
import json, sys
data = json.load(open(sys.argv[1]))
lr = [d for d in data if d['category'] == 'linkres']

# --- Test 1: title-unreachable errors ---
# Pages with empty aliases AND title != filename stem should produce errors.
# My Concept: id=my-concept, title='My Concept', aliases=[] -> error
# Topic: Subtitle: id=topic-subtitle, title='Topic: Subtitle', aliases=[] -> errors (title + maybe id)
# lit-concept: id=lit-concept, title='Lit Concept', aliases=['Lit Concept'] -> only id error (title covered)
title_errs = [d for d in lr if d['severity'] == 'error']
assert len(title_errs) >= 2, (
    f"FAIL T1: expected >=2 title-unreachable errors, got {len(title_errs)}. "
    f"All linkres findings: {[(d['severity'],d['path'],d['message'][:60]) for d in lr]}"
)
print("PASS T1: title-unreachable errors detected (>=2 error findings)")

# --- Test 3: parens-litmus via REAL lint output ---
# [[Hack Agentive Stack]] (no parens) in linker.md body.
# normalize_link('Hack Agentive Stack') -> 'hack agentive stack'
# normalize_link('Hack (Agentive Stack)') -> 'hack  agentive stack' -> 'hack agentive stack' (punct->space, collapse)
# So 'hack agentive stack' should uniquely match hack-agentive-stack.
t3 = [d for d in lr if d['severity'] == 'error'
      and 'hack-agentive-stack' in d['message']
      and '[[Hack Agentive Stack]]' in d['message']]
assert len(t3) == 1, (
    f"FAIL T3: expected 1 error citing hack-agentive-stack for [[Hack Agentive Stack]], "
    f"got {[d['message'] for d in lr]}"
)
print("PASS T3: parens stripped as CHARACTERS -- [[Hack Agentive Stack]] uniquely matched hack-agentive-stack via real lint output")

# --- Test 4: multi-match warning (pinned fixture) ---
# [[bounded-context]] in linker.md: hyphen variant not an exact stem/alias of ctx-one or ctx-two.
# normalize_link('bounded-context') -> 'bounded context'
# normalize_link('Bounded Contexts') -> 'bounded context' (plural map)
# normalize_link('Bounded Context') -> 'bounded context'
# Matches BOTH ctx-one and ctx-two -> one WARNING, not error.
t4 = [d for d in lr if d['severity'] == 'warning'
      and 'ctx-one' in d['message'] and 'ctx-two' in d['message']]
assert len(t4) == 1, (
    f"FAIL T4: expected 1 multi-match warning listing ctx-one+ctx-two for [[bounded-context]], "
    f"got {[d['message'] for d in lr if d['severity'] == 'warning']}"
)
# Self-aliased ctx pages should not emit subcheck-A errors
ctx_errs = [d for d in lr if d['severity'] == 'error'
            and ('ctx-one' in d['path'] or 'ctx-two' in d['path'])]
assert not ctx_errs, (
    f"FAIL T4: self-aliased ctx pages should emit no subcheck-A errors, got {ctx_errs}"
)
print("PASS T4: [[bounded-context]] variant produced exactly one multi-match WARNING (not error)")

# --- Test 5: no-match stays in gap (zero linkres findings for unknown page) ---
# [[Completely Unknown Page]] has no normalized match -> zero linkres findings for it
unknown_findings = [d for d in lr
                    if 'Completely Unknown Page' in d['message']]
assert len(unknown_findings) == 0, (
    f"FAIL T5: [[Completely Unknown Page]] should produce 0 linkres findings "
    f"(no-match stays in gap), got {unknown_findings}"
)
print("PASS T5: [[Completely Unknown Page]] produces zero linkres findings (stays in gap)")

# --- Test 9c: literal LINK-02 id-alias membership is CI-ENFORCED ---
# lit-concept.md: id=lit-concept == filename stem (Obsidian resolves by stem),
# but the literal id alias 'lit-concept' is absent from aliases list.
# Under stem-reachable gating this page would pass CI clean.
# Under literal-membership gating it MUST be a linkres error.
t9c = [d for d in lr if d['severity'] == 'error'
       and d['path'].endswith('lit-concept.md')
       and 'lit-concept' in d['message']
       and ('literal member of aliases' in d['message'] or 'literal id alias' in d['message']
            or 'LINK-02' in d['message'] or 'literal' in d['message'])]
assert len(t9c) == 1, (
    f"FAIL T9c: expected 1 literal-membership error for lit-concept "
    f"(id slug missing though stem-reachable), "
    f"got {[(d['path'], d['message']) for d in lr]}"
)
print("PASS T9c: literal LINK-02 id-alias membership is CI-ENFORCED (stem-reachable is not sufficient)")

# --- Test 10: index.md and log.md body links are scanned ---
# Before --fix, [[My Concept]] in index.md/log.md is unresolved (Page A aliases=[]).
# obsidian_map has key 'my-concept' (stem) but NOT 'my concept' or 'My Concept'.
# normalize_link('My Concept') -> 'my concept' -> uniquely matches my-concept in norm_map.
# -> Should produce linkres errors for both index.md and log.md.
idx = [d for d in lr if d['path'].endswith('index.md') and 'My Concept' in d['message']]
log = [d for d in lr if d['path'].endswith('log.md') and 'My Concept' in d['message']]
assert len(idx) == 1, (
    f"FAIL T10: expected 1 linkres finding citing [[My Concept]] in index.md, "
    f"got {[(d['path'], d['message']) for d in lr]}"
)
assert len(log) == 1, (
    f"FAIL T10: expected 1 linkres finding citing [[My Concept]] in log.md, "
    f"got {[(d['path'], d['message']) for d in lr]}"
)
print("PASS T10: index.md and log.md body links are scanned by linkres (broken links there cannot evade LINK-05)")
PYEOF

# ---------------------------------------------------------------------------
# Run --fix on the wiki
# ---------------------------------------------------------------------------
bash "$REPO_ROOT/bin/lint.sh" --fix --category linkres "$WIKI" > /dev/null 2>/dev/null || true

# ---------------------------------------------------------------------------
# Capture POST-FIX JSON
# ---------------------------------------------------------------------------
bash "$REPO_ROOT/bin/lint.sh" --category linkres --format json "$WIKI" \
    > "$TMP/post-fix.json" 2>/dev/null || true

# ---------------------------------------------------------------------------
# Tests 2, 6, 9, 9b -- run after --fix
# ---------------------------------------------------------------------------

# --- Test 2: after --fix, no more linkres errors for page A ---
python3 - "$TMP/post-fix.json" <<'PYEOF'
import json, sys
data = json.load(open(sys.argv[1]))
lr = [d for d in data if d['category'] == 'linkres']

# Page A (my-concept.md) should have no linkres errors after --fix
my_concept_errs = [d for d in lr if d['severity'] == 'error'
                   and 'my-concept' in d['path']]
assert len(my_concept_errs) == 0, (
    f"FAIL T2: expected 0 linkres errors for my-concept.md after --fix, "
    f"got {my_concept_errs}"
)
print("PASS T2: after --fix, my-concept.md produces 0 linkres errors (alias backfilled)")
PYEOF

# --- Test 9: colon-title YAML-quoting (CONFIRMED HIGH BUG #2 canary) ---
python3 - "$WIKI/concepts/topic-subtitle.md" <<'PYEOF'
import yaml, sys
fm = next(yaml.safe_load_all(open(sys.argv[1])))
aliases = fm.get('aliases') or []
# The title must be present as a STRING, never parsed into a dict {'Topic': 'Subtitle'}.
assert all(isinstance(a, str) for a in aliases), (
    f"FAIL T9: alias parsed as non-string (colon corrupted YAML): {aliases}"
)
assert 'Topic: Subtitle' in aliases, (
    f"FAIL T9: quoted title alias missing/corrupted: {aliases}"
)
print("PASS T9: colon-title alias emitted YAML-quoted, re-parses as a string")
PYEOF

# --- Test 9b: LITERAL id-slug membership (CONFIRMED HIGH BUG #3 canary, Cycle-2) ---
python3 - "$WIKI/concepts/my-concept.md" <<'PYEOF'
import yaml, sys
fm = next(yaml.safe_load_all(open(sys.argv[1])))
aliases = [str(a) for a in (fm.get('aliases') or [])]
# id 'my-concept' == filename stem (stem-reachable), but LINK-02 mandates LITERAL membership.
# A reachability-based to_add would add only the title and SKIP the id.
assert 'My Concept' in aliases, f"FAIL T9b: title alias missing: {aliases}"
assert 'my-concept' in aliases, (
    f"FAIL T9b: id-slug alias missing "
    f"(reachability regression -- to_add must use literal membership, not stem-inclusive reachable): "
    f"{aliases}"
)
print("PASS T9b: --fix added BOTH literal title 'My Concept' AND id slug 'my-concept' (LINK-02 literal invariant)")
PYEOF

# --- Test 6: --fix idempotency ---
# Capture sha256 of topic-subtitle.md before second --fix run
SHA_BEFORE=$(python3 -c "import hashlib; print(hashlib.sha256(open('$WIKI/concepts/topic-subtitle.md','rb').read()).hexdigest())")
# Run --fix a second time
bash "$REPO_ROOT/bin/lint.sh" --fix --category linkres "$WIKI" > /dev/null 2>/dev/null || true
# Capture sha256 after second --fix run
SHA_AFTER=$(python3 -c "import hashlib; print(hashlib.sha256(open('$WIKI/concepts/topic-subtitle.md','rb').read()).hexdigest())")
if [ "$SHA_BEFORE" = "$SHA_AFTER" ]; then
    echo "PASS T6: --fix is idempotent (second run produces byte-identical file)"
else
    echo "FAIL T6: --fix is NOT idempotent (file changed on second run)" >&2
    exit 1
fi

# Also confirm second --fix run emits no new autofix findings for the already-fixed pages
bash "$REPO_ROOT/bin/lint.sh" --fix --category linkres --format json "$WIKI" \
    > "$TMP/second-fix.json" 2>/dev/null || true
python3 - "$TMP/second-fix.json" <<'PYEOF'
import json, sys
data = json.load(open(sys.argv[1]))
# After second --fix, no more autofix findings for already-fixed pages
# (my-concept and topic-subtitle should not be in autofix findings)
autofix = [d for d in data if d['category'] == 'autofix'
           and ('my-concept' in d['path'] or 'topic-subtitle' in d['path'])]
assert len(autofix) == 0, (
    f"FAIL T6b: second --fix run still produced autofix findings for already-fixed pages: {autofix}"
)
print("PASS T6b: second --fix run produces no new autofix findings for already-fixed pages")
PYEOF

# ---------------------------------------------------------------------------
# Test 7: --strict stays green for a properly-formed self-aliased page
# ---------------------------------------------------------------------------
# Create a fresh isolated wiki with just the provenance page + its source summary
STRICT_WIKI="$TMP/strict-wiki"
mkdir -p "$STRICT_WIKI/entities" "$STRICT_WIKI/sources"
cat > "$STRICT_WIKI/index.md" <<'EOF'
# Index
EOF
cat > "$STRICT_WIKI/log.md" <<'EOF'
# Log
EOF

cat > "$STRICT_WIKI/entities/provenance-page.md" <<'EOF'
---
id: provenance-page
title: "Provenance Page"
type: entity
status: active
summary: "A properly formed entity page with provenance."
created_at: 2026-06-02
updated_at: 2026-06-02
sources:
  - src-test-01
epistemic_status: sourced
tags: [test]
domains: [test]
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - "Provenance Page"
  - "provenance-page"
has_contradictions: false
knowledge_domain: science
example: false
---
# Provenance Page
This page has provenance [prov:src-test-01#sec:intro|direct|2026-06-02].
EOF

cat > "$STRICT_WIKI/sources/src-test-01.md" <<'EOF'
---
id: src-test-01
title: "Source Test 01"
type: source
status: active
summary: "Minimal source summary for testing."
created_at: 2026-06-02
updated_at: 2026-06-02
sources: []
epistemic_status: sourced
tags: [test]
domains: [test]
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - "Source Test 01"
  - "src-test-01"
has_contradictions: false
knowledge_domain: science
path: sources/2026/2026-06/2026-06-02-test-source.md
url: ""
content_hash: "sha256:abc123"
ingested_at: 2026-06-02
source_type: article
compilation_status: compiled
compiled_against_hash: "sha256:abc123"
compiled_targets: []
example: false
---
# Source Test 01
Test source.
EOF

# --strict scopes via git diff which is not available here; test --category linkres specifically
# A properly self-aliased page with provenance should produce zero linkres errors
bash "$REPO_ROOT/bin/lint.sh" --category linkres --format json "$STRICT_WIKI" \
    > "$TMP/strict-out.json" 2>/dev/null || true
python3 - "$TMP/strict-out.json" <<'PYEOF'
import json, sys
data = json.load(open(sys.argv[1]))
lr = [d for d in data if d['category'] == 'linkres' and d['severity'] == 'error']
assert len(lr) == 0, (
    f"FAIL T7: expected 0 linkres errors for a properly self-aliased page, got {lr}"
)
print("PASS T7: properly self-aliased page with [prov:] markers produces 0 linkres errors")
PYEOF

# ---------------------------------------------------------------------------
# Test 8: orphan reconciliation (D-03)
# ---------------------------------------------------------------------------
# After --fix on the main wiki, Page A 'my-concept' has aliases ['My Concept', 'my-concept'].
# The linker page has [[My Concept]] which should now resolve via the new alias.
# So my-concept should no longer be an orphan.
# Count orphan findings before and after fix (use a fresh wiki for the before state).
ORPHAN_WIKI="$TMP/orphan-wiki"
mkdir -p "$ORPHAN_WIKI/concepts"
cat > "$ORPHAN_WIKI/index.md" <<'EOF'
# Index
EOF
cat > "$ORPHAN_WIKI/log.md" <<'EOF'
# Log
EOF

# Before-fix version of Page A (aliases=[])
cat > "$ORPHAN_WIKI/concepts/my-concept.md" <<'EOF'
---
id: my-concept
title: "My Concept"
type: concept
status: active
summary: "A test concept page."
created_at: 2026-06-02
updated_at: 2026-06-02
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
---
# My Concept
Body.
EOF

# Linker that references [[My Concept]]
cat > "$ORPHAN_WIKI/concepts/linker.md" <<'EOF'
---
id: linker
title: "Linker"
type: concept
status: active
summary: "Links to my-concept."
created_at: 2026-06-02
updated_at: 2026-06-02
sources: []
epistemic_status: sourced
tags: [test]
domains: [test]
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - "Linker"
  - "linker"
has_contradictions: false
knowledge_domain: science
example: false
---
# Linker
References [[My Concept]] for details.
EOF

# Before fix: [[My Concept]] doesn't resolve (obsidian uses stem 'my-concept', not title)
# So my-concept should be an orphan
bash "$REPO_ROOT/bin/lint.sh" --category orphan --format json "$ORPHAN_WIKI" \
    > "$TMP/orphan-before.json" 2>/dev/null || true

# Apply --fix to add the title alias
bash "$REPO_ROOT/bin/lint.sh" --fix --category linkres "$ORPHAN_WIKI" > /dev/null 2>/dev/null || true

# After fix: [[My Concept]] now resolves via the new title alias -> my-concept no longer orphan
bash "$REPO_ROOT/bin/lint.sh" --category orphan --format json "$ORPHAN_WIKI" \
    > "$TMP/orphan-after.json" 2>/dev/null || true

python3 - "$TMP/orphan-before.json" "$TMP/orphan-after.json" <<'PYEOF'
import json, sys
before = json.load(open(sys.argv[1]))
after = json.load(open(sys.argv[2]))

before_orphan = [d for d in before if d['category'] == 'orphan' and 'my-concept' in d['path']]
after_orphan = [d for d in after if d['category'] == 'orphan' and 'my-concept' in d['path']]

assert len(before_orphan) >= 1, (
    f"FAIL T8: expected my-concept to be an orphan BEFORE --fix "
    f"(orphan check uses stem resolution, not title), "
    f"got {before_orphan}. This may indicate the orphan check still resolves by title (D-03 regression)."
)
assert len(after_orphan) == 0, (
    f"FAIL T8: expected 0 orphan findings for my-concept AFTER --fix added title alias, "
    f"got {after_orphan}"
)
print("PASS T8: orphan count for my-concept decreases after --fix adds title alias (D-03: orphan uses stem+alias resolution)")
PYEOF

echo "PASS: test_lint_linkres -- all 11 test cases passed"
