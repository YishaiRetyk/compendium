# src/compendium/release.py -- TMPL-11, D-04: orphan-branch publish via fresh-temp-dir
# allowlist staging. Byte-parity port of bin/release.sh (Phase 25 MIG-04, plan 25-03).
# Dry-run default; --apply requires interactive y/N; pre-flights check-neutrality.sh
# against the staged dir.
#
# REVIEWS.md HIGH #1: staging uses an explicit ALLOWLIST copied into a fresh
# temp dir with its own `git init` — NOT worktree mutation of the live repo.
# REVIEWS.md HIGH #5: RELEASE_EMAIL defaults to release@example.invalid
# (reserved .invalid TLD per RFC 2606, unambiguously non-routable).
import os
import shutil
import subprocess
import sys
import tempfile

# --- ALLOWLIST (REVIEWS.md HIGH #1). ONLY these paths/globs are copied. ---
# Golden-locked: the INCLUDES echo lines freeze this exact order.
# CUT-01 (Phase 25 cutover): "src" + "pyproject.toml" ship because every bin/<tool>.sh
# is now an exec-shim over `python3 -m compendium.<tool>` — a template without src/
# would ship 16 broken tools. "tests/lib" ships because the phase-07/18 suites are
# seam-routed (Phase 24); tests/ported.manifest and tests/freeze-baseline.sha are
# deliberately NOT shipped — their absence makes the seam's HEAD-fallback legal on a
# template checkout (the oracle then runs the checkout's own shims).
ALLOWLIST = (
    "README.md",
    "LICENSE",
    "PRIVACY.md",
    "AGENTS.md",
    "CLAUDE.md",
    ".gitignore",
    ".gitattributes",
    ".obsidianignore",
    ".neutrality-denylist.txt",
    "bin",
    "src",
    "pyproject.toml",
    "schema",
    "docs",
    ".claude/skills",
    "wiki-cloud/index.md",
    "wiki-cloud/log.md",
    "wiki-cloud/decisions",
    "examples/kahneman",
    ".github",
    ".githooks",
    "tests/lib",
    "tests/phase-07",
    "tests/phase-18",
)

# --- DENYLIST (defense-in-depth). Must never ship; hard-fail if present. ---
DENYLIST_PATHS = (
    ".planning",
    ".brownfield",
    ".git",
    ".obsidian/workspace",
    ".obsidian/cache",
    "wiki-cloud/entities",
    "wiki-cloud/concepts",
    "wiki-cloud/comparisons",
    "wiki-cloud/overviews",
    "wiki-cloud/sources",
    "wiki-cloud/maintenance",
)

USAGE = """\
Usage: bin/release.sh --remote <url> [--tag <tag>] [--apply|--dry-run]

Options:
  --remote URL   Target public remote (required)
  --tag TAG      Tag to create (default: v1.1)
  --dry-run      Default; print plan, no mutation
  --apply        Execute after y/N confirmation
  --help, -h     Show this help

Env:
  RELEASE_EMAIL  Email for the single release commit
                 (default: release@example.invalid — reserved .invalid TLD
                  per RFC 2606, unambiguously non-routable)

Staging (REVIEWS.md HIGH #1):
  A fresh temp dir (mktemp -d -t gsd-release-XXXXXX) is created OUTSIDE
  the live repo; only paths in the ALLOWLIST are copied in; a fresh
  `git init` + single commit produces the published history. The staged
  dir is trap-cleaned on EXIT/INT/TERM/ERR. The live working tree is
  never mutated.

Pre-flight (inside the staged dir):
  - bash bin/check-neutrality.sh  (hard-fail on denylist hits)
  - bash bin/sync-claude.sh --check  (hard-fail on AGENTS.md/CLAUDE.md drift)
  - Programmatic sweep for `privacy: local_only` markers (hard-fail)

Publish (tag-only):
  Pushes ONLY the immutable version tag; never main (which is a protected,
  CI-gated PR branch). Each release is a self-contained single-commit orphan
  snapshot reachable via its tag (git clone --branch <tag>). The single-commit
  assertion is tag-scoped: `git rev-list --count <tag>` on the remote MUST
  return 1 (TMPL-11 — REVIEWS.md HIGH #4).

Exit: 0 ok/dry-run/abort, 1 missing args / bad flag, 2 pre-flight failed
"""


def _out(msg):
    sys.stdout.write(msg + "\n")
    sys.stdout.flush()


def _err(msg):
    sys.stderr.write(msg + "\n")
    sys.stderr.flush()


def _usage(stream):
    stream.write(USAGE)
    stream.flush()


def _run(cmd, **kwargs):
    """Run a command with inherited stdio (bash-style passthrough)."""
    sys.stdout.flush()
    sys.stderr.flush()
    return subprocess.run(cmd, **kwargs).returncode


