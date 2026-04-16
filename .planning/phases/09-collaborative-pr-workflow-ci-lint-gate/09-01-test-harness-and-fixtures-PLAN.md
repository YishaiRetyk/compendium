---
phase: 09-collaborative-pr-workflow-ci-lint-gate
plan: 01
type: execute
wave: 0
depends_on: []
files_modified:
  - tests/phase-09/run.sh
  - tests/phase-09/lib.sh
  - tests/phase-09/fixtures/strict-missing-dr/README.md
  - tests/phase-09/fixtures/strict-missing-prov/README.md
  - tests/phase-09/fixtures/strict-escape-hatch/README.md
  - tests/phase-09/fixtures/privacy-leak-public/README.md
  - tests/phase-09/fixtures/privacy-ok-wiki/README.md
  - tests/phase-09/fixtures/contributor-single/README.md
  - tests/phase-09/fixtures/contributor-multi/README.md
  - tests/phase-09/fixtures/contributor-multi/.git-author-map.txt
  - tests/phase-09/fixtures/ci-lint-json/README.md
autonomous: true
requirements:
  - CI-06
  - CI-07
  - COLAB-04

must_haves:
  truths:
    - "Running `bash tests/phase-09/run.sh` produces a `PHASE 09 TESTS: N/M` summary line and exits non-zero on any test failure."
    - "Each downstream plan can source `tests/phase-09/lib.sh` to get a reusable `make_fixture_repo`, `setup_git_author`, `seed_origin_main_ref`, and `assert_json_has_finding` helper without duplicating boilerplate."
    - "`seed_origin_main_ref <repo>` stages a canonical `refs/remotes/origin/main` pointing at the current `main` branch so Plan 09-03's `--strict` tests can exercise `git diff --name-status origin/main...HEAD` semantics without each test reinventing the remote-ref plumbing."
    - "Every fixture directory listed in 09-VALIDATION.md Wave 0 exists on disk with a README.md documenting its purpose and the exact bytes of any seeded .md files needed to reproduce the test scenario."
    - "All seeded markdown files use LF line endings and UTF-8 encoding (matters for the line-number-sensitive assertions in Plan 09-03's strict tests and Plan 09-04's privacy scanner). The harness verifies this with `file -bi <fixture>.md | grep -q 'charset=utf-8'` and `! grep -lP '\\r' <fixture>.md` (P2 review item — Codex LOW #9)."
  artifacts:
    - path: "tests/phase-09/run.sh"
      provides: "Phase 09 test aggregator (glob over test_*.sh, tally PASS/FAIL, print PHASE 09 TESTS: N/M)"
      contains: "PHASE 09 TESTS"
    - path: "tests/phase-09/lib.sh"
      provides: "Shared bash helpers: make_fixture_repo, setup_git_author, seed_origin_main_ref, assert_json_has_finding, assert_exit_code"
      contains: "make_fixture_repo"
    - path: "tests/phase-09/fixtures/strict-missing-dr/"
      provides: "Fixture with an [inferred] claim on a wiki page and NO matching type:decision page in affected_pages"
    - path: "tests/phase-09/fixtures/strict-missing-prov/"
      provides: "Fixture with a new entity/concept page (type in entity|concept|overview|comparison) and zero [prov: occurrences"
    - path: "tests/phase-09/fixtures/strict-escape-hatch/"
      provides: "Fixture with <!-- lint:expect-inferred id=X reason=Y --> marker on line immediately above an [inferred] claim"
    - path: "tests/phase-09/fixtures/privacy-leak-public/"
      provides: "Fixture with privacy: local_only frontmatter in docs/sample.md (public path)"
    - path: "tests/phase-09/fixtures/privacy-ok-wiki/"
      provides: "Fixture with privacy: local_only frontmatter in wiki/local.md (valid user content)"
    - path: "tests/phase-09/fixtures/contributor-single/"
      provides: "Single-author git repo fixture (all commits by one email)"
    - path: "tests/phase-09/fixtures/contributor-multi/"
      provides: "Multi-author git repo fixture with seeded .git-author-map.txt"
    - path: "tests/phase-09/fixtures/ci-lint-json/"
      provides: "Fixture wiki exercising all severity categories (yaml/orphan/crossref/provenance errors + stale/gap warnings)"
  key_links:
    - from: "tests/phase-09/test_*.sh (downstream plans)"
      to: "tests/phase-09/lib.sh"
      via: "source \"$SCRIPT_DIR/lib.sh\" at test start"
      pattern: "source.*lib\\.sh"
    - from: "tests/phase-09/run.sh"
      to: "tests/phase-09/test_*.sh"
      via: "nullglob for t in test_*.sh"
      pattern: "nullglob"
    - from: "Plan 09-03 strict-mode tests"
      to: "seed_origin_main_ref helper"
      via: "canonical remote-ref setup eliminates per-test branch/remote plumbing"
      pattern: "seed_origin_main_ref"
