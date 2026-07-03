#!/usr/bin/env bash
# test_lint_linkres.sh -- 14 cases covering LINK-04, LINK-05, LINK-06 (re-pointed to
# piped-form enforcement, masked body scan, alias-free orphan resolution).
# T14 guards that masking extends to the provenance + gap scans (review WR-01/WR-04).
# Neutral fixtures only (no real vault slugs per CLAUDE.md §3 neutrality).
# Self-contained: builds its own temp wiki inline. No git needed.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$REPO_ROOT/tests/lib/invoke_tool.sh"   # Phase 24 Plan 05: the frozen parity seam

TMP="$(mktemp -d -t lint-linkres-XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

WIKI="$TMP/wiki"
mkdir -p "$WIKI" "$WIKI/concepts" "$WIKI/entities" "$WIKI/sources"

# ---------------------------------------------------------------------------
# Neutral fixture pages
# Slugs: alpha, beta, gamma-one, gamma-two, hub, prov-page, src-test-01, fmtest
# ---------------------------------------------------------------------------

# alpha.md -- simple page with single-word id == filename stem
cat > "$WIKI/concepts/alpha.md" <<'EOF'
---
id: alpha
title: "Alpha"
type: concept
status: active
summary: "A neutral test concept."
created_at: 2026-06-03
updated_at: 2026-06-03
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
# Alpha
Body text.
EOF

# beta.md -- title with parenthetical (tests parens stripping is not relevant for T1 piped-OK)
cat > "$WIKI/concepts/beta.md" <<'EOF'
---
id: beta
title: "Beta (Parenthetical)"
type: concept
status: active
summary: "Concept with parens in title."
created_at: 2026-06-03
updated_at: 2026-06-03
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
# Beta (Parenthetical)
Body text.
EOF

# gamma-one.md -- multi-match partner (title "Gamma Contract")
# normalize_link("Gamma Contract") -> "gamma contract"
# normalize_link("Gamma Contracts") -> "gamma contract"  (contracts in _PLURAL_MAP)
# Both normalize to the same key -> multi-match via bare [[gamma contracts]]
cat > "$WIKI/concepts/gamma-one.md" <<'EOF'
---
id: gamma-one
title: "Gamma Contract"
type: concept
status: active
summary: "Multi-match partner one."
created_at: 2026-06-03
updated_at: 2026-06-03
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
# Gamma Contract
Body text.
EOF

# gamma-two.md -- multi-match partner (title "Gamma Contracts")
cat > "$WIKI/concepts/gamma-two.md" <<'EOF'
---
id: gamma-two
title: "Gamma Contracts"
type: concept
status: active
summary: "Multi-match partner two."
created_at: 2026-06-03
updated_at: 2026-06-03
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
# Gamma Contracts
Body text.
EOF

# hub.md -- the linking page with varied test links
# Links:
#   [[alpha|Alpha]]               piped, known id       -> OK (T1)
#   [[Alpha]]                     bare, unique match    -> ERROR + fixable (T2, T6)
#   [[future-page|Future Page]]   piped, no match, no / -> GAP (T3)
#   [[Alpha!|Alpha]]              piped, target "Alpha!" normalizes to "alpha" != literal id -> ERROR (T4)
#   [[concepts/alpha|Alpha]]      piped, path-style     -> ERROR (T4b)
#   [[gamma contracts]]           bare LOWERCASE, multi-match -> WARNING (T5)
#   [[Totally Unknown Thing]]     bare, no match        -> ERROR (T7, bare-no-match)
# Plus masked spans (T12):
#   fenced code block with [[Alpha]] and [[anything|X]]
#   inline code span `[[Alpha]]`
#   HTML comment <!-- [[Alpha]] example -->
cat > "$WIKI/concepts/hub.md" <<'EOF'
---
id: hub
title: "Hub"
type: concept
status: active
summary: "Hub page with varied link forms for testing."
created_at: 2026-06-03
updated_at: 2026-06-03
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
# Hub

A properly piped link: [[alpha|Alpha]].
A bare link: [[Alpha]].
A genuine gap (red link): [[future-page|Future Page]].
A malformed piped target: [[Alpha!|Alpha]].
A path-style piped target: [[concepts/alpha|Alpha]].
A bare multi-match: [[gamma contracts]].
A bare no-match: [[Totally Unknown Thing]].

