# src/compendium/repo_snapshot.py — byte-parity port of bin/repo-snapshot.sh
# (Phase 25 MIG-05; mechanical half of the repository acquisition runbook).
#
# PARITY CONTRACT: external commands stay external with identical argv — git
# (clone/rev-parse/symbolic-ref), `date -u +%Y-%m-%d` (PATH-shimmable frozen-now
# site), basename, mktemp, the license grep -qi chain (ORDER IS LOAD-BEARING:
# MPL/LGPL/AGPL cite the GNU GPL, so specific families are checked BEFORE the
# GPL phrase), the dominant-language find|sed|sort|uniq -c|sort -rn|head|awk
# pipeline (sort -rn tie-breaking is observable), and the README-H1-demoting
# sed. Curation stays human/agent judgment AFTER this tool.
import os
import subprocess
import sys

USAGE = """Usage: bin/repo-snapshot.sh <repo-url> [--dest <bundle-dir>] [--force]

Mechanical half of the repository acquisition runbook
(schema/reference/repository-ingestion.md): shallow-clone, harvest snapshot
metadata (commit SHA, default branch, license, dominant language), emit a
snapshot source.md SKELETON (metadata + README + empty Excerpts scaffold).
Curation stays human/agent judgment and happens AFTER this script.

  <repo-url>        e.g. https://github.com/<owner>/<repo>
  --dest <dir>      write <dir>/source.md (creates <dir>); default: stdout.
                    Refuses to overwrite an existing source.md (a curated
                    bundle) unless --force is given.
  --force           allow --dest to overwrite an existing source.md
"""

# The awk program — byte-identical to the bash single-quoted string.
_AWK_LANG_PROG = """{ext=$2}
         END{
           map["py"]="Python"; map["js"]="JavaScript"; map["cjs"]="JavaScript";
           map["mjs"]="JavaScript"; map["ts"]="TypeScript"; map["tsx"]="TypeScript";
           map["go"]="Go"; map["rs"]="Rust"; map["rb"]="Ruby"; map["java"]="Java";
           map["c"]="C"; map["cpp"]="C++"; map["h"]="C"; map["sh"]="Shell";
           map["lua"]="Lua"; map["swift"]="Swift"; map["kt"]="Kotlin"; map["php"]="PHP";
           if (ext in map) print map[ext]; else if (ext != "") print ext; else print "unknown"
         }"""

_LANG_EXT_NAMES = ['*.py', '*.js', '*.cjs', '*.mjs', '*.ts', '*.tsx', '*.go', '*.rs',
                   '*.rb', '*.java', '*.c', '*.cpp', '*.h', '*.sh', '*.lua', '*.swift',
                   '*.kt', '*.php']


def _reconfigure_streams():
    for s in (sys.stdout, sys.stderr):
        try:
            s.reconfigure(encoding="utf-8", errors="surrogateescape")
        except Exception:
            pass


def _out_bytes(b):
    sys.stdout.flush()
    sys.stdout.buffer.write(b)
    sys.stdout.buffer.flush()


def _out(s):
    sys.stdout.write(s)
    sys.stdout.flush()


def _err(s):
    sys.stderr.write(s)
    sys.stderr.flush()


def _rc_of(p):
    return 128 - p.returncode if p.returncode < 0 else p.returncode


def _run(argv, stdout=None, stderr=None):
    sys.stdout.flush()
    sys.stderr.flush()
    p = subprocess.run(argv, stdout=stdout, stderr=stderr)
    return _rc_of(p)


def _capture(argv, stdin_bytes=None, stderr=None):
    sys.stdout.flush()
    sys.stderr.flush()
    p = subprocess.run(argv, input=stdin_bytes, stdout=subprocess.PIPE, stderr=stderr)
    return p.stdout, _rc_of(p)


def _cs(out_bytes):
    return out_bytes.decode("utf-8", "surrogateescape").rstrip("\n")


