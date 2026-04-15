# Domain Pitfalls — v1.1 Shareability

**Domain:** Turning a personal LLM-maintained Obsidian wiki compiler into a shareable starter kit (template repo + guided/manual setup + PR workflow + brownfield onboarding + multi-agent support)
**Researched:** 2026-04-15
**Overall confidence:** MEDIUM — verified patterns from prior art (yeoman/copier/create-react-app, Obsidian Starter Kit community, Dataview issues, Git-wiki experiences) combined with concrete v1.0 retrospective evidence (REQUIREMENTS.md drift, deferred Obsidian verification, partial Nyquist coverage, untested Codex path).

Pitfalls below are ordered by v1.1 risk. Each identifies: failure mode, warning signs, prevention (named checks/flags/docs sections), and owning phase.

---

## Critical Pitfalls

### C-1. Accidental leakage of creator-specific content into the "neutral" starter

**What goes wrong:** Kahneman cluster, Yishai's journal entries, or personal-decision-patterns content survives into the template repo root — either in `wiki/`, `sources/`, in AGENTS.md worked examples, in `log.md` history, or in decision records. Cloners discover it, or worse, an LLM ingests it as if it were schema.

**Why it happens:**
- v1.0 AGENTS.md is 1,178 lines and its worked examples are Kahneman-flavored. Simple file moves leave inline example prose behind.
- Git history still contains private content even after deletion from HEAD (`.git/objects/`). A `git clone` of the public template pulls the whole history.
- `log.md`, `index.md`, and decision records reference real sources by path; moving `examples/` rewrites paths but not *mentions*.
- `local_only` pages could leak if the repo was ever committed with them present.

**Consequences:** Privacy breach, credibility damage ("this 'neutral' template is someone's journal"), LLM onboarding gets confused about whose domain it's working in.

**Warning signs:**
- Grep for `kahneman`, `yishai`, `prospect-theory`, `loss-aversion`, `decision-making`, personal date strings, or any `local_only` privacy tag in the template branch returns hits outside `examples/`.
- `git log --all -- wiki/ sources/` in the template repo shows commits predating the shareability milestone.
- AGENTS.md section 11.x worked examples still reference specific Kahneman page titles.

**Prevention:**
1. **`bin/check-neutrality.sh`** — CI gate that greps the template branch (not `examples/`) for a denylist of creator-specific tokens (personal names, Kahneman domain terms, `local_only`). Fail the build on any hit. Phase owns the denylist file and CI wiring.
2. **Publish from an orphan branch.** Template repo is a fresh `git init` (orphan branch pushed as `main`) — never history-rewritten from the v1.0 repo. Documented in release runbook.
3. **Redact-and-verify pass on AGENTS.md.** Every section 11.x example uses generic domain tokens (`<your-domain>`, `Example Concept`). `bin/check-neutrality.sh` greps AGENTS.md too.
4. **Starter vault is empty by default.** Only `index.md` and `log.md` skeletons; any example content lives in `examples/` with an explicit `DO NOT TREAT AS WIKI` README.

**Owning phase:** Template-extraction phase (the one that produces the public repo) + CI-setup phase. Must block release.

---

### C-2. Brownfield `bootstrap` silently corrupts existing frontmatter

**What goes wrong:** `bin/brownfield.sh bootstrap` runs YAML normalization or sentinel-frontmatter injection on an Obsidian file that already has partial or non-standard frontmatter (tabs, unquoted values with colons, multi-line strings, Dataview inline fields mistaken for frontmatter). YAML parse silently coerces or the inline Python3+PyYAML heredoc (v1.0 pattern) raises and the user loses their file.

**Why it happens:**
- Obsidian users hand-write frontmatter with quirks PyYAML doesn't love (`status: in progress` with unquoted colon in value, Dataview `[[links]]` inside YAML scalar, tabs).
- "Mechanical only" is a promise, not a technical guarantee — YAML round-trips are not byte-exact (key ordering, quote style, comment loss).
- Merging new keys into existing frontmatter can silently overwrite user keys that happen to collide with schema keys (`tags`, `aliases`, `created`).

**Consequences:** User-hostile. A brownfield tool that mangles a vault on first run kills adoption instantly. Git history saves the user, but the user has to know to check — many won't.

**Warning signs:**
- Integration tests don't include YAML edge cases (tabs, Dataview inline, multi-doc, BOM, CRLF).
- `bootstrap` writes to files without a dry-run showing exact byte-level diff.
- No pre-flight "would-affect" report listing every file it intends to touch.

