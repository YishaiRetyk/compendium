# Phase 7: Neutral Template Foundation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-15
**Phase:** 07-neutral-template-foundation
**Areas discussed:** Repo identity/license/release, Denylist seed terms, AGENTS.md neutralization + README voice, requirements-sync behavior, Quickstart/gitignore/example semantics/PRIVACY.md, examples/kahneman/README

---

## Gray Area Selection

| Option | Description | Selected |
|--------|-------------|----------|
| Repo identity, license & orphan-branch | Repo name, MIT vs Apache-2.0, CLAUDE.md form, orphan-branch runbook | ✓ |
| Denylist seed terms | NEUT-08 personal-vault strings beyond Kahneman | ✓ |
| AGENTS.md neutralization + README voice | Inline placeholders vs pointers; README pitch tone | ✓ |
| requirements-sync behavior | DEBT-03 block vs warn; output format; scope | ✓ |

---

## Repo Identity, License, Release

### License (TMPL-03)

| Option | Description | Selected |
|--------|-------------|----------|
| MIT | Shortest, permissive, matches solo-maintained starter default | ✓ |
| Apache-2.0 | Patent grant + NOTICE; heavier | |
| CC BY 4.0 docs + MIT code | Dual-license, more ceremony | |

**Rationale:** MIT aligns with the lightweight template posture.

### Repo Identity

| Option | Description | Selected |
|--------|-------------|----------|
| Decide at release time | Placeholders `<org>/<repo>` until publish | ✓ |
| Name in hand | User supplies concrete org/repo now | |

**Rationale:** Avoid baking a name into committed files; `bin/release.sh` takes target as arg.

### CLAUDE.md form (TMPL-10)

| Option | Description | Selected |
|--------|-------------|----------|
| Symlink CLAUDE.md → AGENTS.md | Single source, Windows symlink fragility | |
| Duplicate content + CI byte-equality | Cross-platform safe; CI enforces; AGENTS.md canonical, CLAUDE.md synced mechanically | ✓ |
| 1-line shim pointer | Simplest, weaker UX, agent-dependent | |

**Rationale:** Template must work cross-platform without asking users to fix git symlink config; CI prevents drift.

### Orphan-branch runbook (TMPL-11)

| Option | Description | Selected |
|--------|-------------|----------|
| Manual runbook only | docs/reference/release.md, user executes | |
| `bin/release.sh` + runbook | Mechanical script + intent/prereq doc, user-invoked | ✓ |
| GitHub Actions workflow | Highest automation, token/secret complexity | |

**Rationale:** Release is mechanical enough to script but sensitive enough to stay user-invoked.

---

## Follow-ups: Sync mechanism + release flags

### CLAUDE.md sync mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| `bin/sync-claude.sh` + pre-commit + CI | Belt + suspenders enforcement | ✓ |
| CI-only check | No hook; maintainer copies manually | |
| Generated at release only | Dev-branch drift invisible until release | |

### `bin/release.sh` default mode

| Option | Description | Selected |
|--------|-------------|----------|
| `--dry-run` ON by default, `--apply` to execute | Safe-by-default + confirmation prompt | ✓ |
| Interactive prompt, no flags | Simpler flag surface | |

**Notes:** Default run prints target branch/worktree, files/history published, refs/tags. `--apply` performs with confirmation. `--yes` deferred.

---

## Denylist Seed Terms

### Sourcing

| Option | Description | Selected |
|--------|-------------|----------|
| User provides list now | Manual inventory | |
| Auto-derive from `wiki/` local_only pages, human-prune | Mechanical-first, human-review-second | ✓ |
| Kahneman-only for now | Too weak for NEUT-08 | |

**Rationale:** Grounds list in actual private material at risk; still human-curated before enforcement.

### Storage

| Option | Description | Selected |
|--------|-------------|----------|
| `bin/check-neutrality.sh` + `.neutrality-denylist.txt` | Plain text file, easy to diff/prune | ✓ |
| Embedded array in CI workflow YAML | Couples list to CI config | |
| Inline in AGENTS.md §N | Mixes schema with enforcement | |

---

## AGENTS.md Neutralization + README

### Neutralization style (NEUT-02/03)

| Option | Description | Selected |
|--------|-------------|----------|
| Generic placeholders inline + pointer at section end | Readable standalone + concrete reference | ✓ |
| Pure pointer-style | Too easy to skip | |
| Neutral inline examples only | Loses real worked cluster value; drift risk | |

### Placeholder set

