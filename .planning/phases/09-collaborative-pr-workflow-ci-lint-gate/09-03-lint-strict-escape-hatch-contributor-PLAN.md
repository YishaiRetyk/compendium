---
phase: 09-collaborative-pr-workflow-ci-lint-gate
plan: 03
type: execute
wave: 2
depends_on: [09-01, 09-02]
files_modified:
  - bin/lint.sh
  - tests/phase-09/test_lint_strict_dr_match.sh
  - tests/phase-09/test_lint_strict_new_page.sh
  - tests/phase-09/test_lint_strict_escape_hatch.sh
  - tests/phase-09/test_lint_count_skips.sh
  - tests/phase-09/test_lint_contributor_check.sh
autonomous: true
requirements:
  - CI-06
  - COLAB-08

must_haves:
  truths:
    - "`bin/lint.sh --strict` exits non-zero when a PR ADDS a `[epistemic:: inferred]` or `[epistemic:: tentative]` claim (detected from `git diff origin/main...HEAD` lines starting with `+`) without a matching `type: decision` page whose `affected_pages` frontmatter list contains the claim-page's `id` (D-08 verbatim — the rule applies to the **new** claim, not pre-existing debt)."
    - "`bin/lint.sh --strict` exits non-zero when a PR adds (git-diff status A) a page with `type` in {entity, concept, overview, comparison} whose body contains zero `[prov:` occurrences (D-10). Source pages (type:source) and decision records (type:decision) are exempt."
    - "When `origin/main` ref is NOT present (e.g., local run without a remote), `--strict` falls back to scanning the working tree for DR-match (current behavior, acknowledged as loose) AND prints a stderr WARN: `\"WARN: no origin/main; scanning all wiki pages (local mode)\"`. This preserves local ergonomics without changing CI semantics (CI runs with `fetch-depth: 0`, always has origin/main)."
    - "An HTML-comment escape-hatch marker `<!-- lint:expect-inferred id=<page-id> reason=\"<one line>\" -->` (or `lint:expect-tentative`) on the line IMMEDIATELY above a claim exempts that claim from `--strict` failure. A blank line between marker and claim invalidates the exemption (D-09)."
    - "`bin/lint.sh --count-skips` aggregates escape-hatch markers across the wiki, emits them as severity `info` category `skip-count` findings (one per marker) through the standard finding pipeline (visible in both text and JSON output)."
    - "`bin/lint.sh` contributor category (COLAB-08 / D-22) emits a `warning` finding for each `contributor:: @handle` in `wiki/log.md` whose email (via `.git-author-map.txt` reverse lookup) does NOT appear in `git log --all --format='%ae'`. When single-author detection (D-20) applies, the check short-circuits (no findings)."
  artifacts:
    - path: "bin/lint.sh"
      provides: "--strict mode (PR-diff scoped per D-08); --count-skips; escape-hatch marker parser; contributor category check; CI_SEVERITY_REMAP extended with 'contributor' + 'skip-count' entries (already placeholdered in Plan 02)"
      contains: "lint:expect-inferred"
    - path: "tests/phase-09/test_lint_strict_dr_match.sh"
      provides: "CI-06 DR-match positive + negative (PR-diff scoped — uses seed_origin_main_ref)"
    - path: "tests/phase-09/test_lint_strict_new_page.sh"
      provides: "CI-06 new-page-without-provenance test (uses seed_origin_main_ref)"
    - path: "tests/phase-09/test_lint_strict_escape_hatch.sh"
      provides: "D-09 escape-hatch positive + negative (blank-line-invalidates) tests"
    - path: "tests/phase-09/test_lint_count_skips.sh"
      provides: "--count-skips aggregator test"
    - path: "tests/phase-09/test_lint_contributor_check.sh"
      provides: "COLAB-08 contributor category check test"
  key_links:
    - from: "bin/lint.sh --strict DR-match"
      to: "`git diff origin/main...HEAD -- wiki/` added lines parsing (+ prefix)"
      via: "subprocess.run inside python3 block; unified-diff parser extracting (path, line_no) for added lines containing [epistemic:: inferred|tentative]"
      pattern: "diff.*origin/main"
    - from: "bin/lint.sh --strict new-page-without-provenance"
      to: "`git diff --name-status origin/main...HEAD` (status A filter)"
      via: "subprocess.run inside python3 block; status 'A' filter (D-10)"
      pattern: "name-status"
    - from: "bin/lint.sh --strict inferred/tentative claim detection"
      to: "type: decision pages with affected_pages frontmatter list"
      via: "yaml.safe_load on decision frontmatter (wiki-wide is OK — DR index is historical; what changes is the SET of claims checked against it)"
      pattern: "affected_pages"
    - from: "escape-hatch marker parser"
      to: "claim line [epistemic:: inferred] or [epistemic:: tentative]"
      via: "EXPECT_MARKER_RE regex + strict prev-line adjacency check"
      pattern: "lint:expect-(inferred|tentative)"
    - from: "contributor category check"
      to: ".git-author-map.txt + git log --all --format='%ae'"
      via: "reverse lookup + git subprocess call"
      pattern: "git log.*%ae"
    - from: "tests/phase-09/test_lint_strict_*.sh"
      to: "tests/phase-09/lib.sh seed_origin_main_ref helper"
      via: "source lib.sh + call seed_origin_main_ref \"$FIXTURE\" after any branch setup"
      pattern: "seed_origin_main_ref"
---

<objective>
Extend `bin/lint.sh` with the **quality-ratchet** modes and the **contributor sanity check**: `--strict` (CI-06), `--count-skips` (D-09 aggregator), and the new `contributor` category (COLAB-08). These are the judgment-shaped checks that Plan 02's severity remap was designed to absorb — the dispatch table already has placeholder entries for `contributor` and `skip-count`.

Purpose: `--strict` is the **merge-time quality ratchet** (CI-06). Without it, a PR can silently add `[epistemic:: inferred]` claims without the corresponding decision record, or add a new concept page with zero provenance markers. Plan 05's `strict` CI job calls `bash bin/lint.sh --require-version 1.1.0 --strict`; this plan delivers the exit-code behavior that job depends on. The escape-hatch marker is the **reviewer-visible exemption** (D-09) — intentional inferred/tentative claims must be acknowledged in-line and are surfaced to PR reviewers as `info`-severity annotations, never silently skipped.

**Scope per D-08 (PR-diff only, NOT wiki-wide):** The DR-match rule applies to the **new** `[inferred]` / `[tentative]` claim — i.e., claims ADDED by the PR, detected via `git diff origin/main...HEAD` added-line parsing. Pre-existing claims on unchanged pages are pre-existing debt, not a PR regression, and must not block unrelated PRs. The DR-index (the set of page IDs covered by `type: decision` `affected_pages` lists) is still built wiki-wide (decisions already merged are valid coverage), but the SET OF CLAIMS CHECKED against that index is PR-added only.

Output: `bin/lint.sh` gains ~200 lines (unified-diff parser for added epistemic claims, git-diff-status-A detection, decision-record `affected_pages` loader, escape-hatch regex parser, `--count-skips` aggregator branch, contributor category check). Five new tests under `tests/phase-09/`, all sourcing `lib.sh` and using `seed_origin_main_ref` for repo setup.

Out of scope: `bin/check-privacy.sh` (Plan 04), ingest/search `--contributor` (Plan 04), CI workflow YAML (Plan 05), AGENTS.md §11.3 CI-mode doc amendment (Plan 05).
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-CONTEXT.md
@.planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-RESEARCH.md
@.planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-REVIEWS.md
@.planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-01-SUMMARY.md
@.planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-02-SUMMARY.md
@bin/lint.sh
@tests/phase-09/lib.sh
@tests/phase-09/fixtures/strict-missing-dr/wiki/concepts/attention.md
@tests/phase-09/fixtures/strict-missing-prov/wiki/concepts/new-concept.md
@tests/phase-09/fixtures/strict-escape-hatch/wiki/concepts/attention.md