**Prevention:**
1. **Mandatory `--dry-run` default.** `bin/brownfield.sh bootstrap` prints a unified diff per file and exits; `--apply` required to write. Documented in manual-setup and brownfield docs pages.
2. **Pre-flight YAML parse gate.** Before touching a file, attempt `yaml.safe_load`; on failure, add to `SKIPPED.md` with the parse error and move on. Never "fix" an unparseable file mechanically.
3. **Key-collision refusal.** If existing frontmatter has any key that bootstrap would set, skip the file and report it to the suggest report — do not overwrite. Named check: `check_key_collision`.
4. **Byte-level diff fixtures.** Integration tests include a `brownfield-fixtures/` directory with: tabs-in-yaml, Dataview-inline fields, BOM, CRLF, multi-doc, empty frontmatter, frontmatter-with-comments. Every fixture has a golden post-bootstrap file; CI greens only on byte-exact match.
5. **`--backup` ON by default.** Bootstrap writes `.brownfield/backups/<path>.orig` before any mutation. `--no-backup` requires explicit flag. Brownfield docs page documents restore procedure.
6. **Sentinel markers are unique and idempotent-detectable.** Injected sentinel includes a fixed string (e.g. `# gsd-brownfield:v1`) that bootstrap grep-checks for before re-injecting. Running bootstrap twice on the same vault is a no-op (see C-3 for the cascading version of this).

**Owning phase:** Brownfield-bootstrap phase. This is the single highest-risk surface area in v1.1 — allocate full-phase attention.

---

### C-3. Idempotency violations: running bootstrap/suggest twice produces duplicates

**What goes wrong:** Second bootstrap run re-injects sentinel frontmatter, duplicates `index.md`/`log.md` skeleton blocks, re-hashes already-hashed files with a new timestamp, or re-writes migration scripts with different names. `suggest` re-generates `.brownfield/migrations/*.sh` with different numbering on every run, so users who already applied migration 003 now see it renumbered to 004.

**Why it happens:**
- "Mechanical" scripts usually write without checking for prior state.
- Migration numbering tends to be position-based rather than content-hashed.
- Timestamps embedded in sentinel markers break byte-level equality checks across runs.

**Consequences:** Users lose confidence ("I ran this twice and now my vault is weird"). PR workflow breaks when two contributors both ran bootstrap locally and pushed divergent sentinel states.

**Warning signs:**
- Running `bin/brownfield.sh bootstrap && bin/brownfield.sh bootstrap` on a clean fixture produces a non-empty diff between the two post-states.
- Migration filenames include run timestamps.
- Sentinel markers include ingest timestamps inside the marker line.

**Prevention:**
1. **Idempotency test in CI.** `bootstrap` must produce zero-byte diff on second run. Named: `test_bootstrap_idempotent`.
2. **Content-hashed migration names.** `.brownfield/migrations/NNN-<slug>-<sha8>.sh` where the hash is over the migration's intended effect, not the generation time. Re-running `suggest` on the same vault produces the same filenames.
3. **Sentinel without timestamps.** The sentinel frontmatter marker is a fixed string + a content hash of the file's *original* body, not wall-clock time. `bootstrap_sentinel: gsd-v1:<sha8>`.
4. **index.md/log.md skeleton guarded by marker.** Skeleton injection checks for a sentinel comment `<!-- gsd-skeleton:v1 -->` and exits no-op if present.

**Owning phase:** Brownfield-bootstrap phase.

---

### C-4. PR workflow lint gate is simultaneously too strict and too loose

