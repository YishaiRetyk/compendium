---
phase: 09-collaborative-pr-workflow-ci-lint-gate
plan: 04
type: execute
wave: 1
depends_on: [09-01]
files_modified:
  - bin/check-privacy.sh
  - bin/ingest.sh
  - bin/search.sh
  - .git-author-map.txt
  - tests/phase-09/test_check_privacy_clean.sh
  - tests/phase-09/test_check_privacy_leak.sh
  - tests/phase-09/test_check_privacy_wiki_ok.sh
  - tests/phase-09/test_ingest_single_author.sh
  - tests/phase-09/test_ingest_auto_detect.sh
  - tests/phase-09/test_ingest_auto_detect_miss.sh
  - tests/phase-09/test_ingest_contributor_explicit.sh
  - tests/phase-09/test_search_contributor.sh
  - tests/phase-09/test_author_map_seed.sh
autonomous: true
requirements:
  - CI-07
  - COLAB-04
  - COLAB-07

must_haves:
  truths:
    - "`bin/check-privacy.sh` exits 0 on a clean repo (no `privacy: local_only` in frontmatter of any public path), exits 2 with `path:line:` output on stderr when leak is present, exits 1 on script failure."
    - "`bin/check-privacy.sh` scans ONLY the `PUBLIC_PATHS` array (`examples/`, `docs/`, `AGENTS.md`, `CLAUDE.md`, `README.md`, `PRIVACY.md`, `.github/`); `wiki/**` is explicitly excluded (D-15). `PRIVACY.md` is included for parity with `bin/check-neutrality.sh` (PRIVACY.md exists at repo root as a top-level public doc — verified 2026-04-16)."
    - "`bin/check-privacy.sh` only matches `privacy: local_only` inside the YAML frontmatter block (between first two `^---` markers). Prose mentions in body are NOT flagged (D-14)."
    - "`bin/ingest.sh --contributor @handle` emits `contributor:: @handle` inside the new log.md entry. Explicit flag overrides auto-detect in both directions (forces emit on single-author, forces the flag-provided value on multi-author)."
    - "`bin/ingest.sh` without `--contributor` on a SINGLE-AUTHOR repo (`git log --all --format='%ae' | sort -u | wc -l == 1`) omits the `contributor::` field entirely (D-20)."
    - "`bin/ingest.sh` without `--contributor` on a MULTI-AUTHOR repo looks up `git config user.email` in `.git-author-map.txt`; on hit, emits mapped `@handle`; on miss, warns to stderr (actionable message pointing at `--contributor` flag + map file) and OMITS the field (never writes bare email, D-21 + Pitfall 5)."
    - "`bin/search.sh --contributor @handle` (or `--contributor handle` — leading `@` is optional) filters `wiki/log.md` entries whose `contributor::` handle matches and returns their enclosing log entry."
    - "`.git-author-map.txt` exists at repo root (committed), ships empty or with a single header comment explaining format (`email  ->  @handle`, `#` comments allowed, case-insensitive email match)."
  artifacts:
    - path: "bin/check-privacy.sh"
      provides: "CI-07 privacy-leak guard — standalone pattern-twin of bin/check-neutrality.sh; exit 0/1/2; frontmatter-only scan; hardcoded PUBLIC_PATHS"
      contains: "PUBLIC_PATHS"
    - path: "bin/ingest.sh"
      provides: "COLAB-04: --contributor flag + single-author detection + .git-author-map.txt lookup + contributor:: log emission"
      contains: "contributor::"
    - path: "bin/search.sh"
      provides: "COLAB-07: --contributor <handle> filter; accepts @handle or bare handle"
      contains: "--contributor"
    - path: ".git-author-map.txt"
      provides: "Human-curated email → @handle map; committed at repo root; ships empty with header comment"
      contains: "email"
    - path: "tests/phase-09/test_check_privacy_clean.sh"
      provides: "CI-07 clean exit 0 test"
    - path: "tests/phase-09/test_check_privacy_leak.sh"
      provides: "CI-07 leak exit 2 test (privacy: local_only in docs/)"
    - path: "tests/phase-09/test_check_privacy_wiki_ok.sh"
      provides: "CI-07 wiki/** local_only is valid user content (exit 0)"
    - path: "tests/phase-09/test_ingest_single_author.sh"
      provides: "COLAB-04 single-author omit field"
    - path: "tests/phase-09/test_ingest_auto_detect.sh"
      provides: "COLAB-04 multi-author auto-detect via map hit"
    - path: "tests/phase-09/test_ingest_auto_detect_miss.sh"
      provides: "COLAB-04 auto-detect miss → warn + omit (no bare email)"
    - path: "tests/phase-09/test_ingest_contributor_explicit.sh"
      provides: "COLAB-04 --contributor flag overrides detection in both directions"
    - path: "tests/phase-09/test_search_contributor.sh"
      provides: "COLAB-07 search filter with @handle and bare handle forms"
    - path: "tests/phase-09/test_author_map_seed.sh"
      provides: "Verifies .git-author-map.txt committed at repo root with expected header"
  key_links:
    - from: "bin/check-privacy.sh"
      to: "bin/check-neutrality.sh pattern (PUBLIC_PATHS, parse_frontmatter_block, scan loop)"
      via: "pattern-twin structure — same flag conventions, same exit codes, same regex approach"
      pattern: "PUBLIC_PATHS="
    - from: "bin/ingest.sh contributor:: emission"
      to: ".git-author-map.txt at repo root"
      via: "parse_author_map() + git config user.email lookup"
      pattern: "\\.git-author-map\\.txt"
    - from: "bin/search.sh --contributor"
      to: "wiki/log.md `contributor:: @handle` inline fields"
      via: "grep-based filter on log.md content"
      pattern: "contributor::"
---

<objective>
Three independent script additions, bundled in one plan because they share the `.git-author-map.txt` contract and can be parallelized against Plan 02/03 (lint additions):

1. **`bin/check-privacy.sh`** — standalone CI-07 privacy-leak guard (D-12), pattern-twin of Phase 7's `bin/check-neutrality.sh`. Scans `PUBLIC_PATHS` frontmatter ONLY for `privacy: local_only`. `wiki/**` is explicitly excluded (valid user content per AGENTS.md §13).
2. **`bin/ingest.sh --contributor <handle>`** (COLAB-04) — emits `contributor:: @handle` in `wiki/log.md`. Auto-detects via `git config user.email` + `.git-author-map.txt`. Single-author repos omit the field entirely (D-20). Auto-detect misses never write bare email (D-21 + Pitfall 5).
3. **`bin/search.sh --contributor <handle>`** (COLAB-07) — filter `wiki/log.md` entries by handle. Accepts both `@octocat` and `octocat` forms.

