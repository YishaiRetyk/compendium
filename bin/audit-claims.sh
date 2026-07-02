#!/usr/bin/env bash
# bin/audit-claims.sh -- Claim Faithfulness Audit (Phase 13).
#
# Deterministic core: select high-risk claims (FAITH-01) -> resolve each
# [prov:source_id#locator] to a bounded passage from the RAW source at the source
# page's path: (FAITH-02, deterministic half) -> emit structured findings + a
# group-by-verdict report + a checkpoint (FAITH-03).
#
# This script mirrors bin/lint.sh's structure (bash arg-parse -> single python3
# heredoc) and COPIES lint's embedded primitives verbatim (lint's python is a
# monolithic heredoc, NOT an importable module -- 13-RESEARCH.md Assumption A1).
#
# SCOPE (Plan 13-03 -- verdict/verifier dispatch + the full §13 chokepoint):
#   - The SINGLE privacy chokepoint gates on the EFFECTIVE claim privacy
#     (resolve_effective_claim_privacy in bin/lib/privacy_resolve.py = strictest
#     of {claim-page, source-summary, raw-source, enclosing-dir, fail-closed
#     default}), NOT source privacy alone (REVIEW HIGH-A). It is the one partition
#     point upstream of BOTH the verdict dispatch AND --emit-worklist.
#   - local_only-effective claims are WITHHELD (-> skipped-privacy) unless
#     --allow-local; their per-record metadata is REDACTED to a bare aggregate
#     count on cloud-facing --emit-worklist stdout (REVIEW HIGH-C). Full detail
#     goes only to the privacy: local_only audit-report.md.
#   - The verdict step (--verifier <cmd>) is THE sole egress: payload on STDIN
#     ONLY via shlex.split(cmd) + shell=False; stdout parsed defensively (no eval).
#     With no --verifier, --emit-worklist ships the partitioned worklist (agent-
#     in-the-loop default, D-01) and resolved claims carry the declared-enum
#     `insufficient` placeholder with rationale "verifier not run".
#
# Verifier-locality contract (REVIEW HIGH-1): every verifier command is treated
# as cloud/egress by DEFAULT. There is NO flag and NO heuristic that inspects the
# command string to mark it trusted. The ONLY admission of a local_only passage
# into a passage-bearing output is the explicit AUDIT_ALLOW_LOCAL flag (set by
# --allow-local). The --local-verifier <cmd> flag is pure sugar that sets both
# the verifier command AND AUDIT_ALLOW_LOCAL.

set -euo pipefail

AUDIT_VERSION="0.1.0"

usage() {
    cat <<'EOF'
Usage: bin/audit-claims.sh [options]

Claim Faithfulness Audit -- deterministic core (Plan 13-02).

Options:
  --since <ref>          Recency base ref (default: last_audit_commit from
                         audit-state.md; fallback: wiki-wide selection).
  --sample N             Max claims to audit after priority-rank (default 20).
  --select <csv>         Subset of selectors: stale,epistemic,recency,fanout,
                         derived-report (default: all five). Unknown names
                         are an error, not silently ignored.
  --format json|report   Output format (default: report).
  --emit-worklist        Emit the resolved {claim,passage,...} worklist as JSON
                         to stdout (no verdict). local_only passages are withheld
                         absent --allow-local (interim privacy guard).
  --apply-verdicts <f>   Read a verdicts JSON back and merge into findings
                         (Plan 03 consumes; parse-and-merge stub here).
  --verifier <cmd>       Verifier command (CLOUD/egress by default). Verdict
                         dispatch lands in Plan 03.
  --allow-local          Opt-in: admit local_only passages to passage-bearing
                         output. Required for any local-only egress.
  --local-verifier <cmd> Sugar: same as that command plus the allow opt-in flag.
  --version              Print AUDIT_VERSION and exit.
  --help, -h             Show this help.
EOF
}

# --- Defaults ---
SINCE=""
SAMPLE="20"
SELECT="stale,epistemic,recency,fanout,derived-report"
FORMAT="report"
EMIT_WORKLIST="0"
APPLY_VERDICTS=""
AUDIT_VERIFIER=""
AUDIT_ALLOW_LOCAL="0"

# --- Bash arg-parse (copied from lint.sh: `while [ "$#" -gt 0 ]; do case "$1" in`
#     dispatch + the `[ "$#" -lt 2 ]` "requires a value" guard idiom). ---
while [ "$#" -gt 0 ]; do
    case "$1" in
        --help|-h) usage; exit 0 ;;
        --version) echo "$AUDIT_VERSION"; exit 0 ;;
        --since)
            if [ "$#" -lt 2 ]; then echo "ERROR: --since requires a value" >&2; exit 1; fi
            SINCE="$2"; shift 2 ;;
        --sample)
            if [ "$#" -lt 2 ]; then echo "ERROR: --sample requires a value" >&2; exit 1; fi
            SAMPLE="$2"; shift 2 ;;
        --select)
            if [ "$#" -lt 2 ]; then echo "ERROR: --select requires a value" >&2; exit 1; fi
            SELECT="$2"; shift 2 ;;
        --format)
            if [ "$#" -lt 2 ]; then echo "ERROR: --format requires a value" >&2; exit 1; fi
            case "$2" in
                json|report) FORMAT="$2" ;;
                *) echo "ERROR: --format must be 'json' or 'report', got '$2'" >&2; exit 1 ;;
            esac
            shift 2 ;;
        --emit-worklist) EMIT_WORKLIST="1"; shift ;;
        --apply-verdicts)
            if [ "$#" -lt 2 ]; then echo "ERROR: --apply-verdicts requires a value" >&2; exit 1; fi
            APPLY_VERDICTS="$2"; shift 2 ;;
        --verifier)
            if [ "$#" -lt 2 ]; then echo "ERROR: --verifier requires a value" >&2; exit 1; fi
            # Every verifier command is CLOUD/egress by default; admission is the
            # AUDIT_ALLOW_LOCAL flag, never inferred from the command string.
            AUDIT_VERIFIER="$2"; shift 2 ;;
        --allow-local) AUDIT_ALLOW_LOCAL="1"; shift ;;
        --local-verifier)
            if [ "$#" -lt 2 ]; then echo "ERROR: --local-verifier requires a value" >&2; exit 1; fi
            # Sugar that sets the verifier command AND the AUDIT_ALLOW_LOCAL flag.
            AUDIT_VERIFIER="$2"; AUDIT_ALLOW_LOCAL="1"; shift 2 ;;
        *) echo "ERROR: unknown option: $1" >&2; usage >&2; exit 1 ;;
    esac
