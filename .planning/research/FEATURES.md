# Feature Landscape

**Domain:** LLM-maintained Obsidian-wiki compiler — v1.1 Shareability (template repo, two-track setup, git PR workflow, brownfield onboarding)
**Researched:** 2026-04-15
**Scope:** Six v1.1 feature buckets only. v1.0 primitives (AGENTS.md, bin/ingest.sh, bin/search.sh, bin/validate-op.sh, bin/lint.sh, five page-type templates, claim provenance, structured ops, epistemic markers, Kahneman cluster) are treated as fixed inputs, not re-researched.

---

## Feature Bucket 1 — Template-Based GitHub Starter Repo

Cloneable structure via GitHub "Use this template". Kahneman cluster relocated to `examples/`. Empty `wiki/` by default. `/docs/` organized into four tracks. `AGENTS.md` / `CLAUDE.md` as top-level schema entry point.

### Table Stakes

| Feature | Why Expected | Complexity | Prior Art |
|---------|--------------|------------|-----------|
| Repo is a GitHub "template repository" (green "Use this template" button) | Every modern scaffold repo uses this; users expect one-click clone without fork baggage | Low | kepano/kepano-obsidian, andrewmcodes/obsidian-beginner-vault-template, SoRobby/ObsidianStarterVault |
| `README.md` with 60-second "what is this / clone it / open in Obsidian / ingest your first source" path | First-impression test; Obsidian starter vaults that lack this get abandoned | Low | voidashi/obsidian-vault-template, kepano/kepano-obsidian |
| `.gitignore` pre-configured for Obsidian (`.obsidian/workspace*.json`, `.obsidian/cache`, `.trash/`) | Noise in commits; universal convention in Obsidian starters | Low | Every Obsidian starter vault on GitHub |
| Empty `wiki/` with `index.md` + `log.md` skeletons committed | Users expect the structure to exist, not to be told to `mkdir` | Low | cookiecutter/copier emit full tree, not partial |
| `LICENSE` file (MIT or Apache-2.0) | Template repos without a license can't legally be reused; GitHub surfaces this prominently | Low | Canonical OSS expectation |
| `examples/kahneman/` preserves the v1.0 validated cluster intact (entity, concept, comparison, source-summary, overview pages + the two ingest log entries) as a canonical worked example | Users learn the conventions by reading real pages; removing examples = raising onboarding cost | Low | Every working Obsidian starter includes sample notes; cookiecutter ships a `hello_world.py` |
| `/docs/README.md` that routes to the four tracks based on user profile | Diátaxis research shows users look for "which door do I walk through first" | Low | Diátaxis framework, mkdocs-material, Canonical/Ubuntu docs |

### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Four-track `/docs/` directly mapped to Diátaxis (quickstart = tutorial, guided setup = how-to, manual setup = how-to, reference = reference + explanation) with an explicit table in `/docs/README.md` naming the mapping | Signals epistemic seriousness to the target audience (Obsidian power users, developer-adjacent); differentiates from "dump a README" starter vaults | Low | Diátaxis: diataxis.fr — adopted by Canonical, Cloudflare, Gatsby, Sequin. |
| `AGENTS.md` + `CLAUDE.md` at repo root as symlink or identical file, making the template agent-agnostic from the filename up | The project's core thesis is agent-agnosticism; the repo layout should embody it on line 1 | Low | No known Obsidian starter does this; differentiator vs. CLAUDE.md-only repos |
| Top-level `PRIVACY.md` page calling out the local_only / cloud_safe frontmatter convention before the user has to read section 11 of AGENTS.md | Obsidian users are privacy-sensitive; surfacing this up front matters | Low | No prior art found in Obsidian starters — differentiator |
| `examples/` README explains WHY Kahneman: "this cluster was used end-to-end in v1.0 validation; every convention in AGENTS.md has at least one instance here; use it as a search target when you need to see how a rule looks in practice" | Turns examples from decoration into a referenceable artifact | Low | Reinforces existing v1.0 EXMP-01..05 work |

