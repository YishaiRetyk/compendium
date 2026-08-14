# src/compendium/search.py — byte-parity port of bin/search.sh (Phase 25 MIG-05).
#
# PARITY CONTRACT: external commands stay external (grep/sed/tr via subprocess
# with identical argv — grep -r traversal order and BRE pattern semantics are
# observable). The contributor-mode python3 heredoc is lifted verbatim.
#
# PIPED-INDEX FIX (wayfinder ticket 24, 2026-08-14). Previously this port froze a
# known-broken behavior for bash parity: on a convention-conforming PIPED index
# ([[id|Title]] — mandated by AGENTS.md §8 rule 3) the title extraction kept the
# whole "id|Title" inner text, the slug never resolved, and the fallback
# `grep -rl ... | head -1` aborted the caller under `set -euo pipefail` with exit 1
# and EMPTY output. Every index entry in the real wiki is piped, so C-8 consult was
# dead end-to-end. The parity bar was retired with the bash implementation
# (Phase 26 / 26-02: "there is one implementation now"), so the fix lands here.
#
# NO SILENT SEAMS (cross-contract rule; store-connection model C-8). Two rules now
# hold everywhere in this module:
#   1. An unresolvable index entry is REPORTED on stderr and skipped — never an
#      empty abort, and never silently dropped from the result set.
#   2. Every consult records a consult-health outcome (see _emit_consult_health)
#      so a degraded or failing C-8 seam is visible in the digest rather than
#      being discovered by an agent getting empty results.
import glob
import os
import re
import subprocess
import sys

WIKI_INDEX = "wiki-cloud/index.md"
WIKI_DIR = "wiki-cloud"

# The six canonical page-type subdirectories (schema/AGENTS.template.md §"both
# tiers use the same six page-type subdirectories"). `decisions` was missing
# here, so every indexed decision record was unreachable through consult even
# after alias parsing was fixed — the resolver has to know the whole schema, not
# a subset of it. `maintenance/` is deliberately absent: it is wiki bookkeeping,
# not a page type.
PAGE_TYPE_DIRS = ("entities", "concepts", "sources", "comparisons",
                  "overviews", "decisions")

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
  1  Error (no arguments, missing index, invalid flag, or the index matched
     entries but NONE resolved to a page — always with a stderr diagnostic)

Failure visibility:
  Unresolvable index entries are always named on stderr, and every consult
  overwrites a one-line health record (`ok <ts>` / `fail <ts> <reason>`) at
  $COMPENDIUM_CONSULT_HEALTH, else
  $XDG_STATE_HOME/compendium/consult-health.status.
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
# Consult health (C-8 failure visibility)
# ---------------------------------------------------------------------------
# The digest must never have to infer that knowledge consult is broken. This
# writes ONE line, fully overwritten on every consult, in the same status
# grammar the GTD digest already parses for job health:
#     ok <iso-ts>                 consult resolved everything it matched
#     fail <iso-ts> <reason>      consult failed or resolved only part of it
# Overwrite-per-run is deliberate: the file's content at digest-build time IS
# the current state, so a fixed seam stops reporting without history to chase.
#
# The record lands OUTSIDE every sovereign store (life-system INV-2: no
# store->store code paths — Compendium must not write into the GTD vault), at
# the same XDG state root ingest.py already uses for its ledger fallback:
#     $XDG_STATE_HOME/compendium/consult-health.status
# Consuming it into the digest is the GTD-engine half of this contract and is
# NOT implemented here; see the ticket-24 report.
#
# Fail-open in both directions: a health-write failure must never change what a
# consult returns, and must never mask the consult's own diagnostics.

def _health_path():
    override = os.environ.get("COMPENDIUM_CONSULT_HEALTH")
    if override:
        return override
    state_home = (os.environ.get("XDG_STATE_HOME")
                  or os.path.expanduser("~/.local/state"))
    return os.path.join(state_home, "compendium", "consult-health.status")


def _emit_consult_health(status, reason=""):
    try:
        from datetime import datetime, timezone
        ts = datetime.now(timezone.utc).isoformat(
            timespec="seconds").replace("+00:00", "Z")
        # Newlines would forge extra status records; collapse to one line.
        reason = " ".join(str(reason).split())
        line = f"{status} {ts}" + (f" {reason}" if reason else "") + "\n"
        path = _health_path()
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8") as fh:
            fh.write(line)
    except Exception:
        pass                                   # never let health break consult


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def extract_tldr(file):
    """sed -n '/^## TL;DR/,/^## /{...}' "$file" | head -1 — returns (text, status)."""
    o, rc = _capture(["sed", "-n", "/^## TL;DR/,/^## /{/^## TL;DR/d;/^## /d;/^$/d;p;}", file])
    first = o.split(b"\n")[0] if o else b""
    return first.decode("utf-8", "surrogateescape"), _pipestatus(rc, 0)


def _slugify(text):
    o, _ = _capture(["tr", "[:upper:]", "[:lower:]"], stdin_bytes=_echo_bytes(text))
    o, _ = _capture(["sed", "-E", "s/[^a-z0-9]+/-/g; s/^-+|-+$//g"], stdin_bytes=o)
    return _cs(o)