done

# --- bin/lib import dir (robust path resolution; mirrors the brownfield
#     breadcrumb pattern so the script works when invoked via absolute path
#     from an unrelated cwd). schema/brownfield/migrations/01-page-typing.sh
#     is the precedent for a .sh heredoc importing a bin/lib python module. ---
export AUDIT_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/lib" && pwd)"

# --- bash -> python handoff (prefer check-privacy.sh's exit-propagation wrapper). ---
export AUDIT_SINCE="$SINCE"
export AUDIT_SAMPLE="$SAMPLE"
export AUDIT_SELECT="$SELECT"
export AUDIT_FORMAT="$FORMAT"
export AUDIT_EMIT_WORKLIST="$EMIT_WORKLIST"
export AUDIT_APPLY_VERDICTS="$APPLY_VERDICTS"
export AUDIT_VERIFIER
export AUDIT_ALLOW_LOCAL
export AUDIT_REPO_ROOT="${AUDIT_REPO_ROOT:-$PWD}"

set +e
python3 - <<'PYEOF'
import os, re, sys, json, shlex, subprocess
from datetime import date

# §13 privacy resolvers (bin/lib/privacy_resolve.py -- pure, egress-free).
sys.path.insert(0, os.environ['AUDIT_LIB_DIR'])
from privacy_resolve import resolve_source_privacy, resolve_effective_claim_privacy

# --- COPIED FROM bin/lint.sh (LINT_VERSION=1.3.0) ---
# These symbols are byte-copies from bin/lint.sh's monolithic python heredoc
# (which is NOT importable). Two sources of truth -- expected drift risk: if
# lint.sh changes any of these, re-copy. Copied symbols:
#   parse_frontmatter, PROV_RE, EPISTEMIC_INLINE_RE, WIKILINK_RE,
#   SOURCE_EXTRA_FIELDS, EXCLUDE_DIRS, EXCLUDE_FILES, the page walk with the
#   example: true skip + type=='source' classification, the source_registry
#   build, the hash-drift predicate, the inbound_links map, and the git-diff
#   subprocess shape.
# ----------------------------------------------------------------------------

REPO_ROOT = os.path.abspath(os.environ.get('AUDIT_REPO_ROOT', os.getcwd()))
WIKI_DIR = os.path.join(REPO_ROOT, 'wiki-cloud')
LOCAL_MAINT = os.path.join(REPO_ROOT, 'wiki-local', 'maintenance')
SAMPLE = int(os.environ.get('AUDIT_SAMPLE', '20') or '20')
SELECT = [s.strip() for s in os.environ.get('AUDIT_SELECT', '').split(',') if s.strip()]
FORMAT = os.environ.get('AUDIT_FORMAT', 'report')
SINCE = os.environ.get('AUDIT_SINCE', '') or ''
EMIT_WORKLIST = os.environ.get('AUDIT_EMIT_WORKLIST', '0') == '1'
APPLY_VERDICTS = os.environ.get('AUDIT_APPLY_VERDICTS', '') or ''
ALLOW_LOCAL = os.environ.get('AUDIT_ALLOW_LOCAL', '0') == '1'
# AUDIT_VERIFIER is parsed/stored but its dispatch is Plan 03. ALL verifiers are
# cloud/egress unless --allow-local is explicitly set -- never infer locality.
VERIFIER = os.environ.get('AUDIT_VERIFIER', '') or ''

import yaml

SOURCE_EXTRA_FIELDS = ['path', 'content_hash', 'ingested_at', 'source_type', 'compilation_status']
WIKILINK_RE = re.compile(r'\[\[([^\]|]+)(?:\|[^\]]+)?\]\]')
PROV_RE = re.compile(
    r'\[prov:([^#\]]+)#([^|\]]+)'
    r'(?:\|([^|\]]+))?'
    r'(?:\|([^\]]+))?'
    r'\]'
)
EPISTEMIC_INLINE_RE = re.compile(r'\[epistemic::\s*(sourced|mixed|inferred|tentative|stale)\]')
EXCLUDE_FILES = {'index.md', 'log.md'}
EXCLUDE_DIRS = {'maintenance', 'examples'}


def parse_frontmatter(filepath):
    """Extract YAML frontmatter and body from a wiki page. (COPIED from lint.sh)"""
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


def parse_frontmatter_str(content):
    """Like parse_frontmatter but over an in-memory string (the raw source text
    already read by read_raw_source). Returns (fm|None, body, error). fm is None
    when the text has no leading --- fence (no new file open -> no new egress)."""
    if not content.startswith('---'):
        return None, content, None
    try:
        end = content.index('---', 3)
        fm = yaml.safe_load(content[3:end])
        body = content[end+3:]
        if not isinstance(fm, dict):
            fm = None
        return fm, body, None
    except ValueError:
        return None, content, 'Unterminated frontmatter (missing closing ---)'
    except yaml.YAMLError as e:
        return None, content, f'YAML parse error: {e}'


# ----------------------------------------------------------------------------
# Page walk + source registry build (COPIED from lint.sh page walk classifier).
# ----------------------------------------------------------------------------
all_pages = []      # (path, fm, body, error)
source_pages = []   # (path, fm, body)

# Walk both wiki-cloud/ and wiki-local/ (two-tier page universe, Phase 15 §13 structural model)
for tier_dir in [WIKI_DIR, os.path.join(REPO_ROOT, 'wiki-local')]:
    if not os.path.isdir(tier_dir):
        continue
    for root, dirs, files in os.walk(tier_dir):
        rel_root = os.path.relpath(root, tier_dir)
        if rel_root.split(os.sep)[0] in EXCLUDE_DIRS:
            continue
        for fname in sorted(files):
            if not fname.endswith('.md'):
                continue
            if fname in EXCLUDE_FILES:
                continue
            fpath = os.path.join(root, fname)
            fm, body, err = parse_frontmatter(fpath)
            # example: true suppresses all checks (lint NEUT-04 parity).
            if isinstance(fm, dict) and fm.get('example') is True:
                continue
            all_pages.append((fpath, fm, body, err))
            if fm and fm.get('type') == 'source':
                source_pages.append((fpath, fm, body))

