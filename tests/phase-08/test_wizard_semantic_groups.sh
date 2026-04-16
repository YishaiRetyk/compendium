#!/usr/bin/env bash
# tests/phase-08/test_wizard_semantic_groups.sh -- WZRD-02: interactive mode
# prints the 4 D-13 group explainers AND the prompt-1 standalone explainer
# verbatim. Feeds canned stdin (one answer per line) and greps the combined
# stdout+stderr (the wizard sends prompts + explainers to stderr so the
# test captures both).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

WIZARD="$REPO_ROOT/bin/init-wizard.sh"

echo "TEST: interactive mode prints D-13 semantic-group explainers (WZRD-02)"

WORK="$(mktemp_repo)"

# NO_COLOR=1 strips ANSI escapes so grep matches plain substrings.
set +e
OUT=$(NO_COLOR=1 printf 'Template Maintainer\npersonal-knowledge\nclaude-code\ncloud_safe\ndefault\ny\n' \
      | bash "$WIZARD" --render-to "$WORK" 2>&1)
set -e

check_line() {
    local needle="$1" label="$2"
    if ! printf '%s\n' "$OUT" | grep -qF "$needle"; then
        echo "ASSERT FAIL: $label missing" >&2
        echo "needle: $needle" >&2
        echo "--- captured output (head 60) ---" >&2
        printf '%s\n' "$OUT" | head -60 >&2
        echo "---" >&2
        exit 1
    fi
}

check_line 'Recorded in the initial decision record for attribution.' \
    'maintainer-name standalone explainer'

check_line 'Your primary knowledge domain seeds the staleness decay rate and AGENTS.md frontmatter examples.' \
    'Domain group explainer'

check_line 'Determines which file the canonical-spec self-reference points at; both AGENTS.md and CLAUDE.md are always written byte-identical.' \
    'LLM agent group explainer'

check_line 'Default privacy tier applied to new pages, and how fast claims decay if their source is not re-verified.' \
    'Privacy defaults group explainer'

check_line "Whether you'll browse the wiki in Obsidian; recorded for future tooling, does not change AGENTS.md." \
    'Obsidian group explainer'

echo "PASS: all 5 D-13 explainer lines appear in interactive output"
exit 0
