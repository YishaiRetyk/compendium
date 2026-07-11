# src/compendium/ingest.py — byte-parity port of bin/ingest.sh (Phase 25 MIG-05).
#
# PARITY CONTRACT: every external command the bash script shells out to is invoked
# via subprocess with IDENTICAL argv (PATH shims — e.g. the frozen-`date` farm in
# tests/phase-24/test_mutating_footprint_characterization.sh — must keep
# intercepting them). The inline python3 heredoc (BRWN-10 strip) is lifted
# verbatim as _bf_strip_frontmatter_field. `set -euo pipefail` abort points are
# replicated explicitly; NOTE the bash does NOT set inherit_errexit, so failures
# INSIDE command substitutions (sanitize_slug, compute_hash internals,
# resolve_contributor) are non-fatal exactly where bash's were — only the
# substitution's own exit status propagates to the main-shell assignment.
import os
import re
import shutil
import subprocess
import sys

USAGE = """Usage: bin/ingest.sh <source-file> [--slug <slug>] [--asset <path>] [--force] [--contributor <handle>]

Scaffolds source ingestion by:
  1. Creating dated directory structure in sources/ (UTC date)
  2. Copying the source file into place
  3. Computing content_hash (SHA-256)
  4. Printing ready-to-ingest instructions for the LLM agent

Options:
  --slug <slug>           Custom slug for the source directory (default: derived from filename)
  --asset <path>          Co-locate a bundle asset (e.g. the original PDF,
                          <path>/original.pdf) alongside source.md in the same
                          dated bundle dir.
  --force                 Overwrite files in an existing destination directory
  --contributor <handle>  Explicit contributor @handle for the log entry.
                          Auto-detects from git config user.email +
                          .git-author-map.txt if omitted. Single-author
                          repos auto-omit the field.
  --help, -h              Show this help message

Notes:
  - Dates are UTC (date -u) so paths are deterministic across time zones.
  - Requires sha256sum or shasum -a 256.
  - If --slug is omitted and sanitization of the filename yields an empty
    slug, the script fails with a clear error.
"""


def _reconfigure_streams():
    for s in (sys.stdout, sys.stderr):
        try:
            s.reconfigure(encoding="utf-8", errors="surrogateescape")
        except Exception:
            pass


def _out(s):
    sys.stdout.write(s)
    sys.stdout.flush()


def _err(s):
    sys.stderr.write(s)
    sys.stderr.flush()


def _rc_of(p):
    # bash reports a signal-killed child as 128+N.
    return 128 - p.returncode if p.returncode < 0 else p.returncode


def _run(argv, cwd=None, stdout=None, stderr=None, stdin_bytes=None):
    """Plain command: stdout/stderr inherited unless redirected (bash default)."""
    sys.stdout.flush()
    sys.stderr.flush()
    p = subprocess.run(argv, input=stdin_bytes, cwd=cwd, stdout=stdout, stderr=stderr)
    return _rc_of(p)


def _capture(argv, stdin_bytes=None, cwd=None, stderr=None):
    """$(...) command substitution: stdout captured, stderr inherited unless redirected."""
    sys.stdout.flush()
    sys.stderr.flush()
    p = subprocess.run(argv, input=stdin_bytes, stdout=subprocess.PIPE, cwd=cwd, stderr=stderr)
    return p.stdout, _rc_of(p)


def _cs(out_bytes):
    """Command-substitution text: decode + strip trailing newlines (bash $())."""
    return out_bytes.decode("utf-8", "surrogateescape").rstrip("\n")


def _b(s):
    return s.encode("utf-8", "surrogateescape")


def _pipestatus(*rcs):
    """pipefail: status of the rightmost command that exited nonzero, else 0."""
    status = 0
    for rc in rcs:
        if rc != 0:
            status = rc
    return status


# ---------------------------------------------------------------------------
# Helpers (bash function ports — all ran inside $(...) => errexit OFF inside)
# ---------------------------------------------------------------------------

def sanitize_slug(raw):
    s, _ = _capture(["tr", "[:upper:]", "[:lower:]"], stdin_bytes=_b(raw))
    s, _ = _capture(["sed", "-E", r"s/\.[^.]+$//"], stdin_bytes=s)        # strip extension
    s, _ = _capture(["sed", "-E", "s/[^a-z0-9]+/-/g"], stdin_bytes=s)     # non-alnum -> hyphen
    s, _ = _capture(["sed", "-E", "s/-+/-/g"], stdin_bytes=s)             # collapse hyphens
    s, _ = _capture(["sed", "-E", "s/^-+|-+$//g"], stdin_bytes=s)         # trim hyphens
    return _cs(s)


