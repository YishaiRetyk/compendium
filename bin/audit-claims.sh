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
# SCOPE (Plan 13-02): this is the DETERMINISTIC CORE. The verdict/verifier
# dispatch and the full §13 privacy chokepoint are Plan 03. Here:
#   - resolved (non-skipped) claims carry the declared-enum verdict `insufficient`
#     with rationale "verifier not run" (NOT an out-of-enum placeholder token).
#     Plan 03 overwrites this with the real dispatched verdict.
#   - --emit-worklist ships an INTERIM frontmatter-only privacy guard: a local_only
#     (or privacy-absent -> fail-closed local_only) passage is withheld absent
#     --allow-local, substituting a {verdict:"skipped-privacy"} record. Plan 03
#     upgrades the check to the full three-level §13 resolver without relaxing this.
#   - NO network, NO subprocess egress (verdict dispatch lands in Plan 03).
#
# Verifier-locality contract (REVIEW HIGH-1): every --verifier is treated as
# cloud/egress by DEFAULT. There is NO flag and NO heuristic that marks a verifier
# "local" implicitly. The ONLY way a local_only passage enters a passage-bearing
# output is an explicit --allow-local. --local-verifier <cmd> is pure sugar for
# `--verifier <cmd> --allow-local`.

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
  --select <csv>         Subset of selectors: stale,epistemic,recency,fanout
                         (default: all four).
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
  --local-verifier <cmd> Sugar for: --verifier <cmd> --allow-local.
  --version              Print AUDIT_VERSION and exit.
  --help, -h             Show this help.
EOF
}

# --- Defaults ---
SINCE=""
SAMPLE="20"
SELECT="stale,epistemic,recency,fanout"
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
            # Every --verifier is CLOUD/egress by default; never infer locality.
            AUDIT_VERIFIER="$2"; shift 2 ;;
        --allow-local) AUDIT_ALLOW_LOCAL="1"; shift ;;
        --local-verifier)
            if [ "$#" -lt 2 ]; then echo "ERROR: --local-verifier requires a value" >&2; exit 1; fi
            # Sugar: --local-verifier <cmd> = --verifier <cmd> --allow-local.
            AUDIT_VERIFIER="$2"; AUDIT_ALLOW_LOCAL="1"; shift 2 ;;
        *) echo "ERROR: unknown option: $1" >&2; usage >&2; exit 1 ;;
    esac
done

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
import os, re, sys, json, subprocess
from datetime import date

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
WIKI_DIR = os.path.join(REPO_ROOT, 'wiki')
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


# ----------------------------------------------------------------------------
# Page walk + source registry build (COPIED from lint.sh page walk classifier).
# ----------------------------------------------------------------------------
all_pages = []      # (path, fm, body, error)
source_pages = []   # (path, fm, body)

if os.path.isdir(WIKI_DIR):
    for root, dirs, files in os.walk(WIKI_DIR):
        rel_root = os.path.relpath(root, WIKI_DIR)
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

# source_registry: source_id -> source fm  (the D-11 resolution anchor)
source_registry = {}
for sp, sfm, sbody in source_pages:
    if sfm and 'id' in sfm:
        source_registry[sfm['id']] = sfm


# ----------------------------------------------------------------------------
# Privacy: INTERIM frontmatter-only guard (REVIEW HIGH-2 / D-02).
# Plan 03 replaces this with the full three-level §13 precedence resolver.
# Fail-closed: privacy absent -> local_only.
# ----------------------------------------------------------------------------
def source_privacy(sfm):
    fm_priv = (sfm or {}).get('privacy')
    if fm_priv == 'cloud_safe':
        return 'cloud_safe'
    # local_only, missing, or any unknown value -> fail-closed local_only.
    return 'local_only'


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
    target = _slugify(name)
    lines = raw_text.splitlines()
    start = None
    start_level = None
    for i, line in enumerate(lines):
        m = ATX_RE.match(line)
        if m and _slugify(m.group(2)) == target:
            start = i
            start_level = len(m.group(1))
            break
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


def resolve_locator(raw_source_text, locator):
    """Return (passage | None, verdict_override | None).

    PROV_RE captures the locator WITHOUT its leading '#' (e.g. 'sec:introduction',
    'p8', 'img2'); normalize to the canonical '#'-prefixed form so callers may
    pass either shape."""
    loc = locator.strip()
    if not loc.startswith('#'):
        loc = '#' + loc
    try:
        if loc.startswith('#img'):
            return None, 'skipped-nontext'
        if loc.startswith('#sec:'):
            name = loc[len('#sec:'):]
            return _resolve_sec(raw_source_text, name), None
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
    except Exception:
        return None, None
    # unknown / malformed locator
    return None, None


def read_raw_source(source_id):
    """Resolve source_id -> raw file at path:. Returns (raw_text|None, reason).
    Guards path traversal (T-13-04): a `..`-escaping path is rejected, never opened."""
    sfm = source_registry.get(source_id)
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
    """Yield (rel_path, line_no, source_id, locator, line_text) for each [prov:]
    on each body line. Multiple markers on one line -> multiple tuples."""
    rel = os.path.relpath(fpath, REPO_ROOT)
    out = []
    if not body:
        return out
    # body offset: frontmatter consumed by parse_frontmatter, so line numbers
    # here are body-relative; that is sufficient and deterministic for findings.
    for idx, line in enumerate(body.splitlines(), start=1):
        for m in PROV_RE.finditer(line):
            sid, loc = m.group(1), m.group(2)
            # canonicalize locator to the '#'-prefixed form (PROV_RE drops the #)
            if not loc.startswith('#'):
                loc = '#' + loc
            out.append((rel, idx, sid, loc, line))
    return out


