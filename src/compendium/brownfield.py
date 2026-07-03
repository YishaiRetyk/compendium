# src/compendium/brownfield.py — Phase 25 MIG-01: byte-parity Python port of
# the frozen bash implementation in bin/brownfield.sh (2,259 lines).
#
# Port shape (plan 25-01):
#   - main() replicates the bash dispatch + per-subcommand option loops exactly
#     (same option handling order, same error strings, same exits, same stream
#     routing). No argparse.
#   - Each bash python3-heredoc body is one _cmd_*() function whose body is the
#     heredoc Python VERBATIM, except the sanctioned import mapping
#     bin/lib/brownfield_* -> compendium.common.* (surfaces verified identical).
#   - The bash glue's `export VAR=...` lines become os.environ[...] assignments
#     in main() BEFORE the _cmd_*() call, so the verbatim os.environ reads
#     inside the bodies keep working unchanged.
#   - sys.exit(N) calls inside the bodies are kept: SystemExit propagates
#     through main() and exits the process with N, matching the bash heredoc
#     exit under `set -euo pipefail` (each bash branch ends in `exit 0` after
#     its PYEOF, mirrored by the `return 0` after each _cmd_*() call).
#
# Behavior parity is byte-exact against the frozen bash oracle; do NOT
# "improve" observable output here — the parity harness diffs stdout, stderr,
# exit code, and the resulting file tree per invocation.
import datetime
import os
import sys

# usage() heredoc — bin/brownfield.sh lines 17-54, byte-exact.
_USAGE = """Usage: bin/brownfield.sh <subcommand> [options]

Subcommands:
  scan                   Dry-run vault inventory; writes .brownfield/REPORT.md
  bootstrap              Idempotent mechanical transforms (default: dry-run)
  suggest                Byte-copy migration scripts + generate candidate YAMLs
  review-typing          Review page-typing cluster decisions (TTY small-batch
                         or large-batch AI handoff); writes decisions.yaml
  verify                 Read-only lint wrapper over the brownfield category
                         set; --promote flips bootstrap_stage bootstrapped ->
                         verified on pages passing the D-14 5-gate pass-list

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

review-typing options:
  --root <path>          Vault root (default: .)
  --threshold N          Cluster-count threshold for small-batch vs large-batch
                         branch (default: 20)
  -h, --help             Show this help

verify options:
  --promote              Flip bootstrap_stage: bootstrapped -> verified on pages
                         passing the D-14 5-gate pass-list
  --root <path>          Vault root (default: .)
  -h, --help             Show this help

Decision boundary: Skip on parse failure or unsafe structure; merge on parseable metadata; warn whenever preserved values may not satisfy the schema.
Design principle: Review may be interactive and AI-guided; apply must always be deterministic.
"""

# suggest --help heredoc — lines 688-714, byte-exact.
_SUGGEST_HELP = """Usage: bin/brownfield.sh suggest [--root DIR]

Generate migration scripts + candidate data files for the brownfield workflow.

Suggest does two things:
  1. Byte-copies canonical migration scripts from schema/brownfield/migrations/
     into <root>/.brownfield/migrations/, prepending a deterministic op_hash
     header (on lines 2 and 3, immediately after the shebang) to each copy.
  2. Generates vault-specific candidate YAMLs under <root>/.brownfield/
     (page-typing-candidates.yaml, page-typing-decisions.yaml,
      provenance-bootstrap-report.yaml, cross-link-candidates.yaml,
      privacy-findings.yaml) and appends ## Cross-link candidates + ## Privacy
     review sections to <root>/.brownfield/REPORT.md.

Vault scope: uses the same .brownfield-ignore logic as `scan` (Phase 10) via
a shared walker helper.  Control-plane files (docs/, schema/, examples/,
AGENTS.md, etc.) listed in .brownfield-ignore are never classified.

Prerequisite: vault should be bootstrapped (bin/brownfield.sh bootstrap --apply)
so pages carry bootstrap_stage: bootstrapped.  If no bootstrapped pages are
found, suggest warns but still writes skeleton candidate files.

Flags:
  --root DIR   Vault root (default: .)
  --help       Print this help and exit 0.

Design principle: Review may be interactive and AI-guided; apply must always be deterministic.
"""

# review-typing --help heredoc — lines 1325-1352, byte-exact.
_REVIEW_TYPING_HELP = """Usage: bin/brownfield.sh review-typing [--root DIR] [--threshold N]

Review page-typing cluster decisions. Branches on pending-cluster count:
  < threshold (default 20) AND TTY available  -> small-batch TTY prompts
  >= threshold OR non-TTY stdout              -> large-batch AI handoff
    (writes .brownfield/review-typing-prompt.md; CLI returns)

TTY primitives per cluster:
  a) approve all   r) reject all   i) inspect   o) override   s) skip

Both modes write back to .brownfield/page-typing-decisions.yaml via
ruamel.yaml round-trip (comments preserved).

On stdin EOF (e.g., piped `</dev/null` in CI), session aborts cleanly and
any decisions made so far are persisted (review item 4 — validated at entry time).

Override label must be one of: entity | concept | source | comparison |
overview | decision (review item 11 — validated at entry time).

Color output honors NO_COLOR env var (Phase 8 D-20).

Flags:
  --root DIR        Vault root (default: .)
  --threshold N     Cluster-count threshold for small-batch vs large-batch
                    branch (default: 20)
  --help            Print this help and exit 0.

Design principle: Review may be interactive and AI-guided; apply must always be deterministic.
"""

# verify --help heredoc — lines 1700-1720, byte-exact.
_VERIFY_HELP = """Usage: bin/brownfield.sh verify [--root DIR] [--promote]

Read-only vault verification (default): wraps bin/lint.sh with the brownfield-
appropriate category set (yaml, provenance, orphan, crossref, brownfield) —
`privacy` is NOT checked here (see bin/check-privacy.sh for public paths).
Also emits WARN for stale candidate artifacts when .brownfield/*.yaml
metadata header's source_script_hash no longer matches the byte-copied
migration script (review item 9 — operational D-09 enforcement).

--promote  Run verify, then flip bootstrap_stage: bootstrapped -> verified on
           pages passing the D-14 5-gate pass-list:
             1. currently bootstrapped
             2. type: is a valid enum
             3. zero error-severity lint findings for the page
             4. type-specific required fields present (e.g., source pages
                have path/content_hash/ingested_at/source_type)
             5. no pending review decision in page-typing-decisions.yaml
--root DIR  Vault root (default: .)
--help      Print this help and exit 0.

Design principle: Review may be interactive and AI-guided; apply must always be deterministic.
"""

# Original bash: BROWNFIELD_DEFAULT_EXCLUDES array (D-19) joined with ':'
# (identical array in the bootstrap and scan glue blocks).
_BF_DE = ":".join((
    ".obsidian",
    ".trash",
    "templates",
    "attachments",
    ".brownfield",
    ".git",
))

_VALID_SUBCOMMANDS = ("scan", "bootstrap", "suggest", "review-typing", "verify")


def _repo_root():
    # bash: `$(cd "$(dirname "$0")/.." && pwd)` with $0 = <repo>/bin/brownfield.sh.
    # This module lives at <repo>/src/compendium/brownfield.py — three dirnames up.
    return os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def _lib_dir():
    # bash: `$(cd "$(dirname "$0")/lib" && pwd)` — <repo>/bin/lib.
    return os.path.join(_repo_root(), "bin", "lib")


def _isatty(fd):
    # bash: `[ -t 0 ]` / `[ -t 1 ]`
    try:
        return os.isatty(fd)
    except OSError:
        return False


