# Phase 8: Two-Track Setup (Wizard + Manual) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-16
**Phase:** 08-two-track-setup-wizard-manual
**Areas discussed:** Placeholder reconciliation, Idempotency & re-run, Manual track & byte-equality, Prompt design & values, Validation & pre-flight UX, Diff/summary output, Initial decision record

---

## Area 2 — Placeholder Reconciliation

### Q2.1 — `{{USER_NAME}}` in AGENTS.md template?

| Option | Description | Selected |
|--------|-------------|----------|
| A | Stay at 4 placeholders; user name lives in `.wizard-answers.yaml` + decision record only | ✓ |
| B | Add `{{USER_NAME}}` back as 5th placeholder (maintained-by byline in AGENTS.md) | |
| C | Make `{{USER_NAME}}` optional — conditional rendering | |

**User's choice:** A
**Notes:** AGENTS.md should stay a neutral operating spec, not a personalized byline document. `{{EXAMPLE_CLUSTER_REF}}` remains settled (rejected in Phase 7 D-08).

### Q2.2 — REQUIREMENTS.md amendment path

| Option | Description | Selected |
|--------|-------------|----------|
| A | Amend WZRD-07 text; note rationale in Phase 8 decision record | ✓ |
| B | Leave WZRD-07 as-is; document deviation in CONTEXT.md + VERIFICATION.md | |

**User's choice:** A
**Notes:** Keep REQUIREMENTS.md as source of truth.

---

## Area 3 — Idempotency & Re-run Detection

### Q3.1 — Initialization detection mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| A | `.wizard-answers.yaml` presence only | |
| B | Placeholder-free AGENTS.md | |
| C | Both must agree | |
| D | `.wizard-answers.yaml` primary + AGENTS.md existence sanity check; warn on "manual-looking" repos without answers file | ✓ |

**User's choice:** D
**Notes:** `.wizard-answers.yaml` is wizard-owned and unambiguous. Manual-track rendered AGENTS.md without answers file is a real case and should warn rather than overwrite.

### Q3.2 — Action on initialized repo

| Option | Description | Selected |
|--------|-------------|----------|
| A | Refuse with clear non-zero exit message | ✓ |
| B | Silent no-op with single-line status | |
| C | Refuse by default + `--force` flag with confirmation | |

**User's choice:** A
**Notes:** No silent no-op. `--force` is the start of an upgrade/reset flow — deferred with `--upgrade` to v1.2. Matches Phase 7's safety posture.

### Q3.3 — `--dry-run` interaction with initialized repo

| Option | Description | Selected |
|--------|-------------|----------|
| A | `--dry-run` always renders regardless of init state (pure preview) | ✓ |
| B | `--dry-run` still refuses on initialized repo | |

**User's choice:** A
**Notes:** `--dry-run` is a preview tool, not a mutation; blocking it provides no safety value and loses debugging utility for the manual track.

---

## Area 4 — Manual Track Structure & Byte-Equality Test

### Q4.1 — `docs/manual-setup.md` structure

| Option | Description | Selected |
|--------|-------------|----------|
| A | Prompt-ordered: 6 numbered sections mirroring wizard prompts + checklist + equivalence + file-touch list | ✓ |
| B | File-oriented: edits grouped by target file with cross-reference table | |
| C | Hybrid — prompt-ordered walkthrough + file-grouped appendix | |

**User's choice:** A
**Notes:** Isomorphism is the whole point of the two-track promise; prompt-ordered makes it explicit and auditable.

### Q4.2 — Canonical-answers fixture location

| Option | Description | Selected |
|--------|-------------|----------|
| A | `schema/fixtures/canonical-answers.yaml` (colocated with template) | ✓ |
| B | `tests/fixtures/canonical-answers.yaml` (new top-level tests tree) | |
| C | `.github/fixtures/canonical-answers.yaml` (CI-adjacent) | |

**User's choice:** A
**Notes:** Colocation with the template it drives; one obvious home.

### Q4.3 — Byte-equality test mechanics (MANUAL-06)

| Option | Description | Selected |
|--------|-------------|----------|
| A | Fixture-driven: commit canonical-AGENTS.md; CI renders via `--answers-file` and diffs | ✓ |
| B | Doctest-driven: parse manual-setup.md snippets, apply to template, compare | |
| C | Triple-check: wizard vs. committed vs. doc-extracted | |

**User's choice:** A
**Notes:** Deterministic and low-complexity. No CI-to-documentation parsing coupling in v1.1.