def main(argv=None):
    args = list(sys.argv[1:] if argv is None else argv)
    apply_mode = 0
    remote = ""
    tag = "v1.1"
    release_email = os.environ.get("RELEASE_EMAIL") or "release@example.invalid"

    i = 0
    while i < len(args):
        a = args[i]
        if a in ("--help", "-h"):
            _usage(sys.stdout)
            return 0
        elif a == "--remote":
            remote = args[i + 1] if i + 1 < len(args) else ""
            if i + 2 > len(args):
                return 1  # bash `shift 2` out of range: set -e kills silently
            i += 2
        elif a == "--tag":
            tag = args[i + 1] if i + 1 < len(args) else ""
            if i + 2 > len(args):
                return 1  # bash `shift 2` out of range: set -e kills silently
            i += 2
        elif a == "--apply":
            apply_mode = 1
            i += 1
        elif a == "--dry-run":
            apply_mode = 0
            i += 1
        else:
            _err("ERROR: unknown argument: " + a)
            _usage(sys.stderr)
            return 1

    if not remote:
        _err("ERROR: --remote required")
        _usage(sys.stderr)
        return 1

    # --- Plan output (always printed; tests grep these markers) ---
    _out("Target remote: " + remote)
    _out("Tag: " + tag)
    _out("Release commit email: " + release_email)
    _out("")
    _out("INCLUDES: (allowlist -- ONLY these paths will be copied)")
    for p in ALLOWLIST:
        _out("  INCLUDES: " + p)
    _out("")
    _out("EXCLUDES: (denylist -- must never ship; hard-fail if found in staged dir)")
    for p in DENYLIST_PATHS:
        _out("  EXCLUDES: " + p)
    _out("")

    if apply_mode == 0:
        _out("(dry-run) Pass --apply to execute.")
        return 0

    # bash `read -r -p` prints the prompt (to stderr) only when stdin is a terminal.
    if sys.stdin.isatty():
        sys.stderr.write("Proceed with publish? [y/N] ")
        sys.stderr.flush()
    line = sys.stdin.readline()
    if not line.endswith("\n"):
        return 1  # EOF (with or without partial data): bash read fails, set -e exits 1
    resp = line.strip(" \t\n")  # default-IFS whitespace stripping by `read`
    if resp not in ("y", "Y", "yes", "YES"):
        _out("Aborted.")
        return 0

    # --- ALLOWLIST-BASED FRESH-TEMP-DIR STAGING (REVIEWS.md HIGH #1) ---
    repo_root = os.getcwd()
    stage = tempfile.mkdtemp(prefix="gsd-release-")
    try:
        _out("Staging dir: " + stage)

        # Copy ONLY allowlisted paths, preserving directory structure.
        for p in ALLOWLIST:
            if os.path.exists(repo_root + "/" + p):
                d = os.path.dirname(p) or "."
                os.makedirs(stage + "/" + d, exist_ok=True)
                rc = _run(["cp", "-a", repo_root + "/" + p, stage + "/" + d + "/"])
                if rc != 0:
                    return rc
        # Defense-in-depth: verify denylist paths absent from staged dir.
        for dp in DENYLIST_PATHS:
            if os.path.exists(stage + "/" + dp):
                _err("ERROR: denylist path present in staged dir: " + dp)
                return 2

        # Programmatic sweep for privacy: local_only (belt-and-suspenders).
        # Match actual frontmatter values only (exact `local_only`, optional trailing
        # whitespace/comment) — NOT schema-doc lines like `privacy: local_only|cloud_safe`.
        rc = _run(
            ["grep", "-rIn", "-E",
             "^privacy:[[:space:]]*local_only[[:space:]]*(#.*)?$", stage],
            stderr=subprocess.DEVNULL,
        )
        if rc == 0:  # grep found matches (already printed to stdout)
            _err("ERROR: privacy: local_only content found in staged dir")
            return 2

        # Initialize fresh git repo in staged dir (single-commit history — TMPL-11).
        os.chdir(stage)
        rc = _run(["git", "init", "--initial-branch=main"],
                  stdout=subprocess.DEVNULL)
        if rc != 0:
            return rc
        rc = _run(["git", "config", "user.email", release_email])
        if rc != 0:
            return rc
        rc = _run(["git", "config", "user.name", "release"])
        if rc != 0:
            return rc

        # Pre-flight neutrality gate against the STAGED dir.
        if os.path.isfile(".neutrality-denylist.txt"):
            rc = _run(["bash", "bin/check-neutrality.sh", "--root", ".",
                       "--denylist", ".neutrality-denylist.txt"])
            if rc != 0:
                _err("NEUTRALITY PRE-FLIGHT FAILED in staged dir. Aborting.")
                return 2
        else:
            _err("ERROR: .neutrality-denylist.txt missing in staged dir")
            return 2

        # CLAUDE.md byte-equality (redundant guard).
        rc = _run(["bash", "bin/sync-claude.sh", "--check"])
        if rc != 0:
            _err("CLAUDE.md drift in staged dir. Aborting.")
            return 2

        rc = _run(["git", "add", "-A"])
        if rc != 0:
            return rc
        rc = _run(["git", "commit", "-m", tag + " release"],
                  stdout=subprocess.DEVNULL)
        if rc != 0:
            return rc
        rc = _run(["git", "tag", tag])
        if rc != 0:
            return rc
        # Tag-only publish: push ONLY the immutable version tag, never main.
        # `main` on the remote is a protected, CI-gated PR branch; force-pushing an
        # unrelated orphan snapshot onto it would be rejected (and would bypass the
        # required status checks). Each release is a self-contained single-commit
        # orphan snapshot reachable via its tag — consumers run `git clone --branch
        # <tag>` (or `git checkout <tag>`). Pushing the tag uploads the orphan commit's
        # objects even though no branch references it. If the tag already exists on the
        # remote, the push is rejected (a version is published once) — investigate, do
        # not clobber.
        rc = _run(["git", "push", remote, tag])
        if rc != 0:
            return rc

        _out("")
        _out("Published tag " + tag + " to " + remote
             + " (main untouched — protected PR/CI branch).")
        _out("Smoke-check: 'git clone --branch " + tag + " --single-branch "
             + remote + " t && git -C t rev-list --count HEAD' -- must return 1.")
        return 0
    finally:
        # trap cleanup EXIT INT TERM ERR equivalent.
        if stage and os.path.isdir(stage):
            shutil.rmtree(stage, ignore_errors=True)


if __name__ == "__main__":          # enables `python3 -m compendium.release`
    sys.exit(main(sys.argv[1:]))
