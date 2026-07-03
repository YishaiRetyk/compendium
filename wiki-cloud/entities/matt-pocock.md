---
id: matt-pocock
title: "Matt Pocock"
type: entity
status: active
summary: "Developer educator and author of the popular 'Matt Pocock Skills' engineering
  skill set, who proposed a four-part skill checklist (Trigger, Structure, Steering,
  Pruning) for writing and auditing agent skills and a prefer-user-invoked, keep-SKILL.md-small
  authoring stance framed as the way out of 'skill hell.'"
created_at: 2026-07-03
updated_at: 2026-07-03
sources:
- src-2026-07-03-building-great-agent-skills
epistemic_status: sourced
tags:
- ai-engineer
- agent-skills
- skill-authoring
- developer-educator
- prompt-engineering
domains:
- ai-agents
- software
supersedes: null
superseded_by: null
aliases:
- "Matt Pocock"
- "matt-pocock"
has_contradictions: false
knowledge_domain: software
example: false
---

# Matt Pocock

## TL;DR

Matt Pocock is a developer educator and the author of "Matt Pocock Skills," which he describes as one of the most popular engineering [[agent-skills|Agent Skills]] sets. In an AI Engineer talk delivered remotely ("The Missing Manual, How to Write Great Skills") he diagnosed "skill hell" — an abundance of shareable skills with no shared rubric to tell good from bad — and answered it with the four-part [[skill-checklist|Skill Checklist]] (Trigger, Structure, Steering, Pruning). His authoring stance is opinionated: prefer *user-invoked* skills to keep the agent's context load small and remove model-invocation unpredictability, keep `SKILL.md` as small as possible, steer with *leading words*, and prune *sediment* and *no-ops*. He publishes the AI Hero newsletter at aihero.dev.

## Key Facts

- Author of "Matt Pocock Skills," which he frames as "one of the most popular engineering skill sets out there" (repo: `github.com/mattpocock/skills`) [prov:src-2026-07-03-building-great-agent-skills#t00:01:37-00:01:52|direct|2026-07-03] [epistemic:: tentative]
- Proposed a four-part skill checklist — Trigger, Structure, Steering, Pruning — as a shared rubric for judging and improving agent skills, and packaged it as a `writing-great-skills` skill in his repo [prov:src-2026-07-03-building-great-agent-skills#t00:02:20-00:03:11|direct|2026-07-03] [epistemic:: tentative]
- Prefers *user-invoked* over *model-invoked* skills: it keeps the agent's context load small and removes the unpredictability of a model that may decline to follow a context pointer, at the cost of higher cognitive load on the "pilot" [prov:src-2026-07-03-building-great-agent-skills#t00:06:02-00:07:15|direct|2026-07-03] [epistemic:: tentative]
- Champions *leading words* — short, meaning-dense phrases (e.g. "vertical slice") repeated in a skill so the agent echoes them into its reasoning traces — as the central steering lever [prov:src-2026-07-03-building-great-agent-skills#t00:12:17-00:14:14|direct|2026-07-03] [epistemic:: tentative]
- Keeps skills small with deletion tests, single-source-of-truth discipline, and removing "sediment" and "no-ops" [prov:src-2026-07-03-building-great-agent-skills#t00:18:55-00:19:05|direct|2026-07-03] [epistemic:: tentative]
- Publishes the AI Hero newsletter at aihero.dev and planned an "AI coding crash course" [prov:src-2026-07-03-building-great-agent-skills#t00:20:15-00:20:30|direct|2026-07-03] [epistemic:: tentative]

## Detail

Pocock's contribution to this wiki is a practitioner's authoring rubric for [[agent-skills|Agent Skills]] that complements Anthropic's official best-practices guidance. Where the Anthropic docs describe the mechanism (three-level [[progressive-disclosure|Progressive Disclosure]], `SKILL.md` frontmatter, degrees of freedom), Pocock supplies a diagnostic checklist and a working vocabulary — "skill hell," user-invoked vs model-invoked triggers, *context pointers*, *leading words*, *legwork per step*, *sediment*, and *no-ops* — captured on the [[skill-checklist|Skill Checklist]] page [prov:src-2026-07-03-building-great-agent-skills#t00:02:11-00:19:53|direct|2026-07-03]. His stated design bias is control over flexibility: he contrasts his mostly user-invoked skills with [[superpowers|Superpowers]], which he characterizes as primarily model-invoked, and argues that removing model-invocation unpredictability is worth the extra cognitive load it places on the human pilot [prov:src-2026-07-03-building-great-agent-skills#t00:06:02-00:07:15|direct|2026-07-03] [epistemic:: tentative].

## Related Pages

- [[skill-checklist|Skill Checklist]] — the four-part authoring rubric he proposed.
- [[agent-skills|Agent Skills]] — the artifact his rubric is about.
- [[superpowers|Superpowers]] — the model-invoked skill set he contrasts his approach with.
- [[progressive-disclosure|Progressive Disclosure]] — the loading discipline his "context pointer" and minimal-`SKILL.md` advice operationalize.

## Sources

- [[src-2026-07-03-building-great-agent-skills|Building Great Agent Skills: The Missing Manual — Matt Pocock]] — AI Engineer talk, 2026-06-29 (YouTube transcript)