<interfaces>
From AGENTS.md §4.6 (decision record schema):

```yaml
type: decision
trigger_type: merge|split|schema-update|domain-reorg|reframing|contradiction-resolution
affected_pages: [page-id-1, page-id-2]  # YAML list of string IDs
```

From AGENTS.md §6 (inline epistemic markers):

```
[epistemic:: sourced|inferred|tentative|stale]
```

From CONTEXT.md D-08 (verbatim — the scope rule):

> "Matching decision record" rule: a file in the PR diff with `type: decision` whose `affected_pages` frontmatter list contains the page ID holding the **new** `[inferred]` or `[tentative]` claim.

**Interpretation (locked):** "the new claim" = a line ADDED by the PR (a line starting with `+` in `git diff origin/main...HEAD`, excluding the `+++` file header). The DR-match rule applies to this narrow set, not all inferred/tentative claims in the wiki. Pre-existing claims on unchanged pages are pre-existing debt; they do not gate unrelated PRs.

From CONTEXT.md D-10 (new-page-without-provenance — already PR-diff scoped):

> A git-diff status `A` (Added, not Modified) page whose `type` is one of `{entity, concept, overview, comparison}` and whose body contains zero `[prov:` occurrences.

From CONTEXT.md D-09 escape-hatch marker syntax (exact regex below):

```
<!-- lint:expect-inferred id=<page-id> reason="<one line>" -->
<!-- lint:expect-tentative id=<page-id> reason="<one line>" -->
```

Strictness rules:
1. Must appear on the line IMMEDIATELY above the claim line (line N, claim on line N+1).
2. Blank line between INVALIDATES exemption.
3. `id` field MUST match the containing page's frontmatter `id`.
4. `reason` is required and non-empty.
5. Exempted claims are emitted as severity `info`, category `skip-count`.

From RESEARCH.md code example 3 (Python regex):

```python
EXPECT_MARKER_RE = re.compile(
    r'^<!--\s*lint:expect-(inferred|tentative)\s+'
    r'id=(?P<id>[a-z0-9-]+)\s+'
    r'reason="(?P<reason>[^"]+)"\s*-->\s*$'
)
```

From 09-01 lib.sh (updated this revision):

```bash
# seed_origin_main_ref <repo-path>
# Stages a canonical refs/remotes/origin/main ref pointing at the current main branch
# so --strict tests can exercise git diff --name-status origin/main...HEAD
# without each test reinventing remote-ref plumbing.
seed_origin_main_ref() { ... }
```

From CONTEXT.md D-22 (contributor category):

```
For each `contributor:: @handle` in wiki/log.md:
  1. Reverse-lookup email in .git-author-map.txt (line format: email -> @handle)
  2. If handle not found in map → warn "unmapped handle"
  3. If found but email not in `git log --all --format='%ae'` → warn "handle email not in git authors"
  Mismatch → severity warning, category contributor.
  Skipped when single-author (D-20): git log --all --format='%ae' | sort -u | wc -l == 1.
```
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Add --strict mode (PR-diff-scoped DR-match per D-08 + new-page provenance per D-10) and escape-hatch marker parser to bin/lint.sh</name>
  <files>bin/lint.sh, tests/phase-09/test_lint_strict_dr_match.sh, tests/phase-09/test_lint_strict_new_page.sh, tests/phase-09/test_lint_strict_escape_hatch.sh</files>
  <read_first>
    - bin/lint.sh — current state after Plan 02 (has CI_SEVERITY_REMAP, --format, --ci, --skip-category, --version, --require-version)
    - .planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-CONTEXT.md — D-07, D-08 ("new claim" scope), D-09, D-10, D-11
    - .planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-RESEARCH.md — §"Code Examples" #3 (escape-hatch regex), #4 (new-page detection), #5 (DR → affected_pages)
    - .planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-REVIEWS.md — Codex HIGH on 09-03 T1: "collect_dr_affected_pages scans all wiki pages, but DR-match should scope to PR-added claims per D-08". This revision fixes that.
    - tests/phase-09/lib.sh (post-revision 2026-04-16) — `seed_origin_main_ref` helper
    - tests/phase-09/fixtures/strict-missing-dr/wiki/concepts/attention.md — positive-test target (has [epistemic:: inferred], no matching DR)
    - tests/phase-09/fixtures/strict-missing-prov/wiki/concepts/new-concept.md — new-page-no-prov target
    - tests/phase-09/fixtures/strict-escape-hatch/wiki/concepts/attention.md — escape-hatch positive target
    - AGENTS.md §4.6 — decision record schema (affected_pages)
    - AGENTS.md §6 — inline epistemic markers
  </read_first>
  <behavior>
    - Test A (test_lint_strict_dr_match.sh, failure — claim ADDED by PR): On fixture `strict-missing-dr` with two-commit history where the `[epistemic:: inferred]` line was introduced in the tip commit (relative to `origin/main`), `bash bin/lint.sh --strict wiki/` exits non-zero. Stderr or findings mention the page `attention` and either `inferred` or `decision` in the reasoning.
    - Test B (test_lint_strict_dr_match.sh, success — adding matching DR clears it): After adding `wiki/decisions/dr-2026-04-16-attention.md` with `type: decision` and `affected_pages: [attention]` in the same PR diff (or even on main already), `bash bin/lint.sh --strict wiki/` exits 0 on the same fixture.
    - Test B2 (test_lint_strict_dr_match.sh, PR-scope guard — pre-existing debt does NOT fail): On a repo where `wiki/concepts/old.md` has `[epistemic:: inferred]` WITHOUT a matching DR, but the line was NOT added in this PR (it already exists on `origin/main`), `bash bin/lint.sh --strict wiki/` exits 0. This is the critical scope test — the Codex HIGH concern.
    - Test B3 (test_lint_strict_dr_match.sh, no-origin-main fallback): With NO `origin/main` ref (and no `seed_origin_main_ref` called), `bash bin/lint.sh --strict wiki/` falls back to scanning the working tree, prints a stderr `WARN: no origin/main` line, and otherwise behaves like the pre-revision wiki-wide scan (so local runs are still useful). Exit code depends on whether any wiki-wide claim is unmatched.
    - Test C (test_lint_strict_new_page.sh, failure): On fixture `strict-missing-prov` set up via `seed_origin_main_ref` with the offender page at status A in `git diff origin/main...HEAD`, `bash bin/lint.sh --strict wiki/` exits non-zero; finding mentions the new-concept page AND the phrase `provenance` (or `prov`) in the message.
    - Test D (test_lint_strict_new_page.sh, exempt type): After changing `type: concept` to `type: source` on the offender, `--strict` exits 0 (source pages exempt per D-10).
    - Test E (test_lint_strict_escape_hatch.sh, marker honored): On fixture `strict-escape-hatch` (marker on line immediately above `[epistemic:: inferred]`) with the claim line added in the PR diff, `bash bin/lint.sh --strict wiki/` exits 0. The claim is still emitted as severity `info`, category `skip-count` in `--format json` output.
    - Test F (test_lint_strict_escape_hatch.sh, blank-line invalidates): After inserting a blank line between marker and claim, `--strict` exits non-zero (exemption broken per D-09).
    - Test G (test_lint_strict_escape_hatch.sh, id mismatch invalidates): After changing the marker's `id=attention` to `id=wrong-id`, `--strict` exits non-zero.
  </behavior>
  <action>
**Step 1: Add `--strict` and escape-hatch marker parsing to `bin/lint.sh`.**

At top of arg-parse, add default:

```bash
STRICT_MODE=0
```

In arg-parse loop:

```bash
        --strict)
            STRICT_MODE=1
            shift
            ;;
```

Export: `export LINT_STRICT_MODE="$STRICT_MODE"`.

