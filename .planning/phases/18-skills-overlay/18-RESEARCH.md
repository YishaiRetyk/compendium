# Phase 18: Skills Overlay - Research

**Researched:** 2026-06-08
**Domain:** Claude Code Agent Skills (SKILL.md format) + Bash generator with `--check` drift gate
**Confidence:** HIGH

## Summary

Phase 18 is a deterministic-generator phase with exceptionally low ambiguity (SPEC score 0.12). All four behavioral source-of-truth files (`schema/workflows/{ingest,query,lint,reflect}.md`) exist and are confirmed non-empty (77, 121, 160, 80 lines respectively). The `.claude/skills/` directory does not yet exist. The generator pattern to implement (`bin/gen-skills.sh`) is a structural twin of `bin/sync-claude.sh` — a pure-bash, zero-dep idempotent emitter with a `--check` regenerate-diff + structural-assertion mode.

One infrastructure prerequisite the SPEC does not call out explicitly: `.gitignore` line 8 currently ignores the entire `.claude/` directory (`!.claude/settings.cloud.json` being the only exception). The `SKILL.md` files must be committed (SPEC requirement 6 / Source-of-Truth Model), so `.gitignore` must be updated to add `!.claude/skills/` and `!.claude/skills/**` before `git add` will track them. This is a mandatory Wave 0 task.

The wiki evidence confirms all SKILL.md authoring rules (third-person what+when descriptions, ≤1024 chars, forward-slash paths, only one `.md` per skill directory at L2 load scope). The description field carries the full discovery load at L1 (~100 tokens/skill). The body template is already canonically specified in SPEC/CONTEXT: `"You have been invoked to {op}. Read \`schema/workflows/{op}.md\` and follow it verbatim."` — exactly three lines (blank frontmatter fence + 1 body line = ≤3 lines when frontmatter separator lines are excluded from the body count per SPEC intent, or a single-line body with frontmatter block).

**Primary recommendation:** Implement `bin/gen-skills.sh` as a direct structural clone of `bin/sync-claude.sh` — associative array for `DESC[]`, heredoc body template, `--check` that regenerates to `mktemp` and uses `cmp`/diff, plus independent structural assertions (≤3 body lines, dir-purity, no first-person pronoun, no `disable-model-invocation: true`). Wire it into `.githooks/pre-commit` between the existing `sync-claude --check` and `lint --strict --staged` steps; add a hard-fail CI step in `lint.yml`. Fix `.gitignore` first.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** All generator inputs live inline in `bin/gen-skills.sh` — a pure-bash associative array `DESC[<op>]="<description>"` for the four per-op description strings, plus a heredoc body template parameterized by `{op}`. Zero external deps, single file = single artifact source-of-truth, mirrors `bin/sync-claude.sh`'s zero-dep minimalism. No separate `schema/skills/` template file or data manifest.
- **D-02:** The op list is the fixed quartet `ingest query lint reflect`, iterated in the script. Adding/removing ops is a deliberate code edit to this list (not config-driven).
- **D-03:** `gen-skills.sh --check` runs in two places: (a) `.githooks/pre-commit` — inserted immediately AFTER the existing `sync-claude --check` step and BEFORE the `lint --strict --staged` write-gate; (b) a CI check in `.github/workflows/lint.yml` that hard-fails the PR on drift.
- **D-04:** Pre-commit drift behavior mirrors `sync-claude` exactly: on drift, regenerate the skill files, `git add` them, print "skills resynced and re-staged — re-run commit", and `exit 1` (auto-fix + ask-to-rerun). CI behavior is hard-fail only (no auto-fix in CI).
- **D-05:** `--check` exit semantics follow `sync-claude`: `0` = OK, non-zero = drift. Pure `cmp`/diff-based, zero deps.
- **D-06:** `gen-skills.sh --check` performs BOTH the regenerate-diff AND independent structural assertions (all inside the one script, no separate lint category): each `SKILL.md` body is ≤3 lines; each skill directory contains only `SKILL.md`; each `description` contains no first-person pronoun (`I`, `I'll`, `we`); model-invocation is not disabled.
- **D-07:** Rationale for the independent asserts (not diff-only): a fattened template would still pass a pure regenerate-diff (committed == fattened-template), so the structural asserts are the real guard that the template itself stays thin.
- **D-08:** No line is added to the resident `AGENTS.md`/`CLAUDE.md` core. Skills are pointers, not authoritative content.
- **D-09:** Author a decision record `wiki-cloud/decisions/dr-2026-06-08-skills-overlay.md` (trigger_type: schema-update or equivalent) recording the overlay rationale, two-layer SOT model, and model-invocation choice; register in `wiki-cloud/index.md`.
- **D-10:** Add `.claude/skills/` to `bin/check-neutrality.sh`'s scanned template-public surface.
- **D-11:** Document the overlay for adopters in `docs/reference/skills.md` — end-user-facing, explaining what the skills are, that they're generated, and that `SKILL.md` files are not hand-edited.

### Claude's Discretion

- Exact wording of the per-op `description` strings (third-person, what+when, tight ~1–2 sentences) — planner/executor drafts them; the SPEC's authoring rules constrain them.
- Exact filename of the docs page (`docs/reference/skills.md` suggested) and the DR slug date-stamp.
- Whether the structural asserts emit one aggregated error or per-file errors (UX detail).

### Deferred Ideas (OUT OF SCOPE)

