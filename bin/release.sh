#!/usr/bin/env bash
# bin/release.sh -- TMPL-11, D-04: orphan-branch publish via fresh-temp-dir
# allowlist staging. Dry-run default; --apply requires interactive y/N;
# pre-flights check-neutrality.sh against the staged dir.
#
# REVIEWS.md HIGH #1: staging uses an explicit ALLOWLIST copied into a fresh
# temp dir with its own `git init` — NOT worktree mutation of the live repo.
# REVIEWS.md HIGH #5: RELEASE_EMAIL defaults to release@example.invalid
# (reserved .invalid TLD per RFC 2606, unambiguously non-routable).
set -euo pipefail

APPLY=0
REMOTE=""
TAG="v1.1"
RELEASE_EMAIL="${RELEASE_EMAIL:-release@example.invalid}"

# --- ALLOWLIST (REVIEWS.md HIGH #1). ONLY these paths/globs are copied. ---
ALLOWLIST=(
  "README.md"
  "LICENSE"
  "PRIVACY.md"
  "AGENTS.md"
  "CLAUDE.md"
  ".gitignore"
  ".gitattributes"
  ".obsidianignore"
  ".neutrality-denylist.txt"
  "bin"
  "schema"
  "docs"
  ".claude/skills"
  "wiki-cloud/index.md"
  "wiki-cloud/log.md"
  "wiki-cloud/decisions"
  "examples/kahneman"
  ".github"
  ".githooks"
  "tests/phase-07"
  "tests/phase-18"
)

# --- DENYLIST (defense-in-depth). Must never ship; hard-fail if present. ---
DENYLIST_PATHS=(
  ".planning"
  ".brownfield"
  ".git"
  ".obsidian/workspace"
  ".obsidian/cache"
  "wiki-cloud/entities"
  "wiki-cloud/concepts"
  "wiki-cloud/comparisons"
  "wiki-cloud/overviews"
  "wiki-cloud/sources"
  "wiki-cloud/maintenance"
)

usage() {
    cat <<'EOF'
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
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --help|-h) usage; exit 0 ;;
        --remote) REMOTE="${2:-}"; shift 2 ;;
        --tag) TAG="${2:-}"; shift 2 ;;
        --apply) APPLY=1; shift ;;
        --dry-run) APPLY=0; shift ;;
        *) echo "ERROR: unknown argument: $1" >&2; usage >&2; exit 1 ;;
    esac
done

if [ -z "$REMOTE" ]; then
    echo "ERROR: --remote required" >&2
    usage >&2
    exit 1
fi

# --- Plan output (always printed; tests grep these markers) ---
echo "Target remote: $REMOTE"
echo "Tag: $TAG"
echo "Release commit email: $RELEASE_EMAIL"
echo ""
echo "INCLUDES: (allowlist -- ONLY these paths will be copied)"
for p in "${ALLOWLIST[@]}"; do echo "  INCLUDES: $p"; done
echo ""
echo "EXCLUDES: (denylist -- must never ship; hard-fail if found in staged dir)"
for p in "${DENYLIST_PATHS[@]}"; do echo "  EXCLUDES: $p"; done
echo ""

if [ "$APPLY" -eq 0 ]; then
    echo "(dry-run) Pass --apply to execute."
    exit 0
fi

read -r -p "Proceed with publish? [y/N] " resp
case "$resp" in
    y|Y|yes|YES) ;;
    *) echo "Aborted."; exit 0 ;;
esac

# --- ALLOWLIST-BASED FRESH-TEMP-DIR STAGING (REVIEWS.md HIGH #1) ---
REPO_ROOT="$(pwd)"
STAGE="$(mktemp -d -t gsd-release-XXXXXX)"
cleanup() {
    [ -n "${STAGE:-}" ] && [ -d "$STAGE" ] && rm -rf "$STAGE"
}
trap cleanup EXIT INT TERM ERR

echo "Staging dir: $STAGE"

# Copy ONLY allowlisted paths, preserving directory structure.
for p in "${ALLOWLIST[@]}"; do
    if [ -e "$REPO_ROOT/$p" ]; then
        mkdir -p "$STAGE/$(dirname "$p")"
        cp -a "$REPO_ROOT/$p" "$STAGE/$(dirname "$p")/"
    fi
done

# Defense-in-depth: verify denylist paths absent from staged dir.
for dp in "${DENYLIST_PATHS[@]}"; do
    if [ -e "$STAGE/$dp" ]; then
        echo "ERROR: denylist path present in staged dir: $dp" >&2
        exit 2
    fi
done

# Programmatic sweep for privacy: local_only (belt-and-suspenders).
# Match actual frontmatter values only (exact `local_only`, optional trailing
# whitespace/comment) — NOT schema-doc lines like `privacy: local_only|cloud_safe`.
if grep -rIn -E '^privacy:[[:space:]]*local_only[[:space:]]*(#.*)?$' "$STAGE" 2>/dev/null; then
    echo "ERROR: privacy: local_only content found in staged dir" >&2
    exit 2
fi

# Initialize fresh git repo in staged dir (single-commit history — TMPL-11).
cd "$STAGE"
git init --initial-branch=main >/dev/null
git config user.email "$RELEASE_EMAIL"
git config user.name "release"

# Pre-flight neutrality gate against the STAGED dir.
if [ -f .neutrality-denylist.txt ]; then
    if ! bash bin/check-neutrality.sh --root . --denylist .neutrality-denylist.txt; then
        echo "NEUTRALITY PRE-FLIGHT FAILED in staged dir. Aborting." >&2
        exit 2
    fi
else
    echo "ERROR: .neutrality-denylist.txt missing in staged dir" >&2
    exit 2
fi

# CLAUDE.md byte-equality (redundant guard).
if ! bash bin/sync-claude.sh --check; then
    echo "CLAUDE.md drift in staged dir. Aborting." >&2
    exit 2
fi

git add -A
git commit -m "${TAG} release" >/dev/null
git tag "$TAG"
# Tag-only publish: push ONLY the immutable version tag, never main.
# `main` on the remote is a protected, CI-gated PR branch; force-pushing an
# unrelated orphan snapshot onto it would be rejected (and would bypass the
# required status checks). Each release is a self-contained single-commit
# orphan snapshot reachable via its tag — consumers run `git clone --branch
# <tag>` (or `git checkout <tag>`). Pushing the tag uploads the orphan commit's
# objects even though no branch references it. If the tag already exists on the
# remote, the push is rejected (a version is published once) — investigate, do
# not clobber.
git push "$REMOTE" "$TAG"

echo ""
echo "Published tag ${TAG} to $REMOTE (main untouched — protected PR/CI branch)."
echo "Smoke-check: 'git clone --branch ${TAG} --single-branch $REMOTE t && git -C t rev-list --count HEAD' -- must return 1."