---

<objective>
Wave 0 foundation: create the `tests/phase-09/` harness and fixture repos that every downstream Phase 9 plan depends on for verification.

Purpose: without this plan, every other Phase 9 task has a `<automated>MISSING — Wave 0 must create ...</automated>` verification. The harness follows the exact pattern established in Phase 7/8 (nullglob + PASS/FAIL accounting + `PHASE NN TESTS: N/M` summary line) so operator muscle-memory from prior phases carries forward. Fixture repos are per-scenario (not shared) so tests do not leak state.

Output: `tests/phase-09/run.sh`, `tests/phase-09/lib.sh`, and 8 fixture directories under `tests/phase-09/fixtures/`. Each fixture ships with a `README.md` documenting its purpose and any seeded files; bash helper builds the throwaway git repo at test time (never commits the synthetic repo into the real tree).

**Review-driven additions (Codex MEDIUM + LOW concerns resolved in revision 2026-04-16):**
- New `seed_origin_main_ref` helper: Plan 09-03's strict tests reference `origin/main...HEAD` semantics; without a canonical helper, each test reinvents the remote/base-ref plumbing (Codex MEDIUM).
- `setup_git_author()` uses a unique per-call filename (email + counter/nanoseconds) instead of the collision-prone `.ts` file (Codex LOW).
- Explicit LF + UTF-8 encoding discipline for all seeded fixture markdown files (Codex LOW; matters for line-number-sensitive assertions downstream).
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-CONTEXT.md
@.planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-RESEARCH.md
@.planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-VALIDATION.md
@tests/phase-08/run.sh
@tests/phase-08/lib.sh

<interfaces>
From tests/phase-08/run.sh (pattern to replicate verbatim, renaming "08" → "09"):

```bash
#!/usr/bin/env bash
set -euo pipefail
FULL=0
while [ "$#" -gt 0 ]; do
    case "$1" in
        --full) FULL=1; shift ;;
        --help|-h) ...; exit 0 ;;
        *) echo "ERROR: unknown option: $1" >&2; exit 1 ;;
    esac
done
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0; FAIL=0; TOTAL=0; FAILED_TESTS=()
shopt -s nullglob
for t in "$SCRIPT_DIR"/test_*.sh; do
    TOTAL=$((TOTAL + 1))
    name="$(basename "$t")"
    echo "--- Running $name ---"
    if bash "$t"; then PASS=$((PASS + 1)); echo "--- PASS $name ---"
    else FAIL=$((FAIL + 1)); FAILED_TESTS+=("$name"); echo "--- FAIL $name ---"; fi
done
echo ""
echo "PHASE 08 TESTS: ${PASS}/${TOTAL}"   # -> rename to PHASE 09 TESTS
if [ "$FAIL" -gt 0 ]; then echo "Failed: ${FAILED_TESTS[*]}" >&2; exit 1; fi
exit 0
```
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Create tests/phase-09/run.sh aggregator + tests/phase-09/lib.sh shared helpers (with seed_origin_main_ref + collision-safe setup_git_author)</name>
  <files>tests/phase-09/run.sh, tests/phase-09/lib.sh</files>
  <read_first>
    - tests/phase-08/run.sh — the exact pattern to replicate (rename 08 → 09)
    - tests/phase-08/lib.sh — reference shape for helper library
    - .planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-RESEARCH.md — §"Test Framework" (line ~970) and §"Wave 0 Gaps" (line ~1020)
    - .planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-VALIDATION.md — Wave 0 Requirements checklist
    - .planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-REVIEWS.md — Codex MEDIUM on seed_origin_main_ref, LOW on setup_git_author collision, LOW on LF/UTF-8 discipline
  </read_first>
  <action>