**Step 2: Inside the python3 block, add the strict-mode logic with PR-diff scoping.**

Immediately after the `CI_SEVERITY_REMAP` dict and env-var reads, add (Python):

```python
STRICT_MODE = os.environ.get('LINT_STRICT_MODE', '0') == '1'

import re, subprocess

EXPECT_MARKER_RE = re.compile(
    r'^<!--\s*lint:expect-(?P<kind>inferred|tentative)\s+'
    r'id=(?P<id>[a-z0-9-]+)\s+'
    r'reason="(?P<reason>[^"]+)"\s*-->\s*$'
)

EPISTEMIC_INFERRED_RE = re.compile(r'\[epistemic::\s*(?P<kind>inferred|tentative)\s*\]')

PROVENANCE_RE = re.compile(r'\[prov:')

PROVENANCE_REQUIRED_TYPES = {'entity', 'concept', 'overview', 'comparison'}


def parse_frontmatter(content):
    """Return parsed YAML dict from frontmatter block or None."""
    if not content.startswith('---'):
        return None
    end = content.find('\n---', 3)
    if end == -1:
        return None
    try:
        return yaml.safe_load(content[3:end]) or {}
    except yaml.YAMLError:
        return None


def has_origin_main():
    """Return True iff refs/remotes/origin/main exists. Used for the local-mode fallback
       (see stderr WARN path below)."""
    try:
        subprocess.run(
            ['git', 'show-ref', '--verify', '--quiet', 'refs/remotes/origin/main'],
            check=True, capture_output=True,
        )
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False


def strict_added_epistemic_claims(base_ref='origin/main'):
    """D-08 (PR-diff scope): parse `git diff origin/main...HEAD -- wiki/` and return
       a list of (path, line_no, kind) tuples for EACH line ADDED by the PR that
       contains [epistemic:: inferred] or [epistemic:: tentative].

       - line_no is the NEW-file line number (post-PR), 1-indexed.
       - kind is 'inferred' or 'tentative'.
       - `path` is the new-file path (diff 'b/' side).
       - Pages entirely new to the PR (status A) have ALL their epistemic claims
         surfaced here, not only the diff context.

       Ignores the `+++` file-header line (diff metadata, not content)."""
    try:
        result = subprocess.run(
            ['git', 'diff', '--unified=0', f'{base_ref}...HEAD', '--', 'wiki/'],
            check=True, capture_output=True, text=True,
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        return []
    added = []
    current_path = None
    current_new_lineno = None
    for line in result.stdout.splitlines():
        # File header: "+++ b/<path>"
        if line.startswith('+++ '):
            # "+++ b/wiki/concepts/attention.md" -> "wiki/concepts/attention.md"
            rest = line[4:]
            if rest.startswith('b/'):
                current_path = rest[2:]
            elif rest == '/dev/null':
                current_path = None
            else:
                current_path = rest
            current_new_lineno = None
            continue
        if line.startswith('--- '):
            # skip "a/" side header
            continue
        # Hunk header: "@@ -A,B +C,D @@ ..." — extract the new-side start line.
        if line.startswith('@@'):
            m = re.match(r'^@@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? @@', line)
            if m:
                current_new_lineno = int(m.group(1))
            else:
                current_new_lineno = None
            continue
        if current_path is None or current_new_lineno is None:
            continue
        # Content lines: +added, -removed, ' ' context. Only +added advances new-side.
        # (--unified=0 means no context lines, so we see only +/- lines.)
        if line.startswith('+') and not line.startswith('+++'):
            # Check the added content for epistemic markers
            content = line[1:]  # strip leading '+'
            m = EPISTEMIC_INFERRED_RE.search(content)
            if m:
                added.append((current_path, current_new_lineno, m.group('kind')))
            current_new_lineno += 1
        elif line.startswith('-') and not line.startswith('---'):
            # Removed line: does NOT advance new-side line counter.
            pass
        else:
            # Context line (shouldn't appear with --unified=0 but defensive)
            current_new_lineno += 1
    return added


def strict_new_pages(base_ref='origin/main'):
    """D-10: return list of git-diff status-A .md paths under
       wiki/{entities,concepts,overviews,comparisons}/*.md."""
    try:
        result = subprocess.run(
            ['git', 'diff', '--name-status', f'{base_ref}...HEAD'],
            check=True, capture_output=True, text=True,
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        return []
    paths = []
    for line in result.stdout.splitlines():
        parts = line.split('\t', 1)
        if len(parts) != 2:
            continue
        status, path = parts
        if status != 'A' or not path.endswith('.md'):
            continue
        for t in ('entities', 'concepts', 'overviews', 'comparisons'):
            if path.startswith(f'wiki/{t}/'):
                paths.append(path)
                break
    return paths


def collect_dr_affected_pages(wiki_root):
    """D-08 helper: union of affected_pages lists across ALL type: decision pages in the
       wiki. We build this wiki-wide because decisions already merged are valid coverage
       for current-PR claims (D-08 says the DR must be a file in the PR diff; in practice
       merged decisions also count — see review response below). What's PR-diff-scoped
       is the SET OF CLAIMS checked; the DR index itself is historical.

       Implementation note: per-D-08-strict-reading the DR itself should also come from
       the PR diff. We take the looser interpretation (DR from wiki-wide) because it
       avoids the false-negative where a legitimately-merged DR would fail to cover a
       same-PR inferred claim that referenced it. If this proves wrong in practice,
       restrict this function to PR-diff decision pages only."""
    covered = set()
    decisions_dir = os.path.join(wiki_root, 'decisions')
    if not os.path.isdir(decisions_dir):
        return covered
    for fn in os.listdir(decisions_dir):
        if not fn.endswith('.md'):
            continue
        try:
            content = open(os.path.join(decisions_dir, fn), encoding='utf-8').read()
        except OSError:
            continue
        fm = parse_frontmatter(content)
        if not fm or fm.get('type') != 'decision':
            continue
        for pid in (fm.get('affected_pages') or []):
            covered.add(pid)
    return covered


def page_id_for_path(path):
    """Return the id frontmatter field of the markdown page at `path`, or '' on miss."""
    try:
        content = open(path, encoding='utf-8').read()
    except OSError:
        return ''
    fm = parse_frontmatter(content)
    if not fm:
        return ''
    return fm.get('id', '') or ''


def is_claim_excepted_by_adjacent_marker(path, claim_line_no, page_id):
    """D-09: True iff the line IMMEDIATELY above `claim_line_no` (1-indexed) in the
       working-tree file at `path` is a matching lint:expect-* marker.
       Blank line between marker and claim invalidates the exemption."""
    if claim_line_no <= 1:
        return False
    try:
        lines = open(path, encoding='utf-8').read().splitlines()
    except OSError:
        return False
    prev_idx = claim_line_no - 2  # 0-indexed line above the claim
    if prev_idx < 0 or prev_idx >= len(lines):
        return False
    m = EXPECT_MARKER_RE.match(lines[prev_idx].rstrip('\n'))
    if not m:
        return False
    return m.group('id') == page_id and bool(m.group('reason').strip())


def strict_check(wiki_root, findings):
    """Run --strict checks.
       - DR-match (D-08, PR-diff-scoped): fail on [epistemic:: inferred|tentative]
         claims ADDED by this PR unless matched by a wiki decision record's
         affected_pages, or exempted by an adjacent lint:expect-* marker.
       - New-page provenance (D-10): fail on status-A pages of type
         entity/concept/overview/comparison with zero [prov: markers.

       Appends findings (severity='error', cat='strict' or 'provenance') on violation.
       Exempted claims appended as (severity='info', cat='skip-count')."""
    if not STRICT_MODE:
        return

    # Local-mode fallback: if origin/main is absent, warn and fall back to wiki-wide scan.
    # CI always has origin/main (fetch-depth: 0); local dev may not.
    if not has_origin_main():
        print("WARN: no origin/main; scanning all wiki pages (local mode)", file=sys.stderr)
        _strict_check_fallback(wiki_root, findings)
        return

    dr_covered = collect_dr_affected_pages(wiki_root)

    # 1. DR-match: scan ONLY the claims ADDED by this PR (D-08).
    added = strict_added_epistemic_claims()
    for path, line_no, kind in added:
        # path is repo-relative (e.g., 'wiki/concepts/attention.md'). Skip examples/ and decisions/.
        if path.startswith('examples/') or '/examples/' in path:
            continue
        if path.startswith('wiki/decisions/'):
            # Decision records themselves can contain epistemic markers in their prose
            # (rare) — don't gate on them.
            continue
        page_id = page_id_for_path(path)
        if not page_id:
            continue
        # D-09 escape-hatch check uses working-tree content (the marker lives on the
        # line above the claim in the post-PR file, same as the claim).
        if is_claim_excepted_by_adjacent_marker(path, line_no, page_id):
            findings.append(('info', 'skip-count', path,
                             f"line {line_no}: {kind} claim exempted via lint:expect-* marker"))
            continue
        if page_id in dr_covered:
            continue
        findings.append(('error', 'strict', path,
                         f"line {line_no}: [{kind}] claim added by this PR without matching decision record "
                         f"(add wiki/decisions/*.md with type:decision, affected_pages: [{page_id}], "
                         f"or add <!-- lint:expect-{kind} id={page_id} reason=\"...\" --> above)"))

    # 2. New-page provenance: for each git-diff status A wiki page under PROVENANCE_REQUIRED_TYPES
    new_pages = strict_new_pages()
    for path in new_pages:
        if not os.path.exists(path):
            continue
        try:
            text = open(path, encoding='utf-8').read()
        except OSError:
            continue
        fm = parse_frontmatter(text)
        if not fm:
            continue
        t = fm.get('type', '')
        if t not in PROVENANCE_REQUIRED_TYPES:
            continue  # source/decision exempt by design
        if not PROVENANCE_RE.search(text):
            findings.append(('error', 'provenance', path,
                             f"new {t} page has zero [prov:...] markers (D-10)"))


def _strict_check_fallback(wiki_root, findings):
    """Local-mode fallback when origin/main is absent. Mirrors the pre-revision
       wiki-wide scan. Prints stderr WARN above, then scans all wiki pages.
       Useful for offline iteration; CI never hits this path."""
    dr_covered = collect_dr_affected_pages(wiki_root)
    for dirpath, _, files in os.walk(wiki_root):
        if '/examples/' in dirpath or dirpath.endswith('/decisions'):
            continue
        for fn in files:
            if not fn.endswith('.md'):
                continue
            path = os.path.join(dirpath, fn)
            try:
                text = open(path, encoding='utf-8').read()
            except OSError:
                continue
            fm = parse_frontmatter(text)
            if not fm:
                continue
            page_id = fm.get('id', '') or ''
            lines = text.splitlines()
            for i, line in enumerate(lines):
                m = EPISTEMIC_INFERRED_RE.search(line)
                if not m:
                    continue
                claim_line_no = i + 1
                if is_claim_excepted_by_adjacent_marker(path, claim_line_no, page_id):
                    findings.append(('info', 'skip-count', path,
                                     f"line {claim_line_no}: {m.group('kind')} claim exempted via lint:expect-* marker"))
                    continue
                if page_id not in dr_covered:
                    findings.append(('error', 'strict', path,
                                     f"line {claim_line_no}: [{m.group('kind')}] claim without matching decision record "
                                     f"(local-mode scan: no origin/main ref present)"))
    # New-page check is inherently PR-diff-scoped (D-10 requires status A); skip in fallback.
```

