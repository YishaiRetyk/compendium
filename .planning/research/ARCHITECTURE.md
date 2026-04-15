# ARCHITECTURE: v1.1 Shareability Integration

**Researched:** 2026-04-15
**Mode:** Project architecture (subsequent milestone, integration-focused)
**Overall confidence:** MEDIUM-HIGH (grounded in existing v1.0 code/schema; judgments about UX tradeoffs are opinion, marked where so)

Each decision below gives: recommendation, integration points, new vs modified, failure modes, build-order slot.

---

## Decision 1: Personalized `AGENTS.md` generation — template substitution, NOT layered override

**Recommendation:** (a) **Template substitution** over the canonical `AGENTS.md` using a small set of named placeholders (`{{PRIMARY_DOMAIN}}`, `{{DEFAULT_PRIVACY}}`, `{{AGENT_FILENAME}}`, `{{DECAY_PROFILE}}`, `{{EXAMPLE_CLUSTER_REF}}`), emitted by a generator (`bin/init-wizard.sh`) that reads `/schema/AGENTS.template.md` + answers from interactive prompts.

**Reject (b) layered core + `AGENTS.local.md` override:** v1.0 explicitly routes all agents to a single schema document (AGENTS.md section 3 LLM Navigation Rule; SCHM-01 agent-agnostic). A "read both files, local wins on conflict" contract adds a precedence rule that every agent must obey — that is exactly the complexity SCHM-01 rejects.

**Reject (c) pure generator producing a novel file:** loses diffability — users who upgrade lose track of what their personalizations actually were.

**Integration points:**
- **New file:** `schema/AGENTS.template.md`
- **New script:** `bin/init-wizard.sh` (interactive prompts → renders template → writes `AGENTS.md` or `CLAUDE.md` at repo root)
- **New file:** `.wizard-answers.yaml` (records inputs that produced current AGENTS.md — powers upgrades)
- **Modified:** Section 3 gains a note that `AGENTS.md` is a rendered instance
- **New frontmatter field:** none (AGENTS.md is not a wiki page)

**Schema upgrade propagation:** Template header carries `schema_version: "1.1.0"`. `bin/init-wizard.sh --upgrade` re-renders new template using `.wizard-answers.yaml` and produces 3-way merge vs. current AGENTS.md.

**Failure modes:**
- Too many placeholders → template becomes unreadable. Keep ≤ 6.
- Hand-edits despite guidance → upgrade path painful. Mitigation: `bin/lint.sh --schema-drift` diffs rendered template vs current AGENTS.md.
- Layered-override not foreclosed — AGENTS.local.md could be added in v1.2 without breaking v1.1.

**v1.0 primitives reused:** AGENTS.md structure (16 sections), bash+inline-python3, 16-field frontmatter schema (unaffected).

**Build order:** AFTER Kahneman move (Decision 2).

---

## Decision 2: Kahneman → `examples/` — move + rewrite wikilinks + example-mode banner

**Recommendation:** (A) **Move to `examples/kahneman/` with full wikilink rewrite**, plus `examples/kahneman/README.md` banner and frontmatter field `example: true`. Starter `wiki/` ships empty except `index.md` and `log.md` skeletons.

**Reject (B) leave in wiki/ with banner:** contaminates Obsidian graph view (OBSD-03). Banner doesn't stop Dataview queries.

**Reject (C) symlinks:** breaks Windows, breaks git on some configs, breaks Obsidian vault indexing.

**Integration points:**
- **New directory:** `examples/kahneman/{entities,concepts,sources,comparisons,overviews}/`
- **Modified files:** all 7 Kahneman pages move; internal wikilinks preserved
- **Modified:** `wiki/index.md` stripped → "no content yet — see `examples/kahneman/index.md`"
- **Modified:** `wiki/log.md` Kahneman entries move to `examples/kahneman/log.md` (preserves §12 append-only invariant)
- **Modified:** `wiki/decision-making.md` + other overviews — rewrite Related Pages into `examples/kahneman/...`
- **New frontmatter field:** `example: true` (boolean, optional, default false)
- **Modified AGENTS.md sections:** §2 (add `examples/`), §5 (new `example` field), §15 (Obsidian config / `.obsidianignore`), §16 (replace Kahneman-specific Dataview examples)
- **Modified lint:** `EXCLUDE_DIRS` in `bin/lint.sh` gains `'examples'` when `example: true` present or dir is `examples/`