def git_diff_changed_pages(base_ref):
    """Copied git-diff subprocess shape (lint.sh strict_added_epistemic_claims).
    Returns set of changed wiki/ file paths (repo-relative)."""
    try:
        result = subprocess.run(
            ['git', 'diff', '--name-only', f'{base_ref}...HEAD', '--', 'wiki/'],
            cwd=REPO_ROOT, check=True, capture_output=True, text=True,
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        return set()
    return set(p.strip() for p in result.stdout.splitlines() if p.strip())


# Build the universe of claim tuples once.
all_claims = []  # list of (rel, line, sid, loc, line_text, fm)
for fpath, fm, body, err in all_pages:
    if fm is None or body is None:
        continue
    if fm.get('type') == 'source':
        continue  # source summaries are registry entries, not audited claims
    for t in claim_tuples_for_page(fpath, body):
        all_claims.append(t + (fm,))

# --- stale-source set (rank 1): claims whose source_id has hash drift. ---
drifted_sources = set()
for src_id, sfm in source_registry.items():
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
    state_path = os.path.join(WIKI_DIR, 'maintenance', 'audit-state.md')
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
RANK = {'stale': 1, 'epistemic': 2, 'recency': 3, 'fanout': 4}
selected = {}  # key (rel,line,sid,loc) -> (rank, tuple, selectors)


def selector_active(name):
    return name in SELECT


for rel, line, sid, loc, line_text, fm in all_claims:
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
    if not hits:
        continue
    best_rank = min(RANK[h] for h in hits)
    prev = selected.get(key)
    if prev is None or best_rank < prev[0]:
        selected[key] = (best_rank, (rel, line, sid, loc, line_text, fm), hits)

# Priority-rank order: stale(1) -> epistemic(2) -> recency(3) -> fanout(4),
# tie-break by (rel, line) for determinism.
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
worklist = []


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


# no-silent-caps log line (D-09) -- emitted as an info finding.
findings.append({
    'severity': 'info',
    'category': 'faithfulness',
    'path': 'wiki/maintenance/audit-report.md',
    'line': 0,
    'source_id': '',
    'locator': '',
    'verdict': 'insufficient',
    'message': f'selected={len(capped)} skipped={skipped_count}',
    'rationale': f'selected={len(capped)} skipped={skipped_count} (total pre-cap={total_selected}, sample={SAMPLE})',
})

for rank, (rel, line, sid, loc, line_text, fm), hits in capped:
    raw_text, reason = read_raw_source(sid)
    if raw_text is None:
        # missing raw / path-escape / no registry entry -> insufficient-locator
        add_finding('insufficient-locator', rel, line, sid, loc,
                    f'could not read raw source ({reason}) for {sid}{loc}')
        continue
    passage, override = resolve_locator(raw_text, loc)
    if override == 'skipped-nontext':
        add_finding('skipped-nontext', rel, line, sid, loc,
                    f'non-text locator {loc} ({sid}) -- skipped')
        continue
    if passage is None:
        add_finding('insufficient-locator', rel, line, sid, loc,
                    f'no passage extractable for {sid}{loc}')
        continue

    # Resolved. Determine source privacy (interim frontmatter-only guard).
    sfm = source_registry.get(sid)
    priv = source_privacy(sfm)
    if priv == 'local_only' and not ALLOW_LOCAL:
        # WITHHOLD passage from any passage-bearing output (worklist).
        add_finding('skipped-privacy', rel, line, sid, loc,
                    f'local_only source {sid} withheld (no --allow-local)')
        # worklist gets a passage-free skipped-privacy record
        worklist.append({
            'verdict': 'skipped-privacy',
            'path': rel, 'line': line, 'source_id': sid, 'locator': loc,
        })
        continue

    # Passage admitted. Worklist carries the passage (egress surface).
    worklist.append({
        'path': rel, 'line': line, 'source_id': sid, 'locator': loc,
        'claim': line_text.strip(), 'passage': passage,
    })
    # Deterministic-core verdict stub: declared-enum `insufficient`, NOT an
    # out-of-enum placeholder token. Plan 03 overwrites this.
    add_finding('insufficient', rel, line, sid, loc, 'verifier not run')


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
        k = (v.get('path'), v.get('line'), v.get('source_id'), v.get('locator'))
        vmap[k] = v
    for f in findings:
        k = (f['path'], f['line'], f['source_id'], f['locator'])
        if k in vmap:
            vv = vmap[k]
            if vv.get('verdict'):
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
    """D-15: advances even on a no-finding run. privacy: local_only (HIGH-B)."""
    maint = os.path.join(WIKI_DIR, 'maintenance')
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
privacy: local_only
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
`wiki/index.md`. Advances on every run, including no-finding runs (D-15).
"""
    with open(state_path, 'w', encoding='utf-8') as f:
        f.write(content)


def write_report():
    """audit-report.md -- pattern-twin of lint-report.md, grouped by verdict.
    privacy: local_only (NOT cloud_safe -- REVIEW HIGH-B)."""
    maint = os.path.join(WIKI_DIR, 'maintenance')
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
privacy: local_only
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
    # Worklist is a passage-bearing EGRESS surface. The interim privacy guard
    # above already withheld local_only passages absent --allow-local.
    sys.stdout.write(json.dumps(worklist, indent=2) + '\n')
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
    print("Report: wiki/maintenance/audit-report.md", file=sys.stderr)

sys.exit(0)
PYEOF
PYRC=$?
set -e
exit "$PYRC"
