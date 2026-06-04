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

## Section 8: Write the Initial Decision Record + Update wiki-cloud/index.md

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

mkdir -p wiki-cloud/decisions
cat > "wiki-cloud/decisions/dr-${TODAY}-initial-setup.md" <<EOF
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

AGENTS.md and CLAUDE.md are now personalized and byte-identical. \`.wizard-answers.yaml\` is the machine-authoritative source of the answer set. \`wiki-cloud/index.md\` has a \`## Decisions\` subsection with a wikilink back to this record.

## Affected Pages

None (this is an inaugural/infrastructure record per AGENTS.md §4.6; affected_pages: [] is permitted).

## Sources

- \`.wizard-answers.yaml\` — machine-authoritative answer set, generated at ${GENERATED_AT}.
- \`schema/AGENTS.template.md\` at SHA ${TEMPLATE_SHA} — the template rendered for this personalization.
- \`docs/manual-setup.md\` — the hand-edit walkthrough followed to produce this record.
EOF
```

### 8b. Append to wiki-cloud/index.md (inline snippet)

```bash
# Append a Decisions subsection + wikilink entry. Idempotent: re-running this
# block when the entry already exists is a no-op; use grep to guard.
TODAY="2026-04-16"
PRIMARY_DOMAIN="personal-knowledge"
ENTRY="- [[dr-${TODAY}-initial-setup|Initial Wizard Setup -- ${PRIMARY_DOMAIN}]] -- Wizard-driven template personalization (wiki-infrastructure, ${TODAY})"

if ! grep -qF "${ENTRY}" wiki-cloud/index.md; then
  if ! grep -qE '^## Decisions$' wiki-cloud/index.md; then
    printf '\n\n## Decisions\n\n%s\n' "${ENTRY}" >> wiki-cloud/index.md
  else
    # Existing section — append to it (the wizard would insert at section end;
    # plain append here works because the section is typically last)
    printf '%s\n' "${ENTRY}" >> wiki-cloud/index.md
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
4. `wiki-cloud/decisions/dr-<TODAY>-initial-setup.md` — the deterministic decision record per AGENTS.md §4.6 (Section 8a).
5. `wiki-cloud/index.md` — appended `## Decisions` subsection with wikilink to the new decision record (Section 8b).

## Section 13: Pointers

- [Pre-flight prerequisites](reference/setup-prerequisites.md) — bash >= 4, git, python3 install across platforms
- [Guided setup (wizard track)](guided-setup.md) — the automated alternative
- [Canonical fixture target](../schema/fixtures/canonical-AGENTS.md) — what the example values produce
- [WZRD-07 amendment note](../.planning/REQUIREMENTS.md) — placeholder set was reduced from 6 to 4 in Phase 8 per D-02
