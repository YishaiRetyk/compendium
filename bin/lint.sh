#!/usr/bin/env bash
# bin/lint.sh -- Wiki health-check CLI helper (AGENTS.md section 11.3).
# Detects orphan pages, missing cross-references, stale claims, contradictions,
# knowledge gaps, and structural issues. Produces wiki-cloud/maintenance/lint-report.md.
#
# Zero LLM/API calls. Deterministic, file-based checks only.
# Requires: python3 with PyYAML.
set -euo pipefail

# Lint rule-set semver per CI-08 / D-26. Bump MAJOR on breaking changes
# (removed category, changed severity semantics). MINOR on non-breaking
# additions. PATCH on bug fixes. --require-version X.Y.Z is a minimum check.
LINT_VERSION="1.6.0"

usage() {
    cat <<'EOF'
Usage: bin/lint.sh [OPTIONS] [wiki-directory]

Wiki health-check that detects structural issues and stale claims.
Produces wiki-cloud/maintenance/lint-report.md and prints a compact summary.

Options:
  --help, -h          Show this help message
  --dry-run           Report findings without writing report page or log
  --fix               Apply mechanical auto-fixes (stale markers)
  --category <cat>    Run only specified category:
                        orphan, crossref, stale, contradiction, gap,
                        provenance, yaml, drift, duplicate, contributor,
                        brownfield, linkres
                      Default: all categories
  --version           Print lint rule-set semver (LINT_VERSION) and exit 0
  --require-version X.Y.Z
                      Fail with exit 1 if running LINT_VERSION < X.Y.Z
                      (minimum-version semantics, semver tuple compare)
  --format text|json  Output format (default: text). JSON writes a `[{severity,
                      category, path, message, line?}, ...]` array to stdout
                      and does NOT write wiki-cloud/maintenance/lint-report.md.
  --ci                CI mode: apply severity remap (yaml/orphan/crossref/
                      provenance -> error; stale/gap/contradiction/drift/
                      contributor -> warning; autofix/skip-count -> info),
                      default-skip `drift-external`, exit 1 on any post-remap
                      error-severity finding.
  --skip-category <cat>
                      Skip one category. Repeatable (chains into cat1:cat2).
                      Inverse of --category. Valid values: any add_finding()
                      category name, plus the logical subcategory
                      'drift-external' (targets drift findings whose message
                      starts with `EXTERNAL: `, i.e. DRFT-03 Obsidian-vault
                      awareness and future external-state checks).
                      Precedence: --category (inclusive) applies FIRST; then
                      --skip-category SUBTRACTS. Example:
                        --category stale --skip-category stale -> no findings.
  --strict                   CI-06 quality ratchet: fail on PR-added
                             [epistemic:: inferred]/[tentative] claims without
                             matching decision record, and on new (git diff
                             status A) pages lacking [prov:] markers. Honors
                             <!-- lint:expect-inferred|tentative id=X reason="Y" -->
                             escape hatch on the line above the claim.
                             Requires origin/main ref (falls back to wiki-wide
                             scan with stderr WARN when absent).
  --count-skips              D-09 aggregator: enumerate every lint:expect-*
                             marker across the wiki. Emits one info/skip-count
                             finding per marker + stderr grand total. Intended
                             for human review, not automated enforcement.
  --staged                   WGATE local-mode: scope --strict's new-page
                             provenance check (D-10) to staged additions
                             only (`git diff --cached --name-only
                             --diff-filter=A` instead of
                             `origin/main...HEAD`). REQUIRES --strict;
                             no-op otherwise. Reads files from the working
                             tree (not from staged blobs) -- assumes the
                             typical git-add-then-commit flow. Used by
                             .githooks/pre-commit per AGENTS.md section 11.3.

Arguments:
  [wiki-directory]    Path to wiki directory (default: wiki-cloud/)

Exit codes:
  0  Script ran successfully (even if error-level findings exist)
  1  Script itself FAILED to run (python3 not found, wiki dir missing)

Examples:
  bin/lint.sh                      # Full lint, write report
  bin/lint.sh --dry-run            # Full lint, no report written
  bin/lint.sh --category orphan    # Only orphan detection
  bin/lint.sh --fix wiki-cloud/          # Full lint with auto-fixes
EOF
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

WIKI_DIR="${WIKI_ROOT:-wiki-cloud/}"
DRY_RUN=0
FIX=0
CATEGORY="all"
REQUIRE_VERSION=""
FORMAT="text"
CI_MODE=0
SKIP_CATEGORIES=""   # colon-separated list
STRICT_MODE=0
COUNT_SKIPS=0
STAGED_MODE=0

while [ "$#" -gt 0 ]; do
    case "$1" in
        --help|-h)
            usage
            exit 0
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --fix)
            FIX=1
            shift
            ;;
        --category)
            if [ "$#" -lt 2 ]; then
                echo "ERROR: --category requires a value" >&2
                exit 1
            fi
            CATEGORY="$2"
            shift 2
            ;;
        --version)
            echo "$LINT_VERSION"
            exit 0
            ;;
        --require-version)
            if [ "$#" -lt 2 ]; then
                echo "ERROR: --require-version requires a semver value (e.g., 1.1.0)" >&2
                exit 1
            fi
            REQUIRE_VERSION="$2"
            shift 2
            ;;
        --format)
            if [ "$#" -lt 2 ]; then
                echo "ERROR: --format requires a value (text or json)" >&2
                exit 1
            fi
            case "$2" in
                text|json) FORMAT="$2" ;;
                *) echo "ERROR: --format must be 'text' or 'json', got '$2'" >&2; exit 1 ;;
            esac
            shift 2
            ;;
        --ci)
            CI_MODE=1
            shift
            ;;
        --skip-category)
            if [ "$#" -lt 2 ]; then
                echo "ERROR: --skip-category requires a value" >&2
                exit 1
            fi
            if [ -z "$SKIP_CATEGORIES" ]; then
                SKIP_CATEGORIES="$2"
            else
                SKIP_CATEGORIES="$SKIP_CATEGORIES:$2"
            fi
            shift 2
            ;;
        --strict)
            STRICT_MODE=1
            shift
            ;;
        --count-skips)
            COUNT_SKIPS=1
            shift
            ;;
        --staged)
            STAGED_MODE=1
            shift
            ;;
        -*)
            echo "ERROR: Unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
        *)
            WIKI_DIR="$1"
            shift
            ;;
    esac
done

# ---------------------------------------------------------------------------
# Version-pin check (D-28 minimum-version semantics, semver tuple ordering)
# ---------------------------------------------------------------------------

if [ -n "$REQUIRE_VERSION" ]; then
    if ! python3 - "$LINT_VERSION" "$REQUIRE_VERSION" <<'PYEOF'
import sys
try:
    running = tuple(map(int, sys.argv[1].split('.')))
    required = tuple(map(int, sys.argv[2].split('.')))
except ValueError:
    print(f"ERROR: bin/lint.sh --require-version expected semver X.Y.Z, got '{sys.argv[2]}'", file=sys.stderr)
    sys.exit(1)
if running < required:
    print(f"ERROR: bin/lint.sh --require-version {sys.argv[2]} not satisfied. "
          f"Running version: {sys.argv[1]}. "
          f"Upgrade bin/lint.sh or lower the pin.", file=sys.stderr)
    sys.exit(1)
sys.exit(0)
PYEOF
    then
        exit 1
    fi
fi

# Normalize wiki dir (strip trailing slash for consistency, re-add)
WIKI_DIR="${WIKI_DIR%/}/"

# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------

if ! command -v python3 >/dev/null 2>&1; then
    echo "ERROR: python3 is required but not found" >&2
    exit 1
fi

if [ ! -d "$WIKI_DIR" ]; then
    echo "ERROR: Wiki directory does not exist: $WIKI_DIR" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# CI default skip: drift-external (D-02). Only applied when --ci and no user
# --skip-category value was provided; an explicit --skip-category wins.
# ---------------------------------------------------------------------------

if [ "$CI_MODE" -eq 1 ] && [ -z "$SKIP_CATEGORIES" ]; then
    SKIP_CATEGORIES="drift-external"
fi

# ---------------------------------------------------------------------------
# Temp file for finding accumulation + cleanup trap
# ---------------------------------------------------------------------------

FINDINGS_FILE=$(mktemp)
trap 'rm -f "$FINDINGS_FILE"' EXIT

echo "Linting ${WIKI_DIR}..." >&2

# ---------------------------------------------------------------------------
# Run all checks via a single python3 block
# ---------------------------------------------------------------------------

export LINT_WIKI_DIR="$WIKI_DIR"
export LINT_FINDINGS_FILE="$FINDINGS_FILE"
export LINT_DRY_RUN="$DRY_RUN"
export LINT_FIX="$FIX"
export LINT_CATEGORY="$CATEGORY"
export LINT_FORMAT="$FORMAT"
export LINT_CI_MODE="$CI_MODE"
export LINT_SKIP_CATEGORIES="$SKIP_CATEGORIES"
export LINT_STRICT_MODE="$STRICT_MODE"
export LINT_COUNT_SKIPS="$COUNT_SKIPS"
export LINT_STAGED_MODE="$STAGED_MODE"
export LINT_REPO_ROOT="${LINT_REPO_ROOT:-$PWD}"

python3 << 'PYEOF'
import sys, os, re, yaml
from datetime import date, timedelta
from pathlib import Path

# ---------------------------------------------------------------------------
# Arguments (from environment)
# ---------------------------------------------------------------------------

wiki_dir = os.environ['LINT_WIKI_DIR']
findings_file = os.environ['LINT_FINDINGS_FILE']
dry_run = os.environ['LINT_DRY_RUN'] == "1"
do_fix = os.environ['LINT_FIX'] == "1"
category_filter = os.environ['LINT_CATEGORY']

# --- Phase 9 CI-mode primitives (D-01..D-06) ---
CI_MODE = os.environ.get('LINT_CI_MODE', '0') == '1'
LINT_FORMAT = os.environ.get('LINT_FORMAT', 'text')
SKIP_CATEGORIES = set(filter(None, os.environ.get('LINT_SKIP_CATEGORIES', '').split(':')))

# --- Phase 9 Plan 03 primitives (D-07..D-11, D-22) ---
STRICT_MODE = os.environ.get('LINT_STRICT_MODE', '0') == '1'
COUNT_SKIPS_MODE = os.environ.get('LINT_COUNT_SKIPS', '0') == '1'
STAGED_MODE = os.environ.get('LINT_STAGED_MODE', '0') == '1'
REPO_ROOT = os.environ.get('LINT_REPO_ROOT', os.getcwd())

import subprocess

# Escape-hatch marker regex (D-09). Matches on line IMMEDIATELY above claim.
# `id` must match containing page's frontmatter id; `reason` must be non-empty.
EXPECT_MARKER_RE = re.compile(
    r'^<!--\s*lint:expect-(?P<kind>inferred|tentative)\s+'
    r'id=(?P<id>[a-z0-9-]+)\s+'
    r'reason="(?P<reason>[^"]+)"\s*-->\s*$'
)

# Inline epistemic marker regex (subset: only inferred|tentative gate --strict).
EPISTEMIC_INFERRED_RE = re.compile(r'\[epistemic::\s*(?P<kind>inferred|tentative)\s*\]')

# Provenance presence check (D-10).
PROVENANCE_PRESENCE_RE = re.compile(r'\[prov:')

# Types that require [prov:] markers when added as new pages (D-10).
PROVENANCE_REQUIRED_TYPES = {'entity', 'concept', 'overview', 'comparison'}

# Severity remap dispatch table (D-02, D-05). Any add_finding() category not
# listed here retains its original severity. Plan 03 extends this with new
# categories (`contributor`, `skip-count`) in one line each.
CI_SEVERITY_REMAP = {
    'yaml':               'error',
    'orphan':             'error',
    'crossref':           'error',
    'provenance':         'error',
    'linkres':            'error',    # high-confidence graph defects gate CI (LINK-04, LINK-05)
    'stale':              'warning',
    'gap':                'warning',
    'contradiction':      'warning',
    'contradiction-sync': 'warning',
    'drift':              'warning',
    'contributor':        'warning',   # Plan 03 populates
    'brownfield':         'warning',   # Phase 10 populates
    'autofix':            'info',
    'skip-count':         'info',      # Plan 03 populates
}