# source_registry: source_id -> {'fm': sfm, 'summary_rel_path': rel}
# Stores summary page repo-relative path so FAITH-04 can key off source tier (review HIGH #2/#3).
source_registry = {}
source_summary_path = {}  # source_id -> summary repo-relative path
for sp, sfm, sbody in source_pages:
    if sfm and 'id' in sfm:
        rel = os.path.relpath(sp, REPO_ROOT)
        source_registry[sfm['id']] = {'fm': sfm, 'summary_rel_path': rel}
        source_summary_path[sfm['id']] = rel


# ----------------------------------------------------------------------------
# Privacy chokepoint (REVIEW HIGH-A / HIGH-1 / HIGH-2 / HIGH-C, D-02).
# The full §13 three-level precedence + the strictest-wins effective-claim
# resolver live in bin/lib/privacy_resolve.py (imported above as
# resolve_source_privacy / resolve_effective_claim_privacy). The audit partition
# gates on resolve_effective_claim_privacy -- the strictest of {claim-page
# privacy, source-summary privacy, raw-source privacy, enclosing-dir, default}
# -- NOT source privacy alone. There is exactly ONE partition point upstream of
# BOTH the verdict dispatch AND --emit-worklist; local_only-effective claims are
# WITHHELD (-> skipped-privacy) unless AUDIT_ALLOW_LOCAL=1. Verifier locality is
# a FLAG (AUDIT_ALLOW_LOCAL), never inferred from the verifier command string.
# ----------------------------------------------------------------------------


# ----------------------------------------------------------------------------
# resolve_locator (FAITH-02 deterministic crux, D-11).
# Reads the RAW source file at the source page's path:, NEVER the summary's
# ## Extracted Claims. Returns (passage_text | None, verdict_override | None).
#   - passage_text is the resolved slice (str) on success.
#   - verdict_override is set for the operational degrades:
#       'insufficient-locator' (no passage extractable / bad locator / missing raw)
#       'skipped-nontext'      (#img)
# ----------------------------------------------------------------------------
ATX_RE = re.compile(r'^(#{1,6})\s+(.*?)\s*#*\s*$')


def _slugify(text):
    """lowercase, trim, collapse internal whitespace to '-', strip non [a-z0-9-]."""
    t = text.strip().lower()
    t = re.sub(r'\s+', '-', t)
    t = re.sub(r'[^a-z0-9-]', '', t)
    return t


def _strip_frontmatter(raw_text):
    """Return the body of a raw source, skipping a leading ---...--- YAML fence."""
    if raw_text.startswith('---'):
        try:
            end = raw_text.index('\n---', 3)
            # advance past the closing fence line
            nl = raw_text.find('\n', end + 1)
            if nl != -1:
                return raw_text[nl + 1:]
            return raw_text[end + 4:]
        except ValueError:
            return raw_text
    return raw_text


def _resolve_sec(raw_text, name):
    """Resolve a #sec:<name> locator against the raw source's ATX headings.
    Exact slug match is preferred; fallback is a contiguous hyphen-token
    subsequence match (a short authored slug matches a longer heading slug
    that contains its tokens in order, e.g. a two-token name against a
    heading slug carrying extra prefix/suffix tokens). First match in
    document order wins within each tier."""
    target = _slugify(name)
    target_tokens = [t for t in target.split('-') if t]
    lines = raw_text.splitlines()
    start = None
    start_level = None
    fallback = None
    fallback_level = None
    for i, line in enumerate(lines):
        m = ATX_RE.match(line)
        if not m:
            continue
        slug = _slugify(m.group(2))
        if slug == target:
            start = i
            start_level = len(m.group(1))
            break
        if fallback is None and target_tokens:
            heading_tokens = [t for t in slug.split('-') if t]
            n = len(target_tokens)
            if any(heading_tokens[j:j + n] == target_tokens
                   for j in range(len(heading_tokens) - n + 1)):
                fallback = i
                fallback_level = len(m.group(1))
    if start is None:
        start, start_level = fallback, fallback_level
    if start is None:
        return None
    # slice to the line before the next heading of same-or-higher level
    end = len(lines)
    for j in range(start + 1, len(lines)):
        m = ATX_RE.match(lines[j])
        if m and len(m.group(1)) <= start_level:
            end = j
            break
    return '\n'.join(lines[start:end]).strip() or None


def _resolve_para(raw_text, n):
    """n-th (1-indexed) blank-line-delimited paragraph of the BODY only.
    ATX headings are skipped (not paragraphs). Fenced code blocks count as ONE
    paragraph (internal blank lines do not split). List blocks count as one."""
    body = _strip_frontmatter(raw_text)
    lines = body.splitlines()
    paras = []
    cur = []
    in_fence = False
    for line in lines:
        stripped = line.strip()
        if stripped.startswith('```'):
            in_fence = not in_fence
            cur.append(line)
            continue
        if in_fence:
            cur.append(line)
            continue
        if stripped == '':
            if cur:
                paras.append(cur)
                cur = []
            continue
        if ATX_RE.match(line):
            # heading terminates the current paragraph and is itself skipped
            if cur:
                paras.append(cur)
                cur = []
            continue
        cur.append(line)
    if cur:
        paras.append(cur)
    if n < 1 or n > len(paras):
        return None
    return '\n'.join(paras[n - 1]).strip() or None


TS_RE = re.compile(r'^\s*\[?(\d{1,2}:\d{2}(?::\d{2})?)\]?')


def _ts_to_secs(ts):
    parts = [int(p) for p in ts.split(':')]
    if len(parts) == 3:
        h, m, s = parts
    else:
        h, m, s = 0, parts[0], parts[1]
    return h * 3600 + m * 60 + s


def _resolve_t(raw_text, start, end):
    lines = raw_text.splitlines()
    any_ts = False
    s0 = _ts_to_secs(start)
    e0 = _ts_to_secs(end)
    out = []
    for line in lines:
        m = TS_RE.match(line)
        if m:
            any_ts = True
            secs = _ts_to_secs(m.group(1))
            if s0 <= secs <= e0:
                out.append(line)
    if not any_ts:
        return None  # no recognizable timestamps -> unbounded -> insufficient-locator
    return '\n'.join(out).strip() or None


PAGE_MARK_RE = re.compile(r'<!--\s*page:\s*(\d+)\s*-->')


