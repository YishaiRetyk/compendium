# Technology Stack — v1.1 Shareability Additions

**Project:** LLM Wiki Compiler
**Milestone:** v1.1 Shareability
**Researched:** 2026-04-15
**Scope:** Stack additions/changes ONLY for v1.1 new features. Existing v1.0 baseline (bash + python3 + pyyaml + git + Obsidian markdown) is fixed and not re-researched.

## Baseline (Fixed — Do Not Change)

| Technology | Role | Status |
|------------|------|--------|
| bash (>= 4) | CLI helpers (ingest/search/lint/validate-op) | Fixed — v1.0 validated |
| python3 + PyYAML | YAML parse/validate via inline heredocs | Fixed — zero-dep policy |
| git | Version control + attribution source-of-truth | Fixed |
| Obsidian-compatible markdown | Wiki artifact format | Fixed |
| AGENTS.md + CLAUDE.md | Agent-agnostic schema layer | Fixed |

**Zero-new-dep bias is the default.** A new dependency must pay for itself in concrete UX or capability gain that bash+python3 cannot credibly deliver.

---

## Recommended Additions (v1.1 Only)

### Guided Setup Wizard — Pure bash `read`, NO new dep

**Recommendation:** Use bash built-ins (`read -p`, `read -r`, case-statement menus). Do **not** adopt `gum`, `whiptail`, `dialog`, or Python `click`/`rich`.

**Why:**
- The wizard asks ~6 questions (domain name, privacy default, LLM agent choice, git remote, etc.) and writes a templated `AGENTS.md`. A flat `read -p` loop with validation is ~80 lines of bash and runs everywhere bash runs — including fresh Ubuntu/macOS without sudo.
- `gum` (charmbracelet/gum, latest ~v0.14+, last updated Apr 2026) is gorgeous but is a Go binary users must install (Homebrew, apt, winget, or manual download). That violates the "clone template and go" promise — a user without `gum` either hits a hard error or gets a degraded fallback, and we'd have to maintain both paths anyway.
- `whiptail` ships on Debian/Ubuntu by default (part of `newt`) but not on macOS or minimal distros; `dialog` has similar patchy availability. Neither is universal enough to assume.
- Python `click`/`rich` would drag in a second install path beyond the pyyaml baseline and conflict with the "inline python3 heredoc" convention the v1.0 stack committed to.
- The wizard runs **once per clone**. Spending user install-friction budget on a one-shot cosmetic win is a bad trade.

**Integration:** `bin/setup.sh` (new) — bash `read` prompts, validates inputs via the same inline python3+pyyaml pattern already used in `bin/validate-op.sh`, writes `AGENTS.md` from a template in `schema/templates/AGENTS.template.md`.

**Install footprint:** 0 bytes. No new dep.

**What NOT to add:** gum, whiptail, dialog, zenity, python-click, python-rich, inquirer, prompt-toolkit.

**Escape hatch:** If post-v1.1 user research shows `read`-based UX is a blocker, revisit with `gum` as an *optional enhancement* gated on `command -v gum` — never required.

**Confidence:** HIGH (verified current state of gum/whiptail via WebSearch; decision follows from zero-new-dep constraint stated in milestone context).

---

### GitHub Template Repo — Standard GitHub config files, NO new tooling

**Recommendation:** Use plain GitHub template-repository settings. Add canonical config files; do not adopt any template-generator framework (no cookiecutter, no copier, no yeoman).

**Why:**
- GitHub's native "Template repository" toggle (Settings → "Template repository" checkbox) has been stable since 2019 and in 2026 supports all the behavior v1.1 needs: users click "Use this template" → get a fresh repo with full file tree, no git history, ready to clone.
- No `.github/template.yml` file exists in GitHub's official config — the feature is a repo setting, not a file. (Easy to mis-remember; verified via GitHub Docs 2026.)
- Cookiecutter/copier would add a Python-level templating layer on top of what GitHub already does, and force users to install it before cloning. Breaks the "click button, clone, go" promise.

**Canonical config files to add** (all in repo root or `.github/`):

