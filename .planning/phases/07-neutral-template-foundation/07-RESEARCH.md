# Phase 7: Neutral Template Foundation - Research

**Researched:** 2026-04-15
**Domain:** Public template repo scaffolding + neutrality enforcement + orphan-branch release + mechanical traceability
**Confidence:** HIGH (most decisions locked in CONTEXT.md; v1.0 primitives well-established; external patterns already verified in milestone-level STACK.md / ARCHITECTURE.md / PITFALLS.md)

---

## User Constraints (from CONTEXT.md)

### Locked Decisions

**Repo Identity, License, Release**
- **D-01:** License is **MIT** (TMPL-03), top-level `LICENSE`.
- **D-02:** Public org/repo name deferred to release time. README/docs/CI use `<org>/<repo>` placeholders; orphan-branch script accepts target remote as flag/argument (not baked into files).
- **D-03:** CLAUDE.md (TMPL-10) is a **byte-identical duplicate** of AGENTS.md. AGENTS.md is canonical. `bin/sync-claude.sh` mechanically copies AGENTS.md → CLAUDE.md. Local **pre-commit hook** runs sync or fails on drift. CI byte-equality check blocks merge on drift. No symlink.
- **D-04:** Orphan-branch release (TMPL-11) uses **`bin/release.sh` + `docs/reference/release.md` runbook**, maintainer-invoked. Script **dry-run by default** (prints branch/worktree, files/history, refs/tags); `--apply` requires interactive y/N confirm. No `--yes` in v1.1.

**Neutrality & Denylist**
- **D-05:** NEUT-08 denylist is **auto-derived, then human-reviewed**. Process: enumerate `privacy: local_only` pages → extract distinctive tokens (slugs, aliases, proper names, multi-word phrases; avoid common words) → generate proposed `.neutrality-denylist.txt` → human prunes → commit → CI enforces. Surface candidate list as explicit task step.
- **D-06:** Enforcement via **`bin/check-neutrality.sh` + `.neutrality-denylist.txt`** (one term/phrase per line; `#` comments + blank lines). Scans public/control-plane paths only: `AGENTS.md`, `CLAUDE.md`, `README.md`, `PRIVACY.md`, `/docs/**`, `.github/**`, `wiki/**`, `bin/**`. Excludes `examples/**`. Exits non-zero with offending path + matching term. NEUT-06 (Kahneman) + NEUT-08 (denylist) both flow through same script.

**AGENTS.md Neutralization & Placeholders**
- **D-07:** Neutralization style: **generic placeholders inline + explicit `See: examples/kahneman/<page>.md` pointer** at end of each illustrative section. Readable standalone; reference one click away. No pure pointer-style. No fictional inline cluster.
- **D-08:** `AGENTS.template.md` carries **exactly four placeholders**: `{{PRIMARY_DOMAIN}}`, `{{DEFAULT_PRIVACY}}`, `{{AGENT_FILENAME}}`, `{{DECAY_PROFILE}}`. Research's `{{EXAMPLE_CLUSTER_REF}}` is **dropped** (hardcoded pointers instead).

**Examples Directory Semantics**
- **D-09:** NEUT-04 authority hierarchy: `examples/` path is primary; `example: true` frontmatter is fallback for out-of-tree pages. Pages under `examples/` excluded from health checks; basic file integrity still runs. Pages with `example: true` elsewhere same treatment. Copied-into-wiki with `example: true` keeps skip until user removes flag (safe adoption ramp).

**README & Onboarding Docs**
- **D-10:** `README.md` voice (TMPL-02): technical Obsidian user, plainspoken, architecture-first, low-fluff. "What this is" + "who it is for" + repo shape + first step + link to `docs/quickstart.md`. No "why not RAG" framing. Honest about prerequisites (bash, python3, git, Obsidian).
- **D-11:** `docs/quickstart.md` (TMPL-06) canonical flow: **fork → `bin/init-wizard.sh` → first `bin/ingest.sh` → open in Obsidian**. Phase 7 ships a **short stub** naming this flow but marking wizard/ingest sections as "filled in Phase 8". Do not duplicate manual-setup content.
- **D-12:** `PRIVACY.md` (TMPL-09) is a **short user-facing explainer**: privacy tiers (`local_only`, `cloud_safe`), operational meaning, what never commits to public/template surfaces, pointer to AGENTS.md for canonical enforcement semantics. Do NOT copy CI grep logic or detailed lint behavior.
- **D-13:** `examples/kahneman/README.md` (NEUT-05) is a reference-example explainer: what the cluster demonstrates (ingest, synthesis, cross-linking, provenance, contradiction handling), why preserved, how to read it, which AGENTS.md sections it illustrates, explicit "do not edit — reference material" note. Not a tutorial; not a stub.

**.gitignore Scope**
- **D-14:** Covers four categories: Obsidian noise (`.obsidian/workspace*.json`, `.obsidian/cache`, `.trash/`), brownfield (`.brownfield/`), planning (`.planning/`), OS/editor noise (`.DS_Store`, `Thumbs.db`, `*.swp`, `.idea/`, `.vscode/`).

**requirements-sync (DEBT-03)**
- **D-15:** Enforcement: **advisory by default, blocking on `--strict`**. PR CI default mode (exit 0, print findings). Milestone-close/Phase-12 runs `--strict` (exit non-zero on drift). Active-phase drift expected within a branch.
- **D-16:** Output: **markdown table to stdout default; `--format json` for CI**. Columns: `REQ-ID | REQUIREMENTS.md | VERIFICATION.md | Drift` (optional `Note`). No committed report artifact.
- **D-17:** Scope: **global by default (all REQ-IDs across all phase VERIFICATION.md files)**; `--phase N` for focused local runs. `--milestone vX.Y` deferred forward-compat hook.

### Claude's Discretion

- Exact CI workflow file names/structure under `.github/workflows/` (single `lint.yml` vs split) — consistent with research.
- Whether CLAUDE.md sync pre-commit hook ships as committed `.githooks/` + install script, or documented manual install step.
- Concrete markdown schema of `docs/reference/release.md` and `docs/reference/*.md` stubs (TMPL-08).
- Exact stdout formatting, exit codes, flag parsing in `bin/check-neutrality.sh`, `bin/sync-claude.sh`, `bin/release.sh`, `bin/requirements-sync.sh` — follow `bin/lint.sh` conventions.
- Whether NEUT-06 and NEUT-08 share one `.neutrality-denylist.txt` or use two files (single file with categorized comments is acceptable).

### Deferred Ideas (OUT OF SCOPE)

- Hosted docs site (MkDocs/Docusaurus).
- `bin/upgrade.sh` for template-fork upgrades — v1.2; document ownership boundary now (likely `docs/reference/release.md` footer or `PROJECT.md`).
- `--yes` flag on `bin/release.sh` (non-interactive automation path) — v1.1 stays interactive-confirm.
- GitHub Actions `workflow_dispatch` for orphan-branch publish — maintainer-local in v1.1.
- Multi-domain example stubs / second-domain starter cluster.
- `--milestone vX.Y` on `bin/requirements-sync.sh`.
- Light "example hygiene" lint mode for `examples/` — TODO in `bin/lint.sh` acceptable.
- Attribution/copyright line beyond MIT boilerplate.