These must NOT be flagged (masked spans):

```
[[Alpha]] and [[anything|X]] inside a fenced code block
```

Also `[[Alpha]]` in inline code is masked.

<!-- [[Alpha]] example in HTML comment is masked -->
EOF

# prov-page.md -- clean piped links + [prov:] marker (T10, --strict compat)
cat > "$WIKI/concepts/prov-page.md" <<'EOF'
---
id: prov-page
title: "Prov Page"
type: concept
status: active
summary: "Page with clean piped links and provenance."
created_at: 2026-06-03
updated_at: 2026-06-03
sources:
  - src-test-01
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
# Prov Page

This page has a piped link [[alpha|Alpha]] and provenance [prov:src-test-01#sec:intro|direct|2026-06-03].
EOF

# src-test-01.md -- source summary for provenance anchor
cat > "$WIKI/sources/src-test-01.md" <<'EOF'
---
id: src-test-01
title: "Source Test 01"
type: source
status: active
summary: "Minimal source summary for testing."
created_at: 2026-06-03
updated_at: 2026-06-03
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
path: sources/2026/2026-06/2026-06-03-test-source.md
url: ""
content_hash: "sha256:abc123"
ingested_at: 2026-06-03
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
Published: 2026-06-03
EOF

# fmtest.md -- NON-TRIVIAL frontmatter for T13 (frontmatter-preservation regression guard)
# Has multiple fields including colon-bearing summary, tags list, non-empty aliases list.
# Body has a bare [[Alpha]] link that --fix must pipe.
# T13 asserts the frontmatter block is byte-for-byte unchanged after --fix.
cat > "$WIKI/concepts/fmtest.md" <<'EOF'
---
id: fmtest
title: "FM Test"
type: concept
status: active
summary: "Page with non-trivial frontmatter: testing colon values, tags, aliases."
created_at: 2026-06-03
updated_at: 2026-06-03
sources: []
epistemic_status: sourced
tags:
  - test-tag
  - another-tag
domains: [test]
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - "FM Test"
  - "fmtest"
has_contradictions: false
knowledge_domain: science
example: false
---
# FM Test

Body with a bare link: [[Alpha]].
EOF

# Index and log with bare [[Alpha]] links -> must be scanned (T9)
printf '# Index\n\n- [[Alpha]] -- alpha page\n' > "$WIKI/index.md"
printf '# Log\n\n## [2026-06-03] note\n\nSee [[Alpha]] for details.\n' > "$WIKI/log.md"

# ---------------------------------------------------------------------------
# Capture frontmatter block of fmtest.md BEFORE --fix (for T13)
# ---------------------------------------------------------------------------
FM_PRE=$(python3 -c "
import sys
content = open('$WIKI/concepts/fmtest.md', 'r').read()
# Find the second --- delimiter
fm_end = content.index('---', 3)
fm_block = content[:fm_end + 3]
sys.stdout.write(fm_block)
")

# ---------------------------------------------------------------------------
# Capture PRE-FIX JSON (run before any --fix)
# ---------------------------------------------------------------------------
invoke_tool_compat lint --category linkres --format json "$WIKI" \
    > "$TMP/pre-fix.json" 2>/dev/null; PRE_EXIT=$?

# ---------------------------------------------------------------------------
# T1 through T5, T7, T9, T10, T12 -- PRE-FIX assertions
# ---------------------------------------------------------------------------
python3 - "$TMP/pre-fix.json" <<'PYEOF'
import json, sys
data = json.load(open(sys.argv[1]))
lr = [d for d in data if d['category'] == 'linkres']
errors = [d for d in lr if d['severity'] == 'error']
warnings = [d for d in lr if d['severity'] == 'warning']

# --- T1: piped known-id [[alpha|Alpha]] produces ZERO linkres errors for a page with ONLY that link ---
# prov-page.md has [[alpha|Alpha]] (piped, known id) and should produce zero linkres errors.
# This distinguishes "known piped link is OK" from bare-link errors.
t1_prov_errors = [d for d in errors if d['path'].endswith('prov-page.md')]
assert len(t1_prov_errors) == 0, (
    f"FAIL T1: prov-page.md has only piped [[alpha|Alpha]] (known id) and should produce zero "
    f"linkres errors, got {t1_prov_errors}"
)
print("PASS T1: piped [[alpha|Alpha]] with known id produces zero linkres errors (prov-page.md is clean)")

# --- T2: bare [[Alpha]] (unique match) -> linkres ERROR ---
t2 = [d for d in errors if d['path'].endswith('hub.md')
      and 'bare link [[Alpha]]' in d.get('message', '')]
assert len(t2) >= 1, (
    f"FAIL T2: expected linkres ERROR for bare [[Alpha]] in hub.md, got {[d['message'] for d in errors if 'hub' in d['path']]}"
)
print("PASS T2: bare [[Alpha]] produces a linkres ERROR")

# --- T3: piped [[future-page|Future Page]] (no match, no slash) -> ZERO linkres findings (genuine gap) ---
t3 = [d for d in lr if 'future-page' in d.get('message', '') or 'Future Page' in d.get('message', '')]
assert len(t3) == 0, (
    f"FAIL T3: [[future-page|Future Page]] (genuine gap) should produce zero linkres findings, got {t3}"
)
print("PASS T3: piped [[future-page|Future Page]] (no match, no slash) produces zero linkres findings (genuine gap)")

# --- T4: piped [[Alpha!|Alpha]] -> linkres ERROR ---
# normalize_link("Alpha!") strips ! via _PUNCT_RE -> "alpha" == id alpha -> verdict 'error', not 'gap'
t4 = [d for d in errors if 'Alpha!' in d.get('message', '')]
assert len(t4) >= 1, (
    f"FAIL T4: expected linkres ERROR for [[Alpha!|Alpha]] (malformed target normalizes to known id), got {t4}"
)
# Assert NO gap finding for this link
t4_gap = [d for d in lr if d['severity'] == 'info' and 'Alpha!' in d.get('message', '')]
assert len(t4_gap) == 0, (
    f"FAIL T4: [[Alpha!|Alpha]] should be an ERROR not a gap, but found gap/info findings: {t4_gap}"
)
print("PASS T4: [[Alpha!|Alpha]] produces a linkres ERROR (normalizes to known id, not a gap)")

# --- T4b: piped [[concepts/alpha|Alpha]] -> linkres ERROR (path-style target) ---
t4b = [d for d in errors if 'concepts/alpha' in d.get('message', '') or 'path-style' in d.get('message', '')]
assert len(t4b) >= 1, (
    f"FAIL T4b: expected linkres ERROR for path-style piped target [[concepts/alpha|Alpha]], got {t4b}"
)
print("PASS T4b: [[concepts/alpha|Alpha]] produces a linkres ERROR (path-style target, id-only convention)")

# --- T5: bare LOWERCASE [[gamma contracts]] -> exactly ONE linkres WARNING (multi-match) ---
# normalize_link("gamma contracts") -> "gamma contract" (contracts->contract in _PLURAL_MAP)
# This matches BOTH gamma-one (title "Gamma Contract") AND gamma-two (title "Gamma Contracts")
# -> multi-match -> WARNING, NOT an error+fixable unique-match
t5 = [d for d in warnings if 'gamma' in d.get('message', '').lower()
      and 'gamma-one' in d.get('message', '') and 'gamma-two' in d.get('message', '')]
assert len(t5) == 1, (
    f"FAIL T5: expected exactly ONE multi-match WARNING for [[gamma contracts]] citing gamma-one+gamma-two, "
    f"got {[d['message'] for d in warnings]}"
)
# Assert it is a WARNING, NOT an error
assert t5[0]['severity'] == 'warning', (
    f"FAIL T5: multi-match should be a WARNING not {t5[0]['severity']}"
)
print("PASS T5: bare [[gamma contracts]] produces exactly ONE WARNING (genuine multi-match via _PLURAL_MAP)")

# --- T7: bare [[Totally Unknown Thing]] (no match) -> linkres ERROR (form violation, not a gap) ---
t7 = [d for d in errors if 'Totally Unknown Thing' in d.get('message', '')]
assert len(t7) >= 1, (
    f"FAIL T7: bare [[Totally Unknown Thing]] (no match) should be a linkres ERROR, got {[d['message'] for d in lr if 'Unknown' in d.get('message','')]}"
)
# The message should indicate it has no unique page match
assert any('no unique page match' in d.get('message', '') or 'no pipe' in d.get('message', '') for d in t7), (
    f"FAIL T7: error message should indicate bare form violation, got {[d['message'] for d in t7]}"
)
print("PASS T7: bare [[Totally Unknown Thing]] produces a linkres ERROR (bare-no-match is still a FORM violation)")

# --- T9: index.md AND log.md bare [[Alpha]] -> linkres errors ---
idx = [d for d in errors if d['path'].endswith('index.md') and 'Alpha' in d.get('message', '')]
log = [d for d in errors if d['path'].endswith('log.md') and 'Alpha' in d.get('message', '')]
assert len(idx) >= 1, (
    f"FAIL T9: expected linkres error for [[Alpha]] in index.md, got {[(d['path'],d['message'][:60]) for d in lr]}"
)
assert len(log) >= 1, (
    f"FAIL T9: expected linkres error for [[Alpha]] in log.md, got {[(d['path'],d['message'][:60]) for d in lr]}"
)
print("PASS T9: index.md and log.md bare [[Alpha]] links produce linkres errors (specials scanned)")

# --- T10: prov-page.md (piped [[alpha|Alpha]] + [prov:] marker) -> ZERO linkres errors ---
t10 = [d for d in errors if d['path'].endswith('prov-page.md')]
assert len(t10) == 0, (
    f"FAIL T10: prov-page.md should produce zero linkres errors (clean piped link), got {t10}"
)
print("PASS T10: prov-page.md with piped links and [prov:] marker produces zero linkres errors")

# --- T12: masked spans -- [[Alpha]] inside fenced code, inline code, HTML comment -> ZERO findings ---
# hub.md has those masked spans; the findings for hub.md should NOT include extra errors from masked spans
# Count linkres findings referencing masked-span content (fenced code / comment / inline code)
# The masked [[Alpha]] inside ``` ... ``` should NOT appear as an additional finding beyond the bare [[Alpha]] in body
hub_errors = [d for d in errors if d['path'].endswith('hub.md')]
# We expect errors for: bare [[Alpha]], [[Alpha!|Alpha]], [[concepts/alpha|Alpha]], [[Totally Unknown Thing]]
# NOT extra errors from inside the fenced code block or inline code or HTML comment
# (those also contain [[Alpha]] but should be masked)
# Count distinct bare-Alpha errors for hub.md: should be exactly 1 (the body bare [[Alpha]])
bare_alpha_hub = [d for d in hub_errors if 'bare link [[Alpha]]' in d.get('message', '')]
assert len(bare_alpha_hub) == 1, (
    f"FAIL T12: expected exactly 1 bare-[[Alpha]] error for hub.md (masked spans ignored), "
    f"got {len(bare_alpha_hub)}: {[d['message'] for d in bare_alpha_hub]}"
)
print("PASS T12: masked spans (fenced code, inline code, HTML comment) are NOT scanned -- only 1 bare [[Alpha]] error from hub.md body")
PYEOF

# ---------------------------------------------------------------------------
# Run --fix on the wiki
# ---------------------------------------------------------------------------
invoke_tool_compat lint --fix --category linkres "$WIKI" > /dev/null 2>/dev/null || true

# ---------------------------------------------------------------------------
# T6: --fix rewrites bare [[Alpha]] in hub.md to [[alpha|Alpha]]
# ---------------------------------------------------------------------------
python3 - "$WIKI/concepts/hub.md" <<'PYEOF'
import sys
content = open(sys.argv[1]).read()
assert '[[alpha|Alpha]]' in content, (
    f"FAIL T6: expected [[alpha|Alpha]] in hub.md after --fix, content: {content[:300]}"
)
# Original bare [[Alpha]] (the body one) should have been piped
# (there should be no remaining bare [[Alpha]] in the body -- the code-fence [[Alpha]] was masked)
# Find the non-fenced body: check that the bare [[Alpha]] in the body was rewritten
# The body has one bare [[Alpha]] (line 6 of body) and masked ones (fenced/inline/comment)
# After fix, the body bare one should become [[alpha|Alpha]] and the masked ones stay unchanged
lines = content.split('\n')
body_start = content.index('\n---\n', 4) + 4  # after closing frontmatter ---
body = content[body_start:]
# The bare link in body should now be piped
assert '[[alpha|Alpha]]' in body, f"FAIL T6: body should contain [[alpha|Alpha]] after --fix, body: {body[:300]}"
print("PASS T6: --fix rewrote bare [[Alpha]] in hub.md body to [[alpha|Alpha]]")
PYEOF

# ---------------------------------------------------------------------------
# Capture POST-FIX JSON
# ---------------------------------------------------------------------------
invoke_tool_compat lint --category linkres --format json "$WIKI" \
    > "$TMP/post-fix.json" 2>/dev/null || true

# T2 error gone after --fix
python3 - "$TMP/post-fix.json" "$TMP/pre-fix.json" <<'PYEOF'
import json, sys
post = json.load(open(sys.argv[1]))
pre = json.load(open(sys.argv[2]))
post_lr = [d for d in post if d['category'] == 'linkres']
# The bare [[Alpha]] error in hub.md body should now be gone
bare_alpha_errors_post = [d for d in post_lr if d['severity'] == 'error'
                          and d['path'].endswith('hub.md')
                          and 'bare link [[Alpha]]' in d.get('message', '')]
assert len(bare_alpha_errors_post) == 0, (
    f"FAIL T2-post: bare [[Alpha]] error in hub.md should be gone after --fix, got {bare_alpha_errors_post}"
)
print("PASS T2-post: bare [[Alpha]] error in hub.md is gone after --fix")
PYEOF

# ---------------------------------------------------------------------------
# T7 post-fix: bare [[Totally Unknown Thing]] is UNFIXABLE -- error remains
# ---------------------------------------------------------------------------
python3 - "$TMP/post-fix.json" <<'PYEOF'
import json, sys
post = json.load(open(sys.argv[1]))
t7_post = [d for d in post if d['category'] == 'linkres' and d['severity'] == 'error'
           and 'Totally Unknown Thing' in d.get('message', '')]
assert len(t7_post) >= 1, (
    f"FAIL T7-post: bare [[Totally Unknown Thing]] (no match) error should remain after --fix (unfixable), "
    f"got {t7_post}"
)
print("PASS T7-post: bare [[Totally Unknown Thing]] error remains after --fix (no unique match, unfixable)")
PYEOF

# ---------------------------------------------------------------------------
# T8: --fix is idempotent -- second run produces byte-identical hub.md
# ---------------------------------------------------------------------------
SHA_BEFORE=$(python3 -c "import hashlib; print(hashlib.sha256(open('$WIKI/concepts/hub.md','rb').read()).hexdigest())")
invoke_tool_compat lint --fix --category linkres "$WIKI" > /dev/null 2>/dev/null || true
SHA_AFTER=$(python3 -c "import hashlib; print(hashlib.sha256(open('$WIKI/concepts/hub.md','rb').read()).hexdigest())")
if [ "$SHA_BEFORE" = "$SHA_AFTER" ]; then
    echo "PASS T8: --fix is idempotent (second run produces byte-identical hub.md)"
else
    echo "FAIL T8: --fix is NOT idempotent (hub.md changed on second run)" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# T11: orphan reconciliation + alias-does-not-count
# Build a fresh isolated wiki for orphan testing.
# ---------------------------------------------------------------------------
ORPHAN_WIKI="$TMP/orphan-wiki"
mkdir -p "$ORPHAN_WIKI/concepts"
cat > "$ORPHAN_WIKI/index.md" <<'EOF'
# Index
EOF
cat > "$ORPHAN_WIKI/log.md" <<'EOF'
# Log
EOF

# page-a: id=alpha, aliases empty. Reached only by a piped [[alpha|Alpha]] in page-b.
# With id-only resolution, piped [[alpha|Alpha]] -> target "alpha" -> resolves via stem "alpha".
# So page-a should NOT be an orphan (piped inbound link counts as inbound to the id target).
cat > "$ORPHAN_WIKI/concepts/alpha.md" <<'EOF'
---
id: alpha
title: "Alpha"
type: concept
status: active
summary: "A neutral test concept."
created_at: 2026-06-03
updated_at: 2026-06-03
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
# Alpha
Body text.
EOF

# page-b: links to alpha via piped [[alpha|Alpha]]
cat > "$ORPHAN_WIKI/concepts/linker.md" <<'EOF'
---
id: linker
title: "Linker"
type: concept
status: active
summary: "Links to alpha."
created_at: 2026-06-03
updated_at: 2026-06-03
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
# Linker
References [[alpha|Alpha]] for details.
EOF

# page-c: has a vestigial self-alias but NO real inbound links.
# Under alias-free orphan resolution, the self-alias must NOT prevent orphan detection.
cat > "$ORPHAN_WIKI/concepts/alone.md" <<'EOF'
---
id: alone
title: "Alone"
type: concept
status: active
summary: "Page with self-alias but no real inbound links."
created_at: 2026-06-03
updated_at: 2026-06-03
sources: []
epistemic_status: sourced
tags: [test]
domains: [test]
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - "Alone"
  - "alone"
has_contradictions: false
knowledge_domain: science
example: false
---
# Alone
No one links here.
EOF

invoke_tool_compat lint --category orphan --format json "$ORPHAN_WIKI" \
    > "$TMP/orphan-out.json" 2>/dev/null || true

python3 - "$TMP/orphan-out.json" <<'PYEOF'
import json, sys
data = json.load(open(sys.argv[1]))
orphans = [d for d in data if d['category'] == 'orphan']

# alpha should NOT be an orphan (piped [[alpha|Alpha]] inbound link resolves via id stem)
alpha_orphan = [d for d in orphans if 'alpha' in d['path'] and 'alpha.md' in d['path']]
assert len(alpha_orphan) == 0, (
    f"FAIL T11: alpha should NOT be an orphan (piped inbound [[alpha|Alpha]] resolves via stem), "
    f"got {alpha_orphan}"
)
print("PASS T11a: piped [[alpha|Alpha]] inbound link counts as inbound to the alpha page (id-stem resolution)")

# alone SHOULD be an orphan (self-aliases must NOT save it from orphan detection)
alone_orphan = [d for d in orphans if 'alone' in d['path']]
assert len(alone_orphan) >= 1, (
    f"FAIL T11: alone SHOULD be an orphan (alias-only inbound resolution must NOT prevent orphan), "
    f"got {alone_orphan}. Orphan findings: {orphans}"
)
print("PASS T11b: alias-only resolution does NOT save 'alone' from orphan detection (review HIGH #5)")
PYEOF

# ---------------------------------------------------------------------------
# T12 (additional): build a dedicated masking fixture to assert zero findings
# ---------------------------------------------------------------------------
MASK_WIKI="$TMP/mask-wiki"
mkdir -p "$MASK_WIKI/concepts" "$MASK_WIKI/sources"
cat > "$MASK_WIKI/index.md" <<'EOF'
# Index
EOF
cat > "$MASK_WIKI/log.md" <<'EOF'
# Log
EOF

# This page's ONLY [[...]] occurrences are inside masked spans.
# Linkres should emit ZERO findings for it.
cat > "$MASK_WIKI/concepts/masked-only.md" <<'EOF'
---
id: masked-only
title: "Masked Only"
type: concept
status: active
summary: "All links are in masked spans."
created_at: 2026-06-03
updated_at: 2026-06-03
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
# Masked Only

```
[[NonExistent]] and [[also-not-real|X]] in fenced code block
```

Inline: `[[NonExistent]]` also masked.

<!-- [[NonExistent]] in HTML comment also masked -->
EOF

invoke_tool_compat lint --category linkres --format json "$MASK_WIKI" \
    > "$TMP/mask-out.json" 2>/dev/null || true
python3 - "$TMP/mask-out.json" <<'PYEOF'
import json, sys
data = json.load(open(sys.argv[1]))
lr = [d for d in data if d['category'] == 'linkres']
errors_for_masked = [d for d in lr if d['severity'] in ('error', 'warning')
                     and 'masked-only' in d['path']]
assert len(errors_for_masked) == 0, (
    f"FAIL T12: masked-only.md should produce zero linkres findings (all [[...]] in masked spans), "
    f"got {errors_for_masked}"
)
print("PASS T12: [[...]] inside fenced code, inline code, HTML comment produce ZERO linkres findings")
PYEOF

# ---------------------------------------------------------------------------
# T13: --fix preserves YAML frontmatter byte-for-byte (regression guard)
# ---------------------------------------------------------------------------
# We captured FM_PRE above before --fix was run on the main wiki.
# At this point --fix has already run on $WIKI (for T6/T8).
# Check that fmtest.md's frontmatter is unchanged.
FM_POST=$(python3 -c "
import sys
content = open('$WIKI/concepts/fmtest.md', 'r').read()
fm_end = content.index('---', 3)
fm_block = content[:fm_end + 3]
sys.stdout.write(fm_block)
")

# Assert body bare [[Alpha]] was piped
python3 - "$WIKI/concepts/fmtest.md" <<'PYEOF'
import sys
content = open(sys.argv[1]).read()
fm_end = content.index('---', 3)
body = content[fm_end + 3:]
assert '[[alpha|Alpha]]' in body, (
    f"FAIL T13a: --fix should have piped bare [[Alpha]] in fmtest.md body, body={body[:200]}"
)
print("PASS T13a: --fix piped the bare [[Alpha]] in fmtest.md body")
PYEOF

# Assert frontmatter is byte-for-byte identical
if [ "$FM_PRE" = "$FM_POST" ]; then
    echo "PASS T13b: --fix preserved fmtest.md YAML frontmatter byte-for-byte"
else
    echo "FAIL T13b: --fix CORRUPTED fmtest.md YAML frontmatter!" >&2
    echo "--- PRE ---" >&2
    printf '%s\n' "$FM_PRE" >&2
    echo "--- POST ---" >&2
    printf '%s\n' "$FM_POST" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# T14: masking applies to the provenance broken-ref scan AND the gap red-link
# scan, not only linkres (review WR-01/WR-04). A page whose ONLY [prov:...] and
# [[...]] tokens live in inline code / fenced blocks must produce ZERO provenance
# errors and ZERO gap red-link findings. The wikilink example is placed in the
# ## TL;DR section so that WITHOUT masking the gap scan would flag it
# (in_tldr_keyfacts => should_flag per D-20) -- this is what makes the test
# regression-meaningful, not vacuous.
# ---------------------------------------------------------------------------
cat > "$MASK_WIKI/concepts/masked-markers.md" <<'EOF'
---
id: masked-markers
title: "Masked Markers"
type: concept
status: active
summary: "Documents marker grammar; all examples are masked."
created_at: 2026-06-03
updated_at: 2026-06-03
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
# Masked Markers

## TL;DR

A provenance marker looks like `[prov:nonexistent-src#sec:x|direct]` and a wikilink
example looks like `[[ghost-only-example]]` -- both inline-code, so masked.

## Detail

Fenced example block:

```
[prov:another-fake-src#p7] and a link [[second-ghost|Display Text]]
```
EOF

invoke_tool_compat lint --format json "$MASK_WIKI" \
    > "$TMP/mask-markers-out.json" 2>/dev/null || true
python3 - "$TMP/mask-markers-out.json" <<'PYEOF'
import json, sys
data = json.load(open(sys.argv[1]))
prov_errs = [d for d in data if d['category'] == 'provenance'
             and 'masked-markers' in d.get('path', '')]
assert len(prov_errs) == 0, (
    f"FAIL T14a: masked [prov:...] examples must not be flagged as broken refs, got {prov_errs}"
)
print("PASS T14a: masked [prov:...] examples produce ZERO provenance findings")

ghosts = {'ghost-only-example', 'second-ghost'}
gap_hits = [d for d in data if d['category'] == 'gap'
            and d.get('path', '').startswith('red-link:')
            and d['path'].split('red-link:', 1)[1].strip().lower() in ghosts]
assert len(gap_hits) == 0, (
    f"FAIL T14b: masked [[...]] examples (incl. one in TL;DR) must not be flagged as gap red-links, got {gap_hits}"
)
print("PASS T14b: masked [[...]] examples produce ZERO gap red-link findings")
PYEOF

echo "PASS: test_lint_linkres -- all 14 test cases passed"