def _resolve_page(raw_text, lo, hi):
    """D-05 <!-- page: N --> slice. #p8 -> page:8 .. before page:9 (exclusive
    upper). #p12-14 -> page:12 .. page:15 (exclusive). Missing lower marker OR
    no markers at all -> None -> insufficient-locator. Missing upper -> EOF."""
    lines = raw_text.splitlines()
    marks = {}  # page number -> line index of its marker
    for i, line in enumerate(lines):
        m = PAGE_MARK_RE.search(line)
        if m:
            marks[int(m.group(1))] = i
    if not marks:
        return None
    if lo not in marks:
        return None  # lower marker absent -> NEVER feed the whole document
    start = marks[lo]
    upper_page = hi + 1
    end = marks.get(upper_page, len(lines))
    return '\n'.join(lines[start:end]).strip() or None


def _resolve_ref(text, n):
    """Return the Nth bullet in the first bibliography-style section in
    DOCUMENT order (whichever of ## Source Citations / Sources by Topic /
    Sources / References appears first in the text wins — the header list is
    an alternation, not a priority order). Positional numbering is sequential
    across topic sub-groups. Wrapped bullets include their indented
    continuation lines. Returns None if not found or N out of range."""
    header_re = re.compile(
        r'^##\s+(Source Citations|Sources by Topic|Sources|References)\s*$',
        re.MULTILINE | re.IGNORECASE
    )
    m = header_re.search(text)
    if not m:
        return None
    after_header = text[m.end():]
    next_h = re.search(r'^##\s', after_header, re.MULTILINE)
    section = after_header[:next_h.start()] if next_h else after_header
    bullets = []
    open_bullet = False
    for line in section.splitlines():
        if line.startswith('- '):
            bullets.append(line[2:].strip())
            open_bullet = True
        elif open_bullet and line[:1] in (' ', '\t') and line.strip():
            bullets[-1] += ' ' + line.strip()
        else:
            open_bullet = False
    if not bullets or n < 1 or n > len(bullets):
        return None
    return bullets[n - 1]


def _resolve_path(text, spec):
    """Resolve a repository #path: locator against the snapshot's ## Excerpts
    registry (repository-ingestion.md). `spec` is '<file>', '<file>:L<n>', or
    '<file>:L<n>-L<m>'. An excerpt heading is '### <file>' (whole-file excerpt,
    matches any request for that path) or '### <file>:L<a>-L<b>' (matches a
    path-only request, or a range request contained in [a, b]). Passage = the
    heading plus its content up to the next heading. None -> insufficient-locator.

    FENCE-AWARE: excerpt bodies quote file content in fenced blocks, and quoted
    markdown routinely contains '## '/'### ' lines — those must not read as
    section/entry boundaries (found live on the first real repository ingest:
    a CHANGELOG excerpt quoting a heading orphaned every excerpt after it).
    Boundary detection therefore skips fenced lines; passages return unmasked."""
    m_spec = re.fullmatch(r'(.+?)(?::L(\d+)(?:-L(\d+))?)?', spec.strip())
    if not m_spec or not m_spec.group(1):
        return None
    want_path = m_spec.group(1)
    want_lo = int(m_spec.group(2)) if m_spec.group(2) else None
    want_hi = int(m_spec.group(3)) if m_spec.group(3) else want_lo
    lines = text.splitlines()
    entry_re = re.compile(r'^###\s+(.+?)(?::L(\d+)-L(\d+))?\s*$')
    in_fence = False
    in_excerpts = False
    entries = []          # (line_idx, path, lo|None, hi|None)
    section_end = len(lines)
    for i, line in enumerate(lines):
        if line.strip().startswith('```'):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        if not in_excerpts:
            if re.match(r'^##\s+Excerpts\s*$', line, re.IGNORECASE):
                in_excerpts = True
            continue
        if re.match(r'^##\s', line):
            section_end = i
            break
        m = entry_re.match(line)
        if m:
            entries.append((i, m.group(1).strip(),
                            int(m.group(2)) if m.group(2) else None,
                            int(m.group(3)) if m.group(3) else None))
    for j, (idx, path, e_lo, e_hi) in enumerate(entries):
        if path != want_path:
            continue
        if want_lo is not None and e_lo is not None:
            if not (e_lo <= want_lo and want_hi <= e_hi):
                continue
        end = entries[j + 1][0] if j + 1 < len(entries) else section_end
        return '\n'.join(lines[idx:end]).strip()
    return None


def _resolve_commit(text, sha):
    """Resolve a repository #commit: locator: valid only for the snapshot's own
    commit (>=7 hex chars, prefix of a 40-hex SHA appearing in the ## Snapshot
    Metadata section). Passage = the metadata section. Any other SHA -> None
    (the snapshot documents exactly one commit)."""
    sha = sha.strip().lower()
    if not re.fullmatch(r'[0-9a-f]{7,40}', sha):
        return None
    header_re = re.compile(r'^##\s+Snapshot Metadata\s*$', re.MULTILINE | re.IGNORECASE)
    m = header_re.search(text)
    if not m:
        return None
    after = text[m.end():]
    next_h2 = re.search(r'^##\s', after, re.MULTILINE)
    section = after[:next_h2.start()] if next_h2 else after
    for full in re.findall(r'\b[0-9a-f]{40}\b', section.lower()):
        if full.startswith(sha):
            return section.strip()
    return None


