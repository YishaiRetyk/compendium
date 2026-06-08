# Claude Code Skills Overlay

This document describes the four Claude Code skill routers shipped with the wiki compiler
schema. Skill files are **generated**, not hand-authored — do not edit them directly.

The four skills provide ergonomic access to the core wiki operations (ingest, query, lint,
reflect) in Claude Code. When invoked, each skill dispatches to its corresponding workflow
file (`schema/workflows/{op}.md`), which remains the sole authoritative source for behavior.

## How skills are generated

The generator `bin/gen-skills.sh` produces all four skill files from a single parameterized
body template and four inline description strings. Re-running the generator overwrites the
files identically (idempotent).

```bash
bash bin/gen-skills.sh           # generate / regenerate all four SKILL.md files
bash bin/gen-skills.sh --check   # drift check: exits 0 on match, 1 on any drift
```

### Two-layer Source-of-Truth model

| Layer | Source of truth | The SKILL.md file |
|-------|-----------------|-------------------|
| **Behavior** | `schema/workflows/{op}.md` | pointer only — zero behavior encoded |
| **Artifact text** (bytes) | `bin/gen-skills.sh` template + description data | generated copy, --check guarded |

This mirrors the existing `AGENTS.md → CLAUDE.md` generated-artifact relationship.
Hand-editing a `SKILL.md` file is prohibited; the `--check` gate will detect and reject it.

## The four skills

| Operation | Skill path | Behavioral source of truth |
|-----------|-----------|---------------------------|
| ingest | `.claude/skills/ingest/SKILL.md` | `schema/workflows/ingest.md` |
| query | `.claude/skills/query/SKILL.md` | `schema/workflows/query.md` |
| lint | `.claude/skills/lint/SKILL.md` | `schema/workflows/lint.md` |
| reflect | `.claude/skills/reflect/SKILL.md` | `schema/workflows/reflect.md` |

Each skill directory contains **only** `SKILL.md`. Claude Code loads all `.md` files in a
skill directory at Level-2 scope — extra files would inflate context unexpectedly.

## Modifying a skill

To change a skill's description or body:

1. Edit `bin/gen-skills.sh` — update the `get_desc()` case for the relevant op (description)
   or the `body_for()` heredoc template (body).
2. Run `bash bin/gen-skills.sh` to regenerate.
3. Run `bash bin/gen-skills.sh --check` to verify the committed files match.
4. Stage and commit: `git add .claude/skills/ && git commit`.

Do **not** edit `SKILL.md` files directly. The `--check` gate rejects hand-edits.

## Drift gate

The `--check` gate runs in two places:

| Location | Behavior on drift |
|----------|-------------------|
| `.githooks/pre-commit` | Auto-regenerates, re-stages, asks you to re-run commit |
| CI `lint.yml` `skills-check` job | Hard-fails the PR — no auto-fix |

The gate checks two things:
- **Regenerate-diff**: regenerates all four files to a temp dir and compares byte-for-byte
  with the committed files using `cmp -s`.
- **Structural assertions**: independently verifies each SKILL.md body is ≤3 post-frontmatter
  lines, each skill dir contains only `SKILL.md`, no description contains a first-person
  pronoun, and `disable-model-invocation: true` is absent.

The structural assertions are not redundant with the regenerate-diff — a fattened template
(with procedural content in the body template) would still pass diff but fail the line-count
assertion.

## Adopter notes

The four `SKILL.md` files are **committed** to the repository (not gitignored). Claude Code
discovers skills from the filesystem at session start and cannot lazily materialize them, so
a fresh clone must have the files present. The `.gitignore` ignores `.claude/` content with a
`.claude/*` file-glob and then re-includes the skills with explicit negation lines
(`!.claude/skills/`, `!.claude/skills/*/`, and `!.claude/skills/*/SKILL.md`). The file-glob
form is required: a `.claude/` *directory* ignore cannot be negated for descendants, so the
skill files would stay invisible to git under the directory-ignore form.

When adopting this template for a new vault, the generated skill files are included
automatically. If you regenerate (e.g., after updating `bin/gen-skills.sh` descriptions),
re-stage and commit the updated SKILL.md files.