def compute_hash(file):
    """Returns (hash_text, rc) — rc is the subshell's exit status ($() leg)."""
    if shutil.which("sha256sum"):
        out, rc1 = _capture(["sha256sum", file])
        out2, rc2 = _capture(["cut", "-d", " ", "-f1"], stdin_bytes=out)
        return _cs(out2), _pipestatus(rc1, rc2)
    elif shutil.which("shasum"):
        out, rc1 = _capture(["shasum", "-a", "256", file])
        out2, rc2 = _capture(["cut", "-d", " ", "-f1"], stdin_bytes=out)
        return _cs(out2), _pipestatus(rc1, rc2)
    else:
        _err("ERROR: No SHA-256 tool found. Install sha256sum or shasum.\n")
        return "", 1


def _trim_ws(s):
    """sed 's/^[[:space:]]*//; s/[[:space:]]*$//' — via the same sed binary."""
    out, _ = _capture(["sed", "s/^[[:space:]]*//; s/[[:space:]]*$//"], stdin_bytes=_b(s))
    return _cs(out)


def resolve_contributor(repo_root, explicit):
    """D-19..D-21 port. Runs where bash ran it inside $() — internal failures
    are non-fatal (no inherit_errexit); only stdout (the handle) is captured."""
    if explicit:
        return explicit
    # D-20 single-author detection: git log --all --format='%ae' 2>/dev/null | sort -u | wc -l | tr -d ' '
    o1, _ = _capture(["git", "log", "--all", "--format=%ae"], cwd=repo_root,
                     stderr=subprocess.DEVNULL)
    o2, _ = _capture(["sort", "-u"], stdin_bytes=o1)
    o3, _ = _capture(["wc", "-l"], stdin_bytes=o2)
    o4, _ = _capture(["tr", "-d", " "], stdin_bytes=o3)
    author_count = _cs(o4)
    try:
        count = int(author_count if author_count else "0")
    except ValueError:
        count = None
    if count is not None and count <= 1:
        # Single-author: omit
        return ""
    # Multi-author: look up email in map
    eo, _erc = _capture(["git", "config", "user.email"], cwd=repo_root,
                        stderr=subprocess.DEVNULL)
    email = _cs(eo)  # `|| true`: captured output kept, status ignored
    if not email:
        _err("WARN: no git config user.email; omitting contributor:: field\n")
        _err("      Set with: git config user.email <your-email>\n")
        _err("      Or use: bin/ingest.sh --contributor @your-handle ...\n")
        return ""
    elo, _ = _capture(["tr", "[:upper:]", "[:lower:]"], stdin_bytes=_b(email))
    email_lc = _cs(elo)
    map_path = os.path.join(repo_root, ".git-author-map.txt")
    if not os.path.isfile(map_path):
        _err(f"WARN: no .git-author-map.txt at repo root; cannot resolve {email} to @handle\n")
        _err("      Omitting contributor:: field.\n")
        _err(f"      Fix: add line '{email}  ->  @your-handle' to .git-author-map.txt\n")
        _err("      Or: re-run with --contributor @your-handle\n")
        return ""
    handle = ""
    with open(map_path, "rb") as f:
        content = f.read().decode("utf-8", "surrogateescape")
    lines = content.split("\n")
    if lines and lines[-1] == "":
        lines.pop()  # while read -r line || [ -n "$line" ] — trailing newline
    for line in lines:
        # Skip comments and blank lines (case ''|\#*)
        if line == "" or line.startswith("#"):
            continue
        # Accept separator "  ->  " or tab
        if "  ->  " in line:
            left = line.split("  ->  ")[0]      # ${line%%  ->  *}
            right = line.rsplit("  ->  ", 1)[1]  # ${line##*  ->  }
        elif "\t" in line:
            left = line.split("\t")[0]           # ${line%%$'\t'*}
            right = line.rsplit("\t", 1)[1]      # ${line##*$'\t'}
        else:
            continue
        llo, _ = _capture(["tr", "[:upper:]", "[:lower:]"], stdin_bytes=_b(left))
        left_lc = _trim_ws(_cs(llo))
        right_trimmed = _trim_ws(right)
        if left_lc == email_lc:
            handle = right_trimmed
            break
    if handle:
        return handle
    # D-21 Pitfall 5 guard: NEVER write bare email
    _err(f"WARN: no mapping for {email} in .git-author-map.txt; omitting contributor:: field\n")
    _err(f"      Fix: add line '{email}  ->  @your-handle' to .git-author-map.txt\n")
    _err("      Or: re-run with --contributor @your-handle\n")
    return ""