def matches_skip(cat, msg, skip_set):
    """Return True iff the finding (cat, msg) should be dropped per skip_set.

    Supports both plain-category skips (e.g., 'yaml') and the
    'drift-external' LOGICAL SUBCATEGORY skip, which targets drift findings
    whose message begins with the `EXTERNAL: ` token (DRFT-03 Obsidian-vault
    awareness and future external-state checks). Plain 'drift' in skip_set
    drops ALL drift findings.

    EXTERNAL: prefix marks drift findings originating from external-state
    checks (DRFT-03 Obsidian vault awareness). The --skip-category drift-external
    filter (applied by --ci default) consults this prefix. See AGENTS.md §11.3.
    """
    if cat in skip_set:
        return True
    if 'drift-external' in skip_set and cat == 'drift' and msg.startswith('EXTERNAL: '):
        return True
    return False

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

DECAY_RATES = {
    'software': timedelta(days=180),
    'technology': timedelta(days=180),
    'science': timedelta(days=730),
    'biography': timedelta(days=1825),
    'personal-goals': timedelta(days=90),
}
DEFAULT_DECAY = timedelta(days=365)

EPISTEMIC_MODIFIERS = {
    'tentative': 0.5,
    'inferred': 0.75,
    'sourced': 1.0,
    'mixed': 0.85,
}

VALID_TYPES = {'entity', 'concept', 'source', 'comparison', 'overview', 'decision'}
VALID_STATUS = {'active', 'stale', 'superseded', 'archived'}
VALID_EPISTEMIC = {'sourced', 'mixed', 'tentative', 'stale'}
VALID_COMPILATION = {'pending', 'partial', 'compiled', 'stale'}

BASE_FIELDS = [
    'id', 'title', 'type', 'status', 'summary', 'created_at', 'updated_at',
    'sources', 'epistemic_status', 'tags', 'domains', 'supersedes',
    'superseded_by', 'aliases', 'has_contradictions', 'knowledge_domain',
]

SOURCE_EXTRA_FIELDS = ['path', 'content_hash', 'ingested_at', 'source_type', 'compilation_status']

WIKILINK_RE = re.compile(r'\[\[([^\]|]+)(?:\|[^\]]+)?\]\]')

# Distinguishing regexes: used by linkres scan (Step C) AND orphan inbound scan (Step D).
# BARE_LINK_RE: matches bare [[target]] (no pipe). Note: BARE_LINK_RE naively also matches
# the target side of a piped link; caller must subtract piped spans (see _in_piped helper).
PIPED_LINK_RE = re.compile(r'\[\[([^\]|]+)\|([^\]]+)\]\]')  # (target, display)
BARE_LINK_RE  = re.compile(r'\[\[([^\]|\n]+)\]\]')           # bare target, no pipe

# ---------------------------------------------------------------------------
# Shared markdown-masking helper (review HIGH #2, #3 -- load-bearing).
# Neutralises YAML frontmatter, fenced code blocks, HTML comments, and inline
# code spans BEFORE both the linkres scan AND the --fix rewrite so that literal
# [[id|Title]] / [[X]] examples inside those spans are NEVER flagged or rewritten.
# The replacement is LENGTH-PRESERVING (newlines kept, other chars -> space)
# so character offsets are aligned between the masked string and the real content.
# This is REQUIRED for the positional --fix (Step C): bare-link span offsets
# found in the masked copy map 1:1 to the real content, enabling splice rewrites
# that preserve frontmatter and code-fence content byte-for-byte.
# ---------------------------------------------------------------------------

_FENCE_RE   = re.compile(r'(^|\n)(```|~~~)[^\n]*\n.*?\n\2[ \t]*(?=\n|$)', re.DOTALL)
_HTMLCOM_RE = re.compile(r'<!--.*?-->', re.DOTALL)
_INLINE_RE  = re.compile(r'`[^`\n]*`')
_FM_RE      = re.compile(r'\A---\n.*?\n---\n', re.DOTALL)

def mask_markdown(text):
    """Return a length-preserving copy of `text` with YAML frontmatter, fenced code,
    HTML comments, and inline code replaced by spaces (newlines kept). Offsets are
    preserved so positional --fix can map masked-match spans back to the real content.
    Order matters: frontmatter and fences first (they may contain <!-- / backticks),
    then HTML comments, then inline code."""
    def _blank(m):
        return ''.join('\n' if c == '\n' else ' ' for c in m.group(0))
    masked = _FM_RE.sub(_blank, text)
    masked = _FENCE_RE.sub(_blank, masked)
    masked = _HTMLCOM_RE.sub(_blank, masked)
    masked = _INLINE_RE.sub(_blank, masked)
    return masked

PROV_RE = re.compile(
    r'\[prov:([^#\]]+)#([^|\]]+)'
    r'(?:\|([^|\]]+))?'
    r'(?:\|([^\]]+))?'
    r'\]'
)
EPISTEMIC_INLINE_RE = re.compile(r'\[epistemic::\s*(sourced|mixed|inferred|tentative|stale)\]')

# Files to exclude from lint candidate list
EXCLUDE_FILES = {'index.md', 'log.md'}
EXCLUDE_DIRS = {'maintenance', 'examples'}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

findings = []

def add_finding(severity, category, path, message):
    findings.append((severity, category, path, message))

def parse_frontmatter(filepath):
    """Extract YAML frontmatter and body from a wiki page."""
    try:
        content = open(filepath, encoding='utf-8').read()
    except Exception as e:
        return None, '', str(e)
    if not content.startswith('---'):
        return None, content, None
    try:
        end = content.index('---', 3)
        fm = yaml.safe_load(content[3:end])
        body = content[end+3:]
        return fm, body, None
    except ValueError:
        return None, content, 'Unterminated frontmatter (missing closing ---)'
    except yaml.YAMLError as e:
        return None, content, f'YAML parse error: {e}'

def should_run(cat):
    return category_filter == 'all' or category_filter == cat

# ---------------------------------------------------------------------------
# Phase 9 Plan 03 helpers: --strict (CI-06), escape-hatch marker parser,
# PR-diff-scoped epistemic claim detection (D-08), new-page provenance check
# (D-10), origin/main fallback.
# ---------------------------------------------------------------------------

def parse_fm_from_text(content):
    """Return parsed YAML frontmatter dict from raw content, or None."""
    if not content.startswith('---'):
        return None
    try:
        end = content.index('---', 3)
    except ValueError:
        return None
    try:
        return yaml.safe_load(content[3:end]) or {}
    except yaml.YAMLError:
        return None


def has_origin_main():
    """Return True iff refs/remotes/origin/main exists.

    Used for the --strict local-mode fallback (see stderr WARN path below).
    CI runs always have origin/main (fetch-depth: 0); local dev may not.
    """
    try:
        subprocess.run(
            ['git', 'show-ref', '--verify', '--quiet', 'refs/remotes/origin/main'],
            cwd=REPO_ROOT, check=True, capture_output=True,
        )
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False


