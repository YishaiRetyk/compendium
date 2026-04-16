#!/usr/bin/env bash
# CI-09 / D-32: docs/reference/ci.md fully populated.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

F="$REPO_ROOT/docs/reference/ci.md"
test -f "$F" || { echo "FAIL: $F missing" >&2; exit 1; }

# No longer a stub
if grep -qi "populated in v1\.1 Phase 9\|Status: stub" "$F"; then
    echo "FAIL: ci.md still contains stub disclaimer" >&2; exit 1
fi

# Severity policy table covers the canonical categories
for cat in yaml orphan crossref provenance stale gap contradiction; do
    grep -q "$cat" "$F" || { echo "FAIL: ci.md severity table missing category '$cat'" >&2; exit 1; }
done
# Error + warning mentioned
grep -qi "error" "$F" || { echo "FAIL: severity-policy missing 'error'" >&2; exit 1; }
grep -qi "warning" "$F" || { echo "FAIL: severity-policy missing 'warning'" >&2; exit 1; }

# JSON schema section: keys
for key in severity category path message; do
    grep -q "$key" "$F" || { echo "FAIL: JSON schema missing key '$key'" >&2; exit 1; }
done

# Required sections
for heading in "Severity policy" "JSON output" "Privacy-leak" "strict" "Escape-hatch" "require-version" "GitHub Actions" "GitLab"; do
    grep -qi "$heading" "$F" || { echo "FAIL: ci.md missing section mentioning '$heading'" >&2; exit 1; }
done

# Multi-provider coverage
grep -qi "Gitea" "$F" || { echo "FAIL: ci.md missing Gitea section" >&2; exit 1; }
grep -qi "Codeberg\|Forgejo" "$F" || { echo "FAIL: ci.md missing Codeberg/Forgejo" >&2; exit 1; }
# GitLab has a .gitlab-ci.yml snippet
grep -q "\.gitlab-ci\.yml\|stages:" "$F" || { echo "FAIL: ci.md missing GitLab snippet" >&2; exit 1; }

# Excluded providers
for excluded in Bitbucket Jenkins Drone; do
    if grep -qi "$excluded section\|## $excluded" "$F"; then
        # allow passing mention in "out of scope" list, but not a full section
        if grep -qE "^#+ .*$excluded" "$F"; then
            echo "FAIL: ci.md has a section for '$excluded' (D-31 excludes)" >&2; exit 1
        fi
    fi
done

# Escape-hatch marker example
grep -q "lint:expect-inferred" "$F" || { echo "FAIL: ci.md missing lint:expect-inferred example" >&2; exit 1; }

# --require-version example in YAML
grep -q "require-version" "$F" || { echo "FAIL: ci.md missing --require-version" >&2; exit 1; }

# Source-of-truth pointer to AGENTS.md §11.3 (Codex MEDIUM review -- prevents spec duplication drift)
grep -qi "AGENTS\.md.*11\.3\|source of truth.*AGENTS" "$F" \
    || { echo "FAIL: ci.md severity-policy / JSON-schema sections must link to AGENTS.md §11.3 as source of truth" >&2; exit 1; }

echo "PASS: docs/reference/ci.md fully populated"