Create `tests/phase-09/run.sh` as a verbatim copy of `tests/phase-08/run.sh` with only two edits:
  1. Change the header comment: `tests/phase-09/run.sh -- Phase 09 test aggregator (harness for CI lint + privacy + contributor tests).`
  2. Change the summary echo line: `echo "PHASE 09 TESTS: ${PASS}/${TOTAL}"` (the `08` → `09` substitution is the only semantic change).

Mark `run.sh` executable: `chmod +x tests/phase-09/run.sh`.

Create `tests/phase-09/lib.sh` with these shared helpers (sourced by downstream test_*.sh files):

```bash
#!/usr/bin/env bash
# tests/phase-09/lib.sh -- Phase 9 shared test helpers.
# Source this from tests/phase-09/test_*.sh:
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "$SCRIPT_DIR/lib.sh"

# Repo root (run-from-anywhere-safe).
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# make_fixture_repo <fixture-name>  -> prints path to a fresh temp repo
# Copies tests/phase-09/fixtures/<fixture-name>/ into a mktemp dir,
# runs `git init -q`, seeds one commit with the copied files, echoes the path.
make_fixture_repo() {
    local fixture="$1"
    local src="$REPO_ROOT/tests/phase-09/fixtures/$fixture"
    if [ ! -d "$src" ]; then
        echo "ERROR: fixture not found: $src" >&2
        return 1
    fi
    local tmp
    tmp="$(mktemp -d -t phase09-fixture-XXXXXX)"
    # Copy all non-README content (README.md is documentation of the fixture, not part of the repo under test)
    (cd "$src" && find . -type f ! -name README.md -print0) | while IFS= read -r -d '' f; do
        mkdir -p "$tmp/$(dirname "$f")"
        cp "$src/$f" "$tmp/$f"
    done
    (cd "$tmp" && git init -q -b main && git config user.email "fixture@example.com" && git config user.name "Fixture" && git add -A && git -c commit.gpgsign=false commit -q -m "fixture seed")
    echo "$tmp"
}

# setup_git_author <repo-path> <name> <email>
# Adds one commit as that author (for multi-author fixtures).
# Uses a UNIQUE per-call filename (email-sanitized + nanoseconds + RANDOM) to
# avoid the collision Codex LOW flagged with the prior `.ts` scheme.
setup_git_author() {
    local repo="$1" name="$2" email="$3"
    local email_slug
    email_slug="$(printf '%s' "$email" | tr '[:upper:]@.+' 'a-z___')"
    # Nanoseconds + RANDOM makes collision in a tight loop effectively impossible.
    local stamp=".author-${email_slug}-$(date +%s%N 2>/dev/null || date +%s)-${RANDOM}.seed"
    (cd "$repo" && git config user.name "$name" && git config user.email "$email" \
        && printf '%s\n' "$email" > "$stamp" \
        && git add "$stamp" \
        && git -c commit.gpgsign=false commit -q -m "author: $name" --author="$name <$email>")
}

# seed_origin_main_ref <repo-path>
# Stages a canonical `refs/remotes/origin/main` ref pointing at the current
# `main` branch so Plan 09-03's --strict tests can exercise
# `git diff --name-status origin/main...HEAD` without each test reinventing
# branch/remote setup (Codex MEDIUM review concern).
#
# Usage (inside a test, after make_fixture_repo and any branch setup):
#   seed_origin_main_ref "$FIXTURE"
#   # Now `git diff --name-status origin/main...HEAD` works inside $FIXTURE.
#
# Assumes the caller has already set up a `main` branch (make_fixture_repo's
# `git init -b main` above establishes this). If the repo's primary branch has
# been renamed, the helper defers to `refs/heads/main` first, then falls back
# to the current HEAD branch name.
seed_origin_main_ref() {
    local repo="$1"
    if [ ! -d "$repo/.git" ]; then
        echo "ERROR: seed_origin_main_ref: $repo is not a git repo" >&2
        return 1
    fi
    local primary
    # Prefer refs/heads/main; fall back to current branch name
    if (cd "$repo" && git show-ref --verify --quiet refs/heads/main); then
        primary="refs/heads/main"
    else
        local cur
        cur="$(cd "$repo" && git symbolic-ref --short HEAD 2>/dev/null || echo main)"
        primary="refs/heads/$cur"
    fi
    (cd "$repo" && git update-ref refs/remotes/origin/main "$primary" \
        && git update-ref refs/remotes/origin/HEAD "$primary")
}

# assert_exit_code <expected> <actual> <description>
assert_exit_code() {
    local expected="$1" actual="$2" desc="$3"
    if [ "$expected" != "$actual" ]; then
        echo "FAIL: $desc (expected exit=$expected, got $actual)" >&2
        return 1
    fi
}

# assert_json_has_finding <json-file> <category> <severity>
# Uses python3 to parse. Exits 0 if matching finding exists, 1 otherwise.
assert_json_has_finding() {
    local json="$1" cat="$2" sev="$3"
    python3 - "$json" "$cat" "$sev" <<'PYEOF'
import json, sys
f = sys.argv[1]; cat = sys.argv[2]; sev = sys.argv[3]
data = json.load(open(f))
for item in data:
    if item.get('category') == cat and item.get('severity') == sev:
        sys.exit(0)
print(f"FAIL: no finding with category={cat} severity={sev} in {f}", file=sys.stderr)
print(f"Findings present: {[(i.get('severity'),i.get('category')) for i in data]}", file=sys.stderr)
sys.exit(1)
PYEOF
}

# cleanup_fixture_repo <path>  -- safe rm -rf of a mktemp dir
cleanup_fixture_repo() {
    local path="$1"
    if [ -n "$path" ] && [ -d "$path" ] && [[ "$path" == /tmp/* ]]; then
        rm -rf "$path"
    fi
}

export -f make_fixture_repo setup_git_author seed_origin_main_ref assert_exit_code assert_json_has_finding cleanup_fixture_repo
```