---

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TMPL-01 | Repo configured as GitHub Template (green button) | Repo setting (not file); documented in Standard Stack + Release Runbook. |
| TMPL-02 | Top-level `README.md` with ≤60-second pitch + link to `docs/quickstart.md` | Voice D-10; section skeleton below. |
| TMPL-03 | `LICENSE` (MIT) | D-01. Boilerplate MIT text. |
| TMPL-04 | `.gitignore` pre-configured | D-14. Four categories below. |
| TMPL-05 | Starter `wiki/` ships with `index.md`/`log.md` skeletons only | After Kahneman move; skeleton content only. |
| TMPL-06 | `/docs/` four-track skeleton | D-11 + Diátaxis mapping. |
| TMPL-07 | `/docs/README.md` names Diátaxis mapping | Direct mapping table below. |
| TMPL-08 | `/docs/reference/` files exist | Stubs acceptable per CONTEXT; planner's schema. |
| TMPL-09 | Top-level `PRIVACY.md` | D-12. |
| TMPL-10 | `CLAUDE.md` at repo root = AGENTS.md | D-03 byte-identical dup + sync script + CI gate. |
| TMPL-11 | Orphan-branch release | D-04 `bin/release.sh` + runbook. |
| NEUT-01 | Kahneman cluster (7 pages + sources) moved to `examples/kahneman/` | File list below; wikilink rewrite algorithm. |
| NEUT-02 | AGENTS.md illustrative content rewritten with generic placeholders | D-07 style. |
| NEUT-03 | AGENTS.md `See: examples/kahneman/...` pointers at end of illustrative sections | D-07. |
| NEUT-04 | `example: true` frontmatter + `bin/lint.sh EXCLUDE_DIRS` extension | D-09; lint.sh L180 extension point. |
| NEUT-05 | `examples/kahneman/README.md` explains preservation | D-13 content schema. |
| NEUT-06 | CI neutrality grep gate (Kahneman-specific strings) | D-06 `bin/check-neutrality.sh` + denylist. |
| NEUT-07 | Decision record `dr-YYYY-MM-DD-kahneman-to-examples.md` (SUPERSEDE) | Per AGENTS.md §11.4; filename 2026-04-15 or execution date. |
| NEUT-08 | CI personal-content denylist check | D-05 auto-derived + D-06 enforcement. |
| DEBT-03 | `bin/requirements-sync.sh` mechanical check | D-15/D-16/D-17. |

---

## Summary

Phase 7 is scaffolding-heavy, low-novelty, high-consequence. Every architectural decision has already been resolved at the milestone level (STACK.md, ARCHITECTURE.md) and locked in CONTEXT.md. The planner's job is to sequence the work so (a) Kahneman is relocated before AGENTS.md is neutralized, (b) CI gates land before the orphan-branch publish, and (c) every new bash script follows `bin/lint.sh`'s established flag/exit/stdout conventions.

Stack is **zero new runtime dependencies** — bash ≥4, python3 + PyYAML (existing baseline), git, GitHub Actions `ubuntu-latest` with `actions/checkout@v6` + `actions/setup-python@v6`. All five new bash scripts use the existing inline-python3-heredoc pattern from `bin/lint.sh` / `bin/validate-op.sh`.

The single highest-risk item in this phase is **creator-content leakage into the public template** (pitfall C-1 from milestone PITFALLS.md). Three gates in combination mitigate it: (1) orphan-branch release (fresh `git init`, no v1.0 history reachable), (2) `bin/check-neutrality.sh` CI gate running on every PR against public control-plane paths, (3) human review of the auto-derived denylist before commit. All three must ship in Phase 7 or the C-1 risk carries forward.

**Primary recommendation:** Plan five waves — (W0) test infrastructure + `requirements-sync.sh`; (W1) Kahneman relocation + decision record + lint `EXCLUDE_DIRS`; (W2) AGENTS.md neutralization + `AGENTS.template.md` + `CLAUDE.md` sync; (W3) public-surface scaffolding (README/LICENSE/PRIVACY/.gitignore/docs skeleton); (W4) CI gates (`check-neutrality.sh` + neutrality/CLAUDE-drift workflows) + orphan-branch `release.sh` + runbook.

---

## Project Constraints (from CLAUDE.md)

No `./CLAUDE.md` exists in the working directory at research time. `CLAUDE.md` is being **created by this phase** (TMPL-10, D-03: byte-identical dup of AGENTS.md). No pre-existing CLAUDE.md directives constrain planning.

**AGENTS.md** (repo root) is the canonical agent-facing schema and is treated with authority equivalent to CLAUDE.md. Relevant directives inherited from AGENTS.md:
- §2 Directory Structure — must be extended to list `examples/`, `docs/`, `schema/`, `.github/`.
- §5 Frontmatter — must document new optional `example: boolean` field (default false).
- §11.4 Decision Records — NEUT-07 SUPERSEDE-class record required.
- §11.3 Lint — `EXCLUDE_DIRS` extension is a schema change visible to agents.
- §15 Tooling — must document GitHub PR workflow note (light touch in Phase 7; fuller treatment in Phase 9).
- §16 Appendices — Dataview examples that reference Kahneman pages must be rewritten to point to `examples/kahneman/...`.

---

## Standard Stack

### Core (all existing — zero new runtime deps)

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| bash | ≥ 4 | All new CLI helpers | Matches v1.0 convention; set -euo pipefail already pervasive |
| python3 + PyYAML | 3.12 / stdlib-shipped | YAML/markdown parsing via inline heredocs | `bin/lint.sh` / `bin/validate-op.sh` precedent; zero-dep policy |
| git | ≥ 2.30 | Orphan branch, worktree, refs manipulation | Required anyway |
| GitHub Actions | `ubuntu-latest` | CI runner | Native GitHub, zero install |
| `actions/checkout` | `@v6` (major-tag pin) | Checkout PR branch | Verified current 2026-04 (STACK.md) |
| `actions/setup-python` | `@v6` | Install python 3.12 | Verified current 2026-04 |

### Supporting

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `git worktree` | Staging orphan-branch publish in separate checkout | `bin/release.sh` — avoids corrupting main working tree |
| `git init` (in orphan worktree) | Fresh history for public template | Per D-04; alternative to `git checkout --orphan` in place |
| GitHub "Template repository" toggle | Settings → checkbox | TMPL-01; documented in `docs/reference/release.md` runbook; not a file |
| `.gitattributes` | `*.md text eol=lf` | Cross-platform PR diff hygiene (STACK.md recommends) |

### Alternatives Considered

| Instead of | Could Use | Tradeoff / Rejection Reason |
|------------|-----------|-----------------------------|
| MIT | Apache-2.0 | TMPL-03 allows either; D-01 locked MIT (shorter, more permissive for template use) |
| Byte-dup CLAUDE.md | Symlink AGENTS.md → CLAUDE.md | Rejected D-03 — breaks Windows + some git configs + Obsidian indexing |
| Orphan branch in place (`git checkout --orphan`) | Fresh `git init` in worktree | Either works; dry-run logs which path the script takes; fresh init is safer (no accidental ref leakage) |
| Single `.neutrality-denylist.txt` | Split `.kahneman-denylist.txt` + `.personal-denylist.txt` | CONTEXT D-06 allows either; single file with categorized comments is simpler |
| GitHub template toggle | cookiecutter/copier | STACK.md rejected: adds Python install step, breaks clone-and-go |
| GHA `workflow_dispatch` for release | Maintainer-local `bin/release.sh` | CONTEXT deferred; v1.1 is local-only |

**Installation:**
```bash
# No new packages required. Existing baseline suffices.
# CI-side in .github/workflows/*.yml:
#   - uses: actions/checkout@v6
#   - uses: actions/setup-python@v6
#     with: { python-version: '3.12' }
#   - run: pip install pyyaml
```

