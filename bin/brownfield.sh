#!/usr/bin/env bash
# bin/brownfield.sh -- Phase 10 BRWN-01..07, BRWN-16, BRWN-21:
# Brownfield onboarding dispatcher.  Subcommands:
#   scan      Dry-run vault inventory; writes .brownfield/REPORT.md (no mutation).
#   bootstrap Idempotent mechanical transforms (default: dry-run; --apply writes).
#   suggest   NOT YET IMPLEMENTED — see Phase 11 (BRWN-11..20)
#   verify    NOT YET IMPLEMENTED — see Phase 11 (BRWN-17)
#
# D-16 classifier lives in bin/lib/brownfield_classify.py (reusable by
# Phase 11's 01-page-typing.sh).  D-02 typed-merge + D-14 sentinel set live
# in bin/lib/brownfield_yaml.py (the round-trip write path used by bootstrap).
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

bootstrap options:
  --apply                Write changes to vault files (default is dry-run preview)
  --dry-run              Preview only; write .brownfield/REPORT.md (default)
  --verbose              Emit per-file unified diff on dry-run
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

# --- bootstrap subcommand ----------------------------------------------------
if [ "$SUBCOMMAND" = "bootstrap" ]; then
    APPLY=0
    VERBOSE=0
    BS_ROOT="."
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --apply)   APPLY=1;   shift ;;
            --dry-run) APPLY=0;   shift ;;
            --verbose) VERBOSE=1; shift ;;
            --root)
                if [ "$#" -lt 2 ]; then
                    echo "ERROR: --root requires a path" >&2
                    exit 1
                fi
                BS_ROOT="$2"
                shift 2
                ;;
            -h|--help) usage; exit 0 ;;
            -*) echo "ERROR: unknown bootstrap option: $1" >&2; usage >&2; exit 1 ;;
            *)  echo "ERROR: unexpected bootstrap argument: $1" >&2; usage >&2; exit 1 ;;
        esac
    done

    if [ ! -d "$BS_ROOT" ]; then
        echo "ERROR: --root path does not exist or is not a directory: $BS_ROOT" >&2
        exit 1
    fi

    # Built-in exclusion directory denylist (D-19) — mirrors scan.  Obsidian
    # plumbing dirs are NEVER touched by bootstrap even when --apply is set.
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

    BROWNFIELD_LIB_DIR="$(cd "$(dirname "$0")/lib" && pwd)"

    # Honor BROWNFIELD_FIXTURE_TODAY for pinned-date fixture tests; otherwise
    # compute today's UTC date.  The env var is scoped to test runs per the
    # fixture-date-freeze convention (tests/phase-10/fixtures/README.md).
    if [ -n "${BROWNFIELD_FIXTURE_TODAY:-}" ]; then
        BROWNFIELD_TODAY="$BROWNFIELD_FIXTURE_TODAY"
    else
        BROWNFIELD_TODAY="$(date -u '+%Y-%m-%d')"
    fi

    # Detect the repo root for source-summary path resolution (D-15 Codex fix #7).
    # Falls back to BS_ROOT when no .git is found — safe because D-15 source
    # hashing only fires on `wiki/sources/*.md` pages which are only touched
    # inside the scanned root anyway.
    BROWNFIELD_REPO_ROOT="$BS_ROOT"
    _probe="$BS_ROOT"
    while [ "$_probe" != "/" ] && [ -n "$_probe" ]; do
        if [ -e "$_probe/.git" ]; then
            BROWNFIELD_REPO_ROOT="$_probe"
            break
        fi
        _probe="$(cd "$_probe/.." && pwd)"
    done

    export BROWNFIELD_APPLY="$APPLY"
    export BROWNFIELD_VERBOSE="$VERBOSE"
    export BROWNFIELD_ROOT="$BS_ROOT"
    export BROWNFIELD_REPO_ROOT
    export BROWNFIELD_LIB_DIR
    export BROWNFIELD_TODAY
    export BROWNFIELD_DEFAULT_EXCLUDES_JOINED="$BF_DE"

    python3 << 'PYEOF'
