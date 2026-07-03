#!/usr/bin/env bash
# tests/phase-10/test_lint_ci_no_downgrade_when_absent.sh
# Phase 10 Plan 04 (BRWN-08 no-false-positive guard) — asserts `bin/lint.sh
# --ci` does NOT downgrade a yaml-category error on a NON-bootstrapped page.
# Pairs with test_lint_ci_downgrade_bootstrapped.sh to prove the downgrade
# is scoped to bootstrapped pages only.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

tmp="$(mktemp -d -t phase10-lint-ci-nodg-XXXXXX)"
mkdir -p "$tmp/wiki-cloud/concepts" "$tmp/wiki-cloud/sources"

# Author a page with the same yaml-error shape (type: "") but NO
# bootstrap_stage frontmatter.
cat > "$tmp/wiki-cloud/concepts/greenfield-broken.md" <<'EOF'
---
id: greenfield-broken
title: "Greenfield Broken"
type: ""
status: active
summary: ""
created_at: 2026-01-01
updated_at: 2026-01-01
sources: []
epistemic_status: tentative
tags: []
domains: []
supersedes: null
superseded_by: null
privacy: local_only
aliases: []
has_contradictions: false
knowledge_domain: ""
---

Body. No bootstrap_stage → must retain full error severity under --ci.
EOF

printf '# Index\n[[Greenfield Broken]]\n' > "$tmp/wiki-cloud/index.md"
printf '# Log\n' > "$tmp/wiki-cloud/log.md"

json="$(invoke_tool_compat lint --ci --format json "$tmp/wiki-cloud" 2>/dev/null || true)"

python3 - <<PY
import json, sys
data = json.loads('''$json''')
hits = [f for f in data if 'greenfield-broken.md' in f.get('path', '')]
if not hits:
    print('FAIL: no findings for greenfield-broken.md', file=sys.stderr)
    print(json.dumps(data, indent=2), file=sys.stderr)
    sys.exit(1)
yaml_hits = [f for f in hits if f['category'] == 'yaml']
if not yaml_hits:
    print('FAIL: no yaml-category findings on greenfield-broken.md (fixture assumption broken)', file=sys.stderr)
    print(json.dumps(hits, indent=2), file=sys.stderr)
    sys.exit(1)
for f in yaml_hits:
    if f['severity'] != 'error':
        print(f'FAIL: expected severity=error, got {f["severity"]} (spurious BRWN-08 downgrade on non-bootstrapped page)', file=sys.stderr)
        print(json.dumps(f, indent=2), file=sys.stderr)
        sys.exit(1)
print('PASS: --ci does NOT downgrade findings on non-bootstrapped pages')
PY

rm -rf "$tmp"
