#!/usr/bin/env bash
# bin/check-neutrality.sh -- NEUT-06 + NEUT-08 gate.
# Greps public control-plane paths against a denylist (Kahneman + personal terms).
# Exits 0 on clean; 1 on script failure; 2 on denylist match.
#
# --suggest-denylist mode is DETERMINISTIC (REVIEWS.md HIGH #3):
#   Input sources (in order):
#     1. wiki-local/**/*.md pages under $ROOT (local-only tier by directory)
#     2. .planning/notes/**/*.md under $ROOT (creator personal notes)
#     3. Git history of known-deleted local_only paths via
#        `git log --all -p -- <paths>` (only when $ROOT is inside a git repo)
#     4. (Optional, with --include-gitignore) creator-specific patterns in .gitignore
#
#   Extraction rule:
#     - Tokenize on word boundaries: \b[A-Za-z][A-Za-z0-9-]{2,}\b (length >=3)
#     - Lowercase-normalize
#     - Filter against embedded stopword list (see --show-stopwords)
#     - Preserve hyphenated slugs as single tokens
#     - Sort lexicographically within each source group
#     - Output is sorted deterministically; same inputs -> byte-identical output.
set -euo pipefail

ROOT="${PWD}"
DENYLIST_DEFAULT=".neutrality-denylist.txt"
DENYLIST=""
SUGGEST=0
INCLUDE_GITIGNORE=0
SHOW_STOPWORDS=0
FORMAT="text"

usage() {
    cat <<'EOF'
Usage: bin/check-neutrality.sh [OPTIONS]

NEUT-06 + NEUT-08 gate. Scans public control-plane paths for denylist hits.

Options:
  --root DIR              Scan root (default: PWD)
  --denylist FILE         Denylist file (default: <root>/.neutrality-denylist.txt)
  --format text|json      Output format (default: text)
  --suggest-denylist      Emit candidate terms; no denylist required
  --include-gitignore     In suggest mode, also scan .gitignore for creator patterns
  --show-stopwords        Print the embedded stopword list and exit 0
  --help, -h              Show this help

Suggest-mode input sources (deterministic):
  1. wiki-local/**/*.md (local-only tier by directory; Phase 15 structural model)
  2. .planning/notes/**/*.md
  3. git log --all -p -- <known-deleted local_only paths>
  4. .gitignore creator-specific patterns (only with --include-gitignore)

Extraction rule:
  - Token: \b[A-Za-z][A-Za-z0-9-]{2,}\b, lowercase-normalized, length >= 3
  - Filter against embedded stopword list
  - Preserve hyphenated slugs as single tokens
  - Sort lexicographically within each source group

Scan-mode exemptions:
  - Directories named `examples/` are pruned (D-06 — sole sanctioned home
    for reference-example clusters).
  - Files listed in the scanner's SELF_REFERENTIAL_EXEMPT set are skipped
    (the scanner itself must describe the denylist by name to do its job).
  - Lines whose only match occurs inside a sanctioned `examples/kahneman/...`
    path reference are exempted (pointer lines like `See: examples/kahneman/...`
    are legitimate — mirrors 07-03/07-04 test precedent).
  - Markdown files with `neutrality_exempt: true` in frontmatter are skipped
    per-page (reserved for meta/schema records that legitimately discuss
    neutralization history, e.g. the Kahneman-to-examples decision record).

Exit codes:
  0  clean (or suggest/show-stopwords completed)
  1  script failure (missing denylist in scan mode, bad args)
  2  denylist hit found in scan mode
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --help|-h) usage; exit 0 ;;
        --root) ROOT="$2"; shift 2 ;;
        --denylist) DENYLIST="$2"; shift 2 ;;
        --format) FORMAT="$2"; shift 2 ;;
        --suggest-denylist) SUGGEST=1; shift ;;
        --include-gitignore) INCLUDE_GITIGNORE=1; shift ;;
        --show-stopwords) SHOW_STOPWORDS=1; shift ;;
        -*) echo "ERROR: unknown option: $1" >&2; usage >&2; exit 1 ;;
        *) echo "ERROR: unexpected argument: $1" >&2; exit 1 ;;
    esac
done

[ -z "$DENYLIST" ] && DENYLIST="$ROOT/$DENYLIST_DEFAULT"

# Public control-plane paths scanned (D-06). examples/ is explicitly excluded.
PUBLIC_PATHS=(AGENTS.md CLAUDE.md README.md PRIVACY.md docs .github wiki-cloud bin)

export CN_ROOT="$ROOT"
export CN_SUGGEST="$SUGGEST"
export CN_INCLUDE_GI="$INCLUDE_GITIGNORE"
export CN_SHOW_STOPWORDS="$SHOW_STOPWORDS"
export CN_FORMAT="$FORMAT"
export CN_DENYLIST="$DENYLIST"
# Join PUBLIC_PATHS with ':' for env transport
CN_PP=""
for p in "${PUBLIC_PATHS[@]}"; do
    if [ -z "$CN_PP" ]; then CN_PP="$p"; else CN_PP="$CN_PP:$p"; fi
