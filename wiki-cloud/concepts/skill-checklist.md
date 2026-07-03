---
id: skill-checklist
title: "Skill Checklist"
type: concept
status: active
summary: "Matt Pocock's four-part rubric for authoring and auditing agent skills — Trigger
  (user-invoked vs model-invoked), Structure (steps + reference, minimal SKILL.md, context
  pointers), Steering (leading words, legwork-per-step), and Pruning (single source of truth,
  sediment, no-ops) — framed as the way out of 'skill hell.'"
created_at: 2026-07-03
updated_at: 2026-07-03
sources:
- src-2026-07-03-building-great-agent-skills
epistemic_status: sourced
tags:
- agent-skills
- skill-authoring
- prompt-engineering
- context-engineering
- progressive-disclosure
domains:
- ai-agents
- software
supersedes: null
superseded_by: null
aliases:
- "Skill Checklist"
- "Skill Checklist Framework"
- "skill-checklist"
has_contradictions: false
knowledge_domain: software
example: false
---

## TL;DR

The Skill Checklist is [[matt-pocock|Matt Pocock]]'s four-part rubric for writing and auditing [[agent-skills|Agent Skills]], presented as the missing shared standard that lets you tell a good skill from a bad one — the way out of "skill hell." The four parts, in order: **Trigger** (is the skill *user-invoked* or *model-invoked*? — a trade of the agent's context load against the pilot's cognitive load); **Structure** (compose the skill from *steps* and *reference*, keep `SKILL.md` as small as possible, and push branch-specific reference behind *context pointers*); **Steering** (use *leading words* — short, meaning-dense phrases the agent echoes into its reasoning traces — and tune *legwork per step* by splitting a skill so the agent sees one step at a time); and **Pruning** (enforce a single source of truth and delete *sediment* and *no-ops*, using deletion tests). The framework is itself packaged as a `writing-great-skills` skill.

## Key Facts