Purpose: These three scripts plus `.git-author-map.txt` are the **contributor-attribution primitives** that Plan 05's workflow YAML invokes (`bash bin/check-privacy.sh` as the `privacy-leak` CI job). COLAB-03 (AGENTS.md §12 amendment documenting `contributor:: @handle` inline field) is intentionally deferred to Plan 05 alongside the §11.1 / §11.3 amendments — this plan ships the code; Plan 05 ships the canonical documentation that matches the code.

Output: 3 new/modified bash scripts + 1 data file + 8 tests. Zero new runtime dependencies.

Out of scope: CI workflow YAML (Plan 05), AGENTS.md amendments (Plan 05), CONTRIBUTING.md (Plan 06).
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-CONTEXT.md
@.planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-RESEARCH.md
@.planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-01-SUMMARY.md
@bin/check-neutrality.sh
@bin/ingest.sh
@bin/search.sh
@tests/phase-09/lib.sh
@tests/phase-09/fixtures/privacy-leak-public/docs/sample.md
@tests/phase-09/fixtures/privacy-ok-wiki/wiki/local.md
@tests/phase-09/fixtures/contributor-multi/.git-author-map.txt

<interfaces>
From bin/check-neutrality.sh (pattern to replicate):

```bash
PUBLIC_PATHS=(AGENTS.md CLAUDE.md README.md PRIVACY.md docs .github wiki bin)
# Note: wiki/ IS in check-neutrality's list. bin/check-privacy.sh MUST EXCLUDE wiki/
# because local_only is valid user content per AGENTS.md §13 / CONTEXT.md D-15.

parse_frontmatter_block() {
    # extracts text between first two `^---` markers
}
```

From AGENTS.md §13 (privacy tiers — `wiki/**` carries `local_only` validly):

> local_only -- NEVER sent to cloud APIs. Processed only by local models.
> cloud_safe -- May be sent to cloud APIs.

From CONTEXT.md D-14 + D-15 (privacy scan rules):
- Frontmatter-only match (`^privacy:\s*local_only\s*$` inside `^---` block)
- PUBLIC_PATHS: `examples docs AGENTS.md CLAUDE.md README.md .github`
- `wiki/**` explicitly EXCLUDED

From CONTEXT.md D-19..D-21 (contributor field):
- Handle format: `@github-handle`
- Single-author detection: `git log --all --format='%ae' | sort -u | wc -l == 1`
- Map file: `.git-author-map.txt` at repo root; `email  ->  @handle`; `#` comments; case-insensitive email
- On miss: warn stderr + omit field (never bare email)

From bin/ingest.sh current flow:
- Creates dated directory in `sources/YYYY/YYYY-MM/YYYY-MM-DD-slug/`
- Computes SHA-256
- Prints ready-to-ingest instructions to stdout
- **Does NOT currently write wiki/log.md** — this is LLM-agent work per D-11/D-12/D-13
- Phase 9 `--contributor` must slot into the instructions printed to stdout OR emit a log.md append block the LLM agent can copy-paste

**Integration decision (locked 2026-04-16 after reading `bin/ingest.sh` end-to-end):**

`bin/ingest.sh` DOES NOT write `wiki/log.md` directly. The current 252-line script:

1. Parses args, validates source file, derives slug, computes UTC date.
2. Creates `sources/YYYY/YYYY-MM/YYYY-MM-DD-slug/` and copies the source in.
3. Computes SHA-256 content_hash.
4. Prints an ingest-instructions stdout block (`=== Ready to Ingest ===`) with source metadata — the LLM agent follows AGENTS.md §11.1 to write `wiki/sources/<id>.md`, update topic pages, and append `wiki/log.md`.

Phase 9's `--contributor` flag therefore **augments the printed stdout template** (integration path (a) per the Codex MEDIUM review). Specifically: the resolved `contributor:: @handle` line is emitted to stdout inside a log-entry template block that the LLM agent copies verbatim into `wiki/log.md` directly below the `## [YYYY-MM-DD] ingest | ...` header.

The test assertions in this plan inspect `bin/ingest.sh` stdout for the literal string `contributor:: @<handle>`. No test attempts to verify `wiki/log.md` mutation — `bin/ingest.sh` does not mutate it. The field lands in `wiki/log.md` via the LLM agent's paste of the printed template, per AGENTS.md §11.1.

