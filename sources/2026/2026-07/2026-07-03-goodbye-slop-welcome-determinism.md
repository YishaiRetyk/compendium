---
title: "Beyond the Prompt: Goodbye Slop, Welcome Determinism — David Khourshid"
author: "David Khourshid"
channel: "AG Grid"
publication: "YouTube"
url: "https://youtu.be/uMvTAF280so"
date: 2026-06-26
source_type: transcript
privacy: cloud_safe
---

# Beyond the Prompt: Goodbye Slop, Welcome Determinism — David Khourshid

> Machine-transcribed from the video's audio with the `stt` CLI (faster-whisper large-v3,
> English, user-specified). Automatic speaker diarization did NOT run — the pipeline's diarizer
> dependency (TorchCodec) was unavailable — so the committed transcript carries no `SPEAKER:`
> labels. This is a single-speaker recorded conference talk by David Khourshid at the "Beyond the
> Prompt" conference (hosted by AG Grid and Bryntum in London, 2026; published on the AG Grid
> channel), so speaker labels are not required. The `[H:MM:SS]` timestamps are the STT segment
> starts. The STT mangles several proper nouns: the title word "determinism" is rendered
> "Terminism" (0:00:17); the speaker's handle "David K Piano" (@DavidKPiano) is rendered "David K.
> Piena" / "David K. Pino" (0:00:36, 0:19:46); "XState" appears as "Xstate" (0:00:46); "Claude" as
> "clod" / "clods" (0:07:19, 0:07:26); "useState" as "use dates" (0:18:40); and "Gary Bernhardt" as
> "Cary Bernhardt" (0:19:36). The visual-editor URL is rendered "stately.sketch.ai" (0:01:52). The
> canonical spellings — David **Khourshid** / **@DavidKPiano**, **XState**, **Stately.ai**,
> **Claude**, **useState**, **Gary Bernhardt** — are taken from the official video description (via
> `yt-dlp`) and general knowledge, not the STT.

## Description

Official video description (AG Grid channel):

> Vibe coding feels productive until you have to maintain it. Behind the agent "thinking..." you
> ignore and the code you never opened lies a growing pile of wasted tokens, nondeterministic
> behavior, and compounding errors hiding in plain sight. This talk pushes back on the status quo:
> elaborate agent architectures, "prompting astrology", overnight automation loops burning through
> context windows and credit cards. Come for the critique, leave with a framework for using AI to
> build software you actually understand.

Speaker (from the video description):

> David Khourshid is the founder of Stately.ai and creator of XState, the most popular open-source
> state machine & statecharts library. He's a longtime advocate for event-driven modeling and
> visual diagramming as the foundation for reliable UIs and, increasingly, AI agents. When he's not
> at a computer keyboard, he's at a piano keyboard.

- X/Twitter: https://x.com/DavidKPiano

This talk was part of the **Beyond the Prompt** conference, hosted by AG Grid and Bryntum in London
in 2026.

## Transcript

