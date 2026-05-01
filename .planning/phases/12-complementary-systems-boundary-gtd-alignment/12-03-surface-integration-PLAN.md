---
id: 12-03-surface-integration
plan_id: 12-03
phase: 12
plan: 03
wave: 2
type: execute
depends_on:
  - 12-01-decision-record
  - 12-02-reference-doc
files_modified:
  - README.md
  - docs/reference/index.md
  - wiki/index.md
  - wiki/log.md
requirements:
  - BOUND-02
  - BOUND-03
autonomous: true
must_haves:
  truths:
    - "README.md gains exactly one new contextual pointer sentence under the existing 'What this is' section, referencing docs/reference/three-layer-model.md."
    - "docs/reference/index.md gains a single bullet entry listing the new three-layer-model.md."
    - "wiki/index.md Decisions section gains a single bullet for dr-2026-05-01-complementary-systems-boundary."
    - "wiki/log.md gains one new reflect entry (newest at bottom, append-only) recording the Phase 12 boundary work."
  artifacts:
    - path: README.md
      provides: "Single contextual pointer sentence at end of 'What this is' section"
      contains: "docs/reference/three-layer-model.md"
    - path: docs/reference/index.md
      provides: "Bullet entry pointing at the new ref doc"
      contains: "three-layer-model.md"
    - path: wiki/index.md
      provides: "Decisions section bullet for the new DR"
      contains: "dr-2026-05-01-complementary-systems-boundary"
    - path: wiki/log.md
      provides: "Phase 12 reflect entry per AGENTS.md §11.4 step 6 / §12"
      contains: "Phase 12 complementary-systems boundary"
  key_links:
    - from: README.md
      to: docs/reference/three-layer-model.md
      via: "markdown link in 'What this is' section"
      pattern: "docs/reference/three-layer-model.md"
    - from: docs/reference/index.md
      to: docs/reference/three-layer-model.md
      via: "bullet entry"
      pattern: "three-layer-model.md"
    - from: wiki/index.md
      to: wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md
      via: "Decisions section wikilink"
      pattern: "dr-2026-05-01-complementary-systems-boundary"
---

<objective>
Wire the new BOUND-01 decision record and BOUND-02 reference doc into the canonical surface points: (1) one contextual pointer sentence in README.md "What this is" section per D-09 / D-10 (locked wording); (2) one bullet in docs/reference/index.md per D-11; (3) one Decisions-section entry in wiki/index.md per AGENTS.md §11.4 step 5; (4) one reflect entry appended to wiki/log.md per AGENTS.md §11.4 step 6 / §12.

Purpose: Discoverability — the boundary is reachable from the README entry point, from the docs reference index, from the wiki Decisions catalog, and from the chronological log. Required deliverables for BOUND-02 acceptance (index entry) and BOUND-03 acceptance (README pointer + audit baseline).
Output: Four surgical edits, each touching exactly the lines specified — no structural changes elsewhere.
</objective>

<context>
@.planning/phases/12-complementary-systems-boundary-gtd-alignment/12-SPEC.md
@.planning/phases/12-complementary-systems-boundary-gtd-alignment/12-CONTEXT.md
@README.md
@docs/reference/index.md
@wiki/index.md
@wiki/log.md
@AGENTS.md
@wiki/decisions/dr-2026-04-15-kahneman-to-examples.md
</context>

<threat_model>
N/A — pure docs phase. This plan adds a single sentence to README.md and bullets/entries to existing index files; no executable code paths, no API surface, no new attack surface. The neutrality CI gate (bin/check-neutrality.sh) and privacy-leak guard (bin/check-privacy.sh) continue to pass — added content does not introduce creator-specific terms or local_only frontmatter into public paths.
</threat_model>

<tasks>