- Skills for `audit` / `brownfield` / `release` / `structured-operations`, and convenience skills (`author-wiki-page`, `validate-frontmatter`) — out of scope by SPEC; revisit only if a future phase justifies expanding the overlay.
- Wizard/installer materializing `.claude/skills/` in an adopter's repo — deferred to the release/template-shipping workstream.
- A `bin/sync-claude.sh --check-tree` that diffs the whole `schema/` tree (raised in CONTEXT-NOTES rec #8) — broader schema-drift tooling, not this phase.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SKILL-01 | Thin `.claude/skills/` wrappers for ingest/query/lint/reflect; each body ≤ 3 lines, pointer-only ("You have been invoked to {op}. Read `schema/workflows/{op}.md` and follow it verbatim.") | Generator emits from heredoc template; body line-count assertion in `--check` (D-06) enforces this mechanically |
| SKILL-02 | Skills add zero authoritative content (routers only); markdown remains the source of truth. Verify no behavior is encoded in a skill that isn't in the workflow file. | Two-layer SOT model: behavioral SOT = `schema/workflows/{op}.md`; artifact SOT = generator template; `--check` gate enforces; structural asserts in generator catch fattened templates (D-07) |

</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Skill file generation | Build tooling (`bin/gen-skills.sh`) | — | Generator owns the artifact bytes; workflow files own the behavior |
| Drift enforcement (local) | Pre-commit hook (`.githooks/pre-commit`) | — | Same layer as `sync-claude --check`; mirrors established repo idiom |
| Drift enforcement (CI) | CI workflow (`.github/workflows/lint.yml`) | — | Hard-fail gate; no auto-fix in CI, consistent with other CI checks |
| Behavioral source of truth | `schema/workflows/{op}.md` | — | Each file is the normative procedure; skills only point to it |
| Artifact source of truth | `bin/gen-skills.sh` (template + DESC data) | — | Generator template is the authoritative byte recipe; committed SKILL.md files are derived copies |
| Discovery / model invocation | SKILL.md frontmatter `description` field (L1 metadata) | — | Always-loaded ~100 tok/skill; carries what+when signal for skill selection by model |
| Neutrality gate | `bin/check-neutrality.sh` (extended) | — | `.claude/skills/` must join the scanned public template surface (D-10) |
| Adopter documentation | `docs/reference/skills.md` | — | End-user-facing explanation; describes generated nature, not hand-edited |
| Governance record | `wiki-cloud/decisions/dr-2026-06-08-skills-overlay.md` | — | DR captures the two-layer SOT model and model-invocation choice |

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| bash | system (≥4.0) | Generator + `--check` implementation | Mirrors `bin/sync-claude.sh`; zero external deps; idiomatic for this repo's `bin/` scripts [VERIFIED: codebase grep] |
| `cmp -s` | POSIX | Byte-comparison for drift detection in `--check` | Used by `sync-claude.sh` for byte-identical check; zero deps [VERIFIED: bin/sync-claude.sh] |
| `mktemp -d` | POSIX | Temp directory for `--check` regeneration | Standard bash temp-file pattern; no external deps [ASSUMED] |
| `git add` | repo | Re-staging in pre-commit auto-fix path | Used in existing pre-commit hook auto-fix pattern [VERIFIED: .githooks/pre-commit] |

### SKILL.md Frontmatter Fields

| Field | Required | Constraint | Source |
|-------|----------|------------|--------|
| `name` | Yes | ≤64 chars, lowercase letters/numbers/hyphens, no XML tags, no reserved words `anthropic`/`claude` | [VERIFIED: wiki-cloud/overviews/agent-skills.md Key Facts] |
| `description` | Yes | ≤1024 chars, non-empty, no XML tags, third-person, what+when, no first-person pronoun | [VERIFIED: wiki-cloud/sources/src-2026-05-06-anthropic-agent-skills-best-practices.md] |
| `disable-model-invocation` | NO (excluded) | Must NOT be `true` — model invocation is explicitly allowed (SPEC §5, D-05 context) | [VERIFIED: 18-SPEC.md requirement 5] |

**Installation:** No package installation. Generator creates directories and files via pure bash.

**Version verification:** N/A — no npm/pip packages. bash and POSIX utilities are already present. [VERIFIED: codebase structure]

## Architecture Patterns

### System Architecture Diagram

```
bin/gen-skills.sh (generator)
    DESC[ingest]="..."   ─────────────────────────────────────────────────────┐
    DESC[query]="..."                                                          │
    DESC[lint]="..."                                                           │
    DESC[reflect]="..."                                                        │ generate
    heredoc body template                                                      │
         │                                                                     ▼
         │                        .claude/skills/
         │                        ├── ingest/SKILL.md  ─────────────── (derived, committed)
         │                        ├── query/SKILL.md   ─────────────── (derived, committed)
         │                        ├── lint/SKILL.md    ─────────────── (derived, committed)
         │                        └── reflect/SKILL.md ─────────────── (derived, committed)
         │
         │ --check
         ├── regenerate → mktemp/
         ├── cmp each committed vs regenerated  ── EXIT 0 (match) / EXIT non-zero (drift)
         └── structural assertions:
               ≤3 body lines per file
               only SKILL.md in each dir
               no first-person in description
               no disable-model-invocation:true


.githooks/pre-commit
    [1] bash bin/sync-claude.sh --check   ── auto-fix CLAUDE.md drift + restage
    [2] bash bin/gen-skills.sh --check    ── auto-fix skill drift + restage  (NEW D-03)
    [3] bash bin/lint.sh --strict --staged ── write-gate on provenance


.github/workflows/lint.yml
    job: lint   (existing)
    job: privacy-leak  (existing)
    job: strict  (existing)
    job: skills-check  (NEW D-03/D-04)
        run: bash bin/gen-skills.sh --check  ── hard-fail, no auto-fix


schema/workflows/ingest.md   ◀── SKILL.md body points here  (behavioral SOT)
schema/workflows/query.md    ◀── SKILL.md body points here
schema/workflows/lint.md     ◀── SKILL.md body points here
schema/workflows/reflect.md  ◀── SKILL.md body points here


Claude Code session start:
    reads .claude/skills/ingest/SKILL.md   → L1: name + description preloaded into system prompt
    reads .claude/skills/query/SKILL.md    → L1 (~100 tok/skill × 4 = ~400 tok total)
    ...
    On trigger: L2 body loaded → "Read schema/workflows/{op}.md and follow it verbatim."
    → model reads schema/workflows/{op}.md (behavioral SOT)
```

### Recommended Project Structure

```
.claude/skills/           # NEW: project-scoped Claude Code skills
├── ingest/
│   └── SKILL.md          # ONLY file in dir (L2 loads all top-level .md)
├── query/
│   └── SKILL.md
├── lint/
│   └── SKILL.md
└── reflect/
    └── SKILL.md

bin/
└── gen-skills.sh         # NEW: deterministic generator + --check gate
```

### Pattern 1: gen-skills.sh Script Structure (mirrors sync-claude.sh)

**What:** Pure-bash generator with `--check` mode, idempotent re-run, zero deps

**When to use:** Creating or drift-checking all four SKILL.md files from the single template

**Example (structural skeleton):**

```bash
#!/usr/bin/env bash
# bin/gen-skills.sh -- deterministic skill generator + --check drift gate.
# Mirrors bin/sync-claude.sh: zero deps, idempotent, CHECK_ONLY flag.
# ARTIFACT SOT: this script (template + DESC data). DO NOT hand-edit SKILL.md files.
set -euo pipefail

CHECK_ONLY=0

# Per-op description strings (D-01: inline associative array)
declare -A DESC
DESC[ingest]="..."    # third-person, what+when, ≤1024 chars
DESC[query]="..."
DESC[lint]="..."
DESC[reflect]="..."

OPS=(ingest query lint reflect)   # D-02: fixed quartet

while [ "$#" -gt 0 ]; do
    case "$1" in
        --check) CHECK_ONLY=1; shift ;;
        --help|-h) echo "Usage: bin/gen-skills.sh [--check]"; exit 0 ;;
        *) echo "ERROR: unknown arg: $1" >&2; exit 1 ;;
    esac
done

# body_for <op> -- emit the SKILL.md content for one op
body_for() {
    local op="$1"
    cat <<EOF
---
name: ${op}
description: ${DESC[$op]}
---

You have been invoked to ${op}. Read \`schema/workflows/${op}.md\` and follow it verbatim.
EOF
}

if [ "$CHECK_ONLY" -eq 1 ]; then
    TMPDIR=$(mktemp -d)
    trap 'rm -rf "$TMPDIR"' EXIT
    DRIFT=0

    for op in "${OPS[@]}"; do
        body_for "$op" > "$TMPDIR/${op}-SKILL.md"
        committed=".claude/skills/${op}/SKILL.md"
        if [ ! -f "$committed" ]; then
            echo "DRIFT: $committed missing" >&2; DRIFT=1; continue
        fi
        if ! cmp -s "$TMPDIR/${op}-SKILL.md" "$committed"; then
            echo "DRIFT: $committed differs from template" >&2; DRIFT=1
        fi
    done

    # D-06: independent structural assertions
    for op in "${OPS[@]}"; do
        dir=".claude/skills/${op}"
        skill="$dir/SKILL.md"
        [ -f "$skill" ] || continue

        # Assert ≤3 body lines (lines after closing frontmatter ---)
        body_lines=$(awk '/^---/{n++; if(n==2){found=1; next}} found{print}' "$skill" | wc -l)
        if [ "$body_lines" -gt 3 ]; then
            echo "ASSERT FAIL: $skill body has $body_lines lines (max 3)" >&2; DRIFT=1
        fi

        # Assert only SKILL.md in the dir (L2 loads all top-level .md)
        extra=$(find "$dir" -maxdepth 1 -name "*.md" ! -name "SKILL.md" | wc -l)
        if [ "$extra" -gt 0 ]; then
            echo "ASSERT FAIL: $dir contains extra .md files (L2 purity)" >&2; DRIFT=1
        fi

        # Assert no first-person pronoun in description
        desc_val=$(awk '/^description:/{print}' "$skill")
        if echo "$desc_val" | grep -qiE '\b(I|I'\''ll|we)\b'; then
            echo "ASSERT FAIL: $skill description contains first-person pronoun" >&2; DRIFT=1
        fi

        # Assert disable-model-invocation:true is NOT present
        if grep -q 'disable-model-invocation: *true' "$skill"; then
            echo "ASSERT FAIL: $skill has disable-model-invocation:true" >&2; DRIFT=1
        fi
    done

    if [ "$DRIFT" -eq 0 ]; then
        echo "OK: .claude/skills/ matches template + structural assertions pass"
        exit 0
    fi
    exit 1
fi

# Generate mode: write all four SKILL.md files
for op in "${OPS[@]}"; do
    dir=".claude/skills/${op}"
    mkdir -p "$dir"
    body_for "$op" > "$dir/SKILL.md"
    echo "Generated $dir/SKILL.md"
done
```

**Source:** [VERIFIED: bin/sync-claude.sh structure, 18-SPEC.md, 18-CONTEXT.md D-01..D-07]

### Pattern 2: Pre-Commit Hook Insertion (mirrors existing sync-claude block)

**What:** Auto-fix drift and restage; `exit 1` to ask-to-rerun

**Example (addition to `.githooks/pre-commit` after sync-claude block):**

```bash
# Phase 18 / SKILL-02: gen-skills drift gate (D-03, D-04)
# Skills are committed generated artifacts; auto-fix + restage mirrors sync-claude pattern.
if ! bash bin/gen-skills.sh --check 2>/dev/null; then
    echo "Skills drift detected. Auto-regenerating..." >&2
    bash bin/gen-skills.sh
    git add .claude/skills/
    echo "Skills resynced and re-staged. Re-run commit." >&2
    exit 1
fi
```

**Source:** [VERIFIED: .githooks/pre-commit existing sync-claude block, 18-CONTEXT.md D-04]

### Pattern 3: SKILL.md File Format (canonical form)

**What:** Minimal frontmatter + single-line pointer body

**Example (ingest skill):**

```yaml
---
name: ingest
description: <third-person what+when description, ≤1024 chars>
---

You have been invoked to ingest. Read `schema/workflows/ingest.md` and follow it verbatim.
```

**Body line count:** The YAML frontmatter block (lines 1–3 `---`) is not body content. The body is the content AFTER the closing `---`. The canonical form has exactly 2 body lines: one blank line + one pointer line = 2 lines total. Well within the ≤3 line constraint.

**Source:** [VERIFIED: 18-SPEC.md requirement 4, 18-CONTEXT.md `<specifics>`, wiki-cloud/sources/src-2026-05-06-anthropic-agent-skills-best-practices.md Key Facts]

### Pattern 4: CI Hard-Fail Step (addition to lint.yml)

**What:** A new CI job that runs `gen-skills.sh --check` with hard-fail, no auto-fix

**Example (new job in `.github/workflows/lint.yml`):**

```yaml
  skills-check:
    # D-03 / D-04: gen-skills --check hard-fail gate. CI never auto-fixes.
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - name: Skills drift + structural assertions (SKILL-02)
        run: bash bin/gen-skills.sh --check
```

**Source:** [VERIFIED: .github/workflows/lint.yml existing job pattern, 18-CONTEXT.md D-03/D-04]

### Anti-Patterns to Avoid

- **Encoding workflow steps in SKILL.md body:** the body is a pointer only; any rule, step, default, or branch absent from `schema/workflows/{op}.md` violates SKILL-02. Grep for imperative/procedural verbs in skill bodies as a desk-check.
- **Multiple `.md` files in a skill directory:** Claude Code L2 loads ALL top-level `.md` files; extras inflate context unexpectedly. Only `SKILL.md` permitted. The `--check` dir-purity assertion catches this.
- **Using `--check` exit code 0/non-zero without also running structural assertions:** a fattened template passes regenerate-diff but fails structural asserts. D-07 is load-bearing — never remove the independent structural asserts as "redundant with diff".
- **Hand-editing a committed `SKILL.md`:** The files are derived artifacts. Changes go to the generator template/description data, then regenerate. `--check` will reject a hand-edited file.
- **Gitignored SKILL.md files:** The `.claude/` directory is currently gitignored. Without explicit `.gitignore` exceptions, `git add` will silently drop the skill files. Claude Code discovers skills from the filesystem at session start — a gitignored file is invisible on clone. [VERIFIED: .gitignore line 8, SPEC requirement 6]
- **First-person pronouns in descriptions:** "I can help you ingest" is wrong. "Processes a new source into wiki pages" is correct. The `--check` assertion catches this.
- **Using Windows-style backslash paths:** `schema\workflows\ingest.md` fails on Unix. Use `schema/workflows/ingest.md`. [VERIFIED: wiki-cloud/sources/src-2026-05-06-anthropic-agent-skills-best-practices.md Key Facts]
- **Setting `disable-model-invocation: true`:** explicitly declined (SPEC §5); model invocation is allowed and the `description` field carries the discovery load. [VERIFIED: 18-SPEC.md requirement 5]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Byte comparison for drift | Custom string diff logic | `cmp -s` (POSIX) | Zero deps, already used in `sync-claude.sh`; exact byte equality is the right bar [VERIFIED: bin/sync-claude.sh] |
| Temp directory for `--check` | Persistent `/tmp/gen-skills-*` files | `mktemp -d` + `trap 'rm -rf "$TMPDIR"' EXIT` | Clean teardown; avoids stale temp files interfering with subsequent checks [ASSUMED] |
| Description field validation | Separate lint category | Inline structural assert in `--check` | D-06 specifies all assertions inside the one script; avoids the overhead of a new lint category; simpler single-file artifact [VERIFIED: 18-CONTEXT.md D-06] |
| Skills for additional operations | Extra `SKILL.md` files for audit/brownfield/release | Nothing — out of scope | Minimalism precedent (Phase 8 WZRD-07/D-02); 4 core ops only [VERIFIED: 18-SPEC.md Boundaries] |

**Key insight:** The repo's established generated-artifact + `--check` idiom (`sync-claude.sh`) already solves the pattern. `gen-skills.sh` is its structural twin; reuse the mental model and UX verbatim rather than inventing a new one.

## Critical Pre-Condition: .gitignore Update

**This is not in SPEC but is a blocking prerequisite.**

[VERIFIED: .gitignore lines 8-9]

The current `.gitignore` contains:
```
.claude/
!.claude/settings.cloud.json
```

This ignores ALL contents of `.claude/` except `settings.cloud.json`. The SKILL.md files at `.claude/skills/{op}/SKILL.md` will be gitignored by default. Git's behavior with negation patterns: to un-ignore files inside an ignored directory, you must un-ignore both the intermediate directory AND the files.

**Required addition to `.gitignore`:**
```
.claude/
!.claude/settings.cloud.json
!.claude/skills/
!.claude/skills/**
```

The `!.claude/skills/` un-ignores the directory itself; `!.claude/skills/**` un-ignores all files and subdirectories within it.

**Why this matters:** SPEC requirement 6 mandates "the four `SKILL.md` files are tracked by git (committed, not gitignored)." Claude Code discovers skills from the filesystem at session start — it cannot lazily materialize them — so a fresh clone must have them present. Without the `.gitignore` fix, `bash bin/gen-skills.sh && git add .claude/skills/` silently adds nothing to the index, breaking the committed-artifact invariant.

**Ordering:** The `.gitignore` fix is Wave 0 — must land before the generator creates files, or the generator run will succeed but files won't be track-able.

## Common Pitfalls

### Pitfall 1: Forgetting the .gitignore Exception

**What goes wrong:** `bin/gen-skills.sh` runs without error, files appear on disk, `git add .claude/skills/` silently stages nothing, committed tree has no SKILL.md files, fresh clone is missing skills.
**Why it happens:** `.gitignore` line 8 (`!.claude/`) ignores the whole `.claude/` directory. The existing exception for `settings.cloud.json` uses file-level negation. Skills are in a subdirectory and need both directory-level AND glob-level negations.
**How to avoid:** Add `!.claude/skills/` and `!.claude/skills/**` to `.gitignore` before running the generator. Verify with `git ls-files .claude/skills/` — should list all four SKILL.md files.
**Warning signs:** `git status` shows nothing after running `bash bin/gen-skills.sh`. The files exist on disk but `git status` is silent.

### Pitfall 2: Structural Assertions "Simplified" Away as Redundant

**What goes wrong:** A future maintainer sees that `--check` already does regenerate-diff and removes the structural assertions as "redundant" — now a fattened template (with procedural content in the body) passes `--check` because committed == fattened-template.
**Why it happens:** The structural asserts exist specifically to catch fattened templates, not just hand-edited committed files. The two checks serve different failure modes (D-07). The relationship between them is non-obvious without the D-07 comment.
**How to avoid:** Add an explicit comment in `gen-skills.sh` citing D-07: "These structural assertions are NOT redundant with the regenerate-diff check. A fattened template still passes diff (committed == fattened-template). Assertions are the real guard."
**Warning signs:** Someone PR-comments "these assertions look redundant since we already diff against the template."

### Pitfall 3: Body Line Count Ambiguity

**What goes wrong:** Confusion about whether the YAML frontmatter separator lines (`---`) count toward the "≤3 lines" body constraint.
**Why it happens:** SPEC says "each `SKILL.md` body is ≤3 lines" but the file starts with a frontmatter block. "Body" could be interpreted as the whole file or only the post-frontmatter content.
**How to avoid:** SPEC requirement 4 clarifies: "each body is at most 3 lines and contains only the pointer form." The canonical form is 2 post-frontmatter lines (one blank + one pointer), comfortably under 3. The `--check` assertion should count lines after the closing `---` of frontmatter.
**Warning signs:** The assertion script counts total file lines instead of post-frontmatter lines and produces false failures on files with frontmatter.

### Pitfall 4: L2 Contamination via Extra .md Files

**What goes wrong:** An extra `.md` file (e.g., `NOTES.md`, `README.md`) lands in a skill directory, adding its full content to Claude's context every time that skill fires.
**Why it happens:** Claude Code L2 loads ALL `.md` files in the skill's top-level directory, not just `SKILL.md`. [VERIFIED: wiki-cloud/concepts/progressive-disclosure.md Key Facts, Detail section "Level 2 includes all top-level markdown"]
**How to avoid:** Directory-purity assertion in `--check` (D-06): `find ".claude/skills/${op}" -maxdepth 1 -name "*.md" ! -name "SKILL.md"` must return empty. Treat any match as a drift failure.
**Warning signs:** `--check` passes diff but the CI job for a future phase adds a `NOTES.md` alongside `SKILL.md` — the assertions are the only guard.

### Pitfall 5: check-neutrality.sh Does Not Cover .claude/skills/

**What goes wrong:** A description string accidentally includes a private vault term (a denylist hit) — `check-neutrality.sh` in CI doesn't catch it because `.claude/skills/` isn't in its scanned `PUBLIC_PATHS`.
**Why it happens:** `PUBLIC_PATHS` in `bin/check-neutrality.sh` line 94 is a hardcoded array: `(AGENTS.md CLAUDE.md README.md PRIVACY.md docs .github wiki-cloud bin schema)`. `.claude/` is not listed.
**How to avoid:** D-10 requires adding `.claude/skills/` to the `PUBLIC_PATHS` array. The generator produces pointer bodies + workflow paths that contain no private terms by construction, but the `description` strings are authored text and need the scan as a backstop. [VERIFIED: bin/check-neutrality.sh line 94]
**Warning signs:** Neutrality CI passes but a description contains a personal slug; the denylist gate is bypassed.

### Pitfall 6: Exit Code Inconsistency with sync-claude

**What goes wrong:** `gen-skills.sh --check` uses `exit 2` for drift (matching `sync-claude.sh`), but SPEC requirement 2 says "exits 1 on any drift." The pre-commit hook uses `if ! bash ...; then` which catches any non-zero — so both work locally — but a test that asserts `DRIFT_EXIT -eq 2` would fail for gen-skills if it uses exit 1.
**Why it happens:** `sync-claude.sh` uses `exit 2` for drift; SPEC says `exit 1` for `gen-skills.sh`; D-05 says "non-zero = drift" (compatible with both). CONTEXT.md canonical ref for `sync-claude.sh` says "exit 0 = OK / exit 2 = DRIFT."
**How to avoid:** SPEC wins: `gen-skills.sh --check` exits **1** on drift (not 2), matching what the SPEC acceptance criteria specify. Any Nyquist test asserting exit codes should assert `DRIFT_EXIT -ne 0` (or `-eq 1` per SPEC). Note: `sync-claude.sh --check` exits 2 — gen-skills is a "structural twin" in behavior but not required to be byte-identical in exit code.
**Warning signs:** A test asserts `-eq 2` and the script exits 1 (or vice versa).

## Code Examples

### Structural Assertion: Body Line Count

```bash
# Count lines in SKILL.md body (after closing frontmatter ---)
# Source: 18-SPEC.md requirement 4, pattern derived from SPEC body definition
body_lines=$(awk '/^---/{n++; if(n==2){found=1; next}} found{print}' "$skill" | wc -l)
if [ "$body_lines" -gt 3 ]; then
    echo "ASSERT FAIL: $skill body has $body_lines lines (max 3)" >&2
    DRIFT=1
fi
```

### Structural Assertion: Directory Purity

```bash
# Source: 18-SPEC.md requirement 3, wiki-cloud/concepts/progressive-disclosure.md
# L2 loads ALL .md in top-level directory — extras inflate context
extra=$(find ".claude/skills/${op}" -maxdepth 1 -name "*.md" ! -name "SKILL.md" | wc -l)
if [ "$extra" -gt 0 ]; then
    echo "ASSERT FAIL: .claude/skills/${op}/ contains extra .md files" >&2
    DRIFT=1
fi
```

### sync-claude --check Pattern (template to clone)

```bash
# Source: [VERIFIED: bin/sync-claude.sh]
if [ "$CHECK_ONLY" -eq 1 ]; then
    if [ ! -f "$DST" ]; then
        echo "DRIFT: $DST missing" >&2; exit 2
    fi
    if ! cmp -s "$SRC" "$DST"; then
        echo "DRIFT: $DST differs from $SRC. Run: bash bin/sync-claude.sh && git add $DST" >&2
        exit 2
    fi
    echo "OK: $SRC == $DST"
    exit 0
fi
```

### Pre-Commit auto-fix + restage Pattern (template to clone)

```bash
# Source: [VERIFIED: .githooks/pre-commit lines 6-12]
if ! bash bin/sync-claude.sh --check 2>/dev/null; then
    echo "CLAUDE.md drift detected. Auto-syncing..." >&2
    bash bin/sync-claude.sh
    git add CLAUDE.md
    echo "CLAUDE.md resynced and re-staged. Re-run commit." >&2
    exit 1
fi
```

### check-neutrality.sh PUBLIC_PATHS Extension (D-10)

```bash
# Source: [VERIFIED: bin/check-neutrality.sh line 94]
# Current:
PUBLIC_PATHS=(AGENTS.md CLAUDE.md README.md PRIVACY.md docs .github wiki-cloud bin schema)
# After D-10 (add .claude/skills/):
PUBLIC_PATHS=(AGENTS.md CLAUDE.md README.md PRIVACY.md docs .github wiki-cloud bin schema .claude/skills)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Skill router as a separate authored file (hand-edited) | Generator pattern: template → committed artifact → `--check` drift gate | Phase 18 (this phase) | Eliminates manual-edit risk; generator is the artifact SOT; structural asserts catch template fattening |
| Skills-first extraction (rejected by 2 advisors) | Markdown-first, skills-as-overlay-last | CONTEXT-NOTES §34–42 (design lineage) | Preserves markdown portability; avoids vendor coupling; skills come last as thin wrappers |
| `disable-model-invocation: true` (considered) | Model invocation enabled; `description` carries discovery load | 18-SPEC.md §5, decision in CONTEXT | Better UX; description must be what+when to compensate |

**Deprecated/outdated:**
- Hand-editing `.claude/skills/` files: explicitly prohibited by the derived-artifact discipline. Changes go to `bin/gen-skills.sh` template/DESC data.
- Skills for non-core operations (audit/brownfield/release/structured-operations): excluded by minimalism precedent; out of scope for Phase 18.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `mktemp -d` is the right temp-dir approach for the `--check` regeneration scratch space | Standard Stack, Pattern 1 | Low: POSIX standard; alternative is a fixed `/tmp/gen-skills-check-$$` with manual cleanup | 
| A2 | The YAML frontmatter `name` field for each skill should match the op name exactly (`ingest`, `query`, `lint`, `reflect`) — matching the directory name and workflow filename | Pattern 3 (SKILL.md format) | Low: CONTEXT-NOTES confirms short op-names mirror workflow filenames 1:1; name constraint `≤64 chars, lowercase` is satisfied |
| A3 | The new CI job should be added to `.github/workflows/lint.yml` (not `neutrality.yml`) because it checks a committed artifact, not a neutrality/privacy property | Architecture, Pattern 4 | Low: D-03/D-04 specify `lint.yml` as the host; neutrality.yml hosts `sync-claude --check` as a precedent for equivalent placement, but the decision is locked |

**If this table is empty:** All other claims in this research were verified against the actual codebase or wiki pages in this session.

## Open Questions (RESOLVED)

1. **Exact per-op `description` strings**
   - What we know: Must be third-person, what+when, ≤1024 chars, no first-person pronouns, tight ~1-2 sentences. Claude's Discretion (not locked).
   - What's unclear: The exact draft text — the executor drafts these, constrained by the authoring rules.
   - Recommendation: Plan should include drafting the four description strings as a task item, with the `description` authoring rules from the wiki as the constraint. Example form: "Processes a new source into wiki pages by running classify-extract-merge-lint. Invoke when asked to ingest, add, or process a new source document."
   - RESOLVED: Description strings are drafted in 18-01 Task 1 `get_desc()` function — third-person what+when, no first-person pronoun, one sentence per op.

2. **Associative array bash compatibility**
   - What we know: `declare -A` (associative arrays) requires bash ≥4.0. macOS ships bash 3.2 (GPLv2) by default; Linux typically ships bash ≥4.
   - What's unclear: Whether any CI runner or contributor environment uses bash <4.
   - Recommendation: The CI runs on `ubuntu-latest` (bash ≥5). Pre-commit runs on the user's machine. Given macOS ships bash 3.2, the script should either (a) use a `case` statement or indexed arrays instead of `declare -A`, or (b) use `#!/usr/bin/env bash` and require bash ≥4 with an explicit check. A `case` statement for four fixed ops is the safest zero-assumption approach. [ASSUMED — worth confirming the user's shell version]
   - RESOLVED: Use `case`-based `get_desc()` function (bash 3.2 portable) — satisfies D-01's inline/zero-dep/single-file intent with broader portability. Deviation from D-01's `declare -A` example is documented in script comment.

3. **Decision record `trigger_type` value**
   - What we know: D-09 says "trigger_type: schema-update or equivalent". The existing DR template requires a non-null value.
   - What's unclear: Whether "schema-update" is a valid enum or a free text field in this repo's frontmatter.
   - Recommendation: Inspect `schema/templates/decision.md` — `trigger_type` is `null` in the template (free text). Use `schema-update` to match the wording of other DRs in this repo (e.g., `dr-2026-06-04-privacy-asymmetric-two-dir`).
   - RESOLVED: `trigger_type: schema-update` — confirmed free text field; matches existing DR convention.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| bash | `bin/gen-skills.sh` generator | Yes | system bash | — |
| `cmp` (POSIX) | `--check` byte comparison | Yes | POSIX standard | — |
| `mktemp` (POSIX) | `--check` temp dir | Yes | POSIX standard | — |
| `find` (POSIX) | `--check` dir-purity assertion | Yes | POSIX standard | — |
| `git add` | pre-commit auto-fix re-staging | Yes | repo-local | — |
| `.claude/` directory | skill file output | Yes (exists, managed by Claude Code) | — | create if absent |
| `schema/workflows/ingest.md` | behavioral SOT for ingest skill | Yes (77 lines) | — | — |
| `schema/workflows/query.md` | behavioral SOT for query skill | Yes (121 lines) | — | — |
| `schema/workflows/lint.md` | behavioral SOT for lint skill | Yes (160 lines) | — | — |
| `schema/workflows/reflect.md` | behavioral SOT for reflect skill | Yes (80 lines) | — | — |

**Missing dependencies with no fallback:** None.

**Missing dependencies with fallback:** None — all dependencies are confirmed available.

**Pre-condition (not a missing dep, but a required change):** `.gitignore` must be updated before files can be tracked. See "Critical Pre-Condition" section above.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | bash test scripts (established repo pattern: `tests/phase-XX/test_*.sh` + `run.sh` aggregator) |
| Config file | none — `tests/phase-18/run.sh` serves as the aggregator (Wave 0 gap) |
| Quick run command | `bash tests/phase-18/run.sh` |
| Full suite command | `bash tests/phase-18/run.sh` (same — no separate full mode for this phase) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SKILL-01 | `bin/gen-skills.sh` creates exactly 4 SKILL.md files at correct paths | unit | `bash tests/phase-18/test_gen_skills_creates_files.sh` | Wave 0 gap |
| SKILL-01 | Second run produces no git diff (idempotent) | unit | `bash tests/phase-18/test_gen_skills_idempotent.sh` | Wave 0 gap |
| SKILL-01 | Each SKILL.md body is ≤3 lines and contains `schema/workflows/{op}.md` pointer | unit | `bash tests/phase-18/test_skill_body_thin.sh` | Wave 0 gap |
| SKILL-01 | Each skill dir contains only SKILL.md (directory purity) | unit | `bash tests/phase-18/test_skill_dir_purity.sh` | Wave 0 gap |
| SKILL-01 | Each SKILL.md has `name` + third-person `description` (no first-person pronoun, no `disable-model-invocation: true`) | unit | `bash tests/phase-18/test_skill_frontmatter.sh` | Wave 0 gap |
| SKILL-02 | `--check` exits 0 on clean committed files matching template | unit | `bash tests/phase-18/test_gen_skills_check_clean.sh` | Wave 0 gap |
| SKILL-02 | `--check` exits non-zero after manual edit to any committed SKILL.md | unit | `bash tests/phase-18/test_gen_skills_check_drift.sh` | Wave 0 gap |
| SKILL-02 | SKILL.md files are tracked by git (not gitignored) | unit | `bash tests/phase-18/test_skills_git_tracked.sh` | Wave 0 gap |
| SKILL-02 | Pre-commit hook: skills `--check` runs between sync-claude and lint steps | integration | `bash tests/phase-18/test_hook_ordering_skills.sh` | Wave 0 gap |
| D-10 | `bin/check-neutrality.sh` covers `.claude/skills/` in scanned paths | unit | `bash tests/phase-18/test_neutrality_covers_skills.sh` | Wave 0 gap |

**Mirror test from Phase 7 for gen-skills:** `tests/phase-07/test_sync_claude.sh` is the direct analog. `tests/phase-18/test_gen_skills_check_clean.sh` should mirror its structure: check clean tree exits 0, inject drift + assert non-zero exit, re-run generate + assert idempotent, verify hook references the script.

### Sampling Rate

- **Per task commit:** `bash tests/phase-18/run.sh`
- **Per wave merge:** `bash tests/phase-18/run.sh` (all tests; wave is small)
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `tests/phase-18/run.sh` — aggregator mirroring `tests/phase-07/run.sh` / `tests/phase-08/run.sh` pattern
- [ ] `tests/phase-18/test_gen_skills_creates_files.sh` — covers SKILL-01 file creation
- [ ] `tests/phase-18/test_gen_skills_idempotent.sh` — covers SKILL-01 idempotency
- [ ] `tests/phase-18/test_skill_body_thin.sh` — covers SKILL-01 ≤3 lines + pointer content
- [ ] `tests/phase-18/test_skill_dir_purity.sh` — covers SKILL-01 dir purity
- [ ] `tests/phase-18/test_skill_frontmatter.sh` — covers SKILL-01 frontmatter format
- [ ] `tests/phase-18/test_gen_skills_check_clean.sh` — covers SKILL-02 `--check` clean path
- [ ] `tests/phase-18/test_gen_skills_check_drift.sh` — covers SKILL-02 `--check` drift detection
- [ ] `tests/phase-18/test_skills_git_tracked.sh` — covers SKILL-02 committed-not-gitignored
- [ ] `tests/phase-18/test_hook_ordering_skills.sh` — covers D-03 pre-commit ordering
- [ ] `tests/phase-18/test_neutrality_covers_skills.sh` — covers D-10 neutrality surface extension
- [ ] `tests/phase-18/lib.sh` — shared fixture utilities (mirror `tests/phase-07/` lib if needed)

## Security Domain

> `security_enforcement` is not explicitly set to `false` in `.planning/config.json`.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Skills are filesystem assets, no auth surface |
| V3 Session Management | no | No sessions involved |
| V4 Access Control | partial | Skill files are project-scoped (`.claude/skills/`); no access control needed but they ship in-tree |
| V5 Input Validation | partial | Generator validates description content (no first-person, no `disable-model-invocation`); template injection not a concern for a bash heredoc with fixed template |
| V6 Cryptography | no | No cryptographic operations |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malicious skill body encoding unauthorized tool invocations | Elevation of Privilege | Body is ≤3 lines pointer-only; structural assertion enforces inert body; template is the only source of body content [VERIFIED: 18-SPEC.md Constraints "Inert bodies"] |
| Private vault term leak via description strings | Information Disclosure | `bin/check-neutrality.sh` denylist scan extended to `.claude/skills/` (D-10); descriptions are authored text and must pass the neutrality gate [VERIFIED: 18-CONTEXT.md D-10] |
| Hand-edited skill content bypassing the derived-artifact discipline | Tampering | `--check` gate enforces regenerate-diff; pre-commit auto-detects and restores; CI hard-fails on drift [VERIFIED: 18-SPEC.md requirement 2, D-04] |

## Sources

### Primary (HIGH confidence)

- `18-SPEC.md` — locked requirements, acceptance criteria, two-layer SOT model, all 6 requirements [VERIFIED: read in full]
- `18-CONTEXT.md` — D-01..D-11 implementation decisions, canonical refs, specifics [VERIFIED: read in full]
- `bin/sync-claude.sh` — exact `--check` idiom, argument parsing, exit codes, cmp usage [VERIFIED: read in full]
- `.githooks/pre-commit` — existing hook composition; auto-fix + restage pattern [VERIFIED: read in full]
- `bin/check-neutrality.sh` — `PUBLIC_PATHS` array (line 94); Python scan logic [VERIFIED: read in full]
- `.github/workflows/lint.yml` — CI job structure; host for new `skills-check` job [VERIFIED: read in full]
- `.gitignore` — `.claude/` gitignore pattern (lines 8-9); critical blocker for tracked SKILL.md files [VERIFIED: read in full]
- `wiki-cloud/concepts/progressive-disclosure.md` — L1 ~100 tok/skill; L2 loads ALL top-level .md; dir-purity rationale [VERIFIED: read in full]
- `wiki-cloud/sources/src-2026-05-06-anthropic-agent-skills-best-practices.md` — third-person description rule; forward-slash paths; naming conventions [VERIFIED: read in full]
- `wiki-cloud/entities/claude-code.md` — `.claude/skills/` project-scope mount; filesystem discovery at session start [VERIFIED: read in full]
- `wiki-cloud/overviews/agent-skills.md` — `name` field constraints (≤64 chars, lowercase); `description` constraints (≤1024 chars) [VERIFIED: read in full]
- `schema/workflows/ingest.md`, `query.md`, `lint.md`, `reflect.md` — confirmed existence + line counts (77, 121, 160, 80) [VERIFIED: bash wc -l]
- `.planning/REQUIREMENTS.md` — SKILL-01, SKILL-02 full definitions [VERIFIED: read]
- `tests/phase-07/test_sync_claude.sh` — direct structural analog for the gen-skills test to mirror [VERIFIED: read in full]
- `tests/phase-08/run.sh` — test aggregator pattern [VERIFIED: read in full]

### Secondary (MEDIUM confidence)

- `.planning/phases/999.4-v1-2-schema-architecture-progressive-disclosure-refactor/CONTEXT-NOTES.md` §"Phase C — Claude Skills Overlay" — design lineage: pointer body form, advisor rejection of skills-first approach [VERIFIED: grep + targeted read]

### Tertiary (LOW confidence)

- None — all key claims verified from the codebase or wiki pages directly.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all tools are POSIX/bash already present in the repo; wiki sources verified
- Architecture: HIGH — patterns cloned from `sync-claude.sh` + pre-commit hook; CI from `lint.yml`
- Pitfalls: HIGH — `.gitignore` issue verified from actual file content; exit code discrepancy from actual source read; L2 purity from wiki Key Facts
- Validation architecture: HIGH — test structure cloned from phase-07/phase-08 established patterns; Wave 0 gaps are all new files (none exist yet)

**Research date:** 2026-06-08
**Valid until:** 2026-09-08 (90 days — stable bash/git tooling; SKILL.md format is Anthropic production spec since Oct 2025)