def _grep_qi(pattern, path):
    """if grep -qi 'pattern' "$p" — condition context, stderr inherited."""
    return _run(["grep", "-qi", pattern, path]) == 0


def detect_license(repo_dir):
    """First recognizable license family in a LICENSE file (order load-bearing)."""
    license_ = "unknown"
    for f in ("LICENSE", "LICENSE.md", "LICENSE.txt", "LICENSE-MIT", "COPYING", "COPYING.md"):
        p = f"{repo_dir}/{f}"
        if not os.path.isfile(p):
            continue
        if _grep_qi("MIT License", p):
            license_ = "MIT"
        elif _grep_qi("Apache License", p):
            license_ = "Apache-2.0"
        elif _grep_qi("Mozilla Public License", p):
            license_ = "MPL-2.0"
        elif _grep_qi("GNU LESSER GENERAL PUBLIC", p):
            license_ = "LGPL"
        elif _grep_qi("GNU AFFERO GENERAL PUBLIC", p):
            license_ = "AGPL-3.0"
        elif _grep_qi("GNU GENERAL PUBLIC LICENSE", p):
            if _grep_qi("Version 3", p):
                license_ = "GPL-3.0"
            else:
                license_ = "GPL"
        elif _grep_qi("BSD", p):
            license_ = "BSD"
        elif _grep_qi("unlicense", p):
            license_ = "Unlicense"
        else:
            license_ = "present (unclassified)"
        break
    return license_


def detect_primary_language(repo_dir):
    """Most frequent implementation-file extension — the exact bash pipeline
    (find | sed | sort | uniq -c | sort -rn | head -1 | awk), each stage the
    real external tool so ordering/tie-break semantics cannot drift.
    Returns (language, awk_rc)."""
    find_argv = ["find", repo_dir, "-type", "f", "-not", "-path", "*/.git/*", "("]
    for i, name in enumerate(_LANG_EXT_NAMES):
        if i > 0:
            find_argv.append("-o")
        find_argv.extend(["-name", name])
    find_argv.append(")")
    fo, _frc = _capture(find_argv, stderr=subprocess.DEVNULL)          # || true
    so, _ = _capture(["sed", r"s/.*\.//"], stdin_bytes=fo)
    so, _ = _capture(["sort"], stdin_bytes=so)
    so, _ = _capture(["uniq", "-c"], stdin_bytes=so)
    so, _ = _capture(["sort", "-rn"], stdin_bytes=so)
    head1 = so.split(b"\n")[0] + b"\n" if so else b""                  # head -1 || true
    ao, arc = _capture(["awk", _AWK_LANG_PROG], stdin_bytes=head1)
    return _cs(ao), arc