Mark executable: `chmod +x tests/phase-09/lib.sh` (optional but consistent with phase-08).

**Note on `git init -b main`:** Using `-b main` ensures the seed fixture's primary branch is named `main` regardless of the operator's `init.defaultBranch` config. This is the anchor Plan 09-03's strict tests rely on.
  </action>
  <verify>
    <automated>bash tests/phase-09/run.sh | tail -1 | grep -q "PHASE 09 TESTS: 0/0"</automated>
  </verify>
  <acceptance_criteria>
    - `tests/phase-09/run.sh` exists and is executable (`test -x tests/phase-09/run.sh`)
    - `tests/phase-09/lib.sh` exists
    - `bash tests/phase-09/run.sh` exits 0 with empty test suite (no test_*.sh files yet) and prints the exact string `PHASE 09 TESTS: 0/0`
    - `grep -q "PHASE 09 TESTS:" tests/phase-09/run.sh` returns 0 (summary line present)
    - `grep -q "make_fixture_repo" tests/phase-09/lib.sh` returns 0 (helper defined)
    - `grep -q "assert_json_has_finding" tests/phase-09/lib.sh` returns 0 (helper defined)
    - `grep -q "setup_git_author" tests/phase-09/lib.sh` returns 0 (helper defined)
    - `grep -q "seed_origin_main_ref" tests/phase-09/lib.sh` returns 0 (helper defined — P1 review fix)
    - `grep -q "git init -q -b main" tests/phase-09/lib.sh` returns 0 (primary branch deterministically `main`)
    - `grep -q "\\.author-\\\${email_slug}" tests/phase-09/lib.sh || grep -q 'author-.*seed' tests/phase-09/lib.sh` returns 0 (unique-per-call filename in setup_git_author — P2 review fix, replaces collision-prone `.ts`)
    - `! grep -q 'date > .ts' tests/phase-09/lib.sh` returns 0 (old collision-prone primitive removed)
    - `bash -n tests/phase-09/lib.sh` passes (no syntax errors)
  </acceptance_criteria>
  <done>
    Harness and shared helpers exist. Downstream test_*.sh files can `source "$SCRIPT_DIR/lib.sh"` and call `make_fixture_repo strict-missing-dr` to instantiate a fresh throwaway git repo per test without boilerplate. Plan 09-03's strict tests call `seed_origin_main_ref "$FIXTURE"` to establish the canonical remote ref for `origin/main...HEAD` diffs.
  </done>
