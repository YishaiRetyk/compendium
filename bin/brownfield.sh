#!/usr/bin/env bash
# bin/brownfield.sh -- Phase 10 BRWN-01, BRWN-02, BRWN-16:
# Brownfield onboarding dispatcher.  Subcommands:
#   scan      Dry-run vault inventory; writes .brownfield/REPORT.md (no mutation).
#   bootstrap (Plan 10-03 populates this branch; currently exits 2)
#   suggest   NOT YET IMPLEMENTED — see Phase 11 (BRWN-11..20)
#   verify    NOT YET IMPLEMENTED — see Phase 11 (BRWN-17)
#
# D-16 classifier lives in bin/lib/brownfield_classify.py (reusable by
# Phase 11's 01-page-typing.sh).  scan uses PyYAML only; the round-trip
# write path arrives with Plan 10-03 for bootstrap.
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: bin/brownfield.sh <subcommand> [options]

Subcommands:
  scan                   Dry-run vault inventory; writes .brownfield/REPORT.md
  bootstrap              Idempotent mechanical transforms (default: dry-run)
  suggest                NOT YET IMPLEMENTED (Phase 11 BRWN-11..20)
  verify                 NOT YET IMPLEMENTED (Phase 11 BRWN-17)

scan options:
  --list-excluded        List every excluded file in REPORT.md (default: counts only)
  --root <path>          Vault root (default: .)
  -h, --help             Show this help

Decision boundary: Skip on parse failure or unsafe structure; merge on parseable metadata; warn whenever preserved values may not satisfy the schema.
EOF
}

# --- Subcommand dispatch -----------------------------------------------------
if [ "$#" -eq 0 ]; then
    usage >&2
    exit 1
fi
SUBCOMMAND="$1"
case "$SUBCOMMAND" in
    --help|-h) usage; exit 0 ;;
esac
shift

case "$SUBCOMMAND" in
    scan|bootstrap) ;;
    suggest|verify)
        echo "ERROR: '$SUBCOMMAND' not yet implemented — see Phase 11 (BRWN-11..20)" >&2
        exit 2
        ;;
    *)
        echo "ERROR: unknown subcommand: $SUBCOMMAND" >&2
        usage >&2
        exit 1
        ;;
esac

# Bootstrap is scaffolded but Plan 10-03 populates the implementation.
if [ "$SUBCOMMAND" = "bootstrap" ]; then
    echo "ERROR: bootstrap subcommand scaffolded but not yet implemented — Plan 10-03 populates" >&2
    exit 2
fi

# --- scan subcommand ---------------------------------------------------------
LIST_EXCLUDED=0
ROOT="."
while [ "$#" -gt 0 ]; do
    case "$1" in
        --list-excluded) LIST_EXCLUDED=1; shift ;;
        --root)
            if [ "$#" -lt 2 ]; then
                echo "ERROR: --root requires a path" >&2
                exit 1
            fi
            ROOT="$2"
            shift 2
            ;;
        --help|-h) usage; exit 0 ;;
        -*) echo "ERROR: unknown scan option: $1" >&2; usage >&2; exit 1 ;;
        *)  echo "ERROR: unexpected scan argument: $1" >&2; usage >&2; exit 1 ;;
    esac
done

if [ ! -d "$ROOT" ]; then
    echo "ERROR: --root path does not exist or is not a directory: $ROOT" >&2
    exit 1
fi

# Built-in exclusion directory denylist (D-19).  Hardcoded bash array per
# the bin/check-neutrality.sh PUBLIC_PATHS convention; user override comes
# via $ROOT/.brownfield-ignore below.
BROWNFIELD_DEFAULT_EXCLUDES=(
    ".obsidian"
    ".trash"
    "templates"
    "attachments"
    ".brownfield"
    ".git"
)
BF_DE=""
for p in "${BROWNFIELD_DEFAULT_EXCLUDES[@]}"; do
    if [ -z "$BF_DE" ]; then BF_DE="$p"; else BF_DE="$BF_DE:$p"; fi