def strict_added_epistemic_claims(base_ref='origin/main'):
    """D-08 (PR-diff scope): parse `git diff origin/main...HEAD -- wiki-cloud/` and
       return a list of (path, line_no, kind) tuples for EACH line ADDED by
       the PR that contains [epistemic:: inferred] or [epistemic:: tentative].

       - line_no is the NEW-file line number (post-PR), 1-indexed.
       - kind is 'inferred' or 'tentative'.
       - `path` is the new-file path (diff 'b/' side).
       - Pages entirely new to the PR (status A) have ALL their epistemic
         claims surfaced here, not only the diff context.

       Ignores the `+++` file-header line (diff metadata, not content)."""
    try:
        result = subprocess.run(
            ['git', 'diff', '--unified=0', f'{base_ref}...HEAD', '--', 'wiki-cloud/'],
            cwd=REPO_ROOT, check=True, capture_output=True, text=True,
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        return []
    added = []
    current_path = None
    current_new_lineno = None
    hunk_header_re = re.compile(r'^@@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? @@')
    for line in result.stdout.splitlines():
        # File header: "+++ b/<path>"
        if line.startswith('+++ '):
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
            continue
        # Hunk header: "@@ -A,B +C,D @@ ..." — extract the new-side start line.
        if line.startswith('@@'):
            m = hunk_header_re.match(line)
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
            content = line[1:]  # strip leading '+'
            m = EPISTEMIC_INFERRED_RE.search(content)
            if m:
                added.append((current_path, current_new_lineno, m.group('kind')))
            current_new_lineno += 1
        elif line.startswith('-') and not line.startswith('---'):
            # Removed line: does NOT advance new-side line counter.
            pass
        else:
            # Context line (shouldn't appear with --unified=0 but defensive).
            current_new_lineno += 1
    return added


def strict_new_pages(base_ref='origin/main'):
    """D-10: return list of git-diff status-A .md paths under
       wiki-cloud/{entities,concepts,overviews,comparisons}/*.md."""
    try:
        result = subprocess.run(
            ['git', 'diff', '--name-status', f'{base_ref}...HEAD'],
            cwd=REPO_ROOT, check=True, capture_output=True, text=True,
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
            if path.startswith(f'wiki-cloud/{t}/'):
                paths.append(path)
                break
    return paths


def staged_new_pages():
    """WGATE-02 / D-02: return list of git-diff status-A .md paths under
       wiki-cloud/{entities,concepts,overviews,comparisons}/*.md, scoped to the
       STAGED INDEX (not origin/main...HEAD).

       Diff source: `git diff --cached --name-only --diff-filter=A`.
       --diff-filter=A returns ONLY added paths, so the returned list is
       direct (no status column to parse).

       Files are read from the working tree, not from staged blobs (D-03).
       Pre-commit hooks fire after `git add`, so working-tree content
       matches the index for the typical add-then-commit flow.
    """
    try:
        result = subprocess.run(
            ['git', 'diff', '--cached', '--name-only', '--diff-filter=A'],
            cwd=REPO_ROOT, check=True, capture_output=True, text=True,
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        return []
    paths = []
    for line in result.stdout.splitlines():
        path = line.strip()
        if not path or not path.endswith('.md'):
            continue
        # D-15 (2): examples/ anywhere in the tree -> path-prefix exemption.
        if path.startswith('examples/') or '/examples/' in path:
            continue
        # D-15 (1): only the four PROVENANCE_REQUIRED_TYPES dirs reach the
        # frontmatter check. wiki-cloud/sources/, wiki-cloud/decisions/, anything outside
        # wiki-cloud/ are skipped at this layer.
        for t in ('entities', 'concepts', 'overviews', 'comparisons'):
            if path.startswith(f'wiki-cloud/{t}/'):
                paths.append(path)
                break
    return paths


def collect_dr_affected_pages(wiki_root):
    """D-08 helper: union of affected_pages lists across ALL type: decision
       pages in the wiki. Built wiki-wide because decisions already merged are
       valid coverage for current-PR claims. What's PR-diff-scoped is the SET
       OF CLAIMS checked; the DR index itself is historical."""
    covered = set()
    decisions_dir = os.path.join(wiki_root, 'decisions')
    if not os.path.isdir(decisions_dir):
        return covered
    for fn in sorted(os.listdir(decisions_dir)):
        if not fn.endswith('.md'):
            continue
        try:
            content = open(os.path.join(decisions_dir, fn), encoding='utf-8').read()
        except OSError:
            continue
        fm = parse_fm_from_text(content)
        if not fm or fm.get('type') != 'decision':
            continue
        for pid in (fm.get('affected_pages') or []):
            if pid:
                covered.add(str(pid))
    return covered


def page_id_for_path(path):
    """Return the id frontmatter field of the markdown page at `path`
       (resolved against REPO_ROOT), or '' on miss."""
    abs_path = path if os.path.isabs(path) else os.path.join(REPO_ROOT, path)
    try:
        content = open(abs_path, encoding='utf-8').read()
    except OSError:
        return ''
    fm = parse_fm_from_text(content)
    if not fm:
        return ''
    return str(fm.get('id', '') or '')


def is_claim_excepted_by_adjacent_marker(path, claim_line_no, page_id):
    """D-09: True iff the line IMMEDIATELY above `claim_line_no` (1-indexed)
       in the working-tree file at `path` is a matching lint:expect-* marker.
       Blank line between marker and claim invalidates the exemption."""
    if claim_line_no <= 1:
        return False
    abs_path = path if os.path.isabs(path) else os.path.join(REPO_ROOT, path)
    try:
        lines = open(abs_path, encoding='utf-8').read().splitlines()
    except OSError:
        return False
    prev_idx = claim_line_no - 2  # 0-indexed line above the claim
    if prev_idx < 0 or prev_idx >= len(lines):
        return False
    m = EXPECT_MARKER_RE.match(lines[prev_idx].rstrip('\n'))
    if not m:
        return False
    if m.group('id') != page_id:
        return False
    return bool(m.group('reason').strip())


def _strict_check_fallback(wiki_root):
    """Local-mode fallback when origin/main is absent. Mirrors the pre-revision
       wiki-wide scan. Prints stderr WARN above, then scans all wiki pages.
       Useful for offline iteration; CI never hits this path."""
    dr_covered = collect_dr_affected_pages(wiki_root)
    for dirpath, _, files in os.walk(wiki_root):
        # Skip examples/ and decisions/ (both are never subject to strict gate)
        rel_parts = os.path.relpath(dirpath, wiki_root).split(os.sep)
        if 'examples' in rel_parts or rel_parts[0] == 'decisions':
            continue
        for fn in sorted(files):
            if not fn.endswith('.md'):
                continue
            path = os.path.join(dirpath, fn)
            try:
                text = open(path, encoding='utf-8').read()
            except OSError:
                continue
            fm = parse_fm_from_text(text)
            if not fm:
                continue
            page_id = str(fm.get('id', '') or '')
            rel = os.path.relpath(path)
            body_lines = text.splitlines()
            for i, line in enumerate(body_lines):
                m = EPISTEMIC_INFERRED_RE.search(line)
                if not m:
                    continue
                claim_line_no = i + 1
                if is_claim_excepted_by_adjacent_marker(path, claim_line_no, page_id):
                    add_finding('info', 'skip-count', rel,
                                f"line {claim_line_no}: {m.group('kind')} claim exempted via lint:expect-* marker")
                    continue
                if page_id and page_id not in dr_covered:
                    add_finding('error', 'strict', rel,
                                f"line {claim_line_no}: [{m.group('kind')}] claim without matching decision record "
                                f"(local-mode scan: no origin/main ref present)")
    # New-page check is inherently PR-diff-scoped (D-10 requires status A); skip in fallback.


def strict_check(wiki_root):
    """Run --strict checks.
       - Staged-mode (D-02 / WGATE-02): when STAGED_MODE is set, ONLY check
         new-page provenance against the staged index. Origin-independent.
         Returns immediately -- does not run the DR-match block or
         has_origin_main() fallback.
       - DR-match (D-08, PR-diff-scoped): fail on [epistemic:: inferred|tentative]
         claims ADDED by this PR unless matched by a wiki decision record's
         affected_pages, or exempted by an adjacent lint:expect-* marker.
       - New-page provenance (D-10): fail on status-A pages of type
         entity/concept/overview/comparison with zero [prov: markers.

       Appends findings (severity='error', cat='strict' or 'provenance') on
       violation. Exempted claims appended as (severity='info', cat='skip-count').
    """
    if not STRICT_MODE:
        return

    # WGATE-02 / D-02 / D-19: Staged-mode dispatch. MUST run BEFORE
    # has_origin_main() -- staged-mode is origin-independent (uses
    # `git diff --cached`, which works on any repo with a HEAD commit).
    # Without this early branch, the has_origin_main() early-return below
    # would route bare `git init -b main` fixtures into _strict_check_fallback,
    # which explicitly skips the new-page check (line ~634 comment). The gate
    # would silently no-op on fresh clones / local-only repos -- the canonical
    # Phase 12.2 target environment per CONTEXT.md trunk-based-dev framing.
    # Per D-04, staged-mode runs D-10 ONLY (no D-08 DR-match). The early
    # `return` after the loop ensures strict_added_epistemic_claims() is
    # never reached when STAGED_MODE is active.
    if STAGED_MODE:
        new_pages = staged_new_pages()
        for path in new_pages:
            abs_path = path if os.path.isabs(path) else os.path.join(REPO_ROOT, path)
            if not os.path.exists(abs_path):
                # File was staged then deleted/moved between diff-list and read.
                # Treat as non-blocking (T-12.2-02-03 race-condition handling).
                continue
            try:
                text = open(abs_path, encoding='utf-8').read()
            except OSError:
                continue
            fm = parse_fm_from_text(text)
            if not fm:
                continue
            # D-15 (3) type:source / D-15 (4) type:decision: exempt by type.
            # The PROVENANCE_REQUIRED_TYPES check below mechanically filters
            # these out (source and decision are NOT in PROVENANCE_REQUIRED_TYPES).
            t = fm.get('type', '')
            if t not in PROVENANCE_REQUIRED_TYPES:
                continue
            # D-15 (5) example:true: brownfield/example pages are exempt.
            if fm.get('example') is True:
                continue
            # D-15 (6) bootstrap_stage:bootstrapped: brownfield in-flight pages
            # are exempt. bootstrap_stage:verified is NOT exempt (D-12) -- those
            # pages have been promoted through verify --promote and are
            # first-class wiki content from the gate's perspective.
            if fm.get('bootstrap_stage') == 'bootstrapped':
                continue
            if not PROVENANCE_PRESENCE_RE.search(text):
                # D-08 (failure UX): emit the actionable-paths message in
                # staged-mode. PR-mode uses the original concise message
                # (preserved verbatim -- Phase-09 tests may grep against it).
                add_finding('error', 'provenance', path,
                            f"new {t} page has zero [prov:...] markers "
                            f"(D-10; add [prov:source_id#locator] markers, "
                            f"set type:source/decision in frontmatter, or "
                            f"`git commit --no-verify` to bypass)")
        return  # Staged-mode is independent of PR-mode flow -- exit before has_origin_main.

    # Local-mode fallback: if origin/main is absent, warn and fall back to wiki-wide scan.
    # CI always has origin/main (fetch-depth: 0); local dev may not.
    if not has_origin_main():
        print("WARN: no origin/main; scanning all wiki pages (local mode)", file=sys.stderr)
        _strict_check_fallback(wiki_root)
        return

    dr_covered = collect_dr_affected_pages(wiki_root)

    # 1. DR-match: scan ONLY the claims ADDED by this PR (D-08).
    added = strict_added_epistemic_claims()
    for path, line_no, kind in added:
        # path is repo-relative (e.g., 'wiki-cloud/concepts/attention.md'). Skip examples/ and decisions/.
        if path.startswith('examples/') or '/examples/' in path:
            continue
        if path.startswith('wiki-cloud/decisions/'):
            # Decision records themselves can contain epistemic markers in their prose;
            # they ARE the gating mechanism and must not gate on themselves.
            continue
        page_id = page_id_for_path(path)
        if not page_id:
            continue
        # D-09 escape-hatch check uses working-tree content (marker on line above claim)
        if is_claim_excepted_by_adjacent_marker(path, line_no, page_id):
            add_finding('info', 'skip-count', path,
                        f"line {line_no}: {kind} claim exempted via lint:expect-* marker")
            continue
        if page_id in dr_covered:
            continue
        add_finding('error', 'strict', path,
                    f"line {line_no}: [{kind}] claim added by this PR without matching decision record "
                    f"(add wiki-cloud/decisions/*.md with type:decision, affected_pages: [{page_id}], "
                    f"or add <!-- lint:expect-{kind} id={page_id} reason=\"...\" --> above)")

    # 2. New-page provenance: for each git-diff status A wiki page under PROVENANCE_REQUIRED_TYPES
    new_pages = strict_new_pages()
    for path in new_pages:
        abs_path = path if os.path.isabs(path) else os.path.join(REPO_ROOT, path)
        if not os.path.exists(abs_path):
            continue
        try:
            text = open(abs_path, encoding='utf-8').read()
        except OSError:
            continue
        fm = parse_fm_from_text(text)
        if not fm:
            continue
        t = fm.get('type', '')
        if t not in PROVENANCE_REQUIRED_TYPES:
            continue  # source/decision exempt by design
        if not PROVENANCE_PRESENCE_RE.search(text):
            add_finding('error', 'provenance', path,
                        f"new {t} page has zero [prov:...] markers (D-10)")


def count_skips_aggregate(wiki_root):
    """D-09 aggregator: scan wiki for all lint:expect-* markers, emit one
       info/skip-count finding per marker. Unlike strict_check (which emits
       skip-count only for actually-exempted inferred/tentative claims),
       this mode enumerates every marker for human-review visibility.

       Prints a human-readable grand total to stderr independent of --format."""
    if not COUNT_SKIPS_MODE:
        return
    per_page = {}
    for dirpath, _, files in os.walk(wiki_root):
        # Skip examples/ and maintenance/ (same exclusions as main walk)
        rel_parts = os.path.relpath(dirpath, wiki_root).split(os.sep)
        if rel_parts[0] in EXCLUDE_DIRS:
            continue
        for fn in sorted(files):
            if not fn.endswith('.md'):
                continue
            path = os.path.join(dirpath, fn)
            try:
                lines = open(path, encoding='utf-8').read().splitlines()
            except OSError:
                continue
            rel = os.path.relpath(path)
            count = 0
            for i, line in enumerate(lines):
                m = EXPECT_MARKER_RE.match(line.rstrip('\n'))
                if not m:
                    continue
                count += 1
                add_finding(
                    'info', 'skip-count', rel,
                    f"line {i+1}: lint:expect-{m.group('kind')} "
                    f"id={m.group('id')} reason=\"{m.group('reason')}\""
                )
            if count > 0:
                per_page[rel] = count
    total = sum(per_page.values())
    if total > 0:
        print(
            f"--count-skips: {total} skipped findings across {len(per_page)} pages",
            file=sys.stderr,
        )


# ---------------------------------------------------------------------------
# Contributor category (COLAB-08 / D-22)
# ---------------------------------------------------------------------------

def parse_author_map(root):
    """Parse .git-author-map.txt at repo root. Return dict {email_lc: @handle}.

    Accepts two separator conventions: "email  ->  @handle" (two-space-arrow-
    two-space) or tab separator. Comments start with `#`; email match is
    case-insensitive.
    """
    path = os.path.join(root, '.git-author-map.txt')
    mapping = {}
    if not os.path.isfile(path):
        return mapping
    try:
        raw_lines = open(path, encoding='utf-8').read().splitlines()
    except OSError:
        return mapping
    for raw in raw_lines:
        line = raw.strip()
        if not line or line.startswith('#'):
            continue
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


def contributor_check(wiki_root, repo_root):
    """COLAB-08 / D-22: for each `contributor:: @handle` in wiki-cloud/log.md,
       verify handle's email (via .git-author-map.txt reverse lookup)
       appears in git log --all --format='%ae'. Short-circuit when
       single-author (D-20).

       Finding severity is always `warning` (non-blocking); CI_SEVERITY_REMAP
       preserves this."""
    if not should_run('contributor'):
        return
    log_path = os.path.join(wiki_root, 'log.md')
    if not os.path.isfile(log_path):
        return
    git_emails = git_author_emails(repo_root)
    # D-20 single-author short-circuit: personal forks emit no contributor
    # findings because the single-author heuristic suppresses the field anyway.
    if len(git_emails) <= 1:
        return
    mapping = parse_author_map(repo_root)
    # Reverse lookup: handle (lowercase) -> email
    reverse = {handle.lower(): email for email, handle in mapping.items()}
    contrib_re = re.compile(r'contributor::\s*(@[a-zA-Z0-9_\-]+)')
    seen = set()
    rel_log = os.path.relpath(log_path)
    try:
        log_lines = open(log_path, encoding='utf-8').read().splitlines()
    except OSError:
        return
    for i, line in enumerate(log_lines):
        for m in contrib_re.finditer(line):
            handle = m.group(1)
            key = handle.lower()
            if key in seen:
                continue
            seen.add(key)
            email = reverse.get(key)
            if email is None:
                add_finding('warning', 'contributor', rel_log,
                            f"line {i+1}: {handle} has no mapping in .git-author-map.txt")
            elif email not in git_emails:
                add_finding('warning', 'contributor', rel_log,
                            f"line {i+1}: {handle} mapped to {email} "
                            f"but email not in git commit authors")

# ---------------------------------------------------------------------------
# Collect all wiki pages
# ---------------------------------------------------------------------------

all_pages = []  # (path, fm, body, error)
source_pages = []  # (path, fm, body)

for root, dirs, files in os.walk(wiki_dir):
    # Skip maintenance directory for lint candidates
    rel_root = os.path.relpath(root, wiki_dir)
    if rel_root.split(os.sep)[0] in EXCLUDE_DIRS:
        continue
    for fname in sorted(files):
        if not fname.endswith('.md'):
            continue
        if fname in EXCLUDE_FILES:
            continue
        fpath = os.path.join(root, fname)
        fm, body, err = parse_frontmatter(fpath)
        # NEUT-04 (D-09 fallback): example: true suppresses all health checks.
        if isinstance(fm, dict) and fm.get('example') is True:
            continue
        all_pages.append((fpath, fm, body, err))
        if fm and fm.get('type') == 'source':
            source_pages.append((fpath, fm, body))

# Build source registry: source_id -> source fm
source_registry = {}
for sp, sfm, sbody in source_pages:
    if sfm and 'id' in sfm:
        source_registry[sfm['id']] = sfm

# ---------------------------------------------------------------------------
# Phase 10 (BRWN-08): identify bootstrapped pages for the --ci error->info
# downgrade applied later in the CI_MODE block. Build once here from the
# already-parsed frontmatter so the downgrade is O(1) per finding.
# BROWNFIELD_ALLOWLIST: categories eligible for downgrade (matches the plan's
# "unknown type, empty knowledge_domain, missing sources, epistemic_status:
# tentative" surface which manifests as yaml/provenance/orphan findings).
# ---------------------------------------------------------------------------

BROWNFIELD_ALLOWLIST = {'yaml', 'provenance', 'orphan'}
BROWNFIELD_BOOTSTRAPPED_PAGES = set()
for page_path, page_fm, _body, _err in all_pages:
    if page_fm and page_fm.get('bootstrap_stage') == 'bootstrapped':
        BROWNFIELD_BOOTSTRAPPED_PAGES.add(os.path.relpath(page_path))

# ---------------------------------------------------------------------------
# Check 1: YAML frontmatter validation
# ---------------------------------------------------------------------------

if should_run('yaml'):
    print("  Checking YAML frontmatter...", file=sys.stderr)
    for fpath, fm, body, err in all_pages:
        rel = os.path.relpath(fpath)
        if err:
            add_finding('error', 'yaml', rel, f'Frontmatter parse error: {err}')
            continue
        if fm is None:
            add_finding('error', 'yaml', rel, 'No YAML frontmatter found')
            continue

        # Check base fields
        missing = [f for f in BASE_FIELDS if f not in fm]
        if missing:
            add_finding('error', 'yaml', rel, f'Missing required fields: {missing}')

        # Validate enums
        if 'type' in fm and fm['type'] not in VALID_TYPES:
            add_finding('error', 'yaml', rel, f"Invalid type: '{fm['type']}'")
        if 'status' in fm and fm['status'] not in VALID_STATUS:
            add_finding('error', 'yaml', rel, f"Invalid status: '{fm['status']}'")
        if 'epistemic_status' in fm and fm['epistemic_status'] not in VALID_EPISTEMIC:
            add_finding('error', 'yaml', rel, f"Invalid epistemic_status: '{fm['epistemic_status']}'")

        # Source-specific fields
        if fm.get('type') == 'source':
            missing_src = [f for f in SOURCE_EXTRA_FIELDS if f not in fm]
            if missing_src:
                add_finding('error', 'yaml', rel, f'Source page missing fields: {missing_src}')
            cs = fm.get('compilation_status')
            if cs and cs not in VALID_COMPILATION:
                add_finding('error', 'yaml', rel, f"Invalid compilation_status: '{cs}'")

        # Decision record validation (per AGENTS.md section 5 items 15-17)
        if fm.get('type') == 'decision':
            VALID_TRIGGER_TYPES = {'merge', 'split', 'schema-update', 'domain-reorg', 'reframing', 'contradiction-resolution'}
            tt = fm.get('trigger_type', '')
            if not tt:
                add_finding('error', 'yaml', rel, 'Decision page missing trigger_type')
            elif tt not in VALID_TRIGGER_TYPES:
                add_finding('error', 'yaml', rel, f'Invalid trigger_type: {tt} (expected one of: {", ".join(sorted(VALID_TRIGGER_TYPES))})')
            ap = fm.get('affected_pages')
            if ap is None:
                add_finding('error', 'yaml', rel, 'Decision page missing affected_pages field')
            elif not isinstance(ap, list):
                add_finding('error', 'yaml', rel, 'affected_pages must be a YAML list')

        # decision_history validation (optional field on any page type, per item 17)
        dh = fm.get('decision_history')
        if dh is not None:
            if not isinstance(dh, list):
                add_finding('error', 'yaml', rel, 'decision_history must be a YAML list')
            elif not all(isinstance(item, str) for item in dh):
                add_finding('error', 'yaml', rel, 'decision_history items must be strings')

# ---------------------------------------------------------------------------
# Check 2: Provenance validation
# ---------------------------------------------------------------------------

if should_run('provenance'):
    print("  Checking provenance references...", file=sys.stderr)
    for fpath, fm, body, err in all_pages:
        if err or fm is None:
            continue
        rel = os.path.relpath(fpath)
        # Mask frontmatter, fenced code, inline code, and HTML comments before
        # scanning so literal [prov:...] examples in documentation prose (e.g. a
        # decision record showing the provenance grammar inside backticks) are not
        # mis-flagged as broken references. Consistent with the linkres masking
        # introduced in 14-02; real markers in prose remain validated.
        prov_matches = PROV_RE.findall(mask_markdown(body))
        for source_id, locator, support_type, checked_at in prov_matches:
            if source_id not in source_registry:
                add_finding('error', 'provenance', rel,
                            f'Broken prov ref: {source_id} not found in {wiki_dir}sources/')

# ---------------------------------------------------------------------------
# Shared normalization helper (D-02: used by linkres + reconciled orphan/gap)
# ---------------------------------------------------------------------------

_PLURAL_MAP = {
    'contexts': 'context',
    'policies': 'policy',
    'contracts': 'contract',
}
_PUNCT_RE = re.compile(r'[^\w\s]')   # strips parens, hyphens, punctuation characters
_WS_RE    = re.compile(r'\s+')

def normalize_link(text):
    """D-02: casefold, strip punctuation chars (parens stripped as CHARACTERS not
    content -- 'Hack (Agentive Stack)' -> 'hack agentive stack', NOT 'hack'),
    collapse whitespace, apply small explicit plural map (contexts->context,
    policies->policy, contracts->contract). NO edit distance, NO stemmer."""
    s = text.casefold()
    s = _PUNCT_RE.sub(' ', s)   # parens/hyphen/punct -> space
    s = s.replace('_', ' ')     # re \w includes underscore; handle separately
    s = _WS_RE.sub(' ', s).strip()
    words = [_PLURAL_MAP.get(w, w) for w in s.split()]
    return ' '.join(words)

def _yaml_quote_alias(a):
    """YAML-double-quote a scalar so colons/brackets/leading indicators stay strings.
    CONFIRMED HIGH BUG #2 fix: an unquoted '  - Topic: Subtitle' parses as a DICT."""
    s = str(a).replace('\\', '\\\\').replace('"', '\\"')
    return f'"{s}"'

def _apply_self_alias_fix(fpath, fm, to_add):
    """Idempotent: append the already-computed missing aliases (to_add: list of raw
    strings) to the page's aliases block. Caller computes to_add ONCE per page (title
    and/or id) and calls this ONCE -- no stale-fm second call (review F / Codex). Never
    removes existing aliases. Regex confined to the frontmatter section (up to second
    '---') to avoid matching body 'aliases:' text (Pitfall 2). Emits YAML-double-quoted
    values so colon-bearing titles stay STRINGS (HIGH BUG #2)."""
    if not to_add:
        return  # nothing missing -- idempotent no-op
    try:
        content = open(fpath, encoding='utf-8').read()
        fm_end = content.find('\n---', 3)  # skip opening ---
        fm_section = content[:fm_end] if fm_end != -1 else content
        existing = [str(a) for a in (fm.get('aliases') or []) if a]
        new_aliases = existing + list(to_add)
        # Quote EVERY value (existing too -- harmless, and repairs any prior unquoted entry):
        aliases_lines = '\n'.join(f'  - {_yaml_quote_alias(a)}' for a in new_aliases)
        new_block = f'aliases:\n{aliases_lines}'
        ALIASES_RE = re.compile(r'^aliases:.*?(?=^\w|\Z)', re.MULTILINE | re.DOTALL)
        new_fm = ALIASES_RE.sub(new_block + '\n', fm_section, count=1)
        if new_fm == fm_section:
            print(f"  warn: --fix could not locate aliases block in {os.path.relpath(fpath)} "
                  f"(skipped to avoid corruption)", file=sys.stderr)
            return  # Regex did not match; skip to avoid corruption
        new_content = new_fm + content[len(fm_section):]
        with open(fpath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        add_finding('info', 'autofix', os.path.relpath(fpath),
                    f'Added self-aliases: {list(to_add)}')
    except Exception as e:
        # Review F / Codex LOW: surface batch-fix failures instead of swallowing them.
        print(f"  warn: --fix failed on {os.path.relpath(fpath)}: {e}", file=sys.stderr)

# ---------------------------------------------------------------------------
# Check 3: Orphan detection (case-insensitive, alias-aware)
# ---------------------------------------------------------------------------

if should_run('orphan'):
    print("  Checking for orphan pages...", file=sys.stderr)

    # Build resolution map: filename stem / id ONLY (NOT aliases, NOT title).
    # Review HIGH #5: aliases removed from orphan resolution map so that the 53
    # vestigial self-aliases on main cannot falsely mark pages as connected.
    # Obsidian resolves [[X]] by filename/path only; the orphan check must mirror
    # this: a page is only "reached" by an inbound [[id]] or [[stem]] link,
    # never by an [[Alias]] link against a vestigial self-alias entry.
    obsidian_map = {}  # lowercase filename stem -> set of page ids (id-only resolution)
    page_ids = set()

    for fpath, fm, body, err in all_pages:
        if fm is None:
            continue
        pid = fm.get('id', '')
        if not pid:
            continue
        page_ids.add(pid)
        stem = os.path.splitext(os.path.basename(fpath))[0].lower()
        obsidian_map.setdefault(stem, set()).add(pid)
        # NOTE: aliases are intentionally NOT indexed here (review HIGH #5).
        # The old alias-indexing loop has been removed. Orphan resolution is
        # filename-stem / id ONLY -- alias membership does not save a page from
        # being an orphan.

    # Keep resolution_map as alias for gap block backward compat (Pitfall 3)
    resolution_map = obsidian_map

    # Collect all wikilinks from all pages (lowercased)
    inbound_links = {}  # page_id -> set of linking page_ids
    for pid in page_ids:
        inbound_links[pid] = set()

    for fpath, fm, body, err in all_pages:
        if fm is None or body is None:
            continue
        linker_id = fm.get('id', '')
        # Run over the MASKED body so [[id|Title]] examples inside code fences,
        # HTML comments, or inline code do NOT count as real inbound links.
        # WIKILINK_RE yields target-before-pipe for both bare and piped forms,
        # so a piped [[id|Title]] correctly resolves to the page whose stem == id.
        wikilinks = WIKILINK_RE.findall(mask_markdown(body))
        for target in wikilinks:
            target_lower = target.strip().lower()
            resolved_ids = resolution_map.get(target_lower, set())
            for rid in resolved_ids:
                if rid != linker_id:
                    inbound_links.setdefault(rid, set()).add(linker_id)

    # Also scan index.md and log.md for wikilinks (they link to pages)
    for special in ['index.md', 'log.md']:
        spath = os.path.join(wiki_dir, special)
        if os.path.exists(spath):
            try:
                scontent = open(spath, encoding='utf-8').read()
                # Mask special files too so code-fence examples don't create fake links.
                wikilinks = WIKILINK_RE.findall(mask_markdown(scontent))
                for target in wikilinks:
                    target_lower = target.strip().lower()
                    resolved_ids = resolution_map.get(target_lower, set())
                    for rid in resolved_ids:
                        inbound_links.setdefault(rid, set()).add('__special__')
            except Exception:
                pass

    # Exclude lint-report from orphan candidates
    orphan_exclude = {'index', 'log', 'lint-report'}
    for pid, linkers in inbound_links.items():
        if pid in orphan_exclude:
            continue
        if len(linkers) == 0:
            # Find the file path for this page
            rel = pid  # fallback
            for fpath, fm, body, err in all_pages:
                if fm and fm.get('id') == pid:
                    rel = os.path.relpath(fpath)
                    break
            add_finding('warning', 'orphan', rel, 'No inbound wikilinks from other wiki pages')

# ---------------------------------------------------------------------------
# Check 4: Missing cross-references
# ---------------------------------------------------------------------------

if should_run('crossref'):
    print("  Checking for missing cross-references...", file=sys.stderr)

    # Build per-page data for active pages
    active_pages = []
    for fpath, fm, body, err in all_pages:
        if fm is None:
            continue
        if fm.get('status') in ('archived', 'superseded'):
            continue
        pid = fm.get('id', '')
        domains = set(fm.get('domains') or [])
        tags = set(fm.get('tags') or [])
        wikilinks = set(t.strip().lower() for t in WIKILINK_RE.findall(body or ''))
        active_pages.append((fpath, pid, domains, tags, wikilinks, fm))

    # Check pairs
    checked_pairs = set()
    for i, (fp_a, pid_a, dom_a, tag_a, wl_a, fm_a) in enumerate(active_pages):
        for j, (fp_b, pid_b, dom_b, tag_b, wl_b, fm_b) in enumerate(active_pages):
            if i >= j:
                continue
            pair_key = tuple(sorted([pid_a, pid_b]))
            if pair_key in checked_pairs:
                continue
            checked_pairs.add(pair_key)

            # Check shared domains (2+) and shared tags (2+)
            shared_domains = dom_a & dom_b
            shared_tags = tag_a & tag_b
            if len(shared_domains) < 2 or len(shared_tags) < 2:
                continue

            # Check if they already link to each other (case-insensitive)
            # Build resolution variants for each page
            variants_a = {pid_a.lower()}
            if fm_a.get('title'):
                variants_a.add(fm_a['title'].lower())
            for alias in (fm_a.get('aliases') or []):
                if alias:
                    variants_a.add(str(alias).lower())

            variants_b = {pid_b.lower()}
            if fm_b.get('title'):
                variants_b.add(fm_b['title'].lower())
            for alias in (fm_b.get('aliases') or []):
                if alias:
                    variants_b.add(str(alias).lower())

            a_links_b = bool(wl_a & variants_b)
            b_links_a = bool(wl_b & variants_a)

            if not a_links_b and not b_links_a:
                rel_a = os.path.relpath(fp_a)
                rel_b = os.path.relpath(fp_b)
                add_finding('warning', 'crossref', rel_a,
                            f'Missing cross-reference: {pid_a} and {pid_b} share domains {sorted(shared_domains)} and tags {sorted(shared_tags)} but lack mutual wikilinks')

# ---------------------------------------------------------------------------
# Check 5: Staleness detection
# ---------------------------------------------------------------------------

if should_run('stale'):
    print("  Checking for stale claims...", file=sys.stderr)
    today = date.today()
    autofix_count = 0

    # --- Hash override check ---
    for src_id, sfm in source_registry.items():
        content_hash = sfm.get('content_hash', '')
        compiled_hash = sfm.get('compiled_against_hash', '')
        comp_status = sfm.get('compilation_status', '')
        if content_hash and compiled_hash and content_hash != compiled_hash and comp_status != 'stale':
            # Find all pages with prov markers referencing this source
            for fpath, fm, body, err in all_pages:
                if fm is None or body is None:
                    continue
                rel = os.path.relpath(fpath)
                prov_matches = PROV_RE.findall(body)
                for sid, loc, stype, cat in prov_matches:
                    if sid == src_id:
                        add_finding('warning', 'stale', rel,
                                    f'Source hash changed: {src_id} content_hash != compiled_against_hash, claim may be stale')
                        break  # one finding per page per source

    # --- Decay rate check ---
    for fpath, fm, body, err in all_pages:
        if fm is None or body is None:
            continue
        if fm.get('type') == 'source':
            continue  # source pages are not checked for claim staleness
        rel = os.path.relpath(fpath)
        knowledge_domain = fm.get('knowledge_domain', '')
        base_decay = DECAY_RATES.get(knowledge_domain, DEFAULT_DECAY)
        page_updated_at = fm.get('updated_at')

        # Parse body line by line for provenance markers
        lines = body.split('\n')
        file_modified = False
        new_lines = []

        for line_num, line in enumerate(lines, 1):
            prov_matches = list(PROV_RE.finditer(line))
            if not prov_matches:
                new_lines.append(line)
                continue

            # Find checked_at date for this claim
            checked_at_date = None
            claim_source_id = None
            for m in prov_matches:
                claim_source_id = m.group(1)
                checked_at_str = m.group(4)  # 4th capture group
                if checked_at_str:
                    try:
                        checked_at_date = date.fromisoformat(checked_at_str.strip())
                    except ValueError:
                        pass

            # Date fallback chain
            if checked_at_date is None and claim_source_id and claim_source_id in source_registry:
                ingested_str = source_registry[claim_source_id].get('ingested_at')
                if ingested_str:
                    try:
                        if isinstance(ingested_str, date):
                            checked_at_date = ingested_str
                        else:
                            checked_at_date = date.fromisoformat(str(ingested_str))
                    except ValueError:
                        pass

            if checked_at_date is None and page_updated_at:
                try:
                    if isinstance(page_updated_at, date):
                        checked_at_date = page_updated_at
                    else:
                        checked_at_date = date.fromisoformat(str(page_updated_at))
                except ValueError:
                    pass

            if checked_at_date is None:
                new_lines.append(line)
                continue

            # Get epistemic modifier from inline marker on this line
            epistemic_match = EPISTEMIC_INLINE_RE.search(line)
            epistemic_status = epistemic_match.group(1) if epistemic_match else 'sourced'
            modifier = EPISTEMIC_MODIFIERS.get(epistemic_status, 1.0)
            effective_decay = timedelta(days=int(base_decay.days * modifier))

            age = today - checked_at_date
            if age > effective_decay:
                add_finding('warning', 'stale', rel,
                            f'Claim at line {line_num} checked_at {checked_at_date} exceeds {effective_decay.days}d decay for domain {knowledge_domain or "default"}')

                # Auto-fix if --fix
                if do_fix and not dry_run:
                    if '[epistemic:: stale]' in line:
                        # Already stale, skip
                        new_lines.append(line)
                        continue

                    # Replace existing epistemic marker or add new one
                    if EPISTEMIC_INLINE_RE.search(line):
                        new_line = EPISTEMIC_INLINE_RE.sub('[epistemic:: stale]', line)
                    else:
                        # Place after last [prov:...] marker
                        last_prov = list(PROV_RE.finditer(line))[-1]
                        insert_pos = last_prov.end()
                        new_line = line[:insert_pos] + ' [epistemic:: stale]' + line[insert_pos:]

                    if new_line != line:
                        new_lines.append(new_line)
                        file_modified = True
                        autofix_count += 1
                        add_finding('info', 'autofix', rel,
                                    f'Added [epistemic:: stale] to claim at line {line_num}')
                        continue

            new_lines.append(line)

        # Write back if modified
        if file_modified and do_fix and not dry_run:
            with open(fpath, 'w', encoding='utf-8') as f:
                f.write('\n'.join(new_lines))

# ---------------------------------------------------------------------------
# Check 6: Contradiction candidate detection (AGENTS.md section 11.3 step 7)
# ---------------------------------------------------------------------------

CONTRADICTION_MARKER_RE = re.compile(r'\[contradiction:([^\]]+)\]')
SECTION_HEADING_RE = re.compile(r'^(#{2,3})\s+(.+)$', re.MULTILINE)

if should_run('contradiction'):
    print("  Checking for contradiction candidates...", file=sys.stderr)

    for fpath, fm, body, err in all_pages:
        if fm is None or body is None:
            continue

        page_type = fm.get('type', '')
        rel = os.path.relpath(fpath)

        # Skip comparison and overview pages -- inherently multi-source by design
        if page_type in ('comparison', 'overview'):
            continue

        # Parse body into sections (## or ### headings)
        # Each section: (heading_text, section_body)
        sections = []
        headings = list(SECTION_HEADING_RE.finditer(body))

        if not headings:
            # Entire body is one section
            sections.append(('(top-level)', body))
        else:
            # Content before first heading
            if headings[0].start() > 0:
                sections.append(('(top-level)', body[:headings[0].start()]))
            for idx, match in enumerate(headings):
                heading_text = match.group(2).strip()
                start = match.end()
                end = headings[idx + 1].start() if idx + 1 < len(headings) else len(body)
                sections.append((heading_text, body[start:end]))

        # Collect existing contradiction markers to avoid re-flagging acknowledged pairs
        existing_pairs = set()
        for cm in CONTRADICTION_MARKER_RE.finditer(body):
            # Parse "source_a#loc vs source_b#loc"
            parts = cm.group(1).split(' vs ')
            if len(parts) == 2:
                src_a = parts[0].split('#')[0].strip()
                src_b = parts[1].split('#')[0].strip()
                normalized = tuple(sorted([src_a, src_b]))
                existing_pairs.add(normalized)

        # For each section, extract provenance source_ids
        for heading_text, section_body in sections:
            prov_matches = PROV_RE.findall(section_body)
            source_ids = set()
            for source_id, locator, support_type, checked_at in prov_matches:
                source_ids.add(source_id)

            if len(source_ids) < 2:
                continue

            # Generate pairs of source_ids, check if already acknowledged
            sorted_ids = sorted(source_ids)
            for i_idx in range(len(sorted_ids)):
                for j_idx in range(i_idx + 1, len(sorted_ids)):
                    pair = (sorted_ids[i_idx], sorted_ids[j_idx])
                    if pair in existing_pairs:
                        continue
                    add_finding('warning', 'contradiction', rel,
                                f'Potential contradiction candidate in section "{heading_text}": '
                                f'claims from {pair[0]} and {pair[1]} (agent review needed)')

# ---------------------------------------------------------------------------
# Check 7: has_contradictions frontmatter sync (AGENTS.md section 11.3 step 8)
# ---------------------------------------------------------------------------

if should_run('contradiction') or should_run('yaml'):
    print("  Checking has_contradictions sync...", file=sys.stderr)

    for fpath, fm, body, err in all_pages:
        if fm is None or body is None:
            continue
        rel = os.path.relpath(fpath)

        # Count [contradiction:...] markers in body
        markers = CONTRADICTION_MARKER_RE.findall(body)
        marker_count = len(markers)
        has_field = fm.get('has_contradictions', False)

        if marker_count > 0 and not has_field:
            add_finding('warning', 'contradiction-sync', rel,
                        f'has_contradictions should be true (found {marker_count} [contradiction:] markers)')
            if do_fix and not dry_run:
                try:
                    content = open(fpath, encoding='utf-8').read()
                    # Replace has_contradictions: false with true
                    content = re.sub(
                        r'^(has_contradictions:\s*)false\s*$',
                        r'\g<1>true',
                        content, flags=re.MULTILINE
                    )
                    # Handle missing field -- add before closing ---
                    if 'has_contradictions' not in content.split('---')[1]:
                        pass  # field already exists if page passed yaml check
                    with open(fpath, 'w', encoding='utf-8') as f:
                        f.write(content)
                    add_finding('info', 'autofix', rel,
                                'Set has_contradictions to true')
                except Exception:
                    pass

        elif marker_count == 0 and has_field:
            add_finding('warning', 'contradiction-sync', rel,
                        'has_contradictions should be false (no [contradiction:] markers found)')
            if do_fix and not dry_run:
                try:
                    content = open(fpath, encoding='utf-8').read()
                    content = re.sub(
                        r'^(has_contradictions:\s*)true\s*$',
                        r'\g<1>false',
                        content, flags=re.MULTILINE
                    )
                    with open(fpath, 'w', encoding='utf-8') as f:
                        f.write(content)
                    add_finding('info', 'autofix', rel,
                                'Set has_contradictions to false')
                except Exception:
                    pass

# ---------------------------------------------------------------------------
# Check 8: Knowledge gap detection -- red links (AGENTS.md section 11.3 step 9)
# ---------------------------------------------------------------------------

TLDR_KEY_FACTS_RE = re.compile(r'^##\s+(TL;DR|Key Facts)\s*$', re.MULTILINE)
NEXT_H2_RE = re.compile(r'^##\s+', re.MULTILINE)

if should_run('gap'):
    print("  Checking for knowledge gaps (red links)...", file=sys.stderr)

    # Reuse the obsidian_map from orphan detection if available, otherwise rebuild.
    # NOTE: the gap block uses `resolution_map` (alias for obsidian_map) for backward compat.
    # The guard is now on `obsidian_map` to match the new variable name (Change 5).
    # Review HIGH #5: self-build also uses id-only (no aliases), consistent with orphan block.
    if 'obsidian_map' not in dir():
        obsidian_map = {}
        for fpath, fm, body, err in all_pages:
            if fm is None:
                continue
            pid = fm.get('id', '')
            if not pid:
                continue
            stem = os.path.splitext(os.path.basename(fpath))[0].lower()
            obsidian_map.setdefault(stem, set()).add(pid)
            # Aliases intentionally NOT indexed (review HIGH #5: id-only resolution)
        resolution_map = obsidian_map  # backward-compat alias

    # Collect all unresolved wikilinks with page context
    # unresolved_links: target_lower -> { 'pages': set of page_ids, 'in_tldr_keyfacts': bool }
    unresolved_links = {}

    for fpath, fm, body, err in all_pages:
        if fm is None or body is None:
            continue
        linker_id = fm.get('id', '')
        # Mask documentation examples (frontmatter, fenced/inline code, HTML
        # comments) before the gap red-link scan so literal [[example]] tokens in
        # prose/code (e.g. a decision record showing [[id|Title]] or [[X]]) are not
        # flagged as phantom knowledge gaps. Consistent with the linkres/orphan/
        # provenance masking; mask_markdown is length-preserving so offsets used in
        # the TL;DR/Key-Facts range check below stay aligned (review WR-01).
        masked_body = mask_markdown(body)
        wikilinks = WIKILINK_RE.findall(masked_body)

        # Identify TL;DR and Key Facts section boundaries
        tldr_kf_ranges = []
        for m in TLDR_KEY_FACTS_RE.finditer(body):
            section_start = m.end()
            # Find next ## heading
            next_h2 = NEXT_H2_RE.search(body, section_start)
            section_end = next_h2.start() if next_h2 else len(body)
            tldr_kf_ranges.append((m.start(), section_end))

        for target in wikilinks:
            target_lower = target.strip().lower()
            # Check if it resolves
            if target_lower in resolution_map:
                continue
            # Also check special files (index, log)
            if target_lower in ('index', 'log', 'lint-report'):
                continue

            if target_lower not in unresolved_links:
                unresolved_links[target_lower] = {'pages': set(), 'in_tldr_keyfacts': False, 'raw': target.strip()}

            unresolved_links[target_lower]['pages'].add(linker_id)

            # Check if this link appears in a TL;DR or Key Facts section
            # Find the position of this wikilink in the body
            link_pattern = re.compile(r'\[\[' + re.escape(target) + r'(?:\|[^\]]+)?\]\]')
            for lm in link_pattern.finditer(masked_body):
                for (rs, re_end) in tldr_kf_ranges:
                    if rs <= lm.start() < re_end:
                        unresolved_links[target_lower]['in_tldr_keyfacts'] = True
                        break

    # Flag red links per D-20 rules
    for target_lower, info in sorted(unresolved_links.items()):
        page_count = len(info['pages'])
        in_special = info['in_tldr_keyfacts']
        raw_target = info['raw']

        should_flag = (page_count >= 2) or in_special

        if should_flag:
            page_list = ', '.join(sorted(info['pages']))
            question = f'What is {raw_target} and how does it relate to the pages that reference it?'
            add_finding('info', 'gap', f'red-link:{raw_target}',
                        f'Unresolved wikilink on {page_count} pages: {page_list}. '
                        f'Suggested question: {question}')

# ---------------------------------------------------------------------------
# Check 9: Sparse source coverage (AGENTS.md section 11.3 step 10)
# ---------------------------------------------------------------------------

if should_run('gap'):
    print("  Checking for sparse source coverage...", file=sys.stderr)

    # Collect knowledge_domain values from all pages and count sources per domain
    domain_source_count = {}  # knowledge_domain -> count of source pages with that domain
    all_domains = set()

    for fpath, fm, body, err in all_pages:
        if fm is None:
            continue
        kd = fm.get('knowledge_domain', '')
        if kd:
            all_domains.add(kd)

    # Count source pages per knowledge_domain
    for fpath, fm, body, err in all_pages:
        if fm is None:
            continue
        if fm.get('type') != 'source':
            continue
        kd = fm.get('knowledge_domain', '')
        if kd:
            domain_source_count[kd] = domain_source_count.get(kd, 0) + 1

    # Ensure all domains have an entry (even if 0 sources)
    for d in all_domains:
        if d not in domain_source_count:
            domain_source_count[d] = 0

    # Maturity guardrail (per D-22): 5+ domains, 3+ with 2+ sources
    total_domains = len(all_domains)
    domains_with_2plus = sum(1 for c in domain_source_count.values() if c >= 2)

    if total_domains < 5 or domains_with_2plus < 3:
        add_finding('info', 'gap', 'maturity',
                    f'Sparse coverage check skipped: wiki needs 5+ domains with 3+ having 2+ sources '
                    f'(currently {total_domains} domains, {domains_with_2plus} meet threshold)')
    else:
        # Compute median source count
        counts = sorted(domain_source_count.values())
        mid = len(counts) // 2
        if len(counts) % 2 == 0:
            median = (counts[mid - 1] + counts[mid]) / 2
        else:
            median = counts[mid]

        threshold = median / 2

        for domain in sorted(domain_source_count.keys()):
            count = domain_source_count[domain]
            if count < threshold or count == 0:
                if count == 0:
                    question = f'What are your key interests or references in {domain}?'
                else:
                    question = f'What additional perspectives on {domain} would strengthen coverage?'
                add_finding('info', 'gap', f'sparse:{domain}',
                            f'Domain "{domain}" has {count} sources vs median {median}. '
                            f'Consider: {question}')

# ---------------------------------------------------------------------------
# Check 9.5: Lexical near-duplicate page detection (a1, category: duplicate)
# ---------------------------------------------------------------------------
# Flags same-type page pairs whose titles/aliases are lexically near-identical
# -- the weakest current relationship heuristic (nothing else detects
# "Geoff Hinton" vs "Geoffrey Hinton" or "Attention Mechanism" vs
# "Attention Mechanisms"). Report-only (severity warning): feeds the
# human-confirmed MERGE operation (§9). NEVER auto-merges, never mutates.
#
# Candidate iff (same type) AND EITHER:
#   - one page's title/alias contains the other's title/alias as a
#     case-insensitive substring (contained string length > 5), OR
#   - levenshtein(title_a, title_b) < 3 for titles longer than 5 chars.
# Survivor = the page with MORE inbound wikilinks (tie -> lexicographically
# first id is survivor, deterministic). One finding per pair.

def _levenshtein(a, b):
    """Pure-stdlib edit distance (no new imports). Two-row DP, O(len(a)*len(b))."""
    if a == b:
        return 0
    if not a:
        return len(b)
    if not b:
        return len(a)
    prev = list(range(len(b) + 1))
    for i, ca in enumerate(a, 1):
        cur = [i]
        for j, cb in enumerate(b, 1):
            cost = 0 if ca == cb else 1
            cur.append(min(
                prev[j] + 1,        # deletion
                cur[j - 1] + 1,     # insertion
                prev[j - 1] + cost, # substitution
            ))
        prev = cur
    return prev[-1]

if should_run('duplicate'):
    print("  Checking for near-duplicate pages...", file=sys.stderr)

    # Build candidate page inventory (self-contained -- the orphan-block
    # resolution_map / inbound_links are scoped to should_run('orphan')).
    # Exclude: EXCLUDE_DIRS/examples (already filtered out of all_pages),
    # example: true (already filtered), and archived/superseded pages.
    dup_pages = []  # list of dicts: id, title, type, names (lowercased name set)
    for fpath, fm, body, err in all_pages:
        if fm is None:
            continue
        if fm.get('status') in ('archived', 'superseded'):
            continue
        pid = fm.get('id', '')
        ptype = fm.get('type', '')
        title = fm.get('title', '')
        if not pid or not ptype or not title:
            continue
        # Names = title + aliases, lowercased, deduped.
        names = {str(title).lower()}
        for alias in (fm.get('aliases') or []):
            if alias:
                names.add(str(alias).lower())
        dup_pages.append({
            'id': pid,
            'title': str(title),
            'type': ptype,
            'names': names,
            'path': os.path.relpath(fpath),
        })

    # Build inbound-wikilink graph over the candidate pages (mirrors the
    # orphan check's resolution + counting, scoped to dup_pages so it works
    # even when should_run('orphan') is False).
    dup_resolution = {}  # lowercase name -> set of page ids
    dup_id_set = {p['id'] for p in dup_pages}
    for p in dup_pages:
        for nm in ({p['id'].lower()} | p['names']):
            dup_resolution.setdefault(nm, set()).add(p['id'])

    dup_inbound = {p['id']: set() for p in dup_pages}
    # Count inbound links from ALL wiki pages (not just candidates), plus
    # index.md/log.md, matching the orphan check's link-graph breadth.
    for fpath, fm, body, err in all_pages:
        if fm is None or body is None:
            continue
        linker_id = fm.get('id', '')
        for target in WIKILINK_RE.findall(body):
            for rid in dup_resolution.get(target.strip().lower(), set()):
                if rid != linker_id:
                    dup_inbound[rid].add(linker_id)
    for special in ('index.md', 'log.md'):
        spath = os.path.join(wiki_dir, special)
        if os.path.exists(spath):
            try:
                scontent = open(spath, encoding='utf-8').read()
            except OSError:
                scontent = ''
            for target in WIKILINK_RE.findall(scontent):
                for rid in dup_resolution.get(target.strip().lower(), set()):
                    dup_inbound[rid].add('__special__')

    def _is_near_duplicate(names_a, names_b):
        """True iff any cross name-pair satisfies the substring-containment or
           Levenshtein<3 candidate predicate (both length-gated at >5)."""
        for na in names_a:
            for nb in names_b:
                if na == nb:
                    continue
                # Substring containment: shorter inside longer, contained len > 5.
                if na in nb and len(na) > 5:
                    return True
                if nb in na and len(nb) > 5:
                    return True
                # Levenshtein < 3, both strings longer than 5 chars.
                if len(na) > 5 and len(nb) > 5 and _levenshtein(na, nb) < 3:
                    return True
        return False

    # Group candidate pages by type, compare same-type unordered pairs once.
    by_type = {}
    for p in dup_pages:
        by_type.setdefault(p['type'], []).append(p)

    seen_pairs = set()
    for t, group in by_type.items():
        for i in range(len(group)):
            for j in range(i + 1, len(group)):
                pa, pb = group[i], group[j]
                pair_key = tuple(sorted([pa['id'], pb['id']]))
                if pair_key in seen_pairs:
                    continue
                if not _is_near_duplicate(pa['names'], pb['names']):
                    continue
                seen_pairs.add(pair_key)
                # Survivor = more inbound links; tie -> lexicographically-first id.
                n_a = len(dup_inbound.get(pa['id'], set()))
                n_b = len(dup_inbound.get(pb['id'], set()))
                if n_a > n_b:
                    survivor, loser, n_survivor, n_loser = pa, pb, n_a, n_b
                elif n_b > n_a:
                    survivor, loser, n_survivor, n_loser = pb, pa, n_b, n_a
                else:
                    # tie: lexicographically-first id survives
                    if pa['id'] <= pb['id']:
                        survivor, loser, n_survivor, n_loser = pa, pb, n_a, n_b
                    else:
                        survivor, loser, n_survivor, n_loser = pb, pa, n_b, n_a
                add_finding('warning', 'duplicate', loser['path'],
                            f'possible duplicate of "{survivor["title"]}" '
                            f'({survivor["id"]}); same type={t}; consider MERGE (§9). '
                            f'Survivor by inbound-link count ({n_loser} vs {n_survivor}).')

# ---------------------------------------------------------------------------
# Check 9.75: Link-FORM + target resolution (linkres) -- LINK-04, LINK-05, LINK-06
# Rule (D-02 unconditional piped form): every intra-wiki body link MUST be
# [[id|Title]] with `id` a known page id. Scans/rewrites run over MASKED body.
# ---------------------------------------------------------------------------
if should_run('linkres'):
    print("  Checking intra-wiki link form + targets (linkres)...", file=sys.stderr)

    # known_ids: lowercase page ids AND filename stems (id == filename by convention).
    # This is the GATE lookup (D-04: exact id match, no normalization on the gating path).
    known_ids = set()
    for fpath, fm, body, err in all_pages:
        if fm is None:
            continue
        pid = fm.get('id', '')
        if pid:
            known_ids.add(pid.lower())
        stem = os.path.splitext(os.path.basename(fpath))[0].lower()
        known_ids.add(stem)

    # norm_map: normalize(id|title|alias|stem) -> set of page ids. ONLY the --fix matcher
    # and the "is this a malformed target or a genuine gap?" disambiguation use it.
    # NOT the gate (gate is exact known_ids membership).
    norm_map = {}
    for fpath, fm, body, err in all_pages:
        if fm is None:
            continue
        pid = fm.get('id', '')
        if not pid:
            continue
        stem = os.path.splitext(os.path.basename(fpath))[0]
        names = [stem, pid] + [str(a) for a in (fm.get('aliases') or []) if a]
        if fm.get('title'):
            names.append(str(fm['title']))
        for name in names:
            key = normalize_link(name)
            if key:
                norm_map.setdefault(key, set()).add(pid)

    # Scan worklist: all wiki pages + index.md + log.md, each as (rel, abs_path, FULL_FILE_TEXT).
    # CRITICAL (review HIGH #2 / cycle-1 #2 -- frontmatter preservation): the worklist MUST carry
    # the FULL on-disk file content (read fresh from abs_path), NOT the parsed post-frontmatter
    # `body`. The positional --fix in Step C writes `new_content` back to `abs_path`; if `raw` were
    # the body-only string, the rewrite would overwrite the whole file with body-only content,
    # DROPPING the YAML frontmatter and any pre-body content. mask_markdown()'s _FM_RE already
    # blanks the leading `---...---` frontmatter block (offset-preserving), so reading the FULL file
    # is the intended, safe design: frontmatter is masked from the scan yet preserved on write.
    linkres_scan = []
    for fpath, fm, body, err in all_pages:
        if fm is not None and body is not None:
            try:
                full = open(fpath, encoding='utf-8').read()  # FULL file, NOT `body`
            except Exception:
                continue
            linkres_scan.append((os.path.relpath(fpath), fpath, full))
    for special in ('index.md', 'log.md'):
        sp = os.path.join(wiki_dir, special)
        if os.path.isfile(sp):
            try:
                linkres_scan.append((os.path.relpath(sp), sp, open(sp, encoding='utf-8').read()))
            except Exception:
                pass

    def _classify_piped(target):
        """Return ('ok'|'error'|'gap', correct_id_or_None) for a piped target."""
        t = target.strip()
        if t.lower() in known_ids:
            return ('ok', None)
        # Path-style target (concepts/foo) is NOT id-only -> error (review MEDIUM).
        if '/' in t:
            return ('error', None)
        normed = normalize_link(t)
        matches = norm_map.get(normed, set()) if normed else set()
        if len(matches) == 0:
            # No known page even by normalization -> deliberate not-yet-existing slug = gap (§3).
            return ('gap', None)
        if len(matches) == 1:
            return ('error', list(matches)[0])  # malformed target that maps to a real page
        return ('error', None)  # ambiguous malformed target

    for rel, abs_path, raw in linkres_scan:
        masked = mask_markdown(raw)

        # --- Piped links over the MASKED body ---
        for m in PIPED_LINK_RE.finditer(masked):
            target, display = m.group(1), m.group(2)
            verdict, correct_id = _classify_piped(target)
            if verdict == 'ok' or verdict == 'gap':
                continue
            if '/' in target:
                add_finding('error', 'linkres', rel,
                            f"piped link [[{target.strip()}|{display}]] uses a path-style "
                            f"target; use the bare page id [[id|{display}]] (id-only convention)")
            elif correct_id:
                add_finding('error', 'linkres', rel,
                            f"piped link [[{target.strip()}|{display}]] target "
                            f"'{target.strip()}' is not a known page id "
                            f"(did you mean [[{correct_id}|{display}]]?)")
            else:
                add_finding('error', 'linkres', rel,
                            f"piped link [[{target.strip()}|{display}]] target "
                            f"'{target.strip()}' is not a known page id (ambiguous)")

        # --- Bare links over the MASKED body. EVERY bare link is a finding (D-02). ---
        # Collect piped spans to subtract, so the bare regex does not re-match a piped target.
        piped_spans = [(m.start(), m.end()) for m in PIPED_LINK_RE.finditer(masked)]
        def _in_piped(pos):
            return any(s <= pos < e for s, e in piped_spans)

        # Accumulate positional rewrites for this file (review suggestion: positional, not global sub).
        rewrites = []  # (start, end, replacement)
        for m in BARE_LINK_RE.finditer(masked):
            if _in_piped(m.start()):
                continue  # this is the target side of a piped link, not a bare link
            bare = m.group(1).strip()
            normed = normalize_link(bare)
            matches = norm_map.get(normed, set()) if normed else set()
            if len(matches) == 1:
                correct_id = list(matches)[0]
                add_finding('error', 'linkres', rel,
                            f"bare link [[{bare}]] (no pipe); use [[{correct_id}|{bare}]] "
                            f"(LINK-04: uniform piped form)")
                if do_fix and not dry_run:
                    rewrites.append((m.start(), m.end(), f'[[{correct_id}|{bare}]]'))
            elif len(matches) == 0:
                # Bare AND unresolvable: still a FORM error (review HIGH #1) but not auto-fixable
                # (no unique target). It is BOTH a knowledge-gap red link AND a bare-form violation.
                add_finding('error', 'linkres', rel,
                            f"bare link [[{bare}]] (no pipe) has no unique page match; "
                            f"pipe it as [[<id>|{bare}]] once the target page exists "
                            f"(LINK-04: bare form not allowed even for red links)")
            else:
                add_finding('warning', 'linkres', rel,
                            f"bare link [[{bare}]] matches multiple pages "
                            f"{sorted(matches)}; pipe it manually with the intended id "
                            f"(ambiguous -- cannot auto-fix)")

        # --- Apply positional --fix against the REAL content (offsets aligned via masking) ---
        # `raw` is the FULL file text (frontmatter + body). Rewrite spans were found in the
        # MASKED copy, whose offsets are index-aligned to `raw` (mask_markdown is length-
        # preserving), and bare-link spans NEVER fall inside the masked frontmatter region.
        # So splicing `raw[last:start] + repl + raw[end:]` and writing it back to abs_path
        # preserves YAML frontmatter byte-for-byte -- only the intended body bare-link spans
        # change (review HIGH #2 / cycle-1 #2 frontmatter-corruption fix).
        if do_fix and not dry_run and rewrites:
            try:
                out, last = [], 0
                for start, end, repl in sorted(rewrites):
                    out.append(raw[last:start]); out.append(repl); last = end
                out.append(raw[last:])
                new_content = ''.join(out)
                if new_content != raw:
                    with open(abs_path, 'w', encoding='utf-8') as f:
                        f.write(new_content)
                    add_finding('info', 'autofix', rel,
                                f'Rewrote {len(rewrites)} bare link(s) to piped form')
            except Exception as e:
                print(f"  warn: --fix failed on {rel}: {e}", file=sys.stderr)

    # Also rebuild obsidian_map without aliases for the gap block's resolution_map,
    # if it hasn't been built yet (--category linkres without --category orphan).
    if 'obsidian_map' not in dir():
        obsidian_map = {}  # lowercase filename stem -> set of page ids (id-only, no aliases)
        for fpath, fm, body, err in all_pages:
            if fm is None:
                continue
            pid = fm.get('id', '')
            if not pid:
                continue
            stem = os.path.splitext(os.path.basename(fpath))[0].lower()
            obsidian_map.setdefault(stem, set()).add(pid)
        resolution_map = obsidian_map  # backward-compat alias for gap block

# ---------------------------------------------------------------------------
# Check 10: Drift detection (DRFT-01, DRFT-02, DRFT-03, DRFT-04)
# ---------------------------------------------------------------------------

if should_run('drift') or should_run('all'):
    import hashlib

    project_root = os.path.dirname(os.path.abspath(wiki_dir.rstrip('/')))
    sources_dir = os.path.join(project_root, 'sources')

    # --- DRFT-01: Unrepresented sources ---
    # Walk sources/ for .md files, check each has a wiki source summary page
    print("  Check 10a: Unrepresented sources (DRFT-01)...", file=sys.stderr)
    wiki_source_paths = set()
    for sp, sfm, sbody in source_pages:
        if sfm and 'path' in sfm:
            wiki_source_paths.add(sfm['path'])

    if os.path.isdir(sources_dir):
        for root, dirs, files in os.walk(sources_dir):
            for fname in files:
                if fname.endswith('.md'):
                    raw_path = os.path.join(root, fname)
                    rel_path = os.path.relpath(raw_path, project_root)
                    if rel_path not in wiki_source_paths:
                        add_finding('warning', 'drift', rel_path,
                                    'Raw source has no wiki source summary page')

    # --- DRFT-02: Missing source files ---
    # For each source summary page, verify the file at path exists
    print("  Check 10b: Missing source files (DRFT-02)...", file=sys.stderr)
    for sp, sfm, sbody in source_pages:
        if sfm is None:
            continue
        rel = os.path.relpath(sp)
        source_path_field = sfm.get('path', '')
        if not source_path_field:
            continue
        abs_source = os.path.join(project_root, source_path_field)
        if not os.path.exists(abs_source):
            add_finding('error', 'drift', rel,
                        f'Source file missing: {source_path_field}')

    # --- Content-hash drift (D-13, D-14) ---
    # Recompute SHA-256 of raw source, compare against stored content_hash
    # Auto-fix (compilation_status -> stale) ONLY when --fix is passed (do_fix and not dry_run)
    # This follows the same gating pattern as stale marker auto-fixes (line 533).
    print("  Check 10c: Content-hash drift...", file=sys.stderr)
    for sp, sfm, sbody in source_pages:
        if sfm is None:
            continue
        rel = os.path.relpath(sp)
        stored_hash = sfm.get('content_hash', '')
        source_path_field = sfm.get('path', '')
        if not stored_hash or not source_path_field:
            continue
        abs_source = os.path.join(project_root, source_path_field)
        if not os.path.exists(abs_source):
            continue  # Already reported as DRFT-02 above
        h = hashlib.sha256()
        with open(abs_source, 'rb') as f:
            for chunk in iter(lambda: f.read(8192), b''):
                h.update(chunk)
        current_hash = f'sha256:{h.hexdigest()}'
        if current_hash != stored_hash:
            add_finding('warning', 'drift', rel,
                        f'Content hash mismatch: source changed since ingest '
                        f'(stored: {stored_hash[:30]}..., current: {current_hash[:30]}...)')
            # Auto-fix: mark compilation_status as stale (D-14)
            # GATED: only when --fix is passed, same pattern as stale marker auto-fixes
            if do_fix and not dry_run:
                comp_status = sfm.get('compilation_status', '')
                if comp_status and comp_status != 'stale':
                    try:
                        content = open(sp, encoding='utf-8').read()
                        content = re.sub(
                            r'^(compilation_status:\s*).*$',
                            r'\1stale',
                            content, flags=re.MULTILINE
                        )
                        with open(sp, 'w', encoding='utf-8') as f:
                            f.write(content)
                        add_finding('info', 'autofix', rel,
                                    'Set compilation_status to stale (content hash drift)')
                    except Exception:
                        pass

    # --- Index coverage (D-11) ---
    # Check that every wiki page has a wikilink in wiki-cloud/index.md
    print("  Check 10d: Index coverage gaps...", file=sys.stderr)
    index_path = os.path.join(wiki_dir, 'index.md')
    if os.path.exists(index_path):
        index_content = open(index_path, encoding='utf-8').read().lower()
        # Collect all wiki pages (excluding index, log, maintenance files)
        skip_ids = {'index', 'log', 'lint-report', 'reflect-state'}
        for page_path, page_fm, page_body, page_err in all_pages:
            if page_fm is None:
                continue
            page_id = page_fm.get('id', '')
            if page_id in skip_ids:
                continue
            page_title = page_fm.get('title', '')
            # Check if page appears in index via id or title (case-insensitive)
            if (page_id.lower() not in index_content and
                page_title.lower() not in index_content):
                rel = os.path.relpath(page_path)
                add_finding('warning', 'drift', rel,
                            f'Page not listed in wiki-cloud/index.md: {page_id}')

    # --- DRFT-03: Obsidian vault awareness ---
    # EXTERNAL: prefix marks drift findings originating from external-state
    # checks (Obsidian vault, future Zotero/etc). The --skip-category drift-external
    # filter (applied by --ci default per D-02) consults this prefix.
    # See AGENTS.md §11.3 and Phase 9 Plan 02 D-06.
    print("  Check 10e: Obsidian vault awareness (DRFT-03)...", file=sys.stderr)
    obsidian_dir = os.path.join(project_root, '.obsidian')
    if not os.path.isdir(obsidian_dir):
        add_finding('info', 'drift', '.obsidian/',
                    'EXTERNAL: No .obsidian/ directory found -- Obsidian vault may not be configured')
    # Check for non-.md files in wiki-cloud/ subdirectories (unexpected binaries)
    for root, dirs, files in os.walk(wiki_dir):
        # Skip maintenance/ directory (may contain non-standard files)
        if 'maintenance' in root:
            continue
        for fname in files:
            if not fname.endswith('.md'):
                fpath = os.path.join(root, fname)
                rel = os.path.relpath(fpath)
                add_finding('info', 'drift', rel,
                            'EXTERNAL: Non-markdown file in wiki-cloud/ (may cause Obsidian issues)')

    # --- DRFT-04: Orphaned operation artifacts (log <-> git drift) ---
    # An operation (query/ingest) that finishes its file edits but skips its
    # commit leaves log.md asserting `pages_affected` the wiki does not contain
    # as committed files. The next operation's commit then flushes the shared
    # append-only log.md while the orphaned page/index edits dangle untracked.
    # This check reads the COMMITTED log.md (git show HEAD:) so that an in-flight
    # operation -- whose fresh log entry is itself still uncommitted alongside
    # its page -- is NOT flagged; only entries already in HEAD are audited.
    # Scope: the machine-parseable `pages_affected:` field (query-workflow
    # format, AGENTS.md §11.2). See AGENTS.md §11.3 step 12 (DRFT-04).
    print("  Check 10f: Orphaned operation artifacts (DRFT-04)...", file=sys.stderr)
    _drft04_skip_ids = {'index', 'log', 'lint-report', 'reflect-state', 'none', ''}
    try:
        wiki_rel = os.path.relpath(os.path.abspath(wiki_dir.rstrip('/')), REPO_ROOT)
        committed_log = subprocess.run(
            ['git', 'show', f'HEAD:{wiki_rel}/log.md'],
            cwd=REPO_ROOT, check=True, capture_output=True, text=True,
        ).stdout
        tracked = subprocess.run(
            ['git', 'ls-files', wiki_rel],
            cwd=REPO_ROOT, check=True, capture_output=True, text=True,
        ).stdout
    except (subprocess.CalledProcessError, FileNotFoundError):
        committed_log = ''
        tracked = ''
    if committed_log:
        # Resolve referenced IDs against the actual `id` frontmatter of
        # git-tracked pages (NOT filename stems): a page whose id != filename
        # is itself a yaml-check error, and must not also produce a spurious
        # orphan finding here.
        tracked_paths = {
            os.path.normpath(p) for p in tracked.splitlines() if p.endswith('.md')
        }
        tracked_ids = set()
        for page_path, page_fm, _b, _e in all_pages:
            if not page_fm:
                continue
            pid = page_fm.get('id', '')
            rel = os.path.relpath(os.path.abspath(page_path), REPO_ROOT)
            if pid and os.path.normpath(rel) in tracked_paths:
                tracked_ids.add(pid)
        log_rel = os.path.relpath(os.path.join(wiki_dir, 'log.md'))
        for m in re.finditer(r'^pages_affected:\s*(.+)$', committed_log, re.MULTILINE):
            for pid in (x.strip() for x in m.group(1).split(',')):
                if pid in _drft04_skip_ids:
                    continue
                if pid not in tracked_ids:
                    add_finding('warning', 'drift', log_rel,
                                f"log.md records pages_affected '{pid}' but no "
                                f"git-tracked wiki page exists for it (orphaned "
                                f"operation artifact -- prior operation skipped "
                                f"its commit; commit the page or fix the log entry)")

# ---------------------------------------------------------------------------
# Check: brownfield (BRWN-09) — 30-day staleness + summary counts
# ---------------------------------------------------------------------------
# Emits:
#   warning/brownfield/<path>: "bootstrapped N days ago; consider Phase-11
#                              suggest/verify" — for pages whose
#                              bootstrap_date is >30 days old.
#   info/brownfield/<empty>:   "bootstrapped pages: X; stale (>30d): Y" —
#                              summary roll-up (only emitted when X > 0).
# Fresh bootstraps (<=30 days) are NOT flagged; missing/malformed
# bootstrap_date is ignored (no finding) because the summary count still
# reflects bootstrap_stage presence.

if should_run('brownfield') or should_run('all'):
    from datetime import date as _date
    today_d = _date.today()
    bf_count = 0
    stale_count = 0
    for page_path, page_fm, _body, _err in all_pages:
        if page_fm is None:
            continue
        if page_fm.get('bootstrap_stage') != 'bootstrapped':
            continue
        bf_count += 1
        bd = page_fm.get('bootstrap_date')
        if not bd:
            continue
        try:
            bdate = _date.fromisoformat(str(bd))
        except (ValueError, TypeError):
            continue
        age_days = (today_d - bdate).days
        if age_days > 30:
            stale_count += 1
            rel = os.path.relpath(page_path)
            add_finding('warning', 'brownfield', rel,
                        f'bootstrapped {age_days} days ago; consider Phase-11 suggest/verify')
    if bf_count > 0:
        add_finding('info', 'brownfield', '',
                    f'bootstrapped pages: {bf_count}; stale (>30d): {stale_count}')

# ---------------------------------------------------------------------------
# Phase 9 Plan 03: --strict check (CI-06 quality ratchet), --count-skips
# aggregator (D-09), and contributor category (COLAB-08 / D-22) run BEFORE
# the filter pipeline so their findings ride through the standard skip +
# remap path.
# ---------------------------------------------------------------------------

strict_check(wiki_dir)
count_skips_aggregate(wiki_dir)
contributor_check(wiki_dir, REPO_ROOT)

# ---------------------------------------------------------------------------
# Apply Phase 9 filters (Plan 02): category narrowing is already enforced by
# `should_run()` at check-time. Here we apply the --skip-category subtraction
# (including `drift-external` logical subcategory) and the --ci severity remap.
# Precedence (D-01 + P0 review fix): category_filter narrows FIRST (via
# should_run), then skip_set SUBTRACTS. Equivalent set math:
#   final = (category_filter or ALL) - skip_set
# ---------------------------------------------------------------------------

if SKIP_CATEGORIES:
    findings = [f for f in findings if not matches_skip(f[1], f[3], SKIP_CATEGORIES)]

if CI_MODE:
    findings = [(CI_SEVERITY_REMAP.get(cat, sev), cat, path, msg)
                for (sev, cat, path, msg) in findings]
    # BRWN-08: downgrade allowlist findings on bootstrapped pages from error
    # to info. SCOPE (I-1): --ci mode only; text-mode lint is unaffected.
    # A finding is eligible iff its category is in BROWNFIELD_ALLOWLIST AND
    # its path is in BROWNFIELD_BOOTSTRAPPED_PAGES AND its severity is error.
    def _bf_downgrade(sev, cat, path):
        if (cat in BROWNFIELD_ALLOWLIST
                and path in BROWNFIELD_BOOTSTRAPPED_PAGES
                and sev == 'error'):
            return 'info'
        return sev
    findings = [(_bf_downgrade(sev, cat, path), cat, path, msg)
                for (sev, cat, path, msg) in findings]

# ---------------------------------------------------------------------------
# Sort findings and write to temp file
# ---------------------------------------------------------------------------

severity_order = {'error': 0, 'warning': 1, 'info': 2}
findings.sort(key=lambda f: (severity_order.get(f[0], 99), f[1], f[2]))

with open(findings_file, 'w', encoding='utf-8') as f:
    for sev, cat, path, msg in findings:
        f.write(f'{sev}|{cat}|{path}|{msg}\n')

# ---------------------------------------------------------------------------
# Count findings
# ---------------------------------------------------------------------------

error_count = sum(1 for f in findings if f[0] == 'error')
warning_count = sum(1 for f in findings if f[0] == 'warning')
info_count = sum(1 for f in findings if f[0] == 'info')
total = len(findings)
autofix_applied = sum(1 for f in findings if f[1] == 'autofix')

# ---------------------------------------------------------------------------
# JSON emitter (D-03 + D-04): print array to stdout, DO NOT write
# lint-report.md. The 4-tuple (sev, cat, path, msg) has no line slot, so
# `line` is OMITTED (NOT present as null) for all Plan 02 findings. Plan 03
# strict/skip-count findings will carry lines via their own mechanism.
# ---------------------------------------------------------------------------

if LINT_FORMAT == 'json':
    import json
    payload = []
    for (sev, cat, path, msg) in findings:
        # Note: `line` intentionally OMITTED when unknown (P0 review fix).
        payload.append({
            'severity': sev,
            'category': cat,
            'path': path,
            'message': msg,
        })
    sys.stdout.write(json.dumps(payload, indent=2) + '\n')
    # CI / strict exit policy (D-05 + CI-06): exit 1 iff any post-remap
    # error-severity finding. --strict participates in the same exit rule
    # (strict_check emits error-severity strict/provenance findings).
    if CI_MODE or STRICT_MODE:
        has_error = any(sev == 'error' for (sev, _, _, _) in findings)
        sys.exit(1 if has_error else 0)
    sys.exit(0)

# ---------------------------------------------------------------------------
# Text-mode emit (v1.0 behavior preserved): generate lint-report.md unless
# --dry-run. The --ci flag still remaps severities for text output; exit code
# still obeys D-05 CI policy.
# ---------------------------------------------------------------------------

if not dry_run:
    maint_dir = os.path.join(wiki_dir, 'maintenance')
    os.makedirs(maint_dir, exist_ok=True)
    report_path = os.path.join(maint_dir, 'lint-report.md')

    # Preserve created_at from existing report
    created_at = str(date.today())
    if os.path.exists(report_path):
        try:
            existing_content = open(report_path, encoding='utf-8').read()
            if existing_content.startswith('---'):
                end = existing_content.index('---', 3)
                existing_fm = yaml.safe_load(existing_content[3:end])
                if existing_fm and 'created_at' in existing_fm:
                    created_at = str(existing_fm['created_at'])
        except Exception:
            pass

    today_str = str(date.today())

    # Build finding sections
    def format_findings(sev):
        items = [f for f in findings if f[0] == sev]
        if not items:
            return '(none)\n'
        # Group by category, preserving insertion order
        from collections import OrderedDict
        cats = OrderedDict()
        for s, cat, path, msg in items:
            cats.setdefault(cat, []).append((path, msg))
        lines = []
        for cat, entries in cats.items():
            lines.append(f'### {cat.title()}')
            for path, msg in entries:
                lines.append(f'- **{path}** | {msg}')
            lines.append('')
        return '\n'.join(lines) + '\n'

    report_content = f"""---
id: lint-report
title: Lint Report
type: overview
status: active
summary: "Wiki health-check findings from most recent lint run."
created_at: {created_at}
updated_at: {today_str}
sources: []
epistemic_status: sourced
tags:
  - meta
  - maintenance
domains: []
supersedes:
superseded_by:
aliases:
  - Lint Report
has_contradictions: false
knowledge_domain: ""
---

# Lint Report

**Last run:** {today_str}
**Total findings:** {total}
**Auto-fixes applied:** {autofix_applied}

## Errors ({error_count})

{format_findings('error')}
## Warnings ({warning_count})

{format_findings('warning')}
## Info ({info_count})

{format_findings('info')}"""

    with open(report_path, 'w', encoding='utf-8') as f:
        f.write(report_content)

    # Append log entry to wiki-cloud/log.md
    log_path = os.path.join(wiki_dir, 'log.md')
    if os.path.exists(log_path):
        log_entry = f"\n## [{today_str}] lint | wiki-cloud health check\n\nfindings: {total} total ({error_count} errors, {warning_count} warnings, {info_count} info)\nauto_fixes: {autofix_applied} applied\nreport: wiki-cloud/maintenance/lint-report.md\n"
        with open(log_path, 'a', encoding='utf-8') as f:
            f.write(log_entry)

# ---------------------------------------------------------------------------
# Print summary to stderr
# ---------------------------------------------------------------------------

autofix_msg = f"{autofix_applied} applied" if (do_fix and not dry_run) else "none -- use --fix to apply"
report_msg = "wiki-cloud/maintenance/lint-report.md" if not dry_run else "(dry-run, no report written)"

print(f"""
=== Wiki Lint Results ===
Errors:   {error_count}
Warnings: {warning_count}
Info:     {info_count}
~~~~~~~~~~~~~~~~~~~~~~~~""", file=sys.stderr)

# Print top findings (up to 5)
top_n = 5
top_findings = findings[:top_n]
if top_findings:
    print("Top findings:", file=sys.stderr)
    for sev, cat, path, msg in top_findings:
        print(f"  [{sev}] {path}: {msg}", file=sys.stderr)

print(f"Auto-fixes applied: {autofix_msg}", file=sys.stderr)
print(f"Report: {report_msg}", file=sys.stderr)

# CI / --strict exit policy for text mode: exit 1 iff any post-remap
# error-severity finding is present. Non-CI, non-strict mode always exits 0
# (v1.0 behavior preserved).
if CI_MODE or STRICT_MODE:
    has_error = any(sev == 'error' for (sev, _, _, _) in findings)
    sys.exit(1 if has_error else 0)

PYEOF

echo "Lint complete." >&2