import difflib
import hashlib
import io
import os
import re
import shutil
import sys
from datetime import datetime, timezone

# Actionable stderr message + exit 1 if ruamel.yaml is missing.  The helper
# module raises ImportError with this exact guidance, but the surface we want
# the user to see is the brownfield.sh tool — not an uncaught Python traceback.
try:
    import yaml as pyyaml
    sys.path.insert(0, os.environ['BROWNFIELD_LIB_DIR'])
    from brownfield_yaml import (  # noqa: E402
        DuplicateKeyError,
        build_d14_sentinel_set,
        merge_sentinels,
        read_fm_body,
        write_roundtrip,
    )
except ImportError as exc:
    if 'ruamel' in str(exc).lower():
        print(
            "ERROR: ruamel.yaml is required for brownfield bootstrap. "
            "Install: pip install ruamel.yaml (see docs/reference/brownfield.md).",
            file=sys.stderr,
        )
    else:
        print(f"ERROR: missing required import for brownfield bootstrap: {exc}", file=sys.stderr)
    sys.exit(1)


ROOT = os.environ['BROWNFIELD_ROOT']
REPO_ROOT = os.environ['BROWNFIELD_REPO_ROOT']
APPLY = os.environ['BROWNFIELD_APPLY'] == '1'
VERBOSE = os.environ['BROWNFIELD_VERBOSE'] == '1'
TODAY_STR = os.environ['BROWNFIELD_TODAY']
TODAY = datetime.strptime(TODAY_STR, '%Y-%m-%d').date()
DEFAULT_EXCLUDE_DIRS = set(
    p for p in os.environ['BROWNFIELD_DEFAULT_EXCLUDES_JOINED'].split(':') if p
)

# Daily-note pattern (D-19): YYYY-MM-DD.md at root or under daily/, journal/.
DAILY_NOTE_RE = re.compile(r'^\d{4}-\d{2}-\d{2}\.md$')

# ---------------------------------------------------------------------------
# .brownfield-ignore parser (mirrors scan's gitignore-subset — D-19).
# ---------------------------------------------------------------------------

def _translate_pattern_to_regex(pat):
    if pat.startswith('/'):
        pat = pat[1:]
    had_trailing_slash = pat.endswith('/')
    if had_trailing_slash:
        pat = pat[:-1]
    out = ['^']
    i = 0
    while i < len(pat):
        c = pat[i]
        if c == '*':
            if i + 1 < len(pat) and pat[i + 1] == '*':
                out.append('.*')
                i += 2
                if i < len(pat) and pat[i] == '/':
                    i += 1
                continue
            out.append('[^/]*')
            i += 1
        elif c == '?':
            out.append('[^/]')
            i += 1
        else:
            out.append(re.escape(c))
            i += 1
    out.append(r'(?:/.*)?$')
    return re.compile(''.join(out))


def _load_brownfield_ignore(root):
    path = os.path.join(root, '.brownfield-ignore')
    exclude, negate = [], []
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


def _any_match(patterns, rel):
    for pat in patterns:
        if pat.match(rel):
            return True
    return False


# ---------------------------------------------------------------------------
# Walk the vault and collect pending writes.
# ---------------------------------------------------------------------------

pending_writes = []  # list of dicts: {path, rel, fm, body, raw_yaml, merged, collisions, warnings, source_hash_update}
skipped = []         # list of dicts: {rel, parse_error, suggestion}
already_bootstrapped = 0  # D-10 sentinel-skip count
orphan_sources = []  # list of rel paths in sources/ with no wiki/sources/ summary

bf_exclude, bf_negate = _load_brownfield_ignore(ROOT)

