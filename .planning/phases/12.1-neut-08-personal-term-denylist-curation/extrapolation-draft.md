# Phase 12.1 — Claude-extrapolated curation draft

**Source:** .planning/backlog-neutrality-denylist-candidate.txt (855 candidate lines) + sources/2026/2026-04/2026-04-10-personal-decision-journal/source.md (direct review of archived journal text)
**Calibration anchor:** .planning/phases/12.1-neut-08-personal-term-denylist-curation/calibration-decisions.txt (20 binary signals — 0 keep / 20 skip)
**Rubric (revised):** SPEC §Constraints baseline (proper noun / personal name / project codename / hyphenated identifier unique to vault) **plus defense-in-depth extension** for (a) spaced multi-word phrases coined in archived journal sources (precedent: existing denylist uses spaced forms `loss aversion`, `system 1`, `cognitive biases`) and (b) popular cog-bias terms heavily used in the user's archived journal that would betray vault provenance if they appeared in public template paths via LLM-mediated example-leak. Generic single-word English vocabulary still rejected.

## Kept (7 terms)

- `pre-committing` — gerund extension of already-denied pre-committed/pre-commitment; completes verb-form coverage of a vault-coined practice
- `physical flinch` — spaced multi-word phrase coined in the personal-decision-journal as the vault-distinctive label for the affective tell preceding a decision; precedent: existing denylist already uses spaced forms (loss aversion, system 1)
- `pre-mortem` — popular cog-bias term used heavily in the journal source; if it appears in the public template, it almost certainly signals vault content was used as input (defense-in-depth against LLM-mediated example-leak)
- `pre-mortems` — plural form of pre-mortem; same defense-in-depth rationale
- `decision fatigue` — spaced popular cog-bias term used heavily in the journal source; defense-in-depth — would betray vault provenance in public paths
- `decision-fatigue` — hyphenated form of decision fatigue (substring-match parser does not collapse hyphenation, so both forms are needed)
- `meta-observation` — phrase used in the journal source as the vault-distinctive label for the user's reflective layer ("the meta-observation from the week...")

## Rejected (602 terms)

### Class: generic-english (545 terms)

- ability, above, accept, across, action, active, actual, actually, addition, after, agents, aliases, already, anchor, anchoring, angles, answer, anything, app, appear
- appeared, applies, apply, applying, approach, argument, around, articulate, articulation, artifact, asked, asking, assumed, author, authors, autopilot, aversion, averted, avoid, avoiding
- away, batching, because, been, before, behavior, behavioral, behind, being, belief, below, between, bias, biased, biases, broke, buy, buying, called, calling
- cap, carefully, case, cases, catching, cause, cc535d138d427a9297d65e7ebf73418f6af5009e164e1f6a3391c4f26fab90a7, change, changes, checkout, choices, chosen, clear, clever, closed, closing, cluster, clusters, codex, cognitive
- commitments, committed, compiled, concept, concepts, concern, conclusion, concrete, condition, considered, context, continuing, contributes, conversation, correspond, corresponds, counter, countering, counterpart, counterparty
- courtesy, covering, creates, crystallize, crystallizing, daily, date, day, decided, deciding, default, defaults, deferred, definitely, delegated, deleted, deleting, deliberate, deliberately, deliberation
- derived, desire, destination, detail, deterministic, did, different, difficult, direct, discovering, distinct, does, domains, down, downstream, draft, drops, each, earlier, eight
- else, emerged, ended, endorse, epistemic, everyday, exercise, existing, experiential, experiment, experiments, explain, explained, explains, explicit, explicitly, extracted, extraction, fact, facts
- fail, failed, fails, failure, fair, false, fatigue, feel, feels, felt, fifteen, find, finds, first, fixed, flinch, flinches, follows, force, formed
- forward, four, frame, framework, frameworks, framing, fresh, freshly, fully, future, general, generalized, going, granularity, handed, happen, happening, harder, having, heuristic
- hold, holds, ideas, identical, identification, identify, identifying, imagining, immediate, improving, incident, indistinguishable, individual, inevitable, inferred, ingest, ingested, inheritance, instant, instead
- instruction, integrating, intended, internal, interrupt, interrupted, interrupting, interrupts, intervention, interventions, introspect, introspecting, items, judgment, keep, keeping, kept, key, kicks, knew
- known, labeled, land, later, layer, learnings, leaving, less, lesson, life, like, lines, list, literature, live, lived, locators, log, loss, loud
- making, markers, material, matter, may, meaningful, memory, merge, merged, merging, metadata, middle, modes, moment, month, months, more, morning, most, motivation
- move, narrative, narrower, negotiate, negotiation, new, next, nine, none, notice, noticeably, noticed, noticing, novel, novelty, number, numbering, observation, observations, observed
- occupy, offload, old, older, ones, open, opened, opening, operate, operational, operationally, option, organizing, outbound, outcome, overview, overviews, own, owner, paired
- paper, para, pass, path, pattern, patterns, per, percent, phases, physical, physically, plans, point, politeness, possible, postponing, practical, practice, precedes, preserves
- pressure, previously, prior, private, problem, produced, productivity, progress, project, projects, promoted, proposed, prov, provenance, psychology, published, pull, pulling, purchase, purchases
- quality, question, quiet, quit, ran, rather, rationale, rationalization, rationalize, reaches, reaching, read, reading, real, reason, reasoning, reasons, receives, recognized, recommendation
- recurring, reference, referenced, reflection, reflective, reflex, reframe, refusing, regarding, registered, related, remembering, reply, reports, required, research, reserved, reserving, reset, response
- restate, result, returned, returning, review, risk, roughly, routing, rule, run, running, salary, same, scope, second, seconds, section, sections, seeing, seems
- sensation, sense, sentence, separate, separated, seven, sha256, shape, shared, showed, shut, shutdown, shutting, side, signature, situations, six, size, skills, slightly
- slot, slots, small, snapping, social, solve, solved, solving, someone, sourced, specific, specifically, spent, stacked, stalled, stand, starting, starts, state, stated
- status, strength, structural, subjectively, substantially, successful, suggested, summary, sunk, supersedes, surface, surfaced, surprising, synthesis, system, systematized, tab, tags, take, takeaways
- takes, target, targeted, targeting, targets, technique, tell, test, textbook, there, therefore, these, things, third, those, threads, three, threshold, tier, time
- title, together, token, told, tractable, training, treating, triggers, trying, twenty, type, typed, unable, underlying, unopposed, url, used, useful, valuable, vault
- visibly, walk, walked, walking, want, wednesday, week, weeks, whereas, whether, whole, wikilink, within, work, worked, working, works, worth, writing, written
- wrong, wrote, years, yet, zero