**Version verification** (performed 2026-04-15):
- `actions/checkout@v6` — verified via milestone STACK.md; major-tag pinning is GitHub's recommended practice for `actions/*` org actions.
- `actions/setup-python@v6` — same.
- `ubuntu-latest` → Ubuntu 24.04 LTS (fully rolled out since Oct 30 2025 per Ubuntu Discourse PSA).
- No npm/pip versions to verify for Phase 7 — zero new deps.

---

## Architecture Patterns

### Recommended Directory Structure (end state of Phase 7)

```
/
├── AGENTS.md                         # neutralized: placeholders + See: examples/kahneman/... pointers
├── CLAUDE.md                         # byte-identical dup (TMPL-10, D-03)
├── README.md                         # TMPL-02 — tech-Obsidian voice (D-10)
├── LICENSE                           # MIT (TMPL-03, D-01)
├── PRIVACY.md                        # TMPL-09 — user-facing privacy explainer (D-12)
├── .gitignore                        # TMPL-04 — four categories (D-14)
├── .gitattributes                    # *.md text eol=lf (STACK recommendation)
├── .neutrality-denylist.txt          # NEUT-08 — human-curated after auto-derivation (D-05)
│                                       (or split into .kahneman-denylist.txt + .personal-denylist.txt)
├── bin/
│   ├── ingest.sh                     # unchanged
│   ├── search.sh                     # unchanged
│   ├── validate-op.sh                # unchanged
│   ├── lint.sh                       # MODIFIED: EXCLUDE_DIRS adds 'examples'; example: true honored
│   ├── check-neutrality.sh           # NEW — NEUT-06, NEUT-08 combined
│   ├── sync-claude.sh                # NEW — AGENTS.md → CLAUDE.md byte-copy
│   ├── release.sh                    # NEW — orphan-branch publish, --dry-run default, --apply confirms
│   └── requirements-sync.sh          # NEW — DEBT-03 mechanical traceability check
├── schema/
│   └── AGENTS.template.md            # NEW — 4 placeholders for Phase 8 wizard
├── examples/
│   └── kahneman/
│       ├── README.md                 # NEUT-05 — reference-example explainer (D-13)
│       ├── index.md                  # moved from wiki/index.md (Kahneman subset) or new cluster index
│       ├── log.md                    # Kahneman entries (preserves §12 append-only invariant)
│       ├── entities/daniel-kahneman.md
│       ├── concepts/prospect-theory.md
│       ├── concepts/loss-aversion.md
│       ├── concepts/cognitive-biases.md
│       ├── comparisons/system-1-vs-system-2.md
│       ├── overviews/decision-making.md
│       └── sources/
│           ├── src-2026-04-09-thinking-fast-and-slow-part1.md
│           └── src-2026-04-10-kahneman-prospect-theory.md
├── wiki/
│   ├── index.md                      # skeleton only — "no content yet" (TMPL-05)
│   ├── log.md                        # empty §12 frame — personal-decision entries move or are stripped
│   └── decisions/
│       └── dr-2026-04-15-kahneman-to-examples.md     # NEUT-07
├── docs/
│   ├── README.md                     # Diátaxis mapping (TMPL-07)
│   ├── quickstart.md                 # stub w/ Phase-8 markers (TMPL-06, D-11)
│   ├── guided-setup.md               # stub (Phase 8 owns)
│   ├── manual-setup.md               # stub (Phase 8 owns)
│   └── reference/
│       ├── index.md
│       ├── schema-tour.md            # stub (TMPL-08; Phase 12 fills)
│       ├── brownfield.md             # stub (TMPL-08; Phase 10/11 fills)
│       ├── privacy-model.md          # stub (TMPL-08; Phase 12 fills)
│       ├── ci.md                     # stub (TMPL-08; Phase 9 fills)
│       ├── examples.md               # stub (TMPL-08; Phase 12 fills)
│       └── release.md                # runbook (D-04; Phase 7 owns, Phase 12 polishes)
└── .github/
    ├── workflows/
    │   ├── neutrality.yml            # runs bin/check-neutrality.sh + CLAUDE.md drift check
    │   └── (lint.yml — deferred to Phase 9)
    ├── CODEOWNERS                    # optional in Phase 7 (Phase 9 owns fuller version)
    ├── PULL_REQUEST_TEMPLATE.md      # optional (Phase 9 owns)
    ├── ISSUE_TEMPLATE/*.yml          # optional (Phase 9 owns)
    ├── CONTRIBUTING.md               # deferred to Phase 9
    └── SECURITY.md                   # deferred to Phase 9
```

**Phase 7 vs Phase 8/9 ownership of `.github/`:** Phase 7 should ship the neutrality + CLAUDE-drift workflow only. PR template, CODEOWNERS, issue templates, CONTRIBUTING, SECURITY are Phase 9 deliverables per ROADMAP. Planner should not scope-creep those into Phase 7.

### Pattern 1: Bash CLI helper structure (follow `bin/lint.sh`)

**What:** Every new script (`check-neutrality.sh`, `sync-claude.sh`, `release.sh`, `requirements-sync.sh`) uses this skeleton.

**When to use:** All four new scripts in Phase 7.

**Example (canonical conventions from `bin/lint.sh` L1–100):**
```bash
#!/usr/bin/env bash
# bin/<name>.sh -- <one-line purpose tied to REQ-ID>.
# <one-paragraph description>. Zero LLM/API calls. Deterministic.
# Requires: python3 (+ PyYAML only if parsing YAML).
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: bin/<name>.sh [OPTIONS] [args]
<one-line summary>
Options:
  --help, -h          Show this help
  --dry-run           Report without mutating (where applicable)
  --format <text|json>  Output format (default: text)
  --strict            Exit non-zero on findings (advisory default)
Exit codes:
  0  Ran successfully (or advisory findings only)
  1  Script itself FAILED (prereqs missing, file not found)
  2  Strict mode: findings present
EOF
}

# flag parsing: case "$1" in ... esac
# validate python3 available: command -v python3
# do work via inline python3 heredoc: python3 - <<'PY' ... PY
```

### Pattern 2: Inline python3 heredoc for parsing / scanning

**What:** Single python3 block reads files, emits findings. No external python files.

**When to use:** `check-neutrality.sh` (grep-plus over paths), `requirements-sync.sh` (parse REQUIREMENTS.md table + all VERIFICATION.md files), `sync-claude.sh` (optional — `cp` suffices).

**Example pattern** (precedent from `bin/lint.sh`):
```bash
FINDINGS=$(WIKI_DIR="$WIKI_DIR" python3 - <<'PY'
import os, sys, re, yaml
wiki_dir = os.environ["WIKI_DIR"]
# ... scan ...
# emit newline-delimited records or JSON depending on --format
PY
)
```

### Pattern 3: `--dry-run` default + `--apply` with interactive confirm (for destructive ops)

**What:** Scripts that modify repo/remote state default to printing what they would do; require explicit `--apply` + y/N prompt before mutating.

**When to use:** `bin/release.sh` (per D-04).

