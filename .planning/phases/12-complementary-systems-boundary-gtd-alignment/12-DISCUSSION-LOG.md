# Phase 12: Complementary Systems Boundary + GTD Alignment - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-01
**Phase:** 12-complementary-systems-boundary-gtd-alignment
**Areas discussed:** Reference doc filename + section ordering, Routing table cell content, README pointer placement + wording, Audit grep patterns + scope

---

## Reference doc filename + section ordering

### Q1 — What filename under docs/reference/?

| Option | Description | Selected |
|--------|-------------|----------|
| three-layer-model.md | Names the doc by its primary mental model. Discoverable by users searching 'layers'/'architecture'. Matches sibling doc style (privacy-model.md). | ✓ |
| complementary-systems.md | Names the doc by its phase/requirement framing. Matches BOUND requirement language. Slightly more abstract for a first-time reader. | |
| system-boundary.md | Names the doc by what it draws (a boundary). Shortest, but less self-explanatory. | |

**User's choice:** three-layer-model.md (Recommended)
**Notes:** Aligns with sibling reference docs that use `<concept>-model.md` naming convention.

### Q2 — Section order in the reference doc?

| Option | Description | Selected |
|--------|-------------|----------|
| Model → Routing → Anti-features | Lead with the conceptual frame so the routing table and anti-features have grounding. Mirrors the source notes flow. | ✓ |
| Routing → Model → Anti-features | Lead with operator-facing rules; treat the model as supporting context. Reader can act before reading theory. | |
| Anti-features → Model → Routing | Lead with what compendium is NOT. Sharp boundary up front, then explain the why. | |

**User's choice:** Model → Routing → Anti-features (Recommended)

### Q3 — Doc opening?

| Option | Description | Selected |
|--------|-------------|----------|
| 1-paragraph framing TL;DR-style | Short opening paragraph mirroring privacy-model.md and brownfield.md. | ✓ |
| Jump straight into Section 1 | Save vertical space; H1 + Section 1 do the framing. | |

**User's choice:** Yes — 1-paragraph framing (Recommended)

---

## Routing table cell content

### Q4 — How should 'Belongs in' column treat compendium for the GTD verbs?

| Option | Description | Selected |
|--------|-------------|----------|
| Task layer for capture/clarify/organize, all 3 layers for review | First three verbs route to task layer; review draws across all layers. | |
| Task layer for capture/clarify/organize/review, none in compendium | All 4 verbs route entirely to task layer. Compendium has no GTD-verb role. | |
| Working-memory layer for capture/clarify, task layer for organize, all layers for review | Most granular: ephemeral capture/clarify in working-memory, organization in task system, review across all layers. | ✓ |

**User's choice:** Working-memory for capture/clarify; task layer for organize; all-layers for review
**Notes:** User picked the most-accurate option over the simpler/sharper alternatives. Signal: precision > sharpness in this doc.

### Q5 — How should 'Compendium role' column phrase compendium's contribution per verb?

| Option | Description | Selected |
|--------|-------------|----------|
| Concrete actions: 'ingest source', 'consume past synthesis', etc. | Specific compendium operations per verb. Mechanically auditable. | ✓ |
| Abstract roles: 'durable memory', 'reflective synthesis', etc. | Abstract role labels per verb. Reads cleaner but less actionable. | |
| Empty cells for non-roles | Empty for capture/clarify/organize, populate only review. Visual sharpness. | |

**User's choice:** Concrete actions per verb (Recommended)

### Q6 — 'Out of scope' column per-verb specific or shared pointer?

| Option | Description | Selected |
|--------|-------------|----------|
| Per-verb specific entries | Each row gets specific exclusions tied to its verb. Maximum specificity. | ✓ |
| Single 'see anti-features section' pointer per row | Less duplication, less informative scanning. | |
| Mixed: specific for capture/clarify/organize, pointer for review | First three explicit; review points to broader anti-features list. | |

**User's choice:** Per-verb specific entries (Recommended)

### Q7 — 1-line caption above the table?

| Option | Description | Selected |
|--------|-------------|----------|
| 1-line caption explaining 4-column reading order | Helps first-time readers parse the table quickly. | ✓ |
| No caption — column headers do the work | Trust the column headers. Saves space. | |

**User's choice:** 1-line caption above the table (Recommended)

---

## README pointer placement + wording

### Q8 — Where does the new line land in README.md?

| Option | Description | Selected |
|--------|-------------|----------|
| End of 'What this is' section, after 'Unlike search-over-notes' paragraph | Reader gets framing first; pointer arrives as next-step. Mirrors quickstart pointer style. | ✓ |
| Top of 'What this is' section, as second sentence | Inject boundary upfront so partial readers see it. Risks reading defensively. | |
| New 'How this fits in your stack' section | Treats boundary as its own README section. Most discoverable but borderline scope. | |

**User's choice:** End of 'What this is' section (Recommended)
**Notes:** User signal — don't disrupt the reader's first-impression flow with a defensive framing.

### Q9 — Wording shape for the pointer line?

