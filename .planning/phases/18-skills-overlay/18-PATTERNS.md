# Phase 18: Skills Overlay - Pattern Map

**Mapped:** 2026-06-08
**Files analyzed:** 9
**Analogs found:** 9 / 9

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `bin/gen-skills.sh` | utility/generator | batch (generate + check) | `bin/sync-claude.sh` | exact — same check idiom, same zero-dep bash style |
| `.claude/skills/{ingest,query,lint,reflect}/SKILL.md` | config/generated artifact | transform (template → file) | `CLAUDE.md` (generated copy of `AGENTS.md`) | role-match — generated, committed, drift-guarded |
| `.githooks/pre-commit` | middleware/hook | request-response | `.githooks/pre-commit` (self — insert new block) | exact — direct modification |
| `.github/workflows/lint.yml` | config/CI | batch | `.github/workflows/lint.yml` (self — add job) | exact — direct modification; new job mirrors `strict` job pattern |
| `bin/check-neutrality.sh` | utility/guard | batch | `bin/check-neutrality.sh` (self — extend PUBLIC_PATHS) | exact — one-line array extension |
| `.gitignore` | config | N/A | `.gitignore` (self — add negation patterns) | exact — direct modification |
| `wiki-cloud/decisions/dr-2026-06-08-skills-overlay.md` | decision record | N/A | `wiki-cloud/decisions/dr-2026-06-05-workflow-extraction.md` | exact — same type, same recency, same trigger_type |
| `wiki-cloud/index.md` | index | N/A | `wiki-cloud/index.md` (self — append DR entry) | exact — direct modification |
| `docs/reference/skills.md` | documentation | N/A | `docs/reference/release.md` (adopter runbook) | role-match — same H1+section doc style |

---

## Pattern Assignments

### `bin/gen-skills.sh` (utility/generator, batch)

**Analog:** `bin/sync-claude.sh`

**Shebang + set + CHECK_ONLY flag** (lines 1-8):
```bash
#!/usr/bin/env bash
# bin/sync-claude.sh -- TMPL-10, D-03: AGENTS.md -> CLAUDE.md byte copy.
# Idempotent. Zero deps.
set -euo pipefail

SRC="AGENTS.md"
DST="CLAUDE.md"
CHECK_ONLY=0
```
Pattern for gen-skills.sh: same shebang, `set -euo pipefail`, `CHECK_ONLY=0`. Replace `SRC`/`DST` with `declare -A DESC` and `OPS=(ingest query lint reflect)`.

**Argument parsing** (lines 10-16):
```bash
while [ "$#" -gt 0 ]; do
    case "$1" in
        --help|-h) echo "Usage: bin/sync-claude.sh [--check]"; exit 0 ;;
        --check) CHECK_ONLY=1; shift ;;
        *) echo "ERROR: unknown arg: $1" >&2; exit 1 ;;
    esac
done
```
Copy verbatim — only the usage string changes.

**`--check` block with `cmp -s`** (lines 20-30):
```bash
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
Pattern for gen-skills.sh: loop over `OPS`, regenerate each to `mktemp -d`, compare with `cmp -s`, accumulate a `DRIFT` flag, then exit 1 on any drift (SPEC requires exit 1, not exit 2). Add independent structural assertions (D-06/D-07) after the diff loop — these are NOT redundant with the diff (D-07: a fattened template still passes diff). Structural assertions:
- body lines after closing `---` frontmatter fence: `awk '/^---/{n++; if(n==2){found=1;next}} found{print}' "$skill" | wc -l` must be ≤ 3
- dir purity: `find ".claude/skills/${op}" -maxdepth 1 -name "*.md" ! -name "SKILL.md" | wc -l` must be 0
- no first-person pronoun: `grep -qiE '\b(I|I'\''ll|we)\b'` on the `description:` line must fail
- no `disable-model-invocation: true` key present

**Generate (idempotent write) block** (lines 32-34):
```bash
cp "$SRC" "$DST"
cmp -s "$SRC" "$DST" || { echo "ERROR: post-copy byte-mismatch (should be impossible)" >&2; exit 1; }
echo "Synced $SRC -> $DST"
```
Pattern for gen-skills.sh: replace `cp` with `mkdir -p "$dir" && body_for "$op" > "$dir/SKILL.md"` in a loop. Idempotent because the heredoc produces identical bytes on every run.

**RESEARCH.md already provides the full structural skeleton** for gen-skills.sh (Pattern 1, lines 178–277 of 18-RESEARCH.md). Use it directly; do not invent a different structure.

---

### `.claude/skills/{ingest,query,lint,reflect}/SKILL.md` (config/generated artifact, transform)

**Analog:** `CLAUDE.md` (generated copy of `AGENTS.md`), and the SKILL.md format from RESEARCH.md Pattern 3