</task>

<task type="auto">
  <name>Task 2: Create 8 fixture directories under tests/phase-09/fixtures/ with seeded .md files (LF + UTF-8 encoding discipline) and README.md</name>
  <files>tests/phase-09/fixtures/strict-missing-dr/README.md, tests/phase-09/fixtures/strict-missing-dr/wiki/concepts/attention.md, tests/phase-09/fixtures/strict-missing-prov/README.md, tests/phase-09/fixtures/strict-missing-prov/wiki/concepts/new-concept.md, tests/phase-09/fixtures/strict-escape-hatch/README.md, tests/phase-09/fixtures/strict-escape-hatch/wiki/concepts/attention.md, tests/phase-09/fixtures/privacy-leak-public/README.md, tests/phase-09/fixtures/privacy-leak-public/docs/sample.md, tests/phase-09/fixtures/privacy-ok-wiki/README.md, tests/phase-09/fixtures/privacy-ok-wiki/wiki/local.md, tests/phase-09/fixtures/contributor-single/README.md, tests/phase-09/fixtures/contributor-multi/README.md, tests/phase-09/fixtures/contributor-multi/.git-author-map.txt, tests/phase-09/fixtures/ci-lint-json/README.md, tests/phase-09/fixtures/ci-lint-json/wiki/index.md</files>
  <read_first>
    - .planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-VALIDATION.md — Wave 0 Requirements list
    - .planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-CONTEXT.md — D-09 (escape-hatch marker syntax), D-10 (new-page definition), D-14 (privacy frontmatter-only scan), D-15 (PUBLIC_PATHS), D-20 (single-author detection)
    - .planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-REVIEWS.md — Codex LOW #10 (newline/encoding discipline)
    - AGENTS.md — §5 (base frontmatter fields) for valid fixture frontmatter
  </read_first>
  <action>
Create these 8 fixture directories and their seeded files. Each directory gets a `README.md` documenting intent; the fixture's actual `.md` files are what `make_fixture_repo` copies into the throwaway git repo.

**Encoding discipline (P2 review fix — applies to ALL seeded files):**