for dirpath, dirnames, filenames in os.walk(ROOT, followlinks=False):
    rel_dir = os.path.relpath(dirpath, ROOT)
    if rel_dir == '.':
        rel_dir = ''

    keep_dirnames = []
    for d in dirnames:
        rel_sub = os.path.join(rel_dir, d) if rel_dir else d
        if d in DEFAULT_EXCLUDE_DIRS:
            if _any_match(bf_negate, rel_sub):
                keep_dirnames.append(d)
                continue
            continue
        if _any_match(bf_exclude, rel_sub) and not _any_match(bf_negate, rel_sub):
            continue
        keep_dirnames.append(d)
    dirnames[:] = keep_dirnames

    for fname in filenames:
        if not fname.endswith('.md'):
            continue
        rel = os.path.join(rel_dir, fname) if rel_dir else fname
        rel_norm = rel.replace(os.sep, '/')

        # Daily-note exclusion (D-19).
        if DAILY_NOTE_RE.match(fname):
            at_root = (rel_dir == '')
            in_daily = rel_dir.split(os.sep)[0] in ('daily', 'journal')
            if at_root or in_daily:
                if not _any_match(bf_negate, rel_norm):
                    continue

        # User .brownfield-ignore (respects negation).
        if _any_match(bf_exclude, rel_norm) and not _any_match(bf_negate, rel_norm):
            continue

        full = os.path.join(dirpath, fname)
        try:
            fm, body, raw_yaml = read_fm_body(full)
        except DuplicateKeyError as e:
            skipped.append({
                'rel': rel_norm,
                'parse_error': str(e),
                'suggestion': "remove duplicate keys; keep the intended value",
            })
            continue
        except pyyaml.YAMLError as e:
            # Condense to first non-empty line so SKIPPED.md stays scannable.
            msg = next((ln for ln in str(e).splitlines() if ln.strip()), 'parse error')
            suggestion = "replace tab indentation with spaces; re-run bootstrap" if '\\t' in repr(msg).lower() or 'tab' in msg.lower() else "fix YAML syntax in frontmatter; re-run bootstrap"
            skipped.append({
                'rel': rel_norm,
                'parse_error': msg,
                'suggestion': suggestion,
            })
            continue
        except (OSError, UnicodeDecodeError) as e:
            skipped.append({
                'rel': rel_norm,
                'parse_error': f"read error: {e}",
                'suggestion': "check file encoding and permissions",
            })
            continue

        # D-10 per-file idempotency: skip pages already marked bootstrapped.
        if fm is not None and fm.get('bootstrap_stage') == 'bootstrapped':
            already_bootstrapped += 1
            continue

        sentinels = build_d14_sentinel_set(full, body, TODAY)
        try:
            merged, collisions, warnings = merge_sentinels(fm, sentinels, rel_norm)
        except Exception as e:  # defensive; merge should not raise on parseable input
            skipped.append({
                'rel': rel_norm,
                'parse_error': f"merge error: {e}",
                'suggestion': "inspect file; consider manual frontmatter correction",
            })
            continue

        pending_writes.append({
            'path': full,
            'rel': rel_norm,
            'fm': fm,
            'body': body,
            'raw_yaml': raw_yaml,
            'merged': merged,
            'collisions': collisions,
            'warnings': warnings,
        })

# ---------------------------------------------------------------------------
# D-15 source-file hashing: update content_hash on existing wiki/sources/*.md
# summary pages using the repo root (not --root) as the resolution base.
# ---------------------------------------------------------------------------

def _hash_raw_source(abs_raw_path):
    h = hashlib.sha256()
    with open(abs_raw_path, 'rb') as fh:
        for chunk in iter(lambda: fh.read(65536), b''):
            h.update(chunk)
    return h.hexdigest()


# Build a set of raw source paths (relative to repo root) whose summaries exist —
# used below to detect orphan raw sources.  O(N+M) via set membership instead of
# O(N*M) nested loops (Gemini perf hint).
referenced_source_paths = set()