done
export CN_PUBLIC_PATHS="$CN_PP"

set +e
python3 - <<'PYEOF'
import json
import os
import re
import subprocess
import sys

ROOT = os.path.abspath(os.environ.get("CN_ROOT", ""))  # set below
SUGGEST = int(os.environ.get("CN_SUGGEST", "0"))
INCLUDE_GI = int(os.environ.get("CN_INCLUDE_GI", "0"))
SHOW_STOPWORDS = int(os.environ.get("CN_SHOW_STOPWORDS", "0"))
FORMAT = os.environ.get("CN_FORMAT", "text")
DENYLIST = os.environ.get("CN_DENYLIST", "")
PUBLIC_PATHS = os.environ.get("CN_PUBLIC_PATHS", "").split(":")

# Embedded stopword list (domain-neutral + common English).
STOPWORDS = {
    # common English
    "the", "and", "for", "that", "this", "with", "from", "you", "your",
    "but", "not", "are", "was", "were", "has", "have", "had", "can", "will",
    "would", "could", "should", "into", "onto", "over", "under", "about",
    "out", "off", "any", "all", "one", "two", "its", "also", "than", "then",
    "when", "where", "what", "who", "how", "why", "which", "some", "such",
    "our", "they", "them", "their", "his", "her", "him", "she", "here",
    # domain-neutral (keep the signal: creator-specific terms only)
    "decision", "decisions", "journal", "journals", "notes", "note",
    "personal", "local", "only", "privacy", "frontmatter", "page", "pages",
    "wiki", "source", "sources", "example", "examples", "kahneman",
    "content", "entry", "entries", "file", "files", "markdown", "data",
    "text", "claim", "claims",
}

if SHOW_STOPWORDS:
    for w in sorted(STOPWORDS):
        print(w)
    sys.exit(0)

def load_denylist(path):
    if not os.path.isfile(path):
        return None
    terms = []
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            s = line.strip()
            if not s or s.startswith("#"):
                continue
            terms.append(s.lower())
    return terms

# Exempt paths that MUST reference the denylist terms by name to do their job
# (the scanner itself talks about what it filters).
SELF_REFERENTIAL_EXEMPT = {
    "bin/check-neutrality.sh",
}

# Line-level sanctioned-path exemption (mirrors 07-03 test_agents_neutralized.sh
# and 07-04 test_no_kahneman_in_public_docs.sh precedent): strip sanctioned
# `examples/kahneman/...` path references from the line before term matching, so
# legitimate `See: examples/kahneman/...` pointers don't trip the gate.
SANCTIONED_PATH_RE = re.compile(r"examples/kahneman[a-z0-9._/-]*", re.IGNORECASE)

def parse_frontmatter_block(text):
    """Return raw frontmatter string or None."""
    if not text.startswith("---"):
        return None
    end = text.find("\n---", 3)
    if end == -1:
        return None
    return text[3:end].strip()

def has_neutrality_exempt(text):
    """True if file frontmatter sets `neutrality_exempt: true`."""
    fm = parse_frontmatter_block(text)
    if fm is None:
        return False
    return bool(re.search(r"^neutrality_exempt:\s*true\b", fm, re.M | re.I))

def scan():
    terms = load_denylist(DENYLIST)
    if terms is None:
        print(f"ERROR: denylist missing: {DENYLIST}", file=sys.stderr)
        sys.exit(1)
    hits = []
    for rel in PUBLIC_PATHS:
        full = os.path.join(ROOT, rel)
        if not os.path.exists(full):
            continue
        targets = []
        if os.path.isfile(full):
            targets = [full]
        else:
            for dirpath, dirnames, filenames in os.walk(full):
                # Prune examples/ explicitly (D-06).
                if "examples" in dirnames:
                    dirnames.remove("examples")
                for fn in filenames:
                    targets.append(os.path.join(dirpath, fn))
        for t in targets:
            # Skip binary-ish by extension (scan .md/.sh/.yml/.yaml/.txt/.json + no-ext)
            _, ext = os.path.splitext(t)
            if ext and ext.lower() not in (".md", ".sh", ".yml", ".yaml", ".txt", ".json", ".py", ".toml", ".ini", ".cfg"):
                continue
            rel_path = os.path.relpath(t, ROOT)
            # Skip self-referential scanner paths (must describe denylist by name).
            if rel_path in SELF_REFERENTIAL_EXEMPT:
                continue
            try:
                with open(t, "r", encoding="utf-8", errors="replace") as f:
                    text = f.read()
            except OSError:
                continue
            # Page-level exemption via frontmatter (applies to .md only).
            if ext.lower() == ".md" and has_neutrality_exempt(text):
                continue
            for i, line in enumerate(text.splitlines(), 1):
                # Line-level exemption: strip sanctioned examples/kahneman/ path
                # references from the line before term matching.
                scrubbed = SANCTIONED_PATH_RE.sub("", line).lower()
                for term in terms:
                    if term in scrubbed:
                        hits.append({"path": rel_path, "line": i, "term": term})
    hits.sort(key=lambda h: (h["path"], h["line"], h["term"]))
    if FORMAT == "json":
        print(json.dumps(hits, indent=2))
    else:
        for h in hits:
            print(f'{h["path"]}:{h["line"]}: {h["term"]}', file=sys.stderr)
    if hits:
        sys.exit(2)
    sys.exit(0)