### Anti-Features

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|--------------------|
| Ship multiple domain presets (personal, research, engineering, legal) in the starter | Each preset doubles the maintenance surface; they drift from AGENTS.md; they pre-commit the user to a style before they understand the system. Prior art: cookiecutter-data-science stayed with one opinionated tree and is healthier for it. | Single neutral starter + `examples/` with Kahneman; let the guided wizard inject domain terminology into AGENTS.md instead |
| Pre-install Obsidian community plugins (Dataview, Templater, Frontmatter Generator) via `.obsidian/plugins/` committed blobs | (a) license pollution, (b) users trust plugin installs they did themselves, (c) plugin versions drift in weeks. Prior art: every well-maintained Obsidian starter documents plugins in README and does not vendor them. | `docs/reference/recommended-plugins.md` with install instructions + rationale |
| A custom Obsidian theme or CSS snippet bundled | Aesthetic; unrelated to the compiler thesis; creates support load ("my graph view colors broke") | Omit |
| Multi-language `/docs/` (i18n scaffolding) | Pure scope bloat for v1.1; zero validated non-English demand | English only, leave room structurally (no `/docs/en/` prefix required) |
| GitHub Actions CI pre-wired to run `bin/lint.sh` on push in the template itself | Good for the project repo, but every user who clones inherits a workflow they may not want running against their private vault; also breaks on forks-with-secrets | Document as an optional recipe in `docs/reference/ci-recipes.md` |

**Complexity:** ~1 plan (mechanical file moves + README authoring + Diátaxis mapping doc). **Dependencies:** none upstream; every other v1.1 bucket lives inside this repo, so this is the substrate.

**Integration with v1.0 primitives:**
- Moves `wiki/kahneman*.md`, `wiki/cognitive-biases.md`, `wiki/sources/kahneman-*.md`, etc. → `examples/kahneman/wiki/` preserving relative wikilinks (verify in lint pass)
- AGENTS.md section 3 (directory structure) needs a line acknowledging `examples/` as a non-active tree
- `bin/lint.sh` needs an exclude rule or scoped root flag so it doesn't treat `examples/` as the live vault

---

## Feature Bucket 2 — Guided Setup Wizard

Interactive prompt flow (likely `bash` with `read` + fallback to a minimal node/python if JSON templating gets heavy) that asks ~4–6 questions and writes a personalized `AGENTS.md` + initial directory scaffolding.

### Table Stakes

| Feature | Why Expected | Complexity | Prior Art |
|---------|--------------|------------|-----------|
| Interactive prompts with sensible defaults (user hits Enter to accept) | Every scaffolding tool since Yeoman (2012) does this; defaults reduce first-run friction dramatically | Low | cookiecutter, copier, cargo-generate, create-react-app, `npm init`, `gh repo create` |
| Non-interactive mode via flags or a config file (`bin/setup.sh --domain=personal --agent=claude --privacy=strict`) | Required for CI, dotfile replay, and users who want to re-run deterministically. Copier and cookiecutter both support `--replay` / answers file. | Low-Med | copier `answers.yml`, cookiecutter `replay/`, cargo-generate `--template-values-file` |
| Idempotent — running twice produces the same result; running against an already-initialized repo either no-ops or refuses with clear message | Users will run it twice. If it clobbers their edits they won't recover. | Med | copier update is the state of the art here |
| Input validation (domain slug matches `^[a-z0-9-]+$`, agent is in the allowed set, privacy tier is one of three named values) | Bad input → bad AGENTS.md → silent wiki corruption days later | Low | cookiecutter `pre_gen_project.py` hooks; copier `validator` in YAML |
| Clear "what this will do / did" output — prints the file list it wrote with a summary diff | User trust; scaffolders that just say "Done." get fork-and-inspect reactions | Low | `gh repo create` prints the URL; `npm create vite` prints the tree |
| Writes an `answers.yml` (or `.setup-answers.md`) into `.planning/` or `docs/` so re-runs and future upgrades know the original choices | Upgrade path depends on this; otherwise v1.2 migrations have to re-interview the user | Low | copier keeps `.copier-answers.yml`; this is the feature that made copier differentiating |

### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Prompts are semantically grouped: Domain (what are you tracking?) → LLM agent (Claude Code / Codex / other) → Privacy defaults (strict / mixed / open) → Obsidian conventions (wikilinks yes/no, Dataview yes/no) — each group prints a one-sentence explainer before its questions | Wizards that explain WHY they're asking get higher completion and better answers. Rare in dev-tooling scaffolders. | Low | `gh auth login` does this well; `create-next-app` does not |
| Wizard output is a *diff* against the starter AGENTS.md, not a rewrite — it edits named sections (1 Identity, 7 Privacy, 15 Agent-specific) and leaves the rest verbatim | Lets users re-run against a modified AGENTS.md without losing their edits; foundational for the v1.2 "update template" story | Med | copier's whole thesis. No Obsidian prior art. |
| Pre-flight check: confirms `git`, `bash >= 4`, and (if relevant) Obsidian is installed, prints an actionable message if not | Guided users are the ones who need this most; power users don't. | Low | `doctor` pattern from `brew doctor`, `rustup check` |
| Privacy default selector explicitly sets both the default_privacy_tier frontmatter default *and* the `.gitignore` entries for `local_only/` before the first commit | Privacy mistakes are irreversible once pushed; wizard is the natural enforcement point | Low | Integrates with BNDY-02 from v1.0 |
| Explicit "what agent are you using?" branch writes a single-line `CLAUDE.md` or `.codex/agent.md` pointer file alongside `AGENTS.md` — no duplication, just a symlink-or-include | Validates the v1.0 agent-agnostic design in the most visible place | Low | Reinforces v1.0 SCHM-01 |