for pending in pending_writes:
    if '/wiki/sources/' not in '/' + pending['rel']:
        continue
    merged = pending['merged']
    if 'path' not in merged:
        continue
    raw_rel = merged['path']
    if not isinstance(raw_rel, str) or not raw_rel.strip():
        continue
    referenced_source_paths.add(raw_rel)
    abs_raw = os.path.join(REPO_ROOT, raw_rel)
    if os.path.isfile(abs_raw):
        digest = _hash_raw_source(abs_raw)
        new_hash = f"sha256:{digest}"
        existing = merged.get('content_hash')
        if existing != new_hash:
            merged['content_hash'] = new_hash

# Orphan raw sources: files under ROOT/sources/ with no summary referencing them.
sources_dir = os.path.join(ROOT, 'sources')
if os.path.isdir(sources_dir):
    for dirpath, dirnames, filenames in os.walk(sources_dir, followlinks=False):
        for fn in filenames:
            if not fn.endswith('.md'):
                continue
            abs_raw = os.path.join(dirpath, fn)
            rel_raw = os.path.relpath(abs_raw, ROOT).replace(os.sep, '/')
            # Compare against both root-scoped and repo-scoped forms since
            # summary pages may reference either.
            rel_raw_repo = os.path.relpath(abs_raw, REPO_ROOT).replace(os.sep, '/')
            if rel_raw in referenced_source_paths or rel_raw_repo in referenced_source_paths:
                continue
            orphan_sources.append(rel_raw)

# ---------------------------------------------------------------------------
# BRWN-04 skeletons: create wiki/index.md and wiki/log.md if absent.
# Skeleton creation is mechanical (BRWN-04) and runs under --apply only.
# ---------------------------------------------------------------------------

skeleton_writes = []  # list of (abs_path, content)
if APPLY:
    wiki_dir = os.path.join(ROOT, 'wiki')
    if os.path.isdir(wiki_dir):
        index_path = os.path.join(wiki_dir, 'index.md')
        log_path = os.path.join(wiki_dir, 'log.md')
        if not os.path.exists(index_path):
            skeleton_writes.append((index_path, "# Index\n\n*Populated by wiki workflows per AGENTS.md §12.*\n"))
        if not os.path.exists(log_path):
            skeleton_writes.append((log_path, "# Log\n\n*Newest entries appended at bottom per AGENTS.md §12.*\n"))

# ---------------------------------------------------------------------------
# Write .brownfield/ state files (REPORT.md always; SKIPPED.md + APPLIED.md on --apply).
# ---------------------------------------------------------------------------

bf_dir = os.path.join(ROOT, '.brownfield')
os.makedirs(bf_dir, exist_ok=True)
report_path = os.path.join(bf_dir, 'REPORT.md')
skipped_path = os.path.join(bf_dir, 'SKIPPED.md')
applied_path = os.path.join(bf_dir, 'APPLIED.md')

all_collisions = [c for p in pending_writes for c in p['collisions']]
all_warnings = [w for p in pending_writes for w in p['warnings']]

timestamp = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
run_stamp = datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S UTC')