def _bf_strip_frontmatter_field(path, field):
    """Verbatim lift of bin/ingest.sh's PYSTRIP heredoc (BRWN-10).
    Returns the string the heredoc printed ('0' or the stripped count)."""
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    lines = content.splitlines(keepends=True)
    # Locate frontmatter block boundaries: first two lines that equal "---".
    in_fm = False
    fm_end = -1
    for i, ln in enumerate(lines):
        stripped = ln.rstrip('\r\n')
        if stripped == '---':
            if not in_fm:
                in_fm = True
            else:
                fm_end = i
                break
    if fm_end < 0:
        # No frontmatter or unterminated — do nothing, report no strip.
        return '0'
    pattern = re.compile(r'^' + re.escape(field) + r'\s*:')
    new_lines = []
    stripped_count = 0
    for i, ln in enumerate(lines):
        if i <= fm_end and pattern.match(ln):
            stripped_count += 1
            continue
        new_lines.append(ln)
    if stripped_count > 0:
        with open(path, 'w', encoding='utf-8') as f:
            f.writelines(new_lines)
    return str(stripped_count)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main(argv=None):
    args = list(sys.argv[1:] if argv is None else argv)
    _reconfigure_streams()

    if len(args) == 0:
        _out(USAGE)
        return 1

    source_file = ""
    slug_override = ""
    slug_provided = 0
    force = 0
    contributor = ""
    asset_file = ""

    while args:
        a = args[0]
        if a in ("--help", "-h"):
            _out(USAGE)
            return 0
        elif a == "--slug":
            if len(args) < 2:
                _err("ERROR: --slug requires a value\n")
                return 1
            slug_override = args[1]
            slug_provided = 1
            args = args[2:]
        elif a == "--asset":
            if len(args) < 2:
                _err("ERROR: --asset requires a value (path to the bundle asset, e.g. original.pdf)\n")
                return 1
            asset_file = args[1]
            args = args[2:]
        elif a == "--force":
            force = 1
            args = args[1:]
        elif a == "--contributor":
            if len(args) < 2:
                _err("ERROR: --contributor requires a value (e.g., @octocat)\n")
                return 1
            contributor = args[1]
            # Normalize: ensure leading @
            if not contributor.startswith("@"):
                contributor = "@" + contributor
            args = args[2:]
        elif a == "--":
            args = args[1:]
            if args and not source_file:
                source_file = args[0]
                args = args[1:]
        elif a.startswith("-"):
            _err(f"ERROR: Unknown option: {a}\n")
            _err(USAGE)
            return 1
        else:
            if not source_file:
                source_file = a
            else:
                _err(f"ERROR: Unexpected positional argument: {a}\n")
                _err(USAGE)
                return 1
            args = args[1:]

    if not source_file:
        _err("ERROR: Missing <source-file> argument\n")
        _err(USAGE)
        return 1

    if not os.path.isfile(source_file):
        _err(f"ERROR: Source file does not exist: {source_file}\n")
        return 1

    if not os.access(source_file, os.R_OK):
        _err(f"ERROR: Source file is not readable: {source_file}\n")
        return 1

    # -----------------------------------------------------------------------
    # Slug derivation and validation
    # -----------------------------------------------------------------------

    bo, brc = _capture(["basename", "--", source_file])
    if brc != 0:
        sys.exit(brc)  # set -e on the $() assignment
    basename_ = _cs(bo)

    if slug_provided == 1:
        slug = sanitize_slug(slug_override)
    else:
        slug = sanitize_slug(basename_)

    if not slug:
        _err("ERROR: Derived or provided slug is empty. Pass --slug <slug> with a non-empty value.\n")
        return 1

    # Defensive: slug must match [a-z0-9-]+ only.
    _, grc = _capture(["grep", "-qE", "^[a-z0-9-]+$"], stdin_bytes=_b(slug))
    if grc != 0:
        _err(f"ERROR: Slug contains invalid characters (allowed: [a-z0-9-]): {slug}\n")
        return 1

    # -----------------------------------------------------------------------
    # Date computation — UTC intentionally; MUST go through the external `date`
    # binary (PATH-shimmed by the characterization tests).
    # -----------------------------------------------------------------------

    do, drc = _capture(["date", "-u", "+%Y-%m-%d"])
    if drc != 0:
        sys.exit(drc)
    today = _cs(do)
    do, drc = _capture(["date", "-u", "+%Y"])
    if drc != 0:
        sys.exit(drc)
    year = _cs(do)
    do, drc = _capture(["date", "-u", "+%Y-%m"])
    if drc != 0:
        sys.exit(drc)
    month = _cs(do)

    # -----------------------------------------------------------------------
    # Destination directory + collision handling
    # -----------------------------------------------------------------------

    dest_dir = f"sources/{year}/{month}/{today}-{slug}"

    if os.path.exists(dest_dir):
        if force != 1:
            _err(f"ERROR: Destination already exists: {dest_dir}\n")
            _err("Pass --force to overwrite, or choose a different --slug.\n")
            return 1
        _err(f"WARNING: --force specified; overwriting files in {dest_dir}\n")

    # Derive the source destination filename BEFORE asset pre-validation (CR-01).
    if "." in basename_:
        ext = "." + basename_.rsplit(".", 1)[1]
        # Lowercase the extension for consistency.
        eo, _ = _capture(["tr", "[:upper:]", "[:lower:]"], stdin_bytes=_b(ext))
        ext = _cs(eo)
    else:
        ext = ""

    # Markdown files use source.md by convention; other extensions are preserved.
    if ext in (".md", ".markdown"):
        ext = ".md"

    dest_file = f"{dest_dir}/source{ext}"

    # Validate ALL --asset preconditions BEFORE creating the bundle dir (WR-02).
    asset_base = ""
    asset_dest = ""
    if asset_file:
        if not os.path.isfile(asset_file):
            _err(f"ERROR: --asset file not found: {asset_file}\n")
            return 1
        if not os.access(asset_file, os.R_OK):
            _err(f"ERROR: --asset file is not readable: {asset_file}\n")
            return 1
        abo, abrc = _capture(["basename", asset_file])
        if abrc != 0:
            sys.exit(abrc)
        asset_base = _cs(abo)
        asset_dest = f"{dest_dir}/{asset_base}"
        if asset_dest == dest_file:
            _err(f"ERROR: --asset basename '{asset_base}' collides with the ingested source destination ({dest_file})\n")
            return 1
        if os.path.exists(asset_dest) and force != 1:
            _err(f"ERROR: asset destination exists: {asset_dest} (use --force to overwrite)\n")
            return 1

    rc = _run(["mkdir", "-p", dest_dir])
    if rc != 0:
        sys.exit(rc)

    # -----------------------------------------------------------------------
    # File placement
    # -----------------------------------------------------------------------

    if force == 1:
        rc = _run(["cp", "-f", source_file, dest_file])
    else:
        rc = _run(["cp", source_file, dest_file])
    if rc != 0:
        sys.exit(rc)

    if asset_file:
        if force == 1:
            rc = _run(["cp", "-f", asset_file, asset_dest])
        else:
            rc = _run(["cp", asset_file, asset_dest])
        if rc != 0:
            sys.exit(rc)
        _err(f"Co-located asset: {asset_dest}\n")

    # -----------------------------------------------------------------------
    # C-1 cross-cutting ledger emission (life-system-spec 10 §C-1; ADR-008).
    # Deterministic script-side vault writes emit their own ledger lines; the
    # PostToolUse hook cannot see them. Fail-open: must never affect ingest's
    # exit code (C-1 failure rule). NON-SILENT (ADR-008 failure handling): when
    # the emit fails (nonzero exit, timeout, exec error) or cc-ledger is absent
    # on this host, the same C-1-shaped record is appended to a local
    # append-only fallback file OUTSIDE the repo tree:
    #     $XDG_STATE_HOME/compendium/ledger-fallback.jsonl
    #     (default: ~/.local/state/compendium/ledger-fallback.jsonl)
    # The file's line depth is the visible metric; the cc-ledger replayer
    # sweeps it (adding refs ["replayed:<source>"] — this side writes plain
    # C-1 lines with refs []). The fallback write is itself fail-open: it must
    # never break ingest either.
    # -----------------------------------------------------------------------

    def _fallback_ledger(target, op):
        # Mirror of the record cc-ledger's bin/emit_op_line.py constructs
        # (same shape, same 0600 append-only semantics; no flock — one short
        # O_APPEND write per record is interleave-safe).
        try:
            import json
            from datetime import datetime, timezone
            state_home = (os.environ.get("XDG_STATE_HOME")
                          or os.path.expanduser("~/.local/state"))
            path = os.path.join(state_home, "compendium", "ledger-fallback.jsonl")
            os.makedirs(os.path.dirname(path), exist_ok=True)
            line = {
                "v": 1,
                "ts": datetime.now(timezone.utc).isoformat(
                    timespec="seconds").replace("+00:00", "Z"),
                "store": "knowledge",
                "target": os.path.abspath(target),
                "op": op,
                "agent": "compendium-ingest",
                "session": os.environ.get("CLAUDE_SESSION_ID", "batch"),
                "refs": [],
            }
            data = (json.dumps(line, separators=(",", ":"), ensure_ascii=False)
                    + "\n").encode("utf-8")
            fd = os.open(path, os.O_WRONLY | os.O_APPEND | os.O_CREAT, 0o600)
            try:
                os.write(fd, data)
            finally:
                os.close(fd)
        except Exception:
            pass

    def _emit_ledger(target, op):
        try:
            root = os.environ.get("CC_LEDGER_ROOT",
                                  os.path.expanduser("~/Documents/cc-ledger"))
            emitter = os.path.join(root, "bin", "emit_op_line.py")
            if not os.path.isfile(emitter):
                _fallback_ledger(target, op)   # cc-ledger absent on this host
                return
            p = subprocess.run(
                [sys.executable, emitter, "--store", "knowledge",
                 "--op", op, "--target", os.path.abspath(target),
                 "--agent", "compendium-ingest",
                 "--session", os.environ.get("CLAUDE_SESSION_ID", "batch")],
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                timeout=10)
            if p.returncode != 0:
                _fallback_ledger(target, op)   # emit ran and failed
        except Exception:
            _fallback_ledger(target, op)       # timeout / exec error

    _emit_ledger(dest_file, "edit" if force == 1 else "create")
    if asset_file:
        _emit_ledger(asset_dest, "edit" if force == 1 else "create")

    # -----------------------------------------------------------------------
    # BRWN-10: strip brownfield-scoped fields to prevent pollution
    # -----------------------------------------------------------------------

    pwd = os.getcwd()
    bf_rel_path = dest_file
    prefix = pwd + "/"
    if bf_rel_path.startswith(prefix):
        bf_rel_path = bf_rel_path[len(prefix):]

    for bf_field in ("bootstrap_stage", "bootstrap_date"):
        go, grc1 = _capture(["grep", "-E", f"^{bf_field}:", dest_file],
                            stderr=subprocess.DEVNULL)
        # | head -1 || true
        bf_value_raw = go.decode("utf-8", "surrogateescape").split("\n")[0] if go else ""
        if not bf_value_raw:
            continue
        vo, _ = _capture(["sed", "-E", "s/^[^:]+:[[:space:]]*//"], stdin_bytes=_b(bf_value_raw))
        vo, _ = _capture(["sed", "-E", "s/[[:space:]]+$//"], stdin_bytes=vo)
        bf_value = _cs(vo)
        try:
            bf_stripped = _bf_strip_frontmatter_field(dest_file, bf_field)
        except Exception:
            # bash: the python3 heredoc dies with a traceback; the $() assignment
            # then aborts the script under set -e with the interpreter's status.
            import traceback
            sys.stderr.write(traceback.format_exc())
            sys.stderr.flush()
            sys.exit(1)
        if (bf_stripped if bf_stripped else "0") != "0":
            _err(f"Note: stripped {bf_field}={bf_value} from {bf_rel_path} during ingest (brownfield-scoped field; see AGENTS.md §5).\n")

    # -----------------------------------------------------------------------
    # Hash computation
    # -----------------------------------------------------------------------

    hash_, hrc = compute_hash(dest_file)
    if hrc != 0:
        sys.exit(hrc)

    # -----------------------------------------------------------------------
    # Contributor resolution (D-19..D-21)
    # -----------------------------------------------------------------------

    resolved_contributor = resolve_contributor(pwd, contributor)

    # -----------------------------------------------------------------------
    # Output — scaffold summary and ingest instructions
    # -----------------------------------------------------------------------

    _out(f"""=== Source Scaffolded ===

  File:    {dest_file}
  Slug:    {slug}
  Hash:    sha256:{hash_}
  Date:    {today} (UTC)

=== Ready to Ingest ===

Tell your LLM agent:

  Ingest the source at {dest_file}

  Source metadata:
    content_hash: "sha256:{hash_}"
    ingested_at: {today}
    path: {dest_file}

  Follow the Ingest Workflow in AGENTS.md section 11.1.

=== Log Entry Template (append to wiki-cloud/log.md) ===

## [{today}] ingest | <source title>

""")

    if resolved_contributor:
        _out(f"contributor:: {resolved_contributor}\n\n")

    _out("<what was done, affected pages, rationale>\n")
    return 0


if __name__ == "__main__":          # enables `python3 -m compendium.ingest`
    sys.exit(main(sys.argv[1:]))
