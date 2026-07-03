# src/compendium/search.py — byte-parity port of bin/search.sh (Phase 25 MIG-05).
#
# PARITY CONTRACT: external commands stay external (grep/sed/tr via subprocess
# with identical argv — grep -r traversal order and BRE pattern semantics are
# observable). The contributor-mode python3 heredoc is lifted verbatim.
#
# KNOWN-BROKEN BEHAVIOR PINNED ON PURPOSE (goldens freeze it; fix tracked for
# post-migration): on a convention-conforming PIPED index ([[id|Title]]), the
# title extraction keeps "id|Title", the slug never resolves, and the fallback
# `grep -rl ... | head -1` fails under `set -euo pipefail` — the bash script
# aborts at the `path=$(resolve_page_path ...)` assignment with the pipeline's
# status and EMPTY output. This port replicates that abort exactly (exit 1,
# nothing printed). Do NOT fix here — behavior parity bar (D-15).
import glob
import os
import re
import subprocess
import sys

WIKI_INDEX = "wiki-cloud/index.md"
WIKI_DIR = "wiki-cloud"

USAGE = """Usage: bin/search.sh [OPTIONS] <keyword>
       bin/search.sh --query "question"

Search wiki pages by keyword with deterministic output per mode.

Modes:
  Default                 Index lookup with TL;DR snippets
  --paths-only            Output file paths only (no headers, no TL;DR)
  --fulltext              Also search wiki-cloud/ body text (default: index-only)
  --query "Q"             Generate an LLM-ready prompt from a question
  --contributor <handle>  Filter wiki-cloud/log.md entries by contributor @handle.
                          Accepts both @octocat and octocat (leading @ optional).

Options:
  --help, -h              Show this help message

Output Contracts:
  Default mode:
    === Search Results ===
    wiki-cloud/<subdir>/<slug>.md -- <TL;DR first line>
    === N result(s) ===

  --paths-only mode:
    wiki-cloud/<subdir>/<slug>.md
    (bare paths, one per line, no headers)

  --query mode:
    === Query Prompt ===
    ... structured prompt ...
    === End Query Prompt ===

  No results (any mode):
    No results found for "<keyword>"

Exit codes:
  0  Success (including no results — that is informational, not an error)
  1  Error (no arguments, missing index, invalid flag)
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
    return 128 - p.returncode if p.returncode < 0 else p.returncode


def _capture(argv, stdin_bytes=None, stderr=None):
    sys.stdout.flush()
    sys.stderr.flush()
    p = subprocess.run(argv, input=stdin_bytes, stdout=subprocess.PIPE, stderr=stderr)
    return p.stdout, _rc_of(p)


def _cs(out_bytes):
    return out_bytes.decode("utf-8", "surrogateescape").rstrip("\n")


def _b(s):
    return s.encode("utf-8", "surrogateescape")


def _echo_bytes(arg):
    """bash builtin `echo "$x"` for a single argument: an argument matching
    -[neE]+ is consumed as options (-n suppresses the newline)."""
    if re.fullmatch(r"-[neE]+", arg):
        return b"" if "n" in arg else b"\n"
    return _b(arg) + b"\n"


def _pipestatus(*rcs):
    status = 0
    for rc in rcs:
        if rc != 0:
            status = rc
    return status


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def extract_tldr(file):
    """sed -n '/^## TL;DR/,/^## /{...}' "$file" | head -1 — returns (text, status)."""
    o, rc = _capture(["sed", "-n", "/^## TL;DR/,/^## /{/^## TL;DR/d;/^## /d;/^$/d;p;}", file])
    first = o.split(b"\n")[0] if o else b""
    return first.decode("utf-8", "surrogateescape"), _pipestatus(rc, 0)


def resolve_page_path(title):
    """Returns (path_text, status). status is the bash function's exit status —
    a nonzero fallback-grep pipeline status ABORTS the caller (set -e)."""
    o, _ = _capture(["tr", "[:upper:]", "[:lower:]"], stdin_bytes=_echo_bytes(title))
    o, _ = _capture(["sed", "-E", "s/[^a-z0-9]+/-/g; s/^-+|-+$//g"], stdin_bytes=o)
    slug = _cs(o)
    for d in (f"{WIKI_DIR}/entities", f"{WIKI_DIR}/concepts", f"{WIKI_DIR}/sources",
              f"{WIKI_DIR}/comparisons", f"{WIKI_DIR}/overviews"):
        if os.path.isfile(f"{d}/{slug}.md"):
            return f"{d}/{slug}.md", 0
    # Fallback: grep for matching title in all wiki files
    go, grc = _capture(["grep", "-rl", f"^title:.*{title}", WIKI_DIR + "/"],
                       stderr=subprocess.DEVNULL)
    first = go.split(b"\n")[0] if go else b""
    return first.decode("utf-8", "surrogateescape"), _pipestatus(grc, 0)


def search_index(query):
    """grep -i "$query" "$WIKI_INDEX" | grep -E '^\\- \\[\\[' || true"""
    o1, _r1 = _capture(["grep", "-i", query, WIKI_INDEX])
    o2, _r2 = _capture(["grep", "-E", r"^\- \[\["], stdin_bytes=o1)
    return _cs(o2)


def search_fulltext(query):
    """grep -ril | grep -v index | grep -v log || true"""
    o1, _r1 = _capture(["grep", "-ril", query, WIKI_DIR + "/"], stderr=subprocess.DEVNULL)
    o2, _r2 = _capture(["grep", "-v", WIKI_INDEX], stdin_bytes=o1)
    o3, _r3 = _capture(["grep", "-v", f"{WIKI_DIR}/log.md"], stdin_bytes=o2)
    return _cs(o3)


def format_result_line(path):
    tldr, rc = extract_tldr(path)
    if rc != 0:
        sys.exit(rc)  # set -e on the local assignment
    if tldr:
        _out(f"{path} -- {tldr}\n")
    else:
        _out(f"{path} -- (no TL;DR)\n")


def _extract_title(line):
    """title=$(echo "$line" | sed -E 's/.*\\[\\[([^]]+)\\]\\].*/\\1/')"""
    o, _ = _capture(["sed", "-E", r"s/.*\[\[([^]]+)\]\].*/\1/"], stdin_bytes=_echo_bytes(line))
    return _cs(o)


def _contributor_mode(log_path, handle):
    """Verbatim lift of the contributor-filter python3 heredoc (COLAB-07)."""
    content = open(log_path, encoding='utf-8').read()
    # Split into entries at `## [` headers; keep the header with each entry
    parts = re.split(r'(?m)^(?=## \[)', content)
    matches = []
    for p in parts:
        if not p.strip().startswith('## ['):
            continue
        if re.search(r'contributor::\s*@' + re.escape(handle) + r'\b', p):
            matches.append(p.rstrip())
    if not matches:
        print(f'No results found for "@{handle}"', file=sys.stderr)
        sys.stderr.flush()
        return
    print("=== Contributor Results ===")
    for m in matches:
        print(m)
        print("---")
    print(f"=== {len(matches)} result(s) ===")
    sys.stdout.flush()


def _shell_words(query):
    """Unquoted $QUERY: IFS whitespace splitting + pathname expansion against
    the cwd (nullglob off: a non-matching pattern stays literal)."""
    words = []
    for word in query.split():
        if any(c in word for c in "*?["):
            matches = sorted(glob.glob(word))
            if matches:
                words.extend(matches)
                continue
        words.append(word)
    return words


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main(argv=None):
    args = list(sys.argv[1:] if argv is None else argv)
    _reconfigure_streams()

    if len(args) == 0:
        _err(USAGE)
        return 1

    keyword = ""
    query = ""
    paths_only = 0
    fulltext = 0
    contributor_filter = ""

    while args:
        a = args[0]
        if a in ("--help", "-h"):
            _out(USAGE)
            return 0
        elif a == "--query":
            if len(args) < 2:
                _err("ERROR: --query requires a value\n")
                return 1
            query = args[1]
            args = args[2:]
        elif a == "--contributor":
            if len(args) < 2:
                _err("ERROR: --contributor requires a value (e.g., @octocat)\n")
                return 1
            contributor_filter = args[1]
            # Strip leading @ for internal matching (accept both forms)
            if contributor_filter.startswith("@"):
                contributor_filter = contributor_filter[1:]
            args = args[2:]
        elif a == "--paths-only":
            paths_only = 1
            args = args[1:]
        elif a == "--fulltext":
            fulltext = 1
            args = args[1:]
        elif a.startswith("-"):
            _err(f"ERROR: Unknown option: {a}\n")
            return 1
        else:
            if not keyword:
                keyword = a
            else:
                _err(f"ERROR: Unexpected positional argument: {a}\n")
                return 1
            args = args[1:]

    # -----------------------------------------------------------------------
    # Contributor filter mode (COLAB-07)
    # -----------------------------------------------------------------------

    if contributor_filter:
        log = f"{WIKI_DIR}/log.md"
        if not os.path.isfile(log):
            _err(f'No results found for "@{contributor_filter}"\n')
            return 0
        try:
            _contributor_mode(log, contributor_filter)
        except Exception:
            # bash: the heredoc python3 dies (traceback on stderr) and set -e
            # aborts the script with the interpreter's status.
            import traceback
            sys.stderr.write(traceback.format_exc())
            sys.stderr.flush()
            return 1
        return 0

    # -----------------------------------------------------------------------
    # Validation
    # -----------------------------------------------------------------------

    if not os.path.isfile(WIKI_INDEX):
        _err(f"ERROR: {WIKI_INDEX} not found\n")
        return 1

    # -----------------------------------------------------------------------
    # Query mode
    # -----------------------------------------------------------------------

    if query:
        result_paths = []
        seen_paths = set()

        for word in _shell_words(query):
            # Skip short words (articles, prepositions) — ${#word} counts BYTES
            # under the seam's LC_ALL=C.
            if len(word.encode("utf-8", "surrogateescape")) <= 3:
                continue
            # Strip punctuation from word
            o, _ = _capture(["sed", "-E", "s/[^a-zA-Z0-9]//g"], stdin_bytes=_echo_bytes(word))
            clean_word = _cs(o)
            if not clean_word:
                continue

            index_lines = search_index(clean_word)
            if index_lines:
                for line in index_lines.split("\n"):
                    title = _extract_title(line)
                    path, rc = resolve_page_path(title)
                    if rc != 0:
                        sys.exit(rc)  # set -e: the $() assignment aborts the script
                    if path and path not in seen_paths:
                        seen_paths.add(path)
                        result_paths.append(path)

        if len(result_paths) == 0:
            _out(f'No results found for "{query}"\n')
            return 0

        _out("=== Query Prompt ===\n")
        _out("\n")
        _out(f"Question: {query}\n")
        _out("\n")
        _out("Relevant wiki pages (read in this order, TL;DR first, drill into Detail only if needed):\n")
        _out("\n")
        count = 1
        for path in result_paths:
            tldr, rc = extract_tldr(path)
            if rc != 0:
                sys.exit(rc)
            if tldr:
                _out(f"{count}. {path} -- {tldr}\n")
            else:
                _out(f"{count}. {path} -- (no TL;DR)\n")
            count += 1
        _out("\n")
        _out("Instructions:\n")
        _out("- Read TL;DR and Key Facts sections first (progressive disclosure).\n")
        _out("- Read Detail sections only where shallow content is insufficient.\n")
        _out("- Cite specific wiki pages and provenance markers in your answer.\n")
        _out("- If the answer produces novel synthesis, write it back to the wiki per AGENTS.md section 11.2.\n")
        _out("=== End Query Prompt ===\n")
        return 0

    # -----------------------------------------------------------------------
    # Keyword mode (default or --paths-only)
    # -----------------------------------------------------------------------

    if not keyword:
        _err('ERROR: No keyword provided. Use <keyword> or --query "question"\n')
        _err(USAGE)
        return 1

    result_map = set()
    result_order = []

    # 1. Index search
    index_lines = search_index(keyword)
    if index_lines:
        for line in index_lines.split("\n"):
            title = _extract_title(line)
            path, rc = resolve_page_path(title)
            if rc != 0:
                sys.exit(rc)  # set -e: the $() assignment aborts the script
            if path and path not in result_map:
                result_map.add(path)
                result_order.append(path)

    # 2. Full-text search (if --fulltext)
    if fulltext == 1:
        ft_results = search_fulltext(keyword)
        if ft_results:
            for path in ft_results.split("\n"):
                if path and path not in result_map:
                    result_map.add(path)
                    result_order.append(path)

    # No results
    if len(result_order) == 0:
        _out(f'No results found for "{keyword}"\n')
        return 0

    # Output
    if paths_only == 1:
        for path in result_order:
            _out(f"{path}\n")
    else:
        _out("=== Search Results ===\n")
        for path in result_order:
            format_result_line(path)
        _out(f"=== {len(result_order)} result(s) ===\n")
    return 0


if __name__ == "__main__":          # enables `python3 -m compendium.search`
    sys.exit(main(sys.argv[1:]))