**Canonical file format** (RESEARCH.md Pattern 3):
```yaml
---
name: ingest
description: <third-person what+when description, ≤1024 chars>
---

You have been invoked to ingest. Read `schema/workflows/ingest.md` and follow it verbatim.
```

Key constraints derived from analogs:
- `name` field: lowercase, ≤64 chars, matches op name and workflow filename exactly (A2 in RESEARCH.md)
- `description` field: third-person, what+when, ≤1024 chars, no first-person pronouns (`I`, `I'll`, `we`), no XML tags
- No `disable-model-invocation: true` key
- Body: exactly 2 post-frontmatter lines (1 blank + 1 pointer), comfortably ≤3
- Forward-slash path in body: `schema/workflows/{op}.md`
- These files are generated — hand-editing is prohibited; `--check` enforces this

**The four files are generated by `bin/gen-skills.sh`**. The planner should not plan them as separately authored files — plan a single generator task that produces all four.

---

### `.githooks/pre-commit` (middleware/hook — MODIFY)

**Analog:** `.githooks/pre-commit` (self)

**Existing sync-claude block** (lines 1-12 — copy this pattern for the skills block):
```bash
#!/usr/bin/env bash
# Pre-commit hook: enforce AGENTS.md <-> CLAUDE.md byte-equality (D-03)
# AND run the local wiki write-gate over staged changes (Phase 12.2).
set -euo pipefail

if ! bash bin/sync-claude.sh --check 2>/dev/null; then
    echo "CLAUDE.md drift detected. Auto-syncing..." >&2
    bash bin/sync-claude.sh
    git add CLAUDE.md
    echo "CLAUDE.md resynced and re-staged. Re-run commit." >&2
    exit 1
fi
```

**New block to insert** — insert AFTER line 12 (after the sync-claude block) and BEFORE the `lint --strict --staged` block (D-03):
```bash
# Phase 18 / SKILL-02: gen-skills drift gate (D-03, D-04)
# Skills are committed generated artifacts; auto-fix + restage mirrors sync-claude pattern.
# D-07: structural assertions inside gen-skills --check are NOT redundant with the diff check.
if ! bash bin/gen-skills.sh --check 2>/dev/null; then
    echo "Skills drift detected. Auto-regenerating..." >&2
    bash bin/gen-skills.sh
    git add .claude/skills/
    echo "Skills resynced and re-staged. Re-run commit." >&2
    exit 1
fi
```

**Existing lint write-gate block** (lines 14-23 — unchanged, stays last):
```bash
# Phase 12.2 / WGATE-01..04: local wiki write-gate over staged changes.
if ! bash bin/lint.sh --strict --staged --category provenance >&2; then
    echo "" >&2
    echo "Write-gate failed. ..." >&2
    exit 1
fi
```

**Hook ordering after modification:** `sync-claude --check` → `gen-skills --check` → `lint --strict --staged`.

---

### `.github/workflows/lint.yml` (config/CI — MODIFY)

**Analog:** `.github/workflows/lint.yml` (self) — existing `strict` job is the closest structural twin for a simple bash-run job

**Existing `strict` job pattern** (lines 71-88):
```yaml
  strict:
    # CI-06: --strict quality ratchet.
    # D-07: skip on draft PRs; run on ready-for-review PRs + push to main.
    if: github.event.pull_request.draft == false || github.event_name == 'push'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
        with:
          fetch-depth: 0
      - uses: actions/setup-python@v6
        with:
          python-version: '3.12'
      - name: Install PyYAML
        run: pip install pyyaml
      - name: Strict quality ratchet (CI-06)
        run: bash bin/lint.sh --require-version 1.1.0 --strict
```

**New job to append** — pure bash, no Python dep needed (D-04: CI hard-fail only, no auto-fix):
```yaml
  skills-check:
    # D-03 / D-04: gen-skills --check hard-fail gate. CI never auto-fixes.
    # D-07: structural assertions inside gen-skills --check catch fattened templates
    # that would still pass a pure regenerate-diff.
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - name: Skills drift + structural assertions (SKILL-02)
        run: bash bin/gen-skills.sh --check
```

Note: `actions/checkout@v6` matches the version already used by all other jobs in this file (lines 38, 61, 78). No `setup-python` needed — `gen-skills.sh` is pure bash.

---

### `bin/check-neutrality.sh` (utility/guard — MODIFY)

**Analog:** `bin/check-neutrality.sh` (self) — one-line change to `PUBLIC_PATHS` array at line 94

**Current `PUBLIC_PATHS` line** (line 94):
```bash
PUBLIC_PATHS=(AGENTS.md CLAUDE.md README.md PRIVACY.md docs .github wiki-cloud bin schema)
```