**Example structure:**
```bash
APPLY=0
while [ "$#" -gt 0 ]; do
    case "$1" in
        --apply) APPLY=1; shift ;;
        --dry-run) APPLY=0; shift ;;
        # ...
    esac
done

# always compute + print plan
echo "Would publish orphan branch 'release/v1.1' from worktree '$WORKTREE'"
echo "Files to include: $(find ... | wc -l)"
echo "Refs/tags to create: v1.1"

if [ "$APPLY" -eq 0 ]; then
    echo "(dry-run) Pass --apply to execute."
    exit 0
fi

read -r -p "Proceed with publish? [y/N] " resp
case "$resp" in
    y|Y|yes) ;;
    *) echo "Aborted."; exit 0 ;;
esac

# ... mutating work ...
```

### Pattern 4: `lint.sh EXCLUDE_DIRS` extension

**What:** Add `'examples'` to the existing set at `bin/lint.sh:180`; extend path-filtering loop at `:222` to also skip individual files whose frontmatter contains `example: true`.

**Current code (verified 2026-04-15):**
```python
# bin/lint.sh:178-180
# Files to exclude from lint candidate list
EXCLUDE_DIRS = {'maintenance'}
```

**Extension for NEUT-04:**
```python
EXCLUDE_DIRS = {'maintenance', 'examples'}

# At :222 (or equivalent per-file loop), add:
# if frontmatter.get('example') is True: skip_file()
# This handles pages with example: true outside examples/ (D-09 fallback).
```

### Pattern 5: Orphan-branch release via `git worktree` (safer than in-place orphan)

**What:** Use a detached worktree to stage the public release, never touching the canonical working tree's refs/history.

**Why preferred over `git checkout --orphan` in place:** If the maintainer Ctrl-Cs mid-script or the push fails, the main worktree is untouched. In-place orphan requires a subsequent `git checkout master` which can leave stale index state.

**Flow:**
1. Create temp worktree: `git worktree add --detach /tmp/release-v1.1 HEAD`
2. In that worktree: `rm -rf .git` then `git init` (fresh history) — or `git checkout --orphan release`
3. Stage: copy the sanitized file tree (respecting `.gitignore`, **excluding `.planning/`, any `.brownfield/`, any creator-only pages**); run `check-neutrality.sh` as a pre-flight
4. Commit: `git add -A && git commit -m "v1.1 release"` with maintainer-configured identity
5. Tag: `git tag v1.1`
6. Push: `git push <target-remote> HEAD:main && git push <target-remote> v1.1`
7. Cleanup: `git worktree remove /tmp/release-v1.1`

### Anti-Patterns to Avoid

- **Hand-writing CLAUDE.md content separately from AGENTS.md.** D-03 locks byte-dup; any drift is a CI failure.
- **Baking a specific `<org>/<repo>` into committed files.** D-02 requires placeholders in README/docs/CI config; `bin/release.sh` takes remote as flag.
- **Stripping Kahneman content without a decision record.** NEUT-07 is non-optional; SUPERSEDE-class per AGENTS.md §11.4.
- **Publishing denylist without human review.** D-05 auto-derive is a candidate list only; the planner MUST include a human-review task before committing `.neutrality-denylist.txt`.
- **Running `bin/release.sh` from the canonical working tree** (no worktree). Risk of corrupting main refs on Ctrl-C.
- **Putting PR/issue templates / CONTRIBUTING.md / CODEOWNERS in Phase 7.** Those are Phase 9 per ROADMAP; don't scope-creep.
- **Treating `docs/quickstart.md` as a full tutorial.** D-11 locks it as a stub naming the Phase-8 flow.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| CLAUDE.md ↔ AGENTS.md parity | Symlink, shim, dual-authored docs | **Byte copy via `bin/sync-claude.sh` (D-03) + CI byte-equality check** | Windows/cross-platform safety; deterministic diff on drift |
| Template repo generator | cookiecutter, copier, yeoman wrappers | **GitHub "Template repository" toggle** | Native feature since 2019; no install step; "Use this template" button is UX requirement TMPL-01 |
| Orphan-branch automation | GitHub Actions `workflow_dispatch` for publish | **Maintainer-local `bin/release.sh`** | CONTEXT deferred GHA path to v1.2; local execution keeps secrets/identity out of CI |
| Denylist maintenance | Hand-written term list from memory | **`bin/check-neutrality.sh --suggest-denylist` auto-derivation + human prune** | D-05 pattern; avoids missed personal terms AND false positives |
| YAML-aware `example: true` filter in lint | Regex over frontmatter block | **Reuse existing python3 + PyYAML path in `bin/lint.sh`** | Precedent in lint.sh; robust to YAML edge cases |
| Requirements-sync parser | grep/sed checkbox parsing | **python3 inline block parsing REQUIREMENTS.md table + per-phase VERIFICATION.md files** | D-16 needs structured output (markdown table + JSON); regex is fragile against future schema additions |
| Docs SSG | MkDocs / Docusaurus / VitePress | **Plain markdown** | STACK.md: MkDocs Material maintenance-mode Nov 2025, Insiders repo deleted May 2026; v1.2 decision not made |

**Key insight:** Phase 7 is a scaffolding phase — the leverage is in **reusing v1.0's primitives** (bash+python3 inline, lint.sh conventions, AGENTS.md §5 frontmatter extensibility, §11.4 decision records) and in **leaning on GitHub-native features** (template toggle, Actions) rather than introducing tooling layers.

---

## Runtime State Inventory

Phase 7 is a rename/refactor/relocate phase. Explicit inventory required.

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| **Stored data** | None — project is a git repo of markdown files; no databases, no caches tied to page paths. Obsidian's internal cache (`.obsidian/cache`) is already in .gitignore (D-14) and rebuilds from the vault on open. | None (verified: no `.db`, `.sqlite`, `.chroma`, Mem0, Redis or similar artifacts in tree; confirmed by directory listing). |
| **Live service config** | None — no external services configured (no n8n, Datadog, Cloudflare, Tailscale etc. in this project). CI workflows on GitHub Actions are file-based in `.github/workflows/` (tracked in git). | None. |
| **OS-registered state** | None — no Windows Task Scheduler, launchd, systemd, cron, or pm2 entries reference this project by path or name. | None. |
| **Secrets / env vars** | None — the project has no secrets, no `.env`, no SOPS, no CI secret refs. README/docs/CI use `<org>/<repo>` placeholders (D-02) so no hardcoded identity. | None. |
| **Build artifacts / installed packages** | None — project is pure bash + ad-hoc python3. No `setup.py`, no `pyproject.toml`, no `package.json`, no egg-info, no compiled binaries. | None. |

**Content-path rename inventory (the `wiki/` → `examples/kahneman/` move, NEUT-01):**

The *sole* stateful surface that tracks page paths is the **wiki content graph itself** (wikilinks in markdown). Specifically:

| Surface | Contains Kahneman path references | Action |
|---------|-----------------------------------|--------|
| `wiki/index.md` | Wikilinks to Kahneman cluster | Rewrite to point to `examples/kahneman/...` OR strip (D-10 / TMPL-05 says skeleton-only). **Planner decision: strip, since wiki ships empty.** |
| `wiki/log.md` | Kahneman ingest entries | Move Kahneman entries to `examples/kahneman/log.md`; keep log.md skeleton in wiki/. |
| `wiki/overviews/decision-making.md` | Related-pages wikilinks | **Move entire file to `examples/kahneman/overviews/` — it is Kahneman-domain content.** |
| `wiki/overviews/personal-decision-patterns.md` | `privacy: local_only` — creator's personal decision journal | **REMOVE** — `local_only` content must never ship in public template. Not a Kahneman example; it's a personal page. This is a NEUT-08 target. |
| `wiki/sources/src-2026-04-10-personal-decision-journal.md` | `privacy: local_only` — creator's journal source | **REMOVE** — same reason. NEUT-08 target. |
| `wiki/sources/src-2026-04-09-thinking-fast-and-slow-part1.md` | Kahneman source page | **MOVE** to `examples/kahneman/sources/`. |
| `wiki/sources/src-2026-04-10-kahneman-prospect-theory.md` | Kahneman source page | **MOVE** to `examples/kahneman/sources/`. |
| `wiki/maintenance/lint-report.md` | May contain Kahneman page references from prior lint runs | **Regenerate or remove** — will be stale after the move anyway. |
| `AGENTS.md` (repo root) §16 appendix | Kahneman-specific Dataview examples | Rewrite with generic placeholders + `See: examples/kahneman/...` pointer per D-07. |
| `.planning/**` (entire dir) | Heavy Kahneman references in research/phase docs | **gitignored (D-14) and excluded from orphan-branch release — verified by `bin/release.sh` pre-flight.** |

