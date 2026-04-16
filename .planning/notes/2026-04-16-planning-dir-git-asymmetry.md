# .planning/ git handling — resolved 2026-04-16

**Original date:** 2026-04-16 (morning)
**Resolved:** 2026-04-16 (same day, evening)
**Audience:** future template author (me), future Claude sessions working in this repo.

## TL;DR (current state)

`.planning/` is **tracked like any other directory** in this repo. The single source of truth for keeping `.planning/` out of the public template is `bin/release.sh`'s ALLOWLIST staging, verified by `tests/phase-07/test_release_allowlist.sh`. No special `git add -f` / `-u` dance required for new planning files.

## What changed and why

Phase 7's `.gitignore` added `.planning/` as belt-and-suspenders alongside `bin/release.sh` ALLOWLIST. But:

- The ignore rule was **redundant** — `bin/release.sh` only copies ALLOWLIST paths into the staged publish dir. `.planning/` is not in the ALLOWLIST, so it cannot leak at publish time regardless of `.gitignore`.
- The ignore rule was **asymmetric** — `.planning/ROADMAP.md` and ~150 other files were already tracked before the rule was added, creating a `gitignored AND tracked` state that caused daily friction (`git add <new-planning-file>` silently refused; `gsd-tools commit` returned `skipped_gitignored`).
- The ignore rule offered **no benefit to template consumers** either. When someone clicks "Use this template" on `YishaiRetyk/compendium`, they get a 1-commit orphan with zero `.planning/` content. Their first `/gsd-new-project` creates a fresh `.planning/` that they can track normally — which is what they'd want anyway, consistent with every other gsd project.

On 2026-04-16, `.planning/` was removed from `.gitignore` (and the corresponding assertion was removed from `tests/phase-07/test_gitignore.sh`). Ordinary `git add .planning/...` now works. The publish-time filter in `bin/release.sh` is untouched.

## What still protects the public template

1. **`bin/release.sh` ALLOWLIST** (lines defining `INCLUDES` array). Only paths in the allowlist get copied into the staged publish dir. `.planning/` is absent from ALLOWLIST → absent from publish.
2. **`bin/release.sh` EXCLUDES post-copy sweep**. After copying, the script hard-fails if any denylist path (`.planning`, `.brownfield`, `wiki/entities`, etc.) shows up in the staged dir. Catches accidental drift in the ALLOWLIST.
3. **`tests/phase-07/test_release_allowlist.sh`** asserts the dry-run output includes `.planning` in EXCLUDES and excludes it from INCLUDES. Blocks regressions in the staging logic.

If any of those three layers changes, revisit this note.

## Landmines to avoid

- **Never** add `.planning/` to the ALLOWLIST in `bin/release.sh`. It must stay in EXCLUDES. `test_release_allowlist.sh` would fail immediately, but a careless edit that also updates the test is not impossible.
- **Never** `git push --force` from this worktree to `YishaiRetyk/compendium`. The orphan-branch snapshot is the canonical template; force-pushing local `main` would replace it with the full dev history. Unrelated to the `.gitignore` change — the landmine exists regardless — but worth repeating.
- If you ever configure a separate "template upstream" remote, name it something like `template-upstream` to avoid muscle-memory confusion with `origin`.

## Related

- Phase 7 `07-VERIFICATION.md` — TMPL-11 single-commit invariant and ALLOWLIST rationale.
- `bin/release.sh` — the actual publish-time filter (INCLUDES + EXCLUDES).
- `tests/phase-07/test_release_allowlist.sh` — dry-run assertion of INCLUDES/EXCLUDES contract.
- `tests/phase-07/test_gitignore.sh` — inline comment explains why `.planning/` is intentionally absent from the ignore list.
