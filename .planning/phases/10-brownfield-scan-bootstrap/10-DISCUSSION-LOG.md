# Phase 10: Brownfield Scan + Bootstrap - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-17
**Phase:** 10-brownfield-scan-bootstrap
**Areas discussed:** YAML safety + backup posture, Dry-run vs apply default, Sentinel shape, Scan classification + confidence, AGENTS.md §5 wording, bin/ingest.sh strip, docs/reference/brownfield.md scope

---

## Gray-Area Selection

| Option | Description | Selected |
|--------|-------------|----------|
| YAML safety + backup posture | Unparseable frontmatter handling, key-collision policy, loss-protection depth | ✓ |
| Dry-run vs apply default | Bootstrap default posture; dry-run output shape; re-run semantics; write-failure handling | ✓ |
| Sentinel shape | Minimal vs content-hash-augmented sentinel; age tracking; empty-value scaffolding set; source hashing scope | ✓ |
| Scan classification + confidence | Rule-set depth; confidence signal shape; unknown framing; Obsidian-quirk exclusions | ✓ |

**User's choice:** All 4 selected for discussion.

---

## Area 1 — YAML safety + backup posture

### Q1: On unparseable frontmatter, what's bootstrap's behavior?

| Option | Description | Selected |
|--------|-------------|----------|
| Skip + log to SKIPPED.md (Recommended) | Pre-flight yaml.safe_load; append to .brownfield/SKIPPED.md; bootstrap continues on parseable files | ✓ |
| Abort entire run on first parse failure | Single bad file halts bootstrap; user fixes and re-runs | |
| Attempt mechanical repair | Regex-normalize tabs/quotes/BOM; research rejects this | |

**User's choice:** 1. Skip + log to SKIPPED.md.
**Notes:** Preserves mechanical-first boundary; re-runnable after user fixes bad files. Pre-flight parse gate; do not mutate on failure; append structured entry (path + parse error); continue. End-of-run summary: parsed / bootstrapped / skipped / next-action-review. No mechanical YAML repair.

### Q2: Key-collision policy on parseable frontmatter?

| Option | Description | Selected |
|--------|-------------|----------|
| Skip file + report (Recommended) | Refuse to touch any page with sentinel-injection key collision; log to REPORT.md | |
| Merge: preserve user's value, inject sentinel only where absent | Existing value wins; sentinel added only for missing keys | |
| Overwrite: sentinel fields win | Bootstrap replaces user values; destroys work | |
| Typed merge policy (user-authored reframe) | Three field classes: A safe-additive, B schema-authoritative, C structural hard failure | ✓ |

**User's choice:** Typed merge policy — the user explicitly rejected the crude global skip-only recommendation and authored a three-class field taxonomy:
- **Class A — safe-additive** (tags, aliases, sources, simple-scalar status): preserve existing value, inject sentinel only where absent.
- **Class B — schema-authoritative** (type, epistemic_status, knowledge_domain, privacy, bootstrap_stage): preserve existing, NEVER overwrite, log to REPORT.md as warning when missing/malformed/noncanonical (suggest/lint's job, not bootstrap's).
- **Class C — structural hard failure** (unparseable YAML, non-mapping frontmatter, detectable duplicate keys, intent-guessing required): skip → SKIPPED.md.

**Decision boundary (user-authored):** *"Skip on parse failure or unsafe structure; merge on parseable metadata; warn whenever preserved values may not satisfy the schema."*