done

# Compute the lib dir relative to this script.
BROWNFIELD_LIB_DIR="$(cd "$(dirname "$0")/lib" && pwd)"

export BROWNFIELD_DEFAULT_EXCLUDES_JOINED="$BF_DE"
export BROWNFIELD_ROOT="$ROOT"
export BROWNFIELD_LIST_EXCLUDED="$LIST_EXCLUDED"
export BROWNFIELD_LIB_DIR="$BROWNFIELD_LIB_DIR"

echo "Scanning ${ROOT} ..." >&2

python3 << 'PYEOF'
import os
import re
import sys
import fnmatch
from datetime import datetime, timezone
from pathlib import Path

# PyYAML only in scan.  The preserving-roundtrip YAML writer arrives with
# Plan 10-03 bootstrap; scan never writes YAML back to vault files.
import yaml

sys.path.insert(0, os.environ['BROWNFIELD_LIB_DIR'])
from brownfield_classify import classify_page, unknown_reason  # noqa: E402

ROOT = os.environ['BROWNFIELD_ROOT']
LIST_EXCLUDED = os.environ['BROWNFIELD_LIST_EXCLUDED'] == '1'
DEFAULT_EXCLUDE_DIRS = set(
    p for p in os.environ['BROWNFIELD_DEFAULT_EXCLUDES_JOINED'].split(':') if p
)

# Daily-note filename patterns (D-19).  Matched against basenames for files
# at root, under daily/, or under journal/.
DAILY_NOTE_RE = re.compile(r'^\d{4}-\d{2}-\d{2}\.md$')

# ---------------------------------------------------------------------------
# .brownfield-ignore parser (gitignore-like subset, fnmatch-based).
# Supported: blank lines, '#' comments, '!' negation, '*', '**'.
# Not supported: trailing-slash directory-only patterns, '\' escapes,
# character classes beyond what fnmatch provides natively.  This is the
# narrowed grammar declared in PLAN truths.
# ---------------------------------------------------------------------------

def _translate_pattern_to_regex(pat: str) -> re.Pattern:
    """Convert a gitignore-like subset glob to a regex.

    Handles '**' (match anything including /), '*' (match anything except /),
    and literal characters.  Anchored at start.  Does not anchor at end so a
    pattern like 'attachments' matches 'attachments/diagram.md'.
    """
    # Drop a leading '/' (treat as anchored-to-root; equivalent here since
    # we match against relative paths).
    if pat.startswith('/'):
        pat = pat[1:]
    # Drop a trailing '/' (we only support file matching at the moment; a
    # trailing slash conventionally means "dir only" but we treat it as a
    # prefix match for both the dir and anything inside).
    had_trailing_slash = pat.endswith('/')
    if had_trailing_slash:
        pat = pat[:-1]

    out: list[str] = ['^']
    i = 0
    while i < len(pat):
        c = pat[i]
        if c == '*':
            # '**' → match anything (including '/')
            if i + 1 < len(pat) and pat[i + 1] == '*':
                out.append('.*')
                i += 2
                # Skip a trailing '/' that often follows '**/'
                if i < len(pat) and pat[i] == '/':
                    i += 1
                continue
            # Single '*' → match anything except '/'
            out.append('[^/]*')
            i += 1
        elif c == '?':
            out.append('[^/]')
            i += 1
        elif c in r'.+()|{}[]^$\\':
            out.append(re.escape(c))
            i += 1
        else:
            out.append(re.escape(c))
            i += 1
    # Allow either exact match or match-followed-by-a-path-separator so
    # 'attachments' matches both 'attachments' and 'attachments/diagram.md'.
    out.append(r'(?:/.*)?$')
    return re.compile(''.join(out))