From bin/search.sh existing flag-parse convention:
- Supports `--paths-only`, `--fulltext`, `--query`, plus positional keyword
- Exit 0 on success (including no results)
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Create bin/check-privacy.sh (standalone CI-07 privacy-leak guard) + 3 fixture tests</name>
  <files>bin/check-privacy.sh, tests/phase-09/test_check_privacy_clean.sh, tests/phase-09/test_check_privacy_leak.sh, tests/phase-09/test_check_privacy_wiki_ok.sh</files>
  <read_first>
    - bin/check-neutrality.sh — ENTIRE file (393 lines). This is the pattern-twin reference for every decision: flag conventions, PUBLIC_PATHS array placement, parse_frontmatter_block function, exit codes (0 clean / 1 script-error / 2 guard-hit), stderr vs stdout conventions
    - .planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-CONTEXT.md — D-12..D-15 (standalone script rationale, full-tree scan, frontmatter-only, hardcoded PUBLIC_PATHS)
    - .planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-RESEARCH.md — §"Code Examples" #3 (Python scanner skeleton with exact regex)
    - AGENTS.md §13 — privacy tiers (for the `wiki/` exclusion rationale to embed in the script header)
    - tests/phase-09/fixtures/privacy-leak-public/docs/sample.md
    - tests/phase-09/fixtures/privacy-ok-wiki/wiki/local.md
    - tests/phase-09/lib.sh
  </read_first>
  <behavior>
    - Test 1 (test_check_privacy_clean.sh): On a clean repo (no `privacy: local_only` in frontmatter of any public path), `bash bin/check-privacy.sh` exits 0 with empty stdout.
    - Test 2 (test_check_privacy_leak.sh): On `privacy-leak-public` fixture (docs/sample.md has `privacy: local_only` in frontmatter), `bash bin/check-privacy.sh` exits 2, stderr contains `docs/sample.md:N: privacy: local_only` (N = line number).
    - Test 3 (test_check_privacy_wiki_ok.sh): On `privacy-ok-wiki` fixture (wiki/local.md has `privacy: local_only` in frontmatter), `bash bin/check-privacy.sh` exits 0 (wiki/** excluded per D-15).
    - Test 4 (within test_check_privacy_leak.sh): Body-text mention of `privacy: local_only` inside prose (NOT frontmatter) in `docs/` does NOT trigger exit 2 (D-14 frontmatter-only rule).
  </behavior>
  <action>
**Step 1: Create `bin/check-privacy.sh`.**

Full script (~120 lines following `bin/check-neutrality.sh` structure):

```bash
#!/usr/bin/env bash
# bin/check-privacy.sh -- CI-07 privacy-leak guard.
# Scans YAML frontmatter under PUBLIC_PATHS for `privacy: local_only`.
# Pattern-twin of bin/check-neutrality.sh (Phase 7 NEUT-06).
#
# Rationale: `local_only` is a valid user-content tier inside `wiki/**`
# (AGENTS.md §13). This guard prevents it from LEAKING into public-facing
# surfaces that ship in the template repo. Changing PUBLIC_PATHS requires
# a PR — the correct review loop for scope changes.
#
# Full-tree scan (D-13) — no diff-only mode. Catches pre-existing leaks.
# Frontmatter-only (D-14) — prose mentions in body text are not flagged.
#
# Exit codes:
#   0  clean — no leaks
#   1  script failure (missing python3, bad args)
#   2  privacy-leak found
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: bin/check-privacy.sh [OPTIONS]

Scans public control-plane paths for `privacy: local_only` frontmatter leaks.

Options:
  --root DIR              Scan root (default: PWD)
  --format text|json      Output format (default: text; json → stdout array)
  --help, -h              Show this help

Scope (D-15):
  PUBLIC_PATHS scanned: examples/, docs/, AGENTS.md, CLAUDE.md, README.md, PRIVACY.md, .github/
  EXPLICITLY EXCLUDED:  wiki/** (local_only is valid user content per AGENTS.md §13)

Exit codes:
  0  clean
  1  script failure
  2  privacy-leak found
EOF
}

ROOT="${PWD}"
FORMAT="text"

while [ "$#" -gt 0 ]; do
    case "$1" in
        --help|-h) usage; exit 0 ;;
        --root)
            if [ "$#" -lt 2 ]; then
                echo "ERROR: --root requires a value" >&2; exit 1
            fi
            ROOT="$2"; shift 2 ;;
        --format)
            if [ "$#" -lt 2 ]; then
                echo "ERROR: --format requires a value (text or json)" >&2; exit 1
            fi
            case "$2" in
                text|json) FORMAT="$2" ;;
                *) echo "ERROR: --format must be 'text' or 'json'" >&2; exit 1 ;;
            esac
            shift 2 ;;
        -*) echo "ERROR: unknown option: $1" >&2; usage >&2; exit 1 ;;
        *)  echo "ERROR: unexpected argument: $1" >&2; exit 1 ;;
    esac
done

# D-15: hardcoded PUBLIC_PATHS. wiki/** EXCLUDED.
# PRIVACY.md included (Gemini LOW review fix, 2026-04-16) — parity with bin/check-neutrality.sh;
# PRIVACY.md exists at repo root as a top-level public doc.
# Changing this array requires a PR (intentional review lever).
PUBLIC_PATHS=(examples docs AGENTS.md CLAUDE.md README.md PRIVACY.md .github)

# Export env for python3 heredoc (no jq dependency, consistent with Phase 7/8 pattern)
export CP_ROOT="$ROOT"
export CP_FORMAT="$FORMAT"
export CP_PUBLIC_PATHS="$(IFS=:; echo "${PUBLIC_PATHS[*]}")"

python3 - <<'PYEOF'
import os, re, sys, json

ROOT = os.path.abspath(os.environ['CP_ROOT'])
FORMAT = os.environ.get('CP_FORMAT', 'text')
PUBLIC_PATHS = os.environ['CP_PUBLIC_PATHS'].split(':')

# D-14: match `privacy: local_only` ONLY within `^---...^---` frontmatter block
PRIVACY_LOCAL_ONLY_RE = re.compile(r'^privacy:\s*local_only\s*$', re.M)

def parse_frontmatter_block(text):
    """Return frontmatter text between first two `^---` markers, or None."""
    if not text.startswith('---'):
        return None
    # Find closing `---` on its own line
    m = re.search(r'\n---\s*$|\n---\s*\n', text, re.M)
    if not m:
        return None
    return text[3:m.start()]

def scan():
    hits = []
    for rel in PUBLIC_PATHS:
        full = os.path.join(ROOT, rel)
        if not os.path.exists(full):
            continue
        targets = []
        if os.path.isfile(full):
            if full.endswith('.md'):
                targets.append(full)
        else:
            for dirpath, dirnames, files in os.walk(full):
                # Prune common junk
                dirnames[:] = [d for d in dirnames if d not in ('.git', 'node_modules')]
                for fn in files:
                    if fn.endswith('.md'):
                        targets.append(os.path.join(dirpath, fn))
        for t in targets:
            try:
                content = open(t, encoding='utf-8', errors='replace').read()
            except OSError:
                continue
            fm = parse_frontmatter_block(content)
            if fm is None:
                continue
            m = PRIVACY_LOCAL_ONLY_RE.search(fm)
            if not m:
                continue
            # Compute line number within frontmatter block (add 1 for opening ---, +1 for 1-indexed)
            line_within_fm = fm[:m.start()].count('\n') + 1
            abs_line = line_within_fm + 1  # +1 for opening `---` line
            hits.append({
                'path': os.path.relpath(t, ROOT),
                'line': abs_line,
                'message': 'privacy: local_only in public path (CI-07)',
            })
    hits.sort(key=lambda h: (h['path'], h['line']))
    if FORMAT == 'json':
        print(json.dumps(hits, indent=2))
    else:
        for h in hits:
            print(f"{h['path']}:{h['line']}: privacy: local_only leaked into public path", file=sys.stderr)
    sys.exit(2 if hits else 0)

scan()
PYEOF
```

Mark executable: `chmod +x bin/check-privacy.sh`.

**Step 2: Write three tests.**

`tests/phase-09/test_check_privacy_clean.sh`:

```bash
#!/usr/bin/env bash
# CI-07: bin/check-privacy.sh exits 0 on clean repo.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

# Use real repo root; must be clean by project invariant
bash "$REPO_ROOT/bin/check-privacy.sh" --root "$REPO_ROOT" \
    || { echo "FAIL: check-privacy should exit 0 on clean repo" >&2; exit 1; }
echo "PASS: check-privacy clean repo exit 0"
```

`tests/phase-09/test_check_privacy_leak.sh`:

```bash
#!/usr/bin/env bash
# CI-07: privacy: local_only in docs/ (public path) frontmatter → exit 2.
# Prose-body mention in docs/ → exit 0 (frontmatter-only rule, D-14).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

FIXTURE="$(make_fixture_repo privacy-leak-public)"
trap 'cleanup_fixture_repo "$FIXTURE"' EXIT

# 1. Leak case: exit 2 with stderr path:line:
if bash "$REPO_ROOT/bin/check-privacy.sh" --root "$FIXTURE" 2>/tmp/pv-err >/dev/null; then
    echo "FAIL: privacy: local_only in docs/ frontmatter should exit 2" >&2
    exit 1
fi
# Confirm exit code 2 specifically (not 1)
bash "$REPO_ROOT/bin/check-privacy.sh" --root "$FIXTURE" 2>/dev/null; RC=$?
if [ "$RC" != "2" ]; then
    echo "FAIL: expected exit 2, got $RC" >&2; exit 1
fi
grep -q "docs/sample.md" /tmp/pv-err \
    || { echo "FAIL: stderr should name docs/sample.md: $(cat /tmp/pv-err)" >&2; exit 1; }
grep -qE "docs/sample.md:[0-9]+:" /tmp/pv-err \
    || { echo "FAIL: stderr should include path:line: format" >&2; exit 1; }

# 2. Body-text mention does NOT trigger (D-14 frontmatter-only)
cat > "$FIXTURE/docs/prose-mention.md" <<'BODY'
# --- frontmatter delimiter (escaped for doc-parser)
id: prose-mention
title: Prose Mention
type: concept
privacy: cloud_safe
# --- frontmatter delimiter (escaped for doc-parser)

This paragraph discusses the `privacy: local_only` tier in prose.
It is NOT a frontmatter leak and MUST NOT trigger the guard.
BODY
# Remove the actual leak so we're only testing the prose case
rm "$FIXTURE/docs/sample.md"

bash "$REPO_ROOT/bin/check-privacy.sh" --root "$FIXTURE" 2>/dev/null \
    || { echo "FAIL: prose-only mention should NOT trigger guard (D-14)" >&2; exit 1; }

echo "PASS: check-privacy leak detection + frontmatter-only rule"
```

`tests/phase-09/test_check_privacy_wiki_ok.sh`:

```bash
#!/usr/bin/env bash
# CI-07: wiki/** local_only IS valid user content (AGENTS.md §13); exit 0.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

FIXTURE="$(make_fixture_repo privacy-ok-wiki)"
trap 'cleanup_fixture_repo "$FIXTURE"' EXIT

bash "$REPO_ROOT/bin/check-privacy.sh" --root "$FIXTURE" \
    || { echo "FAIL: wiki/** privacy: local_only should be exempt (D-15)" >&2; exit 1; }

echo "PASS: check-privacy exempts wiki/** (D-15)"
```

All tests executable.
  </action>
  <verify>
    <automated>bash tests/phase-09/test_check_privacy_clean.sh && bash tests/phase-09/test_check_privacy_leak.sh && bash tests/phase-09/test_check_privacy_wiki_ok.sh</automated>
  </verify>
  <acceptance_criteria>
    - `test -x bin/check-privacy.sh` (executable)
    - `grep -q "PUBLIC_PATHS=" bin/check-privacy.sh` returns 0
    - `grep -q "examples docs AGENTS.md CLAUDE.md README.md PRIVACY.md .github" bin/check-privacy.sh` returns 0 (exact public-paths list; PRIVACY.md included per Gemini LOW review fix)
    - `! grep -qw "wiki" bin/check-privacy.sh | head -1` — `wiki` does NOT appear as a bare word in `PUBLIC_PATHS=(...)` array definition (use `grep -E '^PUBLIC_PATHS=\(' bin/check-privacy.sh` to confirm no `wiki` in that line)
    - `bash bin/check-privacy.sh --help` prints usage and exits 0
    - `bash bin/check-privacy.sh` (on real repo) exits 0 (invariant: project has no leaks)
    - `bash bin/check-privacy.sh --format json` (on real repo) outputs `[]` to stdout and exits 0
    - `bash bin/check-privacy.sh --root <privacy-leak-public fixture>` exits 2 with `docs/sample.md:N:` on stderr
    - `bash bin/check-privacy.sh --root <privacy-ok-wiki fixture>` exits 0 (wiki/** valid)
    - Frontmatter-only rule honored: body-text mention of `privacy: local_only` in `docs/prose-mention.md` does NOT trigger exit 2
    - All 3 tests exit 0
  </acceptance_criteria>
  <done>
    `bin/check-privacy.sh` is a pattern-twin of `bin/check-neutrality.sh` — same exit codes (0/1/2), same flag conventions, same frontmatter-block extraction, same stderr-on-match convention. Plan 05's `privacy-leak` CI job invokes `bash bin/check-privacy.sh` as its sole step.
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Add --contributor flag + single-author detection + .git-author-map.txt to bin/ingest.sh; seed .git-author-map.txt at repo root</name>
  <files>bin/ingest.sh, .git-author-map.txt, tests/phase-09/test_ingest_single_author.sh, tests/phase-09/test_ingest_auto_detect.sh, tests/phase-09/test_ingest_auto_detect_miss.sh, tests/phase-09/test_ingest_contributor_explicit.sh, tests/phase-09/test_author_map_seed.sh</files>
  <read_first>
    - bin/ingest.sh — ENTIRE file (252 lines). Locate: (a) the arg-parse loop, (b) the point where the log-entry template is emitted to stdout or file, (c) usage() help
    - .planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-CONTEXT.md — D-19, D-20, D-21 (handle format, single-author detection, resolution flow including ORDER: git config → map lookup → on-hit/on-miss behavior)
    - .planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-RESEARCH.md — §"Pitfall 5" (no bare email), §"Specific Ideas" (`.git-author-map.txt` format: `email  ->  @handle`, `#` comments, case-insensitive)
    - tests/phase-09/fixtures/contributor-multi/.git-author-map.txt — the format example to replicate
    - tests/phase-09/lib.sh — `setup_git_author` helper
  </read_first>
  <behavior>
    - Test 5 (test_ingest_single_author.sh): On single-author fixture, running `bin/ingest.sh <fake-source>` (no --contributor flag) emits an ingest-instructions block whose log-entry template does NOT contain `contributor::` (single-author auto-omit per D-20).
    - Test 6 (test_ingest_auto_detect.sh): On multi-author fixture with `.git-author-map.txt: alice@example.com -> @alice` and `git config user.email alice@example.com`, `bin/ingest.sh <fake-source>` emits a log-entry template containing `contributor:: @alice`.
    - Test 7 (test_ingest_auto_detect_miss.sh): Same multi-author fixture, but `git config user.email unknown@example.com` (NOT in map). `bin/ingest.sh <fake-source>` emits log-entry template WITHOUT `contributor::` (field omitted) AND writes a warning to stderr that contains all three strings: `unknown@example.com`, `--contributor`, `.git-author-map.txt`.
    - Test 8 (test_ingest_contributor_explicit.sh, multi-author override): On multi-author fixture, `bin/ingest.sh --contributor @different-handle <fake-source>` emits `contributor:: @different-handle` (explicit flag wins over auto-detect).
    - Test 9 (test_ingest_contributor_explicit.sh, single-author force): On single-author fixture, `bin/ingest.sh --contributor @someone <fake-source>` emits `contributor:: @someone` (explicit flag forces emission even on single-author).
    - Test 10 (test_author_map_seed.sh): `.git-author-map.txt` exists at repo root, contains a header comment starting with `#` and documenting format, and is committed (tracked by git).
    - Pitfall 5 guard (within all tests): Output MUST NOT contain `contributor:: <bare-email>` under any circumstance (no `contributor:: user@example.com`).
  </behavior>
  <action>
**Step 1: Understand `bin/ingest.sh` emission point.**

Read the file end-to-end. Locate: (a) the place where the script prints ingest instructions to stdout (template block for the LLM agent to follow). Identify the EXACT line where a `contributor::` field should appear if one is needed. Typically this is inside a here-doc or printf block rendering the log-entry template like:

```
## [2026-04-16] ingest | <source title>

<what was done, affected pages, rationale>
```

Phase 9 adds an optional `contributor:: @handle` line INSIDE the log-entry template, directly below the `## [YYYY-MM-DD]` header.

**Step 2: Add `--contributor` flag + resolution logic to `bin/ingest.sh`.**

Add to arg-parse defaults: `CONTRIBUTOR=""`. In arg-parse loop:

```bash
        --contributor)
            if [ "$#" -lt 2 ]; then
                echo "ERROR: --contributor requires a value (e.g., @octocat)" >&2
                exit 1
            fi
            CONTRIBUTOR="$2"
            # Normalize: ensure leading @
            case "$CONTRIBUTOR" in
                @*) : ;;
                *)  CONTRIBUTOR="@$CONTRIBUTOR" ;;
            esac
            shift 2
            ;;
```

After arg-parse, add the resolution function (bash):

```bash
# D-19..D-21: resolve contributor handle.
# Order:
#   1. If --contributor <handle> provided, use it verbatim.
#   2. Else if single-author (git log --all --format='%ae' | sort -u | wc -l == 1), omit field.
#   3. Else look up `git config user.email` in .git-author-map.txt (case-insensitive).
#   4. On map hit, use mapped @handle.
#   5. On map miss, warn stderr + OMIT field (D-21: never write bare email).
resolve_contributor() {
    local repo_root="${1:-$PWD}"
    local explicit="$CONTRIBUTOR"
    if [ -n "$explicit" ]; then
        echo "$explicit"
        return 0
    fi
    # D-20 single-author detection
    local author_count
    author_count="$(cd "$repo_root" && git log --all --format='%ae' 2>/dev/null | sort -u | wc -l | tr -d ' ')"
    if [ "${author_count:-0}" -le 1 ]; then
        # Single-author: omit
        return 0
    fi
    # Multi-author: look up email in map
    local email
    email="$(cd "$repo_root" && git config user.email 2>/dev/null || true)"
    if [ -z "$email" ]; then
        echo "WARN: no git config user.email; omitting contributor:: field" >&2
        echo "      Set with: git config user.email <your-email>" >&2
        echo "      Or use: bin/ingest.sh --contributor @your-handle ..." >&2
        return 0
    fi
    local email_lc
    email_lc="$(echo "$email" | tr '[:upper:]' '[:lower:]')"
    local map="$repo_root/.git-author-map.txt"
    if [ ! -f "$map" ]; then
        echo "WARN: no .git-author-map.txt at repo root; cannot resolve $email to @handle" >&2
        echo "      Omitting contributor:: field." >&2
        echo "      Fix: add line '$email  ->  @your-handle' to .git-author-map.txt" >&2
        echo "      Or: re-run with --contributor @your-handle" >&2
        return 0
    fi
    local handle
    handle="$(
        grep -v '^\s*#' "$map" | grep -v '^\s*$' | while IFS= read -r line; do
            # Accept separator "  ->  " or tab
            if [[ "$line" == *"  ->  "* ]]; then
                left="${line%%  ->  *}"
                right="${line##*  ->  }"
            elif [[ "$line" == *$'\t'* ]]; then
                left="${line%%$'\t'*}"
                right="${line##*$'\t'}"
            else
                continue
            fi
            left_lc="$(echo "$left" | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
            right_trimmed="$(echo "$right" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
            if [ "$left_lc" = "$email_lc" ]; then
                echo "$right_trimmed"
                break
            fi
        done
    )"
    if [ -n "$handle" ]; then
        echo "$handle"
        return 0
    fi
    # D-21 Pitfall 5 guard: NEVER write bare email
    echo "WARN: no mapping for $email in .git-author-map.txt; omitting contributor:: field" >&2
    echo "      Fix: add line '$email  ->  @your-handle' to .git-author-map.txt" >&2
    echo "      Or: re-run with --contributor @your-handle" >&2
    return 0
}

RESOLVED_CONTRIBUTOR="$(resolve_contributor "$(pwd)")"
```

**Step 3: Emit `contributor::` into log-entry template.**

Find where `bin/ingest.sh` prints the log-entry template. Augment that block:

```bash
# After the `## [YYYY-MM-DD] ingest | <title>` header emission:
if [ -n "$RESOLVED_CONTRIBUTOR" ]; then
    echo "contributor:: $RESOLVED_CONTRIBUTOR"
    echo ""
fi
```

The exact insertion depends on current template shape — planner reads `bin/ingest.sh`, identifies the single-source emission point, and inserts accordingly. Do NOT fabricate an additional emission site; use whatever path already prints the log entry.

Update `usage()`:

```
  --contributor <handle>  Explicit contributor @handle for the log entry.
                          Auto-detects from git config user.email +
                          .git-author-map.txt if omitted. Single-author
                          repos auto-omit the field.
```

**Step 4: Seed `.git-author-map.txt` at repo root (committed).**

Create `/home/yishai/Documents/life/.git-author-map.txt`:

```
# .git-author-map.txt -- email -> GitHub handle map for bin/ingest.sh auto-detect.
#
# Format: "<email>  ->  @<github-handle>"
#   - Two-space-arrow-two-space separator (or a single tab)
#   - One mapping per line
#   - Comments start with #
#   - Email match is case-insensitive
#
# Single-author repos can leave this file empty with just this header —
# bin/ingest.sh detects single-author (git log --all --format='%ae' | sort -u | wc -l == 1)
# and omits the contributor:: field entirely. Multi-author repos add mappings
# as contributors onboard.
#
# Example:
#   octocat@github.com  ->  @octocat
```

(No actual mappings — ships empty. Contributors populate as they onboard.)

**Step 5: Write five tests.**

`tests/phase-09/test_ingest_single_author.sh`:

```bash
#!/usr/bin/env bash
# COLAB-04 / D-20: single-author repo auto-omits contributor:: field.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

FIXTURE="$(make_fixture_repo contributor-single)"
trap 'cleanup_fixture_repo "$FIXTURE"' EXIT
pushd "$FIXTURE" >/dev/null

# Create a fake source file
mkdir -p /tmp/src-test
echo "# test source" > /tmp/src-test/source.md

OUT="$(bash "$REPO_ROOT/bin/ingest.sh" /tmp/src-test/source.md 2>&1 || true)"

# Must NOT contain contributor::
if echo "$OUT" | grep -q "contributor::"; then
    echo "FAIL: single-author repo should omit contributor::" >&2
    echo "$OUT" >&2
    popd >/dev/null; exit 1
fi
# Pitfall 5 guard: no bare email
if echo "$OUT" | grep -qE "contributor:: [^@]"; then
    echo "FAIL: bare email leaked into contributor:: field (D-21 Pitfall 5)" >&2
    popd >/dev/null; exit 1
fi

popd >/dev/null
rm -rf /tmp/src-test
echo "PASS: single-author omits contributor::"
```

`tests/phase-09/test_ingest_auto_detect.sh`:

```bash
#!/usr/bin/env bash
# COLAB-04: multi-author + git config email in map → auto-detect @handle.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

FIXTURE="$(make_fixture_repo contributor-multi)"
trap 'cleanup_fixture_repo "$FIXTURE"' EXIT

# Seed 2 authors so git log has > 1 unique email
setup_git_author "$FIXTURE" "Alice" "alice@example.com"
setup_git_author "$FIXTURE" "Bob" "bob@example.com"

pushd "$FIXTURE" >/dev/null
git config user.email "alice@example.com"

mkdir -p /tmp/src-test2
echo "# test" > /tmp/src-test2/source.md

OUT="$(bash "$REPO_ROOT/bin/ingest.sh" /tmp/src-test2/source.md 2>&1 || true)"

echo "$OUT" | grep -q "contributor:: @alice" \
    || { echo "FAIL: expected 'contributor:: @alice', got:" >&2; echo "$OUT" >&2; popd >/dev/null; exit 1; }

popd >/dev/null
rm -rf /tmp/src-test2
echo "PASS: auto-detect via .git-author-map.txt hit"
```

`tests/phase-09/test_ingest_auto_detect_miss.sh`:

```bash
#!/usr/bin/env bash
# COLAB-04 / D-21 / Pitfall 5: map miss → warn + omit (never bare email).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

FIXTURE="$(make_fixture_repo contributor-multi)"
trap 'cleanup_fixture_repo "$FIXTURE"' EXIT

setup_git_author "$FIXTURE" "Alice" "alice@example.com"
setup_git_author "$FIXTURE" "Bob" "bob@example.com"

pushd "$FIXTURE" >/dev/null
# Charlie is NOT in the map
git config user.email "charlie@example.com"
setup_git_author "$FIXTURE" "Charlie" "charlie@example.com"

mkdir -p /tmp/src-test3
echo "# test" > /tmp/src-test3/source.md

OUT="$(bash "$REPO_ROOT/bin/ingest.sh" /tmp/src-test3/source.md 2>/tmp/ingest-err || true)"

# No contributor:: line
if echo "$OUT" | grep -q "contributor::"; then
    echo "FAIL: map miss should omit contributor::" >&2
    popd >/dev/null; exit 1
fi
# Pitfall 5: no bare email anywhere
if echo "$OUT" | grep -qE "contributor:: [^@]"; then
    echo "FAIL: bare email leaked (Pitfall 5)" >&2
    popd >/dev/null; exit 1
fi
if grep -q "contributor:: charlie@example.com" /tmp/ingest-err; then
    echo "FAIL: email leaked to stderr as contributor::" >&2
    popd >/dev/null; exit 1
fi
# stderr must contain 3 actionable tokens
grep -q "charlie@example.com" /tmp/ingest-err \
    || { echo "FAIL: stderr missing email" >&2; popd >/dev/null; exit 1; }
grep -q -- "--contributor" /tmp/ingest-err \
    || { echo "FAIL: stderr missing --contributor suggestion" >&2; popd >/dev/null; exit 1; }
grep -q "\.git-author-map.txt" /tmp/ingest-err \
    || { echo "FAIL: stderr missing .git-author-map.txt suggestion" >&2; popd >/dev/null; exit 1; }

popd >/dev/null
rm -rf /tmp/src-test3
echo "PASS: map miss → warn + omit (no bare email)"
```

`tests/phase-09/test_ingest_contributor_explicit.sh`:

```bash
#!/usr/bin/env bash
# COLAB-04 / D-20: --contributor overrides detection in both directions.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

# Multi-author: explicit flag overrides map lookup
FIXTURE="$(make_fixture_repo contributor-multi)"
trap 'cleanup_fixture_repo "$FIXTURE"' EXIT
setup_git_author "$FIXTURE" "Alice" "alice@example.com"
setup_git_author "$FIXTURE" "Bob" "bob@example.com"
pushd "$FIXTURE" >/dev/null
git config user.email "alice@example.com"  # would map to @alice

mkdir -p /tmp/src-test4
echo "# test" > /tmp/src-test4/source.md

# Override with @other
OUT="$(bash "$REPO_ROOT/bin/ingest.sh" --contributor @other /tmp/src-test4/source.md 2>&1 || true)"
echo "$OUT" | grep -q "contributor:: @other" \
    || { echo "FAIL: explicit --contributor @other should override" >&2; echo "$OUT" >&2; popd >/dev/null; exit 1; }
# Not @alice
if echo "$OUT" | grep -q "contributor:: @alice"; then
    echo "FAIL: explicit flag should win over map" >&2
    popd >/dev/null; exit 1
fi
popd >/dev/null
cleanup_fixture_repo "$FIXTURE"

# Single-author: explicit flag forces emit
FIX2="$(make_fixture_repo contributor-single)"
trap 'cleanup_fixture_repo "$FIX2"' EXIT
pushd "$FIX2" >/dev/null
OUT2="$(bash "$REPO_ROOT/bin/ingest.sh" --contributor @forced /tmp/src-test4/source.md 2>&1 || true)"
echo "$OUT2" | grep -q "contributor:: @forced" \
    || { echo "FAIL: explicit --contributor should force emit on single-author" >&2; echo "$OUT2" >&2; popd >/dev/null; exit 1; }
popd >/dev/null
rm -rf /tmp/src-test4

# Bare handle accepted (no @) → normalized to @
FIX3="$(make_fixture_repo contributor-multi)"
trap 'cleanup_fixture_repo "$FIX3"' EXIT
setup_git_author "$FIX3" "X" "x@e.com"
setup_git_author "$FIX3" "Y" "y@e.com"
pushd "$FIX3" >/dev/null
mkdir -p /tmp/src-test5; echo "# t" > /tmp/src-test5/source.md
OUT3="$(bash "$REPO_ROOT/bin/ingest.sh" --contributor bare /tmp/src-test5/source.md 2>&1 || true)"
echo "$OUT3" | grep -q "contributor:: @bare" \
    || { echo "FAIL: bare handle should normalize to @bare" >&2; echo "$OUT3" >&2; popd >/dev/null; exit 1; }
popd >/dev/null
rm -rf /tmp/src-test5

echo "PASS: --contributor overrides + bare-handle normalization"
```

`tests/phase-09/test_author_map_seed.sh`:

```bash
#!/usr/bin/env bash
# Verify .git-author-map.txt committed at repo root with expected header.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

MAP="$REPO_ROOT/.git-author-map.txt"
test -f "$MAP" || { echo "FAIL: .git-author-map.txt missing at repo root" >&2; exit 1; }
# Must be tracked by git (not gitignored)
(cd "$REPO_ROOT" && git ls-files --error-unmatch .git-author-map.txt >/dev/null 2>&1) \
    || { echo "FAIL: .git-author-map.txt is not tracked by git" >&2; exit 1; }
# Header documents format
grep -q "email" "$MAP" || { echo "FAIL: header missing 'email' keyword" >&2; exit 1; }
grep -q "@" "$MAP" || { echo "FAIL: header missing '@' in format example" >&2; exit 1; }
grep -q "^#" "$MAP" || { echo "FAIL: no '#' comment lines (header missing)" >&2; exit 1; }
echo "PASS: .git-author-map.txt seeded with header"
```

All tests executable.
  </action>
  <verify>
    <automated>bash tests/phase-09/test_author_map_seed.sh && bash tests/phase-09/test_ingest_single_author.sh && bash tests/phase-09/test_ingest_auto_detect.sh && bash tests/phase-09/test_ingest_auto_detect_miss.sh && bash tests/phase-09/test_ingest_contributor_explicit.sh</automated>
  </verify>
  <acceptance_criteria>
    - `test -f .git-author-map.txt` at repo root
    - `grep -q "email" .git-author-map.txt` (header documents format)
    - `grep -q "^#" .git-author-map.txt` (comment lines present)
    - `git ls-files --error-unmatch .git-author-map.txt` succeeds (committed)
    - `grep -q "^CONTRIBUTOR=" bin/ingest.sh` returns 0 (default)
    - `grep -q "resolve_contributor" bin/ingest.sh` returns 0 (function defined)
    - `grep -q "\.git-author-map\.txt" bin/ingest.sh` returns 0 (map lookup)
    - `grep -q "git log --all --format='%ae'" bin/ingest.sh` returns 0 (single-author detection)
    - `bash bin/ingest.sh --help` lists `--contributor`
    - All 5 tests exit 0
    - Pitfall 5 guard: no test output (stdout OR stderr) contains `contributor:: <bare-email>` — `grep -qE "contributor:: [^@]" <any-test-output>` must never match
    - Bare handle (no leading `@`) passed via `--contributor` normalizes to `@bare` in emitted log entry
  </acceptance_criteria>
  <done>
    `bin/ingest.sh --contributor` works in all four cases: explicit-override, single-author-auto-omit, multi-author-map-hit, multi-author-map-miss-warn-and-omit. `.git-author-map.txt` committed at repo root. Pitfall 5 guard enforced by test. Plan 05 can reference this flag in the amended AGENTS.md §11.1 step.
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 3: Add --contributor filter to bin/search.sh</name>
  <files>bin/search.sh, tests/phase-09/test_search_contributor.sh</files>
  <read_first>
    - bin/search.sh — ENTIRE file (286 lines). Locate the arg-parse loop and the main search-mode dispatch
    - .planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-CONTEXT.md — COLAB-07 / Claude's Discretion (accept both `@handle` and bare)
    - tests/phase-09/lib.sh
  </read_first>
  <behavior>
    - Test L (test_search_contributor.sh, with @): Given `wiki/log.md` with entries tagged `contributor:: @alice` and `contributor:: @bob`, `bash bin/search.sh --contributor @alice` prints only the alice entry (or at least includes the alice header and does NOT include the bob entry).
    - Test M (test_search_contributor.sh, without @): `bash bin/search.sh --contributor alice` (leading @ stripped) returns the same result as Test L (ergonomic parity).
    - Test N (test_search_contributor.sh, no match): `bash bin/search.sh --contributor @nonexistent` exits 0 with `No results found for "@nonexistent"` or equivalent empty-result output (existing search.sh convention: exit 0 on no-results).
  </behavior>
  <action>
**Step 1: Add `--contributor` flag to `bin/search.sh` arg-parse.**

At top of arg-parse defaults: `CONTRIBUTOR_FILTER=""`. In arg-parse loop (BEFORE catch-all):

```bash
        --contributor)
            if [ "$#" -lt 2 ]; then
                echo "ERROR: --contributor requires a value (e.g., @octocat)" >&2
                exit 1
            fi
            CONTRIBUTOR_FILTER="$2"
            # Strip leading @ for internal matching (accept both forms)
            case "$CONTRIBUTOR_FILTER" in
                @*) CONTRIBUTOR_FILTER="${CONTRIBUTOR_FILTER#@}" ;;
            esac
            shift 2
            ;;
```

**Step 2: Add a search-mode branch for `--contributor`.**

After arg-parse, BEFORE the existing mode dispatch, insert:

```bash
if [ -n "$CONTRIBUTOR_FILTER" ]; then
    # COLAB-07: filter wiki/log.md entries whose contributor:: @handle matches.
    LOG="$WIKI_DIR/log.md"
    if [ ! -f "$LOG" ]; then
        echo "No results found for \"@$CONTRIBUTOR_FILTER\"" >&2
        exit 0
    fi
    # Extract log entries (separated by `## [YYYY-MM-DD]` headers) whose body
    # contains `contributor:: @<filter>` (case-sensitive; handles are case-sensitive).
    python3 - "$LOG" "$CONTRIBUTOR_FILTER" <<'PYEOF'
import sys, re
log_path = sys.argv[1]
handle = sys.argv[2]
content = open(log_path, encoding='utf-8').read()
# Split into entries at `## [` headers; keep the header with each entry
parts = re.split(r'(?m)^(?=## \[)', content)
matches = []
for p in parts:
    if not p.strip().startswith('## ['):
        continue
    if re.search(r'contributor::\s*@' + re.escape(handle) + r'\b', p):
        matches.append(p.rstrip())
if not matches:
    print(f'No results found for "@{handle}"', file=sys.stderr)
    sys.exit(0)
print("=== Contributor Results ===")
for m in matches:
    print(m)
    print("---")
print(f"=== {len(matches)} result(s) ===")
PYEOF
    exit 0
fi
```

Update `usage()`:

```
  --contributor <handle>  Filter wiki/log.md entries by contributor @handle.
                          Accepts both @octocat and octocat (leading @ optional).
```

**Step 3: Write test.**

`tests/phase-09/test_search_contributor.sh`:

```bash
#!/usr/bin/env bash
# COLAB-07: --contributor filters wiki/log.md; accepts @handle or bare.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

# Build a tiny temp wiki with a log.md containing two contributor entries
TMP="$(mktemp -d -t srch-ctrb-XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/wiki"
# search.sh resolves WIKI_INDEX; seed an empty index
echo "# Index" > "$TMP/wiki/index.md"

cat > "$TMP/wiki/log.md" <<'LOG'
# Activity Log

## [2026-04-16] ingest | alice-work

contributor:: @alice

Alice ingested a source.

## [2026-04-16] ingest | bob-work

contributor:: @bob

Bob ingested a source.
LOG

pushd "$TMP" >/dev/null

# 1. @alice → only alice entry
OUT1="$(bash "$REPO_ROOT/bin/search.sh" --contributor @alice 2>&1)"
echo "$OUT1" | grep -q "alice-work" \
    || { echo "FAIL: --contributor @alice should find alice-work" >&2; echo "$OUT1"; popd >/dev/null; exit 1; }
if echo "$OUT1" | grep -q "bob-work"; then
    echo "FAIL: --contributor @alice should NOT match bob-work" >&2
    popd >/dev/null; exit 1
fi

# 2. bare `alice` (no @) → same result
OUT2="$(bash "$REPO_ROOT/bin/search.sh" --contributor alice 2>&1)"
echo "$OUT2" | grep -q "alice-work" \
    || { echo "FAIL: bare handle 'alice' should match same as '@alice'" >&2; popd >/dev/null; exit 1; }

# 3. @nonexistent → no results (exit 0 per search.sh convention)
OUT3="$(bash "$REPO_ROOT/bin/search.sh" --contributor @nonexistent 2>&1 || true)"
echo "$OUT3" | grep -qi "No results found" \
    || { echo "FAIL: empty-result message missing" >&2; echo "$OUT3"; popd >/dev/null; exit 1; }

popd >/dev/null
echo "PASS: --contributor filter (leading @ optional, no-match graceful)"
```

Mark executable.
  </action>
  <verify>
    <automated>bash tests/phase-09/test_search_contributor.sh</automated>
  </verify>
  <acceptance_criteria>
    - `grep -q "CONTRIBUTOR_FILTER" bin/search.sh` returns 0
    - `bash bin/search.sh --help` lists `--contributor`
    - `bash bin/search.sh --contributor` (no value) exits 1 with stderr error
    - `bash bin/search.sh --contributor @unknown` exits 0 with empty-result message (not error 1)
    - Test exits 0; both `@handle` and bare `handle` forms produce identical filtered output
    - Exit 0 on no-matches (search.sh convention)
  </acceptance_criteria>
  <done>
    `bin/search.sh --contributor <handle>` filters log entries by handle with leading-@ tolerance. CONTRIBUTING.md (Plan 06) references this flag as the way to audit one contributor's log history.
  </done>
</task>

</tasks>

<verification>
- `bin/check-privacy.sh` exits 0 on clean repo, exit 2 on leak fixture, exit 0 on wiki/** local_only.
- `bin/ingest.sh --contributor` works in all 4 detection paths (single-author omit, auto-hit, auto-miss-warn, explicit-override).
- `bin/search.sh --contributor` filters log entries; accepts @ or bare; returns 0 on no-match.
- `.git-author-map.txt` committed at repo root with header comment.
- Pitfall 5 enforced across all tests (no bare email ever written to `contributor::`).
- All 8 new tests pass.
- Regression: `bash tests/phase-07/run.sh && bash tests/phase-08/run.sh` exit 0 (no existing behavior broken).
</verification>

<success_criteria>
Three scripts + one data file ship. Plan 05's `privacy-leak` CI job is a one-line step: `run: bash bin/check-privacy.sh`. CONTRIBUTING.md (Plan 06) references the `--contributor` flag, `.git-author-map.txt` format, and `bin/search.sh --contributor` usage.
</success_criteria>

<output>
After completion, create `.planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-04-SUMMARY.md` documenting: bin/check-privacy.sh exit-code contract, PUBLIC_PATHS array final contents, `.git-author-map.txt` format decisions (separator, case-insensitivity, comment handling), resolve_contributor() resolution order, Pitfall 5 enforcement evidence, and the 8 test files.
</output>

## Review Response

This plan was revised on 2026-04-16 in response to cross-AI review feedback (see `09-REVIEWS.md`).

### Accepted

| Reviewer | Severity | Concern | How Addressed |
|----------|----------|---------|---------------|
| Codex | MEDIUM | 09-04 T2 `bin/ingest.sh` integration hedged with an "alternative interpretation" note. Unresolved ambiguity would cause rework during implementation. | Read `bin/ingest.sh` end-to-end (252 lines). Committed to integration path (a): `bin/ingest.sh` prints stdout instructions; `--contributor` augments the printed log-entry template. Removed the hedge paragraph. Test assertions match path (a). |
| Gemini | LOW | `PRIVACY.md` missing from `PUBLIC_PATHS` — parity with `bin/check-neutrality.sh`. | Verified `PRIVACY.md` exists at repo root (2026-04-16). Added it to `PUBLIC_PATHS=(examples docs AGENTS.md CLAUDE.md README.md PRIVACY.md .github)`. Updated usage string, acceptance criterion, and must_haves truth to match. |

### Rejected

| Reviewer | Severity | Concern | Reason |
|----------|----------|---------|--------|
| Gemini | MEDIUM | "Regex backslash loss" in T3 `bin/search.sh` — `r'contributor::s*@'` appears to miss backslashes for `\s` and `\b`. | **False positive — rendering artifact in Gemini's output.** Plan text at line 896 reads `r'contributor::\s*@' + re.escape(handle) + r'\b'` — correct with backslashes present. Verified directly before dismissal. |

### Deferred

| Reviewer | Severity | Concern | Deferral Reason |
|----------|----------|---------|-----------------|
| Codex | MEDIUM | Malformed frontmatter in public paths could evade `bin/check-privacy.sh` detection. | Valid concern but out of Phase 9 scope — malformed frontmatter is a YAML-validity issue caught by `bin/lint.sh --ci` (category `yaml`, severity `error`). Defer hardening to a follow-up phase if real malformed-frontmatter privacy escapes are observed. |
| Codex | MEDIUM | `.git-author-map.txt` parser accepts both `  ->  ` and tab separators but docs emphasize only arrow form. | Acceptable looseness; arrow-form is the documented default per D-21. Tab-separator tolerance is a backwards-compat kindness. No change. |
| Codex | LOW | `test_check_privacy_clean.sh` assumes real repo stays privacy-clean throughout phase. | This IS the intended invariant — a test that detects real-repo drift is a feature, not a bug. No change. |
| Codex | LOW | `bin/search.sh --contributor` log-entry parser brittle to log format drift. | Log format governed by AGENTS.md §12 (amended in Plan 05). Drift requires AGENTS.md change, which would be caught in review. No change. |

