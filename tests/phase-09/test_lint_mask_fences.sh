#!/usr/bin/env bash
# test_lint_mask_fences.sh -- fence edge-case hardening for mask_markdown
# (quick task 260703-m4f, promotes .planning/todos phase-14-lint-mask-fence-edge-cases).
# Guards Phase 14 review WR-02 (unclosed fence leaks) + WR-03 (info-string
# pseudo-closer leaks) per CommonMark: a closing fence is a run of >= opener-length
# fence chars of the SAME char followed only by whitespace; an info string on a
# "closing" line means the line does NOT close; an unclosed fence extends to EOF.
# Neutral fixtures only. Self-contained temp wiki. No git needed.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

TMP="$(mktemp -d -t lint-mask-fences-XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

WIKI="$TMP/wiki"
mkdir -p "$WIKI/concepts"
printf '# Index\n' > "$WIKI/index.md"
printf '# Log\n' > "$WIKI/log.md"

fm() {
    # $1 = id, $2 = title
    cat <<EOF
---
id: $1
title: "$2"
type: concept
status: active
summary: "Fence-masking fixture."
created_at: 2026-07-03
updated_at: 2026-07-03
sources: []
epistemic_status: sourced
tags: [test]
domains: [test]
supersedes:
superseded_by:
aliases: []
has_contradictions: false
knowledge_domain: science
example: false
---
EOF
}