def resolve_page_path(target, display=None):
    """Resolve one index entry to a page path; "" means unresolved.

    `target` is the wikilink's target side — already the page `id` on a piped
    link, so slugifying it is idempotent; a bare link's human title slugifies
    the same way it always did. `display` is the alias side and is only used
    for the frontmatter-title fallback, which is where it can actually match.

    Never aborts: an unresolved entry returns "" and the caller reports it.
    The old contract returned the fallback grep's exit status, which the caller
    propagated into sys.exit() — that is what made a piped index kill the whole
    consult with no output.
    """
    slug = _slugify(target)
    for d in PAGE_TYPE_DIRS:
        if os.path.isfile(f"{WIKI_DIR}/{d}/{slug}.md"):
            return f"{WIKI_DIR}/{d}/{slug}.md"
    # Fallback: match the page's frontmatter title. A nonzero grep here means
    # "no match", which is information, not a fatal error.
    for probe in (display, target):
        if not probe:
            continue
        go, _grc = _capture(["grep", "-rl", f"^title:.*{probe}", WIKI_DIR + "/"],
                            stderr=subprocess.DEVNULL)
        first = go.split(b"\n")[0] if go else b""
        if first:
            return first.decode("utf-8", "surrogateescape")
    return ""


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
        _err(f"ERROR: could not read TL;DR from {path} (sed exit {rc})\n")
        _emit_consult_health("fail", f"unreadable page {path}")
        sys.exit(rc)
    if tldr:
        _out(f"{path} -- {tldr}\n")
    else:
        _out(f"{path} -- (no TL;DR)\n")


def _extract_title(line):
    """The wikilink's inner text, verbatim — still "id|Title" on a piped link."""
    o, _ = _capture(["sed", "-E", r"s/.*\[\[([^]]+)\]\].*/\1/"], stdin_bytes=_echo_bytes(line))
    return _cs(o)


def _split_wikilink(inner):
    """Split a wikilink's inner text into (target, display).

    AGENTS.md §8 rule 3 mandates `[[id|Exact Title]]` for every intra-wiki link,
    so the target side is the page id and the alias side is the display title.
    Bare `[[Title]]` links (legacy, and what the old code assumed was the only
    shape) have no alias: target and display are the same text.
    """
    target, sep, display = inner.partition("|")
    target = target.strip()
    display = display.strip() if sep else ""
    return target, display


def _resolve_index_entries(index_lines, seen, order, unresolved):
    """Resolve matched index lines to page paths, in index order.

    An entry that does not resolve is appended to `unresolved` rather than
    dropped: an index pointing at a page that is missing or misnamed is a real
    integrity fault in the wiki, and the consult has to say so.
    """
    for line in index_lines.split("\n"):
        if not line:
            continue
        inner = _extract_title(line)
        target, display = _split_wikilink(inner)
        path = resolve_page_path(target, display)
        if not path:
            unresolved.append(target or inner)
            continue
        if path not in seen:
            seen.add(path)
            order.append(path)


def _health_after_results(unresolved):
    """A consult that returned results but could not resolve every matched
    entry is still degraded — the agent silently got less than the index
    promised, which is exactly the failure C-8 must surface."""
    if unresolved:
        n = len(unresolved)
        _emit_consult_health(
            "fail", f"{n} index entr{'y' if n == 1 else 'ies'} did not resolve "
                    f"to a page — wiki index and pages disagree")
    else:
        _emit_consult_health("ok")


def _report_unresolved(unresolved):
    """Name every unresolvable entry on stderr — stdout stays a clean result
    contract, but the failure is never invisible."""
    if not unresolved:
        return
    _err(f"WARNING: {len(unresolved)} index entr"
         f"{'y' if len(unresolved) == 1 else 'ies'} did not resolve to a page "
         f"(wiki index and pages disagree): {', '.join(unresolved)}\n")


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
        # The seam is pointed at something that is not a wiki — the single most
        # likely deploy misconfiguration, and previously indistinguishable from
        # "this wiki has nothing on your topic".
        _err(f"ERROR: {WIKI_INDEX} not found "
             f"(searching from {os.getcwd()})\n")
        _emit_consult_health("fail", f"{WIKI_INDEX} not found under "
                                     f"{os.getcwd()}")
        return 1

    # -----------------------------------------------------------------------
    # Query mode
    # -----------------------------------------------------------------------

    if query:
        result_paths = []
        seen_paths = set()
        unresolved = []

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
                _resolve_index_entries(index_lines, seen_paths, result_paths,
                                       unresolved)

        _report_unresolved(unresolved)

        if len(result_paths) == 0:
            # Matching the index but resolving nothing is a broken wiki, not an
            # empty one: say so loudly instead of reporting "no results".
            if unresolved:
                _err(f'ERROR: matched {len(unresolved)} index entr'
                     f"{'y' if len(unresolved) == 1 else 'ies'} for "
                     f'"{query}" but resolved none to a page\n')
                _emit_consult_health(
                    "fail", f"query resolved 0 of {len(unresolved)} matched "
                            f"index entries — wiki index/pages disagree")
                return 1
            _out(f'No results found for "{query}"\n')
            _emit_consult_health("ok")
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
                _err(f"ERROR: could not read TL;DR from {path} (sed exit {rc})\n")
                _emit_consult_health("fail", f"unreadable page {path}")
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
        _health_after_results(unresolved)
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
    unresolved = []

    # 1. Index search
    index_lines = search_index(keyword)
    if index_lines:
        _resolve_index_entries(index_lines, result_map, result_order, unresolved)
    _report_unresolved(unresolved)

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
        # Same distinction as query mode: "the index has nothing" and "the index
        # has entries I cannot open" are different answers and must read that way.
        if unresolved:
            _err(f'ERROR: matched {len(unresolved)} index entr'
                 f"{'y' if len(unresolved) == 1 else 'ies'} for "
                 f'"{keyword}" but resolved none to a page\n')
            _emit_consult_health(
                "fail", f"keyword resolved 0 of {len(unresolved)} matched "
                        f"index entries — wiki index/pages disagree")
            return 1
        _out(f'No results found for "{keyword}"\n')
        _emit_consult_health("ok")
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
    _health_after_results(unresolved)
    return 0


if __name__ == "__main__":          # enables `python3 -m compendium.search`
    sys.exit(main(sys.argv[1:]))