**Critical non-obvious item:** `wiki/overviews/personal-decision-patterns.md` and `wiki/sources/src-2026-04-10-personal-decision-journal.md` are `privacy: local_only` creator content — they are NOT Kahneman examples and do NOT belong in `examples/kahneman/`. They must be deleted from the public template (or at minimum, verified absent from the release worktree by the neutrality gate). The NEUT-08 denylist derivation (D-05) will surface terms from these pages.

**Canonical question answered:** After every file in the repo is updated and the orphan-branch publish runs, the *only* runtime artifact that persists with old paths is the user's local Obsidian workspace cache — which is per-user, not shipped, and rebuilds automatically. No stored data, service config, OS state, secrets, or build artifacts carry references to the pre-move layout.

---

## Common Pitfalls

### Pitfall 1: C-1 — Creator-content leakage via incomplete neutralization

**What goes wrong:** Kahneman string or `local_only` term survives in README, AGENTS.md, docs/, or `.github/` — public repo ships with creator's fingerprint. Or: v1.0 git history is reachable because maintainer used `git push --force` instead of orphan-branch workflow, exposing the creator's entire vault history.

**Why it happens:** (1) grep-based neutralization misses one string in a file not-yet-in-scan; (2) denylist omits a creator-specific term the maintainer forgot; (3) `.planning/` leaks if `bin/release.sh` doesn't explicitly exclude it; (4) in-place `git checkout --orphan` leaves refs/reflogs reachable on the remote.

**How to avoid:**
- `bin/check-neutrality.sh` enforces on every PR (NEUT-06, NEUT-08) before merge — blocking.
- `bin/release.sh` runs `check-neutrality.sh` as a **pre-flight** against the prepared worktree; hard-fail if anything trips.
- Orphan release uses **fresh `git init` in a separate worktree**, not in-place orphan (see Pattern 5).
- `.gitignore` has `.planning/` (D-14); release script double-checks via `grep -r` over the staged worktree.
- Human-review step for denylist (D-05) is explicit in the plan, not a silent auto-commit.
- Post-publish **smoke check**: fresh `git clone` of the public URL + `grep -rIn -e kahneman -e <personal-term> .` should return zero hits.

**Warning signs:** `grep -rIn kahneman docs/ AGENTS.md README.md` returns ≥1 hit; `git log --all --oneline` on the public repo shows more than one commit; `git reflog` on the public repo has entries predating the release.

### Pitfall 2: CLAUDE.md ↔ AGENTS.md drift

**What goes wrong:** Someone edits AGENTS.md without running `bin/sync-claude.sh`; CLAUDE.md falls out of sync; downstream agents see stale schema.

**Why it happens:** Pre-commit hook not installed (users can skip `.githooks/`); someone bypasses with `--no-verify`; CI skipped because of draft PR.

**How to avoid:**
- Byte-equality CI check runs on **every PR** (not just mergeable ones); fails merge if drift detected.
- `bin/sync-claude.sh` is trivially re-runnable and idempotent (a `cp`).
- Include install step in `docs/quickstart.md` stub (or `docs/reference/release.md`) for the pre-commit hook.
- Document the one-line manual fix (`bash bin/sync-claude.sh && git add CLAUDE.md`) in CI error output.

**Warning signs:** `cmp AGENTS.md CLAUDE.md` exits non-zero; CI byte-equality job fails.

### Pitfall 3: Denylist false-positives that block legitimate PRs

**What goes wrong:** Denylist includes common words (e.g., "decision", "journal", "personal") that appear legitimately in unrelated public content; PRs get blocked by noise; maintainers weaken the gate.

**Why it happens:** Auto-derivation without human review (D-05 warns against this); token extraction too aggressive.

**How to avoid:**
- D-05 pattern: multi-word phrases preferred; common English words explicitly excluded; human prunes before commit.
- `bin/check-neutrality.sh --suggest-denylist` output shows candidate + source-page context so reviewer can judge.
- Denylist file supports `#` comments — every term should be annotated with why it's banned.

**Warning signs:** Neutrality CI fails on a trivially-unrelated PR (e.g., a typo fix in a doc).

### Pitfall 4: `examples/` contaminating Obsidian graph view

**What goes wrong:** User opens the fresh template in Obsidian; graph view shows the Kahneman cluster as the bulk of the vault; feels "pre-used."

**Why it happens:** Obsidian doesn't natively honor `EXCLUDE_DIRS` from lint.sh; without `.obsidianignore` or workspace config, all markdown is indexed.

**How to avoid:**
- Ship `.obsidian/` config sketch — but **D-14 gitignores `workspace*.json` and `cache`**, so only version-safe files can be committed.
- Document in `docs/reference/examples.md` (Phase 12 — so Phase 7 just stubs it) how to collapse `examples/` in Obsidian.
- ARCHITECTURE.md gap: `.obsidianignore` vs separate vault for examples — verify during Phase 7 human review (open the fresh template in Obsidian, inspect graph).

**Warning signs:** Graph view dominated by Kahneman cluster on first open of fresh template.

### Pitfall 5: `requirements-sync.sh` false advisory output (premature)

**What goes wrong:** Run on in-progress branch; reports "drift" that's just a mid-phase state; maintainers learn to ignore the output.

**Why it happens:** Default advisory mode (D-15) means active-phase drift surfaces constantly; distinguishing signal from noise requires discipline.

**How to avoid:**
- D-15 locks advisory default; `--strict` only at milestone/phase close. Script docstring must make this explicit.
- Default output begins with a 1-line note: "Advisory mode — active-phase drift expected. Pass --strict at milestone close."
- CI consumers use JSON mode (D-16) and annotate but do not fail.

**Warning signs:** Developers `grep -v drift` the output; PR comments filtered out.

### Pitfall 6: Orphan-branch publish loses files via `.gitignore` overreach

**What goes wrong:** Release worktree respects `.gitignore` with `.planning/` entry — good. But `.gitignore` also has `.obsidian/workspace*.json` etc. If maintainer intended to ship a baseline `.obsidian/` config, it silently doesn't publish.

**Why it happens:** Template-starter-kit convention sometimes ships a minimal `.obsidian/app.json` or `graph.json`. D-14's scope covers `workspace*.json` and `cache` — those are still gitignored, correctly. But no `.obsidian/` non-workspace config is committed anyway in this repo.