- Every seeded `.md` file MUST use **LF line endings** (`\n`, not `\r\n`).
- Every seeded `.md` file MUST be **UTF-8 encoded** (no BOM, no Latin-1).
- Verify after writing: `file -bi <file> | grep -q 'charset=utf-8'` and `! grep -lP '\r' <file>`.
- Rationale: Plan 09-03's strict tests assert on specific line numbers (via `git diff` hunks and `[epistemic::]` line indexing). CRLF line endings shift byte offsets and can introduce off-by-one failures that are hard to diagnose.

**Fixture 1: `strict-missing-dr/`** (CI-06 DR-match negative case)
- `README.md`: "Strict mode: [inferred] claim with NO matching decision record. `bin/lint.sh --strict` MUST exit non-zero on this fixture. No type:decision page exists in the fixture."
- `wiki/concepts/attention.md`: a concept page with at least one claim marked `[epistemic:: inferred]` but no `wiki/decisions/*` file referencing this page ID in `affected_pages`.

```markdown
# --- frontmatter delimiter (escaped for doc-parser)
id: attention
title: Attention
type: concept
status: active
summary: "A neural network focus mechanism."
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
# --- frontmatter delimiter (escaped for doc-parser)

## TL;DR

Attention lets models focus on relevant inputs.

## Key Facts

- Attention is likely the most important innovation in deep learning post-2017 [prov:src-2026-04-16-test#p1] [epistemic:: inferred]

## Detail

Fixture body.
```

**Fixture 2: `strict-missing-prov/`** (CI-06 new-page-without-provenance)
- `README.md`: "New-page detection: a git-diff status `A` page with type in {entity,concept,overview,comparison} and ZERO `[prov:` occurrences MUST cause `bin/lint.sh --strict` to exit non-zero. Test harness uses `seed_origin_main_ref` + a two-commit setup to simulate status-A in the diff. Tests exempt the fixture from DR-match by using a type:concept page with no epistemic markers."
- `wiki/concepts/new-concept.md`: concept page with normal body but NO `[prov:` anywhere.

```markdown
# --- frontmatter delimiter (escaped for doc-parser)
id: new-concept
title: New Concept
type: concept
status: active
summary: "A new concept with no provenance markers."
created_at: 2026-04-16
updated_at: 2026-04-16
sources: []
epistemic_status: tentative
tags: [test]
domains: [test]
supersedes:
superseded_by:
privacy: cloud_safe
aliases: []
has_contradictions: false
knowledge_domain: science
example: false
# --- frontmatter delimiter (escaped for doc-parser)

## TL;DR

A concept page without any provenance markers.

## Key Facts

- Something claimed without sourcing.

## Detail

No [prov: markers appear anywhere in this body.
```

**Fixture 3: `strict-escape-hatch/`** (D-09 escape-hatch positive case)
- `README.md`: "Escape-hatch marker on line IMMEDIATELY above an [inferred] claim MUST exempt the claim from --strict failure. Blank line between marker and claim MUST invalidate the exemption (negative test handled by --strict tests, not fixture)."
- `wiki/concepts/attention.md`: same as Fixture 1 but with `<!-- lint:expect-inferred id=attention reason="Source paper under review" -->` on line immediately above the `[epistemic:: inferred]` line (no blank line between).

**Fixture 4: `privacy-leak-public/`** (CI-07 leak case)
- `README.md`: "`privacy: local_only` in a public path (`docs/`) MUST cause `bin/check-privacy.sh` to exit 2."
- `docs/sample.md`:

```markdown
# --- frontmatter delimiter (escaped for doc-parser)
id: sample
title: Sample
type: concept
privacy: local_only
created_at: 2026-04-16
updated_at: 2026-04-16
# --- frontmatter delimiter (escaped for doc-parser)

Body.
```

**Fixture 5: `privacy-ok-wiki/`** (CI-07 valid case)
- `README.md`: "`privacy: local_only` inside `wiki/` is valid user content per AGENTS.md §13. `bin/check-privacy.sh` MUST exit 0 on this fixture."
- `wiki/local.md`:

