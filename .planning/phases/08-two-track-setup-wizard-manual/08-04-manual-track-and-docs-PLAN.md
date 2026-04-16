---
phase: 08-two-track-setup-wizard-manual
plan: 04
type: execute
wave: 2
depends_on:
  - 08-01-test-harness-and-fixtures-PLAN.md
files_modified:
  - docs/manual-setup.md
  - docs/guided-setup.md
  - docs/quickstart.md
  - docs/reference/setup-prerequisites.md
  - .planning/REQUIREMENTS.md
  - tests/phase-08/test_manual_setup_sections.sh
  - tests/phase-08/test_manual_setup_example.sh
  - tests/phase-08/test_manual_setup_checklist.sh
  - tests/phase-08/test_manual_setup_equivalence.sh
  - tests/phase-08/test_manual_setup_file_list.sh
  - tests/phase-08/test_manual_setup_copy_not_edit.sh
  - tests/phase-08/test_manual_setup_inline_templates.sh
autonomous: true
requirements:
  - MANUAL-01
  - MANUAL-02
  - MANUAL-03
  - MANUAL-04
  - MANUAL-05
  - WZRD-07
must_haves:
  truths:
    - "docs/manual-setup.md tells users to COPY schema/AGENTS.template.md → AGENTS.md FIRST, then apply 4 placeholder substitutions IN AGENTS.md — NEVER edit the template in place (review concern #3)"
    - "docs/manual-setup.md walks 6 prompt-ordered sections per D-07: each with (i) wizard's question, (ii) file/line to edit IN AGENTS.md (NOT in schema/AGENTS.template.md), (iii) inline minimal diff, (iv) example value"
    - "docs/manual-setup.md Section 8 includes a SELF-CONTAINED, DETERMINISTIC decision-record template as a here-doc block that a hand-editor can `cat > wiki/decisions/dr-YYYY-MM-DD-initial-setup.md <<EOF ... EOF` substitute date/domain/agent/privacy/decay/maintainer/wizard_version/generated_at/template_sha values, and land at byte-parity WITHOUT invoking the wizard (review concern #4)"
    - "docs/manual-setup.md Section 8 includes the EXACT one-line wiki/index.md append snippet (not prose) — `- [[dr-YYYY-MM-DD-initial-setup|Initial Wizard Setup -- <primary_domain>]] -- Wizard-driven template personalization (wiki-infrastructure, YYYY-MM-DD)` — inlined verbatim matching Plan 03's update_index_md() output (review concern #4)"
    - "docs/manual-setup.md ends with the one-to-one wizard-prompt checklist (MANUAL-03), the equivalence statement (MANUAL-04), and the file-touch list (MANUAL-05)"
    - "Minimal-diff example (MANUAL-02) uses the neutral `personal-knowledge` domain (D-10), NOT Kahneman — preserves NEUT-02/03"
    - "docs/reference/setup-prerequisites.md is a short page covering bash >= 4 + git + python3 install commands across macOS / Debian / Ubuntu / Arch / WSL (D-16)"
    - "docs/quickstart.md and docs/guided-setup.md are populated with wizard walkthroughs (no longer Phase-7 stubs)"
    - ".planning/REQUIREMENTS.md WZRD-07 amended per D-02: states 'exactly 4 placeholders' and drops {{USER_NAME}} + {{EXAMPLE_CLUSTER_REF}}"
    - "7 doc-grep tests verify the structural commitments (sections, checklist, equivalence, file-list, example, copy-not-edit, inline templates)"
  artifacts:
    - path: docs/manual-setup.md
      provides: "Hand-edit walkthrough — copy template to AGENTS.md, 6 sections, inline decision-record & index.md templates, checklist, equivalence, file list (D-07 layout)"
      min_lines: 250
    - path: docs/guided-setup.md
      provides: "Wizard walkthrough (brief: invocation, prompts, output)"
      min_lines: 50
    - path: docs/quickstart.md
      provides: "Populated quickstart with wizard step + first-source-ingest pointer"
    - path: docs/reference/setup-prerequisites.md
      provides: "bash/git/python3 install instructions across 5 platforms"
    - path: .planning/REQUIREMENTS.md
      provides: "WZRD-07 amended to 'exactly 4 placeholders'"
      contains: "exactly 4 placeholders"
  key_links:
    - from: docs/manual-setup.md
      to: AGENTS.md
      via: "copy-from-template step (NOT edit-in-place of schema/AGENTS.template.md)"
      pattern: "cp schema/AGENTS\\.template\\.md AGENTS\\.md"
    - from: docs/manual-setup.md
      to: schema/fixtures/canonical-AGENTS.md
      via: "minimal-diff example produces this exact end state"
      pattern: "canonical-AGENTS\\.md"
    - from: docs/reference/setup-prerequisites.md
      to: docs/manual-setup.md
      via: "pre-flight error message points users at this page"
      pattern: "setup-prerequisites"
---