**Decision record required:** SUPERSEDE-class structural reorganization per §11.4. Emit `dr-YYYY-MM-DD-kahneman-to-examples.md`.

**Failure modes:**
- Example pages still appear in graph view: ship default `.obsidianignore` / workspace config.
- Users can't find Dataview examples: `examples/kahneman/` is canonical tour.
- PR lint complains about example orphans: EXCLUDE_DIRS prevents this.

**v1.0 primitives reused:** SUPERSEDE, decision records, lint EXCLUDE_DIRS, frontmatter extensibility (precedent: `has_contradictions`, `knowledge_domain`).

**Build order:** **FIRST feature in v1.1 after scaffolding.**

---

## Decision 3: `contributor` field in log.md — inline Dataview field

**Recommendation:** Add `contributor:: <github-handle>` as **Dataview inline field on its own line** after the entry header, alongside existing per-entry sub-fields.

**Rejected:**
- Per-entry YAML block — breaks log.md's "single top-level YAML" structure.
- Header-line change — breaks `bin/lint.sh` grep convention `^## \[`.

**Why Dataview inline:** AGENTS.md §6 already uses `[prov::...]`, `[epistemic::...]`. `contributor::` is a semantic extension. Dataview indexes automatically. Existing parsers unaffected.

**Integration points:**
- **Modified AGENTS.md §12:** add optional `contributor::` convention
- **Modified AGENTS.md §11.1:** ingest reads `git config user.name` or `--contributor` flag
- **Modified bin/ingest.sh:** accept `--contributor`, auto-detect from `git config user.email`, omit if single-author
- **Modified bin/lint.sh:** new optional check — `contributor::` handles appear in git commit authors (low-severity warning)
- **New CLI flag:** `bin/ingest.sh --contributor <handle>`
- **No new frontmatter field**

**Failure modes:**
- Handles drift from GitHub usernames — lint catches this. Git authorship is ground truth.
- Private forks — field optional.

**v1.0 primitives reused:** inline Dataview syntax (§6), log.md append-only (§12), `bin/ingest.sh` flag extensibility.

**Build order:** Mid-v1.1, AFTER Decision 6 (PR workflow).

---

## Decision 4: Brownfield bootstrap sentinels — `bootstrap_stage` field

**Recommendation:** Introduce **`bootstrap_stage`** as optional frontmatter field with values `raw|bootstrapped|verified|null`. `bin/brownfield.sh bootstrap` sets `bootstrap_stage: bootstrapped` alongside placeholders (`type: unknown`, `epistemic_status: tentative`, `knowledge_domain: ""`).

Lint becomes aware: when `bootstrap_stage: bootstrapped`, downgrade allowlist findings (unknown `type`, empty `knowledge_domain`, missing `sources`, `epistemic_status: tentative`) from `error` to `info`, tagged "brownfield — pending `suggest`."

**Why dedicated field vs special `type` value:**
- Cleaner separation: `type` stays semantic, `bootstrap_stage` procedural.
- Avoids growing every page-type table.
- Green-field vaults never set it — no noise.

**Integration points:**
- **New frontmatter field:** `bootstrap_stage` (optional, enum `raw|bootstrapped|verified`)
- **Modified AGENTS.md §5:** add field + new subsection "Brownfield fields — optional"
- **Modified AGENTS.md §2:** document `.brownfield/`
- **Modified bin/lint.sh:** `BASE_FIELDS` unchanged; severity downgrade logic + new `brownfield` category
- **New CLI script:** `bin/brownfield.sh`

**Failure modes:**
- Forgotten sentinel → lint warns on pages `bootstrapped` older than 30 days.
- `bin/ingest.sh` strips the field if encountered on normal ingest.
- Relaxed lint hides real errors: allowlist narrow; other errors full severity.

**v1.0 primitives reused:** severity-tiered lint, frontmatter extensibility, AGENTS.md §5 pattern.

**Build order:** Concurrent with Decision 5.

---

## Decision 5: Brownfield idempotency — checksum-keyed `.brownfield/applied.log`

**Recommendation:** Each migration script contains a **stable content hash** (sha256 of operation payload, NOT whole file). On run:
1. Compute operation hash
2. Check `.brownfield/applied.log` for `<hash> <iso-date> <script-name>`
3. If present: print "already applied, skipping", exit 0
4. If absent: execute, append line to applied.log