# ---------------------------------------------------------------------------
# unclosed.md (WR-02): fence opened, NEVER closed -> extends to EOF per
# CommonMark. The bare [[NonExistent]] inside it must NOT be flagged and
# --fix must NOT rewrite anything in this file.
# ---------------------------------------------------------------------------
{
    fm unclosed "Unclosed Fence"
    cat <<'EOF'
# Unclosed Fence

Prose before the fence.

```
[[NonExistent]] and [[also-fake|X]] inside an UNCLOSED fence
more code lines
EOF
} > "$WIKI/concepts/unclosed.md"

# ---------------------------------------------------------------------------
# pseudo-closer.md (WR-03): opener ``` then a line ```ruby -- per CommonMark
# an info string on a closing fence means it does NOT close. No true closer
# follows, so the block extends to EOF. [[GhostOne]] after the pseudo-closer
# must NOT be flagged.
# ---------------------------------------------------------------------------
{
    fm pseudo-closer "Pseudo Closer"
    cat <<'EOF'
# Pseudo Closer

```
code line
```ruby
[[GhostOne]] still inside the fence (pseudo-closer had an info string)
EOF
} > "$WIKI/concepts/pseudo-closer.md"

# ---------------------------------------------------------------------------
# true-closer-after.md (WR-03b, anti-over-masking guard): opener ``` , a
# ```ruby pseudo-closer (does not close), then a TRUE closer ``` , then a
# real bare link in prose AFTER the block. That link MUST still be flagged --
# the fix must not swallow everything to EOF when a true closer exists.
# ---------------------------------------------------------------------------
{
    fm true-closer-after "True Closer After"
    cat <<'EOF'
# True Closer After

```
code line
```ruby
still code ([[MaskedGhost]] must not be flagged)
```

Prose after the true closer with a bare link: [[AfterFence]].
EOF
} > "$WIKI/concepts/true-closer-after.md"

# ---------------------------------------------------------------------------
# closed-normal.md (regression): a normally closed fence (closer has trailing
# whitespace -- allowed) followed by a real bare link that MUST be flagged.
# ---------------------------------------------------------------------------
{
    fm closed-normal "Closed Normal"
    # NOTE: the closing fence line below has two trailing spaces (CommonMark-legal)
    printf '# Closed Normal\n\n```\n[[InsideClosed]] masked\n```  \n\nProse after with bare link: [[AfterClosed]].\n'
} > "$WIKI/concepts/closed-normal.md"

# ---------------------------------------------------------------------------
# long-fence.md (length rule): opener ```` (4 backticks) contains a ``` line
# (3 backticks -- shorter, must NOT close) with a masked ghost after it; the
# true ```` closer ends the block; a bare link after it MUST be flagged.
# ---------------------------------------------------------------------------
{
    fm long-fence "Long Fence"
    cat <<'EOF'
# Long Fence

````
```
[[InnerGhost]] after a shorter inner fence line -- still inside the 4-tick block
````

Prose after with bare link: [[AfterLong]].
EOF
} > "$WIKI/concepts/long-fence.md"

# ---------------------------------------------------------------------------
# mixed-chars.md: opener ``` , a ~~~ line inside (different char, must NOT
# close), no true closer -> extends to EOF; [[TildeGhost]] must NOT be flagged.
# ---------------------------------------------------------------------------
{
    fm mixed-chars "Mixed Chars"
    cat <<'EOF'
# Mixed Chars

```
code
~~~
[[TildeGhost]] still inside the backtick fence (tilde line does not close it)
EOF
} > "$WIKI/concepts/mixed-chars.md"

# ---------------------------------------------------------------------------
# Snapshot file bytes before any --fix (mutation guard for T6)
# ---------------------------------------------------------------------------
sha() { python3 -c "import hashlib,sys; print(hashlib.sha256(open(sys.argv[1],'rb').read()).hexdigest())" "$1"; }
UNCLOSED_PRE="$(sha "$WIKI/concepts/unclosed.md")"
PSEUDO_PRE="$(sha "$WIKI/concepts/pseudo-closer.md")"

# ---------------------------------------------------------------------------
# Run linkres scan -> JSON
# ---------------------------------------------------------------------------
bash "$REPO_ROOT/bin/lint.sh" --category linkres --format json "$WIKI" \
    > "$TMP/out.json" 2>/dev/null || true

python3 - "$TMP/out.json" <<'PYEOF'
import json, sys
data = json.load(open(sys.argv[1]))
lr = [d for d in data if d['category'] == 'linkres']

def hits(token):
    return [d for d in lr if token in d.get('message', '')]

# --- T1 (WR-02): unclosed fence content is masked ---
assert not hits('NonExistent') and not hits('also-fake'), (
    f"FAIL T1: [[NonExistent]]/[[also-fake|X]] inside an UNCLOSED fence must be masked, got "
    f"{[d['message'] for d in lr if 'unclosed' in d['path']]}"
)
print("PASS T1 (WR-02): unclosed fence content produces zero linkres findings")

# --- T2 (WR-03): info-string pseudo-closer does not close; block runs to EOF ---
assert not hits('GhostOne'), (
    f"FAIL T2: [[GhostOne]] after a ```ruby pseudo-closer must still be masked, got {hits('GhostOne')}"
)
print("PASS T2 (WR-03): info-string pseudo-closer does not close the fence (content stays masked)")

# --- T3 (anti-over-masking): true closer after a pseudo-closer ends the block ---
assert not hits('MaskedGhost'), (
    f"FAIL T3a: [[MaskedGhost]] before the true closer must be masked, got {hits('MaskedGhost')}"
)
assert hits('AfterFence'), (
    f"FAIL T3b: bare [[AfterFence]] AFTER the true closer must be flagged (no over-masking), got "
    f"{[d['message'] for d in lr if 'true-closer-after' in d['path']]}"
)
print("PASS T3: true closer ends the block -- masked inside, flagged after")

# --- T4 (regression): normally closed fence w/ trailing-whitespace closer ---
assert not hits('InsideClosed'), (
    f"FAIL T4a: [[InsideClosed]] in a closed fence must be masked, got {hits('InsideClosed')}"
)
assert hits('AfterClosed'), (
    f"FAIL T4b: bare [[AfterClosed]] after a closed fence must be flagged, got "
    f"{[d['message'] for d in lr if 'closed-normal' in d['path']]}"
)
print("PASS T4: normal closed fence (trailing-whitespace closer) -- masked inside, flagged after")

# --- T5 (length rule): shorter inner fence line does not close a longer opener ---
assert not hits('InnerGhost'), (
    f"FAIL T5a: [[InnerGhost]] after a shorter inner ``` line must stay masked inside the ```` block, "
    f"got {hits('InnerGhost')}"
)
assert hits('AfterLong'), (
    f"FAIL T5b: bare [[AfterLong]] after the ```` closer must be flagged, got "
    f"{[d['message'] for d in lr if 'long-fence' in d['path']]}"
)
print("PASS T5: closer must be >= opener length -- shorter inner fence line does not close")

# --- T6 (char rule): tilde line does not close a backtick fence ---
assert not hits('TildeGhost'), (
    f"FAIL T6: [[TildeGhost]] after a ~~~ line inside a ``` fence must stay masked, got {hits('TildeGhost')}"
)
print("PASS T6: fence char must match -- ~~~ does not close a ``` fence")
PYEOF

# ---------------------------------------------------------------------------
# T7: --fix must not mutate files whose only [[...]] tokens are inside
# (unclosed / pseudo-closed) fences -- content-mutation guard.
# ---------------------------------------------------------------------------
bash "$REPO_ROOT/bin/lint.sh" --fix --category linkres "$WIKI" > /dev/null 2>/dev/null || true
UNCLOSED_POST="$(sha "$WIKI/concepts/unclosed.md")"
PSEUDO_POST="$(sha "$WIKI/concepts/pseudo-closer.md")"
if [ "$UNCLOSED_PRE" != "$UNCLOSED_POST" ]; then
    echo "FAIL T7: --fix mutated unclosed.md (rewrote a link inside an unclosed fence)" >&2
    exit 1
fi
if [ "$PSEUDO_PRE" != "$PSEUDO_POST" ]; then
    echo "FAIL T7: --fix mutated pseudo-closer.md (rewrote a link inside a pseudo-closed fence)" >&2
    exit 1
fi
echo "PASS T7: --fix leaves unclosed/pseudo-closed fence files byte-identical"

echo "PASS: test_lint_mask_fences -- all 7 cases passed"