| Option | Description | Selected |
|--------|-------------|----------|
| Contextual sentence with embedded link | One sentence, gives reader the why before the click. | ✓ |
| Bare 'See:' line | Minimal surface change. | |
| Bullet under existing paragraph | Matches READMEs that use bulleted lists; this README's section is prose-only. | |

**User's choice:** Contextual sentence with embedded link (Recommended)
**Notes:** User signal — give the reader the why before the click.

### Q10 — Should docs/reference/index.md get a similar entry?

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — add bullet matching existing index style | Required by SPEC AC #4. Concise existing index style. | ✓ |
| Yes, but with longer description tied to GTD verbs | More descriptive but verbose. | |

**User's choice:** Bullet matching existing index style (Recommended)

---

## Audit grep patterns + scope

### Q11 — Which exact patterns?

| Option | Description | Selected |
|--------|-------------|----------|
| Core 6: 'all-in-one', 'task manager', 'task backend', 'reminder system', 'calendar app', 'inbox interface' | Targets the framings the SPEC and notes flag. Low false-positive risk. | |
| Core 6 + 'replaces' / 'replacement for' (any task system) | Adds dynamic phrasing. Catches more drift but needs care to avoid false positives. | ✓ |
| Core 6 + non-goal terms from ROADMAP.md | Comprehensive: catches both 'IS X' and 'will add Y' framings. Most thorough but most noise. | |

**User's choice:** Core 6 + 'replaces' / 'replacement for' patterns
**Notes:** User accepted false-positive risk in exchange for catching dynamic framing drift.

### Q12 — File scope for the audit?

| Option | Description | Selected |
|--------|-------------|----------|
| README.md + AGENTS.md + docs/ + wiki/decisions/ | Matches BOUND-03 wording exactly. Excludes .planning/, examples/, other wiki/ subtrees. | ✓ |
| Above + .planning/ | Risks false positives because .planning/notes/2026-04-24-*.md legitimately mentions the exclusions. | |
| Above + entire wiki/ tree | Includes user-facing wiki pages; out of scope for v1.1 template shipping. | |

**User's choice:** README.md + AGENTS.md + docs/ + wiki/decisions/ (Recommended)

### Q13 — Audit form?

| Option | Description | Selected |
|--------|-------------|----------|
| Inline shell snippet captured in VERIFICATION.md | One-time check; reproducible from VERIFICATION.md. | ✓ |
| New bin/check-boundary.sh script (CI-enforced) | More durable but adds bin/ change — SPEC requirement #6 forbids it. | |
| Add to existing bin/check-neutrality.sh as new category | Reuses infrastructure but conflates two domains in one script. | |

**User's choice:** Inline shell snippet in VERIFICATION.md (Recommended)
**Notes:** Honors SPEC requirement #6 (zero bin/ changes for this phase).

### Q14 — Bound 'replaces' regex to avoid false positives?

| Option | Description | Selected |
|--------|-------------|----------|
| Bounded: '(replaces\|replacement for) (a \|an \|your )?(task\|gtd\|todo\|reminder\|calendar)' | Catches 'replaces a task manager' / 'replacement for your todo app' without bare-replaces noise. | ✓ |
| Loose: bare 'replaces' / 'replacement for' | Catches more drift but produces false positives ('this script replaces the old one'). | |
| Drop 'replaces' patterns; stick with Core 6 | Simpler grep set; misses dynamic 'replaces X' framings. | |

**User's choice:** Bounded regex (Recommended)

---

## Claude's Discretion

- Exact prose wording of every routing-table cell, the README sentence, the index bullet, and the DR's Why / Consequences sections is open to gsd-doc-writer / planner refinement (semantic content is locked; surface phrasing may polish).
- Anti-features section list ordering and grouping — discretionary as long as all SPEC-required items appear (inbox, next-action execution, calendar, reminders, rapid transactional updates, high-churn waiting-for state, Slack/ticket/event-stream ingest).
- Whether to add a small "Why this exists" paragraph in the new ref doc — discretionary; the TL;DR opening (D-03) may absorb that role.

## Deferred Ideas

- **bin/check-boundary.sh as ongoing CI audit** — discussed (Q13) and rejected for Phase 12 (SPEC requirement #6 forbids bin/ changes). If future drift becomes recurring, promote to v1.2 phase.
- **PROJECT.md core-value paragraph update** — discussed implicitly; not required (current PROJECT.md is already compatible with the boundary).
- **"How this fits in your stack" as new README section** — discussed (Q8 option C); rejected as borderline scope creep against SPEC's "one new pointer line" wording.
- **Adding a 5th GTD verb (engage) to the routing table** — discussed implicitly; not pursued. Allen's 4 classic verbs match the boundary framing.
- **decision_history back-links from existing 4 DRs to BOUND-01** — explicitly out of scope per SPEC; AGENTS.md §4.6 makes this optional.
- **Promoting .planning/notes/2026-04-24-*.md into wiki/** — out of scope by design (notes are origin/inputs; canonical surface is the output).