### Q4.4 — Minimal-diff example domain (MANUAL-02)

| Option | Description | Selected |
|--------|-------------|----------|
| A | Neutral `personal-knowledge` domain (PROJECT.md's first domain) | ✓ |
| B | Reuse Kahneman | |
| C | Generic placeholder like `my-domain` | |

**User's choice:** A
**Notes:** Aligns with PROJECT.md intended first-use case; avoids regressing Phase 7's Kahneman neutralization (NEUT-02/03).

---

## Area 1 — Prompt Design & Allowed Values

### Q1.1 — Primary domain → `{{PRIMARY_DOMAIN}}`

| Option | Description | Selected |
|--------|-------------|----------|
| A | Free-form validated (`^[a-z0-9-]+$`), default `personal-knowledge` | ✓ |
| B | Free-form, no default | |
| C | Pick-list of common domains + "other" | |

**User's choice:** A

### Q1.2 — LLM agent → `{{AGENT_FILENAME}}`

| Option | Description | Selected |
|--------|-------------|----------|
| A | `{claude-code, codex, other}` → self-reference string; both files always written, default `claude-code` | ✓ |
| B | Broader set including cursor, aider, etc. | |
| C | Literal filename picker: `{AGENTS.md, CLAUDE.md}` | |

**User's choice:** A
**Notes:** Ask for intent, not filename. Keep both files written per Phase 7 D-03.

### Q1.3 — Privacy → `{{DEFAULT_PRIVACY}}`

| Option | Description | Selected |
|--------|-------------|----------|
| A | Three named profiles (strict/mixed/open) bundling tier + `.gitignore` + posture | |
| B | Direct schema tier: `{local_only, cloud_safe}`, default `local_only` | ✓ |
| C | Three profiles all resolving to `local_only` tier | |

**User's choice:** B
**Notes:** Three-profile abstraction doesn't correspond to bundled behavior yet; add profiles in v1.2 when they mean something. `.gitignore` stays Phase 7 D-14's concern.

### Q1.4 — Decay profile → `{{DECAY_PROFILE}}`

| Option | Description | Selected |
|--------|-------------|----------|
| A | Pick-list matching AGENTS.md §6 table, default `default` | ✓ |
| B | Auto-derive from primary domain | |
| C | Free-form | |

**User's choice:** A
**Notes:** Maps to existing decay table; doesn't hide behavior behind inference.

### Q1.5 — Obsidian browsing

| Option | Description | Selected |
|--------|-------------|----------|
| A | Single y/n prompt, default y; recorded but doesn't alter generated AGENTS.md (wikilinks/Dataview are structural) | ✓ |
| B | Two prompts: wikilinks y/n + Dataview y/n | |
| C | Skip this group entirely | |

**User's choice:** A
**Notes:** Honest about what's optional (browsing interface) vs. structural (wikilinks, YAML frontmatter).

### Q1.6 — User name capture

| Option | Description | Selected |
|--------|-------------|----------|
| A | Explicit 7th prompt at start, default from `git config user.name` | ✓ |
| B | Silent capture from `git config user.name`, no prompt | |
| C | Fold into the Obsidian group | |

**User's choice:** A
**Notes:** Honest about what's being collected and where it goes.

---

## Area 5 — Validation & Pre-flight UX

### Q5.1 — Validation posture

| Option | Description | Selected |
|--------|-------------|----------|
| A | Fail-fast per-prompt always | |
| B | Collect-all always | |
| C | Hybrid: fail-fast interactive, collect-all for `--answers-file` | ✓ |

**User's choice:** C
**Notes:** Most humane behavior in each context. Shared validator function, different invocation shape.

### Q5.2 — Pre-flight output format

| Option | Description | Selected |
|--------|-------------|----------|
| A | Terse one-liner per missing tool | |
| B | Copy-pasteable install commands per-platform inline | |
| C | Terse line + pointer to `docs/reference/setup-prerequisites.md` | ✓ |

**User's choice:** C
**Notes:** Keep wizard terse; centralize platform matrix in a doc (easier to maintain).

### Q5.3 — Invalid-input error shape

| Option | Description | Selected |
|--------|-------------|----------|
| A | Rule + concrete fix example | ✓ |
| B | Rule only (expects regex literacy) | |
| C | Example only (friendly but imprecise) | |

**User's choice:** A

### Q5.4 — Pre-flight timing

| Option | Description | Selected |
|--------|-------------|----------|
| A | Before any prompting (WZRD-09's "before touching anything") | ✓ |
| B | Just before file writes | |

**User's choice:** A

---

## Area 6 — Diff / Summary Output Format

### Q6.1 — `--dry-run` format

| Option | Description | Selected |
|--------|-------------|----------|
| A | Unified diff (diff -u style) | ✓ |
| B | Side-by-side diff | |
| C | Human summary only | |

**User's choice:** A

### Q6.2 — Completion summary after real run (WZRD-08)

| Option | Description | Selected |
|--------|-------------|----------|
| A | File-list with path, size, short status + next-step hint | ✓ |
| B | Unified diff of every file written | |
| C | Summary + `--verbose` for diffs | |

**User's choice:** A

### Q6.3 — Color/TTY handling

| Option | Description | Selected |
|--------|-------------|----------|
| A | Auto-detect TTY + respect `NO_COLOR` | ✓ |
| B | Always plain | |
| C | Always colorized + `--no-color` flag | |

**User's choice:** A

### Q6.4 — Diff engine

| Option | Description | Selected |
|--------|-------------|----------|
| A | Shell out to `diff -u` | |
| B | Python `difflib.unified_diff` | ✓ |
| C | Pure bash implementation | |

**User's choice:** B
**Notes:** python3 already allowed in STACK.md; difflib gives deterministic cross-platform output. Avoids BSD/GNU `diff` quirks on mixed environments — matters for a shareable template.

### Q6.5 — Next-step hint in summary

| Option | Description | Selected |
|--------|-------------|----------|
| A | Yes — single line pointing at `bin/ingest.sh` | ✓ |
| B | No — purely factual | |

**User's choice:** A

---

## Area 7 — Initial Decision Record (WZRD-10)

### Q7.1 — File path & naming

| Option | Description | Selected |
|--------|-------------|----------|
| A | `wiki/decisions/dr-YYYY-MM-DD-initial-setup.md` | ✓ |
| B | `wiki/decisions/dr-YYYY-MM-DD-wizard-bootstrap.md` | |

**User's choice:** A

### Q7.2 — `trigger_type` enum value

| Option | Description | Selected |
|--------|-------------|----------|
| A | `schema-update` (closest existing value) | |
| B | Extend enum with new `bootstrap` value | |
| C | `schema-update` for v1.1; revisit if pattern emerges | ✓ |

**User's choice:** C
**Notes:** YAGNI — one record of this class exists per repo.

### Q7.3 — `affected_pages`

| Option | Description | Selected |
|--------|-------------|----------|
| A | Empty list `[]` (inaugural/infrastructure per §4.6) | ✓ |
| B | List AGENTS.md / CLAUDE.md | |

**User's choice:** A
**Notes:** AGENTS.md/CLAUDE.md aren't wiki pages.

### Q7.4 — Body content

| Option | Description | Selected |
|--------|-------------|----------|
| A | Wizard-generated from deterministic template; all 7 sections filled via substitution | ✓ |
| B | Skeleton + TODO placeholders | |
| C | Single-section record | |

**User's choice:** A
**Notes:** No LLM-in-wizard (rejected per research anti-features).

### Q7.5 — Captured metadata

| Option | Description | Selected |
|--------|-------------|----------|
| A | 6 answers + wizard version + ISO timestamp + template git SHA | ✓ |
| B | 6 answers + timestamp only | |
| C | 6 answers only | |

**User's choice:** A

### Q7.6 — Relationship to `.wizard-answers.yaml`

| Option | Description | Selected |
|--------|-------------|----------|
| A | `.wizard-answers.yaml` is machine-authoritative; record narrates + links in Sources | ✓ |
| B | Both carry full answer set verbatim | |

**User's choice:** A

---

## Claude's Discretion

- Exact wording of the four semantic-group one-sentence explainers (D-13)
- Prompt prompt-text strings, spacing, status formatting
- Exit code numbers beyond 0/non-zero
- `.wizard-answers.yaml` key naming and ordering (snake_case per AGENTS.md §3)
- Whether `--answers-file` reads via python3 inline or a small bash parser
- Layout of `docs/reference/setup-prerequisites.md`
- Pre-flight check placement (inline vs. shared helper)

## Deferred Ideas

See CONTEXT.md `<deferred>` section: `--upgrade`, `--force`, named privacy profiles, `bootstrap` enum extension, multi-domain presets, GUI wizard, LLM-in-wizard, network-dependent behavior, doc-parsing byte-equality test, prerequisite-install automation.
