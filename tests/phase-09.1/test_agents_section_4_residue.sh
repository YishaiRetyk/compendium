#!/usr/bin/env bash
# I-6: AGENTS.md §4.1 through §4.6 each have exactly ONE `See: schema/examples/<type>.md` line
# in the D-08 residue shape. Also: the former worked-example fenced blocks are GONE.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

A="$REPO_ROOT/AGENTS.md"

# D-09 pointer convention: bare `See: schema/examples/<slug>.md for a concrete filled-in instance.`
# Matches the AGENTS.md §§11.1 (line 880), 11.2 (line 1323), 12 (line 1553) precedent.
for t in entity concept source-summary comparison overview decision; do
    grep -q "^See: schema/examples/$t\.md for a concrete filled-in instance\.$" "$A" \
        || { echo "FAIL: §4 missing bare pointer 'See: schema/examples/$t.md for a concrete filled-in instance.'" >&2; exit 1; }
done

# Exactly 6 such pointers — not 5, not 7
count="$(grep -cE '^See: schema/examples/(entity|concept|source-summary|comparison|overview|decision)\.md for a concrete filled-in instance\.$' "$A")"
[ "$count" -eq 6 ] || { echo "FAIL: expected 6 §4 pointers, found $count" >&2; exit 1; }

# Anti-patterns per R-6: reject markdown-link / bold / list-bullet forms
! grep -qE '^\s*-?\s*\*\*See:\*\*' "$A" || { echo "FAIL: found **See:** (bold) — D-09 violation" >&2; exit 1; }
! grep -qE 'See: \[schema/examples/' "$A" || { echo "FAIL: found markdown-link See pointer — D-09 violation" >&2; exit 1; }

# Former §4 worked-example content ABSENT. Unique verbatim strings from each current block.
for old in \
    "British-Canadian computer scientist, pioneer of deep learning" \
    "A neural network component that allows models to focus" \
    "Seminal paper introducing the Transformer architecture based entirely on attention" \
    "Comparison of recurrent neural networks and Transformer architectures" \
    "High-level overview of deep learning: history, key architectures"
do
    if grep -Fq "$old" "$A"; then
        echo "FAIL: AGENTS.md still contains former §4 worked-example content: '$old'" >&2
        exit 1
    fi
done

# R8 review consensus: ratchet the §4 preamble from "Five page types exist." (pre-Phase-6 drift)
# to "Six page types exist." The DR Consequences section references this polish; the change is
# mandatory (not optional) because the DR prose would contradict a stale "Five" preamble.
grep -F -q 'Six page types exist.' "$A" \
    || { echo "FAIL: §4 preamble must read 'Six page types exist.' (polish promoted to mandatory per R8/DR Consequences); found outdated 'Five page types exist.' or missing" >&2; exit 1; }
! grep -F -q 'Five page types exist.' "$A" \
    || { echo "FAIL: §4 preamble still has outdated 'Five page types exist.' — R8 polish not applied" >&2; exit 1; }

echo "PASS: AGENTS.md §4 residue correctly extracted"