with open(report_path, 'w', encoding='utf-8') as rf:
    mode = 'apply' if APPLY else 'dry-run'
    rf.write(f"# Brownfield Report — bootstrap ({mode}, {TODAY_STR})\n\n")

    # Section (a): bootstrapped-successfully (dry-run: would-bootstrap).
    rf.write("## Bootstrapped successfully\n\n" if APPLY else "## Would bootstrap\n\n")
    clean = [p for p in pending_writes if not p['collisions'] and not p['warnings']]
    if clean:
        for p in clean:
            rf.write(f"- `{p['rel']}`\n")
    else:
        rf.write("_No pages in this category._\n")
    rf.write("\n")

    # Section (b): bootstrapped-with-preserved-collisions (Class A).
    rf.write("## Bootstrapped with preserved collisions\n\n")
    if all_collisions:
        for c in all_collisions:
            rf.write("### Preserved collision\n\n")
            rf.write(f"- path: {c['path']}\n")
            rf.write(f"- field: {c['field']}\n")
            rf.write("- action: preserved existing value\n")
            rf.write("- note: existing value retained during bootstrap; review optional\n\n")
    else:
        rf.write("_No Class-A collisions this run._\n\n")

    # Section (c): bootstrapped-with-schema-warnings (Class B noncanonical).
    rf.write("## Bootstrapped with schema warnings\n\n")
    if all_warnings:
        for w in all_warnings:
            rf.write("### Preserved schema-authoritative field\n\n")
            rf.write(f"- path: {w['path']}\n")
            rf.write(f"- field: {w['field']}\n")
            rf.write(f"- value: {w['value']}\n")
            rf.write("- action: preserved (schema-authoritative per D-02)\n")
            rf.write("- note: noncanonical value may fail lint; review in suggest/verify\n\n")
    else:
        rf.write("_No Class-B schema warnings this run._\n\n")

    # Section (d): Needs human judgment — orphan raw sources fold in here (W-4 fix).
    rf.write("## Needs human judgment\n\n")
    if orphan_sources:
        for o in sorted(orphan_sources):
            rf.write(
                f"- `{o}` — raw source has no corresponding `wiki/sources/*.md` summary page. "
                "Should a source summary be created (handoff to Phase 11 `suggest/01-page-typing.sh`)?\n"
            )
    else:
        rf.write("_No pages flagged for human review._\n")
    rf.write("\n")

    rf.write("---\n")
    rf.write(f"*Generated by bin/brownfield.sh bootstrap at {timestamp}*\n")

# SKIPPED.md always reflects the current run's skipped set (D-05).  Overwrite
# on each run; users see exactly what this run skipped.  APPLIED.md is the
# append-only audit log (D-06).
if skipped:
    with open(skipped_path, 'w', encoding='utf-8') as sf:
        for s in skipped:
            sf.write("## Skipped due to parse failure\n\n")
            sf.write(f"- path: {s['rel']}\n")
            sf.write(f"- parse_error: {s['parse_error']}\n")
            sf.write(f"- suggestion: {s['suggestion']}\n\n")
elif os.path.exists(skipped_path):
    # If nothing skipped this run, remove stale file to avoid confusion.
    try:
        os.remove(skipped_path)
    except OSError:
        pass

# ---------------------------------------------------------------------------
# Dry-run path: print counts, path list, and exit 0.
# ---------------------------------------------------------------------------

parsed_total = len(pending_writes) + already_bootstrapped
would_bootstrap = len(pending_writes)
collisions_total = len(all_collisions)
warnings_total = len(all_warnings)
skipped_total = len(skipped)

if not APPLY:
    # Optional --verbose per-file unified diffs (D-09).  Use the difflib
    # pattern from init-wizard.sh: compare original file bytes to a rendered
    # in-memory image of the post-bootstrap file.
    if VERBOSE:
        from brownfield_yaml import make_yaml
        from ruamel.yaml.compat import StringIO as _SIO
        for p in pending_writes:
            y = make_yaml()
            buf = _SIO()
            y.dump(p['merged'], buf)
            yaml_out = buf.getvalue()
            if not yaml_out.endswith('\n'):
                yaml_out += '\n'
            body_out = p['body']
            if body_out and not body_out.startswith('\n'):
                body_out = '\n' + body_out
            rendered = f"---\n{yaml_out}---\n{body_out}"
            with open(p['path'], 'r', encoding='utf-8') as fh:
                original = fh.read()
            diff = difflib.unified_diff(
                original.splitlines(keepends=True),
                rendered.splitlines(keepends=True),
                fromfile=f"a/{p['rel']}",
                tofile=f"b/{p['rel']}",
            )
            sys.stdout.write(''.join(diff))

    # Printable path list (stdout).
    for p in pending_writes:
        print(p['rel'])

    # Stderr summary block with all 5 count labels (acceptance criterion).
    print("", file=sys.stderr)
    print("=== Brownfield Bootstrap (dry-run) ===", file=sys.stderr)
    print(f"Parsed: {parsed_total}", file=sys.stderr)
    print(f"Would bootstrap: {would_bootstrap}", file=sys.stderr)
    print(f"Collisions: {collisions_total} (Class A preserved)", file=sys.stderr)
    print(f"Schema warnings: {warnings_total} (Class B)", file=sys.stderr)
    print(f"Skipped: {skipped_total}", file=sys.stderr)
    print(f"Report: {os.path.relpath(report_path, ROOT)}", file=sys.stderr)
    print("(dry-run) Pass --apply to execute.", file=sys.stderr)
    sys.exit(0)