**How to avoid:**
- `bin/release.sh --dry-run` lists the exact file tree it will publish; maintainer eyeballs for missing expected files.
- Runbook explicitly lists the minimum expected file set (README, LICENSE, PRIVACY, CLAUDE, AGENTS, .gitignore, bin/*, docs/**, examples/**, schema/**, wiki/index.md, wiki/log.md).

**Warning signs:** Dry-run file count differs from expected by more than 1–2 files without explanation.

---

## Code Examples

### Example 1: AGENTS.md neutralization pattern (NEUT-02, NEUT-03, D-07)

**Before (AGENTS.md, illustrative section):**
```markdown
### §5.2 Example: Concept page frontmatter

```yaml
type: concept
title: Prospect Theory
aliases: ["prospect theory"]
knowledge_domain: behavioral-economics
privacy: cloud_safe
# ...
```
```

**After (neutralized per D-07):**
```markdown
### §5.2 Example: Concept page frontmatter

```yaml
type: concept
title: {{CONCEPT_NAME_PLACEHOLDER}}
aliases: ["{{CONCEPT_ALIAS}}"]
knowledge_domain: {{PRIMARY_DOMAIN}}
privacy: {{DEFAULT_PRIVACY}}
# ...
```

See: `examples/kahneman/concepts/prospect-theory.md` for a concrete filled-in instance.
```

Key rules:
- Inline placeholders where value is domain-specific.
- Exactly one `See: examples/kahneman/<path>.md` pointer at section end (D-07).
- The four top-level AGENTS.template.md placeholders (D-08: `{{PRIMARY_DOMAIN}}`, `{{DEFAULT_PRIVACY}}`, `{{AGENT_FILENAME}}`, `{{DECAY_PROFILE}}`) substitute at wizard-run-time; inline illustrative placeholders (`{{CONCEPT_NAME_PLACEHOLDER}}`, etc.) are readability aids, not wizard placeholders.

### Example 2: `bin/check-neutrality.sh` skeleton

```bash
#!/usr/bin/env bash
# bin/check-neutrality.sh -- NEUT-06 + NEUT-08 gate.
# Greps public control-plane paths against a denylist (Kahneman terms + personal tokens).
# Exits 0 on clean; non-zero with offending path:line:term on match.
# Zero LLM/API calls. Deterministic.
set -euo pipefail

DENYLIST=".neutrality-denylist.txt"
PUBLIC_PATHS=("AGENTS.md" "CLAUDE.md" "README.md" "PRIVACY.md" "docs" ".github" "wiki" "bin")
EXCLUDE_PATHS=("examples")
SUGGEST_MODE=0
FORMAT="text"

while [ "$#" -gt 0 ]; do
    case "$1" in
        --help|-h) usage; exit 0 ;;
        --suggest-denylist) SUGGEST_MODE=1; shift ;;
        --format) FORMAT="$2"; shift 2 ;;
        *) echo "ERROR: unknown arg: $1" >&2; exit 1 ;;
    esac
done

if [ "$SUGGEST_MODE" -eq 1 ]; then
    # Walk wiki/ for privacy: local_only pages; emit candidate tokens (multi-word preferred,
    # common English words filtered). User curates before commit.
    python3 - <<'PY'
# ... token extraction ...
PY
    exit 0
fi

if [ ! -f "$DENYLIST" ]; then
    echo "ERROR: denylist not found at $DENYLIST" >&2
    exit 1
fi

# Load terms (skip blanks + # comments)
mapfile -t TERMS < <(grep -vE '^\s*(#|$)' "$DENYLIST")

FOUND=0
for term in "${TERMS[@]}"; do
    # Case-insensitive, fixed-string; restrict to public paths; exclude examples/
    if grep -rIinF --exclude-dir=examples -- "$term" "${PUBLIC_PATHS[@]}" 2>/dev/null; then
        FOUND=1
    fi
done

if [ "$FOUND" -ne 0 ]; then
    echo "NEUTRALITY GATE FAILED: denylist terms present in public paths." >&2
    exit 2
fi
echo "Neutrality: clean."
```

### Example 3: `bin/sync-claude.sh` (trivial)

```bash
#!/usr/bin/env bash
# bin/sync-claude.sh -- TMPL-10, D-03: AGENTS.md → CLAUDE.md byte copy.
set -euo pipefail

SRC="AGENTS.md"
DST="CLAUDE.md"

if [ ! -f "$SRC" ]; then
    echo "ERROR: $SRC missing" >&2
    exit 1
fi

cp "$SRC" "$DST"

# Verify
if ! cmp -s "$SRC" "$DST"; then
    echo "ERROR: post-copy byte-mismatch (should be impossible)" >&2
    exit 1
fi
echo "Synced $SRC -> $DST"
```

CI byte-equality check (separate step):
```bash
cmp -s AGENTS.md CLAUDE.md || {
    echo "::error::CLAUDE.md drift from AGENTS.md. Run: bash bin/sync-claude.sh && git add CLAUDE.md"
    exit 1
}
```

### Example 4: `bin/lint.sh` `EXCLUDE_DIRS` extension

```python
# bin/lint.sh:178-180 — BEFORE
EXCLUDE_DIRS = {'maintenance'}
```
```python
# bin/lint.sh:178-180 — AFTER (NEUT-04)
EXCLUDE_DIRS = {'maintenance', 'examples'}
```

At the per-file loop (around line 222), add a frontmatter check (pseudocode; adapt to lint.sh's existing idioms):
```python
# after parsing frontmatter for a page
if frontmatter.get('example') is True:
    continue  # Skip health checks (D-09 fallback for out-of-tree examples)
```

### Example 5: Orphan-branch release via worktree

```bash
# bin/release.sh (abbreviated; full script follows Pattern 3)
TARGET_REMOTE="${TARGET_REMOTE:-}"  # required via flag or env
TAG="${TAG:-v1.1}"
WORKTREE="/tmp/gsd-release-$TAG-$$"

[ -n "$TARGET_REMOTE" ] || { echo "ERROR: --remote required" >&2; exit 1; }

# 1. Stage in detached worktree
git worktree add --detach "$WORKTREE" HEAD

# 2. Fresh history
cd "$WORKTREE"
rm -rf .git
git init --initial-branch=main >/dev/null

# 3. Remove paths that must not publish (belt-and-suspenders beyond .gitignore)
rm -rf .planning/ .brownfield/ .obsidian/workspace*.json

# 4. Pre-flight neutrality gate
bash bin/check-neutrality.sh || { echo "NEUTRALITY FAILED in worktree. Aborting." >&2; exit 2; }

# 5. Dry-run reporting
echo "Target remote: $TARGET_REMOTE"
echo "Tag: $TAG"
echo "Worktree: $WORKTREE"
echo "Files:"
find . -type f | sort
echo "Commit: one commit, message 'v1.1 release'"

if [ "$APPLY" -eq 0 ]; then
    echo "(dry-run) Pass --apply to execute."
    exit 0
fi

# 6. Confirm + publish
read -r -p "Proceed with publish? [y/N] " resp
case "$resp" in y|Y|yes) ;; *) echo "Aborted."; exit 0 ;; esac

git add -A
git commit -m "v1.1 release"
git tag "$TAG"
git push "$TARGET_REMOTE" HEAD:main
git push "$TARGET_REMOTE" "$TAG"

# 7. Cleanup
cd -
git worktree remove "$WORKTREE"
```

### Example 6: `bin/requirements-sync.sh` output format (D-16)

```
REQ-ID    | REQUIREMENTS.md | VERIFICATION.md | Drift
----------|-----------------|-----------------|---------------------------
TMPL-01   | Pending         | (no VERIFICATION.md yet) | Expected — Phase 7 in progress
TMPL-03   | Pending         | Complete        | DRIFT — REQUIREMENTS should flip to Complete
NEUT-01   | Pending         | (not found)     | OK — Phase 7 not yet run
DEBT-03   | Pending         | (self)          | OK
```

JSON mode (for CI):
```json
[
  {"req_id": "TMPL-03", "requirements_md": "Pending", "verification_md": "Complete", "drift": true, "note": "Flip REQUIREMENTS to Complete"},
  {"req_id": "NEUT-01", "requirements_md": "Pending", "verification_md": null, "drift": false, "note": "Phase not yet run"}
]
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| MkDocs Material for template docs | Plain markdown in `/docs/` | Nov 2025 (maintenance-mode); May 2026 (Insiders repo deleted) | Do NOT pre-wire MkDocs. Plain markdown renders in GitHub + Obsidian. (STACK.md HIGH confidence) |
| `actions/checkout@v5` / `setup-python@v5` | `@v6` | 2025 | Major-tag pinning `@v6` is GitHub's recommended practice; avoids SHA-pin rot |
| Ubuntu 22.04 on `ubuntu-latest` | Ubuntu 24.04 LTS | Fully rolled out Oct 30 2025 | Python 3.12 available natively; no matrix needed for lint |
| `git checkout --orphan` in-place | `git worktree add` + fresh `git init` | General git best practice | Safer on Ctrl-C; main working tree untouched |

**Deprecated / outdated (do not use):**
- **MkDocs Material Insiders** — repo deleted May 1, 2026; any references in training data are obsolete.
- **cookiecutter / copier for GitHub templates** — GitHub's native template toggle supersedes for clone-and-go UX.
- **`gum` / `whiptail` / `dialog` for bash wizards** — milestone STACK.md rejected; violates clone-and-go.
- **Symlinks for cross-file parity (CLAUDE.md → AGENTS.md)** — D-03 rejected; Windows/Obsidian incompatibility.

---

## Open Questions

1. **Should `.obsidianignore` ship with the template to hide `examples/` from Obsidian graph view?**
   - What we know: ARCHITECTURE.md flags this as a gap. Obsidian honors `.obsidianignore` for indexing/graph.
   - What's unclear: 2026 Obsidian behavior w.r.t. committed `.obsidianignore` — may need manual verification by opening fresh template.
   - Recommendation: Phase 7 ships a minimal `.obsidianignore` with `examples/`. Document the effect in `docs/reference/examples.md` stub. Mark for human verification at phase-gate review. Risk is low (file is trivially removable by user).

2. **Single `.neutrality-denylist.txt` vs split files?**
   - What we know: D-06 allows either; single file with categorized comments acceptable.
   - What's unclear: whether splitting clarifies audit trails for different pitfall categories (C-1 Kahneman vs C-1 personal).
   - Recommendation: **Single file with `# Section: Kahneman` / `# Section: Personal vault terms` comment banners.** Simpler CI; still auditable. Matches "categorized comments" pattern D-06 explicitly endorses.

3. **Does the pre-commit hook for `sync-claude.sh` ship as `.githooks/` + install script, or as a documented manual install?**
   - What we know: CONTEXT lists this under Claude's Discretion.
   - What's unclear: adoption friction vs safety.
   - Recommendation: **Both.** Ship `.githooks/pre-commit` + a one-line `bin/install-hooks.sh` that runs `git config core.hooksPath .githooks`. Document the install step in `docs/reference/release.md` runbook. Users who don't install it still get the CI gate as the hard safety net (D-03 is explicit: CI blocks merge on drift regardless of local hook).

4. **Where does the `bin/upgrade.sh` / template-fork ownership boundary get documented?**
   - What we know: CONTEXT defers `bin/upgrade.sh` to v1.2 but wants the ownership boundary documented now.
   - What's unclear: best home — `docs/reference/release.md` footer, `PROJECT.md`, or a new `docs/reference/ownership.md`.
   - Recommendation: **`docs/reference/release.md` footer** — it's contextually adjacent (release runbook is the maintainer's entry point for anything release-related). Add a "Template upgrades (deferred to v1.2)" H2 with a short "what users own vs what template owns" statement.

5. **NEUT-07 decision record filename — 2026-04-15 or execution date?**
   - What we know: CONTEXT says "or the actual Phase-7 execution date"; today is 2026-04-15.
   - Recommendation: Use execution date at time of the rename task (whichever wave does NEUT-01). If Phase 7 starts and completes 2026-04-15, the filename is `dr-2026-04-15-kahneman-to-examples.md`; if it straddles days, use the day NEUT-01 is committed.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| bash | All new scripts | ✓ (assumed — this is the project baseline) | ≥ 4 | — |
| python3 | check-neutrality.sh, requirements-sync.sh, lint.sh | ✓ (baseline) | ≥ 3.10 | — |
| PyYAML | lint.sh extension (NEUT-04) | ✓ (baseline) | any | — |
| git | release.sh, orphan-branch workflow | ✓ (baseline) | ≥ 2.30 (for `worktree add --detach`) | — |
| GitHub Actions runner | neutrality.yml CI workflow | N/A locally; ✓ on GitHub | `ubuntu-latest` → 24.04 | — |
| cmp (coreutils) | CLAUDE.md byte-equality check | ✓ (Linux/macOS default) | — | — |
| Obsidian (for human verification of graph view) | `.obsidianignore` effectiveness check | Maintainer-dependent | ≥ 1.5 | Documented manual checklist if maintainer doesn't have Obsidian open at phase-gate |

**Missing dependencies with no fallback:** None.

**Missing dependencies with fallback:** Obsidian — if unavailable at phase-gate review, the `.obsidianignore` effect is verified by a documented manual checklist deferred to Phase 12's Obsidian/Dataview verification gate (DEBT-01).

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | **bash + shunit2-style assertions** via inline scripts, consistent with v1.0 phases 3/5/6 pattern. Plus `pytest`/plain `python -m unittest` for python-heavy verification (requirements-sync.sh output parsing). |
| Config file | None — tests live as `tests/phase-07/*.sh` or executable under `bin/` prefixed `test_`. (v1.0 precedent: verification scripts live under phase VERIFICATION.md companion files.) |
| Quick run command | `bash tests/phase-07/run.sh` (aggregator) — ≤ 15 s for unit-level checks |
| Full suite command | `bash tests/phase-07/run.sh --full` — includes orphan-branch dry-run roundtrip + fresh-clone smoke (≤ 60 s) |
| Phase gate | All tests green before `/gsd:verify-work`; orphan-branch publish tested via `--dry-run` (no actual push) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TMPL-01 | Repo is a GitHub Template | manual-only | (verified by maintainer in GitHub Settings) | N/A — out-of-band |
| TMPL-02 | `README.md` exists with ≤60s pitch + link to docs/quickstart.md | unit | `bash tests/phase-07/test_readme.sh` | ❌ Wave 0 |
| TMPL-03 | `LICENSE` present (MIT) | unit | `grep -q 'MIT License' LICENSE && grep -q 'Permission is hereby granted' LICENSE` | ❌ Wave 0 |
| TMPL-04 | `.gitignore` covers four categories | unit | `bash tests/phase-07/test_gitignore.sh` (greps for each required entry) | ❌ Wave 0 |
| TMPL-05 | `wiki/` skeleton-only | unit | `bash tests/phase-07/test_wiki_skeleton.sh` (verifies only index.md + log.md + decisions/) | ❌ Wave 0 |
| TMPL-06 | `/docs/` four-track exists | unit | `bash tests/phase-07/test_docs_skeleton.sh` | ❌ Wave 0 |
| TMPL-07 | `docs/README.md` names Diátaxis mapping | unit | `grep -qi diátaxis docs/README.md` + grep for each of 4 track names | ❌ Wave 0 |
| TMPL-08 | `docs/reference/*.md` stubs exist | unit | `bash tests/phase-07/test_reference_stubs.sh` | ❌ Wave 0 |
| TMPL-09 | `PRIVACY.md` present with tier language | unit | `grep -q 'local_only' PRIVACY.md && grep -q 'cloud_safe' PRIVACY.md` | ❌ Wave 0 |
| TMPL-10 | `CLAUDE.md` byte-equal to AGENTS.md | unit | `cmp -s AGENTS.md CLAUDE.md` | ❌ Wave 0 |
| TMPL-11 | Orphan-branch release script works dry-run | integration | `bash bin/release.sh --dry-run --remote dummy` exits 0 and prints plan | ❌ Wave 0 |
| NEUT-01 | Kahneman cluster in `examples/kahneman/` with wikilinks intact | integration | `bash tests/phase-07/test_kahneman_moved.sh` (verifies 7 pages + sources + wikilink resolvability) | ❌ Wave 0 |
| NEUT-02 | AGENTS.md contains no Kahneman-specific tokens | unit | `! grep -iE 'kahneman\|prospect.theory\|loss.aversion' AGENTS.md` | ❌ Wave 0 |
| NEUT-03 | AGENTS.md contains `See: examples/kahneman/...` pointers | unit | `grep -c 'See: examples/kahneman/' AGENTS.md` ≥ N (N per D-07 section count) | ❌ Wave 0 |
| NEUT-04 | `bin/lint.sh` skips `examples/` and `example: true` pages | integration | `bash tests/phase-07/test_lint_exclude.sh` (fixture with both cases) | ❌ Wave 0 |
| NEUT-05 | `examples/kahneman/README.md` has required sections | unit | `bash tests/phase-07/test_kahneman_readme.sh` (section headings per D-13) | ❌ Wave 0 |
| NEUT-06 | `bin/check-neutrality.sh` fails on Kahneman term in public path | integration | `bash tests/phase-07/test_neutrality_gate.sh` (inject fixture → expect exit 2) | ❌ Wave 0 |
| NEUT-07 | Decision record file exists, SUPERSEDE-class | unit | `test -f wiki/decisions/dr-*-kahneman-to-examples.md && grep -q 'class: SUPERSEDE' wiki/decisions/dr-*-kahneman-to-examples.md` | ❌ Wave 0 |
| NEUT-08 | Denylist gate fails on personal-vault term in public path | integration | `bash tests/phase-07/test_denylist_gate.sh` | ❌ Wave 0 |
| DEBT-03 | `bin/requirements-sync.sh` emits advisory table; `--strict` exits non-zero on drift | integration | `bash tests/phase-07/test_requirements_sync.sh` (fixture REQUIREMENTS.md + VERIFICATION.md) | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `bash tests/phase-07/run.sh` — ≤ 15 s, all unit tests + structural integration checks.
- **Per wave merge:** `bash tests/phase-07/run.sh --full` — includes orphan-branch dry-run roundtrip + fresh-clone smoke (clone into `/tmp`, run lint, run neutrality, grep for forbidden terms).
- **Phase gate:** Full suite green + manual verification (1) fresh Obsidian open against template shows `examples/` collapsible, (2) maintainer confirms GitHub "Template repository" toggle enabled post-publish.

### Wave 0 Gaps

- [ ] `tests/phase-07/run.sh` — aggregator (Wave 0 priority 1)
- [ ] `tests/phase-07/fixtures/` — fixture dir for neutrality + denylist + lint-exclude + requirements-sync tests
- [ ] `tests/phase-07/test_readme.sh`, `test_gitignore.sh`, `test_wiki_skeleton.sh`, `test_docs_skeleton.sh`, `test_reference_stubs.sh`, `test_kahneman_moved.sh`, `test_kahneman_readme.sh`, `test_lint_exclude.sh`, `test_neutrality_gate.sh`, `test_denylist_gate.sh`, `test_requirements_sync.sh`
- [ ] No framework install needed — shunit2 not required; bash + `[ … ]` assertions + exit-on-fail (`set -e`) is consistent with v1.0 phase verification scripts.

---

## Sources

### Primary (HIGH confidence)

- `.planning/phases/07-neutral-template-foundation/07-CONTEXT.md` — authoritative user decisions (D-01 through D-17).
- `.planning/REQUIREMENTS.md` — REQ-ID definitions for TMPL-01..11, NEUT-01..08, DEBT-03.
- `.planning/ROADMAP.md` §Phase 7 — scope, dependencies, success criteria.
- `.planning/research/ARCHITECTURE.md` — Decisions 1, 2 (template substitution + Kahneman move) directly relevant; Decision 7 (docs structure).
- `.planning/research/STACK.md` — GitHub template setting, Actions `@v6` pins, Ubuntu 24.04 rollout, MkDocs maintenance-mode (all verified 2026-04).
- `.planning/research/PITFALLS.md` — C-1 (creator-content leakage) mitigation checklist; M-10 / M-12 scheduled for Phase 12.
- `.planning/research/SUMMARY.md` — milestone-wide phase sequencing rationale.
- `AGENTS.md` (repo root) — canonical schema being neutralized; §11.4 SUPERSEDE record class.
- `bin/lint.sh` (L178-222) — `EXCLUDE_DIRS` extension point verified by direct read 2026-04-15.
- `wiki/` directory listing (verified 2026-04-15) — identified 7 Kahneman pages + 2 Kahneman sources + 1 personal-journal source + 1 personal-decision-patterns overview page requiring move/removal.

### Secondary (MEDIUM confidence)

- [Diátaxis framework](https://diataxis.fr) — canonical reference, stable.
- GitHub Docs — template repository feature + CODEOWNERS + PR templates (via STACK.md 2026 verification).
- Ubuntu Discourse PSA — Ubuntu 24.04 rollout on `ubuntu-latest` (via STACK.md).

### Tertiary (LOW confidence)

- `.obsidianignore` behavior in Obsidian 2026 — flagged as Open Question #1; human verification needed.

---

## Metadata

**Confidence breakdown:**
- Standard Stack: **HIGH** — zero new deps; all verified in milestone STACK.md; lint.sh extension point verified by direct file read.
- Architecture: **HIGH** — Decisions 1 and 2 from milestone ARCHITECTURE.md directly govern this phase; CONTEXT.md locks remaining ambiguities (D-01..D-17).
- Pitfalls: **HIGH** — C-1 is the single dominant risk; mitigation checklist in PITFALLS.md is operationalized here with three gates (neutrality script + orphan release + denylist human review).
- Runtime State Inventory: **HIGH** — direct filesystem inspection confirmed no stored data, service config, OS state, secrets, or build artifacts carry path references. Only surface is the wiki content graph, fully enumerated.
- Validation Architecture: **MEDIUM-HIGH** — test structure follows v1.0 phase-verification precedent; fixture patterns straightforward; orphan-branch dry-run is novel but exercised via `--dry-run` flag (not an actual push).

**Research date:** 2026-04-15
**Valid until:** 2026-05-15 (GitHub Actions version pins and Ubuntu rollout state are stable at monthly horizon; flag for re-verification if Phase 7 slips past May 2026).