**After D-10 extension** — append `.claude/skills` as the last element:
```bash
PUBLIC_PATHS=(AGENTS.md CLAUDE.md README.md PRIVACY.md docs .github wiki-cloud bin schema .claude/skills)
```

No other changes required. The Python scan loop already handles directory traversal via `os.walk` (lines 210-215). The `.claude/skills/` directory will be walked and all `.md` files scanned against the denylist.

---

### `.gitignore` (config — MODIFY)

**Analog:** `.gitignore` (self) — add two negation lines immediately after line 9

**Current lines 7-9**:
```
# Local agent/tool state (settings.cloud.json is tracked -- the cloud deny-profile artifact)
.claude/
!.claude/settings.cloud.json
```

**After modification** — add two lines after line 9:
```
# Local agent/tool state (settings.cloud.json is tracked -- the cloud deny-profile artifact)
.claude/
!.claude/settings.cloud.json
!.claude/skills/
!.claude/skills/**
```

The `!.claude/skills/` negation un-ignores the directory itself; `!.claude/skills/**` un-ignores all files within it. Both are required — git requires un-ignoring intermediate directories AND the files (RESEARCH.md Critical Pre-Condition section). Without this change `git add .claude/skills/` silently stages nothing.

This is Wave 0 — must land before `bin/gen-skills.sh` creates files, or the generated files cannot be tracked.

---

### `wiki-cloud/decisions/dr-2026-06-08-skills-overlay.md` (decision record — NEW)

**Analog:** `wiki-cloud/decisions/dr-2026-06-05-workflow-extraction.md` (most recent DR; same `trigger_type: schema-update`)

**Frontmatter pattern** (lines 1-24 of analog):
```yaml
---
id: dr-2026-06-05-workflow-extraction
title: "Workflow Extraction: AGENTS.md §9–§12 to schema/workflows/ + routing guard + inclusion tripwire"
type: decision
status: active
summary: "Extracts §9 (operations vocabulary)..."
created_at: 2026-06-07
updated_at: 2026-06-07
sources: []
epistemic_status: sourced
tags:
  - meta
  - schema
domains:
  - wiki-infrastructure
supersedes: null
superseded_by: null
aliases:
  - dr-2026-06-05-workflow-extraction
has_contradictions: false
knowledge_domain: software
trigger_type: schema-update
affected_pages: []
---
```

**For Phase 18 DR**, substitute:
- `id`: `dr-2026-06-08-skills-overlay`
- `title`: `"Skills Overlay: Four Generated SKILL.md Routers + bin/gen-skills.sh Drift Gate"`
- `summary`: one-sentence description of the two-layer SOT model and `--check` gate
- `created_at` / `updated_at`: `2026-06-08`
- `aliases`: `[dr-2026-06-08-skills-overlay]`
- `affected_pages`: `[index]` (index.md gets a new DR entry)
- `trigger_type`: `schema-update`

**Section structure** mirrors the analog (TL;DR → Decision → Why → Alternatives Considered → Consequences → Affected Pages → Sources). The DR must record: (1) why the overlay exists (optional accelerator, deferred-last in v1.2); (2) the two-layer SOT model (behavioral SOT = workflow files, artifact SOT = generator); (3) model-invocation enabled choice; (4) `--check` gate rationale; (5) D-07 rationale for independent structural assertions.

No `neutrality_exempt` needed — the DR contains no private vault terms.

---

### `wiki-cloud/index.md` (index — MODIFY)

**Analog:** `wiki-cloud/index.md` (self) — append one line to the `## Decisions` section

**Existing Decisions section entry pattern** (lines 84-94):
```markdown
## Decisions

- [[dr-2026-04-14-phase6-decision-type|dr-2026-04-14-phase6-decision-type]] — Introduce Decision Record Page Type (schema-update, 2026-04-14)
...
- [[dr-2026-06-05-workflow-extraction|Workflow Extraction: AGENTS.md §9–§12 to schema/workflows/ + routing guard + inclusion tripwire]] — Extracts workflow procedures into standalone files; ... (sourced, 2026-06-07)
```

**New entry to append** at end of `## Decisions` block:
```markdown
- [[dr-2026-06-08-skills-overlay|Skills Overlay: Four Generated SKILL.md Routers + bin/gen-skills.sh Drift Gate]] — Introduces four thin SKILL.md pointer routers generated by bin/gen-skills.sh with a --check drift gate; records the two-layer SOT model and model-invocation choice. (sourced, 2026-06-08)
```

Format exactly matches existing entries: `[[id|Title]] — summary text (epistemic_status, date)`.

Also update `updated_at` in the index.md frontmatter from `2026-05-06T22:30:00` to `2026-06-08`.