def main(argv=None):
    args = list(sys.argv[1:] if argv is None else argv)
    _reconfigure_streams()

    repo_url = ""
    dest = ""
    force = 0
    while args:
        a = args[0]
        if a in ("--help", "-h"):
            _out(USAGE)
            return 0
        elif a == "--dest":
            if len(args) < 2:
                _err("ERROR: --dest requires a value\n")
                return 1
            dest = args[1]
            args = args[2:]
        elif a == "--force":
            force = 1
            args = args[1:]
        elif a.startswith("-"):
            _err(f"ERROR: unknown option: {a}\n")
            return 1
        else:
            if repo_url:
                _err("ERROR: multiple repo URLs given\n")
                return 1
            repo_url = a
            args = args[1:]
    if not repo_url:
        _err(USAGE)
        return 1
    if dest and os.path.isfile(f"{dest}/source.md") and force != 1:
        _err(f"ERROR: {dest}/source.md already exists (curated bundle?) — re-running\n")
        _err("would clobber curation. Pass --force to overwrite deliberately.\n")
        return 1

    import shutil
    if not shutil.which("git"):
        _err("ERROR: git not found\n")
        return 1

    to, trc = _capture(["mktemp", "-d", "-t", "repo-snapshot-XXXXXX"])
    if trc != 0:
        sys.exit(trc)
    tmp = _cs(to)

    try:
        _err(f"Cloning (depth 1): {repo_url}\n")
        rc = _run(["git", "clone", "--quiet", "--depth", "1", repo_url, f"{tmp}/repo"])
        if rc != 0:
            sys.exit(rc)  # set -e

        co, crc = _capture(["git", "-C", f"{tmp}/repo", "rev-parse", "HEAD"])
        if crc != 0:
            sys.exit(crc)
        commit_sha = _cs(co)

        bo, brc = _capture(["git", "-C", f"{tmp}/repo", "symbolic-ref", "--short", "HEAD"],
                           stderr=subprocess.DEVNULL)
        default_branch = _cs(bo) if brc == 0 else "unknown"

        ro, rrc = _capture(["date", "-u", "+%Y-%m-%d"])
        if rrc != 0:
            sys.exit(rrc)
        retrieved = _cs(ro)

        no, nrc = _capture(["basename", repo_url, ".git"])
        if nrc != 0:
            sys.exit(nrc)
        repo_name = _cs(no)

        # --- License heuristic ---
        license_ = detect_license(f"{tmp}/repo")

        # --- Dominant-language heuristic ---
        primary_language, awk_rc = detect_primary_language(f"{tmp}/repo")
        if awk_rc != 0:
            sys.exit(awk_rc)  # pipefail: awk is the unguarded final stage
        if not primary_language:
            primary_language = "unknown"

        # --- README body ---
        readme_path = ""
        for f in ("README.md", "Readme.md", "readme.md", "README"):
            if os.path.isfile(f"{tmp}/repo/{f}"):
                readme_path = f"{tmp}/repo/{f}"
                break

        def emit(write, sed_stdout):
            """Streams like the bash emit(): cat heredoc, sed (stdout wired to
            the same sink), cat heredoc. Returns sed's status (set -e site)."""
            head = f"""# {repo_name} — repository snapshot

## Snapshot Metadata

- Repository: {repo_url}
- Commit: {commit_sha}
- Default branch: {default_branch}
- License: {license_}
- Primary language: {primary_language}
- Retrieved: {retrieved}

## README

""".encode("utf-8", "surrogateescape")
            write(head)
            if readme_path:
                # Comment out the README's own H1 title lines (Phase 22 review):
                # an embedded '# Title' would terminate the '## README' slice.
                src = _run(
                    ["sed", r"s/^# \(.*\)$/<!-- readme H1 demoted at snapshot: \1 -->/",
                     readme_path], stdout=sed_stdout)
                if src != 0:
                    return src  # set -e: partial output stays behind, like bash
            else:
                write(b"(no README found at snapshot time)\n")
            tail = b"""
## Excerpts

<!-- Curator-selected code excerpts. Each entry heading is '### <path/to/file>'
     or '### <path/to/file>:L<n>-L<m>'; body is a fenced code block quoting the
     lines at the snapshot commit. #path: locators resolve against these
     headings (schema/reference/repository-ingestion.md). If you anchor a claim
     to code, quote the code here. -->
"""
            write(tail)
            return 0

        if dest:
            rc = _run(["mkdir", "-p", dest])
            if rc != 0:
                sys.exit(rc)
            with open(f"{dest}/source.md", "wb") as fh:
                def _w(b):
                    fh.write(b)
                    fh.flush()
                erc = emit(_w, fh)
            if erc != 0:
                sys.exit(erc)
            _err(f"Wrote {dest}/source.md (commit {commit_sha[0:12]}, branch {default_branch})\n")
            _err("Next: curate the README copy, populate ## Excerpts, then ingest.\n")
        else:
            erc = emit(_out_bytes, None)
            if erc != 0:
                sys.exit(erc)
        return 0
    finally:
        # trap 'rm -rf "$TMP"' EXIT
        subprocess.run(["rm", "-rf", tmp])


if __name__ == "__main__":          # enables `python3 -m compendium.repo_snapshot`
    sys.exit(main(sys.argv[1:]))