**Rejected:**
- Marker frontmatter on target files — one migration touches many pages.
- Per-target checksumming — fragile when user hand-edits between runs.
- Pure inherent idempotency — breaks for multi-step ops.

**Integration points:**
- **New directory:** `.brownfield/` (git-ignored default; opt-in commit)
- **New files:** `.brownfield/REPORT.md`, `.brownfield/migrations/*.sh`, `.brownfield/applied.log`
- **Convention:** migration header must contain `# op_hash: <sha256>`
- **Modified AGENTS.md §2:** add `.brownfield/`
- **New AGENTS.md §11.5 Brownfield Workflow:** document scan/bootstrap/suggest/verify, idempotency contract, mechanical/judgment boundary

**Failure modes:**
- Deleted applied.log → re-run. Mitigation: migrations idempotent-in-effect too (field-present-skip).
- Different hashes for "same" migration when page list changes → CORRECT; new migration is genuinely different.

**v1.0 primitives reused:** bash+inline-python3, sha256 (already used for `content_hash`), append-only log.

**Build order:** Alongside Decision 4. `suggest` after `scan`+`bootstrap`; `verify` last.

---

## Decision 6: PR lint gate — `--format=json|text` flag, JSON for CI

**Recommendation:** Add `--format <text|json>` to `bin/lint.sh` (default `text`). JSON output: array `{severity, category, path, line?, message}` matching existing `add_finding()` tuple. New `.github/workflows/lint.yml` runs `bin/lint.sh --format json` + annotation shim emitting `::error file=...,line=...::`.

**Lints adjusted for PR-friendliness:**
- **`drift-external` (DRFT-03):** needs local Zotero/Obsidian state. Add `--skip-category drift-external`; CI uses it.
- **`stale`:** downgrade to warning in CI mode.
- **`gap`:** warnings only, not blockers.
- **`contradiction`:** keep as error.
- **`yaml`, `orphan`, `crossref`, `provenance`:** keep as blockers.

**Integration points:**
- **Modified bin/lint.sh:** `--format`, `--ci`, `--skip-category` flags; JSON mode; severity-by-category policy table
- **New file:** `.github/workflows/lint.yml`
- **New file:** `.github/PULL_REQUEST_TEMPLATE.md`
- **Modified AGENTS.md §11.3:** new "CI mode" subsection
- **Modified AGENTS.md §15:** Git/GitHub integration note

**Failure modes:**
- Non-GitHub hosts — JSON output platform-neutral; only YAML workflow is GitHub-specific. Document in `/docs/reference/ci.md`.
- Lint rule changes break PRs — version lint (`bin/lint.sh --version`), allow pinning.
- Noisy gap warnings — default inline annotations error-only.

**v1.0 primitives reused:** entire lint framework (Phase 5), severity tiering, category groupings, `add_finding()`.

**Build order:** After Decisions 4+5 (shares severity-policy table).

---

## Decision 7: Four-track `/docs/` — flat files, AGENTS.md stays at repo root

**Recommendation:** `/docs/` flat with four files + `/docs/reference/` subdirectory. **AGENTS.md stays at repo root.**

```
/
├── AGENTS.md                       (operator schema — unchanged)
├── CLAUDE.md                       (symlink or duplicate — agent-agnostic)
├── README.md                       (pitch + link to docs/quickstart.md)
├── docs/
│   ├── quickstart.md               (5-minute clone-and-ingest)
│   ├── guided-setup.md             (wizard walkthrough)
│   ├── manual-setup.md             (hand-edit track)
│   └── reference/
│       ├── index.md
│       ├── schema-tour.md          (human intro to AGENTS.md)
│       ├── brownfield.md           (brownfield.sh user guide)
│       ├── privacy-model.md        (fail-closed semantics)
│       ├── ci.md                   (PR workflow + lint gate)
│       └── examples.md             (tour of examples/kahneman/)
```

**Why AGENTS.md stays at root:** every agent looks at project root (SCHM-01). AGENTS.md is operator doc; /docs/ is user doc.

**Integration points:**
- **New directory:** `docs/` + `docs/reference/`
- **New files:** 4 top-level + 6 reference docs
- **Modified README.md**
- **Unchanged:** AGENTS.md location, wiki/ structure, bin/ scripts

**Failure modes:**
- Confusion /docs/ vs wiki/: README makes distinction loud. /docs/ never has frontmatter.
- Four-track naming drifts from wizard UI: wizard uses exact filenames.
- Reference duplicates AGENTS.md and drifts: link by anchor, don't restate.