# ---------------------------------------------------------------------------
# Apply path: write every pending change, emit APPLIED.md, exit non-zero on
# the first hard write failure (D-11).
# ---------------------------------------------------------------------------

applied = []
write_failure = None

for p in pending_writes:
    try:
        write_roundtrip(p['path'], p['merged'], p['body'], p['raw_yaml'])
        applied.append({'rel': p['rel'], 'outcome': 'bootstrapped'})
    except Exception as e:
        write_failure = (p['rel'], str(e))
        break

skeleton_outcome = []
if write_failure is None:
    for skel_path, skel_content in skeleton_writes:
        try:
            with open(skel_path, 'w', encoding='utf-8', newline='\n') as fh:
                fh.write(skel_content)
            rel = os.path.relpath(skel_path, ROOT).replace(os.sep, '/')
            skeleton_outcome.append({'rel': rel, 'outcome': 'skeleton-created'})
        except OSError as e:
            write_failure = (os.path.relpath(skel_path, ROOT), str(e))
            break

# APPLIED.md append (D-06): header + applied list + skipped list + untouched-remainder.
with open(applied_path, 'a', encoding='utf-8') as af:
    af.write(f"## Run {run_stamp}\n\n")
    if applied:
        for a in applied:
            af.write(f"- `{a['rel']}` — {a['outcome']}\n")
    if skeleton_outcome:
        for s in skeleton_outcome:
            af.write(f"- `{s['rel']}` — {s['outcome']}\n")
    if not applied and not skeleton_outcome:
        af.write("_No files written this run._\n")
    if skipped:
        af.write("\n### Skipped\n\n")
        for s in skipped:
            af.write(f"- `{s['rel']}` — {s['parse_error']}\n")
    if write_failure is not None:
        af.write("\n### Write failure (halt per D-11)\n\n")
        af.write(f"- failed_on: `{write_failure[0]}`\n")
        af.write(f"- error: {write_failure[1]}\n")
        untouched_idx = next(
            (i for i, p in enumerate(pending_writes) if p['rel'] == write_failure[0]),
            None,
        )
        if untouched_idx is not None:
            remaining = [p['rel'] for p in pending_writes[untouched_idx + 1:]]
            if remaining:
                af.write("- untouched_remainder:\n")
                for r in remaining:
                    af.write(f"  - `{r}`\n")
    af.write("\n")

print("", file=sys.stderr)
print("=== Brownfield Bootstrap Results ===", file=sys.stderr)
print(f"Parsed: {parsed_total}", file=sys.stderr)
print(f"Bootstrapped: {len(applied)}", file=sys.stderr)
print(f"Collisions: {collisions_total} (Class A preserved)", file=sys.stderr)
print(f"Schema warnings: {warnings_total} (Class B)", file=sys.stderr)
print(f"Skipped: {skipped_total}", file=sys.stderr)
print(f"Applied: {os.path.relpath(applied_path, ROOT)}", file=sys.stderr)

if write_failure is not None:
    print(f"ERROR: write halted on {write_failure[0]}: {write_failure[1]}", file=sys.stderr)
    sys.exit(1)

sys.exit(0)
PYEOF

    # Safety net: python3 heredoc exits the process on sys.exit(), so reaching
    # here means no Python block ran (e.g., python3 missing).
    exit 0
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
