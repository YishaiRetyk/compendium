---
created: 2026-05-01T00:00:00
title: Fix planning artifact consistency after phase 12–13 reorder
area: planning
files:
  - .planning/REQUIREMENTS.md:215
  - .planning/REQUIREMENTS.md:302
  - .planning/ROADMAP.md:176
  - .planning/ROADMAP.md:229
  - .planning/STATE.md:114
  - .planning/v1.1-MILESTONE-AUDIT.md:211
---

## Problem

The phase 12–13 reorder (commit 18cc4d2) introduced several consistency gaps across planning artifacts:

**High priority:**

1. **REQUIREMENTS.md:215** — The traceability Status column for NEUT-08 contains prose (`Promoted from backlog...`) instead of a lifecycle value. Should be `Pending` until Phase 12.1 completes, then `Complete`. Promotion rationale belongs in the requirement body or a note field, not the Status cell.

2. **ROADMAP.md:176** — The Phase 12.1 success criterion states "`requirements-sync.sh --strict` proves zero NEUT-08 drift," but that command already returns 0 with no verification in place — so the criterion passes trivially. Replace with: _"Phase 12.1 verification artifact marks NEUT-08 Complete, and `requirements-sync.sh --strict --phase 12.1` reports zero drift."_ Longer term, `requirements-sync` should fail strict mode when active requirements are still Pending at phase closure.

**Medium priority:**

3. **REQUIREMENTS.md:302** — Still reads "10 active v1.1 phases (7–13.1)". Should be updated to "11 active v1.1 phases (7–13.2)".

4. **STATE.md:114 and v1.1-MILESTONE-AUDIT.md:211** — Stale descriptions: STATE.md still calls Phase 12 the "v1.0 debt verification gate"; the milestone audit still lists the old phase mapping and marks NEUT-08 as partial/deferred. If these are live planning inputs, update them; otherwise mark superseded.

**Low priority:**

5. **ROADMAP.md:229** — Phase 13.1 dependency says "all feature surfaces stable and documented," but Phase 13.1 *is* the documentation phase — circular. Change to "all feature surfaces stable".

## Solution

Mechanical edits across four files. No design decisions required:
- Fix REQUIREMENTS.md status cell and phase count
- Fix ROADMAP.md success criterion and circular dependency wording
- Update or supersede STATE.md and v1.1-MILESTONE-AUDIT.md stale sections