def load_brownfield_ignore(root: str) -> tuple[list[re.Pattern], list[re.Pattern]]:
    """Return (exclude_patterns, negate_patterns) lists of compiled regexes."""
    path = os.path.join(root, '.brownfield-ignore')
    exclude: list[re.Pattern] = []
    negate: list[re.Pattern] = []
    if not os.path.isfile(path):
        return exclude, negate
    with open(path, 'r', encoding='utf-8') as fh:
        for raw in fh:
            line = raw.strip()
            if not line or line.startswith('#'):
                continue
            if line.startswith('!'):
                body = line[1:].strip()
                if body:
                    negate.append(_translate_pattern_to_regex(body))
            else:
                exclude.append(_translate_pattern_to_regex(line))
    return exclude, negate


def _any_match(patterns: list[re.Pattern], rel: str) -> bool:
    for pat in patterns:
        if pat.match(rel):
            return True
    return False


# ---------------------------------------------------------------------------
# Frontmatter pre-flight (PyYAML safe_load).  Returns (frontmatter, body).
# ---------------------------------------------------------------------------

FRONTMATTER_RE = re.compile(r'^---\s*\n(.*?)\n---\s*\n', re.DOTALL)


def parse_frontmatter(text: str) -> tuple[dict | None, str]:
    match = FRONTMATTER_RE.match(text)
    if not match:
        return None, text
    yaml_block = match.group(1)
    body = text[match.end():]
    try:
        fm = yaml.safe_load(yaml_block)
        if isinstance(fm, dict):
            return fm, body
        return None, body
    except yaml.YAMLError:
        return None, body


# ---------------------------------------------------------------------------
# Walk + classify.
# ---------------------------------------------------------------------------

inventory: list[tuple[str, str, str, str]] = []  # (rel, label, confidence, trace)
unknown_entries: list[tuple[str, str]] = []      # (rel, question)
excluded_counts: dict[str, int] = {}
excluded_files: list[str] = []  # only populated when --list-excluded

bf_exclude, bf_negate = load_brownfield_ignore(ROOT)


def record_exclusion(rule: str, rel: str) -> None:
    excluded_counts[rule] = excluded_counts.get(rule, 0) + 1
    if LIST_EXCLUDED:
        excluded_files.append(f"{rel}  [{rule}]")


# os.walk with followlinks=False (the default) so symlinks pointing outside
# the vault do not escape the scan.
for dirpath, dirnames, filenames in os.walk(ROOT, followlinks=False):
    rel_dir = os.path.relpath(dirpath, ROOT)
    if rel_dir == '.':
        rel_dir = ''

    # Prune excluded directories in-place.  Track the prune so Excluded counts
    # reflect the default denylist hits.
    keep_dirnames = []
    for d in dirnames:
        rel_sub = os.path.join(rel_dir, d) if rel_dir else d
        if d in DEFAULT_EXCLUDE_DIRS:
            # Check for user negation before pruning.
            if _any_match(bf_negate, rel_sub):
                keep_dirnames.append(d)
                continue
            excluded_counts[f"default:{d}/**"] = excluded_counts.get(f"default:{d}/**", 0) + 1
            if LIST_EXCLUDED:
                excluded_files.append(f"{rel_sub}/  [default:{d}/**]")
            continue
        # User .brownfield-ignore dir exclude (only negate-able below).
        if _any_match(bf_exclude, rel_sub) and not _any_match(bf_negate, rel_sub):
            excluded_counts[f"ignore:{rel_sub}"] = excluded_counts.get(f"ignore:{rel_sub}", 0) + 1
            if LIST_EXCLUDED:
                excluded_files.append(f"{rel_sub}/  [ignore:{rel_sub}]")
            continue
        keep_dirnames.append(d)
    dirnames[:] = keep_dirnames

    for fname in filenames:
        # Only consider .md files for classification.  Non-md files are
        # silently ignored (not counted as excluded — they were never
        # candidates to begin with).
        if not fname.endswith('.md'):
            continue

        rel = os.path.join(rel_dir, fname) if rel_dir else fname
        # Normalize for matching
        rel_norm = rel.replace(os.sep, '/')

        # Daily-note exclusion: YYYY-MM-DD.md at root, daily/, or journal/.
        if DAILY_NOTE_RE.match(fname):
            at_root = (rel_dir == '')
            in_daily = rel_dir.split(os.sep)[0] in ('daily', 'journal')
            if at_root or in_daily:
                # Check negation first.
                if not _any_match(bf_negate, rel_norm):
                    record_exclusion('default:daily-notes', rel_norm)
                    continue

        # User .brownfield-ignore file exclude (respects negation).
        if _any_match(bf_exclude, rel_norm) and not _any_match(bf_negate, rel_norm):
            record_exclusion(f"ignore", rel_norm)
            continue

        # Read + classify.
        full = os.path.join(dirpath, fname)
        try:
            with open(full, 'r', encoding='utf-8') as fh:
                text = fh.read()
        except (OSError, UnicodeDecodeError):
            # Unreadable file; log but do not crash.
            unknown_entries.append((rel_norm, f"`{rel_norm}` — unreadable (binary or encoding error). What kind of page should this become?"))
            continue

        fm, body = parse_frontmatter(text)
        label, confidence, trace = classify_page(rel_norm, fm, body)
        inventory.append((rel_norm, label, confidence, trace))
        if label == 'unknown' or confidence == 'unknown':
            unknown_entries.append((rel_norm, unknown_reason(rel_norm, fm, body, trace)))