**What goes wrong:** The lint gate rejects legitimate PRs (new entity page with incomplete cross-references that will be filled by a follow-up ingest) while accepting PRs that introduce real drift (contradictions buried in new concept pages, orphan pages that don't appear in the index yet). Contributors learn to `--no-verify` or monkey-patch lint; the gate becomes performative.

**Why it happens:**
- v1.0 lint was tuned for single-user, whole-vault runs. PR context is partial — only changed files are linted, but lint rules assume whole-vault visibility (orphan detection, cross-ref completeness).
- Contradiction detection surfaces "live candidates" (v1.0 had 2 correct warnings). In a PR context, a warning blocks — but some warnings are intentional (the PR *adds* a contradiction the reviewer wants to see).
- Knowledge-gap detection (sparse coverage) flags new topic areas that are sparse by definition on the PR adding them.

**Consequences:** PR cadence collapses. Contributors abandon or route around the gate. v1.0's "trust layer" becomes a rubber stamp.

**Warning signs:**
- PR lint rejects a PR that a human reviewer would accept.
- Contributors open meta-PRs to "fix lint" without fixing the underlying issue.
- Gate passes on a branch that fails `bin/lint.sh` run on the merged state.

**Prevention:**
1. **Two-mode lint: `--pr` vs `--full`.** PR mode runs structural checks (YAML parse, provenance syntax, frontmatter required fields) as errors; orphan and cross-ref as warnings; contradiction and gap detection as informational. Full mode (scheduled or pre-merge-to-main) runs everything as errors. Documented in `docs/reference/lint-modes.md`.
2. **Merge-base lint comparison.** PR lint runs against `merged-state` (PR branch merged onto `main` in a temp ref), not just the PR branch head. Catches cross-ref breakage visible only post-merge.
3. **Severity escalation policy.** A warning that persists across 3 PRs is auto-promoted to error. Tracked in `.lint-state.json` (committed). Forces resolution without blocking on first pass.
4. **Expected-contradiction escape hatch.** PRs that intentionally introduce a contradiction add a `<!-- lint:expect-contradiction id=<slug> -->` marker and the lint surfaces it without blocking. Reviewer sign-off is the gate, not mechanical lint.
5. **Gap detection exempts PR-new topics.** Gap lint compares against `main`'s topic set; topics introduced in the PR are exempt for this run. Documented flag: `--exempt-pr-new`.

**Owning phase:** Collaboration/PR-workflow phase.

---

## Moderate Pitfalls

### M-1. Guided wizard generates AGENTS.md that drifts from the canonical schema

**What goes wrong:** The wizard writes an AGENTS.md by templating user answers into a preset. The preset lives in the wizard code. Six months later AGENTS.md ships a section 11.5 (new workflow); the wizard's template still produces section 11.1–11.4 only. Wizard-generated vaults diverge from manual-setup vaults.

**Why it happens:** Prior art: yeoman generators, create-react-app, cargo-generate — all suffer template drift when the canonical source of truth (the framework's actual template) is duplicated inside a generator that has its own release cadence. Copier's `--trust` model + template versioning is the response to exactly this.

**Warning signs:**
- Wizard template lives in a separate file from the "real" AGENTS.md.
- Wizard template has no schema version pin.
- No CI check that wizard output matches the canonical AGENTS.md structure.

**Prevention:**
1. **Wizard reads canonical AGENTS.md and performs section-level substitution.** Don't maintain a parallel template. Canonical AGENTS.md has explicit `{{USER_DOMAIN}}`, `{{PRIVACY_DEFAULT}}`, `{{AGENT_NAME}}` placeholders in documented locations. Wizard does key replacement only.
2. **Schema version in both.** AGENTS.md frontmatter has `schema_version: 1.1.0`; wizard asserts it supports that version or refuses to run.
3. **CI check: `test_wizard_output_matches_manual`.** Run wizard with canned answers, run manual-setup walkthrough with same inputs (via doctested doc), diff the two AGENTS.md files — must be byte-equal modulo placeholder substitutions.
4. **Wizard in a single script file.** `bin/setup.sh` with no dependency on a separate template repo. Same repo, same commit, same AGENTS.md.

**Owning phase:** Wizard phase.

---

### M-2. Wizard prompts produce dead-end or contradictory configs

**What goes wrong:** User answers privacy=`all_local` then selects a cloud agent (Claude API); wizard writes an AGENTS.md that says both things. Or wizard asks for domain early, uses it for later prompt defaults, user changes their mind, no back-navigation. Or wizard writes files on step 3 of 7 and crashes on step 5 — partial state, no rollback.

**Why it happens:** Shell wizards typically go forward-only and write eagerly.

**Warning signs:**
- Wizard writes any file before the final confirmation step.
- No validation between prompts (privacy-vs-agent, domain-vs-example-scope).
- No `--review` or summary screen.

**Prevention:**
1. **Two-phase wizard: collect → confirm → write.** All prompts answered first, full summary shown, single confirmation, atomic write (temp dir → mv). Documented pattern.
2. **Validation matrix.** Explicit table in wizard code of incompatible combinations (privacy=`all_local` + agent=cloud-only) with specific error messages and suggested fixes.
3. **Resumable state.** Wizard writes answers to `.setup-state.json` at each step; `--resume` reads it. User can ctrl-C and restart without losing input.
4. **`--dry-run` flag.** Shows what would be written without writing. Manual-setup doc page shows how to derive the same result.

**Owning phase:** Wizard phase.

---

### M-3. Documentation tracks (quickstart/guided/manual/reference) diverge

**What goes wrong:** Quickstart shows `bin/setup.sh --domain personal`; the flag was renamed 3 commits later in the wizard. Manual-setup doc describes AGENTS.md section 11.2 with 4 steps; reference doc describes it with 5. Reference matches code; docs don't. Known v1.0 analog: 9 REQ-IDs stayed "Pending" in REQUIREMENTS.md after phase VERIFICATION passed — the mechanical-check failure pattern repeats here if uncaught.

**Why it happens:** Four docs, one schema, no enforced linkage. Writers update one track and forget the others. v1.0 retrospective explicitly flagged "traceability tables need a mechanical check."

**Warning signs:**
- A code/schema change lands without an accompanying doc PR.
- Manually running through quickstart from a fresh clone fails.
- Manual and guided tracks produce end states that don't byte-match.

**Prevention:**
1. **Doctest-style snippet extraction.** Every fenced code block in `docs/` tagged `shell` with a `<!-- doctest -->` marker is extracted by `bin/doctest-docs.sh` and executed in a sandbox clone. CI runs this. Failing snippet blocks merge.
2. **Shared fragment files.** Setup steps live in `docs/_fragments/*.md` and are included by all four track docs. Updating one fragment updates every track that uses it. Reference doc includes all fragments.
3. **`docs/reference/AGENTS-sections.md` generated from AGENTS.md.** Script extracts section headings + first paragraph from canonical AGENTS.md. CI fails if the generated file is stale (not regenerated in the same commit as AGENTS.md changes).
4. **Fresh-clone smoke test in CI.** Checkout template, run quickstart step-by-step via the doctest extractor, ingest a fixture source, run lint — green required.
5. **Schema-version pin in every doc page frontmatter.** Bumping `schema_version` flags all docs as stale until each is reviewed. Named check: `check_doc_schema_pin`.

**Owning phase:** Docs-structure phase + CI-setup phase.

---

### M-4. Template repo forks can't upgrade as the template evolves

**What goes wrong:** User forks the template, personalizes AGENTS.md with their domain, runs the wizard, ingests 200 sources. Template releases v1.2 with a new section 11.5 workflow and a bin/lint.sh rule. User wants the upgrade but their fork has diverged — merge conflicts in AGENTS.md (their personalizations vs new sections), conflicts in bin/ scripts they may have customized, conflicts in example pages.

Prior art: create-react-app's eject is one-way; expo-eject is painful; dotfile bootstrappers (chezmoi, yadm) solved this with templating + diff-based apply.

**Warning signs:**
- No documented upgrade path between template versions.
- Schema version not visible to the user's repo.
- No separation between "user-owned" files (AGENTS.md, wiki/) and "template-owned" files (bin/, schema/templates/).

**Prevention:**
1. **Explicit ownership boundary.** Documented in `docs/reference/ownership.md`: `bin/`, `schema/templates/`, `docs/` are template-owned (upgrade overwrites); `AGENTS.md`, `wiki/`, `sources/`, `examples/` are user-owned (upgrade never touches). Files users edit stay user-owned; mechanical upgrade only replaces template-owned files.
2. **`bin/upgrade.sh <target-version>`.** Fetches target-version template-owned files, shows diff, applies with `--apply`. Refuses to run if user has local modifications to template-owned files without `--force`.
3. **Schema version in AGENTS.md frontmatter.** User sees `schema_version: 1.1.0` and can compare against template HEAD.
4. **Migration notes per schema version.** `docs/reference/migrations/1.0-to-1.1.md` — what AGENTS.md sections users must review, what new fields to add manually.
5. **AGENTS.md modular via includes.** User's AGENTS.md has `<!-- include: schema/sections/11-workflows.md -->` markers; template ships the included sections; upgrade updates the included files. User-specific content (domain, examples) stays in the top-level file.

**Owning phase:** Template-extraction phase + upgrade-path sub-phase (possibly deferred — document the boundary in v1.1, implement `bin/upgrade.sh` in v1.2).

---

### M-5. Frontmatter YAML merge conflicts in concurrent PRs

**What goes wrong:** Two contributors both ingest on branches that touch the same concept page's frontmatter (`sources:` list, `last_updated:`, `has_contradictions:`). Git's line-based merge fails — both branches added to the `sources:` list, merge-conflict markers get injected into YAML, vault breaks.

**Why it happens:** YAML sequences are line-oriented, and ingest consistently appends. v1.0's append-then-synthesize policy is correct for content but still causes YAML append conflicts.

**Warning signs:**
- Frontmatter YAML in the repo is multi-line sequences rather than flow-style.
- No documented conflict-resolution playbook.
- `bin/ingest.sh` rewrites whole frontmatter blocks rather than appending a single line.

**Prevention:**
1. **Frontmatter field ordering canonicalized.** A `bin/normalize-frontmatter.sh` sorts sequence entries (sources list, tags) and normalizes whitespace. Runs as a pre-commit hook and as a lint check. Git 3-way merge on sorted lists produces clean additions.
2. **Sources list as one-per-line with trailing comma.** Standardized in AGENTS.md schema — enables clean git line-merge.
3. **Conflict-resolution doc page.** `docs/reference/merge-conflicts.md` — step-by-step for the three common YAML conflicts (sources list, epistemic markers in body, log.md append).
4. **`bin/resolve-conflict.sh`.** Takes a conflicted file, parses both sides' YAML, produces the union for sequence fields, prompts for scalar fields. Documented helper, not magic.
5. **log.md uses section-per-day append pattern.** Each day's entries under a dated `## 2026-04-15` header; concurrent appends on different days never conflict; same-day conflicts resolve by ordering within the day.

**Owning phase:** Collaboration/PR-workflow phase.

---

### M-6. Concurrent ingests create duplicate pages for the same entity/concept

**What goes wrong:** Two contributors ingest the same paper (or two papers on the same concept) on parallel branches. Each creates `wiki/concepts/prospect-theory.md` with different content and different provenance chains. Merge: both files exist (different slugs) or one clobbers the other.

**Why it happens:** `bin/ingest.sh` has slug-collision detection against the current branch's filesystem but can't see the other branch's pending page.

**Warning signs:**
- Ingest helper does not check remote branches.
- No page-intent reservation mechanism.
- Lint passes post-merge but topic is split across two pages.

**Prevention:**
1. **Ingest helper queries remote.** `bin/ingest.sh` runs `git fetch --all` and greps remote branches (`git branch -r` + `git grep` across refs) for matching page slugs/titles before creating. Warns + suggests branch name or coordination.
2. **Topic-reservation file.** `.pending-topics.md` committed at branch creation time — lists topics the branch intends to write. Lint warns on overlap.
3. **Post-merge dedup lint rule.** New lint rule `detect_duplicate_concepts`: compares page titles + aliases + top-level concepts via fuzzy match, surfaces likely duplicates in the report.
4. **Documented: asynchronous coordination is async.** `docs/reference/collaboration.md` explicitly calls out that real-time locking is out of scope (matches PROJECT.md). Users coordinate through issues/PR descriptions.

**Owning phase:** Collaboration/PR-workflow phase.

---

### M-7. Cross-references valid per-branch, broken post-merge

**What goes wrong:** Branch A renames `wiki/concepts/system-1.md` → `wiki/concepts/dual-process.md` and updates all inbound `[[system-1]]` wikilinks. Branch B adds a new page with `[[system-1]]` wikilinks (valid at branch time). Merge succeeds (different files). Post-merge: B's new wikilinks are dead.

**Warning signs:** No post-merge link-validation lint. Lint rule exists but is not gated on merge.

**Prevention:**
1. **Post-merge lint hook (CI job on `main`).** Runs full `bin/lint.sh` on main after every merge; opens an auto-fix PR for detected link breakage. Named: `post_merge_link_audit`.
2. **PR lint in merge-base mode** (see C-4 prevention #2) — catches the common case pre-merge.
3. **Rename helper.** `bin/rename-page.sh <old> <new>` updates inbound references, writes a redirect stub in `<old>.md`, and adds a decision record. Renames coordinated via PR + decision-record-in-PR doc convention.

**Owning phase:** Collaboration/PR-workflow phase.

---

### M-8. Attribution confusion — git author ≠ ingest author ≠ source author

**What goes wrong:** Contributor A ingests a paper written by researcher B. The log.md entry shows A as contributor; the source summary page shows B as author; a reviewer merges via squash and suddenly git `Author` is A but `Committer` is the maintainer — later reports credit the maintainer. Users confuse "who curated" with "who authored."

**Why it happens:** v1.1 PROJECT.md says git authorship is source of truth *and* log.md carries a contributor field as convenience index. Convenience indices drift.

**Warning signs:**
- log.md contributor field populated manually.
- Source summary pages don't distinguish `source_author` from `ingest_contributor`.
- Squash-merge the default on the template's PR setup.

**Prevention:**
1. **Three distinct fields, named in AGENTS.md §3 (frontmatter schema):** `source_author` (person who wrote the source), `ingest_contributor` (person whose git commit first ingested), `last_modified_by` (most recent editor). Populated from git, not manually.
2. **`bin/update-contributor-index.sh`.** Reads git log, rewrites log.md contributor fields mechanically. Run as pre-commit hook; manual edits to log.md contributor fields fail lint.
3. **Merge strategy: merge commits, not squash, for ingest PRs.** Documented in `docs/reference/pr-workflow.md`. Preserves authorship. Squash allowed for docs-only PRs.
4. **Attribution doc page.** `docs/reference/attribution.md` distinguishes the three roles explicitly, with examples.

**Owning phase:** Collaboration/PR-workflow phase.

---

### M-9. H1 title detection picks wrong heading

**What goes wrong:** `brownfield.sh suggest` infers page title from first H1. User's page starts with `# TODO` or `# Notes` or `# 2024-01-03` (daily note). Suggested page type and title are nonsense; inferred slug collides with a real page; user applies migration, vault is worse.

**Warning signs:**
- Title-inference has no confidence score.
- No fallback to filename or frontmatter-based title.
- Migration scripts reference inferred titles inline rather than via a reviewable mapping.

**Prevention:**
1. **Multi-signal title inference.** Priority: explicit frontmatter `title:` → filename (de-slugified) → first H1 *if longer than 2 words and not a date/TODO* → `UNTITLED-<hash>`. Documented in brownfield reference.
2. **Title-inference report row per file.** `.brownfield/REPORT.md` includes an explicit `Inferred title: X (confidence: low/med/high, reason: ...)` line per file. User reviews before applying.
3. **Denylist of low-information H1s.** `TODO`, `Notes`, date regexes, `Untitled`. H1 match against denylist → fall through to next signal.
4. **Migration script prints before/after.** Every migration's `echo` line shows `wiki/concepts/foo.md: title "Notes" → "Kahneman on Loss Aversion"`. Idempotent re-run detects already-applied and no-ops.

**Owning phase:** Brownfield-suggest phase.

---

### M-10. Dataview queries break on new empty-value frontmatter fields

**What goes wrong:** Bootstrap adds `has_contradictions: false` and `knowledge_domain: unknown` to every page. Existing Dataview query `WHERE has_contradictions = true` is fine, but `WHERE knowledge_domain` (existence check idiom) now matches every page including the empty ones. User's carefully tuned dashboards break.

**Why it happens:** Dataview is whitespace-sensitive and field-presence-aware. v1.0 retrospective explicitly notes "Obsidian render/Dataview check deferred from Phase 4" — this hazard was not exercised.

**Warning signs:**
- No Dataview-query regression fixture.
- Bootstrap adds fields with string default `""` vs `null` vs absent-key indistinguishably.
- No docs page on how new fields interact with Dataview.

**Prevention:**
1. **New fields default to schema-documented sentinels, not empty strings.** `unknown` for enums, `[]` for sequences, absent (not `null`) for optional scalars. Documented in AGENTS.md §3.
2. **Obsidian-Dataview rendering fixture.** `examples/dataview-fixtures/` with known-good queries that must still return expected row counts after bootstrap. Verified via Obsidian automated render test (resolves deferred Phase 4 verification from v1.0).
3. **Bootstrap `--preserve-dataview` audit mode.** Scans all `.md` files for Dataview blocks, lists which new fields would affect which queries, user reviews before apply.
4. **Migration docs: "new fields and Dataview."** `docs/reference/dataview-impact.md` enumerates every v1.1 frontmatter field and its Dataview implications.
5. **Close the v1.0 deferred verification in v1.1.** Open the canonical Obsidian vault and confirm all existing Dataview queries and the graph view render correctly on both a fresh starter and a post-bootstrap brownfield fixture. Named gate in a verification phase.

**Owning phase:** Brownfield-bootstrap phase (fields + sentinels) + verification phase (actual Obsidian render gate, closing v1.0 debt).

---

### M-11. "Safe auto" introducing semantic changes disguised as mechanical

**What goes wrong:** Bootstrap promises "mechanical only" but YAML normalization removes user comments, reorders keys (Dataview preserves order for display in some plugins), strips trailing whitespace that was load-bearing in a Markdown table. User sees "no content change" in the diff summary but their vault's *rendering* changed.

**Why it happens:** The line between mechanical and semantic is fuzzy. YAML round-trip is not byte-preserving. Markdown is whitespace-sensitive in specific ways.

**Warning signs:**
- Bootstrap's diff summary counts only content-body bytes, not frontmatter bytes.
- YAML normalization uses default dumper (reorders keys).
- No explicit list of transformations bootstrap will perform.

**Prevention:**
1. **Explicit transformation manifest.** `docs/reference/brownfield-bootstrap-transformations.md` enumerates every byte-level change bootstrap may make (e.g. "normalize CRLF → LF; inject sentinel comment line; add frontmatter key X if absent"). Anything not listed is a bug.
2. **Key-order preservation via ruamel.yaml, not PyYAML.** Use a round-trip loader that preserves order and comments. Keep v1.0's inline-Python pattern but with ruamel.yaml instead.
3. **Byte-diff test for all listed transformations.** CI fixture set where each transformation has inputs and expected outputs; no other bytes change. Named: `test_bootstrap_transformation_manifest`.
4. **`--strict` mode.** Refuses to touch any file where the diff includes unlisted byte changes. Default mode logs them as warnings.

**Owning phase:** Brownfield-bootstrap phase.

---

### M-12. Multi-agent interpretation drift (Claude Code vs Codex vs others)

**What goes wrong:** AGENTS.md §11.2 says "read the index first, then drill down." Claude Code honors that. Codex reads §11.2 differently — maybe starts with a grep. Two users' wikis diverge in silent ways: Codex user's `log.md` shows no index-first reads but successful ingests; claim-provenance granularity differs; structured operations applied subtly differently. v1.0 PROJECT.md explicitly flags this: "only Claude Code exercised in v1.0 — Codex pending."

**Why it happens:** Natural-language schema is interpretation-sensitive. Different agents' training, system prompts, and tool surfaces produce different readings.

**Warning signs:**
- No agent-parity test suite.
- No documented "what Codex does differently" section.
- Bug reports from one agent class only.

**Prevention:**
1. **Agent-parity fixture.** A canonical ingest scenario (source → expected page diff). Run with Claude Code and Codex (and others as they're added). Compare output against a golden reference; diffs beyond a tolerance flag interpretation drift. Named: `test_agent_parity`.
2. **Deterministic gates do the real enforcement.** `bin/validate-op.sh`, `bin/lint.sh`, and frontmatter-schema checks are the trust layer — not the agent's interpretation. Expand their coverage so interpretation gaps can't silently pass. (v1.0 already did this for structured ops; extend to ingest-output schema: minimum/maximum provenance markers, claim-granularity bounds, required sections per page type.)
3. **Per-agent addendum files.** `schema/agent-notes/claude-code.md`, `schema/agent-notes/codex.md` — agent-specific gotchas, permitted deviations, known drift patterns. Loaded alongside AGENTS.md. Keeps the core agent-agnostic while acknowledging practical reality.
4. **Lockfile for interpretation decisions.** When an agent makes a judgment call the schema doesn't pin (e.g., "should this split into two concept pages?"), log the decision in a structured-op log with agent ID. Cross-agent drift becomes queryable.
5. **Close the v1.0 agent-agnostic flag explicitly.** Run full v1.0 workflows with Codex against the Kahneman test cluster; diff outputs against Claude Code's. Document findings in `docs/reference/agent-parity.md`. Gate v1.1 completion on this.

**Owning phase:** Verification phase (agent-parity suite) + docs phase (agent-notes addendums).

---

## Minor Pitfalls

### m-1. Wizard assumes `bash`, excludes zsh/fish/Windows users

**What goes wrong:** Wizard relies on `bash`-specific features (arrays, `[[ ]]`, process substitution); Windows Git Bash or PowerShell users hit obscure errors.
**Prevention:** `#!/usr/bin/env bash` + shellcheck CI + explicit Windows compat doc note ("use Git Bash or WSL"). Do not try to support PowerShell natively in v1.1 — document the limitation.
**Owning phase:** Wizard phase.

### m-2. Kahneman examples in `examples/` become stale against evolving schema

**What goes wrong:** Kahneman cluster was hand-crafted against v1.0 schema. Schema evolves; examples don't. Users see outdated conventions in examples and copy them.
**Prevention:** `examples/` runs through the full lint suite in CI with the current schema version. Stale examples fail CI. Named: `test_examples_schema_current`.
**Owning phase:** Template-extraction phase.

### m-3. "As you know" documentation from creator

**What goes wrong:** Docs reference assumed knowledge ("standard Obsidian Dataview"), skip `local_only` privacy rationale because the creator internalized it.
**Prevention:** Outside-review pass by at least one person with no prior v1.0 exposure before v1.1 ships. Checklist in `docs/` contributor guide: "explain every jargon term on first use; no 'just'/'simply'/'obviously'." Linting with vale.sh for weasel words optional.
**Owning phase:** Docs phase.

### m-4. REQUIREMENTS.md bookkeeping drift recurs in v1.1

**What goes wrong:** Same v1.0 pattern — REQ-IDs marked `Pending` after VERIFICATION passes. Retrospective already flagged this as "needs a mechanical check."
**Prevention:** Build the `requirements-sync` command in v1.1 (retrospective recommendation). Compare each phase's VERIFICATION.md Observable Truths against REQUIREMENTS.md status; auto-flip or fail.
**Owning phase:** First phase of v1.1 (infrastructure).

### m-5. Partial Nyquist coverage recurs in v1.1

**What goes wrong:** v1.0 ended with 4/6 VALIDATION.md in draft because audit ran at milestone end. Same risk in v1.1.
**Prevention:** Run `/gsd:validate-phase` at phase transition (retrospective recommendation), not milestone end. Add to phase-transition checklist.
**Owning phase:** Every phase (process-level, not feature-level).

### m-6. Deferred Obsidian verification slides again

**What goes wrong:** v1.0 deferred Obsidian render/Dataview/graph verification. Retrospective: "convention correctness is not rendering correctness." v1.1 adds more fields, more brownfield-injected content, more Dataview interaction — defer again and the surface area grows.
**Prevention:** Gated verification phase. Opens Obsidian (automated via Obsidian CLI / headless render if available, otherwise a documented manual checklist with screenshots) on both fresh starter and post-bootstrap fixture. Surfaced as a `deferred_verification` list persistent in `.planning/` (retrospective recommendation).
**Owning phase:** Final verification phase of v1.1.

### m-7. `local_only` pages accidentally pushed by contributors who didn't internalize the privacy tier

**What goes wrong:** A contributor ingests a source marked `local_only`, doesn't notice, commits, pushes. Privacy breach via PR.
**Prevention:** Pre-commit hook + CI gate: refuse any commit/PR that includes a file with `privacy: local_only` frontmatter. Named: `check_no_local_only_in_commit`. Documented in quickstart + manual + guided tracks.
**Owning phase:** PR-workflow phase.

### m-8. Migration scripts run with wrong CWD

**What goes wrong:** `bin/brownfield.sh` generates `.brownfield/migrations/003-fix-titles.sh` with relative paths assuming vault root as CWD; user runs from `.brownfield/` directory; no-op or wrong-files.
**Prevention:** Every generated migration starts with a CWD assertion (`cd "$(git rev-parse --show-toplevel)"` or explicit abort if not in a git repo root). Template for migrations includes this as boilerplate.
**Owning phase:** Brownfield-suggest phase.

---

## Phase-Specific Warnings

| v1.1 Phase (topic) | Likely Pitfall | Mitigation |
|---|---|---|
| Template extraction | C-1 creator-content leakage; M-4 upgrade-path needs ownership boundary | `bin/check-neutrality.sh` denylist + orphan-branch publish; document user-owned vs template-owned files |
| Docs structure (4 tracks) | M-3 doc drift; m-3 "as-you-know" | Doctest-style snippet extraction, shared fragments, outside-reviewer pass |
| Wizard | M-1 schema drift; M-2 dead-end prompts; m-1 shell compat | Single source AGENTS.md with placeholders; two-phase collect→confirm→write; shellcheck CI |
| Manual setup | M-3 divergence from guided | Shared fragments; `test_wizard_output_matches_manual` |
| PR workflow + lint gate | C-4 too strict/too loose; M-5 YAML conflicts; M-6 duplicate pages; M-7 link breakage; M-8 attribution; m-7 local_only leak | Two-mode lint `--pr`/`--full`; canonicalize frontmatter ordering; remote-aware ingest; post-merge lint; three-field attribution schema; local_only pre-commit gate |
| Brownfield `scan` | (Low risk — read-only report) | Include confidence scores in every inference |
| Brownfield `bootstrap` | C-2 silent corruption; C-3 non-idempotent; M-10 Dataview breakage; M-11 semantic-disguised-as-mechanical | `--dry-run` default; YAML pre-flight parse gate; key-collision refusal; byte-level fixture tests; ruamel.yaml round-trip; idempotency CI test; transformation manifest |
| Brownfield `suggest` | M-9 bad title inference; m-8 CWD assumptions | Multi-signal inference with confidence score; denylist; CWD assertion in every migration |
| Brownfield `verify` | (Integrates with lint — inherits C-4 risks) | Ensure verify uses `--full` mode after brownfield apply, not `--pr` |
| Multi-agent validation | M-12 Claude Code vs Codex drift | Agent-parity fixture; Codex run against Kahneman cluster; deterministic gates do enforcement |
| Final verification / closeout | m-4 REQUIREMENTS drift; m-5 Nyquist gaps; m-6 deferred Obsidian | `requirements-sync` command; per-phase `/gsd:validate-phase`; gated Obsidian render/Dataview check closing v1.0 debt |

---

## Sources

**HIGH confidence (v1.0 first-party):**
- `.planning/PROJECT.md` — v1.1 scope, agent-agnostic constraint, deferred verifications
- `.planning/milestones/v1.0-MILESTONE-AUDIT.md` — REQUIREMENTS.md drift (9 items), SUMMARY frontmatter gaps (15 items), Nyquist partial coverage (4/6 phases draft), deferred Obsidian checks
- `.planning/RETROSPECTIVE.md` — "traceability tables need a mechanical check"; "convention correctness is not rendering correctness"; "deferred verification tracking needed"; inline Python+PyYAML pattern; append-then-synthesize policy
- `.planning/milestones/v1.0-ROADMAP.md` — phase structure, Phase 999.1 brownfield-backlog note ("cross-cuts Phase 1-5 concerns")

**MEDIUM confidence (established prior art, pattern-matched):**
- yeoman / create-react-app / copier / cargo-generate template-drift patterns → M-1, M-4
- chezmoi / yadm / dotbot template-fork upgrade patterns → M-4
- Obsidian Starter Kit community + Dataview field-presence semantics → M-10
- Git-wiki (gollum, MediaWiki-on-Git) merge-conflict patterns on frontmatter/YAML → M-5
- Monorepo docs-drift mitigations (doctest, shared fragments, schema-pin) → M-3

**LOW confidence (reasoned-through, not sourced):**
- Multi-agent interpretation drift magnitude (M-12) — no empirical data yet; prevention strategies are precautionary. v1.0 PROJECT.md explicitly flags Codex as untested. Treat as hypothesis to validate.
- Agent-parity tolerance threshold — what counts as "drift" vs "acceptable variation" is undefined until first Codex run produces real diffs.
