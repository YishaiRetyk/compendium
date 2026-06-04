#!/usr/bin/env bash
# D-09 aggregator: --count-skips emits one skip-count info finding per escape-hatch marker.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

FIXTURE="$(make_fixture_repo strict-escape-hatch)"
trap 'cleanup_fixture_repo "$FIXTURE"' EXIT
pushd "$FIXTURE" >/dev/null

# Seed a second page with 2 more markers
mkdir -p wiki-cloud/concepts
python3 - <<'PYEOF'
content = """---
id: other
title: Other
type: concept
status: active
summary: "Another concept page with two escape-hatch markers."
created_at: 2026-04-16
updated_at: 2026-04-16
sources: [src-2026-04-16-test]
epistemic_status: mixed
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

## TL;DR

Other concept.

## Key Facts

<!-- lint:expect-inferred id=other reason="Paper review pending" -->
- Claim 1 [prov:src-2026-04-16-test#p1] [epistemic:: inferred]

<!-- lint:expect-tentative id=other reason="Preliminary finding" -->
- Claim 2 [prov:src-2026-04-16-test#p2] [epistemic:: tentative]

## Detail

Body.
"""
open("wiki-cloud/concepts/other.md", "w").write(content)
PYEOF
git add . && git -c commit.gpgsign=false commit -q -m "add 2nd page w/ markers"

# Run --count-skips --format json → expect >= 3 skip-count findings
# (1 from fixture's attention.md + 2 from new other.md)
bash "$REPO_ROOT/bin/lint.sh" --count-skips --format json wiki-cloud/ > /tmp/skips.json 2> /tmp/skips.err || true

COUNT="$(python3 -c 'import json; data=json.load(open("/tmp/skips.json")); print(sum(1 for i in data if i["category"]=="skip-count"))')"
if [ "$COUNT" -lt 3 ]; then
    echo "FAIL: expected >= 3 skip-count findings, got $COUNT" >&2
    cat /tmp/skips.json >&2
    popd >/dev/null; exit 1
fi

# Stderr grand-total present
if ! grep -qi "skip" /tmp/skips.err; then
    echo "FAIL: stderr missing skip-count grand total line" >&2
    cat /tmp/skips.err >&2
    popd >/dev/null; exit 1
fi

popd >/dev/null
echo "PASS: --count-skips enumeration + grand total"