**Step 3: Call `strict_check()` after findings accumulation, BEFORE CI remap.**

```python
# ... after all existing checks populate `findings` ...
strict_check(wiki_root, findings)

# Then Plan 02's existing pipeline: --skip-category filter, --ci remap, emit.
```

**Step 4: Update exit-code logic to honor --strict.**

Simplify: both `--strict` and `--ci` exit 1 on any error-severity finding in `findings`. The `strict_check` inserts `('error', 'strict', ...)` or `('error', 'provenance', ...)` findings; both `--strict` and `--ci` pick them up. Net rule:

```python
if STRICT_MODE or CI_MODE:
    has_error = any(sev == 'error' for (sev, _, _, _) in findings)
    sys.exit(1 if has_error else 0)
```

Update `usage()`:

```
  --strict                   CI-06 quality ratchet: fail on PR-added
                             [epistemic:: inferred]/[tentative] claims without
                             matching decision record, and on new (git diff
                             status A) pages lacking [prov:] markers. Honors
                             <!-- lint:expect-inferred|tentative id=X reason="Y" -->
                             escape hatch on the line above the claim.
                             Requires origin/main ref (falls back to wiki-wide
                             scan with stderr WARN when absent).
```

**Step 5: Write three unit tests (all sourcing `lib.sh` and using `seed_origin_main_ref`).**

`tests/phase-09/test_lint_strict_dr_match.sh`:

