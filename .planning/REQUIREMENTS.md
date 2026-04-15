# Requirements: LLM Wiki Compiler — v1.1 Shareability

**Defined:** 2026-04-15
**Core Value:** The wiki is a persistent, compounding artifact — cross-references are already there, contradictions already flagged, synthesis already reflects everything ingested.
**Milestone Focus:** Make the v1.0 starter kit usable by technically comfortable early adopters — template-based starter repo, two-track setup, git-based collaborative curation, safe brownfield onboarding.

Numbering continues from v1.0. New REQ-ID prefixes: `TMPL`, `NEUT`, `WZRD`, `MANUAL`, `COLAB`, `CI`, `BRWN`, `DEBT`.

---

## v1.1 Requirements

### Template Repo Structure (TMPL)

- [ ] **TMPL-01**: Repository is configured as a GitHub Template (green "Use this template" button)
- [ ] **TMPL-02**: Repo ships with top-level `README.md` containing a ≤60-second pitch + link to `docs/quickstart.md`
- [ ] **TMPL-03**: Repo ships with `LICENSE` file (MIT or Apache-2.0)
- [ ] **TMPL-04**: `.gitignore` pre-configured for Obsidian (`.obsidian/workspace*.json`, `.obsidian/cache`, `.trash/`) and `.brownfield/`
- [ ] **TMPL-05**: Starter `wiki/` ships with `index.md` and `log.md` skeletons only (no content)
- [ ] **TMPL-06**: `/docs/` exists with four top-level tracks: `quickstart.md`, `guided-setup.md`, `manual-setup.md`, `reference/index.md`
- [ ] **TMPL-07**: `/docs/README.md` names the Diátaxis mapping explicitly (quickstart=tutorial, guided/manual=how-to, reference=reference+explanation)
- [ ] **TMPL-08**: `/docs/reference/` contains `schema-tour.md`, `brownfield.md`, `privacy-model.md`, `ci.md`, `examples.md`
- [ ] **TMPL-09**: Top-level `PRIVACY.md` page surfacing the local_only / cloud_safe convention
- [ ] **TMPL-10**: `CLAUDE.md` exists at repo root alongside `AGENTS.md` (symlink or identical content — agent-agnostic from filename up)
- [ ] **TMPL-11**: Release process uses orphan-branch publish so v1.0 personal git history does not ship (pitfall C-1 mitigation)

### Neutralization & Examples (NEUT)

- [ ] **NEUT-01**: Kahneman cluster (all 7 pages + sources) moved from `wiki/` to `examples/kahneman/`, internal wikilinks preserved
- [ ] **NEUT-02**: `AGENTS.md` illustrative content rewritten with generic placeholders (no Kahneman, prospect-theory, loss-aversion strings)
- [ ] **NEUT-03**: `AGENTS.md` sections that need examples add `See: examples/kahneman/...` pointers instead of inlining
- [ ] **NEUT-04**: New optional frontmatter field `example: true` documented in `AGENTS.md §5`; `bin/lint.sh EXCLUDE_DIRS` honors `examples/` and/or `example: true`
- [ ] **NEUT-05**: `examples/kahneman/README.md` explains why the cluster is preserved and how to use it as a reference
- [ ] **NEUT-06**: CI neutrality gate: grep-based check that `AGENTS.md` contains zero Kahneman-specific strings (runs on every PR) (pitfall C-1)
- [ ] **NEUT-07**: Decision record `dr-YYYY-MM-DD-kahneman-to-examples.md` committed (SUPERSEDE-class structural reorg per §11.4)
- [ ] **NEUT-08**: CI personal-content denylist check covering domain terms from the creator's private vault, runs on PR diff (pitfall C-1 mitigation)

### Guided Setup Wizard (WZRD)