### Class: ambiguous-not-vault-specific (46 terms)
Hyphenated/multi-word phrases that look distinctive but are widely used outside this vault (popular cog-bias terms, common idioms, generic time-spans). Note: under the revised defense-in-depth rubric, `pre-mortem`/`pre-mortems` were promoted from this class to Kept; other popular-but-not-vault-specific terms remain rejected because they are not heavily-enough used in the journal source to risk betraying vault provenance.

- after-the-fact, already-sunk, contract-rate, counter-offer, counter-offering, decision-fatigue, decision-frameworks, decision-making, downstream-family, dual-process, eight-month, first-person, five-minute, four-decision, four-to-five, freshly-considered, general-knowledge, high-severity, in-the-moment, journal-entry
- long-running, loss-aversion-based, low-stakes, non-recurring, one-to-one, paragraph-level, personal-development, personal-goals, pre-decision, pre-formed, pre-made, pre-reasoning, productivity-app, read-about, real-life, real-time, salary-negotiation, self-diagnosis, single-decision, source-creation
- stalled-project, sunk-cost, system-1-vs-system-2, two-week, utterance-level, week-long

### Class: off-rubric (11 terms)
Already covered by the existing Phase 7 NEUT-08 starter category (+ Kahneman category) — adding would create duplicate denylist entries; or would FP on the live public tree.

- articulate-the-want, autopilot-purchase, cognitive-biases, flinch-level, heuristic-origin, loss-aversion, personal-decision-journal, personal-decision-patterns, pre-commitment, pre-committed, src-2026-04-10-personal-decision-journal

## Summary
- Total candidates: 606 unique tokens (855 raw lines including duplicates across clusters) + 2 spaced phrases discovered via direct journal review (`physical flinch`, `decision fatigue`)
- Kept: 7
- Rejected: 602 (generic-english=545 + ambiguous-not-vault-specific=46 + off-rubric=11)
- Per-cluster contribution to kept-list (in-file tokens only): agents-md-size-risk.md=0, personal-decision-patterns.md=4, personal-decision-journal.md=0
- Spaced phrases sourced from journal review (not in token candidate file): physical flinch (1), decision fatigue (1)
- Note: per RESEARCH.md A1, the agents-md-size-risk cluster (19 generic single-word tokens) yielded 0 promotions as expected.
- Note: rubric revision rationale — Phase 7 already promoted the 9 strongest hyphenated vault-coined terms; the candidate-file-only approach exhausted obvious additions. The revised rubric extends to (a) spaced phrases coined in archived journal sources and (b) popular cog-bias terms used heavily by the user, on the basis that LLM-mediated authoring is the dominant leak vector and Claude pattern-matches on what's heavily present in the user's repo. All 7 kept terms pre-screen as 0-hit on the live public tree (FP-safe).
- Note: per MEDIUM #3 from REVIEWS.md, this kept-count is a sanity check; Plan 04 re-derives N from `git diff <phase-base>..HEAD -- .neutrality-denylist.txt | grep -cE '^\+[^#+]'` as the single source of truth.