def resolve_locator(raw_source_text, locator):
    """Return (passage | None, verdict_override | None).

    PROV_RE captures the locator WITHOUT its leading '#' (e.g. 'sec:introduction',
    'p8', 'img2'); normalize to the canonical '#'-prefixed form so callers may
    pass either shape. Defensively strip a trailing backslash (table-cell
    \\|...\\| escape residue) in case a caller passes an un-normalized locator."""
    loc = locator.strip().rstrip('\\')
    if not loc.startswith('#'):
        loc = '#' + loc
    try:
        if loc.startswith('#img'):
            return None, 'skipped-nontext'
        if loc.startswith('#sec:'):
            name = loc[len('#sec:'):]
            return _resolve_sec(raw_source_text, name), None
        # #path: MUST be dispatched before #para/#p — it shares the '#p' prefix
        # and would otherwise be swallowed by the page-range branch (D-11).
        if loc.startswith('#path:'):
            return _resolve_path(raw_source_text, loc[len('#path:'):]), None
        if loc.startswith('#commit:'):
            return _resolve_commit(raw_source_text, loc[len('#commit:'):]), None
        if loc.startswith('#para'):
            num = loc[len('#para'):]
            if not num.isdigit():
                return None, None
            return _resolve_para(raw_source_text, int(num)), None
        if loc.startswith('#t'):
            rng = loc[len('#t'):]
            if '-' in rng:
                a, b = rng.split('-', 1)
            else:
                a = b = rng
            if not a or not b:
                return None, None
            return _resolve_t(raw_source_text, a, b), None
        if loc.startswith('#p'):
            rng = loc[len('#p'):]
            if '-' in rng:
                a, b = rng.split('-', 1)
            else:
                a = b = rng
            if not a.isdigit() or not b.isdigit():
                return None, None
            return _resolve_page(raw_source_text, int(a), int(b)), None
        if loc.startswith('#r') and loc[2:].isdigit():
            n = int(loc[2:])
            return _resolve_ref(raw_source_text, n), None
    except Exception:
        return None, None
    # unknown / malformed locator
    return None, None


def read_raw_source(source_id):
    """Resolve source_id -> raw file at path:. Returns (raw_text|None, reason).
    Guards path traversal (T-13-04): a `..`-escaping path is rejected, never opened."""
    entry = source_registry.get(source_id)
    if not entry:
        return None, 'no-registry'
    sfm = entry['fm'] if isinstance(entry, dict) else entry  # compat
    if not sfm or 'path' not in sfm:
        return None, 'no-registry'
    rel = sfm['path']
    candidate = os.path.normpath(os.path.join(REPO_ROOT, rel))
    # path traversal guard: candidate MUST stay under REPO_ROOT
    if not (candidate == REPO_ROOT or candidate.startswith(REPO_ROOT + os.sep)):
        return None, 'path-escape'
    try:
        return open(candidate, encoding='utf-8').read(), None
    except FileNotFoundError:
        return None, 'missing-raw'
    except OSError:
        return None, 'missing-raw'


# ----------------------------------------------------------------------------
# FAITH-01 selectors. Each yields a set of (page_path, line_no, source_id, locator)
# claim tuples. A "claim" = a body line containing >=1 [prov:] marker (§6).
# ----------------------------------------------------------------------------
def claim_tuples_for_page(fpath, body):
    """Yield (rel_path, line_no, source_id, locator, support_type, line_text)
    for each [prov:] on each body line. Multiple markers on one line ->
    multiple tuples, each carrying ITS OWN support_type (group 3), not the
    first marker's. Locator and support_type are normalized at extraction so
    every consumer (findings, worklist, --apply-verdicts join key) sees the
    clean form: table-cell \\|...\\| escapes inject a trailing backslash into
    groups 2 and 3, which is stripped here."""
    rel = os.path.relpath(fpath, REPO_ROOT)
    out = []
    if not body:
        return out
    # body offset: frontmatter consumed by parse_frontmatter, so line numbers
    # here are body-relative; that is sufficient and deterministic for findings.
    for idx, line in enumerate(body.splitlines(), start=1):
        for m in PROV_RE.finditer(line):
            sid = m.group(1)
            loc = m.group(2).rstrip('\\')
            stype = (m.group(3) or '').rstrip('\\')
            # canonicalize locator to the '#'-prefixed form (PROV_RE drops the #)
            if not loc.startswith('#'):
                loc = '#' + loc
            out.append((rel, idx, sid, loc, stype, line))
    return out


