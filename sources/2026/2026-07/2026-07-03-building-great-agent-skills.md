---
title: "Building Great Agent Skills: The Missing Manual — Matt Pocock"
author: "Matt Pocock"
channel: "AI Engineer"
publication: "YouTube"
url: "https://www.youtube.com/watch?v=UNzCG3lw6O0"
date: 2026-06-29
source_type: transcript
privacy: cloud_safe
---

# Building Great Agent Skills: The Missing Manual — Matt Pocock

> Machine-transcribed from the video's audio with the `stt` CLI (faster-whisper large-v3,
> English, user-specified). Automatic speaker diarization did NOT run — the pipeline's diarizer
> dependency (TorchCodec) was unavailable — so the committed transcript carries no `SPEAKER:`
> labels. This is a single-speaker recorded talk by Matt Pocock (delivered remotely because he
> could not attend the AI Engineer World's Fair in person), so speaker labels are not required.
> The `[H:MM:SS]` timestamps are the STT segment starts. Matt's spoken title for the talk is
> "The Missing Manual, How to Write Great Skills"; the canonical page title above follows the
> YouTube listing.

## Description

Official video description (AI Engineer channel):

> Let's discuss how to navigate "skill hell" by providing a structured framework for building
> high-quality agent skills. Without a shared rubric, developers and organizations struggle to
> create effective, maintainable skills for AI agents.

Chapters / timestamps (from the video description):

- 0:00 — Introduction to the talk and the concept of "skill hell"
- 2:12 — Overview of the skill checklist framework
- 3:16 — Trigger: Choosing between user-invoked and model-invoked skills
- 7:29 — Structure: Organizing steps and references
- 9:00 — Making the skill.md file minimal
- 11:54 — Steering: Using leading words to guide agent behavior
- 14:56 — Increasing "leg work" per step
- 16:48 — Pruning: Removing sediment, crud, and no-ops
- 19:06 — Final summary of the checklist framework
- 19:55 — Where to find the "writing great skills" resource

The Skill Checklist Framework (as summarized in the video description):

- **Trigger** (3:16–7:25): Decide whether a skill should be user-invoked or model-invoked. Model-invoked skills offer more flexibility but increase context load and introduce unpredictability. User-invoked skills offer more control but require greater cognitive load from the pilot.
- **Structure** (7:29–11:53): Organize a skill into two primary units — steps (procedures) and reference (supporting information). Keep `skill.md` minimal by moving branching reference material behind context pointers to reduce bloat and maintenance costs.
- **Steering** (11:54–16:47): Use leading words — specific terms that pack dense meaning — to influence agent behavior and guide reasoning traces. Force the agent to do more "leg work" by breaking complex processes into smaller, individual skills that hide future steps.
- **Pruning** (16:48–19:05): Keep a clean skill set with a single source of truth, removing "sediment" (irrelevant legacy material) and "no-ops" (instructions that don't actually change agent behavior).

- **Resource — "writing great skills" skill:** https://github.com/mattpocock/skills/blob/main/skills/productivity/writing-great-skills/SKILL.md
- **Newsletter:** https://aihero.dev

## Transcript

﻿[0:00:00] Hello friends, I was dearly hoping to be able to come to the AI Engineer World's Fair,
[0:00:03] but family matters have intruded and I'm not able to make it. However, I will not be leaving you
[0:00:08] empty-handed, I'm going to give you the talk that I would have given in San Francisco. This talk is
[0:00:14] called The Missing Manual, How to Write Great Skills, and I think that the ability to distinguish
[0:00:19] good skills from bad skills is only getting more important. As developers, we seem to be pretty
[0:00:24] talented at finding different forms of hell for us to go to in like a few years
[0:00:29] ago we had tutorial hell which is where you would go into a bunch of tutorials
[0:00:32] trying to learn something not be able to piece it together and sort of just get
[0:00:37] into this cycle you couldn't get out of we had framework hell where every other
[0:00:42] 10 minutes there was a JavaScript framework being announced and you know
[0:00:45] you had to learn the hot new thing all the time and now I think we have another
[0:00:49] version of hell which is skill hell skill hell is where you have all of
[0:00:53] these skills available freely available that you can download contribute to you can figure out on
[0:00:58] your own but you don't really know how the pieces all work together you can't tell a good skill from
[0:01:03] a bad skill and this means that people are trying to piece together these frameworks trying to try
[0:01:07] everything that's out there all at once and they sort of can't or rather they don't get the results
[0:01:13] that the skills themselves promise this is true at an individual level but it's also true at an
[0:01:17] an organization level too. Organizations have no way or no understanding on how to build good
[0:01:23] skills, how to take their operating procedures and turn them into things that an agent can do.
[0:01:28] And if you don't do that, then it's hard to get the bounty that skills can offer.
[0:01:33] Just one more skill, bro. That's kind of seems like what we're saying. And I feel a bit of guilt
[0:01:37] here too, because we have Matt Pocock Skills, which is my skills repo, which is one of the
[0:01:42] most popular engineering skill sets out there. And so I feel like I want to help the people who
[0:01:48] use my skills get out of skill hell. So how do we do it? How do we get out of this? Well,
[0:01:52] what is actually missing here? Well, in my opinion, the thing that we're missing is we don't
[0:01:56] know what makes a skill great. We can't yet look at a skill and go, okay, this skill is doing these
[0:02:01] good things and these bad things. There's no shared rubric, no framework for looking at a skill and
[0:02:07] making it better. And so that's what I'm going to give you in this talk. I'm going to give you a
[0:02:11] a skill checklist, a checklist of things you can look at inside the skill to make sure that it's
[0:02:16] doing what it says it's doing and ways you can improve it, ways you can write skills. This
[0:02:20] checklist looks like this. We start with the trigger of the skill, how the skill is invoked
[0:02:26] and the decisions that you need to design there. Then the internal structure of the skill, how the
[0:02:31] skill is actually composed and laid out internally. Then number three is how do you actually steer
[0:02:37] using the skill? How do you get the skill to tell the agent what to do? And then four, how do you
[0:02:43] make the skill as small as possible? Because once we've got a working skill, we then need to
[0:02:48] basically maximize it, prune out all of the irrelevant stuff, prune out all of the no-ops.
[0:02:53] There's one handy advantage of me not being in the room with you, which is you can immediately
[0:02:56] go and try this out because I've encoded all of this into a new skill in my repo called
[0:03:01] writing great skills. So if you've got an immediate use case for this, just go to this
[0:03:05] my skills repo you know just close this browser get out of here and go and use this skill to
[0:03:11] either improve your skills or write great new ones but let's start going through the checklist then
[0:03:15] we have number one the trigger the way the skill is invoked and in order to talk about this i'm
[0:03:20] actually going to do a bit of comparison here which is that my skills are often compared to
[0:03:24] another set of extremely popular engineering skills called superpowers and i'm really often
[0:03:29] asked the question how do your skills compare to superpowers what's the difference between them to
[0:03:34] To understand that, we need to understand the difference
[0:03:35] between user invoked and model invoked skills.
[0:03:39] Anytime you have a skill, you can always invoke it manually.
[0:03:43] So the skill sits on your file system,
[0:03:45] the agent will just be able to pull up the skill
[0:03:47] and understand what's in there.
[0:03:49] And you can always do that
[0:03:50] by communicating that to the agent.
[0:03:52] Doesn't always look like this forward slash
[0:03:54] depending on the harness,
[0:03:55] but that you can always user invoke your skills.
[0:03:58] Another way that skills can be invoked
[0:03:59] is by the agent itself.
[0:04:01] These are called model invocable skills
[0:04:02] or model invoked skills, you can take a description,
[0:04:06] so the description of the skill always ends up
[0:04:10] in the agent's context, and the agent can look in that
[0:04:13] and go, okay, based on that description,
[0:04:15] I'm going to invoke the skill,
[0:04:16] and I end up reading the skill.md file,
[0:04:20] which is where the meat of the skill is,
[0:04:21] into my context window.
[0:04:23] That's how you invoke a skill.
[0:04:24] That's what happens when a skill is invoked.
[0:04:26] So this description serves as a kind of context pointer.
[0:04:29] It sits in the agent's context,
[0:04:31] context pointing to another file where the agent can go if it wants more context. But that context
[0:04:36] pointer, you don't need to put it into the agent's context. It can just be invisible from the agent.
[0:04:42] And that is what we call a user invocable skill. So some skills can only be invoked by the user
[0:04:48] because they don't have this context pointer. It's optional. For instance, we can see in my
[0:04:52] code base design here, this is a model invocable skill. It has a description that ends up in the
[0:04:57] agent's contacts window. But if we look at my grill me skill instead, we can see it has disable
[0:05:02] model invocation true. This means that this little description here will only show to the user.
[0:05:07] It won't be visible to the agent. So this then is tip number one, decide if your skill is user
[0:05:12] invoked or model invoked. Now you might think that model invoke skills are better, right? Because
[0:05:17] either the model can invoke it itself or the user can invoke it. It's more flexible. But every time
[0:05:22] you add a model invoked skill into your agent's environment, it increases what I'm going to call
[0:05:28] the context load on that agent. It adds a new description, which is costing you tokens on every
[0:05:35] request, but also adding a different thing for the agent to think about. So if you have 100 model
[0:05:41] invoked skills, that's going to be 100 descriptions inside the context for your agent. So it seems to
[0:05:46] make sense then to either tamp down the number of model invoked skills or to just use all user
[0:05:51] invoked skills but user invoked skills have a different load which is the more user invoked
[0:05:57] skills you have the higher cognitive load on the user in other words the more things the user needs
[0:06:02] to keep in their head the more skill you require from the pilot and so if we compare matt pocock
[0:06:08] skills to superpowers superpowers is primarily model invoked skills it gives the agent super
[0:06:15] powers whereas my skills i much prefer to be in full control that means i get to keep the context
[0:06:21] load on the agent as small as possible, but it does impose more of a cognitive load on me. So
[0:06:27] I need to understand the skills really deeply in order to get the most use out of it. So why have
[0:06:31] I done this? Why did I prefer user invoked skills? Well, every time you have a model invoked skill,
[0:06:38] it basically, you get a cost in unpredictability because every time you have a context pointer
[0:06:43] pointing from one resource to another, the model may just choose not to follow it. You know,
[0:06:48] Even if it's absolutely perfect for the task, it may just choose not to invoke the skill.
[0:06:54] I much prefer removing that level of unpredictability, imposing a bit more
[0:06:58] cognitive load on the user. And what you get is just you're removing a class of problem from
[0:07:05] even being a problem because this unpredictability leaves people to need to eval their skills to make
[0:07:10] sure they're being called at the right time, which is really nasty. And it's a problem that
[0:07:15] I prefer to avoid. But what I'm hoping to show you here is that model invoked skills and user
[0:07:19] invoked skills both have their same costs. So it's not an easy decision which one you choose.
[0:07:24] So that then is the trigger, how the skill gets invoked. Now let's talk about the structure,
[0:07:30] the internal layout of the skill. I think of there as being two main units that you need to put
[0:07:34] into most skills. These two units are the steps and the reference. The steps are the step-by-step
[0:07:42] step procedure that the skill is going to walk through. And the reference is any supporting
[0:07:46] information that helps it walk through those steps. You can have skills that have no steps
[0:07:52] and are only reference. And you can have skills that are no reference and only a set of simple
[0:07:57] steps to walk through. But if you start thinking of skills as composed of these two units, it really
[0:08:01] helps just break them down a lot more. If we look at an example, one of my skills called 2PRD
[0:08:06] RD creates a product requirements document out of the current context window. It's got three
[0:08:11] steps in it. So it finds the relevant context. It confirms the test seams with the user. So there's
[0:08:17] like a little human in the loop checkpoint there just to make sure we're not doing anything weird
[0:08:21] with the testing, which I find really important. And then we write the product requirements document.
[0:08:26] To handle those three steps, we've got two bits of reference material. We've got a little bit
[0:08:31] of reference on what is a test seam and then we've got a product requirements document template so
[0:08:37] just a literal markdown template which is used to write the prd so this is a great way to write
[0:08:43] a skill from scratch you work out if you need some steps then you write those steps and you
[0:08:48] work out what reference material those steps need and you put it in a separate little spot
[0:08:52] in the skill which is for reference material however there's a really important constraint
[0:08:57] that we need to think about, which is tip number three,
[0:08:59] we want to make the main skill.md file as small as possible.
[0:09:04] Every skill is composed of its description
[0:09:06] and then a skill.md file,
[0:09:08] and then any reference material that branches off that.
[0:09:11] And this skill.md file, if we make it small,
[0:09:14] then we're saving in a bunch of different ways.
[0:09:16] Smaller skills are just easier to maintain,
[0:09:18] easier to audit, fewer words to think about.
[0:09:21] And every time you shave off a word that is a token shaved,
[0:09:25] that multiple tokens shave from your skill's cost.
[0:09:28] So I do believe that small skills are really important,
[0:09:31] both for maintainers and for users.
[0:09:33] One really useful way you can make your skill smaller
[0:09:36] is by thinking about the different branches of the skill,
[0:09:39] the different ways the skill can be used.
[0:09:41] Because if you have reference material
[0:09:43] that's only used in one branch,
[0:09:45] then that's a candidate for being removed
[0:09:47] from the main skill.md.
[0:09:48] For instance, if we look at my2prd here,
[0:09:51] we have two pieces of reference material,
[0:09:53] what is a test seam and the PRD template? Well, we need the PRD template every single time because
[0:09:59] we are always creating a PRD. And we probably also need the what is a test seam information
[0:10:03] every time because we're always asking about the test seams. So to PRD, there's only one branch and
[0:10:09] all the reference material belongs on that branch. So it probably also belongs in the skill.md file.
[0:10:15] However, if we look at a different skill of mine, which is domain modeling, domain modeling does
[0:10:20] does two things. It updates a local glossary called context.md, and then it also creates
[0:10:25] architectural decision records. In other words, it's doing two different things, or it might
[0:10:30] actually choose to do neither of these, in which case it doesn't need the template and it doesn't
[0:10:34] need the ADR template either. So in other words, domain modeling has two or maybe three branches,
[0:10:40] and this means that we don't need to include the ADR template or the context.md template
[0:10:46] template into the main skill they can be moved into separate zones the way you do that is you
[0:10:51] have the skill.md file then you put it behind a context pointer and you point the context template
[0:10:57] to a separate Markdown file inside the skills folder that context pointer literally just says
[0:11:03] if you need the template or if you need to update the context.md file go to this file and I call
[0:11:08] that an external reference it's a reference that's external to the skill.md that you can just easily
[0:11:15] easily reference the agent can pull in very easily because it's bundled along with the skill. So this
[0:11:19] is a technique you can use for making the skill.md as small as possible, which has so many benefits.
[0:11:26] Hide branching reference material behind context pointers. In other words, if you feel like your
[0:11:30] skill is going to be used in lots of different ways, then take the reference material that's
[0:11:35] relevant for those branches and hide them behind context pointers. So that is structure. We need
[0:11:39] to think about making the skill.md super duper small. We need to think about the branches in
[0:11:44] our skill moving material out behind context pointers. And we need to think about steps and
[0:11:50] reference, which are the two main units inside a skill. Let's go next to steering, the actual ways
[0:11:56] we get the agent to do what we want it to do. And for me, steering comes down to one really cool
[0:12:02] technique, which is the kind of main thing I want you to get from this talk. This technique fixes
[0:12:06] this issue, which is the agent doesn't do what I want. In other words, I specify something in the
[0:12:13] the skill, I think that I've been clear and then it just doesn't do the thing. Now I think the main
[0:12:17] reason this happens is because you're not using a technique called leading words. The idea of
[0:12:23] leading words or light vert, if you like literary theory I suppose, is that there are certain words
[0:12:29] that pack in a bunch of meaning into a very small space. These leading words are really powerful
[0:12:35] with agents because you put the leading word in the skill itself, in the text, and then the agent
[0:12:41] will repeat the leading word back to itself as part of its operations, as part of its thinking
[0:12:46] tokens, and as part of its output to you. And then, because it's re-emphasizing that word,
[0:12:52] and that word hopefully describes what you want from the agent, that then goes and changes its
[0:12:57] behavior. Let's make this more concrete with an example. So let's imagine that we have a problem,
[0:13:01] which is a classic problem with agents, which is that they code layer by layer. In other words,
[0:13:06] if you give them a big tranche of work to do, they will generally code up all of the database layer,
[0:13:11] then all of the schemas, then all of the API endpoints, then all of the front end.
[0:13:15] They don't do the sort of typical human thing, which is to seek feedback early on,
[0:13:21] get something small working, and then expand out from there. Now we can try to encourage the agent
[0:13:26] to do that by just saying, you know, don't code layer by layer, make sure that you create a small
[0:13:31] slice first and then go from there. But what if instead we used a leading word? We said
[0:13:35] vertical slice is our leading word. We want to slice up the work instead of horizontal slices
[0:13:41] into vertical slices. A vertical slice is a pretty well-known terminology in development,
[0:13:47] and so this will hopefully trigger the agent's priors and it will understand what we mean. We
[0:13:52] don't just have to like have a two-word skill where it just says vertical slice. What we're
[0:13:56] doing is we're packing lots of meaning into a relatively short phrase that we then repeat
[0:14:01] throughout the skill. The cool thing about this technique is you can know if it's worked
[0:14:05] because you say vertical slice in your skill and then you'll notice in the reasoning traces that
[0:14:10] it's saying, okay, we're going to do this as a thin vertical slice, then you should get better
[0:14:14] implementation plans. Everyone I've explained this technique to sort of feels like, oh yeah,
[0:14:18] I've been doing that for a while. I've been using these little phrases to try to encourage the agent
[0:14:23] to do what I want. All I'm asking you now is to use those consistently within your skills and
[0:14:30] and watch in the thinking traces
[0:14:31] as the agent adopts your way of doing it.
[0:14:34] So often if the agent isn't doing what you want,
[0:14:37] you need to make your leading words more consistent,
[0:14:39] more powerful, and look for others
[0:14:42] because English is a pretty wide API
[0:14:45] in terms of different functions you can call,
[0:14:48] different things you can experiment with.
[0:14:49] And there are many leading word candidates out there
[0:14:52] and agents are actually pretty good
[0:14:53] at helping you think of them.
[0:14:54] Another little lever you can use with agents
[0:14:57] is sometimes the agent just doesn't do enough legwork.
[0:15:01] What I mean by this is that, okay, we're on a step,
[0:15:04] let's say, and maybe the step is to ask clarifying
[0:15:07] questions or to explore the code base,
[0:15:09] and the agent just doesn't do enough of it.
[0:15:12] It doesn't put enough effort into that particular step.
[0:15:15] A real classic case of this and something that I have found
[0:15:18] almost everywhere it exists is plan mode.
[0:15:21] Because in plan mode, we have two steps.
[0:15:24] We have ask clarifying questions
[0:15:25] questions and then create a plan. And what I have found in every single implementation of
[0:15:30] plan mode I've tried is that Ask Clarifying Questions just, you know, doesn't ever do
[0:15:35] enough legwork. It sees that its ultimate goal is to create a plan, and so it just does a small
[0:15:40] amount of legwork with Ask Clarifying Questions, asks you a couple of things, and then eagerly
[0:15:45] creates the plan. So what was my solution here? Instead of doing plan mode, I instead have a
[0:15:50] skill called grill with docs, which is kind of my ask clarifying questions phase. And then I split
[0:15:57] that up into a separate skill. So I split the planning into its own skill. So grill with docs
[0:16:03] now is its own skill where the agent only sees that part of the process. And then after grill
[0:16:09] with docs completes, we then go and do 2PRD. In other words, we have step one and step two,
[0:16:14] but the agent only sees one step at a time. So this is a really cool technique for increasing
[0:16:20] increasing legwork on the step that you're on by hiding the future goal, hiding the future steps.
[0:16:25] It's not always necessary to split skills into individual steps, but in particular cases where
[0:16:32] you really want an extra chunk of legwork, it really, there's no technique like it. It works
[0:16:37] very, very well. So that is steering, using leading words to capture what you want in small reusable
[0:16:42] tokens, and then making sure that it's doing the right amount of legwork per step. So let's head
[0:16:48] head now into pruning. Now, pruning really is just a quickfire set of failure modes, different things
[0:16:53] that you can get wrong. And the first is fairly obvious, is we do not want massive skills. Massive
[0:17:00] skills are usually a kind of symptom of something else going wrong. So a symptom of one of these
[0:17:05] other failure modes. And the first one is pretty simple. Don't repeat yourself. You need to make
[0:17:11] sure you're watching out for duplication. And in general, I like to have every part of the skill
[0:17:17] to have a single source of truth in other words if you have a piece of reference material like
[0:17:21] the prd template let's say or something even smaller like what is a test seam you make sure
[0:17:27] that you don't repeat that in several places or like cover multiple steps in multiple places just
[0:17:32] make sure each part has a single source of truth and you're not repeating yourself even across
[0:17:37] reference material too the next way that skills get big is via sediment and sediment is just a
[0:17:43] classic thing when people are working on the same set of docs really which is that everyone starts
[0:17:50] contributing to a shared markdown file people add their own stuff they don't feel brave enough to
[0:17:55] delete and modify anyone else's and so you just end up with this huge amount of sediment with
[0:17:59] often irrelevant material for the skill especially stuff that hasn't been laid out properly with a
[0:18:05] skill with a lot of sediment you really need to look at structure that's the first thing you need
[0:18:09] to do you need to make sure that the stuff that's been added is relevant for all branches if it's
[0:18:14] not then move it into the correct branches or if it's just totally irrelevant maybe just remove it
[0:18:19] or kill it or maybe there's stuff in there that's totally stale in which case you just need to kill
[0:18:23] it dead the next failure mode is really common when an agent writes your skills which are no ops
[0:18:30] so things inside the skill that appear to do something but don't actually influence the agent's
[0:18:35] behavior inside the context of the skill. Let's imagine we have an implement skill and we have
[0:18:40] an entire paragraph of the skill that tells the agent to write a long, detailed commit message.
[0:18:45] What would happen if you just deleted that paragraph? Well, the agent would probably still
[0:18:49] write a decent, like, long commit message. People ask me a lot how I get my skills so small,
[0:18:55] and it's just using these techniques, using deletion tests, making sure that I compact
[0:19:01] things into leading words, I don't have anything irrelevant in there, and I don't have any
[0:19:05] sediment and that finally brings us to the full sweep of things number one we check the trigger
[0:19:11] we make sure that it's firing at the right times we check whether we're imposing context load or
[0:19:16] cognitive load with structure we think about branches we think about structuring things into
[0:19:21] steps and reference and we make sure that material that's only relevant for one branch is outside of
[0:19:28] the main skill.md for steering we're thinking about condensing text down into leading words
[0:19:33] words and watching those leading words appear in the reasoning traces and we're also thinking
[0:19:37] about legwork should we break this skill down further to increase its focus on the current
[0:19:42] phase by hiding the future phrase phase from it and with pruning we're doing a final pruning pass
[0:19:48] over the entire skill watching out for sediments watching out for crud and watching out especially
[0:19:53] for no Ops now all of this stuff the best way to get started with this framework is inside this
[0:19:59] skill inside the writing great skills skill you can check it out from matt pocott skills download
[0:20:04] it use it to improve your own skills and maybe even use it to run over some community authored
[0:20:11] skills so that you can check that the skills that you're actually pulling in are any good if you
[0:20:15] want to follow along with my stuff then i have a newsletter up on aihero.dev and my plans for the
[0:20:20] next few months are to release an ai coding crash course which is an intro to a lot of the stuff
[0:20:25] I've been talking about and how you get off the ground working with engineering and AI.
[0:20:30] I hope that what I've given you is enough to help you escape from skill hell, or at least
[0:20:35] try to make the bitter journey out of there. I'm so sorry not to be able to attend in person,
[0:20:40] but thanks for watching. I'll see you very soon.