| File | Path | Purpose |
|------|------|---------|
| `CODEOWNERS` | `.github/CODEOWNERS` | Require review on schema changes (AGENTS.md, bin/*, schema/templates/*) |
| `PULL_REQUEST_TEMPLATE.md` | `.github/PULL_REQUEST_TEMPLATE.md` | Checklist: ingest source attached? lint passes? privacy tier declared? |
| `ISSUE_TEMPLATE/bug.yml` | `.github/ISSUE_TEMPLATE/bug.yml` | Issue form (form schema — stable GitHub feature since 2021) |
| `ISSUE_TEMPLATE/feature.yml` | `.github/ISSUE_TEMPLATE/feature.yml` | Feature request form |
| `ISSUE_TEMPLATE/config.yml` | `.github/ISSUE_TEMPLATE/config.yml` | Links to docs/quickstart.md, disables blank issues |
| `CONTRIBUTING.md` | `.github/CONTRIBUTING.md` | PR workflow expectations (fork → ingest → lint → PR) |
| `SECURITY.md` | `.github/SECURITY.md` | Responsible disclosure — minimal since local-first |
| `.gitignore` | repo root | Exclude `.brownfield/`, `.obsidian/workspace*.json`, local-only paths |
| `.gitattributes` | repo root | Mark `*.md` as `text eol=lf` for cross-platform PR diffs |

**Integration:** No integration with existing CLI helpers required. These are GitHub-plane config files consumed by GitHub UI/API, not by bash scripts.

**Install footprint:** 0 bytes runtime. Static files in repo.

**What NOT to add:** cookiecutter, copier, yeoman, plop, any repo-template-generator CLI.

**Confidence:** HIGH (GitHub template-repo feature + CODEOWNERS + PR templates documented in current GitHub Docs; all features stable and broadly used).

---

### CI (PR Lint Gate) — GitHub Actions, `ubuntu-latest`, pinned v6 actions

**Recommendation:** One workflow file: `.github/workflows/lint.yml`. Runs `bin/lint.sh` on every PR and on pushes to `main`. Single job, single step beyond setup.

**Why:**
- The project already has `bin/lint.sh`. CI = "run that script in a clean environment on PR." That is a five-line job.
- GitHub Actions is the free, zero-config CI that ships with every GitHub repo. Using anything else (CircleCI, Travis, self-hosted) is a friction tax that contradicts the template-repo value prop.
- `ubuntu-latest` (Ubuntu 24.04 LTS since late 2025 migration, fully rolled out by Oct 30 2025) ships with bash 5.x, python3 (3.12), and PyYAML is `pip install`-able in one line. No Docker, no matrix, no caching complexity needed at v1.1 scale.

**Action versions (verified current as of 2026-04):**

| Action | Version | Purpose |
|--------|---------|---------|
| `actions/checkout` | `v6` | Check out the PR branch |
| `actions/setup-python` | `v6` | Install Python 3.12 (pyyaml target) |

Pin to `@v6` (major tag) — GitHub recommends this for actions owned by `actions/*` org. Pinning to SHA is overkill for a docs/starter project; pinning to `@v6.0.0` risks rot.

**Minimal workflow:**

```yaml
# .github/workflows/lint.yml
name: Lint
on:
  pull_request:
    branches: [main]
  push:
    branches: [main]
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: actions/setup-python@v6
        with:
          python-version: '3.12'
      - run: pip install pyyaml
      - run: bash bin/lint.sh
```

**Integration:** Invokes `bin/lint.sh` unchanged. No code change required in existing helpers. The script's exit code is the gate — matches shell convention already in use locally.

**Install footprint:** 0 bytes for the repo; CI runs on GitHub's infra. Workflow file is ~20 lines YAML.

**What NOT to add:** matrix builds across OS (lint is OS-agnostic), Docker images (setup-python is faster), caching via `actions/cache` (pip install pyyaml is ~2 seconds — premature optimization), pre-commit action (wiki repos get edited in Obsidian; forcing pre-commit hooks on non-developer contributors breaks the guided-setup track).

**Confidence:** HIGH (actions/checkout and actions/setup-python v6 verified via GitHub repo/marketplace pages 2026; Ubuntu 24.04 rollout verified via Ubuntu Discourse PSA).

---

### Brownfield Scan Reporting — Plain markdown, `.brownfield/REPORT.md`, NO new dep

**Recommendation:** `bin/brownfield.sh scan` writes a plain markdown report to `.brownfield/REPORT.md` (gitignored by default). Staged migration scripts written to `.brownfield/migrations/NNN-description.sh`. No new tooling.

**Why:**
- Comparable tools confirm the pattern:
  - `notion2obsidian` (bitbonsai) — `--dry-run` flag, emits preview output.
  - `obsidian-vault-manager` (mpfilbin) — `--dry-run` on mutating commands, plain CLI output.
  - `obsidian-export` (zoni) — respects `.export-ignore` (gitignore-style patterns); no separate report format.
  - Dotfile bootstrappers (chezmoi, yadm, dotbot) — emit plain-text diff summaries, not structured JSON reports.
- None of these tools use a dedicated reporting framework. The idiom is: "dry-run writes a human-readable markdown/text report; a separate `apply`/`bootstrap` command actually mutates." That matches the four-subcommand design (scan/bootstrap/suggest/verify) already specified.
- Markdown report is viewable **inside Obsidian** if the user drops it in the vault — zero friction for the target audience. A JSON report would require a viewer; an HTML report would require a browser.

**Report format conventions (opinionated):**
- `.brownfield/REPORT.md` — scan findings grouped by severity (critical/moderate/cosmetic), each finding has: path, what-is, what-should-be, proposed-migration-script-link.
- `.brownfield/migrations/NNN-<slug>.sh` — one script per transformation class (e.g. `001-add-sentinel-frontmatter.sh`, `002-normalize-yaml.sh`). Each is idempotent (safe to re-run), prints what it changed, exits 0 on no-op.
- `.brownfield/` in root-level `.gitignore` — avoid polluting the vault history with scan artifacts.

**Integration:** `bin/brownfield.sh` is a new bash script. It calls the same inline python3+pyyaml pattern for YAML parsing that `bin/ingest.sh` and `bin/lint.sh` already use. `verify` subcommand shells out to `bin/lint.sh`. No new dep.

**Install footprint:** 0 bytes. New script, existing toolchain.

**What NOT to add:** jq (bash+python handles JSON fine if ever needed), yq (pyyaml covers it), Python reporting libs (rich, tabulate), any templating engine (markdown is the template).

**Confidence:** MEDIUM (pattern confirmed across 3+ comparable tools; specific file layout is our judgment call, not copied from a canonical source).

---

### Documentation Format — Plain markdown in `/docs/`, NO static-site generator

**Recommendation:** Plain markdown in `/docs/` with four subdirectories (`quickstart/`, `guided-setup/`, `manual-setup/`, `reference/`). Do **not** pre-wire MkDocs, Docusaurus, or any other SSG even though v1.2 may host the site.

**Why:**
- The v1.1 milestone *explicitly* defers hosted docs to backlog. Pre-wiring an SSG config optimizes for a feature that has not been scoped, prioritized, or committed.
- GitHub renders markdown natively in both the repo file browser and on the template-landing page. Contributors and users reading docs on github.com get the full experience today, zero build step.
- **Critical finding:** MkDocs Material entered **maintenance mode in November 2025**. The Insiders repo was deleted May 1, 2026. Pre-wiring MkDocs Material now bets the docs toolchain on an unmaintained project. Poor trade.
- Docusaurus (Meta, React-based) is heavier: Node.js toolchain, build step, version-specific React dependencies. A v1.2 hosted-docs decision might choose something else entirely (Astro Starlight, VitePress, Zola, or just deploy markdown straight to GitHub Pages with Jekyll's default theme) — pre-wiring Docusaurus creates sunk-cost pressure.
- "v1.2 hosted-site is a config flip" is a false economy: whichever SSG v1.2 chooses, adapting plain markdown takes hours, not days. The *actual* v1.2 work is deciding what to host, not plumbing config.
- Plain markdown is also what Obsidian reads. Docs-in-vault becomes a nice side effect: users can browse `/docs/` *inside Obsidian* after cloning. An SSG-specific syntax (Docusaurus MDX components, MkDocs admonitions) would break that.

**Integration:** None. `/docs/*.md` are read by humans via GitHub UI or Obsidian. No script touches them.

**Install footprint:** 0 bytes.

**Conventions to follow** so a future SSG can ingest cleanly:
- Use standard CommonMark + GFM tables only. No Docusaurus-MDX, no MkDocs-specific admonition syntax.
- Relative links between docs files (`[quickstart](../quickstart/index.md)`) — works in GitHub, Obsidian, and every SSG.
- Front matter limited to `title:` and `summary:` (both ignored by GitHub, usable by any SSG).
- Images in `/docs/assets/` with relative paths.

**What NOT to add:** MkDocs, MkDocs-Material, Docusaurus, VitePress, Astro Starlight, Zola, Hugo, Jekyll, Gatsby, any Node- or Python-level docs toolchain. Reopen this decision as a scoped v1.2 task.

**Confidence:** HIGH (MkDocs Material maintenance-mode announcement verified via squidfunk/mkdocs-material alternatives page and comparison posts 2026; Docusaurus active but heavyweight; deferral reasoning follows from milestone's explicit backlog).

---

## Summary of New Dependencies

**Zero new runtime dependencies.** The v1.1 milestone adds only:

| Addition | Type | Runtime dep? |
|----------|------|--------------|
| `bin/setup.sh` | New bash script | No |
| `bin/brownfield.sh` | New bash script | No |
| `.github/workflows/lint.yml` | GitHub Actions YAML (CI-side) | No |
| `.github/CODEOWNERS`, PR/issue templates | GitHub config | No |
| `/docs/**/*.md` | Plain markdown | No |
| `schema/templates/AGENTS.template.md` | Template file for wizard | No |

Every v1.1 deliverable runs on the **existing** bash + python3 + pyyaml + git baseline.

---

## Alternatives Considered and Rejected

| Category | Recommended | Rejected | Why Rejected |
|----------|-------------|----------|--------------|
| Wizard TUI | bash `read` | gum v0.14+ | Requires user pre-install; violates clone-and-go |
| Wizard TUI | bash `read` | whiptail | Non-universal (no macOS default) |
| Wizard TUI | bash `read` | python click+rich | Adds second install path beyond pyyaml baseline |
| Repo templating | GitHub template toggle | cookiecutter/copier | Adds Python pre-install step |
| CI | GitHub Actions | CircleCI/Travis | Friction tax vs native GitHub |
| CI actions | `@v6` major tag pin | SHA pin | Overkill for docs repo |
| CI runner | ubuntu-latest | Matrix (mac/win) | Lint is OS-agnostic; doubles CI time |
| Brownfield report | Plain markdown | JSON + viewer | Obsidian reads markdown natively |
| Docs format | Plain markdown | MkDocs Material | Maintenance mode Nov 2025; Insiders deleted May 2026 |
| Docs format | Plain markdown | Docusaurus | Node toolchain; heavy; v1.2 decision not made |
| Docs format | Plain markdown | VitePress/Astro Starlight | Same reasoning — premature commitment |

---

## Constraint Conformance Check

| Constraint | Conformance |
|------------|-------------|
| Local-first, file-based, no servers | PASS — no additions require a server |
| Zero/minimal new runtime deps | PASS — zero new runtime deps |
| Agent-agnostic (no Claude-Code-specific integrations) | PASS — wizard writes `AGENTS.md` generically; CI runs `bin/lint.sh`; templates are agent-neutral |
| Must work offline for wiki operations | PASS — all additions except CI are local-only; CI is optional (not required for local operation) |

No addition breaks any constraint. GitHub Actions runs in the cloud, but it is strictly optional (opt-in via pushing to a GitHub remote) — the local workflow continues to run unchanged without it.

---

## Downstream Guidance for gsd-roadmapper

Suggested phase breakdown implications:

1. **Repo scaffolding phase** can be a single integrated unit: GitHub template config + CI workflow + `/docs/` skeleton. All are static files. Low risk, no new tooling.
2. **Wizard phase** is a bash-only deliverable with an `AGENTS.template.md` authoring sub-task. Risk concentrated in template design, not in tooling. No dependency on CI phase.
3. **Brownfield phase** is the largest net-new code (`bin/brownfield.sh` with 4 subcommands). Consider splitting: (a) `scan` + report format, (b) `bootstrap` mechanical ops, (c) `suggest` staged scripts, (d) `verify` + integration.
4. **Docs-writing phase** depends on all of the above being stable so docs can reference real commands. Sequence it last within v1.1.
5. **No phase should introduce a new runtime dependency.** If a phase proposes one, flag it back to research.

---

## Sources

- [charmbracelet/gum — GitHub](https://github.com/charmbracelet/gum)
- [Whiptail vs Dialog comparison — Aprende IT](https://aprendeit.com/en/creating-interactive-scripts-in-linux-using-dialog-or-whiptail/)
- [Creating a pull request template — GitHub Docs](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/creating-a-pull-request-template-for-your-repository)
- [github/form-templates CODEOWNERS example](https://github.com/github/form-templates/blob/main/CODEOWNERS)
- [actions/setup-python — GitHub](https://github.com/actions/setup-python)
- [actions/checkout — GitHub Marketplace](https://github.com/marketplace/actions/setup-python)
- [Ubuntu 24.04 rollout PSA — Ubuntu Discourse](https://discourse.ubuntu.com/t/psa-for-folks-using-python-in-github-action-runners-and-ubuntu-latest-label/48654)
- [Material for MkDocs — Alternatives / Maintenance-mode context](https://squidfunk.github.io/mkdocs-material/alternatives/)
- [MkDocs vs Docusaurus 2026 — Damavis Blog](https://blog.damavis.com/en/mkdocs-vs-docusaurus-for-technical-documentation/)
- [notion2obsidian — dry-run pattern](https://github.com/bitbonsai/notion2obsidian)
- [obsidian-vault-manager — dry-run pattern](https://github.com/mpfilbin/obsidian-vault-manager)
- [obsidian-export — gitignore exclude pattern](https://github.com/zoni/obsidian-export)