- The checklist is a four-item rubric — Trigger, Structure, Steering, Pruning — for auditing an existing skill and for writing new ones, motivated by the absence of any shared standard for judging skill quality ("skill hell") [prov:src-2026-07-03-building-great-agent-skills#t00:01:52-00:02:53|direct|2026-07-03]
- **Trigger:** a *user-invoked* skill is invoked manually (its description can be hidden from the agent); a *model-invoked* skill puts its description in the agent's context so the agent may choose to load `SKILL.md` — model-invoked adds context load + unpredictability, user-invoked adds cognitive load on the pilot [prov:src-2026-07-03-building-great-agent-skills#t00:03:39-00:07:24|direct|2026-07-03] [epistemic:: tentative]
- **Structure:** most skills decompose into *steps* (the procedure) and *reference* (supporting info); keep the main `SKILL.md` as small as possible because tokens saved are per-request cost saved and small skills are easier to maintain and audit [prov:src-2026-07-03-building-great-agent-skills#t00:07:30-00:09:33|direct|2026-07-03] [epistemic:: tentative]
- Structure technique — hide branch-specific reference behind *context pointers* to bundled "external reference" files, so a skill used in many ways doesn't carry every branch's material in the main file [prov:src-2026-07-03-building-great-agent-skills#t00:09:33-00:11:39|direct|2026-07-03] [epistemic:: tentative]
- **Steering:** *leading words* are short phrases dense with meaning (e.g. "vertical slice") that, placed in a skill, the agent repeats into its reasoning traces and output — steering its behavior; the technique is verifiable by watching the traces [prov:src-2026-07-03-building-great-agent-skills#t00:12:17-00:14:14|direct|2026-07-03] [epistemic:: tentative]
- Steering technique — tune *legwork per step*: split a multi-step skill into separate skills so the agent sees one step at a time and does more work on it, because a hidden future goal stops it rushing ahead (his fix for plan mode's under-powered "ask clarifying questions" step) [prov:src-2026-07-03-building-great-agent-skills#t00:14:54-00:16:48|direct|2026-07-03] [epistemic:: tentative]
- **Pruning:** massive skills are a symptom; enforce a single source of truth (no duplication), remove *sediment* (accreted irrelevant/stale material from many contributors) and *no-ops* (instructions that don't change behavior), the latter found with a deletion test [prov:src-2026-07-03-building-great-agent-skills#t00:16:48-00:19:05|direct|2026-07-03] [epistemic:: tentative]

## Detail

The checklist exists to answer a specific gap: there are now more freely shared skills than anyone can evaluate, and no rubric for looking at a skill and deciding whether it is doing its job — a state [[matt-pocock|Matt Pocock]] calls "skill hell," the successor to "tutorial hell" and "framework hell" [prov:src-2026-07-03-building-great-agent-skills#t00:00:24-00:02:11|direct|2026-07-03] [epistemic:: tentative]. Each of the four parts is a lens plus one or two concrete techniques.

### 1. Trigger — who invokes the skill

Every skill can be *user-invoked* (the file sits on disk and the user tells the agent to use it, often via a forward-slash command whose exact form depends on the harness). A skill is additionally *model-invoked* when its description is placed in the agent's context: the agent reads the description and may decide to pull the `SKILL.md` body into its context window [prov:src-2026-07-03-building-great-agent-skills#t00:03:39-00:04:26|direct|2026-07-03]. That description is a **context pointer** — text in context pointing to a file the agent can read for more — and it is optional, so it can be hidden to make a skill user-invocable only (his "grill me" skill sets `disable model invocation: true`) [prov:src-2026-07-03-building-great-agent-skills#t00:04:26-00:05:07|direct|2026-07-03] [epistemic:: tentative].

The trade is symmetric, which is why the choice isn't free. Model-invoked skills look more flexible, but each one adds a description that costs tokens on every request and one more thing for the agent to weigh — 100 model-invoked skills is 100 descriptions permanently resident ("context load") — and each context pointer is *unpredictable*, because the model can decline to follow it even when the skill is perfect for the task, which forces authors to eval their skills to confirm they fire [prov:src-2026-07-03-building-great-agent-skills#t00:05:12-00:07:15|direct|2026-07-03] [epistemic:: tentative]. User-invoked skills remove that unpredictability but raise the *cognitive load* on the human pilot, who must remember the skills and understand them deeply. Pocock's own bias is user-invoked (control, minimal agent context), which he contrasts with [[superpowers|Superpowers]] as primarily model-invoked [prov:src-2026-07-03-building-great-agent-skills#t00:05:51-00:06:31|direct|2026-07-03] [epistemic:: tentative].

### 2. Structure — steps, reference, and a small SKILL.md

Most skills decompose into **steps** (the procedure the skill walks) and **reference** (supporting material for those steps); a skill can be all-steps or all-reference [prov:src-2026-07-03-building-great-agent-skills#t00:07:30-00:08:01|direct|2026-07-03]. His "2PRD" skill illustrates the shape: three steps (find context, confirm test seams with the user, write the PRD) plus two reference pieces (a note on test seams, a PRD template) [prov:src-2026-07-03-building-great-agent-skills#t00:08:01-00:08:37|direct|2026-07-03] [epistemic:: tentative].

The load-bearing rule is to keep the main `SKILL.md` as small as possible — fewer words to maintain and audit, and fewer tokens paid on every use [prov:src-2026-07-03-building-great-agent-skills#t00:08:52-00:09:33|direct|2026-07-03]. The lever is *branches*: reference material used in only one of a skill's branches should move out of the main file, behind a **context pointer** to a bundled "external reference" markdown file. A single-branch skill like 2PRD keeps its reference inline (every run needs it); a multi-branch skill like "domain modeling" (update a `context.md` glossary, or write an ADR, or neither) pushes its templates behind pointers so a given run loads only what it needs [prov:src-2026-07-03-building-great-agent-skills#t00:09:33-00:11:39|direct|2026-07-03] [epistemic:: tentative]. This is the same load-on-demand economics as [[progressive-disclosure|Progressive Disclosure]], stated as an authoring heuristic.

### 3. Steering — leading words and legwork

Steering addresses the common failure where a skill states something clearly and the agent still doesn't comply. Pocock's central technique is **leading words**: words or short phrases that pack dense meaning (he ties this to a literary-theory notion). Placed in the skill text, a leading word is repeated by the agent into its operations, thinking tokens, and output, and that re-emphasis changes behavior [prov:src-2026-07-03-building-great-agent-skills#t00:12:17-00:12:57|direct|2026-07-03] [epistemic:: tentative]. His example fixes agents' tendency to code "layer by layer" (whole database layer, then schemas, then endpoints, then front end): the leading word "vertical slice" — established dev terminology — triggers the model's priors to build a thin end-to-end slice instead. The phrase is repeated consistently through the skill, and the technique is *verifiable*: you can watch the reasoning traces adopt "thin vertical slice" and produce better plans [prov:src-2026-07-03-building-great-agent-skills#t00:12:57-00:14:14|direct|2026-07-03] [epistemic:: tentative].

The second lever is **legwork per step**: when the agent under-invests in a step (asking clarifying questions, exploring the codebase), splitting the skill so the agent sees only the current step forces more effort, because the hidden future goal stops it rushing ahead. His remedy for plan mode's weak "ask clarifying questions" phase is to break it into a standalone "grill with docs" skill that runs before "2PRD" [prov:src-2026-07-03-building-great-agent-skills#t00:14:54-00:16:48|direct|2026-07-03] [epistemic:: tentative].

### 4. Pruning — single source of truth, sediment, no-ops

Once a skill works, prune it. Massive skills are a symptom of the failure modes below [prov:src-2026-07-03-building-great-agent-skills#t00:16:48-00:17:05|direct|2026-07-03]:

- **Duplication** — give every part, including each reference, a single source of truth rather than repeating it across steps or files [prov:src-2026-07-03-building-great-agent-skills#t00:17:05-00:17:37|direct|2026-07-03].
- **Sediment** — the accretion that forms when many contributors add to a shared markdown file but nobody feels brave enough to delete others' work; fix it by looking at structure first, moving material into the right branches, and killing anything irrelevant or stale [prov:src-2026-07-03-building-great-agent-skills#t00:17:37-00:18:23|direct|2026-07-03].
- **No-ops** — instructions that look meaningful but don't change behavior (e.g. a paragraph telling the agent to write a long commit message it would write anyway); the test is deletion: remove the passage and check whether behavior changes [prov:src-2026-07-03-building-great-agent-skills#t00:18:23-00:19:05|direct|2026-07-03] [epistemic:: tentative].

The whole rubric is distributed as a `writing-great-skills` skill in the Matt Pocock skills repo, usable both to write new skills and to audit community-authored ones [prov:src-2026-07-03-building-great-agent-skills#t00:19:53-00:20:15|direct|2026-07-03] [epistemic:: tentative].

## Related Pages

- [[matt-pocock|Matt Pocock]] — the author of the checklist.
- [[agent-skills|Agent Skills]] — the artifact the checklist audits; carries Anthropic's official authoring guidance this rubric complements.
- [[progressive-disclosure|Progressive Disclosure]] — the loading discipline the "context pointer" and minimal-`SKILL.md` advice restate as authoring heuristics.
- [[superpowers|Superpowers]] — the primarily-model-invoked skill set the Trigger section contrasts against.
- [[context-engineering|Context Engineering]] — the broader discipline of managing what enters the context window that "context load" is an instance of.

## Sources

- [[src-2026-07-03-building-great-agent-skills|Building Great Agent Skills: The Missing Manual — Matt Pocock]] — AI Engineer talk, 2026-06-29 (YouTube transcript)
