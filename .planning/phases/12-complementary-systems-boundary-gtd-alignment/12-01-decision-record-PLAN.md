---
id: 12-01-decision-record
plan_id: 12-01
phase: 12
plan: 01
wave: 1
type: execute
depends_on: []
files_modified:
  - wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md
requirements:
  - BOUND-01
autonomous: true
must_haves:
  truths:
    - "A type-decision page exists at wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md."
    - "The decision record states that compendium owns durable, provenance-backed wiki memory and review support, while complementary systems own executable commitments, reminders, calendars, transactional state, and high-churn operational events."
    - "The decision record's Why section explicitly contrasts compendium ownership (durable synthesis, heavy-write/cheap-read) vs complementary-system ownership (executable commitments / reminders / calendars / transactional state)."
    - "The Alternatives Considered section names and rejects (a) all-in-one PKM/task system framing, (b) deferring boundary statement to v2, (c) embedding boundary inline in README only."
    - "bin/lint.sh --category yaml,provenance exits 0 when run against the new decision record."
  artifacts:
    - path: wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md
      provides: "BOUND-01 decision record (trigger_type schema-update, affected_pages [], 7 required sections per AGENTS.md §4.6)"
      contains: "type: decision"
  key_links:
    - from: wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md
      to: docs/reference/three-layer-model.md
      via: "relative markdown link in body (NOT wikilink — body links to non-wiki refs use plain markdown)"
      pattern: "docs/reference/three-layer-model.md"
---

<objective>
Create the BOUND-01 decision record `wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md` capturing that compendium owns durable, provenance-backed wiki memory and review support, while complementary systems own executable commitments, reminders, calendars, transactional state, and high-churn operational events.

Purpose: Convert the substance of the three exploratory `.planning/notes/2026-04-24-*.md` notes into the canonical shipped surface, satisfying BOUND-01 and unblocking BOUND-02 / BOUND-03 which cross-reference this file.
Output: One new decision record file conforming to AGENTS.md §4.6 (type: decision, trigger_type: schema-update, affected_pages: [], 7 required sections).
</objective>

<context>
@.planning/phases/12-complementary-systems-boundary-gtd-alignment/12-SPEC.md
@.planning/phases/12-complementary-systems-boundary-gtd-alignment/12-CONTEXT.md
@AGENTS.md
@wiki/decisions/dr-2026-04-14-phase6-decision-type.md
@wiki/decisions/dr-2026-04-20-brownfield-apply-vs-advisory.md
@.planning/notes/2026-04-24-agentic-gtd-boundary.md
@.planning/notes/2026-04-24-openbrain-vs-compendium-critique.md
@.planning/notes/2026-04-24-wiki-compiler-idea.md
</context>

<threat_model>
N/A — pure docs phase. This plan adds one markdown decision record under wiki/decisions/. No executable code paths, no API surface, no new attack surface introduced. The existing public-paths leak guard (bin/check-neutrality.sh / bin/check-privacy.sh) and AGENTS.md ↔ CLAUDE.md byte-equality pre-commit hook are unchanged by this plan.
</threat_model>

<tasks>

<task type="auto" tdd="false">
  <name>Task 1: Write BOUND-01 decision record at wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md</name>
  <files>wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md</files>
  <read_first>
    - .planning/phases/12-complementary-systems-boundary-gtd-alignment/12-SPEC.md (locked requirements 1, BOUND-01 acceptance criteria)
    - .planning/phases/12-complementary-systems-boundary-gtd-alignment/12-CONTEXT.md (locked decisions D-15, D-16, D-17, D-18)
    - AGENTS.md §4.6 (Decision page type contract: required frontmatter fields, 7 required sections, epistemic_status: sourced pattern)
    - AGENTS.md §3 "What Agents Must NOT Do" (no wikilinks in frontmatter; first-mention-only links; no display aliases)
    - AGENTS.md §5 (base + decision-record additional fields: trigger_type, affected_pages)
    - wiki/decisions/dr-2026-04-14-phase6-decision-type.md (inaugural-record precedent — affected_pages: [] with sources: [] empty)
    - wiki/decisions/dr-2026-04-20-brownfield-apply-vs-advisory.md (most recent DR — full base-fields shape)
    - .planning/notes/2026-04-24-agentic-gtd-boundary.md (3-layer model + good-fits/poor-fits — origin substance)
    - .planning/notes/2026-04-24-openbrain-vs-compendium-critique.md (heavy-write/cheap-read tradeoff + non-goals — origin substance)
    - .planning/notes/2026-04-24-wiki-compiler-idea.md (architecture origin)
  </read_first>
  <action>