<task type="auto" tdd="false">
  <name>Task 1: Add README pointer + docs/reference/index.md bullet</name>
  <files>README.md, docs/reference/index.md</files>
  <read_first>
    - README.md (read full file — pointer goes at the end of the existing "What this is" section, immediately after the existing "Unlike search-over-notes ..." paragraph, BEFORE "## Who this is for")
    - docs/reference/index.md (read full file — new bullet inserted into the existing flat bullet list, alphabetical / position-of-similar-docs)
    - .planning/phases/12-complementary-systems-boundary-gtd-alignment/12-CONTEXT.md (D-09 placement, D-10 locked wording, D-11 index bullet wording)
    - .planning/phases/12-complementary-systems-boundary-gtd-alignment/12-SPEC.md (BOUND-03 audit semantics — README wording must NOT trigger the bounded `replaces|replacement for` audit pattern; D-10 wording is pre-vetted)
  </read_first>
  <action>
**Edit 1 — README.md (single new sentence):**

Locate the existing "What this is" section. The section ends with the paragraph beginning "Unlike search-over-notes or chat-on-top-of-PDFs, the result is a persistent artifact. ..." That paragraph ends with "The vault gets more useful as you ingest more material and ask better questions."

Append a NEW paragraph (single sentence per D-10, exact wording locked):

```
Compendium is the durable wiki-memory layer of a multi-system stack — it complements a task / GTD backend rather than substituting for one. See [docs/reference/three-layer-model.md](docs/reference/three-layer-model.md) for the boundary and routing rules.
```

Place this NEW paragraph after the existing "Unlike search-over-notes ..." paragraph (so it is the last paragraph in the "What this is" section), and BEFORE the `## Who this is for` H2 line.

The wording is locked (D-10) to avoid tripping the bounded `(replaces|replacement for)` audit regex from D-12 — do NOT substitute "replaces" or "replacement for" or any variant. Use the literal sentence above.

**Edit 2 — docs/reference/index.md (single new bullet):**

Add a single bullet to the existing flat bullet list at top-level (currently 6 bullets: schema-tour, brownfield, privacy-model, ci, examples, release). Insert the new bullet for `three-layer-model.md`. Recommended placement: after `privacy-model.md` (the closest sibling reference doc style-wise per D-01 framing), but anywhere in the existing top-level list is acceptable as long as it appears as a single bullet.

Use the locked wording from D-11 (operator may lightly polish):

```
- [three-layer-model.md](three-layer-model.md) — The 3-layer model and complementary-systems boundary.
```

Do NOT modify any other bullet, and do NOT add a `(Phase 12)` parenthetical (the existing bullets use that suffix to mark planned work; this doc is being shipped, not planned).

Do NOT touch the `## Contributing` section.
  </action>
  <verify>
    <automated>grep -c 'docs/reference/three-layer-model.md' README.md | grep -q '^1$' && grep -c 'three-layer-model.md' docs/reference/index.md | grep -q '^[12]$' && awk '/^## What this is$/,/^## Who this is for$/' README.md | grep -c 'docs/reference/three-layer-model.md' | grep -q '^1$'</automated>
  </verify>
  <acceptance_criteria>
    - README.md contains exactly one new pointer line referencing the new ref doc: `grep -c 'docs/reference/three-layer-model.md' README.md` returns exactly `1`.
    - The pointer sits inside the "What this is" section (between `## What this is` and `## Who this is for`): `awk '/^## What this is$/,/^## Who this is for$/' README.md | grep -c 'docs/reference/three-layer-model.md'` returns exactly `1`.
    - The pointer wording matches D-10 verbatim — uses "complements" and "substituting for" (positive framing per D-10 to avoid the bounded `(replaces|replacement for)` audit regex): `grep -c 'complements a task / GTD backend rather than substituting for one' README.md` returns exactly `1`.
    - The pointer does NOT use the bounded `(replaces|replacement for) (a |an |your )?(task|gtd|todo|reminder|calendar|inbox)` pattern from D-12: `grep -Eic '(replaces|replacement for) (a |an |your )?(task|gtd|todo|reminder|calendar|inbox)' README.md` returns 0.
    - docs/reference/index.md gains a bullet for three-layer-model.md: `grep -Ec '^- \[three-layer-model\.md\]\(three-layer-model\.md\)' docs/reference/index.md` returns exactly `1`.
    - docs/reference/index.md still contains all 6 pre-existing reference doc bullets (no accidental deletions): `grep -cE '^- \[(schema-tour|brownfield|privacy-model|ci|examples|release)\.md\]' docs/reference/index.md` returns exactly `6`.
    - README.md still contains the 'What this is' H2: `grep -c '^## What this is$' README.md` returns 1.
    - README.md still contains the existing 'Unlike search-over-notes' anchor paragraph (no accidental deletion): `grep -c 'Unlike search-over-notes or chat-on-top-of-PDFs' README.md` returns 1.
  </acceptance_criteria>
  <done>
    README.md contains exactly one new contextual pointer sentence (D-10 locked wording) inside the "What this is" section pointing at `docs/reference/three-layer-model.md`. docs/reference/index.md gains a single bullet entry for `three-layer-model.md`. No other content changed in either file.
  </done>