**Notes:** User explicitly offered to help rewrite BRWN-04/BRWN-08/Phase 10 success-criterion 2 wording to reflect the typed-merge policy (BRWN-04's "mechanical transforms only" framing no longer captures the policy).

REPORT.md has four sections: bootstrapped-success / bootstrapped-with-preserved-collisions / bootstrapped-with-schema-warnings / skipped-due-to-parse-failure.

### Q3: Loss-protection mechanism for bootstrap --apply?

| Option | Description | Selected |
|--------|-------------|----------|
| Git is the backup + APPLIED.md manifest (Recommended) | Bootstrap writes .brownfield/APPLIED.md; git reset --hard <sha> as canonical undo | ✓ |
| .brownfield/backups/<path>.orig on by default | Per-file .orig copies; --no-backup opt-out | |
| Both: manifest default + --backup opt-in | Manifest always; .orig behind explicit flag | |
| No backup layer (--dry-run default is the safety) | Trust dry-run + git; no manifest, no backups | |

**User's choice:** 1. Git is the backup + APPLIED.md manifest.
**Notes:** Repo already assumes git; git stays canonical undo path. APPLIED.md gives precise audit trail. No .orig duplication (would create two recovery procedures that can drift). "Dry-run alone is not enough once --apply exists — manifest gives precise audit trail."

### Q4: Byte-exact fixture suite depth for BRWN-21 CI test?

| Option | Description | Selected |
|--------|-------------|----------|
| Standard: 6 fixtures (Recommended) | clean + no-frontmatter + tabs + CRLF + Dataview-inline + frontmatter-with-comments | ✓ |
| Minimal: 2 fixtures | Happy paths only; defer weird-YAML coverage until bug reports | |
| Exhaustive: 10+ fixtures | Standard + BOM + multi-doc + empty-valid + mixed-indent + numerics + UTF-8 | |
| Start minimal, grow on bug reports | 2 fixtures; add one per observed failure | |

**User's choice:** 1. Standard: 6 fixtures.
**Notes:** Right confidence/maintenance tradeoff for v1.1. CRITICAL NUANCE: golden fixture contract must cover BOTH byte-exact transformed-output fixtures AND byte-exact skip/report-artifact fixtures. tabs-in-yaml (if ruamel.yaml treats it as unparseable) should validate SKIPPED.md entry + unmodified file, not a transformed file.

---

## Area 2 — Dry-run vs apply default

### Q1: Default posture for bootstrap?

| Option | Description | Selected |
|--------|-------------|----------|
| Dry-run by default, --apply required to write (Recommended) | Matches bin/release.sh Phase 7 precedent | ✓ |
| Writes by default, --dry-run flag to preview | Fewer keystrokes; foot-gun for first-run users | |
| Tiered: scan always dry-run, bootstrap dry-run default, bootstrap --apply writes, bootstrap --apply --assume-yes | Richer safety gradient; more flags | |

**User's choice:** 1. Dry-run by default, --apply required.
**Notes:** Exploration should be safe; writing should require explicit intent. Brownfield tooling is exactly where accidental writes are most costly. No extra --assume-yes complexity until automation needs it.

### Q2: What does dry-run output look like?

| Option | Description | Selected |
|--------|-------------|----------|
| Unified diff per file + aggregated summary (Recommended) | diff -u per touched file + counts | |
| Aggregate counts + .brownfield/REPORT.md preview only | No per-file diff in stdout | |
| Both modes via --verbose | Summary default; --verbose shows full diffs | ✓ |

**User's choice:** 3. Both modes via --verbose.
**Notes:** User reframed — diffs matter but would be too noisy for large vaults by default. Best UX: default = aggregated summary + clear pointer to REPORT.md; --verbose adds unified diffs per touched file.

### Q3: --apply re-run semantics when .brownfield/APPLIED.md already exists?

| Option | Description | Selected |
|--------|-------------|----------|
| Idempotent re-run: per-file state-check via bootstrap_stage (Recommended) | Skip bootstrapped files silently; append new timestamped APPLIED.md block; zero-byte diff on clean re-run | ✓ |
| Hard abort with "--force-reapply to override" | Explicit intent; breaks BRWN-03 "running twice is a no-op" | |
| Overwrite APPLIED.md silently, re-run the pass | No ceremony; loses audit trail for prior runs | |

**User's choice:** 1. Idempotent re-run.
**Notes:** Matches BRWN-03 requirement directly. Skip already-bootstrapped files; append new run block to APPLIED.md; zero-byte diff on clean re-run.

### Q4: Write-failure mid-apply semantics?

| Option | Description | Selected |
|--------|-------------|----------|
| Halt + report + leave 1..N-1 mutated + partial APPLIED.md (Recommended) | Honest outcome; user chooses git-reset vs fix-and-rerun | ✓ |
| Halt + git-reset-to-HEAD rollback of files 1..N-1 | Bootstrap owns rollback; requires clean git tree precondition | |
| Continue-on-error: log failure, attempt remaining, aggregate errors | Best-coverage; noisy for escalating failure modes | |

**User's choice:** 1. Halt + report + partial APPLIED.md.
**Notes:** Most honest; avoids auto-rollback in dirty working tree; preserves recoverability through git + idempotent re-run. Continue-on-error too noisy for failures like disk full or permission issues.

---

## Area 3 — Sentinel shape

### Q1: Sentinel payload — minimal vs hash-augmented?

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal: bootstrap_stage: bootstrapped alone (Recommended) | Presence = bootstrapped; consistent with BRWN-07 narrow-scope | ✓ |
| Hash-augmented: bootstrap_stage + bootstrap_sentinel: gsd-v1:<sha8> | Hash over original body; detects hand-edits since import | |
| Hash-only: bootstrap_sentinel: gsd-v1:<sha8> | Single field; loses human-readable stage enum | |

**User's choice:** 1. Minimal.
**Notes:** bootstrap_stage is the actual state Phase 10 needs. Hash-augmenting introduces complexity this phase does not use. Enough machinery already exists through git, APPLIED.md, lint, and per-file idempotency.

### Q2: BRWN-09 "30-day stale" measurement?

| Option | Description | Selected |
|--------|-------------|----------|
| New bootstrap_date: YYYY-MM-DD field (Recommended) | Deterministic; survives shallow clones | ✓ |
| Reuse updated_at | No new field; drifts on every wiki edit | |
| git log for oldest commit touching the file | No frontmatter field; unreliable with shallow clones | |
| Encode into APPLIED.md, read on lint | Cross-file dependency; breaks if .brownfield/ deleted | |

**User's choice:** 1. New bootstrap_date.
**Notes:** updated_at is semantically wrong for "when was this bootstrapped". git history is unreliable. APPLIED.md is not a good canonical source for page-local lifecycle state. Add bootstrap_date; keep it explicit and local to the page.

### Q3: Empty-value sentinel field set for no-frontmatter pages?

| Option | Description | Selected |
|--------|-------------|----------|
| AGENTS.md §5 base-fields set, empty/default, minus inferrable (Recommended) | Rich scaffolding; ids/titles/timestamps inferred; semantic fields empty | ✓ |
| Minimum-survival set only | Just type, privacy, bootstrap_stage, bootstrap_date; rely on suggest for rest | |
| Full set with tool-authored defaults where plausible | Option 1 + knowledge_domain: "imported" (polluting) | |

**User's choice:** 1. Base-fields set, empty/default, minus inferrable.
**Notes:** Scaffolding, not interpretation. Inferred values (id, title, created_at) are fine. Semantic fields stay conservative: type:"", summary:"", knowledge_domain:"", sources:[], epistemic_status:tentative. Explicitly rejected knowledge_domain:"imported" — migration-state concept, would pollute decay model.

### Q4: bootstrap's treatment of raw sources/ files (SHA hashing scope)?

| Option | Description | Selected |
|--------|-------------|----------|
| Update content_hash only on existing wiki/sources/*.md (Recommended) | Strict mechanical boundary; orphans logged for Phase 11 | ✓ |
| Bootstrap creates minimal source-summary scaffolds for orphans | Mechanical mapping; saves suggest round-trip; dilutes scaffolding-only promise | |
| Bootstrap hashes every .md regardless of type | Simplest; creates schema-invalid frontmatter | |

**User's choice:** 1. Update content_hash only on existing source-summary pages.
**Notes:** Bootstrap should not start creating new wiki pages for orphan sources. Even mechanical mapping crosses from scaffolding into content-layer intervention. Logging orphans as "needs summary" is the right handoff to Phase 11 suggest/01-page-typing.sh. Hash only where the field already belongs; log unmatched raw sources.

---

## Area 4 — Scan classification + confidence

### Q1: Classification rule-set depth?

| Option | Description | Selected |
|--------|-------------|----------|
| Standard: frontmatter + filename + H1 + link density (Recommended) | Four deterministic signals; reusable by 01-page-typing.sh | ✓ |
| Minimal: frontmatter-only | Fast but most pages end up unknown | |
| Heuristic-rich: standard + body-text patterns + corpus stats | Higher accuracy, more rules to maintain/test | |

**User's choice:** 1. Standard: 4 signals.
**Notes:** Frontmatter-only too weak for real brownfield vaults; heuristic-rich too much rule surface for v1.1. Four signals: deterministic, explainable, reusable by 01-page-typing.sh, strong enough to generate a useful report. "Actually informative without turning into a mini classifier project."

### Q2: Confidence signal shape in REPORT.md?

| Option | Description | Selected |
|--------|-------------|----------|
| Categorical: high/medium/low/unknown (Recommended) | Four tiers; human-readable | |
| Numeric: 0.0-1.0 | Finer-grained; over-interpretable | |
| Rule-trace: list matched signals | Fully transparent; no summary label | |
| Categorical + rule-trace | Category label + expandable trace | ✓ |

**User's choice:** 4. Categorical + rule-trace.
**Notes:** Category label good for readability; rule trace makes result trustworthy and reviewable. Best signal density is confidence: high|medium|low|unknown + short trace like `signals: frontmatter=none, filename=pascalcase, h1=entity-like, links=outbound-heavy`.

### Q3: unknown page framing in REPORT.md?

| Option | Description | Selected |
|--------|-------------|----------|
| One-line reason per unknown, phrased as open question (Recommended) | Matches BRWN-02; encourages user judgment | ✓ |
| Structured reason + machine-readable suggestions | Pre-fills suggestions; anchors user judgment | |
| Grouped by failure mode | Batch triage; less per-page prose | |

**User's choice:** 1. One-line open-question prose.
**Notes:** Matches requirement; keeps tone helpful instead of overconfident; encourages user judgment where tool is genuinely uncertain. Frame unknowns as open questions.

### Q4: Obsidian-quirk exclusions?

| Option | Description | Selected |
|--------|-------------|----------|
| Built-in denylist by default + .brownfield-ignore override (Recommended) | Sensible defaults + user override | ✓ |
| Include everything, classify quirks as unknown | Comprehensive; user wades through noise | |
| .brownfield-ignore only (no built-in denylist) | Maximum conservative; heavy onboarding cost | |
| Built-in denylist, not user-configurable in v1.1 | Hardcoded; defer config file to v1.2 | |

**User's choice:** 1. Built-in denylist + .brownfield-ignore override.
**Notes:** Built-in exclusions necessary for sane out-of-the-box behavior. Real vault layouts vary; user override worth it for brownfield onboarding. Pure built-in too rigid; include-everything too noisy; .brownfield-ignore-only too much friction. Ship default denylist + allow user overrides + report excluded counts (not full exclusion spam).

---

## Follow-up Area 5 — AGENTS.md §5 `bootstrap_stage` wording scope

### Q1: Where does bootstrap_stage documentation live?

| Option | Description | Selected |
|--------|-------------|----------|
| Inline row in §5 field-descriptions table (Recommended) | One row; matches example: true Phase 7 pattern | ✓ |
| Dedicated §5 subsection | Full paragraph; §5 length growth | |
| Both: row + pointer sentence above table | Extra call-out; forward-ref drift risk | |

**User's choice:** 1. Inline row.

---

## Follow-up Area 6 — bin/ingest.sh strip behavior (BRWN-10)

### Q2: When ingest encounters a page with bootstrap_stage?

| Option | Description | Selected |
|--------|-------------|----------|
| Strip + one-line stderr warning (Recommended) | Silent-but-observable; matches Phase 9 miss-warn precedent | ✓ |
| Silent strip | No signal; opaque | |
| Refuse to ingest | Forces explicit promotion; breaks "ingest just works" | |

**User's choice:** 1. Strip + stderr warn.

---

## Follow-up Area 7 — docs/reference/brownfield.md content scope

### Q3: What does Phase 10 ship in docs/reference/brownfield.md?

| Option | Description | Selected |
|--------|-------------|----------|
| Scan + bootstrap complete; suggest + verify stubbed (Recommended) | Matches Phase 7→9 ci.md precedent | ✓ |
| Full runbook all four subcommands, marked "pending" where applicable | Forward-refs drift | |
| Phase 10 only; Phase 11 owns its own sections | Cleanest authorship; TOC churn at Phase 11 | |

**User's choice:** 1. Scan + bootstrap complete; suggest + verify stubbed.

---

## Claude's Discretion

- Exact bash flag parsing for `bin/brownfield.sh` subcommands (mirror existing conventions).
- Internal Python module structure for ruamel.yaml round-trip + classifier (inline heredoc vs extracted helper).
- Exact `.brownfield-ignore` parser scope (gitignore-grammar subset).
- Stdout color/styling (TTY / NO_COLOR).
- Exact lint downgrade mechanism (per-page auto-detect — recommended).
- Plan count and wave structure (likely 3 plans).
- Classification rule-module location (inline vs `bin/lib/brownfield_classify.py`).
- Error-message wording.

## Deferred Ideas

- `bin/brownfield.sh suggest` + `verify` (→ Phase 11).
- AGENTS.md §11.5 full populate (→ Phase 11).
- `bin/brownfield.sh apply` chain-runner (→ v1.2 BRWNAPPLY-01).
- Interactive review UI (→ v1.2 BRWNAPPLY-02).
- Content-hash sentinel (research C-3; deferred per minimalism).
- `.brownfield/backups/<path>.orig` per-file copies (deferred; git is backup).
- `knowledge_domain: imported` bucket (rejected; pollutes decay model).
- Source-summary page scaffolding during bootstrap (deferred per D-15).
- `--assume-yes` / `--force` flags.
- Config-file alternative to `.brownfield-ignore`.
- LLM-driven classification (explicit anti-feature).
- Introspection subcommands (`brownfield status` / `brownfield list`).
- Multi-vault brownfield.
- REQUIREMENTS.md BRWN-04 / BRWN-08 / success-criterion 2 wording amendment (flagged as pre-plan action item; user offered to help draft).