- [ ] **WZRD-01**: `bin/init-wizard.sh` exists, bash-only, no new runtime dependencies
- [ ] **WZRD-02**: Wizard prompts are semantically grouped: Domain → LLM agent → Privacy defaults → Obsidian conventions, each group prints a one-sentence explainer before its questions
- [ ] **WZRD-03**: Wizard supports non-interactive mode via `--answers-file <path>` for CI and replay
- [ ] **WZRD-04**: Wizard validates input: domain matches `^[a-z0-9-]+$`, agent is in allowed set, privacy tier is one of three named values
- [ ] **WZRD-05**: Wizard is idempotent — re-running on an already-initialized repo either no-ops or refuses with a clear message
- [ ] **WZRD-06**: Wizard writes `.wizard-answers.yaml` recording the inputs that produced the rendered AGENTS.md (powers v1.2 upgrades)
- [ ] **WZRD-07**: Wizard renders from `schema/AGENTS.template.md` using named placeholders (≤6 placeholders: `{{PRIMARY_DOMAIN}}`, `{{DEFAULT_PRIVACY}}`, `{{AGENT_FILENAME}}`, `{{DECAY_PROFILE}}`, `{{EXAMPLE_CLUSTER_REF}}`, `{{USER_NAME}}`)
- [ ] **WZRD-08**: Wizard prints the file list it wrote with a summary diff on completion
- [ ] **WZRD-09**: Wizard pre-flight check: confirms `git`, `bash >= 4`, prints actionable message if missing
- [ ] **WZRD-10**: Wizard writes an initial decision record per DCSN-01 capturing the setup choices (self-referential first reflect artifact)
- [ ] **WZRD-11**: `bin/init-wizard.sh --dry-run` prints the rendered diff without applying it (bridges manual track)

### Manual Setup Track (MANUAL)

- [ ] **MANUAL-01**: `/docs/manual-setup.md` walks section-by-section through `AGENTS.md` explaining what each section expects
- [ ] **MANUAL-02**: `/docs/manual-setup.md` contains a concrete minimal-diff example from neutral starter → working personal-knowledge setup
- [ ] **MANUAL-03**: `/docs/manual-setup.md` ends with a checklist that maps one-to-one to wizard prompts (wizard-manual isomorphism)
- [ ] **MANUAL-04**: `/docs/manual-setup.md` includes explicit equivalence statement — wizard and manual produce the same end state
- [ ] **MANUAL-05**: `/docs/manual-setup.md` lists every file the wizard touches and what it writes
- [ ] **MANUAL-06**: Byte-equality test: wizard output with canonical answers matches manual track's stated end state (pitfall M-1/M-3 mitigation)

### Collaborative PR Workflow (COLAB)

- [ ] **COLAB-01**: Top-level `CONTRIBUTING.md` describing branch-per-ingest convention, PR workflow, attribution rules
- [ ] **COLAB-02**: `.github/pull_request_template.md` prompts for source attribution, ingest type, privacy review confirmation, lint output
- [ ] **COLAB-03**: `log.md` entry schema amended (AGENTS.md §12) with optional `contributor:: <handle>` Dataview inline field
- [ ] **COLAB-04**: `bin/ingest.sh --contributor <handle>` flag; auto-detects from `git config user.email` if omitted; omits field entirely on single-author repos
- [ ] **COLAB-05**: Git commit authorship is the attribution source of truth; documented as such in `CONTRIBUTING.md`
- [ ] **COLAB-06**: `CONTRIBUTING.md` includes merge-conflict recipes for `index.md` and `log.md` (the write-heavy hotspots)
- [ ] **COLAB-07**: `bin/search.sh --contributor <handle>` filter (parses `log.md` contributor field)
- [ ] **COLAB-08**: `bin/lint.sh` optional check: `contributor::` handles appear as git commit authors (low-severity warning)

### CI Lint Gate (CI)

- [ ] **CI-01**: `.github/workflows/lint.yml` runs on every PR using `actions/checkout@v6` + `actions/setup-python@v6` on `ubuntu-latest`
- [ ] **CI-02**: `bin/lint.sh --format json` mode emits structured findings `{severity, category, path, line?, message}`
- [ ] **CI-03**: `bin/lint.sh --ci` mode applies severity policy: `stale`, `gap`, and `contradiction` surface as warnings (not blockers — contradictions reflect source disagreement, not system failure, per Phase 5 decision); `yaml`, `orphan`, `crossref`, `provenance` remain blockers
- [ ] **CI-04**: `bin/lint.sh --skip-category drift-external` skips cross-tool drift checks in CI (DRFT-03 requires local Zotero/Obsidian state)
- [ ] **CI-05**: Annotation shim converts JSON findings to GitHub `::error file=...,line=...::` inline annotations
- [ ] **CI-06**: `bin/lint.sh --strict` mode: exits non-zero on any `[inferred]`/`[tentative]` claim added without a matching decision record, and on new pages lacking provenance (quality ratchet at merge time)
- [ ] **CI-07**: Privacy-leak guard: CI check fails a PR only when `privacy: local_only` (or any `local_only` frontmatter) appears under paths declared public (default: `examples/**`, `docs/**`, `AGENTS.md`, `CLAUDE.md`, `README.md`, `.github/**`). `local_only` is a valid tier in user content (`wiki/**`) — the guard prevents leakage into public/template material only. Public paths glob is configurable in `.github/workflows/lint.yml`.
- [ ] **CI-08**: `bin/lint.sh --version` supports version pinning so rule changes don't silently break existing PRs
- [ ] **CI-09**: `/docs/reference/ci.md` documents GitLab/Gitea/Codeberg equivalents of the GitHub workflow (JSON output is platform-neutral)