```markdown
# --- frontmatter delimiter (escaped for doc-parser)
id: local
title: Local Only Page
type: concept
privacy: local_only
created_at: 2026-04-16
updated_at: 2026-04-16
# --- frontmatter delimiter (escaped for doc-parser)

Body.
```

**Fixture 6: `contributor-single/`** (COLAB-04 single-author)
- `README.md`: "Single-author repo fixture. `make_fixture_repo` creates the git repo with only the default fixture@example.com commit — satisfies D-20 single-author heuristic (`git log --all --format='%ae' | sort -u | wc -l` == 1). `bin/ingest.sh` auto-detect MUST omit the `contributor::` field entirely."
- No seeded files needed beyond the README (make_fixture_repo skips README.md, and the fresh git init creates only the initial commit anyway). Add a `.gitkeep` to force the dir exist: `tests/phase-09/fixtures/contributor-single/.gitkeep`.

**Fixture 7: `contributor-multi/`** (COLAB-04 multi-author with map)
- `README.md`: "Multi-author repo fixture. Test setup calls `setup_git_author` TWICE to add commits by alice@example.com and bob@example.com. The seeded `.git-author-map.txt` maps `alice@example.com -> @alice`. Auto-detect MUST emit `contributor:: @alice` when `git config user.email` is alice@example.com, and MUST warn + omit when the configured email is not in the map."
- `.git-author-map.txt`:

```
# .git-author-map.txt -- email -> GitHub handle map (Phase 9 COLAB-04 fixture).
# Format: "<email>  ->  @<handle>"  (two-space-arrow-two-space, or tab separator)
# Comments start with #. Case-insensitive email match.
alice@example.com  ->  @alice
```

**Fixture 8: `ci-lint-json/`** (CI-02/CI-03 severity-remap test bed)
- `README.md`: "Exercises all severity categories. Seeded with a minimal wiki that triggers: yaml error (malformed frontmatter), orphan warning (page with no inbound links), stale warning (old checked_at), gap info (red link). Used to validate `--format json` shape and `--ci` severity remap."
- `wiki/index.md`: minimal wiki index listing one concept:

```markdown
# Index

## Concepts

- [[Attention]] -- test concept (sourced, 2026-04-16)
```

(Downstream tests seed additional triggering files as needed via inline heredoc; this fixture just provides the skeleton. Keep fixture minimal so it does not drift from `bin/lint.sh` rule changes.)

Do NOT commit the fixture git repos (no `.git/` subdirectories). `make_fixture_repo` performs `git init` at test time on a throwaway mktemp dir. The `tests/phase-09/fixtures/` tree on disk is static input only.

**Post-write encoding verification (part of the task):**

```bash
# After seeding all fixture files, verify encoding/line-endings discipline:
find tests/phase-09/fixtures -name '*.md' -o -name '.git-author-map.txt' | while read f; do
    # LF-only: fail if any \r present
    if grep -lP '\r' "$f" >/dev/null 2>&1; then
        echo "ERROR: CRLF line endings in fixture: $f" >&2
        exit 1
    fi
    # UTF-8: file -bi should report charset=utf-8 or us-ascii (ASCII is a UTF-8 subset)
    charset="$(file -bi "$f" | grep -oE 'charset=[a-z0-9-]+' || echo 'charset=unknown')"
    case "$charset" in
        charset=utf-8|charset=us-ascii) ;;
        *) echo "ERROR: non-UTF-8 fixture: $f ($charset)" >&2; exit 1 ;;
    esac
done
```