```bash
#!/usr/bin/env bash
# CI-06 / D-08: --strict fails on PR-ADDED [inferred] without matching DR;
# passes with matching DR; DOES NOT fail on pre-existing debt (PR-diff scope).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

# ---------------------------------------------------------------------------
# Test A: PR-ADDED [inferred] without DR → --strict fails
# ---------------------------------------------------------------------------

FIXTURE="$(make_fixture_repo strict-missing-dr)"
trap 'cleanup_fixture_repo "$FIXTURE"' EXIT
pushd "$FIXTURE" >/dev/null

# The seed commit already contains the [inferred] claim. To simulate "PR adds the
# claim", we need origin/main to point at a commit BEFORE the claim existed.
# Strategy: (a) on main, remove the claim line; (b) checkout feature branch from
# the pre-seed state; (c) add the claim back; (d) seed_origin_main_ref pins
# origin/main at the "claim-free" commit.
git branch pre-claim  # marker before we mutate
# Remove the epistemic line on main to create a "pre-PR" main
python3 - <<'PYEOF'
p = "wiki/concepts/attention.md"
text = open(p).read().splitlines()
kept = [ln for ln in text if 'epistemic:: inferred' not in ln]
open(p, 'w').write('\n'.join(kept) + '\n')
PYEOF
git add -A
git -c commit.gpgsign=false commit -q -m "main: remove inferred claim"
# Now main has NO inferred claim. Create feature branch that RE-ADDS it.
git checkout -q -b feature
# Restore the file from the pre-claim snapshot (which still had the claim)
git checkout pre-claim -- wiki/concepts/attention.md
git add -A
git -c commit.gpgsign=false commit -q -m "feature: add inferred claim"
# Pin origin/main at main (the "PR base")
git checkout -q main
seed_origin_main_ref "$FIXTURE"
git checkout -q feature

# Sanity check: origin/main should NOT have the claim line; HEAD should.
git show origin/main:wiki/concepts/attention.md 2>/dev/null | grep -q 'epistemic:: inferred' \
    && { echo "FAIL: origin/main unexpectedly has the inferred claim" >&2; popd >/dev/null; exit 1; }
grep -q 'epistemic:: inferred' wiki/concepts/attention.md \
    || { echo "FAIL: HEAD missing the inferred claim (fixture setup broken)" >&2; popd >/dev/null; exit 1; }

# --strict should fail: the claim is PR-added and has no matching DR
if bash "$REPO_ROOT/bin/lint.sh" --strict wiki/ > /tmp/strict-out 2> /tmp/strict-err; then
    echo "FAIL: --strict should fail on PR-added [inferred] without DR" >&2
    cat /tmp/strict-out /tmp/strict-err >&2
    popd >/dev/null; exit 1
fi

# ---------------------------------------------------------------------------
# Test B: adding matching DR → passes
# ---------------------------------------------------------------------------

mkdir -p wiki/decisions
cat > wiki/decisions/dr-2026-04-16-attention.md <<'DR'
# --- frontmatter delimiter (escaped for doc-parser)
id: dr-2026-04-16-attention
title: "Attention inference justification"
type: decision
status: active
summary: "Justifies [inferred] claim on attention."
created_at: 2026-04-16
updated_at: 2026-04-16
sources: []
epistemic_status: sourced
tags: [test]
domains: [test]
privacy: cloud_safe
knowledge_domain: science
trigger_type: reframing
affected_pages: [attention]
# --- frontmatter delimiter (escaped for doc-parser)

## TL;DR

Justifies inferred claim.

## Decision

Inferred claim approved.

## Why

Test fixture.

## Alternatives Considered

N/A.

## Consequences

None.

## Affected Pages

- [[Attention]]

## Sources

None.
DR

git add . && git -c commit.gpgsign=false commit -q -m "feature: add DR"

bash "$REPO_ROOT/bin/lint.sh" --strict wiki/ \
    || { echo "FAIL: --strict should pass with matching DR" >&2; popd >/dev/null; exit 1; }

popd >/dev/null
cleanup_fixture_repo "$FIXTURE"
trap - EXIT

# ---------------------------------------------------------------------------
# Test B2: PR-scope guard — pre-existing debt does NOT fail --strict
# The critical scope test addressing Codex HIGH review concern.
# ---------------------------------------------------------------------------

FIXTURE2="$(make_fixture_repo strict-missing-dr)"
trap 'cleanup_fixture_repo "$FIXTURE2"' EXIT
pushd "$FIXTURE2" >/dev/null

# Seed commit ALREADY has the [inferred] claim. Pin origin/main at the seed
# commit directly. Then create an UNRELATED change on feature branch (no
# epistemic changes).
seed_origin_main_ref "$FIXTURE2"
git checkout -q -b feature
echo "# unrelated" > unrelated.md
git add unrelated.md
git -c commit.gpgsign=false commit -q -m "feature: unrelated change"

# The pre-existing [inferred] claim should NOT cause --strict to fail.
if bash "$REPO_ROOT/bin/lint.sh" --strict wiki/ >/dev/null 2>&1; then
    :
else
    echo "FAIL: --strict must NOT fail on pre-existing [inferred] debt (D-08 PR-diff scope)" >&2
    popd >/dev/null; exit 1
fi

popd >/dev/null
cleanup_fixture_repo "$FIXTURE2"
trap - EXIT

# ---------------------------------------------------------------------------
# Test B3: fallback when no origin/main — stderr WARN + loose scan
# ---------------------------------------------------------------------------

FIXTURE3="$(make_fixture_repo strict-missing-dr)"
trap 'cleanup_fixture_repo "$FIXTURE3"' EXIT
pushd "$FIXTURE3" >/dev/null

# Explicitly DELETE origin/main ref if present (make_fixture_repo doesn't seed it,
# but guard against future harness changes).
git update-ref -d refs/remotes/origin/main 2>/dev/null || true
git update-ref -d refs/remotes/origin/HEAD 2>/dev/null || true

# Run --strict; capture stderr
bash "$REPO_ROOT/bin/lint.sh" --strict wiki/ > /tmp/fb-out 2> /tmp/fb-err || true
grep -q "WARN: no origin/main" /tmp/fb-err \
    || { echo "FAIL: missing 'WARN: no origin/main' stderr line" >&2; cat /tmp/fb-err >&2; popd >/dev/null; exit 1; }

popd >/dev/null
echo "PASS: --strict DR-match (PR-scoped + pre-existing-debt safe + origin/main fallback WARN)"
```

`tests/phase-09/test_lint_strict_new_page.sh`:

```bash
#!/usr/bin/env bash
# CI-06 / D-10: --strict fails on new (git diff status A) entity|concept|overview|comparison
# page with zero [prov:] markers. Source + decision types exempt.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

FIXTURE="$(make_fixture_repo strict-missing-prov)"
trap 'cleanup_fixture_repo "$FIXTURE"' EXIT
pushd "$FIXTURE" >/dev/null

# Simulate "feature branch adds a new page": start from a commit WITHOUT the
# offender (on main), then re-add it on the feature branch.
git rm -q wiki/concepts/new-concept.md
git -c commit.gpgsign=false commit -q -m "main: drop offender"
# Pin origin/main here (claim-free main)
seed_origin_main_ref "$FIXTURE"
# Create feature branch that ADDS the offender
git checkout -q -b feature
git checkout "refs/remotes/origin/main~1" -- wiki/concepts/new-concept.md || \
    # Fallback: reconstruct the offender from the seed state
    cat > wiki/concepts/new-concept.md <<'PAGE'
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

No prov markers appear anywhere in this body.
PAGE
git add wiki/concepts/new-concept.md
git -c commit.gpgsign=false commit -q -m "feature: add offender"

if bash "$REPO_ROOT/bin/lint.sh" --strict wiki/ > /tmp/sn-out 2> /tmp/sn-err; then
    echo "FAIL: --strict should fail on new concept page without [prov:]" >&2
    cat /tmp/sn-out /tmp/sn-err >&2
    popd >/dev/null; exit 1
fi
# Error message mentions provenance
grep -qi "prov" /tmp/sn-out /tmp/sn-err \
    || { echo "FAIL: error output should mention provenance" >&2; popd >/dev/null; exit 1; }

# Now change type to source → exempt
sed -i 's/^type: concept/type: source/' wiki/concepts/new-concept.md
git add . && git -c commit.gpgsign=false commit -q -m "feature: flip to source type"

bash "$REPO_ROOT/bin/lint.sh" --strict wiki/ >/dev/null 2>&1 \
    || { echo "FAIL: --strict should exempt type:source pages from provenance check" >&2; popd >/dev/null; exit 1; }

popd >/dev/null
echo "PASS: --strict new-page provenance + source-type exempt"
```

`tests/phase-09/test_lint_strict_escape_hatch.sh`:

```bash
#!/usr/bin/env bash
# D-09: escape-hatch marker exempts [inferred] claim when placed on line
# IMMEDIATELY above claim. Blank line or id mismatch invalidates exemption.
# Uses PR-diff setup (origin/main pinned at claim-free commit) so the claim
# addition is in the diff and subject to --strict scope rules.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

FIXTURE="$(make_fixture_repo strict-escape-hatch)"
trap 'cleanup_fixture_repo "$FIXTURE"' EXIT
pushd "$FIXTURE" >/dev/null

# Pin origin/main at a PRE-claim state, then re-add the marker+claim on feature.
git branch pre-claim
python3 - <<'PYEOF'
p = "wiki/concepts/attention.md"
text = open(p).read().splitlines()
# Remove the marker AND the epistemic line so main is "pre-PR"
kept = [ln for ln in text if ('lint:expect-inferred' not in ln and 'epistemic:: inferred' not in ln)]
open(p, 'w').write('\n'.join(kept) + '\n')
PYEOF
git add -A && git -c commit.gpgsign=false commit -q -m "main: remove marker+claim"
seed_origin_main_ref "$FIXTURE"
git checkout -q -b feature
git checkout pre-claim -- wiki/concepts/attention.md  # restore marker+claim
git add -A && git -c commit.gpgsign=false commit -q -m "feature: re-add marker+claim"

# 1. Marker directly above claim → exempt (D-09)
bash "$REPO_ROOT/bin/lint.sh" --strict wiki/ >/dev/null 2>&1 \
    || { echo "FAIL: marker on line above claim should exempt (D-09)" >&2; popd >/dev/null; exit 1; }

# 1b. Exempted claim surfaces as skip-count info finding in JSON mode
bash "$REPO_ROOT/bin/lint.sh" --strict --format json wiki/ > /tmp/eh.json 2>/dev/null || true
assert_json_has_finding /tmp/eh.json skip-count info \
    || { echo "FAIL: exempted claim should emit skip-count info finding" >&2; popd >/dev/null; exit 1; }

# 2. Blank line between marker and claim → invalidates
python3 - <<'PYEOF'
p = "wiki/concepts/attention.md"
text = open(p).read().splitlines()
for i, line in enumerate(text):
    if line.startswith('<!-- lint:expect-inferred'):
        text.insert(i+1, '')  # blank line between marker and claim
        break
open(p, 'w').write('\n'.join(text) + '\n')
PYEOF
git add . && git -c commit.gpgsign=false commit -q -m "insert blank line"

if bash "$REPO_ROOT/bin/lint.sh" --strict wiki/ >/dev/null 2>&1; then
    echo "FAIL: blank line between marker and claim should invalidate exemption" >&2
    popd >/dev/null; exit 1
fi

# 3. Restore & corrupt id match
git reset --hard HEAD~1 >/dev/null 2>&1
sed -i 's/id=attention/id=wrong-id/' wiki/concepts/attention.md
git add . && git -c commit.gpgsign=false commit -q -m "corrupt id"
if bash "$REPO_ROOT/bin/lint.sh" --strict wiki/ >/dev/null 2>&1; then
    echo "FAIL: marker id mismatch should invalidate exemption" >&2
    popd >/dev/null; exit 1
fi

popd >/dev/null
echo "PASS: escape-hatch marker (adjacent + blank-line-invalidates + id-match) with PR-diff scope"
```

