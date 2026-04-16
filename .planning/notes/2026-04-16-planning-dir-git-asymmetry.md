# .planning/ git asymmetry — local author vs. template consumer

**Captured:** 2026-04-16
**Audience:** future template author (me), future Claude sessions working in this repo.

## TL;DR

`.planning/` is listed in `.gitignore` *and* ~150+ of its files are tracked in the local `main` history. Both are intentional. `bin/release.sh` ALLOWLIST staging keeps `.planning/` out of the public template. The ignore rule is written for template consumers, not the author.

## What's actually going on

| Context | Behavior |
|---|---|
| `.gitignore` line 10 | `.planning/` — shipped with the public template so consumers' fresh ingests land in an ignored dir by default. |
| Pre-existing tracked files (`ROADMAP.md`, `phases/**/*`, `PROJECT.md`, this note's sibling `2026-04-09-agents-md-size-risk.md`) | Tracked *before* the ignore rule was added in Phase 7. Git keeps tracking them until a `git rm --cached`. |
| New files under `.planning/` (created during planning sessions) | Blocked by the ignore rule. `git add <path>` refuses with a hint; `git add -f <path>` or `git add -u <path>` (for modifications of already-tracked files) bypasses. |
| `bin/release.sh --apply` ALLOWLIST staging | `.planning/` is in the EXCLUDES list — it never reaches the published orphan-branch commit. |
| Public template repo (`YishaiRetyk/compendium`) | A 1-commit orphan. Zero `.planning/` content. Consumers clone clean. |
| Local `main` (`/home/yishai/Documents/compendium`) | Carries the full planning history. Diverged from the public template after the 2026-04-16 re-publish. |

## Day-to-day friction for the author

- `git add .planning/<path>` on a new file silently refuses. Use `git add -f` for new files or `git add -u` for modifications.
- `gsd-tools commit --files .planning/...` returns `skipped_gitignored` when the file list contains an untracked `.planning/` path. Workaround: either pre-create the file and use `git add -f` manually, or drop `.planning/` paths from the `--files` list and rely on `-u` on already-tracked ones.
- Don't push local `main` to the public template remote. It has unrelated histories; the push would be rejected anyway, but a `--force` from muscle memory would clobber the orphan snapshot. If you need a separate tracking remote for dev work, name it something other than `origin` to avoid ambiguity.

## If this ever becomes painful

Three options ranked by blast radius:

1. **Leave as-is.** Works today; friction is low.
2. **Untrack `.planning/` in local main.** `git rm --cached -r .planning/ && git commit`. Future planning work stops appearing in `git log`. Filesystem is unchanged; gsd tooling keeps working (it reads the FS, not the index).
3. **Split remotes explicitly.** Configure a named `template-upstream` remote that only ever receives `bin/release.sh --apply` pushes. Keep `origin` (or a private mirror) for the dev repo. Prevents accidental full-history pushes.

## Landmines to avoid

- **Never** `git push --force` from this worktree to `YishaiRetyk/compendium`. The orphan-branch snapshot is the canonical template; force-pushing local `main` would replace it with 200+ commits of planning history, re-creating the bug that triggered the 2026-04-16 re-publish.
- **Never** add `.planning/` to an ALLOWLIST path in `bin/release.sh`. It must stay in EXCLUDES.
- When adding new `.planning/` files (new phases, notes), use `git add -f` if you want them tracked alongside the existing planning history. If you're ambivalent, leave them untracked — they still serve their purpose in the working tree for gsd tooling.

## Related

- Phase 7 `07-VERIFICATION.md` — TMPL-11 single-commit invariant and ALLOWLIST rationale.
- `bin/release.sh` — the actual publish-time filter.
- `.gitignore` lines 8–10 — the ignore rule with its author comment.
