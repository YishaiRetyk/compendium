# Release Runbook (Orphan Branch)

This runbook is the maintainer-invoked path for publishing the neutralized template to a public repo. It uses `bin/release.sh` (shipped in Phase 7 plan 05).

## Prerequisites

- Clean working tree (no uncommitted changes).
- Target public remote configured locally (or accessible via the `--remote` flag).
- Neutrality gate green: `bash bin/check-neutrality.sh` exits 0.
- AGENTS.md / CLAUDE.md byte-equality: `bash bin/sync-claude.sh --check` exits 0.
- All Phase 7 tests green: `bash tests/phase-07/run.sh`.

## What the script publishes

`bin/release.sh` uses **fresh-temp-dir allowlist staging** (REVIEWS.md HIGH #1): a brand-new directory is created outside the live repo with `mktemp -d`, ONLY allowlisted paths are copied into it, and a fresh `git init` there produces the public history. The live working tree is never mutated.

The allowlist (the ONLY paths that may reach the public repo):

- `AGENTS.md`, `CLAUDE.md`, `README.md`, `LICENSE`, `PRIVACY.md`
- `.gitignore`, `.gitattributes`, `.obsidianignore`, `.neutrality-denylist.txt`
- `bin/` (all scripts)
- `schema/` (including `schema/AGENTS.template.md`)
- `docs/` (four-track skeleton + reference/)
- `wiki/index.md`, `wiki/log.md`, `wiki/decisions/` (decision records only)
- `examples/kahneman/` (preserved reference example)
- `.github/` (workflows, CODEOWNERS, templates)
- `.githooks/` (pre-commit hook)
- `tests/phase-07/` (test harness; later phases add their own)

Explicit **denylist** (defense-in-depth — even if accidentally allowlisted, these must never ship; the script hard-fails if any are found in the staged dir):

- `.planning/`, `.brownfield/`, `.git/`
- `.obsidian/workspace*`, `.obsidian/cache`
- `wiki/entities/`, `wiki/concepts/`, `wiki/comparisons/`, `wiki/overviews/`, `wiki/sources/`
- `wiki/maintenance/`
- Any file with `privacy: local_only` frontmatter (programmatic post-copy sweep)

The staged repo has exactly one commit; this is assertable post-publish via `git rev-list --all --count` (must return `1` — REVIEWS.md HIGH #4, TMPL-11).

## Dry-run first

```bash
bash bin/release.sh --remote git@github.com:<org>/<repo>.git --dry-run
```

The script prints:

- Target remote and tag.
- Release commit email (default `release@example.invalid` — reserved `.invalid` TLD per RFC 2606; override via `RELEASE_EMAIL` env var; REVIEWS.md HIGH #5).
- Full `INCLUDES:` allowlist (one line per entry with the `INCLUDES: ` prefix — assertable by `tests/phase-07/test_release_allowlist.sh`).
- Full `EXCLUDES:` denylist (one line per entry with the `EXCLUDES: ` prefix).
- `(dry-run) Pass --apply to execute.`

Dry-run never creates the staging dir and never mutates anything. It is the default mode; `--apply` is required to execute.

## Apply

```bash
bash bin/release.sh --remote git@github.com:<org>/<repo>.git --apply
```

The script then:

1. Creates `$STAGE=$(mktemp -d -t gsd-release-XXXXXX)` outside the repo.
2. Installs a cleanup trap covering `EXIT INT TERM ERR` so the staged dir is removed on any exit path.
3. Copies each allowlisted path into `$STAGE` (preserving directory structure; never `cp -r .`).
4. Verifies every denylist path is absent in `$STAGE`; hard-fails if any is present.
5. Sweeps `$STAGE` for `privacy: local_only` frontmatter; hard-fails on any hit.
6. Runs `git init --initial-branch=main` + `git config` (user.email = `$RELEASE_EMAIL`, user.name = `release`) in `$STAGE`.
7. **Pre-flights `bin/check-neutrality.sh --root . --denylist .neutrality-denylist.txt` against the staged dir**; hard-fails on denylist hit.
8. Runs `bin/sync-claude.sh --check` inside the staged dir (redundant byte-equality guard).
9. Prompts `Proceed with publish? [y/N]`. Typing anything other than `y`/`Y`/`yes`/`YES` aborts with exit 0.
10. On `y`: `git add -A`, single commit `${TAG} release`, `git tag`, `git push <remote> HEAD:main`, `git push <remote> <tag>`.

There is no `--yes` flag in v1.1. Interactive confirmation is required.

## Post-publish smoke check

```bash
git clone git@github.com:<org>/<repo>.git /tmp/smoke && cd /tmp/smoke

# REVIEWS.md HIGH #4 — single-commit history assertion:
COUNT=$(git rev-list --all --count)
echo "git rev-list --all --count = $COUNT"
[ "$COUNT" -eq 1 ] || { echo "FAIL: expected 1 commit, got $COUNT"; exit 1; }

# Neutrality smoke (use the published denylist categories).
# --exclude=release.md so this very runbook's quoted example command
# doesn't self-match when docs/ is scanned recursively.
grep -rIn -iE '<creator-slug>|<creator-term-1>|<creator-term-2>' --exclude=release.md AGENTS.md README.md docs/ && echo "LEAK" || echo "Clean"

# Denylist-paths-must-be-absent smoke:
for d in .planning .brownfield wiki/entities wiki/concepts wiki/comparisons wiki/overviews wiki/sources wiki/maintenance; do
    [ ! -e "$d" ] && echo "OK absent: $d" || echo "FAIL present: $d"
done

# Allowlist-essentials-must-be-present smoke:
for f in README.md LICENSE AGENTS.md CLAUDE.md PRIVACY.md examples/kahneman; do
    [ -e "$f" ] && echo "OK present: $f" || echo "FAIL absent: $f"
done
```

All three smokes must be green: single commit, clean grep, all allowlist items present, all denylist items absent.

## Rollback

On the public remote: delete the branch via the GitHub UI or `git push --delete <remote> main` (and the tag with `git push --delete <remote> <tag>`). Since the template is generated from the maintainer's live repo via fresh-staging, there is no downstream state to unwind — rerun `bin/release.sh` after fixing whatever tripped the smoke.

## Template upgrades (deferred to v1.2)

Users who fork the template own their fork. Future `bin/upgrade.sh` (v1.2) will provide a migration path for schema bumps. In v1.1, upgrades are manual: users pull from their fork's upstream and resolve conflicts in `AGENTS.md` / `bin/`. Domain content in `wiki/` is never touched by upgrades.
