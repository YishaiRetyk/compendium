---
id: src-2026-07-03-building-great-agent-skills
title: "Building Great Agent Skills: The Missing Manual — Matt Pocock"
type: source
status: active
summary: "A recorded conference talk by Matt Pocock giving a four-part 'skill checklist'
  for authoring and auditing agent skills — Trigger (user-invoked vs model-invoked),
  Structure (steps + reference, minimal SKILL.md, context pointers), Steering (leading
  words, legwork-per-step), and Pruning (single source of truth, sediment, no-ops) — framed
  as the way out of 'skill hell.'"
created_at: 2026-07-03
updated_at: 2026-07-03
sources: []
epistemic_status: sourced
tags:
- agent-skills
- skill-authoring
- context-engineering
- prompt-engineering
- youtube-transcript
domains:
- ai-agents
- software
supersedes: null
superseded_by: null
aliases:
- "Building Great Agent Skills: The Missing Manual"
- "The Missing Manual, How to Write Great Skills"
- "src-2026-07-03-building-great-agent-skills"
has_contradictions: false
knowledge_domain: software
example: false
path: sources/2026/2026-07/2026-07-03-building-great-agent-skills.md
url: "https://www.youtube.com/watch?v=UNzCG3lw6O0"
content_hash: "sha256:194bf6e242155e0e7432310bb0fcc16ecf888cfb8e1eab7564b395a42500cc6e"
ingested_at: 2026-07-03
source_type: transcript
channel: "AI Engineer"
publish_date: 2026-06-29
duration: "20:43"
extraction_tool: stt
extraction_model: "faster-whisper large-v3 (English); speaker diarization unavailable (TorchCodec missing)"
extraction_date: 2026-07-03
compilation_status: compiled
compiled_against_hash: "sha256:194bf6e242155e0e7432310bb0fcc16ecf888cfb8e1eab7564b395a42500cc6e"
compiled_targets:
- skill-checklist
- agent-skills
- progressive-disclosure
- matt-pocock
- superpowers
---

# Building Great Agent Skills: The Missing Manual — Matt Pocock

## TL;DR

A recorded talk by [[matt-pocock|Matt Pocock]] — delivered remotely because he could not attend the AI Engineer World's Fair in person — that supplies "the missing manual" for writing great [[agent-skills|Agent Skills]]. Its diagnosis is "skill hell": there are now more freely shared skills than anyone can evaluate, and no shared rubric to tell a good skill from a bad one. Its answer is a four-part [[skill-checklist|Skill Checklist]]: (1) **Trigger** — decide whether a skill is *user-invoked* or *model-invoked*, trading the agent's context load against the pilot's cognitive load; (2) **Structure** — compose a skill from *steps* and *reference*, keep `SKILL.md` as small as possible, and push branch-specific reference behind *context pointers*; (3) **Steering** — use *leading words* (short phrases dense with meaning the agent echoes into its reasoning traces) and tune *legwork per step* by splitting a skill so the agent sees one step at a time; (4) **Pruning** — enforce a single source of truth and delete *sediment* (accreted irrelevant material) and *no-ops* (instructions that do not change behavior), using deletion tests. The whole framework is itself packaged as a `writing-great-skills` skill in his repo.

## Key Takeaways

