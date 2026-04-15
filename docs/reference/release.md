# Release Runbook (Orphan Branch)

This runbook is the maintainer-invoked path for publishing the neutralized template to a public repo. It uses `bin/release.sh` (shipped in Phase 7 plan 05).

## Prerequisites

- Clean working tree (no uncommitted changes).
- Target public remote configured locally (or accessible via the `--remote` flag).
- Neutrality gate green: `bash bin/check-neutrality.sh` exits 0.
- AGENTS.md / CLAUDE.md byte-equality: `bash bin/sync-claude.sh --check` exits 0.
- All Phase 7 tests green: `bash tests/phase-07/run.sh`.

## What the script publishes

`bin/release.sh` stages a fresh `git init` worktree containing ONLY the public file set:

- AGENTS.md, CLAUDE.md, README.md, LICENSE, PRIVACY.md
- .gitignore, .gitattributes, .obsidianignore
- bin/ (all scripts)
- schema/AGENTS.template.md
- examples/kahneman/** (preserved reference example)
- wiki/index.md, wiki/log.md, wiki/decisions/**
- docs/**
- .github/workflows/neutrality.yml
- .githooks/pre-commit
- .neutrality-denylist.txt

The orphan worktree is `rm -rf .git` + fresh `git init`, producing a single commit with no personal v1.0 history. See PITFALLS.md C-1.

## Dry-run first

```bash
bash bin/release.sh --remote git@github.com:<org>/<repo>.git --dry-run
```

The script prints:
- Target worktree path (`/tmp/gsd-release-<tag>-<pid>`)
- Full file tree it will publish (`find . -type f | sort`)
- Commit message and tag
- Expected refs to push

Review the file list. Confirm no `.planning/`, `.brownfield/`, or `privacy: local_only` content appears.

## Apply

```bash
bash bin/release.sh --remote git@github.com:<org>/<repo>.git --apply
```

The script runs `bin/check-neutrality.sh` as a **pre-flight** against the staged worktree and hard-fails if anything trips. Then it prompts `Proceed with publish? [y/N]`. Typing `y` commits, tags, and pushes.

There is no `--yes` flag in v1.1. Interactive confirmation is required.

## Post-publish smoke check

```bash
git clone git@github.com:<org>/<repo>.git /tmp/smoke && cd /tmp/smoke
grep -rIn -iE '<creator-slug>|<creator-term-1>|<creator-term-2>' AGENTS.md README.md docs/ && echo "LEAK" || echo "Clean"
git log --oneline
```

- Neutrality check should print `Clean`.
- `git log` should show exactly one commit.

## Rollback

On the public remote: delete the branch via the GitHub UI or `git push --delete <remote> main`. Since the template is generated, there is no downstream state to unwind.

## Template upgrades (deferred to v1.2)

Users who fork the template own their fork. Future `bin/upgrade.sh` (v1.2) will provide a migration path for schema bumps. In v1.1, upgrades are manual: users pull from their fork's upstream and resolve conflicts in `AGENTS.md` / `bin/`. Domain content in `wiki/` is never touched by upgrades.