Create exactly one new file at the path `wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md`.

**Frontmatter** (all base fields per AGENTS.md §5 + decision-record extras D-16 + matching the dr-2026-04-14-phase6-decision-type.md inaugural-record shape):

```yaml
---
id: dr-2026-05-01-complementary-systems-boundary
title: "Complementary Systems Boundary: Compendium as Durable Wiki Memory in a Multi-System Stack"
type: decision
status: active
summary: "Compendium owns durable, provenance-backed wiki memory and review support; complementary systems own executable commitments, reminders, calendars, transactional state, and high-churn operational events."
created_at: 2026-05-01
updated_at: 2026-05-01
sources: []
epistemic_status: sourced
tags:
  - boundary
  - architecture
  - gtd-alignment
  - meta
domains:
  - wiki-infrastructure
supersedes:
superseded_by:
privacy: cloud_safe
aliases: []
has_contradictions: false
knowledge_domain: software
trigger_type: schema-update
affected_pages: []
---
```

(`sources: []` is empty because the cited material — `.planning/notes/2026-04-24-*.md` and `.planning/REQUIREMENTS.md` / `.planning/ROADMAP.md` — are not source-summary pages in `wiki/sources/`; the body's `## Sources` section uses plain markdown links per the inaugural-record precedent.)

**Forbidden-patterns comment** (immediately after the closing `---`, copy verbatim from sibling DRs):

```
<!-- FORBIDDEN PATTERNS (see AGENTS.md section 3):
     - No wikilinks in frontmatter (use plain string IDs in sources[], affected_pages[], supersedes, etc.)
     - No display aliases: write [[Page Title]] not [[Page Title|Alias]]
     - Link each page only on first mention in the body -->
```

**Body — all 7 required sections per AGENTS.md §4.6, in this exact order:**

1. `## TL;DR` — 1 short paragraph stating: compendium owns durable, provenance-backed wiki memory and review support; complementary systems (task manager, calendar, reminders, working-memory layer) own executable commitments, transactional state, and high-churn operational events. The boundary makes the multi-system stack explicit before v1.1 closes (CLOSE-04 scope-leak gate depends on it).

2. `## Decision` — Adopt the following architectural framing:
   - **Compendium** is the wiki-compiler layer of a multi-system agent stack. It owns: durable synthesis, decisions and rationale, provenance-backed beliefs, reflective memory, review support that surfaces stale claims / contradictions / neglected projects / durable insights.
   - **Complementary systems** own the layers compendium does NOT serve: a task layer (executable commitments, next actions, reminders, calendar, waiting-for mechanics, transactional state) and a working-memory layer (recent conversations, scratch context, inbox material, short-lived reasoning state).
   - The boundary is captured in this decision record (canonical home per AGENTS.md §4.6) and elaborated operationally in `docs/reference/three-layer-model.md` (3-layer model + 4-verb routing table + anti-features).

3. `## Why` — State exactly what framing was adopted and what it replaced (per AGENTS.md §4.6 requirement). Use approximately this framing pivot, polished for cadence:

   > Compendium is heavy-write at ingest and cheap-read at query — the opposite shape of a task / GTD backend, which is heavy-read at every check-in and cheap-write at capture. Conflating the two layers produces a system that is bad at both: noisy and high-friction for transactional task work, and shallow and unfaithful for durable synthesis. The framing adopted is "compendium owns durable, provenance-backed synthesis and reflective memory; complementary systems own executable commitments, reminders, calendars, and transactional/operational state." The framing it replaces is the implicit "all-in-one PKM/task system" assumption that compendium would absorb inbox capture, next-action execution, calendar, reminders, and high-churn operational state. That implicit framing was never written down but was the natural drift direction; this record makes the rejection explicit before v1.1 closes.

   Reference `.planning/notes/2026-04-24-openbrain-vs-compendium-critique.md` for the heavy-write/cheap-read tradeoff and `.planning/notes/2026-04-24-agentic-gtd-boundary.md` for the 3-layer model context.

4. `## Alternatives Considered` — List at minimum these three alternatives with rejection rationales (per D-18, locked):

   - **All-in-one PKM/task system framing.** Rejected as a fundamental category error: compendium's ingest pipeline is heavy-write / cheap-read (correct for durable synthesis), which is the wrong shape for capture, clarify, and execute workflows that need cheap-write / heavy-read. Treating compendium as a task backend would produce a system that is shallow at both jobs. (See `.planning/notes/2026-04-24-openbrain-vs-compendium-critique.md`.)
   - **Deferring the boundary statement to v2.** Rejected because `CLOSE-04` (final scope-leak check) cannot pass while the canonical shipped surface lacks an explicit complementary-systems boundary. Without this record, README and docs could be read as ambient endorsement of all-in-one framing, making the v1.1 closure gate unverifiable.
   - **Embedding the boundary inline in README only.** Rejected because decision records are the canonical home for architectural decisions per AGENTS.md §4.6 and the Phase 6 dr-2026-04-14-phase6-decision-type precedent. README can point at the boundary, but the boundary itself is structural and lives in `wiki/decisions/`.

5. `## Consequences` — Enumerate concrete consequences. Include at minimum:
   - The complementary-systems boundary is now canonical: future work that would add a task manager, calendar, reminder engine, inbox UI, or Slack/ticket/event-stream ingest pipeline to compendium must either supersede this record or live in a complementary system.
   - `docs/reference/three-layer-model.md` becomes the operator-facing operationalization of this record (3-layer model + capture/clarify/organize/review routing + anti-features list).
   - README gains one contextual pointer sentence under "What this is" (per BOUND-03) referencing the new ref doc — discoverability without surface bloat.
   - No new wiki page types or `wiki/` directory taxonomies are added (still 6 page types per AGENTS.md §4: entity, concept, source, comparison, overview, decision).
   - REQUIREMENTS.md `BOUND-01` (this record), `BOUND-02` (the ref doc), and `BOUND-03` (audit + README pointer + indexes) are unblocked; `CLOSE-04` scope-leak gate becomes verifiable once Phase 12 closes.
   - Deferred items remain deferred: GTD review dashboards (backlog Phase 999.6), task-system bridging (out of scope for v1.1), Slack/ticket ingest (out of scope per ROADMAP.md non-goals).

6. `## Affected Pages` — Single sentence: "None. This is an infrastructure-only decision record (`affected_pages: []`); no pre-existing wiki pages are restructured by stating the complementary-systems boundary." (Mirrors the dr-2026-04-14-phase6-decision-type.md precedent verbatim in shape.)

7. `## Sources` — Plain markdown links (NOT wikilinks — these are non-wiki refs):
   - `.planning/notes/2026-04-24-agentic-gtd-boundary.md` — 3-layer model + good-fits/poor-fits lists.
   - `.planning/notes/2026-04-24-openbrain-vs-compendium-critique.md` — heavy-write/cheap-read tradeoff + non-goals.
   - `.planning/notes/2026-04-24-wiki-compiler-idea.md` — architecture origin.
   - `.planning/REQUIREMENTS.md` BOUND-01 / BOUND-02 / BOUND-03 (the requirement IDs this record closes).
   - `.planning/ROADMAP.md` Phase 12 entry (goal, dependencies, non-goals).
   - `docs/reference/three-layer-model.md` (sibling operator-facing operationalization, written in the same phase).

   Use this exact markdown link form (relative paths from repo root, since DR body links to non-wiki refs use plain markdown per the integration-points note in CONTEXT.md):

   ```
   - [.planning/notes/2026-04-24-agentic-gtd-boundary.md](../../.planning/notes/2026-04-24-agentic-gtd-boundary.md) — 3-layer model + good-fits/poor-fits lists.
   - [.planning/notes/2026-04-24-openbrain-vs-compendium-critique.md](../../.planning/notes/2026-04-24-openbrain-vs-compendium-critique.md) — heavy-write/cheap-read tradeoff + non-goals.
   - [.planning/notes/2026-04-24-wiki-compiler-idea.md](../../.planning/notes/2026-04-24-wiki-compiler-idea.md) — architecture origin.
   - [.planning/REQUIREMENTS.md](../../.planning/REQUIREMENTS.md) — BOUND-01, BOUND-02, BOUND-03.
   - [.planning/ROADMAP.md](../../.planning/ROADMAP.md) — Phase 12 entry.
   - [docs/reference/three-layer-model.md](../../docs/reference/three-layer-model.md) — operator-facing 3-layer model + routing rules.
   ```

**Body link rule (per D-17 and AGENTS.md §8 first-mention-only):** Link `docs/reference/three-layer-model.md` ONCE (in the Sources section is the natural first-mention site). Do NOT link it again in the body — subsequent prose mentions are plain text.

**Style guidance:**
- Open the TL;DR with a 1-paragraph framing, mirroring the cadence of dr-2026-04-20-brownfield-apply-vs-advisory.md.
- Keep the Why section's framing-pivot statement explicit ("the framing adopted is X; the framing it replaces is Y") per AGENTS.md §4.6.
- Negative-framing language ("compendium does not own ...", "task manager / calendar / reminders / inbox are out of scope") is REQUIRED in Alternatives Considered and Consequences per BOUND-03 audit semantics — those mentions are correct content and the Phase 12 audit (Plan 12-04) annotates them as `negative-framing`.
- Do NOT use wikilinks anywhere in this body. Body links use plain markdown to match Phase 6 + Phase 11 DR precedent for non-wiki references.
  </action>
  <verify>
    <automated>test -f wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md && grep -c '^## \(TL;DR\|Decision\|Why\|Alternatives Considered\|Consequences\|Affected Pages\|Sources\)$' wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md | grep -q '^7$' && bash bin/lint.sh --category yaml,provenance >/dev/null 2>&1</automated>
  </verify>
  <acceptance_criteria>
    - File exists: `test -f wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md` returns exit 0.
    - Filename matches the dr-YYYY-MM-DD-slug convention from AGENTS.md §4.6: `grep -E '^dr-2026-05-01-complementary-systems-boundary\.md$' <(ls wiki/decisions/) | wc -l` returns 1.
    - All 7 required sections present at H2 level: `grep -c '^## \(TL;DR\|Decision\|Why\|Alternatives Considered\|Consequences\|Affected Pages\|Sources\)$' wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md` returns exactly `7`.
    - Frontmatter has `type: decision`: `grep -c '^type: decision$' wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md` returns 1.
    - Frontmatter has `trigger_type: schema-update`: `grep -c '^trigger_type: schema-update$' wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md` returns 1.
    - Frontmatter has `affected_pages: []`: `grep -c '^affected_pages: \[\]$' wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md` returns 1.
    - Frontmatter has `id: dr-2026-05-01-complementary-systems-boundary`: `grep -c '^id: dr-2026-05-01-complementary-systems-boundary$' wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md` returns 1.
    - `id:` matches filename per AGENTS.md §5 rule 10.
    - Frontmatter has `epistemic_status: sourced`: `grep -c '^epistemic_status: sourced$' wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md` returns 1.
    - Frontmatter has `privacy: cloud_safe`: `grep -c '^privacy: cloud_safe$' wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md` returns 1.
    - Lint passes for the new file: `bash bin/lint.sh --category yaml,provenance` exits 0.
    - "Why" section explicitly contrasts compendium ownership vs complementary-system ownership: `awk '/^## Why$/,/^## Alternatives Considered$/' wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md | grep -Ei 'compendium|durable' | head -1 | wc -l` returns 1, AND the same range matches `grep -Ei 'task|calendar|reminder' | head -1 | wc -l` returns 1 (presence test — both ownership halves named in negative-framing form).
    - "Alternatives Considered" names "all-in-one PKM/task system": `awk '/^## Alternatives Considered$/,/^## Consequences$/' wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md | grep -Ei 'all-in-one' | wc -l` returns at least 1.
    - "Alternatives Considered" names the v2 deferral rejection: `awk '/^## Alternatives Considered$/,/^## Consequences$/' wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md | grep -Ei 'v2|defer' | wc -l` returns at least 1.
    - "Alternatives Considered" names the README-only rejection: `awk '/^## Alternatives Considered$/,/^## Consequences$/' wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md | grep -Ei 'README' | wc -l` returns at least 1.
    - Sources section cites the three origin notes: `awk '/^## Sources$/,0' wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md | grep -c '2026-04-24' ` returns at least 3.
    - Sources section cites the new ref doc: `grep -c 'docs/reference/three-layer-model.md' wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md` returns at least 1.
    - No wikilinks in frontmatter (per AGENTS.md §3): `awk '/^---$/{c++} c==1{print} c==2{exit}' wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md | grep -c '\[\[' ` returns 0.
    - Forbidden-patterns reminder comment present: `grep -c 'FORBIDDEN PATTERNS (see AGENTS.md section 3)' wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md` returns 1.
  </acceptance_criteria>
  <done>
    Decision record file exists at `wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md`, conforms to AGENTS.md §4.6 (frontmatter + 7 sections), passes `bash bin/lint.sh --category yaml,provenance`, and matches all acceptance criteria above.
  </done>
</task>

</tasks>

<verification>
- File exists at the locked path with the locked filename.
- Frontmatter passes `bin/lint.sh --category yaml,provenance` (no required-field gaps, no wikilinks in YAML).
- All 7 required sections present at H2.
- Three locked alternatives appear in Alternatives Considered (D-18 contract).
- Why section names both ownership halves (compendium = durable; complementary = task/calendar/reminders) per BOUND-01 acceptance.
- Sources cites the three `.planning/notes/2026-04-24-*.md` files + REQUIREMENTS.md + ROADMAP.md + the new ref doc.
- No wikilinks in frontmatter; first-mention-only enforced for the new ref doc cross-link.
</verification>

<success_criteria>
- `wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md` exists and passes lint (yaml + provenance categories).
- Body matches the BOUND-01 narrative requirements: durable synthesis ownership stated explicitly; complementary-system ownership of executable commitments / reminders / calendars / transactional state stated explicitly; three locked alternatives all rejected with rationale.
- The file is referenced by Plan 12-02 (the new ref doc cites this DR by ID) and Plan 12-03 (wiki/index.md Decisions entry, wiki/log.md reflect entry name this DR's slug).
</success_criteria>

<output>
After completion, this DR is consumed by:
- Plan 12-02 (ref doc cites BOUND-01 DR by ID `dr-2026-05-01-complementary-systems-boundary`).
- Plan 12-03 (wiki/index.md Decisions section adds bullet for this DR; wiki/log.md reflect entry names this DR by slug).
- Plan 12-04 (reviewed-match audit grep scans this file's body — Alternatives Considered + body matches must all be `negative-framing` per BOUND-03; the audit annotates and verdicts each match in 12-VERIFICATION.md).
</output>