- The organizing problem is "skill hell": an abundance of freely available skills with no shared rubric for telling a good skill from a bad one, so people can't get the results skills promise — at both the individual and the organizational level [prov:src-2026-07-03-building-great-agent-skills#t00:00:49-00:01:28|direct|2026-07-03]
- The remedy is a four-item **skill checklist** — Trigger, Structure, Steering, Pruning — a rubric for auditing a skill and for writing new ones [prov:src-2026-07-03-building-great-agent-skills#t00:02:11-00:02:53|direct|2026-07-03]
- **Trigger:** a skill is either *user-invoked* (manual; its description can be hidden from the agent) or *model-invoked* (the description sits in the agent's context so the agent can choose to load `SKILL.md`); model-invoked adds context load and unpredictability, user-invoked adds cognitive load on the pilot — there is no free choice [prov:src-2026-07-03-building-great-agent-skills#t00:05:07-00:07:24|direct|2026-07-03] [epistemic:: tentative]
- **Structure:** most skills decompose into *steps* (the procedure) and *reference* (supporting info); keep the main `SKILL.md` as small as possible and hide branch-specific reference behind *context pointers* to bundled files [prov:src-2026-07-03-building-great-agent-skills#t00:07:30-00:11:39|direct|2026-07-03] [epistemic:: tentative]
- **Steering:** *leading words* — short phrases packed with meaning (e.g. "vertical slice") that the agent repeats into its reasoning traces and output — are the central lever for making an agent actually do what the skill says; you can verify the technique worked by watching the reasoning traces [prov:src-2026-07-03-building-great-agent-skills#t00:12:17-00:14:14|direct|2026-07-03] [epistemic:: tentative]
- **Pruning:** massive skills are a symptom; enforce a single source of truth (no duplication), remove *sediment* (accreted irrelevant/stale material) and *no-ops* (instructions that don't change behavior, found via a deletion test) [prov:src-2026-07-03-building-great-agent-skills#t00:16:48-00:19:05|direct|2026-07-03] [epistemic:: tentative]

## Extracted Claims

### Framing: "skill hell" and the missing rubric

- Matt Pocock recorded this as the talk he would have given at the AI Engineer World's Fair, which he could not attend in person; his spoken title is "The Missing Manual, How to Write Great Skills" [prov:src-2026-07-03-building-great-agent-skills#t00:00:00-00:00:14|direct|2026-07-03] [epistemic:: tentative]
- Distinguishing good skills from bad skills is "only getting more important" [prov:src-2026-07-03-building-great-agent-skills#t00:00:14-00:00:24|direct|2026-07-03]
- Developers keep finding "forms of hell": prior examples were "tutorial hell" and "framework hell"; the new one is "skill hell" [prov:src-2026-07-03-building-great-agent-skills#t00:00:24-00:00:49|direct|2026-07-03] [epistemic:: tentative]
- Skill hell is having many freely available skills you can download/contribute to but not knowing how the pieces work together, and being unable to tell a good skill from a bad one — so people try everything at once and don't get the promised results [prov:src-2026-07-03-building-great-agent-skills#t00:00:49-00:01:17|direct|2026-07-03]
- This holds at the organizational level too: organizations have no shared understanding of how to turn their operating procedures into skills an agent can execute, and without that they can't get the "bounty" skills offer [prov:src-2026-07-03-building-great-agent-skills#t00:01:17-00:01:33|direct|2026-07-03]
- Pocock frames his own repo — "Matt Pocock Skills" — as "one of the most popular engineering skill sets out there," and says he wants to help its users get out of skill hell [prov:src-2026-07-03-building-great-agent-skills#t00:01:37-00:01:52|direct|2026-07-03] [epistemic:: tentative]
- What is missing is a shared rubric / framework for looking at a skill and judging or improving it — knowing what makes a skill great [prov:src-2026-07-03-building-great-agent-skills#t00:01:52-00:02:11|direct|2026-07-03]
- The checklist has four parts, in order: (1) the **trigger** — how the skill is invoked; (2) the internal **structure** — how the skill is composed and laid out; (3) **steering** — how you get the skill to tell the agent what to do; (4) making the skill **as small as possible** — pruning irrelevant material and no-ops [prov:src-2026-07-03-building-great-agent-skills#t00:02:20-00:02:53|direct|2026-07-03]
- The entire framework is encoded as a skill in his repo called "writing great skills," so viewers can apply it immediately [prov:src-2026-07-03-building-great-agent-skills#t00:02:53-00:03:11|direct|2026-07-03] [epistemic:: tentative]

### Trigger — user-invoked vs model-invoked skills

- His skills are frequently compared to another popular engineering skill set called "superpowers," and he is often asked how they differ; answering that requires the user-invoked vs model-invoked distinction [prov:src-2026-07-03-building-great-agent-skills#t00:03:20-00:03:39|direct|2026-07-03] [epistemic:: tentative]
- Any skill can always be *user-invoked* (manually): the skill sits on the file system and the agent can pull it up when the user communicates that — often via a forward-slash command, though the exact form depends on the harness [prov:src-2026-07-03-building-great-agent-skills#t00:03:39-00:03:58|direct|2026-07-03] [epistemic:: tentative]
- A skill can also be *model-invoked*: the skill's description always ends up in the agent's context, and the agent can read that description and decide to invoke the skill, pulling the `SKILL.md` file (where "the meat of the skill is") into its context window [prov:src-2026-07-03-building-great-agent-skills#t00:03:58-00:04:26|direct|2026-07-03]
- That description functions as a **context pointer** — text sitting in the agent's context that points to another file the agent can read for more context; the pointer is optional and can be made invisible to the agent [prov:src-2026-07-03-building-great-agent-skills#t00:04:26-00:04:42|direct|2026-07-03]
- A *user-invocable* skill is one with no such context pointer, so only the user can invoke it [prov:src-2026-07-03-building-great-agent-skills#t00:04:42-00:04:52|direct|2026-07-03]
- Example: his "code base design" skill is model-invocable (its description reaches the agent's context window), whereas his "grill me" skill sets `disable model invocation: true`, so its description shows only to the user and is not visible to the agent [prov:src-2026-07-03-building-great-agent-skills#t00:04:52-00:05:07|direct|2026-07-03] [epistemic:: tentative]
- Tip #1: decide whether your skill is user-invoked or model-invoked [prov:src-2026-07-03-building-great-agent-skills#t00:05:07-00:05:12|direct|2026-07-03]
- Model-invoked seems more flexible (either the model or the user can invoke it), but every model-invoked skill increases the agent's **context load** — its description costs tokens on every request and adds another thing for the agent to weigh; 100 model-invoked skills means 100 descriptions permanently in context [prov:src-2026-07-03-building-great-agent-skills#t00:05:12-00:05:46|direct|2026-07-03] [epistemic:: tentative]
- User-invoked skills instead impose a **cognitive load on the user**: the more of them you have, the more the pilot must keep in their head and the more skill it demands of them [prov:src-2026-07-03-building-great-agent-skills#t00:05:51-00:06:02|direct|2026-07-03]
- The [[superpowers|Superpowers]] skill set is primarily model-invoked ("gives the agent superpowers"), whereas Pocock prefers user-invoked skills to stay in full control — keeping the agent's context load small at the cost of more cognitive load on himself, so he must understand the skills deeply [prov:src-2026-07-03-building-great-agent-skills#t00:06:02-00:06:31|direct|2026-07-03] [epistemic:: tentative]
- His deeper reason for preferring user-invoked: a model-invoked skill costs **unpredictability**, because a context pointer from one resource to another may simply not be followed — the model can decline to invoke a skill even when it is perfect for the task [prov:src-2026-07-03-building-great-agent-skills#t00:06:31-00:06:54|direct|2026-07-03]
- That unpredictability forces people to *eval* their skills to confirm they fire at the right time, which he finds "really nasty" and prefers to avoid by removing the class of problem entirely [prov:src-2026-07-03-building-great-agent-skills#t00:06:54-00:07:15|direct|2026-07-03] [epistemic:: tentative]
- Both trigger modes carry costs, so which to choose is not an easy decision [prov:src-2026-07-03-building-great-agent-skills#t00:07:15-00:07:24|direct|2026-07-03]

### Structure — steps, reference, and a minimal SKILL.md

- Most skills decompose into two units: **steps** (the step-by-step procedure the skill walks through) and **reference** (supporting information that helps it walk the steps); a skill may be all-reference or all-steps [prov:src-2026-07-03-building-great-agent-skills#t00:07:30-00:08:01|direct|2026-07-03]
- Worked example — his "2PRD" skill creates a product-requirements document from the current context window in three steps: find relevant context, confirm the "test seams" with the user (a human-in-the-loop checkpoint), then write the PRD; it carries two pieces of reference — a note on what a test seam is, and a PRD markdown template [prov:src-2026-07-03-building-great-agent-skills#t00:08:01-00:08:37|direct|2026-07-03] [epistemic:: tentative]
- Recommended way to write a skill from scratch: work out whether you need steps, write them, then work out what reference material those steps need and put it in a separate reference spot [prov:src-2026-07-03-building-great-agent-skills#t00:08:37-00:08:52|direct|2026-07-03]
- Tip #3: make the main `SKILL.md` file as small as possible; a skill is its description plus a `SKILL.md` plus any reference material branching off it [prov:src-2026-07-03-building-great-agent-skills#t00:08:52-00:09:16|direct|2026-07-03]
- Smaller skills are easier to maintain and audit, have fewer words to reason about, and every word shaved is tokens shaved from the skill's per-use cost — important for both maintainers and users [prov:src-2026-07-03-building-great-agent-skills#t00:09:16-00:09:33|direct|2026-07-03]
- To shrink a skill, look at its **branches** (the different ways it can be used): reference material used in only one branch is a candidate for removal from the main `SKILL.md` [prov:src-2026-07-03-building-great-agent-skills#t00:09:33-00:09:48|direct|2026-07-03]
- 2PRD has a single branch — it always creates a PRD and always asks about test seams — so all its reference belongs on that branch and probably belongs inline in `SKILL.md` [prov:src-2026-07-03-building-great-agent-skills#t00:09:48-00:10:15|direct|2026-07-03] [epistemic:: tentative]
- By contrast his "domain modeling" skill has two-or-three branches (update a local `context.md` glossary, create architectural decision records, or neither), so the ADR template and the `context.md` template should not sit in the main skill [prov:src-2026-07-03-building-great-agent-skills#t00:10:15-00:10:46|direct|2026-07-03] [epistemic:: tentative]
- The mechanism for moving them out: keep the `SKILL.md`, then place a **context pointer** to a separate markdown file bundled inside the skill's folder (e.g. "if you need the template, go to this file") — he calls this an **external reference** [prov:src-2026-07-03-building-great-agent-skills#t00:10:46-00:11:19|direct|2026-07-03] [epistemic:: tentative]
- The general structure technique: hide branching reference material behind context pointers whenever a skill will be used in many different ways [prov:src-2026-07-03-building-great-agent-skills#t00:11:26-00:11:39|direct|2026-07-03]

### Steering — leading words and legwork per step

- Steering is how you actually get the agent to do what you want, and for Pocock it reduces to one main technique — the key takeaway of the talk [prov:src-2026-07-03-building-great-agent-skills#t00:11:50-00:12:06|direct|2026-07-03]
- The problem it fixes: you specify something in the skill, believe you were clear, and the agent still doesn't do it [prov:src-2026-07-03-building-great-agent-skills#t00:12:06-00:12:17|direct|2026-07-03]
- The fix is **leading words**: certain words pack a lot of meaning into a very small space (he ties the idea to a literary-theory notion); putting a leading word in the skill text makes the agent repeat it back in its operations, its thinking tokens, and its output, and that re-emphasis steers its behavior [prov:src-2026-07-03-building-great-agent-skills#t00:12:17-00:12:57|direct|2026-07-03] [epistemic:: tentative]
- Worked example — agents tend to code "layer by layer" (all the database layer, then schemas, then API endpoints, then the front end) instead of getting a small slice working and seeking feedback early; the leading word "vertical slice" (established dev terminology) triggers the agent's priors to slice work vertically instead [prov:src-2026-07-03-building-great-agent-skills#t00:12:57-00:13:47|direct|2026-07-03] [epistemic:: tentative]
- You don't reduce the skill to the bare phrase; you pack meaning into a short phrase and repeat it consistently throughout the skill [prov:src-2026-07-03-building-great-agent-skills#t00:13:47-00:14:01|direct|2026-07-03]
- The technique is verifiable: after putting "vertical slice" in the skill you can watch the reasoning traces say things like "we're going to do this as a thin vertical slice," and you should get better implementation plans [prov:src-2026-07-03-building-great-agent-skills#t00:14:01-00:14:14|direct|2026-07-03] [epistemic:: tentative]
- His ask is to use leading words *consistently* within skills and watch the thinking traces adopt them; if the agent still misbehaves, make the leading words more consistent and more powerful and look for more, since "English is a pretty wide API" and agents themselves are good at suggesting candidate leading words [prov:src-2026-07-03-building-great-agent-skills#t00:14:14-00:14:54|direct|2026-07-03] [epistemic:: tentative]
- A second steering lever is **legwork**: sometimes the agent doesn't put enough effort into the step it is on (e.g. asking clarifying questions or exploring the codebase) [prov:src-2026-07-03-building-great-agent-skills#t00:14:54-00:15:15|direct|2026-07-03]
- Classic failure: plan mode has two steps — ask clarifying questions, then create a plan — and in every implementation he's tried, "ask clarifying questions" does too little legwork because the agent sees its ultimate goal is the plan and rushes to it [prov:src-2026-07-03-building-great-agent-skills#t00:15:15-00:15:45|direct|2026-07-03] [epistemic:: tentative]
- His fix: split the phases into separate skills — a "grill with docs" skill for the clarifying-questions phase, then "2PRD" afterward — so the agent sees only one step at a time and does more legwork on the current step by having the future goal hidden from it [prov:src-2026-07-03-building-great-agent-skills#t00:15:45-00:16:25|direct|2026-07-03] [epistemic:: tentative]
- Splitting a skill into single steps isn't always necessary, but when you need an extra chunk of legwork on a step, "there's no technique like it" [prov:src-2026-07-03-building-great-agent-skills#t00:16:25-00:16:48|direct|2026-07-03]

### Pruning — single source of truth, sediment, no-ops

- Pruning is a quickfire set of failure modes; the headline is that massive skills are usually a *symptom* of one of the other failure modes [prov:src-2026-07-03-building-great-agent-skills#t00:16:48-00:17:05|direct|2026-07-03]
- Failure mode 1 — don't repeat yourself: watch for duplication, and give every part of the skill (including each piece of reference material) a single source of truth rather than repeating it across steps or files [prov:src-2026-07-03-building-great-agent-skills#t00:17:05-00:17:37|direct|2026-07-03]
- Failure mode 2 — **sediment**: when many people contribute to a shared markdown file, they add their own material but don't feel brave enough to delete or modify others', leaving a large accretion of often-irrelevant content; the fix is to look at structure first, move added material into the correct branches, and remove or "kill dead" anything irrelevant or stale [prov:src-2026-07-03-building-great-agent-skills#t00:17:37-00:18:23|direct|2026-07-03]
- Failure mode 3 — **no-ops** (common when an agent writes your skills): instructions that appear to do something but don't actually change the agent's behavior within the skill's context; e.g. a paragraph telling the agent to write a long detailed commit message that, if deleted, would change nothing because the agent would write a good commit message anyway [prov:src-2026-07-03-building-great-agent-skills#t00:18:23-00:18:55|direct|2026-07-03] [epistemic:: tentative]
- How he keeps his skills small: deletion tests (delete a passage and see whether behavior changes), compacting instructions into leading words, and keeping nothing irrelevant and no sediment [prov:src-2026-07-03-building-great-agent-skills#t00:18:55-00:19:05|direct|2026-07-03] [epistemic:: tentative]

### Recap and resources

- Full-checklist recap: check the **trigger** fires at the right times (context load vs cognitive load); use **structure** (branches, steps + reference, one-branch material kept out of the main `SKILL.md`); apply **steering** (condense into leading words watched in the reasoning traces; use legwork by hiding future phases); and do a final **pruning** pass for sediment, crud, and especially no-ops [prov:src-2026-07-03-building-great-agent-skills#t00:19:05-00:19:53|direct|2026-07-03]
- The recommended starting point is the "writing great skills" skill in the Matt Pocock skills repo, which can also be run over community-authored skills to check their quality; he also runs a newsletter at aihero.dev and plans an "AI coding crash course" [prov:src-2026-07-03-building-great-agent-skills#t00:19:53-00:20:30|direct|2026-07-03] [epistemic:: tentative]

## Notes

**Validity assessment:**

- The audio is clean, single-speaker, studio-recorded narration, so the page is graded `sourced`; per-claim `[epistemic:: tentative]` hedges are applied across the STT failure surface per the video-ingestion tiered-epistemic policy: proper nouns, product/skill names, coined terms, and numbers.
- **Names and skill titles mended from context or corroborated by the video description:** the speaker is **Matt Pocock** (rendered "matt pocott" once at 0:20:04); his repo is *Matt Pocock Skills* at `github.com/mattpocock/skills` and the packaged framework skill is `writing-great-skills` (both confirmed from the official video description via `yt-dlp`, not the STT). Named skills used as examples — **2PRD** (rendered "2PRD RD", "to PRD", "my2prd"), **grill me**, **grill with docs**, **domain modeling**, **code base design**, and a generic **implement** skill — are as-heard and should be treated as tentative. The `disable model invocation: true` frontmatter flag is transcribed by ear and may differ from the exact key.
- **Coined / borrowed terms:** "skill hell", "leading words", "context pointer", "external reference", "sediment", "no-ops", "legwork", "deletion test", and "vertical slice" are the talk's working vocabulary. "Leading words" is glossed by the speaker with a literary-theory aside the STT renders as "light vert" — most likely *Leitwort* (a recurring guiding keyword), though the talk does not spell it, so the connection is noted as tentative, not asserted.
- **Numbers** ("100 model-invoked skills / 100 descriptions") are illustrative and as-spoken.
- **Comparison to Superpowers:** Pocock characterizes [[superpowers|Superpowers]] as "primarily model-invoked skills." This is his framing of a third-party project; it is recorded as his claim (tentative) rather than asserted as fact on the Superpowers page.
- **Speaker labels:** automatic diarization did not run (the pipeline's TorchCodec dependency was missing), so the committed raw transcript carries no `SPEAKER:` labels. The talk is single-speaker throughout, so labels are not required.

## Source Metadata

- **Speaker:** Matt Pocock
- **Channel:** AI Engineer
- **Publication:** YouTube
- **URL:** https://www.youtube.com/watch?v=UNzCG3lw6O0
- **Publish date:** 2026-06-29
- **Duration:** 20:43
- **Skills repo:** https://github.com/mattpocock/skills
- **Featured skill:** https://github.com/mattpocock/skills/blob/main/skills/productivity/writing-great-skills/SKILL.md
- **Newsletter:** https://aihero.dev
- **Source type:** transcript (video sub-case)
- **Path:** `sources/2026/2026-07/2026-07-03-building-great-agent-skills.md`

The video fields (title, channel, publish date, duration) were sourced from the `yt-dlp`
metadata pulled during acquisition. The committed transcript is the durable record; the `url`
is a courtesy pointer that may rot.
