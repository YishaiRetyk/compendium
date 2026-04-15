#!/usr/bin/env bash
# bin/lint.sh -- Wiki health-check CLI helper (AGENTS.md section 11.3).
# Detects orphan pages, missing cross-references, stale claims, contradictions,
# knowledge gaps, and structural issues. Produces wiki/maintenance/lint-report.md.
#
# Zero LLM/API calls. Deterministic, file-based checks only.
# Requires: python3 with PyYAML.
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: bin/lint.sh [OPTIONS] [wiki-directory]

Wiki health-check that detects structural issues and stale claims.
Produces wiki/maintenance/lint-report.md and prints a compact summary.

Options:
  --help, -h          Show this help message
  --dry-run           Report findings without writing report page or log
  --fix               Apply mechanical auto-fixes (stale markers)
  --category <cat>    Run only specified category:
                        orphan, crossref, stale, contradiction, gap,
                        provenance, yaml, drift
                      Default: all categories

Arguments:
  [wiki-directory]    Path to wiki directory (default: wiki/)

Exit codes:
  0  Script ran successfully (even if error-level findings exist)
  1  Script itself FAILED to run (python3 not found, wiki dir missing)

Examples:
  bin/lint.sh                      # Full lint, write report
  bin/lint.sh --dry-run            # Full lint, no report written
  bin/lint.sh --category orphan    # Only orphan detection
  bin/lint.sh --fix wiki/          # Full lint with auto-fixes
EOF
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

WIKI_DIR="${WIKI_ROOT:-wiki/}"
DRY_RUN=0
FIX=0
CATEGORY="all"

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
VALID_PRIVACY = {'local_only', 'cloud_safe'}
VALID_COMPILATION = {'pending', 'partial', 'compiled', 'stale'}

BASE_FIELDS = [
    'id', 'title', 'type', 'status', 'summary', 'created_at', 'updated_at',
    'sources', 'epistemic_status', 'tags', 'domains', 'supersedes',
    'superseded_by', 'privacy', 'aliases', 'has_contradictions', 'knowledge_domain',
]

SOURCE_EXTRA_FIELDS = ['path', 'content_hash', 'ingested_at', 'source_type', 'compilation_status']

WIKILINK_RE = re.compile(r'\[\[([^\]|]+)(?:\|[^\]]+)?\]\]')
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
        if 'privacy' in fm and fm['privacy'] not in VALID_PRIVACY:
            add_finding('error', 'yaml', rel, f"Invalid privacy: '{fm['privacy']}'")

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
        prov_matches = PROV_RE.findall(body)
        for source_id, locator, support_type, checked_at in prov_matches:
            if source_id not in source_registry:
                add_finding('error', 'provenance', rel,
                            f'Broken prov ref: {source_id} not found in {wiki_dir}sources/')

# ---------------------------------------------------------------------------
# Check 3: Orphan detection (case-insensitive, alias-aware)
# ---------------------------------------------------------------------------

if should_run('orphan'):
    print("  Checking for orphan pages...", file=sys.stderr)

    # Build resolution map: lowercase variant -> page id
    resolution_map = {}  # lowercase name -> set of page ids
    page_ids = set()

    for fpath, fm, body, err in all_pages:
        if fm is None:
            continue
        pid = fm.get('id', '')
        if not pid:
            continue
        page_ids.add(pid)

        # Add id, title, aliases (all lowercased) to resolution map
        variants = set()
        variants.add(pid.lower())
        if fm.get('title'):
            variants.add(fm['title'].lower())
        for alias in (fm.get('aliases') or []):
            if alias:
                variants.add(str(alias).lower())

        for v in variants:
            resolution_map.setdefault(v, set()).add(pid)

    # Collect all wikilinks from all pages (lowercased)
    inbound_links = {}  # page_id -> set of linking page_ids
    for pid in page_ids:
        inbound_links[pid] = set()

    for fpath, fm, body, err in all_pages:
        if fm is None or body is None:
            continue
        linker_id = fm.get('id', '')
        wikilinks = WIKILINK_RE.findall(body)
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
                wikilinks = WIKILINK_RE.findall(scontent)
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

    # Reuse the resolution_map from orphan detection if available, otherwise rebuild
    if 'resolution_map' not in dir():
        resolution_map = {}
        for fpath, fm, body, err in all_pages:
            if fm is None:
                continue
            pid = fm.get('id', '')
            if not pid:
                continue
            variants = set()
            variants.add(pid.lower())
            if fm.get('title'):
                variants.add(fm['title'].lower())
            for alias in (fm.get('aliases') or []):
                if alias:
                    variants.add(str(alias).lower())
            for v in variants:
                resolution_map.setdefault(v, set()).add(pid)

    # Collect all unresolved wikilinks with page context
    # unresolved_links: target_lower -> { 'pages': set of page_ids, 'in_tldr_keyfacts': bool }
    unresolved_links = {}

    for fpath, fm, body, err in all_pages:
        if fm is None or body is None:
            continue
        linker_id = fm.get('id', '')
        wikilinks = WIKILINK_RE.findall(body)

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
            for lm in link_pattern.finditer(body):
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
    # Check that every wiki page has a wikilink in wiki/index.md
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
                            f'Page not listed in wiki/index.md: {page_id}')

    # --- DRFT-03: Obsidian vault awareness ---
    print("  Check 10e: Obsidian vault awareness (DRFT-03)...", file=sys.stderr)
    obsidian_dir = os.path.join(project_root, '.obsidian')
    if not os.path.isdir(obsidian_dir):
        add_finding('info', 'drift', '.obsidian/',
                    'No .obsidian/ directory found -- Obsidian vault may not be configured')
    # Check for non-.md files in wiki/ subdirectories (unexpected binaries)
    for root, dirs, files in os.walk(wiki_dir):
        # Skip maintenance/ directory (may contain non-standard files)
        if 'maintenance' in root:
            continue
        for fname in files:
            if not fname.endswith('.md'):
                fpath = os.path.join(root, fname)
                rel = os.path.relpath(fpath)
                add_finding('info', 'drift', rel,
                            'Non-markdown file in wiki/ (may cause Obsidian issues)')

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
# Generate lint report (unless --dry-run)
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
privacy: cloud_safe
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

    # Append log entry to wiki/log.md
    log_path = os.path.join(wiki_dir, 'log.md')
    if os.path.exists(log_path):
        log_entry = f"\n## [{today_str}] lint | wiki health check\n\nfindings: {total} total ({error_count} errors, {warning_count} warnings, {info_count} info)\nauto_fixes: {autofix_applied} applied\nreport: wiki/maintenance/lint-report.md\n"
        with open(log_path, 'a', encoding='utf-8') as f:
            f.write(log_entry)

# ---------------------------------------------------------------------------
# Print summary to stderr
# ---------------------------------------------------------------------------

autofix_msg = f"{autofix_applied} applied" if (do_fix and not dry_run) else "none -- use --fix to apply"
report_msg = "wiki/maintenance/lint-report.md" if not dry_run else "(dry-run, no report written)"

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

PYEOF

echo "Lint complete." >&2
