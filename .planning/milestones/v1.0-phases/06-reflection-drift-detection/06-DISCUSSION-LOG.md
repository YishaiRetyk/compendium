# Phase 6: Reflection & Drift Detection - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-14
**Phase:** 06-reflection-drift-detection
**Areas discussed:** Decision record design, Reflect workflow triggers, Drift detection scope, Lint integration

---

## Decision Record Design

### Page Type

| Option | Description | Selected |
|--------|-------------|----------|
| Dedicated type | New page type 'decision' with own template, directory, frontmatter, and index category | ✓ |
| Overview subtype | Stay as type: overview with a distinguishing tag/field | |
| You decide | Claude picks based on codebase structure | |

**User's choice:** Dedicated type
**Notes:** Clean separation from topic overviews.

### Triggers

| Option | Description | Selected |
|--------|-------------|----------|
| Page merges/splits | Structural reorganization rationale | ✓ |
| Schema updates | Why rules evolved | ✓ |
| Domain reorganization | Taxonomic reasoning | ✓ |
| Significant reframing | Intellectual evolution from new evidence | ✓ |

**User's choice:** All four, plus two additional triggers from user notes
**Notes:** User added: (5) major supersession — when a page/framework is explicitly replaced, leveraging existing SUPERSEDE vocabulary; (6) contradiction-resolution decisions — when the wiki chooses how to represent an ongoing disagreement. Unifying principle: "create a decision record when future-you would reasonably ask 'why is the wiki shaped this way?'"

### Content Structure

| Option | Description | Selected |
|--------|-------------|----------|
| Structured fields | Frontmatter (trigger type, affected pages, date) + full §11.4 sections + Affected Pages section | ✓ |
| Minimal skeleton | Just TL;DR + Decision + Why | |
| You decide | Claude picks balance of structure vs friction | |

**User's choice:** Structured fields
**Notes:** Parseable for auditing.

### Back-links from Affected Pages

| Option | Description | Selected |
|--------|-------------|----------|
| Frontmatter + optional visible section | `decision_history` frontmatter always present; visible section only when meaningful | ✓ |
| Decision record outward only | One-way navigation, no back-links | |

**User's choice:** Frontmatter + optional visible section
**Notes:** User specified: purely one-way navigation is too weak. Always keep machine-readable backlinks in frontmatter for auditability. Visible "Decision History" section only when history is meaningful — avoids body clutter on pages with minor or no structural decisions.

---

## Reflect Workflow Triggers

| Option | Description | Selected |
|--------|-------------|----------|
| Manual only | User/agent explicitly runs reflect | |
| Prompted by other workflows | Workflows emit "reflect recommended" reminders | |
| Inline during operations | Decision records created as part of operation commits | |
| Hybrid (user-proposed) | Inline for obvious events + workflow recommendations for ambiguous signals + manual periodic sweep | ✓ |

**User's choice:** Hybrid — three-tier model
**Notes:** User proposed combining options 2 and 3 with manual fallback. Inline creation for clear structural events (merge, split, supersede, schema update, domain reorg, recognized reframing). Workflow-emitted "reflect recommended" for ambiguous signals (framing shifts, contradiction resolution, novel synthesis, accumulated drift). Manual/periodic reflect as safety net scanning log.md and git history.

### Reflect Checkpoint Mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| State file with explicit checkpoint | Dedicated state file with last_reflect_log_entry, last_reflect_commit, last_reflect_at | ✓ |
| Infer from latest decision record | Use most recent decision record timestamp | |
| Claude's discretion | Planner decides | |

**User's choice:** State file with explicit checkpoint
**Notes:** User specified: decision records are outputs, not control-plane state. A reflect run may produce no decision records but still needs to advance the checkpoint. Both log.md and git history used for discovery — neither alone is sufficient.

---

## Drift Detection Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Wiki ↔ sources only | Just DRFT-01 and DRFT-02 filesystem checks | |
| Wiki ↔ sources + Obsidian vault awareness | Add Obsidian-specific filesystem checks | ✓ |
| Full toolchain including Zotero/cloud | External system integration | |

**User's choice:** Wiki ↔ sources + Obsidian vault awareness
**Notes:** User specified: option 1 too narrow for an explicitly Obsidian-oriented system; option 3 too much for v1, pulls into connector-specific integration. DRFT-03 scoped narrowly to filesystem-visible toolchain drift. Zotero/cloud deferred to future integration layer.

### Content-Hash Drift

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit drift check | Compare file hash against stored content_hash | ✓ |
| Covered by compilation_status | Rely on existing stale mechanism | |

**User's choice:** Explicit drift check
**Notes:** User specified: decay staleness (time passed) vs content-hash drift (source literally changed) are fundamentally different signals. Hash drift is deterministic and stronger. Content-hash drift is the mechanism; compilation_status: stale is the resulting state. Not "already covered well enough."

---

## Lint Integration

### Integration Model

| Option | Description | Selected |
|--------|-------------|----------|
| Folded into standard lint | Drift checks run as part of bin/lint.sh by default | |
| Optional lint flag | --drift enables drift checks, skipped by default | |
| Separate subcommand | bin/drift.sh as standalone tool | |
| Standard lint + future scalability (user-proposed) | Folded in for v1; add --quick/--full/--skip-hash later if needed | ✓ |

**User's choice:** Standard lint + future scalability
**Notes:** User specified: drift is part of wiki health, not a separate concern. Splitting too early weakens the "one health-check entry point" model. Opt-in checks likely to be skipped. But don't hardcode "no flags ever" — leave room for performance modes later.

### Drift Category Classification

| Option | Description | Selected |
|--------|-------------|----------|
| Drift as new lint category | Distinct from structural, staleness, contradiction, gap | ✓ |
| Drift absorbs existing checks | Reclassify structural checks where appropriate | |

**User's choice:** Drift as new lint category
**Notes:** User specified: drift is a distinct concept (divergence between layers/systems). Categorize by why the finding matters, not raw symptom. Same check can classify as structural or drift depending on context. Overlap is okay; duplication in reporting is not.

### Severity Tiers

| Option | Description | Selected |
|--------|-------------|----------|
| All drift is warning | Consistent flat severity | |
| Tiered within drift | error/warning/info per finding type | ✓ |

**User's choice:** Tiered within drift
**Notes:** User specified mapping: error = broken traceability (missing source, nonexistent provenance target); warning = stale compilation (hash drift, uncompiled sources, index divergence); info = cosmetic (Dataview improvements, noncritical mismatches).

---

## Claude's Discretion

- Decision record file naming convention
- Decision record template exact wording
- Format of "reflect recommended" messages
- AGENTS.md §11.4 restructuring approach
- Drift check integration into §11.3 step sequence
- bin/lint.sh internal implementation for drift checks
- Reflect state file exact location and format
- Whether decision_history uses page IDs or filenames

## Deferred Ideas

- Zotero/cloud drift reconciliation — future integration layer
- Lint performance modes (--quick, --full, --skip-hash) — not needed at v1 scale