<objective>
Populate the manual-track docs and amend WZRD-07 per D-02. This is the human-readable counterpart to the wizard: a contributor following `docs/manual-setup.md` section-by-section MUST land at the same end state as the wizard (enforced by Plan 05's CI byte-equality test) — and MUST be able to do so WITHOUT running the wizard (review concerns #3 and #4).

Purpose: D-07 locks the doc structure (6 prompt-ordered sections + checklist + equivalence + file-touch list). Review concern #3 fixes a critical bug in the previous iteration: users were incorrectly told to hand-edit `schema/AGENTS.template.md` (the source template). Corrected flow: COPY the template to `AGENTS.md` first, then substitute IN `AGENTS.md`. The template stays pristine. Review concern #4 requires inlining deterministic decision-record and index.md templates so the manual track does not depend on wizard-generated output. MANUAL-02's minimal-diff example uses `personal-knowledge` (D-10) to avoid regressing Phase 7's NEUT-02/03.

Output: 4 docs files (manual-setup, guided-setup, quickstart, setup-prerequisites) + 7 doc-structure tests + WZRD-07 amendment in REQUIREMENTS.md.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/STATE.md
@.planning/phases/08-two-track-setup-wizard-manual/08-CONTEXT.md
@.planning/phases/08-two-track-setup-wizard-manual/08-RESEARCH.md
@.planning/phases/08-two-track-setup-wizard-manual/08-01-test-harness-and-fixtures-PLAN.md
@docs/manual-setup.md
@docs/guided-setup.md
@docs/quickstart.md
@docs/README.md
@docs/reference/index.md
@schema/AGENTS.template.md
@schema/fixtures/canonical-answers.yaml
@schema/fixtures/canonical-AGENTS.md
@.planning/REQUIREMENTS.md
@tests/phase-08/lib.sh

<interfaces>
<!-- D-07 manual-setup.md required structure, REVISED per review concerns #3 + #4 (NORMATIVE) -->

CRITICAL correction from previous iteration (review concern #3):
  The old flow said "edit schema/AGENTS.template.md line X" which would mutate the starter template.
  The corrected flow says "COPY schema/AGENTS.template.md → AGENTS.md FIRST, then edit line X IN AGENTS.md."
  The template stays pristine so subsequent `bin/init-wizard.sh --dry-run` still works and CI byte-equality
  still holds.

Section structure (revised):

0. Pre-step (NEW): `cp schema/AGENTS.template.md AGENTS.md` — establish the working file that all subsequent sections edit.
1. Intro (1 paragraph)
2. Section 1: Maintainer name (prompt 1) — recorded in .wizard-answers.yaml + decision record only
3. Section 2: Primary domain (prompt 2 → {{PRIMARY_DOMAIN}}) — file: AGENTS.md line 588; minimal diff replacing `{{PRIMARY_DOMAIN}}` with `personal-knowledge`
4. Section 3: LLM agent (prompt 3 → {{AGENT_FILENAME}}) — file: AGENTS.md line 32; minimal diff replacing with `CLAUDE.md`
5. Section 4: Privacy tier (prompt 4 → {{DEFAULT_PRIVACY}}) — file: AGENTS.md line 589; minimal diff replacing with `cloud_safe`
6. Section 5: Decay profile (prompt 5 → {{DECAY_PROFILE}}) — file: AGENTS.md line 848; minimal diff replacing with `default`
7. Section 6: Obsidian browsing (prompt 6) — recorded in .wizard-answers.yaml only
8. Section 7: Write .wizard-answers.yaml (inline heredoc)
9. Section 8: INLINE deterministic decision-record template + INLINE wiki/index.md append snippet — both self-contained, no wizard invocation required (review concern #4)
10. Section 9: Sync CLAUDE.md — `bash bin/sync-claude.sh`
11. Section 10: Wizard-prompt checklist (MANUAL-03) — 6 checkbox items
12. Section 11: Equivalence statement (MANUAL-04)
13. Section 12: File-touch list (MANUAL-05) — 5 paths
14. Section 13: Pointers

<!-- WZRD-07 amendment (NORMATIVE per D-02) -->
Current text (REQUIREMENTS.md):
> **WZRD-07**: Wizard renders from `schema/AGENTS.template.md` using named placeholders (≤6 placeholders: `{{PRIMARY_DOMAIN}}`, `{{DEFAULT_PRIVACY}}`, `{{AGENT_FILENAME}}`, `{{DECAY_PROFILE}}`, `{{EXAMPLE_CLUSTER_REF}}`, `{{USER_NAME}}`)

Amended text:
> **WZRD-07**: Wizard renders from `schema/AGENTS.template.md` using exactly 4 named placeholders: `{{PRIMARY_DOMAIN}}`, `{{DEFAULT_PRIVACY}}`, `{{AGENT_FILENAME}}`, `{{DECAY_PROFILE}}`. (Amended Phase 8 per D-02: `{{EXAMPLE_CLUSTER_REF}}` rejected; `{{USER_NAME}}` lives only in `.wizard-answers.yaml` + the initial decision record, never in AGENTS.md.)
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Write docs/manual-setup.md (REVISED: copy-template-first + inline decision-record + inline index.md); populate docs/guided-setup.md and docs/quickstart.md; create docs/reference/setup-prerequisites.md; amend WZRD-07</name>
  <files>docs/manual-setup.md, docs/guided-setup.md, docs/quickstart.md, docs/reference/setup-prerequisites.md, .planning/REQUIREMENTS.md</files>
  <read_first>
    - docs/manual-setup.md (current stub)
    - docs/guided-setup.md (current stub)
    - docs/quickstart.md (current Phase 7 D-11 stub)
    - docs/README.md (Diátaxis mapping reference)
    - schema/AGENTS.template.md lines 30-35, 55-60, 585-595, 845-850 (the 4 placeholder sites with surrounding context)
    - schema/fixtures/canonical-answers.yaml (the canonical answer set)
    - schema/fixtures/canonical-AGENTS.md (the byte-frozen target state)
    - .planning/phases/08-two-track-setup-wizard-manual/08-03-wizard-side-effects-PLAN.md (Plan 03's decision-record substitution map + update_index_md() wikilink format — manual doc MUST match exactly for byte-parity)
    - .planning/REQUIREMENTS.md lines 38–58 (current WZRD/MANUAL spec text)
    - .planning/phases/08-two-track-setup-wizard-manual/08-CONTEXT.md §Specifics (manual track exit step recipe)
    - .planning/phases/08-two-track-setup-wizard-manual/08-RESEARCH.md §Pitfall 4 (AGENT_FILENAME ambiguity — must be documented), §Pitfall 7 (.wizard-answers.yaml maintainer_name PII warning), §Code Examples Example 5 (decision record skeleton — this is what gets inlined into docs/manual-setup.md Section 8)
  </read_first>
  <action>

### 1. docs/manual-setup.md (REVISED D-07 layout — review concerns #3 + #4)

Write a complete walkthrough with exactly this structure (markdown headings exactly as shown). The content MUST match Plan 03's decision-record substitution map and update_index_md() helper output byte-for-byte so following the manual walkthrough lands at the canonical fixture.

```markdown
# Manual Setup (Hand-Edit Track)

Hand-edit your way to a personalized `AGENTS.md` without running `bin/init-wizard.sh`. The end state is byte-identical to the wizard's output — CI enforces this via `.github/workflows/setup-parity.yml` (Plan 05).

You should choose the manual track if: you want to understand exactly what the wizard does, you cannot run bash >= 4 + python3 + git locally, or you want fine-grained control over the rendered AGENTS.md before committing.

## Pre-step: Copy the Template to AGENTS.md

**Critical:** Do **NOT** hand-edit `schema/AGENTS.template.md` directly — that is the source template, shared with the wizard and CI. All substitutions below apply to your NEW `AGENTS.md` file at the repo root.

```bash
cp schema/AGENTS.template.md AGENTS.md
```

Or, if you prefer a one-shot pipeline using `sed` (equivalent to the copy-then-substitute flow):

```bash
sed \
  -e 's|{{AGENT_FILENAME}}|CLAUDE.md|g' \
  -e 's|{{PRIMARY_DOMAIN}}|personal-knowledge|g' \
  -e 's|{{DEFAULT_PRIVACY}}|cloud_safe|g' \
  -e 's|{{DECAY_PROFILE}}|default|g' \
  schema/AGENTS.template.md > AGENTS.md
```

The `sed` pipeline applies all 4 substitutions from Sections 2–5 below in a single pass. If you use it, skip Sections 2–5's minimal-diff edits (they've already happened) and jump to Section 6. If you prefer step-by-step substitutions, proceed to Section 1.

**Either way, `schema/AGENTS.template.md` stays pristine.**

## Section 1: Maintainer Name

**Wizard prompt:** `Maintainer name [Default: <git config user.name, or "unknown">]:`

**File to edit:** None (this answer is recorded in `.wizard-answers.yaml` and the initial decision record only — NOT in AGENTS.md). See Section 7 for the `.wizard-answers.yaml` write step and Section 8 for the decision record.

**Example value:** `Template Maintainer`

**Note (Pitfall 7):** `.wizard-answers.yaml` is committed and contains your maintainer name. If you want pseudonymous collaboration, edit the file before `git commit`.

## Section 2: Primary Domain

**Wizard prompt:** `Primary domain [Default: personal-knowledge]:`

**File to edit:** `AGENTS.md` line 588 (same line number as `schema/AGENTS.template.md` since AGENTS.md is a copy).

**Minimal diff (in AGENTS.md, NOT in schema/AGENTS.template.md):**
```diff
-knowledge_domain: "{{PRIMARY_DOMAIN}}"   # Primary decay-rate bucket (set by wizard from user's domain)
+knowledge_domain: "personal-knowledge"   # Primary decay-rate bucket (set by wizard from user's domain)
```

**Validation rule:** Must match `^[a-z0-9-]+$`. Example values: `personal-knowledge`, `software-engineering`, `cognitive-science`.

**Example value used in this walkthrough:** `personal-knowledge`

## Section 3: LLM Agent

**Wizard prompt:** `LLM agent [Default: claude-code] (claude-code, codex, other):`

**File to edit:** `AGENTS.md` line 32.

**Minimal diff (when agent = claude-code, in AGENTS.md):**
```diff
-This file (`{{AGENT_FILENAME}}`) is the canonical agent spec; the wizard selects `AGENTS.md` or `CLAUDE.md` per the user's agent choice.
+This file (`CLAUDE.md`) is the canonical agent spec; the wizard selects `AGENTS.md` or `CLAUDE.md` per the user's agent choice.
```

**Note (Pitfall 4):** Both `AGENTS.md` and `CLAUDE.md` are ALWAYS written byte-identical (Section 9 runs `bin/sync-claude.sh`). The `{{AGENT_FILENAME}}` placeholder controls only which filename appears in the self-reference text on line 32.

**Mapping table:**

| Wizard answer | {{AGENT_FILENAME}} substitution |
|---------------|--------------------------------|
| `claude-code` | `CLAUDE.md` |
| `codex`       | `AGENTS.md` |
| `other`       | `AGENTS.md` |

## Section 4: Privacy Tier

**Wizard prompt:** `Default privacy tier [Default: local_only] (local_only, cloud_safe):`

**File to edit:** `AGENTS.md` line 589.

**Minimal diff (in AGENTS.md, using cloud_safe to match the canonical fixture):**

> Note: this example deviates from the prompt default (`local_only` per D-11) to match the public canonical fixture `schema/fixtures/canonical-AGENTS.md`. See `schema/fixtures/README.md` for the rationale (`bin/release.sh`'s privacy-leak regex). Hand-editors targeting the canonical byte-equality check MUST use `cloud_safe` here; hand-editors personalizing for their own private repo MAY use `local_only` and accept that their AGENTS.md will differ from the canonical fixture.

```diff
-privacy_default: {{DEFAULT_PRIVACY}}     # Illustrative wizard-supplied default privacy tier (see `privacy` above for the actual enum field)
+privacy_default: cloud_safe              # Illustrative wizard-supplied default privacy tier (see `privacy` above for the actual enum field)
```

**Example value used in this walkthrough:** `cloud_safe`

## Section 5: Decay Profile

**Wizard prompt:** `Decay profile [Default: default] (software, science, biography, personal-goals, default):`

**File to edit:** `AGENTS.md` line 848.

**Minimal diff (in AGENTS.md):**
```diff
-The default staleness decay profile is `{{DECAY_PROFILE}}` (set by the wizard from the user's chosen decay profile name).
+The default staleness decay profile is `default` (set by the wizard from the user's chosen decay profile name).
```

**Reference:** See AGENTS.md §6 for the full decay-rate table. The 5 profiles map to: software (180d), science (730d), biography (1825d), personal-goals (90d), default (365d).

**Example value used in this walkthrough:** `default`

## Section 6: Obsidian Browsing

**Wizard prompt:** `Will you browse this wiki in Obsidian? [Default: y] (y/n):`

**File to edit:** None — recorded in `.wizard-answers.yaml` only and does not change AGENTS.md.

**Example value used in this walkthrough:** `true`

## Section 7: Write `.wizard-answers.yaml` (Manual Initialization Signal)

```bash
cat > .wizard-answers.yaml <<'YAML'
# Generated manually following docs/manual-setup.md on 2026-04-16T00:00:00Z
# Source of truth for the wizard answer set; powers v1.2 `--upgrade`.
wizard_version: "1.1.0"
generated_at: "2026-04-16T00:00:00Z"
template_sha: "<unresolved>"
answers:
  maintainer_name: "Template Maintainer"
  primary_domain: "personal-knowledge"
  agent: "claude-code"
  default_privacy: "cloud_safe"
  decay_profile: "default"
  obsidian: true
YAML
```

Replace the date and answer values to match your edits. For the `template_sha` field, you can resolve it via `git log -1 --format=%H schema/AGENTS.template.md` and substitute the result in place of `<unresolved>`.

## Section 8: Write the Initial Decision Record + Update wiki/index.md

Both of these are self-contained; no wizard invocation required.

### 8a. Initial decision record (deterministic template)

Substitute the 11 placeholder values (TODAY, PRIMARY_DOMAIN, AGENT, AGENT_FILENAME, DEFAULT_PRIVACY, DECAY_PROFILE, OBSIDIAN_YN, MAINTAINER_NAME, TEMPLATE_SHA, WIZARD_VERSION, GENERATED_AT) in the heredoc below. The walkthrough values (personal-knowledge / claude-code / CLAUDE.md / cloud_safe / default / y / Template Maintainer / <unresolved> / 1.1.0 / 2026-04-16T00:00:00Z) produce byte-parity with the wizard's output.

```bash
TODAY="2026-04-16"
PRIMARY_DOMAIN="personal-knowledge"
AGENT="claude-code"
AGENT_FILENAME="CLAUDE.md"
DEFAULT_PRIVACY="cloud_safe"
DECAY_PROFILE="default"
OBSIDIAN_YN="y"
MAINTAINER_NAME="Template Maintainer"
TEMPLATE_SHA="<unresolved>"
WIZARD_VERSION="1.1.0"
GENERATED_AT="2026-04-16T00:00:00Z"

mkdir -p wiki/decisions
cat > "wiki/decisions/dr-${TODAY}-initial-setup.md" <<EOF
---
id: dr-${TODAY}-initial-setup
title: "Initial Wizard Setup -- ${PRIMARY_DOMAIN}"
type: decision
status: active
summary: "Template personalization applied via manual-setup.md walkthrough. Renders from schema/AGENTS.template.md using exactly 4 placeholder substitutions."
created_at: ${TODAY}
updated_at: ${TODAY}
sources: []
epistemic_status: sourced
tags:
  - meta
  - setup
domains:
  - wiki-infrastructure
privacy: cloud_safe
knowledge_domain: software
supersedes:
superseded_by:
aliases: []
has_contradictions: false
trigger_type: schema-update
affected_pages: []
---

## TL;DR

Initial template personalization. Substituted the 4 wizard placeholders in AGENTS.md (\`{{PRIMARY_DOMAIN}}\`, \`{{AGENT_FILENAME}}\`, \`{{DEFAULT_PRIVACY}}\`, \`{{DECAY_PROFILE}}\`) against the chosen answer set. Wrote CLAUDE.md byte-identical to AGENTS.md. Recorded answers in .wizard-answers.yaml. Maintainer: ${MAINTAINER_NAME}. Wizard version: ${WIZARD_VERSION}.

## Decision

Applied manual-setup.md Sections 2–5 to render \`AGENTS.md\` from \`schema/AGENTS.template.md\` (template SHA: ${TEMPLATE_SHA}). The 4 substitutions: \`{{PRIMARY_DOMAIN}}\` → \`${PRIMARY_DOMAIN}\`, \`{{AGENT_FILENAME}}\` → \`${AGENT_FILENAME}\` (because agent = ${AGENT}), \`{{DEFAULT_PRIVACY}}\` → \`${DEFAULT_PRIVACY}\`, \`{{DECAY_PROFILE}}\` → \`${DECAY_PROFILE}\`. Obsidian browsing: ${OBSIDIAN_YN}.

## Why

The schema requires an initial structural decision record per AGENTS.md §4.6 when template placeholders are substituted. This record captures the answer set, the wizard version, and the template git SHA so a future \`--upgrade\` flow (v1.2) can compute a clean diff against the new template state.

## Alternatives Considered

- **Primary domain:** other valid slugs (e.g., \`software-engineering\`, \`cognitive-science\`) — rejected; ${PRIMARY_DOMAIN} chosen for this walkthrough.
- **LLM agent:** \`codex\` or \`other\` (both → \`AGENTS.md\` for the self-reference) — rejected; ${AGENT} chosen.
- **Privacy tier:** \`local_only\` — rejected; \`cloud_safe\` chosen to match the canonical public fixture.
- **Decay profile:** \`software\` (180d), \`science\` (730d), \`biography\` (1825d), \`personal-goals\` (90d) — rejected; \`default\` (365d) chosen.

## Consequences

AGENTS.md and CLAUDE.md are now personalized and byte-identical. \`.wizard-answers.yaml\` is the machine-authoritative source of the answer set. \`wiki/index.md\` has a \`## Decisions\` subsection with a wikilink back to this record.

## Affected Pages

None (this is an inaugural/infrastructure record per AGENTS.md §4.6; affected_pages: [] is permitted).

## Sources

- \`.wizard-answers.yaml\` — machine-authoritative answer set, generated at ${GENERATED_AT}.
- \`schema/AGENTS.template.md\` at SHA ${TEMPLATE_SHA} — the template rendered for this personalization.
- \`docs/manual-setup.md\` — the hand-edit walkthrough followed to produce this record.
EOF
```

### 8b. Append to wiki/index.md (inline snippet)

```bash
# Append a Decisions subsection + wikilink entry. Idempotent: re-running this
# block when the entry already exists is a no-op; use grep to guard.
TODAY="2026-04-16"
PRIMARY_DOMAIN="personal-knowledge"
ENTRY="- [[dr-${TODAY}-initial-setup|Initial Wizard Setup -- ${PRIMARY_DOMAIN}]] -- Wizard-driven template personalization (wiki-infrastructure, ${TODAY})"

if ! grep -qF "${ENTRY}" wiki/index.md; then
  if ! grep -qE '^## Decisions$' wiki/index.md; then
    printf '\n\n## Decisions\n\n%s\n' "${ENTRY}" >> wiki/index.md
  else
    # Existing section — append to it (the wizard would insert at section end;
    # plain append here works because the section is typically last)
    printf '%s\n' "${ENTRY}" >> wiki/index.md
  fi
fi
```

The wikilink format above matches `bin/init-wizard.sh`'s `update_index_md()` helper exactly. If the wizard has already run (or another contributor added a `## Decisions` section), the `grep -qF` guard prevents duplicate entries.

## Section 9: Sync CLAUDE.md

```bash
bash bin/sync-claude.sh
```

This copies AGENTS.md to CLAUDE.md byte-identical. Verify: `cmp -s AGENTS.md CLAUDE.md && echo OK`.

## Section 10: Wizard-Prompt Checklist (MANUAL-03)

Tick each box as you complete the corresponding wizard prompt:

- [ ] **Prompt 1 — Maintainer name:** recorded in `.wizard-answers.yaml` (Section 7) and decision record (Section 8a)
- [ ] **Prompt 2 — Primary domain:** edited `AGENTS.md` line 588 (Section 2)
- [ ] **Prompt 3 — LLM agent:** edited `AGENTS.md` line 32 (Section 3)
- [ ] **Prompt 4 — Privacy tier:** edited `AGENTS.md` line 589 (Section 4)
- [ ] **Prompt 5 — Decay profile:** edited `AGENTS.md` line 848 (Section 5)
- [ ] **Prompt 6 — Obsidian browsing:** recorded in `.wizard-answers.yaml` (Section 7)

## Section 11: Equivalence Statement (MANUAL-04)

The wizard track and the manual track produce a byte-identical end state. CI enforces this via `tests/phase-08/test_canonical_byte_equality.sh` and the `setup-parity.yml` GitHub workflow. If you follow this walkthrough using the example values from each section (`personal-knowledge`, `claude-code`, `cloud_safe`, `default`, `true`, date `2026-04-16`), your rendered `AGENTS.md` is byte-equal to `schema/fixtures/canonical-AGENTS.md`.

## Section 12: File-Touch List (MANUAL-05)

The wizard writes (and you have now reproduced, manually) these 5 files:

1. `AGENTS.md` — rendered from `schema/AGENTS.template.md` with 4 placeholder substitutions (Sections 2–5 OR the `sed` pipeline in the pre-step).
2. `CLAUDE.md` — byte-identical copy of AGENTS.md, written via `bash bin/sync-claude.sh` (Section 9).
3. `.wizard-answers.yaml` (Section 7).
4. `wiki/decisions/dr-<TODAY>-initial-setup.md` — the deterministic decision record per AGENTS.md §4.6 (Section 8a).
5. `wiki/index.md` — appended `## Decisions` subsection with wikilink to the new decision record (Section 8b).

## Section 13: Pointers

- [Pre-flight prerequisites](reference/setup-prerequisites.md) — bash >= 4, git, python3 install across platforms
- [Guided setup (wizard track)](guided-setup.md) — the automated alternative
- [Canonical fixture target](../schema/fixtures/canonical-AGENTS.md) — what the example values produce
- [WZRD-07 amendment note](../.planning/REQUIREMENTS.md) — placeholder set was reduced from 6 to 4 in Phase 8 per D-02
```

### 2. docs/guided-setup.md (replace stub)

```markdown
# Guided Setup (Wizard Track)

Run `bin/init-wizard.sh` and answer 6 prompts; the wizard writes 5 files to repo root.

## Quickstart

```bash
bash bin/init-wizard.sh
```

The wizard runs pre-flight (bash >= 4, git, python3) and then prompts you in this order:

1. **Maintainer name** — recorded in `.wizard-answers.yaml` and the initial decision record
2. **Primary domain** — substituted into `{{PRIMARY_DOMAIN}}` (validated `^[a-z0-9-]+$`)
3. **LLM agent** — `claude-code | codex | other`; controls `{{AGENT_FILENAME}}` self-reference
4. **Default privacy tier** — `local_only | cloud_safe`; substituted into `{{DEFAULT_PRIVACY}}`
5. **Decay profile** — `software | science | biography | personal-goals | default`
6. **Obsidian browsing** — y/n; recorded for future tooling, does not alter AGENTS.md

## Modes

- `bash bin/init-wizard.sh` — interactive, mutates repo
- `bash bin/init-wizard.sh --dry-run` — preview-only, prints unified diff per file
- `bash bin/init-wizard.sh --answers-file path/to/answers.yaml` — non-interactive (CI / replay)

## What gets written

5 files at repo root: `AGENTS.md`, `CLAUDE.md`, `.wizard-answers.yaml`, `wiki/decisions/dr-<TODAY>-initial-setup.md`, `wiki/index.md` (appended).

## Re-run / upgrade

The wizard refuses to re-run on an initialized repo (presence of `.wizard-answers.yaml`). To start fresh: `rm .wizard-answers.yaml AGENTS.md && bash bin/init-wizard.sh`. Upgrade flow planned for v1.2.

See [manual-setup.md](manual-setup.md) for the hand-edit equivalent.
```

### 3. docs/quickstart.md (populate the Phase-8 sections)

Read current content first; preserve any non-Phase-8 stubs; add a `## 1. Run the wizard` section pointing at `bin/init-wizard.sh` with a one-line invocation, then `## 2. Ingest your first source` linking to `bin/ingest.sh` (existing). Reference `docs/reference/setup-prerequisites.md` for prerequisites.

### 4. docs/reference/setup-prerequisites.md (new file per D-16)

```markdown
# Setup Prerequisites

`bin/init-wizard.sh` and most other `bin/*.sh` scripts require:

- **bash >= 4.0**
- **git**
- **python3 >= 3.8**

Optional but recommended:
- **PyYAML** (for richer `.wizard-answers.yaml` parsing — wizard falls back to a stdlib parser if absent)

## Installation by Platform

### macOS

```bash
brew install bash git python3
pip3 install pyyaml
```

(macOS ships with bash 3.2 by default; `brew install bash` is required.)

### Debian / Ubuntu / WSL (Debian-based)

```bash
sudo apt update && sudo apt install -y bash git python3 python3-pip
pip3 install pyyaml   # or: sudo apt install python3-yaml
```

### Arch Linux

```bash
sudo pacman -S bash git python python-yaml
```

### Fedora / RHEL

```bash
sudo dnf install bash git python3 python3-pyyaml
```

### Windows (native, no WSL)

Use Git Bash + Python from python.org. The wizard has not been tested on PowerShell or cmd.exe; WSL is the recommended path.

## Verify

```bash
bash --version | head -1   # Should report 5.x or 4.x
git --version              # Any modern version
python3 --version          # 3.8+
python3 -c "import yaml; print(yaml.__version__)"   # Optional; 5.x or 6.x
```

If any check fails, install the missing tool above. The wizard's pre-flight (`bin/init-wizard.sh`) re-runs these checks and exits 3 with a one-line-per-missing-tool message before any file I/O.
```

### 5. Amend .planning/REQUIREMENTS.md WZRD-07 (per D-02)

Edit `.planning/REQUIREMENTS.md`. Locate the WZRD-07 line and replace with:

```
- [ ] **WZRD-07**: Wizard renders from `schema/AGENTS.template.md` using exactly 4 named placeholders: `{{PRIMARY_DOMAIN}}`, `{{DEFAULT_PRIVACY}}`, `{{AGENT_FILENAME}}`, `{{DECAY_PROFILE}}`. (Amended Phase 8 per D-02: `{{EXAMPLE_CLUSTER_REF}}` rejected; `{{USER_NAME}}` lives only in `.wizard-answers.yaml` + the initial decision record, never in AGENTS.md.)
```

### 6. Verify

- `bash bin/check-neutrality.sh` exits 0 (no Kahneman tokens in new docs).
- `bash tests/phase-07/run.sh` exits 0.
- Critical review concern #3: `docs/manual-setup.md` must NOT tell users to edit `schema/AGENTS.template.md` in place — grep for any guidance that does. Every edit-instruction in Sections 2–5 references `AGENTS.md` line N, not `schema/AGENTS.template.md` line N.
- Critical review concern #4: `docs/manual-setup.md` Section 8 must contain a self-contained `cat > wiki/decisions/...` heredoc AND an inline `wiki/index.md` append snippet — both as code blocks, not prose pointers to the wizard.
  </action>
  <verify>
    <automated>test -f docs/manual-setup.md && [ "$(grep -cE '^## Section [0-9]+' docs/manual-setup.md)" -ge 13 ] && grep -q 'cp schema/AGENTS\.template\.md AGENTS\.md' docs/manual-setup.md && grep -q 'File to edit.*AGENTS\.md' docs/manual-setup.md && ! grep -qE 'File to edit.*schema/AGENTS\.template\.md' docs/manual-setup.md && grep -q 'cat > "wiki/decisions/dr-${TODAY}-initial-setup.md"' docs/manual-setup.md && grep -q 'trigger_type: schema-update' docs/manual-setup.md && grep -q 'personal-knowledge' docs/manual-setup.md && ! grep -qi 'kahneman' docs/manual-setup.md && grep -q 'byte-identical end state' docs/manual-setup.md && grep -q '\.wizard-answers\.yaml' docs/manual-setup.md && test -f docs/reference/setup-prerequisites.md && grep -q 'bash >= 4' docs/reference/setup-prerequisites.md && grep -q 'exactly 4 named placeholders' .planning/REQUIREMENTS.md && ! grep -q 'EXAMPLE_CLUSTER_REF' .planning/REQUIREMENTS.md && bash bin/check-neutrality.sh && bash tests/phase-07/run.sh</automated>
  </verify>
  <acceptance_criteria>
    - `docs/manual-setup.md` exists, contains at least 13 `## Section N` headings (Sections 1–13 per revised D-07 structure).
    - `docs/manual-setup.md` contains the pre-step `cp schema/AGENTS.template.md AGENTS.md` command OR the equivalent `sed` pipeline writing to AGENTS.md (review concern #3).
    - `docs/manual-setup.md` Sections 2–5 reference `AGENTS.md line N` (NOT `schema/AGENTS.template.md line N`). Verify: grep matches `File to edit:.*AGENTS\.md line` ≥4 times AND grep for `File to edit:.*schema/AGENTS\.template\.md line` returns 0 matches.
    - `docs/manual-setup.md` Section 8 contains a self-contained `cat > "wiki/decisions/dr-${TODAY}-initial-setup.md" <<EOF ... EOF` heredoc block including literal `trigger_type: schema-update` (review concern #4).
    - `docs/manual-setup.md` Section 8 contains the inline wiki/index.md append snippet with literal `[[dr-${TODAY}-initial-setup|Initial Wizard Setup -- ${PRIMARY_DOMAIN}]]` wikilink (review concern #4).
    - `docs/manual-setup.md` mentions `personal-knowledge` (D-10) AND does NOT mention `kahneman` (case-insensitive — preserves NEUT-02/03).
    - `docs/manual-setup.md` contains literal `byte-identical end state` (MANUAL-04 statement).
    - `docs/manual-setup.md` lists all 5 wizard-touched files in Section 12 (MANUAL-05): grep for `AGENTS.md`, `CLAUDE.md`, `.wizard-answers.yaml`, `wiki/decisions/`, `wiki/index.md`.
    - `docs/manual-setup.md` Section 10 has a 6-item checklist (MANUAL-03): `[ "$(grep -c '^- \[ \] \*\*Prompt [1-6]' docs/manual-setup.md)" -eq 6 ]`.
    - `docs/guided-setup.md` no longer contains the `populated in v1.1 Phase 8` stub marker.
    - `docs/quickstart.md` references `bin/init-wizard.sh`.
    - `docs/reference/setup-prerequisites.md` exists, contains `bash >= 4`, `git`, `python3`, and at least 4 platform headings (macOS, Debian, Arch, Windows).
    - `.planning/REQUIREMENTS.md` WZRD-07 line contains literal `exactly 4 named placeholders` AND no longer contains `EXAMPLE_CLUSTER_REF` or `USER_NAME`.
    - `bash bin/check-neutrality.sh && bash tests/phase-07/run.sh` exit 0 (no regression).
  </acceptance_criteria>
  <done>Manual-track docs landed with corrected copy-then-edit flow (review concern #3) and inline deterministic decision-record + index.md templates (review concern #4); quickstart + guided-setup populated; setup-prerequisites created; WZRD-07 amended.</done>
</task>

<task type="auto">
  <name>Task 2: 7 doc-structure tests verifying MANUAL-01..05 + review concerns #3 and #4</name>
  <files>tests/phase-08/test_manual_setup_sections.sh, tests/phase-08/test_manual_setup_example.sh, tests/phase-08/test_manual_setup_checklist.sh, tests/phase-08/test_manual_setup_equivalence.sh, tests/phase-08/test_manual_setup_file_list.sh, tests/phase-08/test_manual_setup_copy_not_edit.sh, tests/phase-08/test_manual_setup_inline_templates.sh</files>
  <read_first>
    - tests/phase-08/lib.sh
    - docs/manual-setup.md (just-shipped from Task 1)
  </read_first>
  <action>
For each test below: shebang `#!/usr/bin/env bash`, `set -euo pipefail`, source lib.sh, descriptive echo, exit 0 on success.

1. `tests/phase-08/test_manual_setup_sections.sh` (MANUAL-01):
   - `assert_file_exists "$REPO_ROOT/docs/manual-setup.md"`
   - Verify at least 13 `## Section N` headings: `[ "$(grep -cE '^## Section [0-9]+' "$REPO_ROOT/docs/manual-setup.md")" -ge 13 ]`
   - Verify each placeholder line citation present: grep for `line 588`, `line 32`, `line 589`, `line 848` in the doc.

2. `tests/phase-08/test_manual_setup_example.sh` (MANUAL-02):
   - Grep for `personal-knowledge` (the D-10 example) appearing in the diff snippets.
   - Negative assert: `! grep -qi 'kahneman' "$REPO_ROOT/docs/manual-setup.md"` (NEUT-02/03 preservation).
   - Verify each minimal-diff fence: `[ "$(grep -cE '^```diff$' "$REPO_ROOT/docs/manual-setup.md")" -ge 4 ]` (one diff per Section 2/3/4/5).

3. `tests/phase-08/test_manual_setup_checklist.sh` (MANUAL-03):
   - Verify 6-item checklist: `[ "$(grep -cE '^- \[ \] \*\*Prompt [1-6]' "$REPO_ROOT/docs/manual-setup.md")" -eq 6 ]`

4. `tests/phase-08/test_manual_setup_equivalence.sh` (MANUAL-04):
   - `assert_grep 'byte-identical end state' "$REPO_ROOT/docs/manual-setup.md" "MANUAL-04 statement present"`
   - Verify reference to CI test: `grep -q 'setup-parity\.yml' "$REPO_ROOT/docs/manual-setup.md"` OR `grep -q 'test_canonical_byte_equality' "$REPO_ROOT/docs/manual-setup.md"`.

5. `tests/phase-08/test_manual_setup_file_list.sh` (MANUAL-05):
   - All 5 written-files mentioned in Section 12: `for f in 'AGENTS.md' 'CLAUDE.md' '\.wizard-answers\.yaml' 'wiki/decisions/' 'wiki/index\.md'; do grep -qE "$f" "$REPO_ROOT/docs/manual-setup.md" || { echo "FAIL: missing $f"; exit 1; }; done`

6. **NEW (review concern #3):** `tests/phase-08/test_manual_setup_copy_not_edit.sh`:
   - Verify the pre-step cp/sed command appears: `grep -qE 'cp schema/AGENTS\.template\.md AGENTS\.md' "$REPO_ROOT/docs/manual-setup.md" || grep -qE 'sed .+ schema/AGENTS\.template\.md > AGENTS\.md' "$REPO_ROOT/docs/manual-setup.md"`
   - Verify NO section tells users to edit the template in place: `! grep -qE '^\*\*File to edit:\*\*[[:space:]]*`?schema/AGENTS\.template\.md' "$REPO_ROOT/docs/manual-setup.md"` (the "File to edit:" lines must NOT reference schema/AGENTS.template.md).
   - Verify each "File to edit:" line references `AGENTS.md` (at least 4 matches, one per Section 2/3/4/5): `[ "$(grep -cE '^\*\*File to edit:\*\*[[:space:]]*`?AGENTS\.md' "$REPO_ROOT/docs/manual-setup.md")" -ge 4 ]`

7. **NEW (review concern #4):** `tests/phase-08/test_manual_setup_inline_templates.sh`:
   - Verify the inline decision-record heredoc exists: `grep -q 'cat > "wiki/decisions/dr-${TODAY}-initial-setup.md" <<EOF' "$REPO_ROOT/docs/manual-setup.md"`
   - Verify the decision-record template contains all 7 required section headings: `for h in 'TL;DR' 'Decision' 'Why' 'Alternatives Considered' 'Consequences' 'Affected Pages' 'Sources'; do grep -qE "## $h" "$REPO_ROOT/docs/manual-setup.md" || { echo "FAIL: decision-record section $h missing"; exit 1; }; done`
   - Verify the decision record has `trigger_type: schema-update` and `type: decision` and `affected_pages: []` (all 3 critical frontmatter values inlined): `grep -q 'trigger_type: schema-update' "$REPO_ROOT/docs/manual-setup.md" && grep -qE '^type: decision' "$REPO_ROOT/docs/manual-setup.md" && grep -qE 'affected_pages: \[\]' "$REPO_ROOT/docs/manual-setup.md"`
   - Verify the inline wiki/index.md append snippet exists with the exact wikilink format Plan 03's update_index_md() produces: `grep -qF '[[dr-${TODAY}-initial-setup|Initial Wizard Setup -- ${PRIMARY_DOMAIN}]]' "$REPO_ROOT/docs/manual-setup.md"`
   - Verify the doc does NOT defer the decision record to the wizard: `! grep -qE '(run the wizard|invoke the wizard|bin/init-wizard\.sh).*to (generate|produce|create).*(decision|wiki/decisions)' "$REPO_ROOT/docs/manual-setup.md"` — the manual track is self-contained.

After all 7 written:
- `bash tests/phase-08/run.sh` reports `PHASE 08 TESTS: 20/20` (13 from Plan 03 + 7 from Plan 04) and exits 0.
  </action>
  <verify>
    <automated>bash tests/phase-08/run.sh && bash tests/phase-08/run.sh 2>&1 | grep -qE 'PHASE 08 TESTS: 20/20'</automated>
  </verify>
  <acceptance_criteria>
    - All 7 test files exist with shebang + `set -euo pipefail` + lib.sh source.
    - `bash tests/phase-08/run.sh` exits 0 with `PHASE 08 TESTS: 20/20` in stdout.
    - `bash bin/check-neutrality.sh && bash tests/phase-07/run.sh` exit 0.
  </acceptance_criteria>
  <done>7 doc-structure tests verify MANUAL-01..05 mechanically PLUS review concerns #3 (copy-not-edit) and #4 (inline deterministic templates); aggregator at 20/20.</done>
</task>

</tasks>

<verification>
1. `bash tests/phase-08/run.sh` exits 0 with `PHASE 08 TESTS: 20/20`.
2. `! grep -qi 'kahneman' docs/manual-setup.md docs/guided-setup.md docs/quickstart.md docs/reference/setup-prerequisites.md` (NEUT-02/03 preserved).
3. `grep -q 'exactly 4 named placeholders' .planning/REQUIREMENTS.md` (D-02 amendment landed).
4. `grep -q 'cp schema/AGENTS\.template\.md AGENTS\.md' docs/manual-setup.md` (review concern #3 — copy-not-edit).
5. `grep -q 'cat > "wiki/decisions/dr-${TODAY}-initial-setup.md"' docs/manual-setup.md` (review concern #4 — inline decision-record template).
6. `bash bin/check-neutrality.sh` exits 0.
7. `bash tests/phase-07/run.sh` exits 0.
</verification>

<success_criteria>
- Manual-track doc complete with the CORRECTED flow: copy template → AGENTS.md first, then edit AGENTS.md (review concern #3).
- Section 8 contains self-contained, byte-complete decision-record heredoc template + inline wiki/index.md append snippet (review concern #4). Manual track reaches the canonical fixture end state WITHOUT wizard invocation.
- WZRD-07 amended in REQUIREMENTS.md per D-02.
- setup-prerequisites.md centralizes the platform install matrix (D-16 mitigation).
- 7 doc-grep tests verify the structural commitments mechanically; aggregator at 20/20.
- Zero Kahneman regression in any new doc.
</success_criteria>

<output>
After completion, create `.planning/phases/08-two-track-setup-wizard-manual/08-04-SUMMARY.md` capturing: the 13 sections of manual-setup.md, the WZRD-07 before/after diff, the platform matrix in setup-prerequisites.md, the copy-then-edit correction (review concern #3), the inline decision-record + index.md templates (review concern #4), and confirmation that no Kahneman tokens appear in any new doc.
</output>