def git_diff_changed_pages(base_ref):
    """Copied git-diff subprocess shape (lint.sh strict_added_epistemic_claims).
    Returns set of changed wiki-cloud/ + wiki-local/ file paths (repo-relative)."""
    try:
        result = subprocess.run(
            ['git', 'diff', '--name-only', f'{base_ref}...HEAD', '--', 'wiki-cloud/', 'wiki-local/'],
            cwd=REPO_ROOT, check=True, capture_output=True, text=True,
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        return set()
    return set(p.strip() for p in result.stdout.splitlines() if p.strip())


# Build the universe of claim tuples once.
all_claims = []  # list of (rel, line, sid, loc, stype, line_text, fm)
for fpath, fm, body, err in all_pages:
    if fm is None or body is None:
        continue
    if fm.get('type') == 'source':
        continue  # source summaries are registry entries, not audited claims
    for t in claim_tuples_for_page(fpath, body):
        all_claims.append(t + (fm,))

# --- stale-source set (rank 1): claims whose source_id has hash drift. ---
drifted_sources = set()
for src_id, entry in source_registry.items():
    sfm = entry['fm'] if isinstance(entry, dict) else entry
    content_hash = sfm.get('content_hash', '')
    compiled_hash = sfm.get('compiled_against_hash', '')
    comp_status = sfm.get('compilation_status', '')
    if content_hash and compiled_hash and content_hash != compiled_hash and comp_status != 'stale':
        drifted_sources.add(src_id)

# --- recency set (rank 3): claims on git-diff-changed pages. ---
recency_pages = set()
base_ref = SINCE
if not base_ref:
    # checkpoint lookup
    state_path = os.path.join(LOCAL_MAINT, 'audit-state.md')
    if os.path.exists(state_path):
        sfm, _, _ = parse_frontmatter(state_path)
        if isinstance(sfm, dict) and sfm.get('last_audit_commit'):
            base_ref = str(sfm['last_audit_commit'])
if base_ref:
    recency_pages = git_diff_changed_pages(base_ref)
    first_run_wide = False
else:
    # first-run / no-checkpoint fallback: wiki-wide SELECTION only -- bounded by
    # --sample; NOT a full-vault audit (ROADMAP non-goal preserved).
    first_run_wide = True

# --- high-fanout set (rank 4): claims on top-fanout pages. ---
resolution_map = {}
page_ids = set()
for fpath, fm, body, err in all_pages:
    if fm is None:
        continue
    pid = fm.get('id', '')
    if not pid:
        continue
    page_ids.add(pid)
    variants = {pid.lower()}
    if fm.get('title'):
        variants.add(fm['title'].lower())
    for alias in (fm.get('aliases') or []):
        if alias:
            variants.add(str(alias).lower())
    for v in variants:
        resolution_map.setdefault(v, set()).add(pid)

inbound_links = {pid: set() for pid in page_ids}
for fpath, fm, body, err in all_pages:
    if fm is None or body is None:
        continue
    linker_id = fm.get('id', '')
    for target in WIKILINK_RE.findall(body):
        target_lower = target.strip().lower()
        for rid in resolution_map.get(target_lower, set()):
            if rid != linker_id:
                inbound_links.setdefault(rid, set()).add(linker_id)

# Determine high-fanout pages (>=2 inbound links is "high" for the selector).
FANOUT_THRESHOLD = 2
high_fanout_ids = {pid for pid, linkers in inbound_links.items()
                   if len(linkers) >= FANOUT_THRESHOLD}
# map page id -> rel path
id_to_relpath = {}
for fpath, fm, body, err in all_pages:
    if fm and fm.get('id'):
        id_to_relpath[fm['id']] = os.path.relpath(fpath, REPO_ROOT)
high_fanout_paths = {id_to_relpath[pid] for pid in high_fanout_ids if pid in id_to_relpath}

# --- Classify each claim into selector buckets; assign best (lowest) rank. ---
RANK = {'stale': 1, 'epistemic': 2, 'recency': 3, 'fanout': 4, 'derived-report': 5}
selected = {}  # key (rel,line,sid,loc) -> (rank, tuple, selectors)

# Fail fast on unknown selector names: a typo would otherwise silently select
# zero claims and the run would complete "successfully" with nothing audited.
unknown_selectors = set(SELECT) - set(RANK)
if unknown_selectors:
    print(f"ERROR: unknown selector(s): {', '.join(sorted(unknown_selectors))} "
          f"(valid: {', '.join(sorted(RANK))})", file=sys.stderr)
    sys.exit(1)


def selector_active(name):
    return name in SELECT


for rel, line, sid, loc, stype, line_text, fm in all_claims:
    key = (rel, line, sid, loc)
    hits = []
    if selector_active('stale') and sid in drifted_sources:
        hits.append('stale')
    if selector_active('epistemic') and EPISTEMIC_INLINE_RE.search(line_text):
        ekind = EPISTEMIC_INLINE_RE.search(line_text).group(1)
        if ekind in ('inferred', 'tentative'):
            hits.append('epistemic')
    if selector_active('recency'):
        if first_run_wide or rel in recency_pages:
            hits.append('recency')
    if selector_active('fanout') and rel in high_fanout_paths:
        hits.append('fanout')
    if selector_active('derived-report'):
        entry = source_registry.get(sid, {})
        src_fm = entry.get('fm', {}) if isinstance(entry, dict) else {}
        if src_fm.get('source_type') == 'research-report':
            hits.append('derived-report')
    if not hits:
        continue
    best_rank = min(RANK[h] for h in hits)
    prev = selected.get(key)
    if prev is None or best_rank < prev[0]:
        selected[key] = (best_rank, (rel, line, sid, loc, stype, line_text, fm), hits)

# Priority-rank order: stale(1) -> epistemic(2) -> recency(3) -> fanout(4)
# -> derived-report(5), tie-break by (rel, line) for determinism.
ordered = sorted(
    selected.values(),
    key=lambda v: (v[0], v[1][0], v[1][1]),
)
total_selected = len(ordered)
capped = ordered[:SAMPLE]
skipped_count = total_selected - len(capped)


# ----------------------------------------------------------------------------
# Resolve + build findings (9-key dict, D-14). Severity map:
#   contradicts -> warning; weak/insufficient/insufficient-locator/
#   skipped-privacy/skipped-nontext -> info; supports -> info. NEVER error.
# Deterministic-core stub: a resolved claim has verdict `insufficient` with
# rationale "verifier not run" (Plan 03 OVERWRITES with the real dispatch).
# ----------------------------------------------------------------------------
def severity_for(verdict):
    if verdict == 'contradicts':
        return 'warning'
    return 'info'


findings = []
worklist = []                 # the SINGLE partitioned worklist (cloud_safe-effective
                              # entries only, unless --allow-local). BOTH the verdict
                              # dispatch and --emit-worklist consume THIS object.
redacted_skip_count = 0       # REVIEW HIGH-C: count of withheld local_only-effective
                              # claims whose per-record metadata is redacted on stdout.

VALID_VERDICTS = ('supports', 'weak', 'contradicts', 'insufficient',
                  'insufficient-locator', 'skipped-privacy', 'skipped-nontext')


def add_finding(verdict, rel, line, sid, loc, message):
    findings.append({
        'severity': severity_for(verdict),
        'category': 'faithfulness',
        'path': rel,
        'line': line,
        'source_id': sid,
        'locator': loc,
        'verdict': verdict,
        'message': message,
        'rationale': message,
    })


# ----------------------------------------------------------------------------
# Verifier dispatch (THE sole egress, D-01). Invoked per worklist entry via
# shlex.split(cmd) + shell=False (REVIEW MEDIUM): a command WITH args parses,
# and NO shell ever runs. The payload {claim,passage,support_type} is passed on
# STDIN ONLY via input= -- NEVER interpolated into argv (command-injection
# mitigation, T-13-09). stdout is parsed DEFENSIVELY: a JSONDecodeError or a
# missing/out-of-enum `verdict` yields an `insufficient` finding, never a crash,
# never eval (T-13-10).
# ----------------------------------------------------------------------------
def run_verifier(verifier_cmd, claim_text, passage, support_type):
    """Return (verdict, rationale). Defensive: malformed -> ('insufficient', ...)."""
    payload = json.dumps({
        'claim': claim_text,
        'passage': passage,
        'support_type': support_type,
    })
    try:
        proc = subprocess.run(
            shlex.split(verifier_cmd),
            input=payload, text=True, capture_output=True, shell=False,
            cwd=REPO_ROOT,
        )
    except (OSError, ValueError) as exc:
        return 'insufficient', f'verifier could not be invoked: {exc}'
    out = proc.stdout or ''
    try:
        parsed = json.loads(out)
    except (json.JSONDecodeError, ValueError):
        return 'insufficient', 'verifier returned unparseable output'
    if not isinstance(parsed, dict) or 'verdict' not in parsed:
        return 'insufficient', 'verifier returned unparseable output'
    verdict = parsed.get('verdict')
    if verdict not in VALID_VERDICTS:
        return 'insufficient', f'verifier returned out-of-enum verdict: {verdict!r}'
    rationale = parsed.get('rationale') or ''
    return verdict, rationale


# no-silent-caps log line (D-09) -- emitted as an info finding.
findings.append({
    'severity': 'info',
    'category': 'faithfulness',
    'path': 'wiki-local/maintenance/audit-report.md',
    'line': 0,
    'source_id': '',
    'locator': '',
    'verdict': 'insufficient',
    'message': f'selected={len(capped)} skipped={skipped_count}',
    'rationale': f'selected={len(capped)} skipped={skipped_count} (total pre-cap={total_selected}, sample={SAMPLE})',
})

# Locator-resolution health counters (hollow-audit tripwire). Deliberate skips
# (non-text, privacy) are excluded from the base: only claims that ATTEMPTED
# passage resolution count, so the ratio measures locator health, not policy.
locator_resolved_count = 0
locator_failed_count = 0

for rank, (rel, line, sid, loc, stype, line_text, fm), hits in capped:
    raw_text, reason = read_raw_source(sid)
    if raw_text is None:
        # missing raw / path-escape / no registry entry -> insufficient-locator
        locator_failed_count += 1
        add_finding('insufficient-locator', rel, line, sid, loc,
                    f'could not read raw source ({reason}) for {sid}{loc}')
        continue
    passage, override = resolve_locator(raw_text, loc)
    if override == 'skipped-nontext':
        add_finding('skipped-nontext', rel, line, sid, loc,
                    f'non-text locator {loc} ({sid}) -- skipped')
        continue
    if passage is None:
        locator_failed_count += 1
        add_finding('insufficient-locator', rel, line, sid, loc,
                    f'no passage extractable for {sid}{loc}')
        continue
    locator_resolved_count += 1

    # --- THE single privacy chokepoint (FAITH-04 / Phase 15 structural predicate):
    #     A claim is effective-local_only iff its page OR any contributing source-summary
    #     lives under wiki-local/. The collapsed resolver keys off the SUMMARY PAGE PATH
    #     (not the raw sources/ path -- raw sources/ is cloud-safe-only by structural rule).
    #     Collapsed from the §13 three-level precedence ladder in Phase 15. ---
    entry = source_registry.get(sid)
    sfm = entry['fm'] if isinstance(entry, dict) and 'fm' in entry else entry
    summary_path = source_summary_path.get(sid, '')
    effective_priv = resolve_effective_claim_privacy(
        fm, rel, sfm, None, summary_path)

    # Locality is the AUDIT_ALLOW_LOCAL flag, never inferred from the command
    # string. local_only-effective claims are admitted ONLY when --allow-local
    # (or the --local-verifier sugar) set the flag.
    if effective_priv == 'local_only' and not ALLOW_LOCAL:
        # WITHHOLD claim text AND passage from the partitioned worklist (the one
        # gate for BOTH egress surfaces). REVIEW HIGH-C: also redact the per-claim
        # metadata (source_id/path/line/locator/rationale -- private slugs,
        # T-13-21) from cloud-facing stdout. The full per-record detail lands ONLY
        # in the local-control-plane audit-report.md (wiki-local/maintenance/) via add_finding below.
        add_finding('skipped-privacy', rel, line, sid, loc,
                    f'local_only-effective claim withheld (no --allow-local)')
        redacted_skip_count += 1
        continue

    # Admitted (cloud_safe-effective, OR local_only with --allow-local). The
    # worklist carries the passage + claim text (the egress surface). effective_priv
    # is the structural claim privacy (wiki-local/ path-prefix predicate).
    # support_type is THIS marker's third [prov:] field, carried through the
    # claim tuple (normalized at extraction) — not re-extracted from the line,
    # which would grab the FIRST marker's support_type on multi-marker lines.
    support_type = stype
    worklist.append({
        'path': rel, 'line': line, 'source_id': sid, 'locator': loc,
        'claim': line_text.strip(), 'passage': passage,
        'support_type': support_type, 'privacy': effective_priv,
    })

    if VERIFIER:
        # THE sole egress: dispatch the (already-partitioned) claim to the verifier.
        verdict, rationale = run_verifier(VERIFIER, line_text.strip(), passage, support_type)
        add_finding(verdict, rel, line, sid, loc,
                    rationale or f'verifier verdict: {verdict}')
    else:
        # Agent-in-the-loop default (D-01): no --verifier -> the worklist IS the
        # output. The deterministic core emits no real verdict; carry the
        # declared-enum `insufficient` placeholder so the finding stays in-enum.
        add_finding('insufficient', rel, line, sid, loc, 'verifier not run')


# ----------------------------------------------------------------------------
# Hollow-audit tripwire. If most sampled claims could not have their cited
# passage located, the audit is silently checking almost nothing — the exact
# failure mode that once let a majority-unresolvable tier ship undetected.
# Review-only contract preserved: a prominent stderr WARNING plus a
# warning-severity finding; never an error, never a changed exit code.
# Floor: warn when under half of resolution ATTEMPTS succeed, with a minimum
# attempt count so tiny samples do not produce noise.
# ----------------------------------------------------------------------------
LOCATOR_RATIO_FLOOR = 0.5
LOCATOR_RATIO_MIN_ATTEMPTS = 5
locator_attempts = locator_resolved_count + locator_failed_count
if locator_attempts >= LOCATOR_RATIO_MIN_ATTEMPTS:
    locator_ratio = locator_resolved_count / locator_attempts
    if locator_ratio < LOCATOR_RATIO_FLOOR:
        tripwire_msg = (
            f'locator-resolution ratio {locator_resolved_count}/{locator_attempts} '
            f'({locator_ratio:.0%}) is below the {LOCATOR_RATIO_FLOOR:.0%} floor — '
            f'most sampled claims could not be matched to a source passage, so this '
            f'audit run is largely hollow. Likely causes: locator/heading drift, '
            f'renamed sections, or a resolver regression. Inspect the '
            f'insufficient-locator findings before trusting this run.'
        )
        print('!' * 72, file=sys.stderr)
        print(f'WARNING: {tripwire_msg}', file=sys.stderr)
        print('!' * 72, file=sys.stderr)
        findings.append({
            'severity': 'warning',
            'category': 'faithfulness',
            'path': 'wiki-local/maintenance/audit-report.md',
            'line': 0,
            'source_id': '',
            'locator': '',
            'verdict': 'insufficient-locator',
            'message': tripwire_msg,
            'rationale': tripwire_msg,
        })


# ----------------------------------------------------------------------------
# --apply-verdicts <file>: parse-and-merge stub (Plan 03 consumes fully).
# Match each verdict record to its finding on (path, line, source_id, locator).
# ----------------------------------------------------------------------------
if APPLY_VERDICTS:
    try:
        verdicts = json.loads(open(APPLY_VERDICTS, encoding='utf-8').read())
    except Exception:
        verdicts = []
    vmap = {}
    for v in (verdicts or []):
        if not isinstance(v, dict):
            continue
        # REVIEW MEDIUM (T-13-20): validate strictly. Reject records whose verdict
        # is outside the declared enum; key ONLY on (path,line,source_id,locator);
        # IGNORE any `passage`/`claim` keys (never re-import passage/claim text
        # from an external verdict file).
        vv = v.get('verdict')
        if vv not in VALID_VERDICTS:
            continue
        k = (v.get('path'), v.get('line'), v.get('source_id'), v.get('locator'))
        vmap[k] = v
    for f in findings:
        k = (f['path'], f['line'], f['source_id'], f['locator'])
        if k in vmap:
            vv = vmap[k]
            f['verdict'] = vv['verdict']
            f['severity'] = severity_for(vv['verdict'])
            if vv.get('rationale'):
                f['message'] = vv['rationale']
                f['rationale'] = vv['rationale']


# ----------------------------------------------------------------------------
# Emit: --emit-worklist (JSON, no verdict) | --format json | report.
# ----------------------------------------------------------------------------
def head_sha():
    try:
        r = subprocess.run(['git', 'rev-parse', '--short', 'HEAD'],
                           cwd=REPO_ROOT, check=True, capture_output=True, text=True)
        return r.stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return ''


def write_checkpoint():
    """D-15: advances even on a no-finding run. Under wiki-local/maintenance/ (structural local-only)."""
    maint = LOCAL_MAINT
    os.makedirs(maint, exist_ok=True)
    state_path = os.path.join(maint, 'audit-state.md')
    created_at = str(date.today())
    if os.path.exists(state_path):
        try:
            efm, _, _ = parse_frontmatter(state_path)
            if isinstance(efm, dict) and efm.get('created_at'):
                created_at = str(efm['created_at'])
        except Exception:
            pass
    today_str = str(date.today())
    content = f"""---
id: audit-state
title: Audit State
type: overview
status: active
summary: "Claim-faithfulness audit checkpoint (control-plane, not indexed)."
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
  - Audit State
has_contradictions: false
knowledge_domain: ""
last_audit_commit: {head_sha()}
last_audit_at: {today_str}
last_sample_size: {SAMPLE}
---

# Audit State

Checkpoint for `bin/audit-claims.sh`. Control-plane only; not listed in
`wiki-cloud/index.md`. Advances on every run, including no-finding runs (D-15).
"""
    with open(state_path, 'w', encoding='utf-8') as f:
        f.write(content)


def write_report():
    """audit-report.md -- pattern-twin of lint-report.md, grouped by verdict.
    Under wiki-local/maintenance/ (structural local-only, NOT cloud tier)."""
    maint = LOCAL_MAINT
    os.makedirs(maint, exist_ok=True)
    report_path = os.path.join(maint, 'audit-report.md')
    created_at = str(date.today())
    if os.path.exists(report_path):
        try:
            efm, _, _ = parse_frontmatter(report_path)
            if isinstance(efm, dict) and efm.get('created_at'):
                created_at = str(efm['created_at'])
        except Exception:
            pass
    today_str = str(date.today())

    from collections import OrderedDict
    groups = OrderedDict()
    for f in findings:
        groups.setdefault(f['verdict'], []).append(f)

    def fmt_group(verdict):
        items = groups.get(verdict, [])
        if not items:
            return '(none)\n'
        lines = []
        for f in items:
            loc = f"{f['source_id']}{f['locator']}" if f['source_id'] else '(meta)'
            lines.append(f"- **{f['path']}**:{f['line']} | {loc} | {f['message']}")
        return '\n'.join(lines) + '\n'

    verdict_order = ['contradicts', 'weak', 'supports', 'insufficient',
                     'insufficient-locator', 'skipped-privacy', 'skipped-nontext']
    body_sections = []
    for v in verdict_order:
        body_sections.append(f"## {v} ({len(groups.get(v, []))})\n\n{fmt_group(v)}")
    body = '\n'.join(body_sections)

    content = f"""---
id: audit-report
title: Audit Report
type: overview
status: active
summary: "Claim-faithfulness audit findings from most recent audit run."
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
  - Audit Report
has_contradictions: false
knowledge_domain: ""
---

# Audit Report

**Sample size:** {SAMPLE}
**Selected/Skipped:** {len(capped)}/{skipped_count} (total pre-cap {total_selected})

{body}"""
    with open(report_path, 'w', encoding='utf-8') as f:
        f.write(content)


if EMIT_WORKLIST:
    # Worklist is a passage-bearing EGRESS surface. The SINGLE chokepoint above
    # already withheld local_only-effective claims (text AND passage) absent
    # --allow-local. REVIEW HIGH-C: emit the cloud-facing stdout as the admitted
    # entries PLUS a single aggregate REDACTED record for the withheld claims --
    # carrying ONLY a bare count, NO per-record source_id/path/line/locator/
    # rationale (private slugs, T-13-21). Full per-record detail lands ONLY in
    # the privacy: local_only audit-report.md (write_report below). cloud_safe
    # worklist entries are emitted in full and are unaffected.
    emitted = list(worklist)
    if redacted_skip_count > 0:
        emitted.append({
            'verdict': 'skipped-privacy',
            'redacted': True,
            'count': redacted_skip_count,
        })
    sys.stdout.write(json.dumps(emitted, indent=2) + '\n')
    # Still advance the checkpoint + report so the run is auditable.
    write_report()
    write_checkpoint()
elif FORMAT == 'json':
    sys.stdout.write(json.dumps(findings, indent=2) + '\n')
    write_report()
    write_checkpoint()
else:
    write_report()
    write_checkpoint()
    print(f"Audit complete. Selected {len(capped)}, skipped {skipped_count}.", file=sys.stderr)
    print("Report: wiki-local/maintenance/audit-report.md", file=sys.stderr)

sys.exit(0)
PYEOF
PYRC=$?
set -e
exit "$PYRC"