| Option | Description | Selected |
|--------|-------------|----------|
| `{{PRIMARY_DOMAIN}}` | User's domain | ✓ |
| `{{DEFAULT_PRIVACY}}` | local_only vs cloud_safe default | ✓ |
| `{{AGENT_FILENAME}}` | AGENTS.md vs CLAUDE.md self-reference | ✓ |
| `{{DECAY_PROFILE}}` | Staleness policy | ✓ |

**Notes:** `{{EXAMPLE_CLUSTER_REF}}` (research-proposed) rejected in favor of hardcoded pointers.

### README voice (TMPL-02)

| Option | Description | Selected |
|--------|-------------|----------|
| Technical Obsidian user, plainspoken | Direct, architecture-first, low-fluff | ✓ |
| Curious knowledge worker, slightly promotional | Motivating framing up front | |
| Draft myself after planning | Placeholder until user writes | |

---

## requirements-sync Behavior (DEBT-03)

### Enforcement

| Option | Description | Selected |
|--------|-------------|----------|
| Advisory / warn-only | Prints drift, exits 0 | |
| Block on drift | Hard-fail every PR | |
| Block only at milestone-close | Advisory in-between, `--strict` for release gate | ✓ |

**Rationale:** In-branch drift is normal; hard-blocking creates busywork. Milestone-close needs zero drift.

### Output

| Option | Description | Selected |
|--------|-------------|----------|
| Markdown table stdout + `--format json` | Human default, JSON for CI | ✓ |
| Plain stdout only | Simplest | |
| Writes a committed report file | Diff noise risk | |

### Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Entire REQUIREMENTS.md vs all VERIFICATION.md (global) | Catches cross-phase drift | |
| Current milestone only | Lighter, misses past drift | |
| Per-phase flag, global default | Flexibility without changing main behavior | ✓ |

---

## Additional Pass: Quickstart, .gitignore, example semantics, PRIVACY, Kahneman README

### docs/quickstart.md flow (TMPL-06)

| Option | Description | Selected |
|--------|-------------|----------|
| Fork → wizard → first ingest | Canonical happy path; Phase 7 stubs, Phase 8 fills | ✓ |
| Fork → manual-edit → first ingest | Duplicates manual-setup.md | |
| Stub only, full in Phase 8 | Least-risk sequencing | |

**Notes:** Target flow is option 1; Phase 7 implementation resembles option 3 until wizard lands.

### .gitignore scope (TMPL-04)

| Option | Description | Selected |
|--------|-------------|----------|
| Obsidian noise | `.obsidian/workspace*.json`, cache, `.trash/` | ✓ |
| Brownfield artifacts | `.brownfield/` | ✓ |
| Planning directory | `.planning/` | ✓ |
| OS/editor noise | `.DS_Store`, `Thumbs.db`, `*.swp`, `.idea/`, `.vscode/` | ✓ |

### NEUT-04 authority

| Option | Description | Selected |
|--------|-------------|----------|
| `examples/` primary, `example: true` fallback | Directory is strongest signal; frontmatter for out-of-tree | ✓ |
| Both equally authoritative | No hierarchy | |

**Notes:** Example pages excluded from normal wiki health checks; basic file integrity still runs. Copied example with `example:true` in `wiki/` continues to skip until flag removed.

### PRIVACY.md role (TMPL-09)

| Option | Description | Selected |
|--------|-------------|----------|
| Short explainer, AGENTS.md canonical | Tiers, operational meaning, pointer | ✓ |
| Full reference spec | Duplicates enforcement | |

### examples/kahneman/README.md (NEUT-05)

| Option | Description | Selected |
|--------|-------------|----------|
| Reference-example explainer | What/why/how-to-read + AGENTS.md section map + "do not edit" | ✓ |
| Tutorial walkthrough | Heavier; parallel onboarding risk | |
| Minimal stub | Low discoverable value | |

---

## Claude's Discretion

- Exact `.github/workflows/` file structure (single vs split).
- Pre-commit hook installation method (`.githooks/` + install script vs manual).
- Concrete markdown schema of `docs/reference/*.md` stubs.
- Flag parsing / exit code conventions in new bin scripts (follow `bin/lint.sh`).
- Whether NEUT-06 and NEUT-08 share one denylist file or use two.

## Deferred Ideas

- Hosted docs site (MkDocs/Docusaurus).
- `bin/upgrade.sh` for template-fork upgrades (v1.2).
- `--yes` non-interactive flag on `bin/release.sh`.
- GitHub Actions `workflow_dispatch` for orphan-branch publish.
- Multi-domain example stubs.
- `--milestone vX.Y` flag on `bin/requirements-sync.sh`.
- Light "example hygiene" lint mode.
- Custom copyright/attribution line.