**v1.0 primitives reused:** repo-root schema convention, markdown-only docs, Obsidian-compatible markdown.

**Build order:** Last in v1.1. Exception: `docs/quickstart.md` placeholder can ship first.

---

## Cross-Cutting: Build Order Summary

| Order | Feature | Rationale | Depends on |
|-------|---------|-----------|------------|
| 1 | **Decision 2** — Kahneman → examples/ | All features reference starter vault state | Nothing |
| 2 | **Decision 1** — AGENTS.md template + wizard | Template authored against Kahneman-free baseline | Decision 2 |
| 3 | **Decision 4** — Brownfield sentinels + lint relaxation | New field + severity mechanism reused in 6 | Shares lint changes with 6 |
| 4 | **Decision 5** — Brownfield idempotency | Needs Decision 4's field conventions | Decision 4 |
| 5 | **Decision 6** — PR lint gate | Builds on severity-policy from Decision 4 | Decision 4 |
| 6 | **Decision 3** — `contributor::` in log.md | Only meaningful once PR workflow exists | Decision 6 |
| 7 | **Decision 7** — `/docs/` four-track | Docs written against stable features | Decisions 1–6 |

---

## Cross-Cutting: AGENTS.md Edit Map

| Section | Change | Driven By |
|---------|--------|-----------|
| §1 Overview | `/docs/` is user-facing companion | Decision 7 |
| §2 Directory Structure | Add `examples/`, `.brownfield/`, `docs/` | Decisions 2, 5, 7 |
| §3 Navigation | AGENTS.md is a rendered template | Decision 1 |
| §5 Frontmatter | New optional `example`, `bootstrap_stage` fields | Decisions 2, 4 |
| §6 Provenance/Epistemics | No change | Decision 3 |
| §11.1 Ingest | `bin/ingest.sh --contributor` flag | Decision 3 |
| §11.3 Lint | New CI-mode subsection, severity policy, JSON output | Decision 6 |
| §11.5 Brownfield (NEW) | Full scan/bootstrap/suggest/verify workflow | Decisions 4, 5 |
| §12 Index and Log | `contributor::` optional field | Decision 3 |
| §15 Tooling | Git/GitHub PR workflow integration | Decision 6 |
| §16 Appendices | Replace Kahneman Dataview examples | Decision 2 |

---

## Cross-Cutting: New Frontmatter Fields

| Field | Values | Required? | Owner | Introduced By |
|-------|--------|-----------|-------|---------------|
| `example` | boolean | optional (default false) | example pages | Decision 2 |
| `bootstrap_stage` | enum `raw\|bootstrapped\|verified` | optional | brownfield workflow | Decision 4 |

Both **additive**. No existing field semantics change.

---

## Cross-Cutting: New CLI / Flags

| Script/Flag | Purpose | Decision |
|-------------|---------|----------|
| `bin/init-wizard.sh` (NEW) | Interactive template rendering → personalized AGENTS.md | 1 |
| `bin/init-wizard.sh --upgrade` | Re-render on schema version bump | 1 |
| `bin/brownfield.sh scan\|bootstrap\|suggest\|verify` (NEW) | Brownfield vault onboarding | 4, 5 |
| `bin/ingest.sh --contributor <handle>` | PR-author attribution in log.md | 3 |
| `bin/lint.sh --format json` | CI-consumable output | 6 |
| `bin/lint.sh --ci` | Severity-downgrade policy | 6 |
| `bin/lint.sh --skip-category drift-external` | Skip cross-tool drift in CI | 6 |

---

## Confidence & Gaps

**HIGH confidence:**
- Frontmatter extensibility pattern — precedent from Phase 5.
- Lint severity/category mechanism.
- Log.md inline field compatibility.
- AGENTS.md at root for agent-agnosticism.

**MEDIUM confidence:**
- Placeholder vs layered override (Decision 1) — worth a decision record.
- Flat vs nested `/docs/`.
- Applied-log vs checksumming for brownfield idempotency.

**LOW confidence / gaps:**
- `bin/init-wizard.sh --upgrade` 3-way merge mechanism — needs spike.
- `.obsidianignore` vs separate vault for examples/ — needs Obsidian verification (v1.0 revisit flag).
- Multi-agent validation (Codex) against v1.1 workflows — gate on Decision 1.