### Brownfield Onboarding (BRWN)

- [ ] **BRWN-01**: `bin/brownfield.sh scan` — dry-run; writes `.brownfield/REPORT.md` inventorying each page with **provisional type suggestions** (entity/concept/source-summary/comparison/overview/unknown) + confidence signal. Suggestions are non-authoritative — they inform the user; the authoritative typing decision happens in `suggest`'s `01-page-typing.sh` which the user reviews. `scan` touches no vault content.
- [ ] **BRWN-02**: `scan` report explicitly lists unclassifiable pages (`unknown`) with a one-line reason each, framed as open questions for the user to resolve
- [ ] **BRWN-03**: `bin/brownfield.sh bootstrap` is idempotent — running twice is a no-op
- [ ] **BRWN-04**: `bootstrap` touches only mechanical transforms: sentinel frontmatter (empty values + `bootstrap_stage: bootstrapped`), SHA hashing of source files, `index.md`/`log.md` skeletons if absent, YAML quoting/ordering normalization
- [ ] **BRWN-05**: `bootstrap` preserves user page bodies verbatim — only frontmatter and scaffolding files are touched (migration-tool rule #1)
- [ ] **BRWN-06**: `bootstrap` uses `ruamel.yaml` round-trip parsing to preserve comments and key order (pitfall C-2/M-10 mitigation)
- [ ] **BRWN-07**: New frontmatter field `bootstrap_stage` (enum `raw|bootstrapped|verified`) documented in `AGENTS.md §5`. Semantics carry beyond bootstrap completion — `verified` persists on imported pages permanently, serving as the page-level marker for "content predates the LLM ingest pipeline" (feeds search, audit, and any future provenance tooling that needs the imported-vs-LLM-generated distinction).
- [ ] **BRWN-08**: `bin/lint.sh` downgrades allowlist findings (unknown `type`, empty `knowledge_domain`, missing `sources`, `epistemic_status: tentative`) from `error` to `info` when `bootstrap_stage: bootstrapped`
- [ ] **BRWN-09**: `bin/lint.sh` new `brownfield` category reports counts of pages still in `bootstrapped` state; warns on pages `bootstrapped` older than 30 days
- [ ] **BRWN-10**: `bin/ingest.sh` strips `bootstrap_stage` if encountered on normal ingest (prevents pollution)
- [ ] **BRWN-11**: `bin/brownfield.sh suggest` writes `.brownfield/REPORT.md` + `.brownfield/migrations/*.sh`
- [ ] **BRWN-12**: Four staged migration script classes: `01-page-typing.sh`, `02-provenance-bootstrap.sh`, `03-cross-link-inference.sh`, `04-privacy-classification.sh`
- [ ] **BRWN-13**: Each migration script is **user-invoked manually** (`bash .brownfield/migrations/02-provenance-bootstrap.sh`); self-describing (prints what it will change); dry-run default; per-script `--apply` flag executes the change on that single class; idempotent when re-run. v1.1 does NOT ship a single-command chain-runner that auto-applies all classes — that is explicitly deferred to v1.2 (see BRWNAPPLY-01).
- [ ] **BRWN-14**: Each migration script header contains `# op_hash: <sha256>` derived from normalized operation descriptors (not the rendered shell); idempotency recorded in `.brownfield/applied.log`
- [ ] **BRWN-15**: `02-provenance-bootstrap.sh` tags pre-existing claims using the **existing epistemic vocabulary only** (`inferred` per EPST-01). **Zero claim-level schema expansion.** The imported-vs-LLM-generated distinction is captured at the page level via `bootstrap_stage` (BRWN-07) — no magic-string provenance values, no new epistemic sub-markers. AGENTS.md §5 documents `bootstrap_stage` as the canonical provenance-lineage field for imported pages.
- [ ] **BRWN-16**: Classification heuristics in `scan` are rule-based (frontmatter fields, filename conventions, link density) — no LLM calls inside `brownfield.sh`
- [ ] **BRWN-17**: `bin/brownfield.sh verify` is a thin wrapper over `bin/lint.sh` with brownfield-appropriate severity thresholds
- [ ] **BRWN-18**: `docs/reference/brownfield.md` explains the mechanical-vs-judgment boundary explicitly ("this is why `bootstrap` won't ever do X; use `suggest`")
- [ ] **BRWN-19**: `docs/reference/brownfield.md` documents `git reset` recipe as the canonical undo path
- [ ] **BRWN-20**: New `AGENTS.md §11.5 Brownfield Workflow` documents scan/bootstrap/suggest/verify, idempotency contract, mechanical/judgment boundary
- [ ] **BRWN-21**: Byte-exact fixture tests: bootstrap produces identical output on sample vaults across runs (pitfall M-11 mitigation)

### v1.0 Debt Closure (DEBT)

- [ ] **DEBT-01**: Obsidian render verification — open generated wiki in Obsidian, confirm wikilinks resolve and Dataview queries render correctly (deferred from v1.0 Phase 4)
- [ ] **DEBT-02**: Codex (or other non-Claude) agent-parity: run v1.0 ingest workflow end-to-end against Kahneman example cluster using a second agent; document diffs; set agent-parity tolerance
- [ ] **DEBT-03**: `bin/requirements-sync.sh` mechanical check: compares `VERIFICATION.md` truths against `REQUIREMENTS.md` status checkboxes; flags drift (retrospective lesson)
- [ ] **DEBT-04**: Genuine write-back query scenario executed end-to-end (Phase 4 validation scenario that produced NO-WRITE-BACK in v1.0 re-run)

## v2 Requirements

Deferred to future milestones.

### Obsidian Plugin Distribution (PLUGIN)

- **PLUGIN-01**: Obsidian community plugin that wraps `bin/brownfield.sh scan` for in-app dry-run
- **PLUGIN-02**: Plugin-based wizard alternative for users without terminal comfort
- **PLUGIN-03**: Published to Obsidian's community plugin registry

### One-Command Installer (INSTALL)

- **INSTALL-01**: `curl | bash` script that clones template + runs wizard in chosen directory
- **INSTALL-02**: Homebrew/Scoop tap for named-package install

### Hosted Docs Site (DOCSSITE)

- **DOCSSITE-01**: Static site (MkDocs or Docusaurus) published to GitHub Pages / Cloudflare Pages
- **DOCSSITE-02**: Versioned docs tracking schema_version

### Brownfield --apply Mode (BRWNAPPLY)

- **BRWNAPPLY-01**: `bin/brownfield.sh apply` single-command chain-runner that executes all four generated migration scripts in order without per-script user intervention (v1.1 requires manual per-script invocation; v1.2 adds auto-apply after dry-run path battle-tested)
- **BRWNAPPLY-02**: Interactive review UI for per-migration approval before apply

## Out of Scope

Explicitly excluded from v1.1. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Real-time / concurrent multi-user editing | Collaboration in v1.1 is asynchronous git PR only; shared-vault coordination is a different product |
| Hosted multi-tenant service | Local + git-hosted only; no servers |
| GUI / Electron wizard | CLI is sufficient for the target audience; future Obsidian plugin is the GUI vector |
| API key input during setup | Privacy risk; agent configs live outside this repo |
| LLM calls inside `bin/brownfield.sh` | Non-deterministic, network-dependent; violates mechanical-tool thesis |
| Auto-merge on lint pass | Wiki curation is judgment work; human review required |
| CLA bot | Scope creep; license covers it |
| Custom Obsidian theme/CSS | Unrelated to compiler thesis |
| Multi-language `/docs/` scaffolding | Zero validated non-English demand |
| Pre-installed Obsidian plugins as committed blobs | License pollution, plugin drift, user-trust violation |
| Domain presets (personal/research/engineering variants) | Multiplies maintenance; wizard-injected domain is better |
| Custom merge drivers for index.md/log.md | Requires local install; documented manual-merge recipe is sufficient |

## Traceability

Filled by roadmapper during phase creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| (pending roadmap) | — | — |

**Coverage:**
- v1.1 requirements: 78 total (TMPL: 11, NEUT: 8, WZRD: 11, MANUAL: 6, COLAB: 8, CI: 9, BRWN: 21, DEBT: 4)
- Mapped to phases: 0 (pending roadmap)
- Unmapped: 78

---
*Requirements defined: 2026-04-15 — v1.1 Shareability milestone*