﻿[0:00:05] Hello, and thank you very much.
[0:00:07] And I'm very excited to be here in London.
[0:00:10] I'm sure you could tell by my accent that I'm not from here.
[0:00:13] I came from Florida, where it's a lot warmer than here.
[0:00:17] But I'm here to say goodbye, slop, and welcome to Terminism.
[0:00:21] So before I get into it, I sort of want to qualify what I'm talking about.
[0:00:27] I'm not just one of those people who goes on Twitter or social media and says,
[0:00:31] this model changes everything and you know just talk about AI like it's some
[0:00:36] fad. I'm living this day to day. I'm David K. Piena pretty much everywhere
[0:00:41] online and as was mentioned I have been talking about state machines for a long
[0:00:46] time. I created this open source library called Xstate which is a library for
[0:00:52] making state machines and state charts and that was about ten years ago. Five
[0:00:56] Five years ago, I founded a company called stately.ai
[0:01:00] where we allow you to make it easier
[0:01:02] to make state machines.
[0:01:03] And I will demonstrate a little bit of that later,
[0:01:06] but I have been really, really busy.
[0:01:09] So over the last few months,
[0:01:12] I've been working on a new version of our stately editor,
[0:01:15] the next version of XState's v6.
[0:01:18] And to give you an idea,
[0:01:21] XState has been a part of many critical systems.
[0:01:24] It's very useful for complex application logic.
[0:01:27] And if you live in the UK,
[0:01:30] then I can almost guarantee that you've interacted
[0:01:33] with something that relies on XState.
[0:01:37] I'm not allowed to say what that is,
[0:01:39] but you can maybe guess.
[0:01:41] Also been working on a couple of other open source things
[0:01:43] like XState Store v4, a graph library,
[0:01:48] an open source completely free state machine visualizer,
[0:01:52] which you could check out at stately.sketch.ai some other open source like with tan stack a
[0:01:58] couple of large projects that i'm not allowed to talk about and i'm doing all of this while helping
[0:02:03] my wife take care of a three-month-old who is actually in the audience so if you hear
[0:02:08] a crying baby then that's either my son or claude has gone down and someone is complaining about it
[0:02:16] But yeah, needless to say, I'm tired, never as tired as my wife, but definitely tired.
[0:02:22] And I thought that having a baby was actually going to be, you know, not too bad.
[0:02:27] It's a tiny thing.
[0:02:29] How hard could it be?
[0:02:30] You know, it's crying, you feed it, it eats.
[0:02:33] When it's fed, it sleeps.
[0:02:34] And honestly, for the first couple of days, it was embarrassingly deterministic.
[0:02:39] This is all it was.
[0:02:40] but then we got home from the hospital and we soon realized that babies are a
[0:02:45] little bit more complicated than I realized this is actually something that
[0:02:51] got me really interested in state machines and state charts not not having
[0:02:55] a baby but like ten years ago where there's this thing called state and
[0:02:59] transition explosion where when things get complex you see an explosion of
[0:03:05] transitions and states everywhere and having a baby taught me about new types
[0:03:09] types of explosions too, I won't get into that.
[0:03:12] There's also some unknown transitions
[0:03:14] where I'm crying along with a baby.
[0:03:17] But yeah, I realize that babies are actually
[0:03:21] pretty non-deterministic.
[0:03:23] Things are getting harder and harder.
[0:03:25] I mean, we're at the three month mark,
[0:03:27] so we'll see what happens.
[0:03:29] But I wanted to define determinism
[0:03:31] because I feel like we throw these terms around a lot.
[0:03:35] Determinism in the simplest terms possible
[0:03:38] is given the same input, you have the same output.
[0:03:43] So conceptually, you can think about this
[0:03:45] like a pure function.
[0:03:46] It's not exactly a pure function
[0:03:48] because of course this can be async,
[0:03:50] but the idea is that whatever you give in,
[0:03:53] you know exactly what the result is going to be.
[0:03:57] Non-determinism is different.
[0:03:59] Non-determinism means that given the exact same input,
[0:04:02] you don't exactly know what's going to come out.
[0:04:06] Now, this doesn't mean that it's going to be completely random.
[0:04:09] It could be a fixed set of choices, and it's not exclusive to LLMs.
[0:04:14] I learned about determinism and non-determinism through, you know, finite state machines.
[0:04:20] We have DFAs, which is deterministic finite automata, and NFAs, which is non-deterministic
[0:04:27] finite automata.
[0:04:28] And interestingly enough, you could convert NFAs to DFAs, but what happens is that the
[0:04:35] the state machine gets a lot more complex.
[0:04:37] So you're paying for that complexity in structure.
[0:04:40] And so that's where I got really interested in state charts
[0:04:43] because it sort of helps you contain
[0:04:46] and reduce that complexity and makes it really visual
[0:04:49] so that you could describe things like Casio watches
[0:04:53] or microwaves or complex web apps,
[0:04:55] or as we're going to see soon, AI agents as well.
[0:05:00] So, you know, AI agents have changed the game
[0:05:03] and before AI I was constantly working on a couple of side projects that you
[0:05:10] know it would be hard for me to finish them but of course AI came along and now
[0:05:14] I have 15 to 20 unfinished side projects and as you previously heard going to a
[0:05:20] prototype is easy but going to production is hard and I think one of
[0:05:25] the main reasons for this is that AI has actually made it a lot easier to skip
[0:05:29] skip engineering and just go straight to, you know, let's prompt, let's see what comes
[0:05:35] out, and then let's just work with that.
[0:05:38] And so this is the practice that, as I'm going to talk about, I sort of want to see eliminated.
[0:05:44] So my opinion in what the best way to build with AI is, is actually the same way that
[0:05:52] we should build without AI.
[0:05:54] So, if we go back a few years before LLMs came about, you know, the principles are the
[0:06:02] same.
[0:06:02] So, in my opinion, model thoughtfully.
[0:06:05] So, think about what is the structure of my program, what's the vocabulary, the shared
[0:06:12] language that we should use, and how can we best represent the blueprints of the app without
[0:06:18] building it first.
[0:06:20] Iterate sufficiently.
[0:06:21] So, you know, just going back on the code and going from rough prototype to something
[0:06:27] that's a little bit more solid and realize what the gaps are, go back and keep iterating
[0:06:33] on it.
[0:06:34] And also make core logic explicit.
[0:06:37] This is something that I've been talking about for many years and is also why I like state
[0:06:41] machines and state charts.
[0:06:43] Make it so that it's very clear and not scattered all over your code base.
[0:06:49] because the root problem again in my opinion is it's not vibe coding it's not AI is taking over
[0:06:58] everything it's not even AI hallucinating it's it actually starts from us it's unstructured
[0:07:04] delegation it's when we decide you know what let's throw everything over the wall and let's
[0:07:10] let the agents take care of judgments take care of the structure and implementation and sometimes
[0:07:16] Sometimes even taste.
[0:07:17] I know some of you are guilty where it's like,
[0:07:19] I don't care how it looks, just clod, make it look pretty.
[0:07:24] Codex cannot be trusted to do that yet,
[0:07:26] but clods pretty good at it.
[0:07:27] And out comes slop, but guess what?
[0:07:30] The slop works, so who cares?
[0:07:33] Spoiler alert, your users care when the code
[0:07:36] slowly rots from the inside out,
[0:07:39] and it takes longer to maintain features,
[0:07:41] or you have big security holes, or things like that.
[0:07:44] that. So, yes, we do need to care. And slop is not a new thing. It's not an AI exclusive
[0:07:53] thing. I'm sure you've seen PRs like this before. Maybe not a million lines of code
[0:07:58] had it, but you've seen PRs like this and what is your first instinct looks good to
[0:08:03] me, right? Like, okay, let's just skim through it. Let's accept it. And all of a sudden,
[0:08:08] you know, button is rewritten in Rust and you have to just deal with that. And, of course,
[0:08:13] Or we're even dealing with this when we work with AI where it gives us this crazy bash
[0:08:18] command and you're like, okay, yeah, go for it, dude.
[0:08:21] I don't know what this does.
[0:08:22] But I'm sure it's fine.
[0:08:24] And I'm definitely guilty of this.
[0:08:28] So what is slop code exactly?
[0:08:31] In my opinion, slop code is code without a reliable model.
[0:08:35] It is code that you can't fully understand.
[0:08:38] You can't fully explain.
[0:08:40] plain. It's code where you're not sure whether all of the edge cases are covered, whether
[0:08:44] it works or not. It might look like it works on the surface, but you cannot be entirely
[0:08:50] sure. So it doesn't mean broken code. It might not even be bad code, but slop code does have
[0:08:57] a lot of properties, like no clear domain boundaries, the invariants are not explicit,
[0:09:04] You can't really inspect the states and the behavior is scattered throughout the app.
[0:09:10] And there's really no safe way to change it.
[0:09:12] And like I was saying, this stuff existed even before LLMs.
[0:09:16] So you know, but it works, right?
[0:09:21] And this is why we allow slop code to really permeate throughout our code base.
[0:09:27] But the problem is that this stuff's addictive.
[0:09:30] It's like a this is sort of a triple pun.
[0:09:32] It's a state machine, slot machine, slop machine, and yeah, we just keep pulling that lever.
[0:09:39] If the code isn't exactly what we want or the behavior is not exactly what we want or
[0:09:44] it doesn't look exactly right, we just pull that lever again and we see, you know, maybe
[0:09:50] we could get a bit of a better result.
[0:09:52] This is addicting and this is also what just, you know, makes the slop permeate throughout
[0:09:58] our entire code base and all of our projects.
[0:10:01] Now, you might be saying, well, isn't AI better than me at coding?
[0:10:06] Like it has all of the knowledge everywhere, so surely it's going to make better decisions
[0:10:11] than me.
[0:10:12] And I'm going to argue that no, that's not exactly the case, because LLMs weren't trained
[0:10:16] on good code.
[0:10:17] They were trained on all of our code.
[0:10:19] And so what that means is it's going to repeat our patterns.
[0:10:24] It's going to latch on to things that already exist in the code base, and it's just going
[0:10:29] to keep rolling with those things so in the industry there's really two ways that i'm seeing
[0:10:36] right now that's um that behavior and this structure is sort of represented basically
[0:10:42] where this source of truth lives the first is markdown files we have things like skills we have
[0:10:49] like claw.md agents.md you know we have all of our plans in here and markdown is just a natural
[0:10:57] language way of trying to describe intent. Now, a lot of people might argue that the code is a
[0:11:04] source of truth, too, because, of course, this is where everything gets executed. But I would say
[0:11:09] that code is a noisy source of truth because, sure, we are encoding all of our intent, but we're
[0:11:16] mixing it with just architecture and boilerplate and just all sorts of different patterns. And it
[0:11:24] it turns out that probably 90% of our code
[0:11:28] has nothing to do with the behavioral intents
[0:11:32] that we seek to explain in our markdown.
[0:11:35] So this really points to one hidden layer,
[0:11:38] which is the central theme of this talk,
[0:11:41] which is having an explicit model.
[0:11:44] So the difference is you could think of this
[0:11:47] as a combination of intent and execution,
[0:11:50] where a model is structured.
[0:11:52] structured. You can still have natural language in the model. The code can map directly to
[0:11:58] the model, and also everything that we intend to do in our app can map directly to the model
[0:12:04] as well. And I'm going to demonstrate that later. But yeah, so first let me define what
[0:12:11] a model is. And I'm not talking about large language models. I'm talking about just modeling
[0:12:16] modeling software. So in my mind, a model is an explicit representation of how the system
[0:12:23] should behave. And so this is why I like state machines so much, because with state machines,
[0:12:29] a very common way of describing the behavior is given when then statements. You might have
[0:12:35] heard of them as Gherkin or cucumber, but you could say given I'm in this state, when
[0:12:41] when this event happens, then I'm in this state.
[0:12:44] And so, again, those map to states, events, and transitions,
[0:12:50] and you could basically put that to a graph.
[0:12:53] State machines, though, are not the only way
[0:12:55] to model software, and they're not the only aspect
[0:12:58] of software that you can model.
[0:12:59] So logical flows, you could use state machines,
[0:13:02] BPMN, state charts, of course, flow charts even,
[0:13:06] just simple diagrams.
[0:13:07] You could also model your data,
[0:13:09] And, you know, domain-driven design comes into play a lot here.
[0:13:14] And I'm sure Matt Pocock will talk about that later.
[0:13:17] But, you know, these things are becoming more and more relevant.
[0:13:22] Now, you might also be thinking, if models matter so much and they're so important to making good software, why doesn't AI tend to go for them?
[0:13:32] And the answer is simple, actually.
[0:13:34] It's because agents are very obedient, but they ironically don't have much agency.
[0:13:39] You tell an agent build the feature, it's going to pretty much go straight to code.
[0:13:43] Sure, it has a thinking loop, but when you're refining, you're working with that noisy artifact, that noisy source of truth, so you're just having the agent mess around in the code trying to iterate on it.
[0:13:57] However, if you do have knowledge of saying, I know exactly how I want to model this, then the agent will provide you that model.
[0:14:07] So I'm not saying that you have to create these models from scratch, instead you could
[0:14:11] have AI say I'm going to help you create this model and using that model, that shared understanding,
[0:14:18] we're going to work on the feature and so when we need to make refinements and iterate
[0:14:23] on it, we can update the model and then reference that model in the code.
[0:14:28] So we still have this executable description of our code base without all of the noise
[0:14:34] of code now I see a lot of failure modes where where projects tend to exclude
[0:14:41] models one of them is one shotting and this is definitely popular in some of
[0:14:47] the earlier AI applications I've seen where we think okay we could go
[0:14:50] straight from a prompt to the result and I'll demonstrate basically what the
[0:14:57] opposite of this is but the truth is a lot of apps don't actually or shouldn't
[0:15:02] to work this way because iteration and human input is still important.
[0:15:07] Another one is prose control flow.
[0:15:09] So for example, skills are really popular, and skills are really useful for saying this
[0:15:15] is important knowledge that you should have when you're working in the code base, but
[0:15:20] if your skills say you must do this, you should never do this, only do this when this happens,
[0:15:27] and then do step one, step two, step three,
[0:15:30] then you're trying to represent control flow
[0:15:33] in natural language, and you're really hoping
[0:15:36] that the agent is gonna follow it, and sometimes it won't.
[0:15:40] Also, agents as the system, so sometimes we think
[0:15:45] throwing more agents at the problem
[0:15:46] is going to fix everything, and again,
[0:15:49] that's just asking for more chaos
[0:15:51] if we don't constrain the system.
[0:15:54] time. There is a talk about this later, AI in the AG Studio, that I'm looking forward to,
[0:15:59] which does talk about basically a multi-agent approach and having a structure for that.
[0:16:06] Or I hope it does. I didn't see the talk yet. Neither did you. And there's also entanglements
[0:16:12] of concerns. AI and agents are really good at just getting the job done. They want the software
[0:16:20] to work and then it will say goal complete and the result of this is the same as if we
[0:16:26] you know we go back to being junior developers and we're like okay forget about separation of
[0:16:32] concerns forget about organization we're just going to mix everything together and if it works
[0:16:37] it works and one solution that we might think will fix all of this is just larger context windows
[0:16:46] windows, but that's not always the case.
[0:16:49] More context does not mean more structure.
[0:16:52] You can't just keep shoving instructions into context and telling it you must do this or
[0:16:57] you must follow this workflow exactly.
[0:17:00] The context just gets noisier, and just because models can handle larger context doesn't mean
[0:17:07] that they're going to perform better.
[0:17:09] There's many, many studies on this.
[0:17:11] this. Another problem is that if we keep doing this, we have compounding slop. And so I've
[0:17:19] experienced this a lot where I would just let the code run amok and let the agents do
[0:17:23] whatever they want. The problem is that agents make assumptions. They fill in the gaps with
[0:17:29] what they think is best. And some of those assumptions are going to be wrong. Like, AI
[0:17:35] cannot read your mind, so it's going to try to fill in the blanks. And these wrong assumptions
[0:17:40] are amplified throughout your code base.
[0:17:42] Again, AI is going to follow the existing patterns
[0:17:46] in your code base, and so that's just going to make
[0:17:49] the bad assumptions permeate and even get worse.
[0:17:53] So I like to describe a missing model of the code base
[0:17:57] as a missing blueprint.
[0:17:59] Imagine that you're building a house,
[0:18:01] and you decide, okay, how do we start?
[0:18:04] Let's start with one wall.
[0:18:06] Okay, now we need to build a floor over here.
[0:18:09] you're okay, there should probably be a wall on this side.
[0:18:11] And then you keep going and going and you're like,
[0:18:14] okay, I think we have four walls,
[0:18:15] so now let's try to put a roof on the thing.
[0:18:18] How do you think that house is going to look?
[0:18:20] And also, would you live in that house?
[0:18:23] Probably not.
[0:18:24] It might eventually look good from the outside,
[0:18:28] but structurally, you know,
[0:18:29] like this was not well designed or designed at all.
[0:18:32] We were just building things until it sort of looked right.
[0:18:35] Right?
[0:18:35] So that's why a blueprint is so important.
[0:18:40] And one common thing I've seen in React apps is, like, I've given talks on use dates where
[0:18:47] you would start with just this pattern of using state for everything and then it sort
[0:18:51] of expands and then you get apps that look like this.
[0:18:55] And again, AI is just following the patterns that already exist in your code base.
[0:19:01] So what is the inversion?
[0:19:03] What is the solution to all of this?
[0:19:05] Ken Wheeler recently tweeted about this,
[0:19:09] where he said agent-driven workflows
[0:19:11] with a sprinkling of deterministic tools
[0:19:13] are a fool's errand, and I completely agree with this.
[0:19:16] He says to expect these deterministic workflows
[0:19:20] to be a sprinkling of AI instead of the other way around,
[0:19:25] doing what they're actually good at.
[0:19:28] I saw another term in an article recently
[0:19:30] called deterministic core agentic shell,
[0:19:33] which sort of mirrors the functional core
[0:19:36] imperative shell statement by Cary Bernhardt,
[0:19:39] and I really like this,
[0:19:40] and he actually called me out in this article.
[0:19:43] He said, you know, if this wasn't enough
[0:19:46] to summon David K. Pino, it definitely did,
[0:19:48] which is why I'm putting it on the screen,
[0:19:50] but I really like that framing,
[0:19:52] because I'm starting to see two types of apps now.
[0:19:55] One of them is LLMs that call programs,
[0:19:58] Basically, all of the workflow logic lives in the LLM.
[0:20:02] We trust the agents to say, you know what, you'll route and you'll probably do the correct
[0:20:07] thing.
[0:20:07] You're super smart.
[0:20:08] We'll let you be the traffic controller or the air traffic controller or whatever.
[0:20:15] And this is risky.
[0:20:17] It's also a little bit lazy.
[0:20:18] So I want to invert this and I want to encourage you to write programs that instead call LLMs.
[0:20:25] Basically, move the non-determinism to the edges and move the determinism to the core.
[0:20:32] Because like I mentioned, a lot of apps don't look like this or shouldn't look like this
[0:20:37] anymore.
[0:20:37] Instead, they require these steps in the middle where we're iterating.
[0:20:43] And this is where non-determinism and this deterministic structure fits.
[0:20:48] fits, because inside of that iteration step
[0:20:52] can be that structure, those well-defined workflows
[0:20:56] where we have AI at the nodes, at the edges.
[0:21:01] Matt is actually going to talk about the software development
[0:21:04] lifecycle later, and I'm excited to see
[0:21:07] how he incorporates that into this flow.
[0:21:11] So this is all to say that AI-driven apps
[0:21:14] apps are getting more complex, and we do need that structure.
[0:21:18] Now I know that some of you might argue that some of this might seem like too much ceremony,
[0:21:23] but I will argue that modeling is not ceremony when it replaces confusion.
[0:21:29] So this means that you don't have to model absolutely everything in your app formally.
[0:21:34] Really only the confusing parts.
[0:21:37] And I think this is where it's most useful, and also, AI is really good at helping you
[0:21:43] model things as well so you don't have to physically write every single line out yourself.
[0:21:49] We've seen this a lot with rough prototyping when we're doing UX.
[0:21:54] You start with something rough and then you just keep iterating on that until it actually
[0:21:59] looks good.
[0:22:00] You don't have to make everything a very formalized specification at the beginning.
[0:22:06] So start rough and then iterate on it.
[0:22:09] it.
[0:22:11] Like I mentioned earlier, I've been working on the next version of the stately editor,
[0:22:16] and it does have some AI parts, but it's also one of the most complex apps that me and a
[0:22:24] bunch of others have worked on, and yeah, so I have a lot of battle scars here, and
[0:22:30] I know that because we have a structure, I'll just breeze through this real quick, but because
[0:22:37] Because we have a structure where the core logic is represented, in our case with state
[0:22:42] machines, it makes it really easy to let AI actually help with feature developments.
[0:22:48] Because AI is not going to mix concerns or do anything like that.
[0:22:53] AI has a clear picture of what the core logic is and how it interacts with the different
[0:22:59] parts of our app.
[0:23:00] So one of the engineering practices that I think is still relevant to this day is separation
[0:23:06] separation of concerns because AI will prevent slopping up your code base and making a mess
[0:23:12] of it if your concerns are explicit and well separated.
[0:23:19] Now I talk about state machines a lot, but I will say that you don't necessarily need
[0:23:23] state machines.
[0:23:24] The important thing is that you need structure.
[0:23:27] There's another talk about this later that I'm excited about where agents work well in
[0:23:33] structure.
[0:23:34] structure. So you're not only helping yourself, but you're helping agents as well. And while
[0:23:39] I have a few minutes, I want to show you just really a quick demo of what exactly I'm talking
[0:23:45] about. So let's say that you are tasked with creating an AI app that has to draft emails.
[0:23:52] And so you would give it a prompt, and the prompt would be, okay, I want to make an email
[0:23:58] about something. And typically, if we were going back a few years, we would just have
[0:24:03] have the LLM take that prompt and spit out an email.
[0:24:06] But nowadays, the requirements, the bar
[0:24:09] is higher because we might want that email to be refined.
[0:24:14] We might want to make sure that that email is factually
[0:24:17] accurate and good to go and that nothing is missing.
[0:24:21] So this app becomes a little bit more complex.
[0:24:24] And so what I did was I used XState.
[0:24:28] And I basically formulated this as a state machine
[0:24:32] so that we could say, first work on the draft,
[0:24:35] or sorry, first work on requirements.
[0:24:38] See that we have all of the information,
[0:24:40] and then once we have everything, create a draft.
[0:24:43] And then iterate on that draft with the user,
[0:24:46] and then when we're happy with it, send it.
[0:24:49] So instead of throwing this all to AI,
[0:24:51] I'm using a state machine,
[0:24:53] and basically I'm having that formal model
[0:24:56] help me structure this workflow out.
[0:24:58] out. So, for example, if I have a draft request, and I'm actually going to show you the state
[0:25:04] machine here, but if I have a draft request of find me after my talk, that's very vague.
[0:25:13] And so, it's actually going to navigate through the states and it's saying, hey, I need to
[0:25:18] know who the recipient is or what the subject is. So, I'll add details. It's you at example.com
[0:25:27] and it's my talk on determinism so it's going to be evaluating again and I think
[0:25:35] that's enough detail so we're gonna go and draft anyway and then it's going to
[0:25:40] draft an email and then this looks really formal so I'm just gonna say my
[0:25:47] name is David make it less formal and then it's going to draft again I'm
[0:25:55] I'm thankful that the internet works here.
[0:25:57] And let's see.
[0:25:58] This looks good.
[0:25:59] We have all of my information.
[0:26:02] So I'm just going to go ahead and send it.
[0:26:06] And so the biggest difference between this and your typical AI
[0:26:11] app is that we have a formal structure and a highly visual
[0:26:17] one, too, for how the agent works.
[0:26:20] And so we're not putting the agents in every single part of this workflow.
[0:26:26] The non-deterministic parts are the fuzzy parts, like is the email missing anything
[0:26:31] or even drafting the email, something that we cannot express fully in code.
[0:26:36] And the deterministic parts ensure that we're at the right state at the right time.
[0:26:41] So it should be impossible to send the email without approving a draft, and it should be
[0:26:47] impossible to create a draft without having all of the requirements satisfied.
[0:26:53] And this is pretty simple.
[0:26:56] Again, you don't need a state machine specifically, but the important thing is that you are keeping
[0:27:02] what should be explicit and deterministic as the core of your entire application and
[0:27:09] then at the edges using LLMs to actually execute and to do the fuzzy non-deterministic things.
[0:27:16] And then you just continue the loop, and honestly, this structure works for most things.
[0:27:22] If you wanted to create your own cursor, then it's exactly this type of while loop as well.
[0:27:28] So how do we transition to determinism?
[0:27:31] What I want you to do, maybe not today, maybe tomorrow or next week, look at your existing
[0:27:37] applications, pick one confusing workflow in there, could just be one, and model it
[0:27:44] explicitly.
[0:27:44] think about how can you organize this to make more sense.
[0:27:49] Now this might look like decoupling UI from the core logic, or
[0:27:53] maybe you have a workflow where you're just handing everything off to an AI agent
[0:27:57] instead of having that codified in your actual code.
[0:28:02] And there's many ways you could do this, but
[0:28:05] the guiding principles I like to do is ask yourself what can be deterministic in
[0:28:11] in there, so don't let your AI agents do deterministic things.
[0:28:17] Where is iteration useful?
[0:28:18] So what parts of it can we actually
[0:28:20] use a human in the loop to help refine the results?
[0:28:25] And of course, where can the logic
[0:28:27] be separate from the UI, which is good advice
[0:28:30] whether you're working with AI or without AI.
[0:28:34] So in short, nondeterminism should
[0:28:36] be at the edges of your AI applications,
[0:28:39] And determinism should be at the core, so we should prevent doing the things that we've
[0:28:45] been doing before, one-shotting, putting control flow in natural language, letting agents and
[0:28:51] sub-agents run amuck, and mixing concerns and making our code base messier.
[0:28:58] So going back to my baby, our son, things are getting more and more non-deterministic,
[0:29:05] However, we've had lots of help from friends, family, books, lots of resources, and that
[0:29:11] provides a model for understanding what do we do next?
[0:29:15] What do we do when our baby reaches four months, when the baby gets older?
[0:29:20] It doesn't make the complexity go away.
[0:29:23] It provides a framework so that the complexity of dealing with the baby is survivable.
[0:29:29] And your code base is your baby, or at least your company's baby.
[0:29:33] I don't know how you feel about your code base, but the model is not just to be this
[0:29:41] random artifact.
[0:29:42] The model is for future you, the model is for your team, and the model is especially
[0:29:48] for your agents so that it could stop producing slop and actually produce good code.
[0:29:54] And I believe that the model is how collaboration survives the speed, like these 10x speeds
[0:30:00] that we're getting by building with AI.
[0:30:03] So in short, the best practices didn't change.
[0:30:07] AI, of course, made it easier for us
[0:30:09] to forget about the best practices,
[0:30:12] but I really feel like the best practices
[0:30:14] have become more important now than ever.
[0:30:18] So thank you so much, London, for having me.