TOKEN_RE = re.compile(r"\b[A-Za-z][A-Za-z0-9-]{2,}\b")

def tokenize(text):
    out = set()
    for m in TOKEN_RE.findall(text):
        lc = m.lower()
        if len(lc) < 3:
            continue
        if lc in STOPWORDS:
            continue
        out.add(lc)
    return sorted(out)

def parse_frontmatter(text):
    if not text.startswith("---"):
        return None
    end = text.find("\n---", 3)
    if end == -1:
        return None
    return text[3:end].strip()

def source_local_only_wiki():
    # (1) wiki-local/ pages -- ALL pages under wiki-local/ are local-only
    # by structural tier (Phase 15: directory is the classifier, not frontmatter).
    # Phase 15: frontmatter field is stripped; directory IS the classifier.
    results = {}  # path -> token set
    wiki_local_dir = os.path.join(ROOT, "wiki-local")
    if not os.path.isdir(wiki_local_dir):
        return results
    for dirpath, _, filenames in os.walk(wiki_local_dir):
        for fn in filenames:
            if not fn.endswith(".md"):
                continue
            p = os.path.join(dirpath, fn)
            try:
                with open(p, "r", encoding="utf-8", errors="replace") as f:
                    text = f.read()
            except OSError:
                continue
            rel = os.path.relpath(p, ROOT)
            # Tokenize full text (body carries the personal terms).
            results[rel] = tokenize(text)
    return results

def source_planning_notes():
    # (2) .planning/notes/**/*.md
    results = {}
    notes_dir = os.path.join(ROOT, ".planning", "notes")
    if not os.path.isdir(notes_dir):
        return results
    for dirpath, _, filenames in os.walk(notes_dir):
        for fn in filenames:
            if not fn.endswith(".md"):
                continue
            p = os.path.join(dirpath, fn)
            try:
                with open(p, "r", encoding="utf-8", errors="replace") as f:
                    text = f.read()
            except OSError:
                continue
            rel = os.path.relpath(p, ROOT)
            results[rel] = tokenize(text)
    return results

def source_git_history():
    # (3) git log --all -p -- <known-deleted local_only paths>
    paths = [
        "wiki/overviews/personal-decision-patterns.md",
        "wiki/sources/src-2026-04-10-personal-decision-journal.md",
    ]
    # Only run if ROOT is inside a git repo.
    try:
        subprocess.run(
            ["git", "rev-parse", "--is-inside-work-tree"],
            cwd=ROOT, check=True,
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        return {}
    results = {}
    for p in paths:
        try:
            out = subprocess.run(
                ["git", "log", "--all", "--pretty=format:", "-p", "--", p],
                cwd=ROOT, check=False,
                stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                text=True,
            )
        except (subprocess.CalledProcessError, FileNotFoundError):
            continue
        if not out.stdout:
            continue
        # Extract only added lines (start with + but not +++ header lines)
        added = []
        for line in out.stdout.splitlines():
            if line.startswith("+++"):
                continue
            if line.startswith("+"):
                added.append(line[1:])
        text = "\n".join(added)
        if text.strip():
            results[f"git:{p}"] = tokenize(text)
    return results

def source_gitignore():
    if not INCLUDE_GI:
        return {}
    gi = os.path.join(ROOT, ".gitignore")
    if not os.path.isfile(gi):
        return {}
    try:
        with open(gi, "r", encoding="utf-8") as f:
            text = f.read()
    except OSError:
        return {}
    # Conventionally prefix creator-specific lines with `# creator:`
    picked = []
    for line in text.splitlines():
        if line.strip().startswith("# creator:"):
            picked.append(line.split(":", 1)[1])
    if not picked:
        return {}
    return {".gitignore": tokenize("\n".join(picked))}

def suggest():
    groups = []
    for label_fn, fn in [
        ("wiki local_only", source_local_only_wiki),
        ("planning/notes", source_planning_notes),
        ("git history (deleted local_only)", source_git_history),
        ("gitignore creator patterns", source_gitignore),
    ]:
        results = fn()
        for src in sorted(results.keys()):
            groups.append((src, results[src]))
    # Deterministic output: sorted by source path, tokens sorted within.
    for src, tokens in groups:
        print(f"# source: {src}")
        for t in tokens:
            print(t)
        print()
    sys.exit(0)

if SUGGEST:
    suggest()
else:
    scan()
PYEOF
PYRC=$?
set -e

# Re-raise the python exit code.
exit "$PYRC"