### Anti-Features

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|--------------------|
| A GUI wizard (Electron app, web-based form) | 100x scope; the target audience uses a terminal; Obsidian users are already comfortable with markdown files | Stay CLI; a future Obsidian plugin (already deferred) is the right vector for a GUI |
| Asking the user to paste their OpenAI / Anthropic API key during setup | Privacy risk (key ends up in shell history / logs), scope creep (now we're a secret manager), and not needed — the system calls no APIs itself | Document in `docs/reference/agent-setup.md` how to configure the agent's own config |
| Auto-generating example pages specific to the user's domain ("you said 'cooking' so here are three recipe pages") | LLM-in-wizard is a huge complexity jump; hallucinated pages set bad examples; violates the "quiet and reliable" constraint from the project README | Tell the user to run their first ingest via `bin/ingest.sh`; that's the real workflow |
| A full Yeoman-style plugin/generator architecture | Over-engineered for ~5 questions and one template file; Yeoman is itself considered deprecated in 2026 vs. copier/cookiecutter | Flat bash script, optionally calling a small templating helper |
| "Dozens of knobs" — advanced questions about decay rates, lint thresholds, index split size, etc. | Every extra prompt drops completion; defaults are better than choices for users who don't know what good looks like | Ship sensible defaults; document how to tune post-hoc in reference docs |
| Pull-from-network behavior (fetch latest AGENTS.md from GitHub before prompting) | Breaks air-gapped use, adds a failure mode, and makes the wizard non-deterministic across time | Wizard only touches files already in the cloned template |

**Complexity:** ~2 plans (plan 1: prompt flow + answers.yml + domain/privacy/agent injection into AGENTS.md; plan 2: idempotency, validation, non-interactive mode, integration tests). **Dependencies:** needs Bucket 1 (template repo structure) as its substrate. Bucket 6 (domain-agnostic defaults) must land before or with this — wizard has nothing to personalize if AGENTS.md still has Kahneman baked in.

**Integration with v1.0 primitives:**
- Modifies AGENTS.md sections 1 (identity/domain), 7 (privacy tiers), 11 (workflows — agent-specific commands), 15 (agent-specific hooks)
- Creates/updates frontmatter defaults used by `bin/ingest.sh` for new pages
- Writes an initial decision record (per DCSN-01) capturing the setup choices — turns "setup" into the first reflect-workflow artifact, beautifully self-referential

---

## Feature Bucket 3 — Manual Setup Track

A `/docs/manual-setup.md` walkthrough that shows a power user how to produce the same end state as the wizard by hand-editing files. No new code; it is a documentation track plus an explicit contract that AGENTS.md remains hand-editable after wizard-generation.

### Table Stakes

| Feature | Why Expected | Complexity | Prior Art |
|---------|--------------|------------|-----------|
| Section-by-section walk of AGENTS.md explaining what each section expects | Power users want the map, not the turn-by-turn | Low | Diátaxis "how-to" pattern; rails.initializers docs |
| Concrete "here is a minimal diff from the neutral starter to a working personal-knowledge setup" example | Power users learn from diffs, not prose | Low | Common in dotfile repos, `.config` examples |
| Explicit equivalence statement — "the wizard produces exactly what these steps produce; they are interchangeable" | Power users distrust wizards; removing the suspicion that the wizard does magic is load-bearing | Low | `rustup` docs do this with toolchain setup |
| List of every file the wizard touches and what it writes to each | Power users want to audit | Low | cookiecutter `--list-installed-templates` |

### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| A `bin/setup.sh --dry-run --answers=my-answers.yml` flag that prints the diff without applying it — serves both tracks as a debugging aid | Bridges manual and guided; power users can use the wizard as a generator, inspect, then hand-apply | Low | Like `terraform plan` |
| `/docs/manual-setup.md` ends with a checklist that maps one-to-one to wizard prompts, so users can use it as a pre-flight if they ever want to re-enter the wizard track | Keeps the two tracks isomorphic — a maintainability win | Low | Novel as far as I found |

### Anti-Features

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|--------------------|
| Duplicate content between manual and guided docs | Drift; when AGENTS.md changes, only one gets updated | Manual-setup doc should reference the reference track for section semantics; it's the operator's guide, not the spec |
| "Advanced" manual-only features the wizard can't do | Creates a two-tier user class and ongoing friction to keep parity | Everything the manual track can do, the wizard can emit (or explicitly defer to post-wizard edits) |
| Long prose narrative | Power users skim | Terse, code-block-heavy, checklist-format |

**Complexity:** ~0.5 plan (a single documentation deliverable; co-ship with Bucket 2). **Dependencies:** Bucket 2 must be designed in parallel — they share the answers-schema.

**Integration with v1.0 primitives:** Documentation-only; points at AGENTS.md sections and existing frontmatter conventions. No new code.

---

## Feature Bucket 4 — Git-Based PR Workflow for Collaborative Curation

Documentation + one GitHub Actions workflow + an `log.md` schema amendment. Contributors fork, create a branch, run `bin/ingest.sh`, commit the resulting wiki diffs, open a PR; a CI lint gate runs `bin/lint.sh --strict`; maintainer merges. Attribution = git authorship (source of truth); `log.md` gets a per-entry `contributor:` field as a convenience index that `bin/search.sh` can filter on.

### Table Stakes

| Feature | Why Expected | Complexity | Prior Art |
|---------|--------------|------------|-----------|
| CI check running `bin/lint.sh` on every PR, blocking merge on failure | Every docs-as-code project (mkdocs-material, Diátaxis implementers, Astro Starlight sites) gates on lint/build | Low | mkdocs-material CI, Vale prose-lint CI, markdownlint-cli |
| `CONTRIBUTING.md` at repo root describing the branch-per-ingest convention | GitHub surfaces CONTRIBUTING.md prominently in the PR UI; absence is a red flag for new contributors | Low | Universal OSS expectation |
| PR template (`.github/pull_request_template.md`) prompting for: source attribution, ingest type, privacy review confirmation, lint output | Templates measurably improve PR quality; zero-cost | Low | `kubernetes/kubernetes`, `rust-lang/rust` |
| Contributor guidance on how to resolve merge conflicts in `index.md` and `log.md` (the two hotspot files under concurrent ingests) | These two files are write-heavy; without explicit guidance you get mangled merges | Low | GitHub wiki has a "conflict in Home.md" FAQ; DocuBook / mkdocs docs folders see this |
| Git authorship preserved end-to-end — `bin/ingest.sh` should never rewrite author metadata | Without this, attribution is a lie | Low | Trivial, but worth asserting in tests |

### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| `bin/lint.sh --strict` mode that exits non-zero on any `[inferred]` or `[tentative]` claim added without a matching decision record, and on any new page lacking provenance | Turns the lint gate into an actual quality ratchet rather than a syntactic check. The project's edge is claim-level provenance — this enforces it at merge time. | Med | No prior art in docs-as-code projects because none have claim-level provenance; novel |
| Per-`log.md` entry `contributor:` convenience field + a `bin/search.sh --contributor=<handle>` filter | Lets a maintainer audit one contributor's ingests fast; keeps git authorship authoritative while making queries ergonomic | Low | `git log --author` exists; layering it into the wiki-native search is the differentiator |
| CI posts the lint report as a PR comment (not just pass/fail) with clickable links to the offending claims | Reviewers see *what* failed without clicking into Actions logs | Med | Danger JS, reviewdog pattern |
| PR template includes a "Privacy review" checkbox — contributor attests they classified `local_only` vs `cloud_safe` frontmatter correctly | Privacy drift is the single highest-consequence collaboration risk | Low | Novel; extends v1.0 BNDY-02 |
| Explicit "local_only pages must never appear in a PR" rule, enforced by a CI check that greps for `privacy: local_only` in the diff | Mechanical guarantee against the worst privacy mistake; no ambiguity | Low | Enforces BNDY-02 at the merge boundary |

### Anti-Features

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|--------------------|
| Auto-merge when lint passes | Removes the human review step; wiki curation is fundamentally a judgment activity | Require at least one maintainer review; lint is necessary, not sufficient |
| Bots that auto-suggest cross-references in PR comments | LLM-in-CI is expensive, adds a failure mode, and duplicates what `bin/lint.sh` gap detection already does locally | Lint locally, surface gaps in the local run |
| A custom contributor-license-agreement bot (CLA-bot) | Scope creep; repo license already covers this; CLA bots are controversial and add friction | Skip unless the project goes commercial |
| Real-time editing / shared live vault features | Explicitly out-of-scope in PROJECT.md (`Out of Scope: Real-time / concurrent multi-user editing`) | Reiterate in CONTRIBUTING.md |
| Rich per-contributor profile pages inside the wiki | Conflates attribution with content; contributor stats belong in `git shortlog -s`, not `wiki/people/` | `log.md` index + git log are enough |
| Custom merge driver for `log.md` / `index.md` | Maintenance burden; users have to install it locally to get any benefit | Documented manual-merge recipe + idempotent `bin/ingest.sh` re-run |

**Complexity:** ~1.5 plans (plan A: CONTRIBUTING.md + PR template + lint-on-PR workflow + log.md contributor field + search filter; plan B: privacy-leak grep check + lint-report PR comment). **Dependencies:** needs Bucket 1 (repo exists) and v1.0's `bin/lint.sh` (exists). The `--strict` mode is an addition to the existing lint.

**Integration with v1.0 primitives:**
- `bin/lint.sh` gains `--strict` flag and `--report-format=github-pr-comment` output mode
- `bin/search.sh` gains `--contributor=` filter (parses `log.md` contributor field)
- `log.md` schema (LOG-01..03) amended: new optional `contributor:` key per entry
- AGENTS.md section 12 (log format) documents the new field
- No changes to ingest/query/reflect workflows themselves

---

## Feature Bucket 5 — `bin/brownfield.sh` with scan / bootstrap / suggest / verify

Onboarding path for users with an existing Obsidian vault. Strict mechanical / judgment boundary is the defining architectural decision.

### Table Stakes

| Feature | Why Expected | Complexity | Prior Art |
|---------|--------------|------------|-----------|
| `scan` is strictly dry-run, writes to stdout + a markdown file, touches no vault content | Every migration tool learned this the hard way; Notion importer, Joplin's RESTful importer, obsidian-metadata all default to dry-run | Low | Notion → Obsidian importer, Evernote ENEX importers, obsidian-metadata |
| Report classifies each page by inferred type (entity / concept / source-summary / comparison / overview / unknown) with a confidence signal | Users need to eyeball the inference before touching content | Low | obsidian-metadata's batch-preview is the closest analog |
| `bootstrap` is idempotent — running it twice on the same vault is a no-op | Users will re-run it; destructive second runs = trust death | Low | Frontmatter Generator's "skip if field present" semantics |
| `bootstrap` touches only mechanical transforms: sentinel frontmatter fields with empty values, SHA hashing of source files, creating `index.md` / `log.md` skeletons if absent, normalizing YAML quoting/ordering | Everyone agrees on what's mechanical; disagreement is about judgment, so enforcing the line keeps the tool trustworthy | Med | Strict boundary is novel vs. existing tools that blur it |
| `suggest` writes to a dedicated namespace (`.brownfield/REPORT.md`, `.brownfield/migrations/*.sh`) that is git-ignorable if the user chooses | Users want to inspect before applying; dedicated directory makes cleanup one `rm -rf` | Low | `rustfix`, `codemod` staging dirs, `terraform plan` output |
| Each staged migration script is self-describing: prints what it is about to change (dry-run default), `--apply` flag to execute, idempotent when re-run | Codemod ergonomics as of 2026 — `jscodeshift --dry`, `ruff --fix --diff` | Low-Med | `jscodeshift`, `ruff`, `gofmt -d` |
| `verify` is just `bin/lint.sh` invoked with brownfield-appropriate severity thresholds | Don't reinvent lint; reuse what exists | Low | Any tool that has `init` + `check` (e.g. `pre-commit install` + `pre-commit run`) |
| Preserves user's existing content verbatim in page bodies — only touches frontmatter and scaffolding files | Rule #1 of migration tools; every dataloss incident teaches this | Low | Universal |

### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Four transformation classes in `suggest`, each as its own staged script: `01-page-typing.sh`, `02-provenance-bootstrap.sh`, `03-cross-link-inference.sh`, `04-privacy-classification.sh` — user can apply any subset, in any order, and re-run | Granularity beats monolith. User can apply provenance but skip cross-link inference if they disagree with the heuristic. | Med | Novel; no existing Obsidian migration tool ships this architecture. Closest analog: django `squashmigrations` per-app |
| Each script prints a colorized diff of what it changed, with a trailing summary (`applied: 47 files, skipped: 12 (already compliant), errors: 0`) | Trust-building output; users see exactly what happened | Low | `ruff --diff`, `prettier --list-different`, `rsync -v` |
| `scan` report explicitly lists pages it *cannot* classify (`unknown`) with a one-line reason each, so the user knows what judgment remains to do by hand | Calibrates user expectations; tool honesty > tool confidence | Low | Novel |
| Provenance-bootstrap script marks pre-existing claims with `[inferred:bootstrap]` epistemic tag so a subsequent lint run can distinguish imported content from LLM-generated content | Preserves the v1.0 epistemic-status ethos during import; pre-existing content is *not* claimed to be sourced | Med | Novel; extends EPST-01/02 |
| The strict mechanical-vs-judgment boundary is written into the tool's help text and `docs/reference/brownfield.md` — "this is why `bootstrap` won't ever do X; use `suggest` for X" | Teaches users the architecture as they use it; reduces "why didn't it do X?" issues | Low | Explicit design-doc-in-tool is rare but high-leverage (cf. `git help everyday`) |

### Anti-Features

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|--------------------|
| `brownfield --apply` that runs all judgment-heavy transforms automatically | Already explicitly deferred to v1.2. Reasoning: mechanical errors are recoverable; judgment errors at scale silently corrupt knowledge and are hard to audit | Staged scripts; user applies each after review |
| LLM calls *inside* `brownfield.sh` to do the classification | Makes the tool non-deterministic, non-replayable, and network-dependent. The v1.0 thesis is that LLM work happens in an agent session with AGENTS.md as the contract — the CLI stays mechanical | LLM agent can be pointed at the `scan` report in a separate session, operate via structured ops, and produce a diff that reviewers see |
| Auto-installing Obsidian plugins required for the imported vault | Invasive; user-hostile; plugins drift | README note: "for best results, install Dataview X.Y" |
| A UI / TUI with arrow keys and previews | Scope creep; CLI output + generated scripts hit the same need with less code | Stay stdout + files |
| "Migration history" sqlite/json tracker | Scope creep; git already tracks what changed (each migration script is a commit) | Commit each applied migration as its own commit, use git log |
| One-shot "undo" for `bootstrap` | Git revert is the undo; the tool shouldn't reimplement it | Document `git reset` recipe in `docs/reference/brownfield.md` |
| Schema inference that invents new frontmatter fields the v1.0 schema doesn't define | Schema drift is an explicit v1.0 concern (DRFT-*); tool must not introduce it | Only emit fields that AGENTS.md already defines; log unknowns for user review |

**Complexity:** ~3 plans — the largest bucket.
- Plan A: `scan` subcommand + classification heuristics + REPORT.md format
- Plan B: `bootstrap` (mechanical transforms only, idempotency tests)
- Plan C: `suggest` migration-script generator (four classes) + `verify` wiring
  Optional plan D for polish (colorized diffs, PR-comment output). This is the feature most likely to slip into 4+ plans.

**Dependencies:** needs v1.0 `bin/lint.sh` (for `verify`), AGENTS.md schema (for what mechanical fields exist), the page-type templates (classification targets). Downstream of Bucket 1 (repo structure) only because `docs/reference/brownfield.md` lives there.

**Integration with v1.0 primitives:**
- `verify` = thin wrapper over existing `bin/lint.sh`
- Uses the same frontmatter schema (PAGE-06), same epistemic markers (EPST-01), same provenance fields (PROV-01..05)
- New `[inferred:bootstrap]` sub-marker is a narrow EPST extension
- Generated migration scripts use the existing structured-operations vocabulary (SOPS-01..04) at the level where they touch content — so post-import state is indistinguishable from greenfield state
- `scan` report classification feeds off the five page types (PAGE-01..05); if a page can't be classified it's an open question the user answers
- `.brownfield/` directory is added to `.gitignore` defaults (Bucket 1)

---

## Feature Bucket 6 — Domain-Agnostic Defaults

Kahneman-specific examples and framing are stripped from the neutral starter `AGENTS.md`. Kahneman content remains intact in `examples/kahneman/` as a reference exemplar. A neutral set of placeholder section text replaces the Kahneman-specific illustrations in AGENTS.md.

### Table Stakes

| Feature | Why Expected | Complexity | Prior Art |
|---------|--------------|------------|-----------|
| AGENTS.md uses generic placeholders (`<YOUR DOMAIN>`, `<ENTITY>`, `<CONCEPT>`) rather than "Kahneman", "Prospect Theory", etc. in section examples | Users should not have to mentally translate examples to their domain | Low | Every production template (create-react-app, cookiecutter-django, rails new) uses placeholders |
| Each AGENTS.md section that uses examples includes a `See: examples/kahneman/...` pointer to the worked instance | Decouples spec from illustration without losing the illustration | Low | Standard doc convention; Diátaxis reference/explanation separation |
| The neutral AGENTS.md is still internally consistent — a user can follow it end-to-end without ever reading `examples/` | Examples are optional; spec is load-bearing | Med | Reinforces v1.0 SCHM-01's agent-agnostic ethos |
| Epistemic markers, frontmatter schema, structured-ops vocabulary, privacy tiers all remain intact — only illustrative content moves | Preserving the v1.0 validated contract | Low | Diff-minimal refactors are standard practice |

### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| `examples/` contains a second example stub (even a one-page scaffold) for a clearly different domain — e.g. a recipe card or an engineering decision log — signaling the system is not tied to psychology-of-decisions content | Addresses the "is this only for reading pop-psych books?" reaction | Low-Med | Optional but high-leverage |
| AGENTS.md gains a short "How to adapt this for your domain" section (maybe section 2.5) that the wizard personalizes | Gives the manual-track user a target shape; gives the wizard a hook to edit | Low | Novel positioning |
| Explicit test: a lint rule (or CI check) that the neutral AGENTS.md contains zero Kahneman-specific strings | Prevents regressions; the Kahneman content will try to leak back in during routine edits | Low | Simple `grep -i kahneman AGENTS.md` in CI |

### Anti-Features

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|--------------------|
| Multiple domain presets for the neutral AGENTS.md (personal / research / engineering variants) | Explicit duplicate of the Bucket 1 anti-feature; multiplies maintenance; wizard-injected domain is better than pre-committed variants | Single neutral spec + wizard personalization |
| Removing Kahneman content entirely from the repo | It's a validated worked example costing near-zero to keep under `examples/`; deleting it loses a real-world teaching tool and breaks v1.0 validation references | Keep in `examples/kahneman/` with an explanatory README |
| A "domain taxonomy" (list of 30 approved domains) in the schema | Implies the system is rigid about domain; the whole point is it's agent-agnostic | Leave domain as a free-text field in `answers.yml` |

**Complexity:** ~0.5–1 plan (mostly careful edits to AGENTS.md + `examples/kahneman/` README + one CI regression check). **Dependencies:** Must land before or with Bucket 2 (wizard has nothing meaningful to personalize against a Kahneman-laden file). Co-ships naturally with Bucket 1 (same file moves).

**Integration with v1.0 primitives:** Edits the single largest v1.0 artifact (AGENTS.md, 1,178 lines, 16 sections). Specifically:
- Section 3 (directory layout): add `examples/` description
- Sections 4.1–4.5 (page-type examples): replace Kahneman snippets with generic
- Section 6 (epistemic syntax): examples become generic
- Section 11.1 (ingest workflow): examples become generic
- Section 12 (log format): examples become generic
- No behavioral changes; verification = v1.0 lint still passes after the edits

---

## Feature Dependency Graph

```
Bucket 1 (Template repo structure)
    |
    +--> Bucket 6 (Domain-agnostic defaults)
    |        |
    |        +--> Bucket 2 (Guided wizard) <----+
    |                  |                        |
    |                  +--> Bucket 3 (Manual setup docs)
    |
    +--> Bucket 4 (Git PR workflow)
    |
    +--> Bucket 5 (brownfield.sh)
```

Critical ordering:
1. **Bucket 1 + Bucket 6 first and together** — the template can't ship with Kahneman-laden AGENTS.md at root; the neutral file is the substrate everything else modifies.
2. **Bucket 2 + Bucket 3 second, in parallel** — they share a schema (answers.yml / manual checklist); designing one without the other invites drift.
3. **Bucket 4 independent** — can land any time after Bucket 1 since it modifies `bin/lint.sh`, `bin/search.sh`, and adds CI + docs, none of which collide with Buckets 2/3/5/6.
4. **Bucket 5 last** — largest complexity, most independent of the setup/docs work, benefits from Bucket 4's `--strict` lint mode being stable so `verify` has a real gate.

---

## MVP Recommendation

Prioritize (in order):

1. **Bucket 1 (Template repo) + Bucket 6 (Domain-agnostic AGENTS.md)** — ~1 plan combined. Unblocks everything. Delivers immediate user value (cloneable repo) even if no other bucket lands.
2. **Bucket 4 (Git PR workflow) — table-stakes slice only** (CONTRIBUTING.md, PR template, lint-on-PR CI, privacy-leak grep check). ~1 plan. High leverage for the "shareability" thesis.
3. **Bucket 2 (Guided wizard) + Bucket 3 (Manual setup docs)** — ~2.5 plans combined. This is what turns "cloneable repo" into "usable by non-experts".
4. **Bucket 5 (brownfield.sh)** — ~3 plans. The biggest unlock for users with existing Obsidian vaults. Worth the complexity; schedule last so earlier work is stable when `verify` integrates.

Defer within v1.1 (if scope compresses):
- Bucket 4's differentiators (lint-report PR comment, `--contributor=` filter) → drop to backlog
- Bucket 5's optional polish plan (colorized diffs) → drop
- Bucket 6's second-domain example stub → drop (keep just the Kahneman cleanup)

Total plan estimate: **8–10 plans across ~5 phases** (natural phase boundaries: [B1+B6], [B2+B3], [B4], [B5 scan], [B5 bootstrap + suggest + verify]).

---

## Sources

**Prior art — template repos and starter vaults:**
- [kepano/kepano-obsidian — reference Obsidian starter](https://github.com/kepano/kepano-obsidian) — HIGH confidence (active, canonical in the community)
- [andrewmcodes/obsidian-beginner-vault-template — minimal defaults](https://github.com/andrewmcodes/obsidian-beginner-vault-template) — MEDIUM
- [SoRobby/ObsidianStarterVault — comprehensive tree](https://github.com/SoRobby/ObsidianStarterVault) — MEDIUM
- [voidashi/obsidian-vault-template — structured example](https://github.com/voidashi/obsidian-vault-template) — MEDIUM
- [14 example vaults roundup — Obsidian Forum](https://forum.obsidian.md/t/14-example-vaults-from-around-the-web-kepano-nick-milo-the-sweet-setup-and-more/81788) — MEDIUM

**Prior art — scaffolding tools:**
- [Copier documentation — comparisons page](https://copier.readthedocs.io/en/stable/comparisons/) — HIGH (official)
- [Cookiecutter alternatives article](https://www.cookiecutter.io/article-post/cookiecutter-alternatives) — MEDIUM
- [Project Templating and Onboarding With Cookiecutter — Wiley 2026](https://onlinelibrary.wiley.com/doi/full/10.1002/spe.70024) — HIGH (peer-reviewed 2026)
- [Project Scaffolding That Evolves With Your Software Using Copier (podcast)](https://www.pythonpodcast.com/episodepage/project-scaffolding-that-evolves-with-your-software-using-copier) — MEDIUM

**Prior art — documentation architecture:**
- [Diátaxis framework — start here](https://diataxis.fr/start-here/) — HIGH (canonical source)
- [Canonical/Ubuntu adoption of Diátaxis](https://ubuntu.com/blog/diataxis-a-new-foundation-for-canonical-documentation) — HIGH
- [Sequin's Diátaxis adoption post-mortem](https://blog.sequinstream.com/we-fixed-our-documentation-with-the-diataxis-framework/) — MEDIUM

**Prior art — brownfield / frontmatter migration:**
- [Obsidian Frontmatter Generator plugin](https://github.com/HananoshikaYomaru/Obsidian-Frontmatter-Generator) — HIGH (active)
- [natelandau/obsidian-metadata — batch metadata updates](https://github.com/natelandau/obsidian-metadata) — HIGH (active, Python-based batch tool)
- [Obsidian Bulk Exporter plugin](https://www.obsidianstats.com/plugins/bulk-exporter) — MEDIUM
- [Obsidian Forum: bulk restructure YAML frontmatter](https://forum.obsidian.md/t/how-to-bulk-restructure-yaml-frontmatter/40169) — MEDIUM (community patterns)

**Confidence posture:**
- HIGH confidence on Diátaxis mapping and copier/cookiecutter patterns (well-documented, multiple sources agree).
- MEDIUM confidence on specific Obsidian starter vault conventions (training-data + one current search round; specific plugin versions not verified via Context7).
- MEDIUM confidence on Obsidian migration tool ecosystem — the space is active and churns; concrete tool choices (obsidian-metadata vs Frontmatter Generator) should be re-validated at implementation time.
- The strict mechanical-vs-judgment boundary in Bucket 5 has no exact prior art I found — this is a novel design choice, not a convention to follow. Treat it as an architectural bet.