# ---------------------------------------------------------------------------
# Write .brownfield/REPORT.md (D-04 four-section structure; scan uses a + d).
# ---------------------------------------------------------------------------

report_dir = os.path.join(ROOT, '.brownfield')
os.makedirs(report_dir, exist_ok=True)
report_path = os.path.join(report_dir, 'REPORT.md')

timestamp = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
today = datetime.now(timezone.utc).strftime('%Y-%m-%d')

with open(report_path, 'w', encoding='utf-8') as rf:
    rf.write(f"# Brownfield Report — scan ({today})\n\n")

    # -- Inventory -----------------------------------------------------------
    rf.write("## Inventory\n\n")
    if inventory:
        rf.write("| path | label | confidence | signals |\n")
        rf.write("|------|-------|------------|---------|\n")
        for rel, label, confidence, trace in sorted(inventory):
            rf.write(f"| `{rel}` | {label} | {confidence} | {trace} |\n")
    else:
        rf.write("_No classifiable markdown pages found._\n")
    rf.write("\n")

    # -- Excluded ------------------------------------------------------------
    rf.write("## Excluded\n\n")
    if excluded_counts:
        for rule, count in sorted(excluded_counts.items()):
            rf.write(f"- excluded {count} file(s) under `{rule}`\n")
    else:
        rf.write("_Nothing excluded._\n")
    if LIST_EXCLUDED and excluded_files:
        rf.write("\n### Full excluded list\n\n")
        for line in sorted(excluded_files):
            rf.write(f"- {line}\n")
    rf.write("\n")

    # -- Needs human judgment ------------------------------------------------
    rf.write("## Needs human judgment\n\n")
    if unknown_entries:
        for rel, question in sorted(unknown_entries):
            rf.write(f"- {question}\n")
    else:
        rf.write("_No pages flagged for human review._\n")
    rf.write("\n")

    # -- Footer --------------------------------------------------------------
    rf.write("---\n")
    rf.write(f"*Generated by bin/brownfield.sh scan at {timestamp}*\n")

# ---------------------------------------------------------------------------
# Stderr summary (per PATTERNS.md §"bin/brownfield.sh" #4).
# ---------------------------------------------------------------------------

excluded_total = sum(excluded_counts.values())
unknown_total = len(unknown_entries)

print("", file=sys.stderr)
print("=== Brownfield Scan Results ===", file=sys.stderr)
print(f"Inventoried: {len(inventory)}", file=sys.stderr)
print(f"Excluded (directories + files): {excluded_total}", file=sys.stderr)
print(f"Unknown: {unknown_total}", file=sys.stderr)
print(f"Report: {os.path.relpath(report_path, ROOT)}", file=sys.stderr)
PYEOF