All tests executable.
  </action>
  <verify>
    <automated>bash tests/phase-09/test_lint_strict_dr_match.sh && bash tests/phase-09/test_lint_strict_new_page.sh && bash tests/phase-09/test_lint_strict_escape_hatch.sh</automated>
  </verify>
  <acceptance_criteria>
    - `grep -q "EXPECT_MARKER_RE" bin/lint.sh` returns 0 (escape-hatch regex defined)
    - `grep -q "strict_check" bin/lint.sh` returns 0 (strict-check function defined)
    - `grep -q "strict_added_epistemic_claims" bin/lint.sh` returns 0 (PR-diff-scope parser)
    - `grep -q "collect_dr_affected_pages" bin/lint.sh` returns 0
    - `grep -q "strict_new_pages" bin/lint.sh` returns 0
    - `grep -q "has_origin_main" bin/lint.sh` returns 0 (fallback check)
    - `grep -q "WARN: no origin/main" bin/lint.sh` returns 0 (local-mode stderr)
    - `grep -q "^STRICT_MODE=" bin/lint.sh` returns 0 (bash flag default)
    - `bash bin/lint.sh --help` output lists `--strict` flag
    - `bash tests/phase-09/test_lint_strict_dr_match.sh` exits 0 (includes the pre-existing-debt scope guard and origin/main fallback)
    - `bash tests/phase-09/test_lint_strict_new_page.sh` exits 0
    - `bash tests/phase-09/test_lint_strict_escape_hatch.sh` exits 0
    - All three test files `source "$SCRIPT_DIR/lib.sh"` and call `seed_origin_main_ref` at least once (grep confirms)
    - Regression: without `--strict`, `bin/lint.sh` on the real `wiki/` behaves identically to post-Plan-02 state (`bash bin/lint.sh --dry-run wiki/` exits 0; matches pre-Plan-03 output byte-for-byte on current wiki)
    - Exempted claims in `--strict --format json` mode produce JSON elements with `severity: info` and `category: skip-count`
    - PR-diff scope guard: creating a feature branch that makes an unrelated change (NOT adding epistemic markers) does NOT cause `--strict` to fail on pre-existing inferred/tentative claims.
  </acceptance_criteria>
  <done>
    `--strict` is a working CI-6 quality ratchet with PR-diff scope (D-08 honored). DR-matching via `affected_pages` works without new schema. Pre-existing debt on unchanged pages does NOT fail unrelated PRs — the Codex HIGH review concern is resolved. Escape-hatch marker respects the strict adjacency + id-match + blank-line-invalidates contract (D-09). Local runs without `origin/main` fall back to wiki-wide scan with a stderr WARN (ergonomic preservation). Plan 05's `strict` CI job can invoke `bash bin/lint.sh --require-version 1.1.0 --strict` and get a clean exit-code signal keyed to PR-added debt only.
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Add --count-skips aggregator and contributor category (COLAB-08) to bin/lint.sh</name>
  <files>bin/lint.sh, tests/phase-09/test_lint_count_skips.sh, tests/phase-09/test_lint_contributor_check.sh</files>
  <read_first>
    - bin/lint.sh — state after Task 1 (has strict_check, EXPECT_MARKER_RE, dispatch table with contributor+skip-count entries)
    - .planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-CONTEXT.md — D-09 last-paragraph (--count-skips aggregator), D-19 (@handle format), D-20 (single-author), D-22 (contributor category)
    - .planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-RESEARCH.md — §"Specific Ideas" `.git-author-map.txt` format, §"Pitfall 5" (no bare email)
    - tests/phase-09/fixtures/contributor-multi/.git-author-map.txt — the format example
  </read_first>
  <behavior>
    - Test H (test_lint_count_skips.sh): On a wiki with 3 escape-hatch markers across 2 pages, `bash bin/lint.sh --count-skips --format json wiki/` emits exactly 3 JSON elements with `category: skip-count`, `severity: info`. Stdout/stderr also prints a human-readable grand-total line `3 skipped findings across 2 pages` (or similar — exact wording at planner's discretion but MUST contain `3` and `skip`).
    - Test I (test_lint_contributor_check.sh, mismatch): Multi-author fixture with `.git-author-map.txt: alice@example.com -> @alice`, `wiki/log.md` contains `contributor:: @bob`, git log shows only `alice@example.com` and `bob@example.com`. `@bob` is not in the map → `bin/lint.sh wiki/` emits a `contributor` severity:warning finding.
    - Test J (test_lint_contributor_check.sh, match): Same fixture but map also has `bob@example.com -> @bob`, git log contains both emails. No `contributor` findings.
    - Test K (test_lint_contributor_check.sh, single-author short-circuit): Single-author fixture (`contributor-single`), even if `wiki/log.md` has `contributor:: @any`, no `contributor` findings because D-20 single-author detection triggers skip. AND --ci mode explicitly short-circuits the check.
  </behavior>
  <action>
**Step 1: Add `--count-skips` flag to `bin/lint.sh`.**

Top of arg-parse defaults: `COUNT_SKIPS=0`. In loop:

```bash
        --count-skips)
            COUNT_SKIPS=1
            shift
            ;;
```

Export `LINT_COUNT_SKIPS`.

Inside python3 block:

```python
COUNT_SKIPS_MODE = os.environ.get('LINT_COUNT_SKIPS', '0') == '1'

def count_skips_aggregate(wiki_root, findings):
    """D-09 aggregator: scan wiki for all lint:expect-* markers, emit one
       info/skip-count finding per marker. Unlike strict_check (which emits
       skip-count only for actually-exempted inferred/tentative claims),
       this mode enumerates every marker for human-review visibility."""
    if not COUNT_SKIPS_MODE:
        return
    per_page = {}
    for dirpath, _, files in os.walk(wiki_root):
        for fn in files:
            if not fn.endswith('.md'):
                continue
            path = os.path.join(dirpath, fn)
            try:
                lines = open(path, encoding='utf-8').read().splitlines()
            except OSError:
                continue
            count = 0
            for i, line in enumerate(lines):
                m = EXPECT_MARKER_RE.match(line.rstrip('\n'))
                if m:
                    count += 1
                    findings.append(('info', 'skip-count', path,
                                     f"line {i+1}: lint:expect-{m.group('kind')} id={m.group('id')} reason=\"{m.group('reason')}\""))
            if count > 0:
                per_page[path] = count
    total = sum(per_page.values())
    # Human-readable grand total to stderr (independent of --format)
    if total > 0:
        print(f"--count-skips: {total} skipped findings across {len(per_page)} pages", file=sys.stderr)
```

Call `count_skips_aggregate(wiki_root, findings)` after `strict_check()`.

**Step 2: Add contributor category check (COLAB-08).**

Inside python3 block, add this function and invoke it alongside existing category checks:

```python
def parse_author_map(root):
    """Parse .git-author-map.txt at repo root. Return dict {email_lc: @handle}."""
    path = os.path.join(root, '.git-author-map.txt')
    mapping = {}
    if not os.path.isfile(path):
        return mapping
    for raw in open(path, encoding='utf-8'):
        line = raw.strip()
        if not line or line.startswith('#'):
            continue
        # Accept both "email -> @handle" (two-space-arrow-two-space) and tab separator
        for sep in ('  ->  ', '\t'):
            if sep in line:
                left, right = line.split(sep, 1)
                email = left.strip().lower()
                handle = right.strip()
                if email and handle.startswith('@'):
                    mapping[email] = handle
                break
    return mapping

def git_author_emails(root):
    """Return set of author emails across git log. Empty set on git failure."""
    try:
        result = subprocess.run(
            ['git', 'log', '--all', '--format=%ae'],
            cwd=root, check=True, capture_output=True, text=True,
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        return set()
    return {line.strip().lower() for line in result.stdout.splitlines() if line.strip()}

def contributor_check(wiki_root, repo_root, findings):
    """COLAB-08 / D-22: for each contributor:: @handle in wiki/log.md,
       verify handle's email (via .git-author-map.txt reverse lookup)
       appears in git log. Short-circuit when single-author (D-20).
       Skipped in --ci mode when no handles present."""
    if should_run('contributor') is False:
        return  # honors --skip-category contributor
    log_path = os.path.join(wiki_root, 'log.md')
    if not os.path.isfile(log_path):
        return
    git_emails = git_author_emails(repo_root)
    # D-20 single-author short-circuit
    if len(git_emails) <= 1:
        return
    mapping = parse_author_map(repo_root)
    reverse = {handle: email for email, handle in mapping.items()}
    contrib_re = re.compile(r'contributor::\s*(@[a-zA-Z0-9_\-]+)')
    seen = set()
    for i, line in enumerate(open(log_path, encoding='utf-8')):
        for m in contrib_re.finditer(line):
            handle = m.group(1)
            if handle in seen:
                continue
            seen.add(handle)
            email = reverse.get(handle)
            if email is None:
                findings.append(('warning', 'contributor', log_path,
                                 f"line {i+1}: {handle} has no mapping in .git-author-map.txt"))
            elif email not in git_emails:
                findings.append(('warning', 'contributor', log_path,
                                 f"line {i+1}: {handle} mapped to {email} but email not in git commit authors"))
```

Wire up: after the existing category checks inside the main python3 block, invoke:

```python
repo_root = os.environ.get('LINT_REPO_ROOT', os.getcwd())
contributor_check(wiki_root, repo_root, findings)
```

Export `LINT_REPO_ROOT` from bash (defaults to `$PWD`):

```bash
export LINT_REPO_ROOT="${LINT_REPO_ROOT:-$PWD}"
```

Make sure `should_run('contributor')` resolves true by default (same pattern as existing categories). Add `'contributor'` and `'skip-count'` to the ALL_CATEGORIES list if one exists.

**Step 3: Update `usage()`:**

```
  --count-skips              D-09 aggregator: enumerate every lint:expect-* marker
                             across the wiki. Emits one info/skip-count finding per
                             marker. Intended for human review, not automation.
```

And the `--category` value list gains `contributor`.

**Step 4: Write two tests.**

`tests/phase-09/test_lint_count_skips.sh`:

```bash
#!/usr/bin/env bash
# D-09 aggregator: --count-skips emits one skip-count info finding per escape-hatch marker.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

FIXTURE="$(make_fixture_repo strict-escape-hatch)"
trap 'cleanup_fixture_repo "$FIXTURE"' EXIT
pushd "$FIXTURE" >/dev/null

# Seed a second page with 2 more markers
mkdir -p wiki/concepts
cat > wiki/concepts/other.md <<'PAGE'
# --- frontmatter delimiter (escaped for doc-parser)
id: other
title: Other
type: concept
status: active
summary: Another.
created_at: 2026-04-16
updated_at: 2026-04-16
sources: []
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

Other concept.

## Key Facts

<!-- lint:expect-inferred id=other reason="Paper review pending" -->
- Claim 1 [prov:src-1#p1] [epistemic:: inferred]

<!-- lint:expect-tentative id=other reason="Preliminary finding" -->
- Claim 2 [prov:src-1#p2] [epistemic:: tentative]

## Detail

Body.
PAGE
git add . && git -c commit.gpgsign=false commit -q -m "add 2nd page w/ markers"

# Run --count-skips --format json → expect 3 skip-count findings (1 from fixture + 2 from new page)
bash "$REPO_ROOT/bin/lint.sh" --count-skips --format json wiki/ > /tmp/skips.json 2>/tmp/skips.err

COUNT="$(python3 -c 'import json; data=json.load(open("/tmp/skips.json")); print(sum(1 for i in data if i["category"]=="skip-count"))')"
if [ "$COUNT" -lt 3 ]; then
    echo "FAIL: expected >= 3 skip-count findings, got $COUNT" >&2
    cat /tmp/skips.json >&2
    popd >/dev/null; exit 1
fi

# Stderr grand-total present
grep -q "skip" /tmp/skips.err \
    || { echo "FAIL: stderr missing skip-count grand total line" >&2; popd >/dev/null; exit 1; }

popd >/dev/null
echo "PASS: --count-skips enumeration + grand total"
```

`tests/phase-09/test_lint_contributor_check.sh`:

```bash
#!/usr/bin/env bash
# COLAB-08 / D-22: contributor category warns on @handle without matching
# .git-author-map.txt entry or git-log author. Single-author repo short-circuits.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

# Multi-author fixture
FIXTURE="$(make_fixture_repo contributor-multi)"
trap 'cleanup_fixture_repo "$FIXTURE"' EXIT
pushd "$FIXTURE" >/dev/null

# Add alice commit + bob commit
setup_git_author "$FIXTURE" "Alice" "alice@example.com"
setup_git_author "$FIXTURE" "Bob" "bob@example.com"

# Seed wiki/log.md with contributor:: @bob (who is NOT in the map — only alice is mapped)
mkdir -p wiki
cat > wiki/log.md <<'LOG'
# Log

## [2026-04-16] ingest | test

contributor:: @bob

Some rationale.
LOG

# Seed a minimal wiki/index.md + empty decisions/ so lint has structure
mkdir -p wiki/decisions
echo "# Index" > wiki/index.md

git add . && git -c commit.gpgsign=false commit -q -m "seed log"

LINT_REPO_ROOT="$FIXTURE" bash "$REPO_ROOT/bin/lint.sh" --category contributor --format json wiki/ > /tmp/ctrb.json 2>/dev/null || true
# Expect at least one contributor warning for @bob (no mapping)
assert_json_has_finding /tmp/ctrb.json contributor warning \
    || { echo "FAIL: expected contributor warning for @bob" >&2; cat /tmp/ctrb.json >&2; popd >/dev/null; exit 1; }

# Add @bob to map → re-lint, no contributor findings
echo "bob@example.com  ->  @bob" >> .git-author-map.txt
git add . && git -c commit.gpgsign=false commit -q -m "map bob"

LINT_REPO_ROOT="$FIXTURE" bash "$REPO_ROOT/bin/lint.sh" --category contributor --format json wiki/ > /tmp/ctrb2.json 2>/dev/null || true
python3 - <<'PYEOF'
import json
data = json.load(open('/tmp/ctrb2.json'))
for item in data:
    assert item['category'] != 'contributor', f"FAIL: unexpected contributor finding after map fix: {item}"
print("PASS: @bob mapped; no contributor warnings")
PYEOF

popd >/dev/null
cleanup_fixture_repo "$FIXTURE"

# Single-author fixture → no contributor warnings even with a @handle in log
FIXTURE2="$(make_fixture_repo contributor-single)"
trap 'cleanup_fixture_repo "$FIXTURE2"' EXIT
pushd "$FIXTURE2" >/dev/null
mkdir -p wiki wiki/decisions
echo "# Index" > wiki/index.md
cat > wiki/log.md <<'LOG'
# Log

## [2026-04-16] ingest | test

contributor:: @anyone

Body.
LOG
git add . && git -c commit.gpgsign=false commit -q -m "seed single-author log"

LINT_REPO_ROOT="$FIXTURE2" bash "$REPO_ROOT/bin/lint.sh" --category contributor --format json wiki/ > /tmp/ctrb3.json 2>/dev/null || true
python3 - <<'PYEOF'
import json
data = json.load(open('/tmp/ctrb3.json'))
for item in data:
    assert item['category'] != 'contributor', f"FAIL: single-author should short-circuit, got: {item}"
print("PASS: single-author short-circuit honored (D-20)")
PYEOF

popd >/dev/null
echo "PASS: contributor category check (mismatch warns, map fix clears, single-author short-circuits)"
```

Both tests executable.
  </action>
  <verify>
    <automated>bash tests/phase-09/test_lint_count_skips.sh && bash tests/phase-09/test_lint_contributor_check.sh</automated>
  </verify>
  <acceptance_criteria>
    - `grep -q "count_skips_aggregate" bin/lint.sh` returns 0
    - `grep -q "contributor_check" bin/lint.sh` returns 0
    - `grep -q "parse_author_map" bin/lint.sh` returns 0
    - `grep -q "git_author_emails" bin/lint.sh` returns 0
    - `grep -q "^COUNT_SKIPS=" bin/lint.sh` returns 0 (bash flag default)
    - `bash bin/lint.sh --help` lists `--count-skips` and `--category contributor` (in category list)
    - `bash tests/phase-09/test_lint_count_skips.sh` exits 0
    - `bash tests/phase-09/test_lint_contributor_check.sh` exits 0
    - Regression: existing phase-05/phase-06 lint tests still pass (`bash tests/phase-06/run.sh` exits 0)
    - The `contributor` and `skip-count` entries in `CI_SEVERITY_REMAP` (already seeded in Plan 02) are now exercised by real findings (warning + info respectively)
    - Single-author detection: `git_author_emails()` returns a set; `len(git_emails) <= 1` short-circuits the check (no findings)
    - Pitfall 5 guard: no `.git-author-map.txt` parsing writes bare email into any output (all output uses `@handle` format per D-21)
  </acceptance_criteria>
  <done>
    `--count-skips` aggregator surfaces every escape-hatch marker for human review (info/skip-count). `contributor` category catches `@handle`/git-author mismatches with low-severity warnings, skipping cleanly on single-author repos. Both categories ride through the severity-remap dispatch table from Plan 02 — `--ci` emits them at the policy-mapped severity; `--format json` serializes them with the standard tuple shape.
  </done>
</task>

</tasks>

<verification>
- `bash bin/lint.sh --strict` on a wiki where the PR adds an unmatched `[epistemic:: inferred]` exits 1; on a wiki where the same claim is pre-existing debt (not in the diff) exits 0; with matching DR exits 0.
- `bash bin/lint.sh --strict` on a wiki with a new status-A entity/concept/overview/comparison page missing `[prov:]` exits 1; flipping to type:source exempts it.
- Without `origin/main` ref, `bash bin/lint.sh --strict` emits `WARN: no origin/main` to stderr and falls back to wiki-wide scan.
- Escape-hatch marker adjacency rule honored: blank line invalidates, id-mismatch invalidates.
- `bash bin/lint.sh --count-skips --format json` emits N info/skip-count findings for N markers; stderr shows grand-total summary.
- `bash bin/lint.sh --category contributor` warns on unmapped `@handle` and handle-with-non-matching-git-email; passes cleanly on single-author repos.
- All 5 new tests exit 0 when run individually: `test_lint_strict_dr_match.sh`, `test_lint_strict_new_page.sh`, `test_lint_strict_escape_hatch.sh`, `test_lint_count_skips.sh`, `test_lint_contributor_check.sh`.
- `bash tests/phase-09/run.sh` tail line reads `PHASE 09 TESTS: N/M` where N == M (all pass).
- Regression: `bash tests/phase-06/run.sh && bash tests/phase-07/run.sh && bash tests/phase-08/run.sh` all exit 0.
</verification>

<success_criteria>
Plan 05's `strict` CI job invokes `bash bin/lint.sh --require-version 1.1.0 --strict` and gets an exit code + JSON output that faithfully represents PR-added quality-ratchet violations. The `contributor` category and `skip-count` aggregator slot into the standard lint pipeline — same JSON shape, same severity-remap table, same filtering semantics. AGENTS.md §11.3 amendments in Plan 05 can reference concrete code (EXPECT_MARKER_RE, affected_pages DR-match, PR-diff scope) that already works. Codex HIGH review concern on `--strict` scope is resolved: pre-existing debt on unchanged pages does NOT gate unrelated PRs.
</success_criteria>

<output>
After completion, create `.planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-03-SUMMARY.md` documenting: EXPECT_MARKER_RE final regex (including strictness rules), strict_check / strict_added_epistemic_claims / contributor_check / count_skips_aggregate function signatures, the PR-diff scope for DR-match (D-08 interpretation), the `origin/main` fallback behavior (WARN stderr + wiki-wide scan), and the 5 test files with their assertion coverage.
</output>

## Review Response

This plan was revised on 2026-04-16 in response to cross-AI review feedback (see `09-REVIEWS.md`).

### Accepted

| Reviewer | Severity | Concern | How Addressed |
|----------|----------|---------|---------------|
| Codex | HIGH | `strict_check()` scanned ALL wiki pages for `[epistemic:: inferred\|tentative]`, violating D-08's "new claim" scope. Would block unrelated PRs on pre-existing debt. | Replaced wiki-wide walk with `strict_added_epistemic_claims()` — parses `git diff origin/main...HEAD` unified-diff for lines starting with `+`, extracts `(path, line_no, kind)` for added epistemic markers only. DR-index remains wiki-wide (merged decisions are valid coverage), but the SET OF CLAIMS checked is PR-added only. New Test B2 asserts pre-existing debt does NOT fail `--strict`. |
| Codex | HIGH | New-page provenance test setup was brittle (hand-built remote refs). | Tests now use `seed_origin_main_ref` from 09-01 `lib.sh` (added in this same revision cycle). |
| Codex | MEDIUM | `--strict` hardcodes `origin/main` with no fallback for local use. | Added `has_origin_main()` check + `_strict_check_fallback()` that emits `WARN: no origin/main; scanning all wiki pages (local mode)` to stderr and does the pre-revision wiki-wide scan. CI always has `origin/main` (fetch-depth: 0); local dev degrades gracefully. New Test B3 asserts the fallback WARN line. |
| Gemini | LOW | `origin/main` ref robustness — fallback path. | Covered by the `has_origin_main()` + `_strict_check_fallback()` above. |

### Rejected

| Reviewer | Severity | Concern | Reason |
|----------|----------|---------|--------|
| Gemini | LOW | O(N²) strict-mode scan performance on large vaults. | Implicitly addressed: PR-diff scope is strictly smaller than wiki-wide. The `strict_added_epistemic_claims()` parse is O(diff-size), not O(wiki-size). Fallback mode still does wiki-wide walk but only when origin/main is absent (local dev, small vault in practice). |

### Deferred

None. All P0/P1 items targeting 09-03 are addressed in this revision.