# bootstrap python3 heredoc — bin/brownfield.sh lines 156-645, verbatim
# except the sanctioned import mapping.
def _cmd_bootstrap():
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
        from compendium.common.yaml_rt import (  # noqa: E402
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
    orphan_sources = []  # list of rel paths in sources/ with no wiki-cloud/sources/ summary

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
    # D-15 source-file hashing: update content_hash on existing wiki-cloud/sources/*.md
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
        if '/wiki-cloud/sources/' not in '/' + pending['rel']:
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
    # BRWN-04 skeletons: create wiki-cloud/index.md and wiki-cloud/log.md if absent.
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
                    f"- `{o}` — raw source has no corresponding `wiki-cloud/sources/*.md` summary page. "
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
            from compendium.common.yaml_rt import make_yaml
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


# suggest python3 heredoc — lines 746-1289, verbatim except import mapping.
def _cmd_suggest():
    import datetime
    import hashlib
    import os
    import pathlib
    import re
    import sys

    import yaml as pyyaml

    from compendium.common.classify import (  # noqa: E402
        VALID_TYPES,
        classify_page,
        cluster_by_signals,
        cluster_is_autoapproveable,
        PASCAL_CASE_RE,
        DATE_PREFIX_RE,
    )
    from compendium.common.walk import walk_vault_respecting_ignore  # noqa: E402  (REVIEWS item 3)


    ROOT = os.environ['BROWNFIELD_ROOT']
    TOOL = os.environ['BROWNFIELD_TOOL_VERSION']
    SCHEMA_MIG_DIR = os.environ['BROWNFIELD_SCHEMA_MIG_DIR']
    BF_DIR = os.path.join(ROOT, '.brownfield')
    BF_MIG_DIR = os.path.join(BF_DIR, 'migrations')
    os.makedirs(BF_MIG_DIR, exist_ok=True)

    # --- Date determinism (mirrors bootstrap's pattern) -----------------------
    fx_today = os.environ.get('BROWNFIELD_FIXTURE_TODAY') or ''
    if fx_today:
        try:
            datetime.date.fromisoformat(fx_today)
        except ValueError as e:
            sys.stderr.write(
                f'ERROR: BROWNFIELD_FIXTURE_TODAY="{fx_today}" is not valid YYYY-MM-DD: {e}\n'
            )
            sys.exit(1)
        GENERATED_AT = f'{fx_today}T00:00:00Z'
    else:
        GENERATED_AT = datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')


    # --- Hashing helpers (REVIEWS item 8: Python hashlib, macOS-portable) ---
    def sha256_bytes(b: bytes) -> str:
        return 'sha256:' + hashlib.sha256(b).hexdigest()


    def sha256_file(path: str) -> str:
        return sha256_bytes(pathlib.Path(path).read_bytes())


    def compute_op_hash(canonical_path: str, data_schema_version: int = 1) -> str:
        """op_hash covers canonical script body (post-op_hash-header-strip) + schema
        version.  No vault content; stable across vaults per D-10."""
        body = pathlib.Path(canonical_path).read_bytes()
        lines = body.split(b'\n')
        stripped = [
            ln for ln in lines
            if not ln.startswith(b'# op_hash:')
            and not ln.startswith(b'# op_hash_scope:')
        ]
        h = hashlib.sha256()
        h.update(b'\n'.join(stripped))
        h.update(f'\n# data_schema_version: {data_schema_version}\n'.encode())
        return 'sha256:' + h.hexdigest()


    # --- Byte-copy canonical scripts + inject op_hash header on lines 2+3 -----
    SCRIPTS = (
        '01-page-typing.sh',
        '02-provenance-bootstrap.sh',
        '03-cross-link-inference.sh',
        '04-privacy-review.sh',
    )

    for script in SCRIPTS:
        canon = os.path.join(SCHEMA_MIG_DIR, script)
        target = os.path.join(BF_MIG_DIR, script)
        if not os.path.isfile(canon):
            sys.stderr.write(f'ERROR: canonical migration script not found: {canon}\n')
            sys.exit(1)
        op_hash = compute_op_hash(canon)
        body_text = pathlib.Path(canon).read_text(encoding='utf-8')
        lines = body_text.split('\n')
        if not lines or not lines[0].startswith('#!'):
            sys.stderr.write(
                f'ERROR: canonical {script} does not start with a shebang '
                f'— REVIEWS item 13 invariant broken\n'
            )
            sys.exit(1)
        output_lines = [
            lines[0],
            f'# op_hash: {op_hash}',
            '# op_hash_scope: canonical-script-body + data-schema-version',
        ] + lines[1:]
        pathlib.Path(target).write_text('\n'.join(output_lines), encoding='utf-8')
        os.chmod(target, 0o755)

    # Write a shell-source-able env file so migration scripts copied into the
    # vault can locate the repo's bin/lib at run time.  The scripts live under
    # .brownfield/migrations/<script>.sh which has no ancestor link to the
    # source repo; without this breadcrumb they cannot find brownfield_yaml.
    # Gitignored alongside the rest of .brownfield/ (TMPL-04).
    env_path = os.path.join(BF_DIR, '.brownfield-env')
    lib_dir_abs = os.environ['BROWNFIELD_LIB_DIR']
    with open(env_path, 'w', encoding='utf-8') as fh:
        fh.write('# Written by bin/brownfield.sh suggest at ' + GENERATED_AT + '\n')
        fh.write('# Sourced by .brownfield/migrations/*.sh to locate bin/lib at run-time.\n')
        fh.write(f'BROWNFIELD_LIB_DIR="{lib_dir_abs}"\n')

    # Canonical script source hashes (for D-09 metadata header's source_script_hash field)
    SCRIPT_HASHES = {s: sha256_file(os.path.join(SCHEMA_MIG_DIR, s)) for s in SCRIPTS}


    # --- Slug-form signal derivation (matches cluster_by_signals' shape) -----
    # These must align with _LABEL_HINTS in bin/lib/brownfield_classify.py so
    # cluster_is_autoapproveable() can count agreement.  classify_page's
    # internal signals dict uses LABEL slugs (entity/concept/...); here we
    # derive SHAPE slugs (pascal/kebab/entity-like/inbound-heavy/...) from
    # the same raw page data.
    KEBAB_RE = re.compile(r'^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$')
    DR_PREFIX_RE = re.compile(r'^dr-\d{4}-\d{2}-\d{2}-')


    def filename_slug(rel_path: str) -> str:
        stem = pathlib.Path(rel_path).stem
        if DR_PREFIX_RE.match(stem):
            return 'dr-prefixed'
        if DATE_PREFIX_RE.match(stem) or stem.startswith('src-'):
            return 'date-prefixed'
        if PASCAL_CASE_RE.match(stem):
            return 'pascal'
        if KEBAB_RE.match(stem):
            return 'kebab'
        return 'none'


    SECTION_RE = re.compile(r'^##\s+(.+?)\s*$', re.MULTILINE)


    def heading_slug(body: str) -> str:
        secs = set(SECTION_RE.findall(body or ''))
        # Order matters: source + comparison shapes are more specific than
        # the generic TL;DR/Key Facts/Detail triad.
        if 'Extracted Claims' in secs and 'Source Metadata' in secs:
            return 'source-like'
        if 'Comparison Table' in secs:
            return 'comparison-like'
        if 'Decision' in secs and 'Alternatives Considered' in secs:
            return 'decision-like'
        if 'TL;DR' in secs and 'Key Facts' in secs and 'Detail' in secs:
            # Directory hint disambiguates entity vs concept vs overview — but
            # only when path clearly signals.  Default to 'entity-like' since
            # that maps to the most common brownfield page shape.
            return 'entity-like'
        return 'none'


    def dir_label_hint(rel_path: str) -> str | None:
        """Use directory-under-wiki/ as a weak label hint for heading slug.

        Returns a heading slug override when the path clearly signals (concepts/
        -> concept-like, overviews/ -> overview-like, etc.).  None otherwise.
        """
        parts = rel_path.replace('\\', '/').split('/')
        try:
            wiki_idx = parts.index('wiki')
            subdir = parts[wiki_idx + 1] if len(parts) > wiki_idx + 1 else None
        except ValueError:
            subdir = parts[0] if parts else None
        if subdir == 'concepts':
            return 'concept-like'
        if subdir == 'entities':
            return 'entity-like'
        if subdir == 'overviews':
            return 'overview-like'
        if subdir == 'sources':
            return 'source-like'
        if subdir == 'comparisons':
            return 'comparison-like'
        if subdir == 'decisions':
            return 'decision-like'
        return None


    # --- Walk vault via shared walker (REVIEWS item 3) ------------------------
    FM_RE = re.compile(r'^---\r?\n(.*?)\r?\n---\r?\n(.*)$', re.DOTALL)
    WIKILINK_RE = re.compile(r'\[\[([^\]|#]+)')


    def parse_fm_body(path: str):
        try:
            raw = pathlib.Path(path).read_text(encoding='utf-8', errors='replace')
        except OSError:
            return None, ''
        m = FM_RE.match(raw)
        if not m:
            return None, raw
        try:
            fm = pyyaml.safe_load(m.group(1)) or {}
        except Exception:
            return None, raw
        if not isinstance(fm, dict):
            return None, m.group(2)
        return fm, m.group(2)


    pages_data = []  # list of (abs_path, rel_path, fm, body)
    inbound: dict[str, int] = {}

    for abs_path in walk_vault_respecting_ignore(ROOT):
        rel = os.path.relpath(abs_path, ROOT).replace(os.sep, '/')
        fm, body = parse_fm_body(abs_path)
        pages_data.append((abs_path, rel, fm, body))
        for m in WIKILINK_RE.finditer(body or ''):
            target_title = m.group(1).strip()
            inbound[target_title] = inbound.get(target_title, 0) + 1

    # Sort for determinism
    pages_data.sort(key=lambda t: t[1])


    def inbound_count_for(fm, rel):
        title = (fm or {}).get('title') or pathlib.Path(rel).stem
        return inbound.get(str(title), 0)


    _DIR_TO_LABEL = {
        'concept-like':    'concept',
        'entity-like':     'entity',
        'overview-like':   'overview',
        'source-like':     'source',
        'comparison-like': 'comparison',
        'decision-like':   'decision',
    }

    classifications = []
    bootstrapped_paths = []
    for abs_path, rel, fm, body in pages_data:
        ic = inbound_count_for(fm, rel)
        label, confidence, _trace = classify_page(rel, fm, body or '', inbound_count=ic)
        fm_slug = 'none'
        if fm and isinstance(fm.get('type'), str):
            t = fm['type'].strip()
            if t in VALID_TYPES:
                fm_slug = t

        # Heading slug: prefer directory hint (unambiguous when the page lives
        # under wiki-cloud/concepts/, wiki-cloud/entities/, etc.); fall back to body-based
        # shape detection for flat vaults that don't use the wiki-cloud/<type>/ layout.
        h_from_dir = dir_label_hint(rel)
        h_from_body = heading_slug(body or '')
        if h_from_dir:
            h = h_from_dir
        elif h_from_body != 'none':
            h = h_from_body
        else:
            h = 'none'

        # Proposed label: explicit frontmatter wins; directory hint second;
        # classify_page's rule-based output third.  This is the label used
        # to look up _LABEL_HINTS for auto-approve agreement counting.
        if fm_slug != 'none':
            proposed_label = fm_slug
        elif h_from_dir:
            proposed_label = _DIR_TO_LABEL.get(h_from_dir, label)
        else:
            proposed_label = label

        outbound = len(WIKILINK_RE.findall(body or ''))
        if outbound >= 5:
            links_slug = 'outbound-heavy'
        elif outbound == 0:
            links_slug = 'none'
        else:
            links_slug = 'outbound-light'

        inbound_slug = 'inbound-heavy' if ic >= 5 else 'inbound-light'

        classifications.append({
            'path': rel,
            'label': proposed_label,
            'confidence': confidence,
            'signals': {
                'frontmatter': fm_slug,
                'filename': filename_slug(rel),
                'heading': h,
                'inbound': inbound_slug,
                'links': links_slug,
            },
            'inbound_count': ic,
        })

        if fm and fm.get('bootstrap_stage') == 'bootstrapped':
            bootstrapped_paths.append(rel)

    clusters = cluster_by_signals(classifications)


    # --- Write metadata header helper ----------------------------------------
    def write_metadata_header(fh, source_script: str):
        fh.write('# ---\n')
        fh.write('# schema_version: 1\n')
        fh.write(f'# tool_version: {TOOL}\n')
        fh.write(f'# generated_at: {GENERATED_AT}\n')
        fh.write(f'# vault_root: {ROOT}\n')
        fh.write(f'# source_script_hash: {SCRIPT_HASHES[source_script]}\n')
        fh.write('# ---\n')


    # --- page-typing-candidates.yaml -----------------------------------------
    candidates_path = os.path.join(BF_DIR, 'page-typing-candidates.yaml')
    with open(candidates_path, 'w', encoding='utf-8') as fh:
        write_metadata_header(fh, '01-page-typing.sh')
        # Emit clusters AND per-page classifications so consumers can inspect
        # individual paths.  The "pages" list on each cluster is the authoritative
        # membership record used by 01-page-typing.sh --apply in Plan 11-03.
        payload = {
            'clusters': clusters,
            'pages': [
                {'path': c['path'], 'label': c['label'], 'confidence': c['confidence']}
                for c in classifications
            ],
        }
        pyyaml.safe_dump(payload, fh, sort_keys=False, default_flow_style=False, allow_unicode=True)


    # --- page-typing-decisions.yaml (REVIEWS item 7: D-03 widened predicate) --
    decisions = {'clusters': []}
    for cl in clusters:
        auto = cluster_is_autoapproveable(cl)
        decisions['clusters'].append({
            'cluster_id': cl['cluster_id'],
            'page_count': cl['page_count'],
            'proposed_label': cl['proposed_label'],
            'confidence': cl['confidence'],
            'decision': 'approve' if auto else 'pending',
            'resolved_label': cl['proposed_label'] if auto else None,
            'overrides': [],
        })

    decisions_path = os.path.join(BF_DIR, 'page-typing-decisions.yaml')
    with open(decisions_path, 'w', encoding='utf-8') as fh:
        write_metadata_header(fh, '01-page-typing.sh')
        # REVIEWS item 10: point readers at the per-script applied.log variance doc.
        fh.write('# Note: per-script applied.log block shapes documented in schema/brownfield/migrations/README.md.\n')
        pyyaml.safe_dump(decisions, fh, sort_keys=False, default_flow_style=False, allow_unicode=True)


    # --- provenance-bootstrap-report.yaml (02 dry-run preview) ---------------
    # WR-01/WR-02 fix: import canonical eligibility helpers from
    # brownfield_provenance instead of re-implementing the regexes here. The
    # library is the same code 02-provenance-bootstrap.sh consumes on --apply,
    # so the suggest preview and apply results cannot drift.
    from compendium.common.provenance import section_scan  # noqa: E402


    prov_report = {'pages': []}
    for abs_path, rel, fm, body in pages_data:
        if not fm or fm.get('bootstrap_stage') != 'bootstrapped':
            continue
        eligible = section_scan(body or '', ['TL;DR', 'Key Facts'])
        sample = [ln for _, ln in eligible[:3]]
        entry = {'path': rel, 'eligible_bullets': len(eligible), 'sample': sample}
        if not eligible:
            entry['note'] = 'no eligible claim bullets found'
        prov_report['pages'].append(entry)

    prov_path = os.path.join(BF_DIR, 'provenance-bootstrap-report.yaml')
    with open(prov_path, 'w', encoding='utf-8') as fh:
        write_metadata_header(fh, '02-provenance-bootstrap.sh')
        pyyaml.safe_dump(prov_report, fh, sort_keys=False, default_flow_style=False, allow_unicode=True)


    # --- cross-link-candidates.yaml (03 output) ------------------------------
    TITLE_MAP: dict[str, str] = {}
    ALIAS_MAP: dict[str, str] = {}
    for abs_path, rel, fm, body in pages_data:
        t = (fm or {}).get('title') or pathlib.Path(rel).stem
        TITLE_MAP[str(t)] = rel
        for a in ((fm or {}).get('aliases') or []):
            ALIAS_MAP[str(a)] = rel

    CODE_FENCE = re.compile(r'^```')
    EXISTING_WL = re.compile(r'\[\[[^\]]+\]\]')


    def eligible_title(t: str) -> bool:
        if not t:
            return False
        tokens = t.split()
        return len(tokens) >= 2 or len(t) >= 8


    cross_links = {'candidates': []}
    for abs_path, rel, fm, body in pages_data:
        if not body:
            continue
        in_fence = False
        seen_pairs: set = set()
        for ln_no, ln in enumerate(body.splitlines(), start=1):
            if CODE_FENCE.match(ln):
                in_fence = not in_fence
                continue
            if in_fence:
                continue
            masked = EXISTING_WL.sub(lambda m: ' ' * len(m.group(0)), ln)
            for title, target in list(TITLE_MAP.items()) + list(ALIAS_MAP.items()):
                if target == rel:
                    continue
                if not eligible_title(title):
                    continue
                pattern = re.compile(r'\b' + re.escape(title) + r'\b')
                if pattern.search(masked):
                    pair = (rel, target)
                    if pair in seen_pairs:
                        continue
                    seen_pairs.add(pair)
                    existing_link = ('[[' + title + ']]') in body
                    match_type = 'exact-title' if title in TITLE_MAP else 'alias'
                    cross_links['candidates'].append({
                        'source_page': rel,
                        'line_number': ln_no,
                        'matched_text': ln.strip()[:120],
                        'proposed_target': target,
                        'match_type': match_type,
                        'target_already_linked_from_source': bool(existing_link),
                    })
                    break

    cross_links_path = os.path.join(BF_DIR, 'cross-link-candidates.yaml')
    with open(cross_links_path, 'w', encoding='utf-8') as fh:
        write_metadata_header(fh, '03-cross-link-inference.sh')
        pyyaml.safe_dump(cross_links, fh, sort_keys=False, default_flow_style=False, allow_unicode=True)


    # --- privacy-findings.yaml (04 output) -----------------------------------
    # REVIEWS item 12: .brownfield/ is gitignored; raw email/phone intentionally
    # preserved so operators can triage.  SSN values redacted to '[redacted-SSN]'.
    EMAIL_RE = re.compile(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b')
    PHONE_RE = re.compile(r'\b(?:\+?1[-.\s]?)?\(?[2-9][0-9]{2}\)?[-.\s]?[0-9]{3}[-.\s]?[0-9]{4}\b')
    SSN_RE = re.compile(r'\b\d{3}[-\s]\d{2}[-\s]\d{4}\b')
    EXAMPLE_TLDS = ('@example.com', '@example.org', '@example.net', '@test.invalid')
    BACKTICK = re.compile(r'`[^`]*`')

    privacy = {'findings': []}
    for abs_path, rel, fm, body in pages_data:
        if not body:
            continue
        in_fence = False
        for ln_no, ln in enumerate(body.splitlines(), start=1):
            if CODE_FENCE.match(ln):
                in_fence = not in_fence
                continue
            if in_fence:
                continue
            masked = BACKTICK.sub(lambda m: ' ' * len(m.group(0)), ln)
            for m in EMAIL_RE.finditer(masked):
                if any(tld in m.group(0) for tld in EXAMPLE_TLDS):
                    continue
                privacy['findings'].append({
                    'path': rel, 'line_number': ln_no,
                    'pattern_type': 'email', 'matched_text': m.group(0),
                    'risk_level': 'medium',
                    'suggestion': 'Review whether this email should appear in a cloud_safe page',
                })
            for m in PHONE_RE.finditer(masked):
                privacy['findings'].append({
                    'path': rel, 'line_number': ln_no,
                    'pattern_type': 'phone', 'matched_text': m.group(0),
                    'risk_level': 'medium',
                    'suggestion': 'Review whether this phone number should appear in a cloud_safe page',
                })
            for m in SSN_RE.finditer(masked):
                privacy['findings'].append({
                    'path': rel, 'line_number': ln_no,
                    'pattern_type': 'ssn', 'matched_text': '[redacted-SSN]',
                    'risk_level': 'high',
                    'suggestion': 'SSN-like pattern detected; verify this is not real PII',
                })

    privacy_path = os.path.join(BF_DIR, 'privacy-findings.yaml')
    with open(privacy_path, 'w', encoding='utf-8') as fh:
        write_metadata_header(fh, '04-privacy-review.sh')
        pyyaml.safe_dump(privacy, fh, sort_keys=False, default_flow_style=False, allow_unicode=True)


    # --- Extend REPORT.md with Phase 11 advisory sections --------------------
    # WR-03 fix: iterative `suggest` re-runs must not duplicate the Phase 11
    # advisory sections. Before appending, truncate any existing content from
    # the first Phase-11 marker (`## Cross-link candidates`) onward so the
    # bootstrap-produced prefix is preserved and the Phase-11 sections are
    # rewritten fresh on every run.
    report_path = os.path.join(BF_DIR, 'REPORT.md')
    if os.path.exists(report_path):
        with open(report_path, 'r', encoding='utf-8') as fh:
            existing = fh.read()
        cutoff = existing.find('\n## Cross-link candidates\n')
        if cutoff >= 0:
            existing = existing[:cutoff]
        with open(report_path, 'w', encoding='utf-8') as fh:
            fh.write(existing)
    with open(report_path, 'a', encoding='utf-8') as fh:
        fh.write('\n## Cross-link candidates\n\n')
        if cross_links['candidates']:
            for c in cross_links['candidates']:
                mark = ' (already linked)' if c['target_already_linked_from_source'] else ''
                fh.write(
                    f"- `{c['source_page']}`:{c['line_number']} -> "
                    f"`{c['proposed_target']}` ({c['match_type']}){mark}\n"
                )
        else:
            fh.write('_No cross-link candidates found._\n')
        fh.write('\n## Privacy review\n\n')
        if privacy['findings']:
            for f in privacy['findings']:
                fh.write(f"- `{f['path']}`:{f['line_number']} — {f['pattern_type']} ({f['risk_level']})\n")
        else:
            fh.write('_No privacy-sensitive patterns detected._\n')


    # --- Summary line(s) -----------------------------------------------------
    sys.stderr.write(f'suggest: byte-copied 4 migration scripts to {BF_MIG_DIR}/\n')
    n_pending = sum(1 for c in decisions['clusters'] if c['decision'] == 'pending')
    n_approve = sum(1 for c in decisions['clusters'] if c['decision'] == 'approve')
    sys.stderr.write(
        f'suggest: wrote {len(clusters)} typing clusters '
        f'({n_pending} pending / {n_approve} auto-approved)\n'
    )
    sys.stderr.write(
        f"suggest: wrote {len(prov_report['pages'])} provenance-bootstrap eligible previews\n"
    )
    sys.stderr.write(
        f"suggest: wrote {len(cross_links['candidates'])} cross-link candidates\n"
    )
    sys.stderr.write(
        f"suggest: wrote {len(privacy['findings'])} privacy findings\n"
    )
    if not bootstrapped_paths:
        sys.stderr.write(
            'suggest: WARN no bootstrapped pages found '
            '— run `bin/brownfield.sh bootstrap --apply` first for best results\n'
        )


# review-typing python3 heredoc — lines 1395-1669, verbatim except import
# mapping. Reads real stdin (bash used process substitution for the same reason).
def _cmd_review_typing():
    import io
    import os
    import sys

    from ruamel.yaml import YAML  # noqa: E402
    from compendium.common.yaml_rt import VALID_ENUMS  # noqa: E402  (REVIEWS item 11 — enum source)

    yaml = YAML(typ='rt')
    yaml.preserve_quotes = True
    yaml.indent(mapping=2, sequence=4, offset=2)

    decisions_path = os.environ['BF_DECISIONS_FILE']
    candidates_path = os.environ['BF_CANDIDATES_FILE']

    # --- Colors (REVIEWS item 14 — Phase 8 D-20 NO_COLOR convention) ---------
    _NO_COLOR = os.environ.get('NO_COLOR', '') != '' or not sys.stderr.isatty()
    CLR_DIM   = '' if _NO_COLOR else '\033[2m'
    CLR_BOLD  = '' if _NO_COLOR else '\033[1m'
    CLR_RESET = '' if _NO_COLOR else '\033[0m'

    # --- EOF-safe prompt (REVIEWS item 4 — CRITICAL for CI/non-interactive) ---
    _EOF_SENTINEL = object()
    _MAX_REPROMPTS_PER_CLUSTER = 5

    # Pre-peek buffer: read stdin up front when it's non-TTY so we can distinguish
    # "scripted input" (small-batch) from "immediate EOF / nothing piped"
    # (large-batch AI handoff). Per RESEARCH Pitfall 8: scripted-stdin-with-data
    # always flows through small-batch regardless of stdout TTY state.
    _stdin_is_tty = sys.stdin.isatty()
    _prebuffered_lines = []
    _prebuffered_exhausted = False
    if not _stdin_is_tty:
        try:
            _raw_stdin = sys.stdin.read()
        except Exception:
            _raw_stdin = ''
        if _raw_stdin:
            # Preserve trailing blank lines; split and keep empty trailing elements
            # up to but not including a single trailing empty after split.
            _prebuffered_lines = _raw_stdin.splitlines(True)
        _prebuffered_exhausted = not _prebuffered_lines


    def prompt(msg):
        """Return user input (stripped) or _EOF_SENTINEL on stdin EOF.

        REVIEWS item 4 contract: distinguish zero-byte read (EOF) from '\\n'
        (Enter with no input). EOF ends the session cleanly; Enter-with-no-input
        is re-prompted (bounded by _MAX_REPROMPTS_PER_CLUSTER).

        When stdin was non-TTY and pre-buffered at startup, prompts consume from
        the buffer. Once the buffer empties, further reads return _EOF_SENTINEL.
        TTY stdin reads directly via sys.stdin.readline().
        """
        global _prebuffered_exhausted
        sys.stderr.write(msg)
        sys.stderr.flush()
        if _stdin_is_tty:
            raw = sys.stdin.readline()
            if raw == '':
                return _EOF_SENTINEL
            return raw.strip()
        # Non-TTY: consume the pre-buffered lines we captured at startup.
        if _prebuffered_lines:
            raw = _prebuffered_lines.pop(0)
            return raw.strip()
        _prebuffered_exhausted = True
        return _EOF_SENTINEL


    # --- Load (skip D-09 metadata-comment header so ruamel sees the YAML block) ---
    def load_with_header(path):
        with open(path, encoding='utf-8') as fh:
            content = fh.read()
        lines = content.splitlines(keepends=True)
        header = []
        body_start = 0
        seen_first = False
        for i, ln in enumerate(lines):
            if ln.strip() == '# ---':
                header.append(ln)
                if seen_first:
                    body_start = i + 1
                    break
                seen_first = True
            elif seen_first:
                header.append(ln)
            elif not seen_first:
                # pre-header line (should not happen; defensive)
                header.append(ln)
        body = ''.join(lines[body_start:])
        data = yaml.load(body) if body.strip() else None
        return data, ''.join(header)


    decisions, dec_header = load_with_header(decisions_path)
    candidates, _cand_header = load_with_header(candidates_path)

    if decisions is None:
        sys.stderr.write(f"review-typing: no data in {decisions_path}; nothing to do.\n")
        sys.exit(0)

    cand_by_id = {c['cluster_id']: c for c in (candidates.get('clusters', []) if candidates else [])}

    pending = [c for c in decisions.get('clusters', []) if c.get('decision') == 'pending']

    if not pending:
        sys.stderr.write("review-typing: all clusters resolved; nothing to do.\n")
        sys.exit(0)

    n_thresh = int(os.environ.get('BF_N_THRESHOLD', '20'))
    tty_stdout = os.environ.get('BF_TTY_STDOUT') == '1'

    # Branch selection per D-04 + RESEARCH Pitfall 8:
    #   - pending >= threshold                                  -> large-batch
    #   - stdin is TTY (interactive)        AND pending < N     -> small-batch
    #   - stdin is non-TTY BUT has data     AND pending < N     -> small-batch (scripted)
    #   - stdin is non-TTY AND immediately EOF (no scripted input) -> large-batch (CI-safe)
    # The pre-peek buffer above distinguishes "scripted input" from "immediate EOF".
    _has_scripted_stdin = (not _stdin_is_tty) and bool(_prebuffered_lines)
    _has_usable_stdin = _stdin_is_tty or _has_scripted_stdin
    force_large_batch = (len(pending) >= n_thresh) or (not _has_usable_stdin)

    # REVIEWS item 11 — label enum source (exclude empty string — that is a D-14
    # scaffolding sentinel, not a valid RESOLVED override label).
    VALID_TYPE_ENUM = {t for t in VALID_ENUMS.get('type', set()) if t}
    if not VALID_TYPE_ENUM:
        VALID_TYPE_ENUM = {'entity', 'concept', 'source', 'comparison', 'overview', 'decision'}


    def writeback(reason_msg):
        buf = io.StringIO()
        yaml.dump(decisions, buf)
        with open(decisions_path, 'w', encoding='utf-8') as fh:
            fh.write(dec_header)
            fh.write(buf.getvalue())
        sys.stderr.write(f"\nreview-typing: {reason_msg} {decisions_path}\n")


    if force_large_batch:
        prompt_path = os.path.join(os.environ['BROWNFIELD_ROOT'], '.brownfield', 'review-typing-prompt.md')
        with open(prompt_path, 'w', encoding='utf-8') as fh:
            fh.write("# Review typing — AI-guided batch session\n\n")
            fh.write(f"**Pending clusters:** {len(pending)} (threshold: {n_thresh})\n\n")
            fh.write("Open these two files:\n\n")
            fh.write("- `.brownfield/page-typing-candidates.yaml` — read-only reference: each cluster's signals, proposed label, member pages.\n")
            fh.write("- `.brownfield/page-typing-decisions.yaml` — edit target: each cluster has `decision: pending`. Change to `approve` / `reject`; add `resolved_label` on approve; optionally add per-page overrides under a cluster's `overrides:` key.\n\n")
            fh.write("## Your job\n\n")
            fh.write("For each pending cluster:\n\n")
            fh.write("1. Read the signals and sample pages.\n")
            fh.write("2. Consider: does the proposed label fit the semantic role of these pages? Would splitting the cluster into sub-groups make sense? Are there outlier pages that need per-page overrides?\n")
            fh.write("3. **Edit ONLY the decisions manifest. Do not modify vault pages.** Do NOT modify `page-typing-candidates.yaml`.\n")
            fh.write("4. When all clusters are resolved, inform the user that they can now run:\n\n")
            fh.write("   ```\n")
            fh.write("   bash .brownfield/migrations/01-page-typing.sh --apply\n")
            fh.write("   ```\n\n")
            fh.write("## Constraints\n\n")
            fh.write("- Legal labels for `resolved_label`: `entity`, `concept`, `source`, `comparison`, `overview`, `decision`.\n")
            fh.write("- Per-page overrides go under a cluster's `overrides:` key; each entry has `path:` and `label:`.\n")
            fh.write("- Do not merge or split clusters by editing cluster membership — if a cluster needs splitting, mark it `reject` and the user re-runs `suggest` after manually splitting the vault.\n\n")
            fh.write("## Decision boundary\n\n")
            fh.write("*Review may be interactive and AI-guided; apply must always be deterministic.*\n\n")
            fh.write("This prompt lives outside the `bin/brownfield.sh` CLI by design: the CLI never calls an LLM. You — the AI assistant reading this file — operate on the manifest from outside the CLI. The user then runs a deterministic apply script.\n")
        sys.stderr.write(f"review-typing: {len(pending)} pending clusters >= threshold {n_thresh} OR non-TTY environment.\n")
        sys.stderr.write(f"Wrote {prompt_path}. Open this file in your AI session to review.\n")
        sys.stderr.write("When done, run: bash .brownfield/migrations/01-page-typing.sh --apply\n")
        sys.exit(0)

    # ===== Small-batch TTY mode =====
    sys.stderr.write(f"review-typing: {len(pending)} pending clusters; TTY mode.\n\n")
    _eof_abort = False

    for cluster_dec in pending:
        if _eof_abort:
            break
        cid = cluster_dec['cluster_id']
        cand = cand_by_id.get(cid)
        if cand is None:
            sys.stderr.write(f"WARN: cluster {cid} missing from candidates; leaving pending.\n")
            continue

        sys.stderr.write(f"\n{CLR_BOLD}=== {cid} ({cand.get('page_count', '?')} pages, confidence={cand.get('confidence', '?')}) ==={CLR_RESET}\n")
        sys.stderr.write(f"Proposed label: {cand.get('proposed_label', '?')}\n")
        signals_obj = cand.get('signals', {})
        try:
            signals_dict = dict(signals_obj)
        except Exception:
            signals_dict = signals_obj
        sys.stderr.write(f"{CLR_DIM}Signals:{CLR_RESET} {signals_dict}\n")
        pages_list = list(cand.get('pages', []))
        sys.stderr.write(f"{CLR_DIM}Sample pages (first 5):{CLR_RESET}\n")
        for p in pages_list[:5]:
            sys.stderr.write(f"  - {p}\n")
        if len(pages_list) > 5:
            sys.stderr.write(f"  ... and {len(pages_list) - 5} more\n")

        reprompts = 0
        while True:
            choice = prompt("\n[a]pprove all / [r]eject all / [i]nspect / [o]verride / [s]kip: ")
            if choice is _EOF_SENTINEL:
                # REVIEWS item 4: true EOF → clean abort (partial progress preserved by writeback below)
                sys.stderr.write(
                    "\nreview-typing: stdin EOF detected; aborting session cleanly. "
                    "Remaining clusters stay pending. Progress saved.\n"
                )
                _eof_abort = True
                break

            c = (choice or '').strip().lower()[:1]
            if c == 'a':
                cluster_dec['decision'] = 'approve'
                cluster_dec['resolved_label'] = cand.get('proposed_label')
                sys.stderr.write(f"-> approved (all {cand.get('page_count', '?')} pages -> {cand.get('proposed_label')})\n")
                break
            elif c == 'r':
                cluster_dec['decision'] = 'reject'
                cluster_dec['resolved_label'] = None
                sys.stderr.write("-> rejected\n")
                break
            elif c == 'i':
                sys.stderr.write("Pages in this cluster:\n")
                for p in pages_list:
                    sys.stderr.write(f"  - {p}\n")
                reprompts = 0
                continue
            elif c == 'o':
                sys.stderr.write("Enter comma-separated page paths to override, then label.\n")
                sys.stderr.write("  example: wiki-cloud/concepts/foo.md, wiki-cloud/concepts/bar.md\n")
                paths_raw = prompt("paths: ")
                if paths_raw is _EOF_SENTINEL:
                    _eof_abort = True
                    break
                label = prompt("label (entity/concept/source/comparison/overview/decision): ")
                if label is _EOF_SENTINEL:
                    _eof_abort = True
                    break
                label = label.strip()
                paths = [p.strip() for p in paths_raw.split(',') if p.strip()]
                if not paths or not label:
                    sys.stderr.write("override cancelled (empty input)\n")
                    reprompts = 0
                    continue
                # REVIEWS item 11: validate label against VALID_TYPE_ENUM BEFORE writing.
                if label not in VALID_TYPE_ENUM:
                    sys.stderr.write(
                        f"review-typing: invalid label: {label!r}; must be one of "
                        f"{sorted(VALID_TYPE_ENUM)}. Override discarded.\n"
                    )
                    reprompts = 0
                    continue
                if cluster_dec.get('overrides') is None:
                    cluster_dec['overrides'] = []
                for p in paths:
                    cluster_dec['overrides'].append({'path': p, 'label': label})
                sys.stderr.write(f"-> added {len(paths)} override(s); cluster still in prompt — choose a/r/s.\n")
                reprompts = 0
                continue
            elif c == 's':
                sys.stderr.write("-> skipped (cluster remains pending)\n")
                break
            else:
                reprompts += 1
                if reprompts >= _MAX_REPROMPTS_PER_CLUSTER:
                    sys.stderr.write(
                        f"review-typing: {_MAX_REPROMPTS_PER_CLUSTER} consecutive invalid inputs; "
                        f"skipping cluster {cid}.\n"
                    )
                    break
                sys.stderr.write("Unrecognized choice. Try a/r/i/o/s.\n")
                continue

    # Always write back (preserves partial progress even on EOF abort per REVIEWS item 4).
    writeback("wrote")


# verify python3 heredoc — lines 1743-1992, verbatim except import mapping.
def _cmd_verify():
    import hashlib
    import json
    import os
    import pathlib
    import re
    import subprocess
    import sys

    from compendium.common.yaml_rt import VALID_ENUMS, read_fm_body, write_roundtrip  # noqa: E402
    from ruamel.yaml import YAML  # noqa: E402

    yaml = YAML(typ='rt')

    ROOT = os.environ['BROWNFIELD_ROOT']
    LINT_SH = os.environ['BROWNFIELD_LINT_SH']
    PROMOTE = os.environ.get('BF_PROMOTE') == '1'

    # ===== REVIEWS item 9: stale candidate artifact detection =====
    # For each candidate YAML mapped to its canonical script, compare the
    # source_script_hash recorded in the D-09 metadata header against the current
    # body-post-op_hash-strip sha256 of the byte-copy under .brownfield/migrations/.
    # (suggest records the CANONICAL script's sha256 as source_script_hash; the
    # byte-copy has an op_hash header prepended, so stripping it yields the
    # canonical body, whose sha256 should match the recorded value.)
    CANDIDATE_TO_SCRIPT = {
        'page-typing-candidates.yaml':       '01-page-typing.sh',
        'page-typing-decisions.yaml':        '01-page-typing.sh',
        'provenance-bootstrap-report.yaml':  '02-provenance-bootstrap.sh',
        'cross-link-candidates.yaml':        '03-cross-link-inference.sh',
        'privacy-findings.yaml':             '04-privacy-review.sh',
    }
    HEADER_HASH_RE = re.compile(r'^# source_script_hash:\s*(sha256:[0-9a-f]+)\s*$', re.MULTILINE)


    def _body_post_op_hash_strip_sha256(path):
        body = pathlib.Path(path).read_bytes()
        lines = body.split(b'\n')
        stripped = [
            ln for ln in lines
            if not ln.startswith(b'# op_hash:')
            and not ln.startswith(b'# op_hash_scope:')
        ]
        return 'sha256:' + hashlib.sha256(b'\n'.join(stripped)).hexdigest()


    stale_count = 0
    for cand_name, script_name in CANDIDATE_TO_SCRIPT.items():
        cand_path = os.path.join(ROOT, '.brownfield', cand_name)
        script_path = os.path.join(ROOT, '.brownfield', 'migrations', script_name)
        if not (os.path.isfile(cand_path) and os.path.isfile(script_path)):
            continue
        head_text = ''
        with open(cand_path, 'r', encoding='utf-8') as fh:
            for _ in range(10):
                ln = fh.readline()
                if not ln:
                    break
                head_text += ln
        m = HEADER_HASH_RE.search(head_text)
        if not m:
            continue
        recorded = m.group(1)
        current = _body_post_op_hash_strip_sha256(script_path)
        if recorded != current:
            stale_count += 1
            sys.stderr.write(
                f"verify: stale candidate artifact detected: {cand_name} "
                f"(source_script_hash in header {recorded} != current body-post-op_hash-strip "
                f"{current} for migrations/{script_name}); "
                f"re-run `bin/brownfield.sh suggest` to refresh.\n"
            )

    # ===== Lint wrapper (D-13) =====
    # Point WIKI_ROOT at <vault-root>/wiki-cloud/ if it exists; otherwise at the vault
    # root itself (so fixtures/vaults that look like wiki directories still lint).
    wiki_dir = os.path.join(ROOT, 'wiki')
    if not os.path.isdir(wiki_dir):
        wiki_dir = ROOT

    env = os.environ.copy()
    env['WIKI_ROOT'] = wiki_dir

    lint_argv = [
        'bash', LINT_SH,
        '--ci', '--format', 'json',
        '--category', 'yaml,provenance,orphan,crossref,brownfield',
    ]

    print("verify: running bin/lint.sh --ci --format json --category yaml,provenance,orphan,crossref,brownfield")

    result = subprocess.run(lint_argv, capture_output=True, text=True, env=env)

    try:
        findings = json.loads(result.stdout) if result.stdout.strip() else []
    except json.JSONDecodeError:
        sys.stderr.write("verify: WARNING — could not parse lint JSON output; stderr follows\n")
        sys.stderr.write(result.stderr)
        findings = []

    errors_by_path = {}
    warnings_by_path = {}
    for f in findings:
        p = f.get('path', '') or ''
        if not p:
            continue
        try:
            if os.path.isabs(p):
                rel = os.path.relpath(p, ROOT)
            else:
                rel = os.path.relpath(os.path.join(ROOT, p), ROOT) if not p.startswith(ROOT) else os.path.relpath(p, ROOT)
        except ValueError:
            rel = p
        sev = f.get('severity', '')
        if sev == 'error':
            errors_by_path.setdefault(rel, []).append(f)
        elif sev == 'warning':
            warnings_by_path.setdefault(rel, []).append(f)

    n_err = sum(len(v) for v in errors_by_path.values())
    n_warn = sum(len(v) for v in warnings_by_path.values())
    print(f"verify: lint findings: {n_err} error(s), {n_warn} warning(s); {stale_count} stale candidate artifact(s)")
    sys.stderr.write(
        f"verify: lint findings: {n_err} error(s), {n_warn} warning(s); {stale_count} stale candidate artifact(s)\n"
    )

    if not PROMOTE:
        if n_err:
            sys.stderr.write(f"verify: {len(errors_by_path)} page(s) have blocking findings:\n")
            for path in sorted(errors_by_path.keys())[:20]:
                sys.stderr.write(f"  - {path} ({len(errors_by_path[path])} error(s))\n")
        sys.exit(0)

    # ===== --promote: 5-gate pass-list per page =====
    # Gate 5 source: any page inside a `decision: pending` cluster of
    # page-typing-decisions.yaml is blocked from promotion.
    pending_pages = set()
    decisions_path = os.path.join(ROOT, '.brownfield', 'page-typing-decisions.yaml')
    if os.path.isfile(decisions_path):
        with open(decisions_path, encoding='utf-8') as fh:
            content = fh.read()
        lines = content.splitlines(keepends=True)
        seen_first = False
        body_start = 0
        for i, ln in enumerate(lines):
            if ln.strip() == '# ---':
                if seen_first:
                    body_start = i + 1
                    break
                seen_first = True
        try:
            dec = yaml.load(''.join(lines[body_start:]))
        except Exception:
            dec = None

        cand_path_pt = os.path.join(ROOT, '.brownfield', 'page-typing-candidates.yaml')
        cand_by_id_pt = {}
        if os.path.isfile(cand_path_pt):
            with open(cand_path_pt, encoding='utf-8') as fh:
                cand_content = fh.read()
            cand_lines = cand_content.splitlines(keepends=True)
            sf = False
            bs = 0
            for i, ln in enumerate(cand_lines):
                if ln.strip() == '# ---':
                    if sf:
                        bs = i + 1
                        break
                    sf = True
            try:
                cand_data = yaml.load(''.join(cand_lines[bs:]))
            except Exception:
                cand_data = None
            if cand_data:
                for c in cand_data.get('clusters', []):
                    cand_by_id_pt[c['cluster_id']] = list(c.get('pages', []))

        if dec:
            for cluster_dec in dec.get('clusters', []):
                if cluster_dec.get('decision') == 'pending':
                    for p in cand_by_id_pt.get(cluster_dec.get('cluster_id', ''), []):
                        pending_pages.add(p)

    valid_types = {t for t in VALID_ENUMS.get('type', set()) if t}
    if not valid_types:
        valid_types = {'entity', 'concept', 'source', 'comparison', 'overview', 'decision'}

    EXCLUDE_DIR_NAMES = {'.brownfield', '.git', '.obsidian', '.trash', 'node_modules'}
    promoted = []
    blocked = []

    for dirpath, dirnames, filenames in os.walk(ROOT, followlinks=False):
        dirnames[:] = [d for d in dirnames if d not in EXCLUDE_DIR_NAMES]
        for fn in filenames:
            if not fn.endswith('.md'):
                continue
            full = os.path.join(dirpath, fn)
            rel = os.path.relpath(full, ROOT)
            try:
                fm, body, raw = read_fm_body(full)
            except Exception:
                continue
            if fm is None:
                continue

            # Gate 1: currently bootstrapped
            if fm.get('bootstrap_stage') != 'bootstrapped':
                continue

            # Gate 2: type: is a valid enum
            t = fm.get('type')
            if not t or t not in valid_types:
                blocked.append((rel, f'type not valid enum: {t!r}'))
                continue

            # Gate 3: zero error-severity lint findings for this page
            if rel in errors_by_path:
                blocked.append((rel, f'{len(errors_by_path[rel])} lint error(s)'))
                continue

            # Gate 4: type-specific required fields present
            if t == 'source':
                required = ('path', 'content_hash', 'ingested_at', 'source_type')
                missing = [k for k in required if k not in fm or fm.get(k) in (None, '')]
                if missing:
                    blocked.append((rel, f'source missing required fields: {missing}'))
                    continue

            # Gate 5: no pending review decision
            if rel in pending_pages:
                blocked.append((rel, 'page has pending review decision'))
                continue

            # All 5 gates passed → flip bootstrap_stage to verified
            fm['bootstrap_stage'] = 'verified'
            try:
                write_roundtrip(full, fm, body, raw)
                promoted.append(rel)
            except Exception as e:
                blocked.append((rel, f'write_roundtrip failed: {e}'))

    print(f"verify --promote: {len(promoted)} page(s) promoted to verified; {len(blocked)} page(s) blocked")
    sys.stderr.write(
        f"verify --promote: {len(promoted)} page(s) promoted to verified; {len(blocked)} page(s) blocked\n"
    )
    for rel in promoted[:10]:
        sys.stderr.write(f"  [promoted] {rel}\n")
    for rel, reason in blocked[:10]:
        sys.stderr.write(f"  [blocked]  {rel} — {reason}\n")


# scan python3 heredoc — lines 2050-2258, verbatim except import mapping.
def _cmd_scan():
    import os
    import re
    import sys
    import fnmatch
    from datetime import datetime, timezone
    from pathlib import Path

    # PyYAML only in scan.  The preserving-roundtrip YAML writer arrives with
    # Plan 10-03 bootstrap; scan never writes YAML back to vault files.
    import yaml

    from compendium.common.classify import classify_page, unknown_reason  # noqa: E402
    # REVIEWS item 3: .brownfield-ignore parsing + walk semantics are SHARED
    # with the suggest subcommand via bin/lib/brownfield_walk.py so scan and
    # suggest cannot drift on exclusion behavior.
    from compendium.common.walk import (  # noqa: E402
        load_brownfield_ignore,
        any_match as _any_match,
    )

    ROOT = os.environ['BROWNFIELD_ROOT']
    LIST_EXCLUDED = os.environ['BROWNFIELD_LIST_EXCLUDED'] == '1'
    DEFAULT_EXCLUDE_DIRS = set(
        p for p in os.environ['BROWNFIELD_DEFAULT_EXCLUDES_JOINED'].split(':') if p
    )

    # Daily-note filename patterns (D-19).  Matched against basenames for files
    # at root, under daily/, or under journal/.
    DAILY_NOTE_RE = re.compile(r'^\d{4}-\d{2}-\d{2}\.md$')


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


def main(argv=None):
    if argv is None:
        argv = sys.argv[1:]
    args = list(argv)

    # --- Subcommand dispatch (bin/brownfield.sh lines 58-76) ------------------
    if len(args) == 0:
        sys.stderr.write(_USAGE)
        return 1
    subcommand = args[0]
    if subcommand in ("--help", "-h"):
        sys.stdout.write(_USAGE)
        return 0
    args = args[1:]
    if subcommand not in _VALID_SUBCOMMANDS:
        sys.stderr.write(f"ERROR: unknown subcommand: {subcommand}\n")
        sys.stderr.write(_USAGE)
        return 1

    # --- bootstrap subcommand (bash glue lines 79-154) -------------------------
    if subcommand == "bootstrap":
        apply_flag = 0
        verbose = 0
        bs_root = "."
        i = 0
        while i < len(args):
            a = args[i]
            if a == "--apply":
                apply_flag = 1
                i += 1
            elif a == "--dry-run":
                apply_flag = 0
                i += 1
            elif a == "--verbose":
                verbose = 1
                i += 1
            elif a == "--root":
                if len(args) - i < 2:
                    sys.stderr.write("ERROR: --root requires a path\n")
                    return 1
                bs_root = args[i + 1]
                i += 2
            elif a in ("-h", "--help"):
                sys.stdout.write(_USAGE)
                return 0
            elif a.startswith("-"):
                sys.stderr.write(f"ERROR: unknown bootstrap option: {a}\n")
                sys.stderr.write(_USAGE)
                return 1
            else:
                sys.stderr.write(f"ERROR: unexpected bootstrap argument: {a}\n")
                sys.stderr.write(_USAGE)
                return 1

        if not os.path.isdir(bs_root):
            sys.stderr.write(f"ERROR: --root path does not exist or is not a directory: {bs_root}\n")
            return 1

        # Honor BROWNFIELD_FIXTURE_TODAY for pinned-date fixture tests; otherwise
        # compute today's UTC date (bash: `date -u '+%Y-%m-%d'`).
        fixture_today = os.environ.get("BROWNFIELD_FIXTURE_TODAY", "")
        if fixture_today:
            brownfield_today = fixture_today
        else:
            brownfield_today = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d")

        # Detect the repo root for source-summary path resolution (D-15 Codex fix #7).
        # bash probe loop: walk up from BS_ROOT until a .git entry is found.
        brownfield_repo_root = bs_root
        probe = bs_root
        while probe != "/" and probe:
            if os.path.exists(os.path.join(probe, ".git")):
                brownfield_repo_root = probe
                break
            probe = os.path.abspath(os.path.join(probe, ".."))

        os.environ["BROWNFIELD_APPLY"] = str(apply_flag)
        os.environ["BROWNFIELD_VERBOSE"] = str(verbose)
        os.environ["BROWNFIELD_ROOT"] = bs_root
        os.environ["BROWNFIELD_REPO_ROOT"] = brownfield_repo_root
        os.environ["BROWNFIELD_LIB_DIR"] = _lib_dir()
        os.environ["BROWNFIELD_TODAY"] = brownfield_today
        os.environ["BROWNFIELD_DEFAULT_EXCLUDES_JOINED"] = _BF_DE

        _cmd_bootstrap()
        return 0  # bash safety net after PYEOF (line 650)

    # --- suggest subcommand (bash glue lines 674-743) ---------------------------
    if subcommand == "suggest":
        sg_root = "."
        i = 0
        while i < len(args):
            a = args[i]
            if a == "--root":
                if len(args) - i < 2:
                    sys.stderr.write("ERROR: --root requires a path\n")
                    return 1
                sg_root = args[i + 1]
                i += 2
            elif a in ("--help", "-h"):
                sys.stdout.write(_SUGGEST_HELP)
                return 0
            else:
                sys.stderr.write(f"ERROR: unknown suggest argument: {a}\n")
                return 1

        if not os.path.isdir(sg_root):
            sys.stderr.write(f"ERROR: --root path does not exist or is not a directory: {sg_root}\n")
            return 1
        sg_root_abs = os.path.abspath(sg_root)

        # Resolve repo root — same upward-walk pattern as bootstrap.  We need
        # schema/brownfield/migrations/ to live under the repo root.
        sg_repo_root = _repo_root()

        if not os.path.isdir(os.path.join(sg_repo_root, "schema", "brownfield", "migrations")):
            sys.stderr.write(f"ERROR: schema/brownfield/migrations/ not found under {sg_repo_root}\n")
            return 1

        os.environ["BROWNFIELD_ROOT"] = sg_root_abs
        os.environ["BROWNFIELD_LIB_DIR"] = os.path.join(sg_repo_root, "bin", "lib")
        os.environ["BROWNFIELD_SCHEMA_MIG_DIR"] = os.path.join(sg_repo_root, "schema", "brownfield", "migrations")
        # bash: `export BROWNFIELD_TOOL_VERSION="${BROWNFIELD_TOOL_VERSION:-1.1.0}"`
        os.environ["BROWNFIELD_TOOL_VERSION"] = os.environ.get("BROWNFIELD_TOOL_VERSION") or "1.1.0"
        # bash: `export BROWNFIELD_FIXTURE_TODAY="${BROWNFIELD_FIXTURE_TODAY:-}"`
        os.environ["BROWNFIELD_FIXTURE_TODAY"] = os.environ.get("BROWNFIELD_FIXTURE_TODAY", "")

        _cmd_suggest()
        return 0  # bash `exit 0` after PYEOF (line 1292)

    # --- review-typing subcommand (bash glue lines 1302-1393) -------------------
    if subcommand == "review-typing":
        rt_root = "."
        rt_threshold = "20"  # CONTEXT planner default; RESEARCH Q3 recommends 20
        i = 0
        while i < len(args):
            a = args[i]
            if a == "--root":
                if len(args) - i < 2:
                    sys.stderr.write("ERROR: --root requires a path\n")
                    return 1
                rt_root = args[i + 1]
                i += 2
            elif a == "--threshold":
                if len(args) - i < 2:
                    sys.stderr.write("ERROR: --threshold requires a value\n")
                    return 1
                rt_threshold = args[i + 1]
                i += 2
            elif a in ("--help", "-h"):
                sys.stdout.write(_REVIEW_TYPING_HELP)
                return 0
            else:
                sys.stderr.write(f"ERROR: unknown review-typing argument: {a}\n")
                return 1

        if not os.path.isdir(rt_root):
            sys.stderr.write(f"ERROR: --root path does not exist or is not a directory: {rt_root}\n")
            return 1
        rt_root_abs = os.path.abspath(rt_root)

        rt_decisions_file = os.path.join(rt_root_abs, ".brownfield", "page-typing-decisions.yaml")
        rt_candidates_file = os.path.join(rt_root_abs, ".brownfield", "page-typing-candidates.yaml")

        if not os.path.isfile(rt_decisions_file):
            sys.stderr.write(f"ERROR: {rt_decisions_file} not found. Run `bin/brownfield.sh suggest` first.\n")
            return 1

        os.environ["BROWNFIELD_ROOT"] = rt_root_abs
        os.environ["BROWNFIELD_LIB_DIR"] = _lib_dir()
        os.environ["BF_DECISIONS_FILE"] = rt_decisions_file
        os.environ["BF_CANDIDATES_FILE"] = rt_candidates_file
        os.environ["BF_N_THRESHOLD"] = rt_threshold
        os.environ["BF_TTY_STDIN"] = "1" if _isatty(0) else "0"
        os.environ["BF_TTY_STDOUT"] = "1" if _isatty(1) else "0"

        # bash runs the heredoc via `python3 <(cat <<'PYEOF')` process
        # substitution so the script keeps real stdin for interactive prompts;
        # here the body simply reads sys.stdin normally.
        _cmd_review_typing()
        return 0  # bash `exit 0` after PYEOF (line 1673)

    # --- verify subcommand (bash glue lines 1681-1740) ---------------------------
    if subcommand == "verify":
        vf_root = "."
        vf_promote = 0
        i = 0
        while i < len(args):
            a = args[i]
            if a == "--root":
                if len(args) - i < 2:
                    sys.stderr.write("ERROR: --root requires a path\n")
                    return 1
                vf_root = args[i + 1]
                i += 2
            elif a == "--promote":
                vf_promote = 1
                i += 1
            elif a in ("--help", "-h"):
                sys.stdout.write(_VERIFY_HELP)
                return 0
            else:
                sys.stderr.write(f"ERROR: unknown verify argument: {a}\n")
                return 1

        if not os.path.isdir(vf_root):
            sys.stderr.write(f"ERROR: --root path does not exist or is not a directory: {vf_root}\n")
            return 1
        vf_root_abs = os.path.abspath(vf_root)
        vf_repo_root = _repo_root()

        os.environ["BROWNFIELD_ROOT"] = vf_root_abs
        os.environ["BROWNFIELD_LIB_DIR"] = os.path.join(vf_repo_root, "bin", "lib")
        os.environ["BROWNFIELD_LINT_SH"] = os.path.join(vf_repo_root, "bin", "lint.sh")
        os.environ["BF_PROMOTE"] = str(vf_promote)

        _cmd_verify()
        return 0  # bash `exit 0` after PYEOF (line 1995)

    # --- scan subcommand (bash fall-through, lines 1998-2047) --------------------
    list_excluded = 0
    root = "."
    i = 0
    while i < len(args):
        a = args[i]
        if a == "--list-excluded":
            list_excluded = 1
            i += 1
        elif a == "--root":
            if len(args) - i < 2:
                sys.stderr.write("ERROR: --root requires a path\n")
                return 1
            root = args[i + 1]
            i += 2
        elif a in ("--help", "-h"):
            sys.stdout.write(_USAGE)
            return 0
        elif a.startswith("-"):
            sys.stderr.write(f"ERROR: unknown scan option: {a}\n")
            sys.stderr.write(_USAGE)
            return 1
        else:
            sys.stderr.write(f"ERROR: unexpected scan argument: {a}\n")
            sys.stderr.write(_USAGE)
            return 1

    if not os.path.isdir(root):
        sys.stderr.write(f"ERROR: --root path does not exist or is not a directory: {root}\n")
        return 1

    os.environ["BROWNFIELD_DEFAULT_EXCLUDES_JOINED"] = _BF_DE
    os.environ["BROWNFIELD_ROOT"] = root
    os.environ["BROWNFIELD_LIST_EXCLUDED"] = str(list_excluded)
    os.environ["BROWNFIELD_LIB_DIR"] = _lib_dir()

    sys.stderr.write(f"Scanning {root} ...\n")

    _cmd_scan()
    return 0


if __name__ == "__main__":          # enables `python3 -m compendium.brownfield`
    sys.exit(main(sys.argv[1:]))