---

### `docs/reference/skills.md` (documentation — NEW)

**Analog:** `docs/reference/release.md` (adopter-facing runbook; plain H1 + sections, no frontmatter, imperative style)

**Structure pattern from `docs/reference/release.md`** (lines 1-15):
```markdown
# Release Runbook (Orphan Branch)

This runbook is the maintainer-invoked path for...

## Prerequisites

- Clean working tree...

## What the script publishes
...
```

**For `docs/reference/skills.md`**, follow the same plain-markdown, no-frontmatter, H1 title + section pattern. Content outline (D-11):
1. H1: `# Claude Code Skills Overlay`
2. One-paragraph intro: what the four skills are, that they are generated (not hand-edited), and that `SKILL.md` files live at `.claude/skills/{op}/SKILL.md`
3. `## How skills are generated` — describes `bin/gen-skills.sh`, the `--check` gate, and the two-layer SOT model (behavioral SOT = workflow files, artifact SOT = generator)
4. `## The four skills` — table listing op name, skill path, behavioral SOT file, description (one line each)
5. `## Modifying a skill` — do NOT hand-edit; make changes in `bin/gen-skills.sh` template/DESC data, then re-run generator; `--check` will reject hand-edits
6. `## Drift gate` — explains pre-commit auto-fix behavior and CI hard-fail behavior
7. Optional: `## Adopter notes` — for template adopters; mention that skill files are committed in the template (fresh clone has them)

---

## Shared Patterns

### Zero-dep pure-bash bin/ style
**Source:** `bin/sync-claude.sh` (all 35 lines)
**Apply to:** `bin/gen-skills.sh`
- `#!/usr/bin/env bash` shebang
- `set -euo pipefail` at top
- `while [ "$#" -gt 0 ]; do case "$1" in ...` argument parser
- No external runtime deps (no Python, no node)
- Descriptive comments citing the decision numbers that motivated the code

### `--check` + `cmp -s` drift gate
**Source:** `bin/sync-claude.sh` lines 20-30
**Apply to:** `bin/gen-skills.sh --check` block
```bash
if ! cmp -s "$SRC" "$DST"; then
    echo "DRIFT: $DST differs from $SRC. Run: ..." >&2
    exit 2   # (gen-skills uses exit 1 per SPEC requirement 2)
fi
echo "OK: $SRC == $DST"
exit 0
```

### Auto-fix + restage pre-commit pattern
**Source:** `.githooks/pre-commit` lines 6-12
**Apply to:** new skills block in `.githooks/pre-commit`
```bash
if ! bash bin/sync-claude.sh --check 2>/dev/null; then
    echo "CLAUDE.md drift detected. Auto-syncing..." >&2
    bash bin/sync-claude.sh
    git add CLAUDE.md
    echo "CLAUDE.md resynced and re-staged. Re-run commit." >&2
    exit 1
fi
```

### CI job structure (no Python dep)
**Source:** `.github/workflows/lint.yml` lines 71-88 (`strict` job)
**Apply to:** new `skills-check` job in `lint.yml`
- `runs-on: ubuntu-latest`
- `actions/checkout@v6` (matching version used by all other jobs)
- Single `run:` step with the bash command

### Decision record frontmatter
**Source:** `wiki-cloud/decisions/dr-2026-06-05-workflow-extraction.md` lines 1-24
**Apply to:** `wiki-cloud/decisions/dr-2026-06-08-skills-overlay.md`
Required fields (all in snake_case): `id`, `title`, `type: decision`, `status: active`, `summary`, `created_at`, `updated_at`, `sources: []`, `epistemic_status: sourced`, `tags`, `domains`, `supersedes: null`, `superseded_by: null`, `aliases`, `has_contradictions: false`, `knowledge_domain: software`, `trigger_type: schema-update`, `affected_pages`

### Index Decisions entry format
**Source:** `wiki-cloud/index.md` lines 84-94
**Apply to:** new entry in `wiki-cloud/index.md`
```markdown
- [[<id>|<Title>]] — <summary> (<epistemic_status>, <YYYY-MM-DD>)
```

---

## No Analog Found

All files have a usable analog. No entries in this section.

---

## Metadata

**Analog search scope:** `bin/`, `.githooks/`, `.github/workflows/`, `wiki-cloud/decisions/`, `wiki-cloud/index.md`, `docs/reference/`, `.gitignore`
**Files scanned:** 11 (sync-claude.sh, pre-commit, check-neutrality.sh, lint.yml, .gitignore, dr-2026-06-04-privacy-asymmetric-two-dir.md, dr-2026-06-05-workflow-extraction.md, index.md, release.md, brownfield.md — partial, index.md decisions section)
**Pattern extraction date:** 2026-06-08