Run this verification manually after seeding; acceptance criteria include one exemplar check as automated assertion.
  </action>
  <verify>
    <automated>test -d tests/phase-09/fixtures/strict-missing-dr && test -d tests/phase-09/fixtures/strict-missing-prov && test -d tests/phase-09/fixtures/strict-escape-hatch && test -d tests/phase-09/fixtures/privacy-leak-public && test -d tests/phase-09/fixtures/privacy-ok-wiki && test -d tests/phase-09/fixtures/contributor-single && test -d tests/phase-09/fixtures/contributor-multi && test -d tests/phase-09/fixtures/ci-lint-json && test -f tests/phase-09/fixtures/contributor-multi/.git-author-map.txt && grep -q "alice@example.com" tests/phase-09/fixtures/contributor-multi/.git-author-map.txt && ! find tests/phase-09/fixtures -name '*.md' -exec grep -lP '\r' {} + | grep -q .</automated>
  </verify>
  <acceptance_criteria>
    - All 8 fixture directories exist under `tests/phase-09/fixtures/`
    - Each fixture has a `README.md` documenting purpose (`find tests/phase-09/fixtures -name README.md | wc -l` equals 8)
    - `strict-missing-dr/wiki/concepts/attention.md` contains `[epistemic:: inferred]` (exact string, with double-colon)
    - `strict-missing-prov/wiki/concepts/new-concept.md` does NOT contain `[prov:` (`! grep -q '\[prov:' tests/phase-09/fixtures/strict-missing-prov/wiki/concepts/new-concept.md`)
    - `strict-escape-hatch/wiki/concepts/attention.md` contains `<!-- lint:expect-inferred id=attention reason=` on a line and `[epistemic:: inferred]` on the very next line (no blank between)
    - `privacy-leak-public/docs/sample.md` contains `privacy: local_only` in frontmatter
    - `privacy-ok-wiki/wiki/local.md` contains `privacy: local_only` in frontmatter
    - `contributor-multi/.git-author-map.txt` contains `alice@example.com  ->  @alice` (exact two-space-arrow-two-space separator)
    - No `.git/` subdirectory exists in any fixture (fixtures are static input; `make_fixture_repo` creates the git repo at test time)
    - **Encoding discipline (P2 review fix):** `! find tests/phase-09/fixtures -name '*.md' -exec grep -lP '\r' {} +` returns empty (no CRLF); all seeded `.md` files pass `file -bi <f> | grep -qE 'charset=(utf-8|us-ascii)'`
  </acceptance_criteria>
  <done>
    All 8 fixtures documented and seeded with LF + UTF-8 discipline. Downstream plans can write test_*.sh files that call `make_fixture_repo <name>` and assert behavior without re-creating fixture content inline. Line-number-sensitive assertions in Plan 09-03 are robust against EOL drift.
  </done>
</task>

</tasks>

<verification>
- `bash tests/phase-09/run.sh` exits 0 with `PHASE 09 TESTS: 0/0` summary.
- `find tests/phase-09/fixtures -maxdepth 1 -mindepth 1 -type d | wc -l` equals 8.
- `bash -n tests/phase-09/lib.sh` passes (syntax clean).
- `grep -c "make_fixture_repo\|setup_git_author\|seed_origin_main_ref\|assert_json_has_finding" tests/phase-09/lib.sh` is at least 4 (all helpers defined).
- No `.md` fixture file contains CR (`\r`): `! find tests/phase-09/fixtures -name '*.md' -exec grep -lP '\r' {} +`.
</verification>

<success_criteria>
Every downstream Phase 9 plan (02–06) can source `tests/phase-09/lib.sh` and instantiate fixture repos via `make_fixture_repo <name>` without boilerplate. Plan 09-03 strict tests use `seed_origin_main_ref` to establish canonical remote refs instead of hand-building each time. The aggregator picks up future `tests/phase-09/test_*.sh` files automatically via `nullglob`.
</success_criteria>

<output>
After completion, create `.planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-01-SUMMARY.md` documenting: harness pattern chosen (phase-08 clone), helper-library public API (exported bash functions with signatures — including the new `seed_origin_main_ref` and the revised collision-safe `setup_git_author`), fixture list and purpose map, LF + UTF-8 encoding discipline, and the convention that fixtures are static input (no committed .git/).
</output>