</task>

<task type="auto" tdd="false">
  <name>Task 2: Add wiki/index.md Decisions entry + wiki/log.md reflect entry</name>
  <files>wiki/index.md, wiki/log.md</files>
  <read_first>
    - wiki/index.md (read full file — Decisions section currently has 4 bullets; the new bullet appends after the most recent dr-2026-04-20-brownfield entry, mirroring its bullet shape exactly)
    - wiki/log.md (read full file — newest-at-bottom append-only; new reflect entry goes at EOF after the latest 2026-04-30 lint entry, leaving a blank line above)
    - .planning/phases/12-complementary-systems-boundary-gtd-alignment/12-CONTEXT.md (integration-points note: wiki/index.md Decisions entry + wiki/log.md reflect entry are required deliverables per Review-Driven Amendments)
    - AGENTS.md §11.4 step 5 (after a new DR lands, update wiki/index.md Decisions section)
    - AGENTS.md §11.4 step 6 + AGENTS.md §12 (append a single reflect entry to wiki/log.md per the locked log format; entries are newest-at-bottom append-only)
    - wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md (must exist from Plan 12-01 — read its `title:` frontmatter to confirm canonical title for the wikilink target shape; read its `summary:` for the index-bullet's one-line summary text)
  </read_first>
  <action>
**Edit 1 — wiki/index.md (single new bullet under existing `## Decisions` section):**

The current `## Decisions` section has 4 bullets, the most recent being:

```
- [[Brownfield Apply-vs-Advisory Architecture + Review-Manifest Pattern]] — Captures the apply-class vs advisory-class split, review-manifest pattern, bootstrap_stage lifecycle gate, and cross-AI review-feedback hardenings (items 1–11) (sourced, 2026-04-20)
```

Note that the existing entries use TWO bullet shapes:
1. The first three use `[[dr-YYYY-MM-DD-slug]]` (the canonical slug as wikilink target, with display alias-free shape).
2. The fourth uses `[[Title]]` (the human-readable title as wikilink target).

Both shapes are valid Obsidian wikilinks (Obsidian resolves either via `id`/filename or `title` matching). However, AGENTS.md §3 forbids display aliases (`[[Title|alt]]`) but allows `[[Title]]` and `[[id]]` equally. The new bullet should match the **canonical-slug** shape used by the FIRST THREE existing entries (the most common pattern), since that shape is unambiguous about which file it references and matches the `dr-YYYY-MM-DD-slug` filename precedent from AGENTS.md §4.6.

Append exactly one new bullet at the end of the `## Decisions` section (after the dr-2026-04-20 entry):

```
- [[dr-2026-05-01-complementary-systems-boundary]] — Compendium owns durable, provenance-backed wiki memory and review support; complementary systems own task execution, reminders, calendars, and transactional state. (sourced, 2026-05-01)
```

Format breakdown (per AGENTS.md §12):
- `[[dr-2026-05-01-complementary-systems-boundary]]` — wikilink to the canonical slug (matches filename and `id:` field).
- ` — ` — em-dash separator (UTF-8 em-dash, NOT three hyphens).
- One-line summary derived from the DR's `summary:` frontmatter, lightly compressed.
- ` (sourced, 2026-05-01)` — `(<epistemic_status>, <updated_at>)` per AGENTS.md §12 index bullet format.

Do NOT modify any of the 4 pre-existing Decisions bullets. Do NOT touch any frontmatter fields (the `neutrality_exempt: true` exemption stays).

**Edit 2 — wiki/log.md (single new reflect entry appended at EOF):**

The current log ends with two consecutive `## [2026-04-30] lint | wiki health check` entries (the second one is a duplicate but neither agent should edit those — AGENTS.md §3 prohibits log rewrites). Append a NEW reflect entry at the bottom of the file, separated from the previous entry by exactly one blank line.

Use this format (per AGENTS.md §12 base log entry shape; entries describe what / when / brief rationale):

```

## [2026-05-01] reflect | Phase 12 complementary-systems boundary

Created decision record [[dr-2026-05-01-complementary-systems-boundary]] (`trigger_type: schema-update`, `affected_pages: []`) capturing that compendium owns durable, provenance-backed wiki memory and review support, while complementary systems own task execution, reminders, calendars, and transactional state. Created `docs/reference/three-layer-model.md` with the 3-layer model, capture/clarify/organize/review routing table, and anti-features section. Added README pointer under "What this is", `docs/reference/index.md` bullet, and the Decisions entry above. Closes BOUND-01, BOUND-02, BOUND-03; unblocks the CLOSE-04 scope-leak gate for v1.1 closure.
```

The leading blank line is intentional — it separates the new entry from the prior `## [2026-04-30] lint | wiki health check` block.

The DR is linked ONCE via wikilink (first-mention-only per AGENTS.md §8 rule 2); the ref doc and README references use plain markdown / inline backticks (they are not wiki pages, so wikilinks do not apply to them).

Do NOT use `contributor::` field — this repo is single-author per `git log --all --format='%ae' | sort -u | wc -l` (AGENTS.md §11.1 step 9a single-author-omit rule). If verification later determines this repo is multi-author, the field can be added — but per current state, the field is correctly omitted.

Do NOT modify any pre-existing log entries (append-only per AGENTS.md §3).
  </action>
  <verify>
    <automated>grep -c 'dr-2026-05-01-complementary-systems-boundary' wiki/index.md | grep -q '^1$' && awk '/^## Decisions$/,0' wiki/index.md | grep -c '^- \[\[dr-2026-05-01-complementary-systems-boundary\]\]' | grep -q '^1$' && grep -c '^## \[2026-05-01\] reflect | Phase 12 complementary-systems boundary$' wiki/log.md | grep -q '^1$'</automated>
  </verify>
  <acceptance_criteria>
    - wiki/index.md gains exactly one new Decisions bullet for the BOUND-01 DR: `awk '/^## Decisions$/,0' wiki/index.md | grep -c '^- \[\[dr-2026-05-01-complementary-systems-boundary\]\]'` returns exactly `1`.
    - The new bullet uses the canonical-slug wikilink shape (no display alias): `awk '/^## Decisions$/,0' wiki/index.md | grep -Ec '\[\[dr-2026-05-01-complementary-systems-boundary\]\]( |$)'` returns at least `1`, AND `awk '/^## Decisions$/,0' wiki/index.md | grep -c '\[\[dr-2026-05-01-complementary-systems-boundary|'` returns 0 (no `|` display alias).
    - The new bullet ends with the locked epistemic_status + updated_at suffix: `awk '/^## Decisions$/,0' wiki/index.md | grep -Ec 'dr-2026-05-01-complementary-systems-boundary.*\(sourced, 2026-05-01\)'` returns at least `1`.
    - The 4 pre-existing Decisions bullets are unchanged: `awk '/^## Decisions$/,0' wiki/index.md | grep -c '^- \[\[' ` returns exactly `5` (4 existing + 1 new).
    - wiki/log.md gains exactly one new entry header for the Phase 12 reflect: `grep -c '^## \[2026-05-01\] reflect | Phase 12 complementary-systems boundary$' wiki/log.md` returns exactly `1`.
    - The new log entry contains a wikilink to the new DR (first-mention-only): `awk '/^## \[2026-05-01\] reflect/,0' wiki/log.md | grep -Ec '\[\[dr-2026-05-01-complementary-systems-boundary\]\]'` returns at least `1`.
    - The new log entry references the new ref doc by relative path: `awk '/^## \[2026-05-01\] reflect/,0' wiki/log.md | grep -Ec 'docs/reference/three-layer-model\.md'` returns at least `1`.
    - The new log entry mentions BOUND-01, BOUND-02, BOUND-03: `awk '/^## \[2026-05-01\] reflect/,0' wiki/log.md | grep -Ec 'BOUND-01.*BOUND-02.*BOUND-03|BOUND-01, BOUND-02, BOUND-03'` returns at least `1`.
    - wiki/log.md is still newest-at-bottom append-only (no pre-existing entries removed): `grep -c '^## \[' wiki/log.md` increases by exactly 1 compared to pre-Plan-12-03 baseline (i.e., from 4 to 5 entry headers if the two duplicate 2026-04-30 entries are both kept).
    - No `contributor::` field added (single-author repo per single-author-omit rule): `grep -c '^contributor::' wiki/log.md` returns 0 OR is unchanged from pre-edit count.
    - No pre-existing log entry text was modified: `git diff wiki/log.md | grep -c '^-' | tr -d ' '` returns 0 for non-context lines (only additions, no deletions).
  </acceptance_criteria>
  <done>
    wiki/index.md gains exactly one new Decisions section bullet for the BOUND-01 DR, in the canonical-slug wikilink shape with `(sourced, 2026-05-01)` suffix. wiki/log.md gains exactly one new `## [2026-05-01] reflect | Phase 12 complementary-systems boundary` entry appended at EOF, naming the DR by wikilink (first-mention) and referencing the new ref doc + the three closed REQ-IDs. No pre-existing content modified in either file.
  </done>
</task>

</tasks>

<verification>
- README.md "What this is" section contains exactly one new pointer line with the locked D-10 wording.
- docs/reference/index.md gains exactly one new bullet for three-layer-model.md.
- wiki/index.md Decisions section gains exactly one new bullet using the canonical-slug wikilink form.
- wiki/log.md gains exactly one new reflect entry at EOF, separated by a blank line, naming the DR via wikilink and the ref doc by relative path.
- No deletions or modifications to pre-existing content in any of the four files.
</verification>

<success_criteria>
- All 4 surface-integration edits land surgically (single sentence / single bullet / single entry each).
- README pointer wording matches D-10 verbatim and does NOT trigger the bounded `(replaces|replacement for)` audit pattern from D-12.
- The Decisions wikilink in wiki/index.md uses the canonical-slug form (`[[dr-2026-05-01-complementary-systems-boundary]]`), no display alias, no display pipe.
- The reflect log entry follows AGENTS.md §12 base format and §8 first-mention-only (DR linked once via wikilink in the entry body).
- After this plan, Plan 12-04's reviewed-match audit can scan all four files (README + docs/ + wiki/decisions/ + wiki/index.md is implicit via wiki/decisions/) and verdict every match correctly.
</success_criteria>

<output>
After completion, the surface integration is consumed by:
- Plan 12-04 (the reviewed-match audit greps over `README.md AGENTS.md docs/ wiki/decisions/` per D-13; the README pointer + ref doc anti-features section + DR Alternatives Considered are all expected hits, all verdicted `negative-framing`).
- Plan 12-04 (REQUIREMENTS.md status flips reference these surface points as evidence; VERIFICATION.md cites these file paths as proof of BOUND-02 / BOUND-03 closure).
</output>
