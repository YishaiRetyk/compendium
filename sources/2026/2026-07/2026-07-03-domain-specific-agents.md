---
title: "The Future Is Domain-Specific Agents — Justin Schroeder, StandardAgents"
author: "Justin Schroeder"
channel: "AI Engineer"
publication: "YouTube"
url: "https://www.youtube.com/watch?v=spNAUEgq_A8"
date: 2026-06-29
source_type: transcript
privacy: cloud_safe
---

# The Future Is Domain-Specific Agents — Justin Schroeder, StandardAgents

> Machine-transcribed from the video's audio with the `stt` CLI (faster-whisper large-v3,
> English, user-specified). Automatic speaker diarization did NOT run — the pipeline's diarizer
> dependency (TorchCodec) was unavailable — so the committed transcript carries no `SPEAKER:`
> labels. This is a single-speaker recorded conference talk by Justin Schroeder at the AI Engineer
> World's Fair (published on the AI Engineer channel), so speaker labels are not required. The
> `[H:MM:SS]` timestamps are the STT segment starts. The STT renders the speaker's surname as
> "Schrader" and his X handle as "JPSchrader"; the canonical spellings — Justin **Schroeder**,
> **@jpschroeder** — and his company name **StandardAgents** are taken from the official video
> description (via `yt-dlp`), not the STT. His open-source project "ArrowJS" is rendered "Aero.js"
> by the STT.

## Description

Official video description (AI Engineer channel):

> "Composition over inheritance" has always been a good engineering rule. It may also be the
> unlock for useful AI. A Gmail agent is fundamentally more powerful than a Gmail skill — and when
> composed with Sheets, Notion, and GitHub agents, the system gets more capable, more reliable, and
> cheaper to run. Suddenly, smaller models can do real work, and AI can move from internal copilots
> to customer-facing products. In this talk, we'll unpack why this architecture hasn't become the
> default yet, what's been missing, and how to start building toward it today.

Speaker (from the video description):

- **Justin Schroeder (StandardAgents)** — Co-founder of StandardAgents. Compulsive open source
  builder. Creator of dmux, ArrowJS, FormKit, AutoAnimate, Tempo, zodown.
  - X/Twitter: https://x.com/jpschroeder
  - LinkedIn: https://www.linkedin.com/in/jpschroeder/
  - GitHub: https://github.com/justin-schroeder

## Transcript

﻿[0:00:02] Okay, so I'm going to be talking about domain-specific agents and why I really think that they are going to play an unbelievably important role in the future of AI and in the future of how we build agents.
[0:00:16] To get started real quick, my name is Justin Schrader.
[0:00:19] You can find me on X at JPSchrader.
[0:00:23] And I work at a small company called Standard Agents,
[0:00:26] which nobody's heard of right now because we're still kind of in stealth mode.
[0:00:30] After this talk, if you're interested, feel free to reach out to me
[0:00:33] and I can let you know a little bit more.
[0:00:37] Mostly, I'm known for doing a lot of different open source projects.
[0:00:41] DMUX, which is a great multiplexer for all of your coding agents.
[0:00:45] Aero.js, which is sort of like a UI framework, sort of like React for the agentic era.
[0:00:51] A bunch more that I won't get into, but maybe check them out if you're interested.
[0:00:56] Okay, I think we can all agree that the moment in time that we are in is very similar to the Industrial Revolution.
[0:01:04] In fact, it might be like an accelerated Industrial Revolution.
[0:01:07] Maybe it's a bigger deal, but it's certainly not smaller.
[0:01:10] I probably don't need to convince you of that if you're listening to one of these talks.
[0:01:13] but that is the moment we find us find ourselves in so I actually think it's
[0:01:18] helpful to go back and sort of look at what was the key catalyst of the
[0:01:23] Industrial Revolution and ultimately it was that we learned how to harness
[0:01:27] energy with machines we learned how to harness energy with machines and what's
[0:01:32] interesting is that in this next era we are essentially learning to harness
[0:01:37] harness intelligence with agents. And agents, I think, can be thought of a little bit like the
[0:01:44] machine of yesteryear. It's the thing that is going to use the intelligence. Not so much us,
[0:01:52] but the agents. What's interesting about that is, I bet if I was in an actual room with you guys and
[0:01:59] we all put up our hands, I bet a lot of you, when I say, what is an agent, instantly have examples
[0:02:05] examples that pop into mind, but also probably can't pull out a definition immediately.
[0:02:10] Some of you maybe can, but the reality is that we haven't even coalesced on a definition
[0:02:17] of what an agent is, even though we're well into the agentic era at this point.
[0:02:22] And I think that's kind of interesting.
[0:02:25] Here's my definition.
[0:02:26] You can feel free to agree with it or not, but agents are deterministic software that
[0:02:32] harness the non deterministic results produced by models in pursuit of some
[0:02:37] desired objective now deterministic software might make you think more like
[0:02:44] a harness and I actually think the distinction between an agent and a
[0:02:48] harness is really pedantic not very helpful and for the most part in most
[0:02:54] cases you can just conflate the two a harness is an agent and an agent is a
[0:02:58] harness okay and for the for the purposes of this talk we're gonna go
[0:03:02] ahead and just move forward with that I think you could probably make some good
[0:03:05] arguments for why one is the other and vice versa but really not important
[0:03:10] right now now if you did have some examples pop to mind they might have been
[0:03:15] like Claude or Codex you know open claw Hermes but you know what's interesting
[0:03:21] is I bet if you went out on to you know the the streets of corporate America in
[0:03:26] any city maybe not san francisco but any city in america and you asked somebody just in an
[0:03:33] office building could you name an agent by name i think some people are going to get clawed some
[0:03:43] people might get codex and that's about it i don't think hardly anybody's going to be getting open
[0:03:48] claw or hermes and and really even claude i don't know that people would even know that that's an
[0:03:54] an agent. These things are not well understood. And yet what's so crazy is everybody is building
[0:04:02] agents. I have a real estate agency down the street that's building agents. I know in like
[0:04:08] independent private insurance brokers building their own agents. I know fortune 500 companies,
[0:04:14] lots of them building their own custom agents. Everybody is trying to build their own custom
[0:04:21] agents and I know people don't believe me but go talk to them just go talk to
[0:04:26] people they are trying to build custom agents and I can't help but wonder why
[0:04:31] nobody seems to be asking this question why there's already AI everywhere you
[0:04:36] can get on chat GPT all the way down to some open source model from China on
[0:04:41] some you know rickety website there's everything in between but still people
[0:04:45] want to build custom agents and ultimately it comes down to integration
[0:04:49] Businesses want their data properly integrated into AI.
[0:04:54] They believe and are probably right that if they appropriately leverage AI,
[0:05:00] they're going to have these dramatic gains in their business and so on and so forth.
[0:05:04] So they need to figure out how to get integrated.
[0:05:06] And building their own custom agents is obviously a way to do that.
[0:05:11] And it's one of the first ways that they discover as a mechanism for doing it.
[0:05:15] The problem, though, is that agents are really hard.
[0:05:20] You have to take very, very careful care of the agentic loop and make sure that it's properly orchestrated.
[0:05:27] There are a ton of different provider abstractions you need to think about.
[0:05:31] Fortunately, there's some good tools coming out around that, you know, like the Vercel AISDK is great.
[0:05:38] Durable execution, you need to make sure if there's faults, we can pick back up.
[0:05:42] these are relatively hard problems especially if you're thinking about it
[0:05:47] at scale and the reality is there's just tons more there's all kinds of
[0:05:51] validations and stop conditions and so on and so forth and so what often
[0:05:55] happens is people do try to build their own custom agents and they sort of work
[0:05:58] as a demo but but not much more than that and really it turns out that it's
[0:06:03] an absolute nightmare for people building robust agents is just hard and
[0:06:09] And if you go talk to anybody in an IT department,
[0:06:13] they are pulling their hair out
[0:06:15] because there are so many different concerns.
[0:06:18] There's no defined way to build an agent right now.
[0:06:20] Like actually no defined way.
[0:06:22] The closest thing maybe is Eve
[0:06:25] that just came out from Vercel
[0:06:27] is maybe like the closest thing.
[0:06:29] But in reality, everybody's kind of coming up
[0:06:32] with their own way to do it.
[0:06:34] Telemetry and observability on these agents
[0:06:36] is unbelievably hard, especially at scale.
[0:06:38] If you want to know exactly what is getting transmitted on every single step of every
[0:06:43] single turn of your agent, so that way you can diagnose it and fine tune it and make
[0:06:48] sure things aren't going off the rails, that is very hard to do.
[0:06:52] Agents are also not portable.
[0:06:54] So if I do get a good agent working, if I've managed to climb to the top of this mountain
[0:07:00] and I've got a good agent that's finally working well, well, it works well on my machine.
[0:07:06] But if I try to pass that off to somebody else, there's a very high likelihood that between all of the environment variable configurations and system requirements and run times, there's a good chance it's not going to run on that person's machine.
[0:07:19] And they're not composable.
[0:07:21] So even if I get a really good chatbot working for my university, the chances that I'm going to then be able to reuse that for another thing is very, very low.
[0:07:32] I can't just easily share that.
[0:07:35] So what often happens is after a short pursuit towards agents people kind of back away say, okay fine
[0:07:41] No more agents. No agents. Instead. We're gonna do the MCP thing. We've heard about this it works and sure enough
[0:07:49] Model context protocol it does work and really it works pretty well to take, you know, your corporate
[0:07:56] Information like Zillow's information and then shove that into one of these really large
[0:08:02] pre-existing agent something like Claude or ChatGPT which I would consider a
[0:08:07] large general-purpose agent and it sort of works like that and it works okay but
[0:08:14] if you take a look this is actually from the MCP website and if you take a look
[0:08:19] at what is supported in MCP clients around the world you will notice that
[0:08:24] only one of these columns is actually filled out all the way down and that of
[0:08:31] course is tools so MCP has become a de facto tool distribution mechanism for
[0:08:38] agents so if I need to get my company's tools into that other agent then MCP is
[0:08:46] a good way to do that it has not proven to be great at providing other value yet
[0:08:53] and frankly tools are just not enough you know I like to joke that we didn't
[0:09:00] land a man on the moon by giving one guy a ton of tools. That's not a realistic way to get a really
[0:09:07] large project done. So, you know, maybe MCP is not the way, but aha, we have skills. We have skills
[0:09:17] and skills are great. I actually do enjoy skills. I'm sure you do too. We install them all the time
[0:09:23] for all kinds of things. And fundamentally what a skill is, is a markdown file, which basically
[0:09:28] works as documentation. Now, interestingly, there's lots of research out there that shows
[0:09:33] that if you use very many of these, it actually makes your agent substantially worse, but they do
[0:09:39] work as documentation for various complex things. So, you know, back to the analogy of a man getting
[0:09:46] to the moon, it's a little bit like just giving this guy, you know, a ton of documentation and
[0:09:51] the documentation is going to help, but it's not the fundamental problem. So what's the fundamental
[0:09:57] problem okay let's build up a basic agent stack here let's start with a
[0:10:03] model all agents start with a model a big one small one doesn't matter they
[0:10:07] start with a model then you have something like a system prompt on top of
[0:10:11] that which tells the model what its role in the grand universe is sort of like
[0:10:17] it's it's life objective then we have tools the things that it can actually do
[0:10:22] the effects it can take and then skills would be layered on top of that and
[0:10:27] And then MCP would be layered on top of that.
[0:10:30] And then finally,
[0:10:31] you have all the messages from the conversation.
[0:10:33] That is roughly the stack of information
[0:10:37] that gets passed along within the runtime of an agent.
[0:10:41] And if you take a look here,
[0:10:42] almost all of it is context.
[0:10:48] Basically everything, the system prompt, tools, skills,
[0:10:50] all of that is stuff that ends up
[0:10:52] in the context of the agent.
[0:10:55] And so basically people are trying to solve the integration problem by working on the context or the model.
[0:11:06] These are the two areas where we constantly see new advances.
[0:11:10] We also see new things come out like skills and MCP, new technologies, new protocols.
[0:11:17] They are all coming out in the area of the context and the model.
[0:11:22] So how does it actually work then? Well, basically you work at a company, you
[0:11:31] occasionally need to do some business travel, so you've got a couple travel MCPs
[0:11:35] installed. You've also got, you know, Figma and Playwright installed on yours.
[0:11:39] And all of these are building up in that context layer. And then you've got some,
[0:11:44] you know, Gmail MCPs to go check your mail for you and some Google Sheets to
[0:11:48] go fill out some other, some other expense reports or something like that.
[0:11:52] and then you've got skills you're a developer so you've got some react
[0:11:56] fixers and linters this is actually I think like the number one or the number
[0:12:00] two most popular MCP server that's out there maybe you've got Matt's grill me
[0:12:06] skill or or maybe you've got the github skill and basically what you're doing is
[0:12:11] you are inflating that context layer and we have a term for this in engineering
[0:12:16] it's called inheritance the idea of inheritance is you take an object and
[0:12:21] and then you add more attributes to it
[0:12:24] to allow that one object to have other properties, right?
[0:12:29] And that's exactly what we are doing here with an agent.
[0:12:33] We're saying this agent is pretty good,
[0:12:35] but if we add all of these additional extra layers,
[0:12:39] then the agent can do stuff
[0:12:41] that it previously couldn't do before.
[0:12:44] That is exactly what inheritance is.
[0:12:46] And the truth about inheritance is it works.
[0:12:49] It does work.
[0:12:50] that's why these things are out there and they are working but there's an old
[0:12:56] saying composition over inheritance and it turns out this this is as old as time
[0:13:03] eventually inheritance starts to break down imagine like you know okay I've got
[0:13:09] five skills on chat GPT or on our on Claude excuse me and that works pretty
[0:13:15] well now what if I have a hundred skills what if I have a thousand skills there's
[0:13:20] There's some point at which I get diminishing returns from adding additional context.
[0:13:25] That's just obvious.
[0:13:27] We all kind of understand that implicitly.
[0:13:29] So is there an alternative?
[0:13:31] Well composition is the alternative to inheritance.
[0:13:34] It looks something like this.
[0:13:35] So imagine we have another little agent and again we're trying to provide Figma as a thing
[0:13:43] that can be done by our primary agent.
[0:13:45] Well, what we could do is have a tiny little agent where the actual system prompt of the
[0:13:51] agent is written specifically to be a Figma agent.
[0:13:56] It knows everything about Figma.
[0:13:57] It knows all of its context, all of its API, all of the right places to click and the things
[0:14:03] to do and mouse movements to make and everything like that.
[0:14:06] And then it has these precise tools that it needs to perform all of those actions and
[0:14:11] nothing more, just that.
[0:14:13] and then a very small message history which just has to do with the Figma
[0:14:19] portion of this and then you can have more of these you can still have your
[0:14:22] Gmail and your travel and your Google sheets and all that kind of stuff but
[0:14:26] each of them is a separate isolated agent a full agent not just a little
[0:14:32] server with tools on it it's a full agent with its own message history its
[0:14:36] own agentic loop and then above these you have a coordinator and the
[0:14:43] communication mechanism for all of these small agents speaking to the larger
[0:14:49] agent above it is just English they just talk to each other the way human does so
[0:14:55] if the primary agent is saying oh I should I should check my mail to see if
[0:15:00] there's anything about going on a trip well it knows to go ask Gmail for any
[0:15:06] new emails about a trip those funnel their way back up says oh yeah actually
[0:15:11] there's a trip coming up to Los Angeles this weekend and then it can go to our
[0:15:17] travel agent and start to make bookings that's kind of a rough idea of how
[0:15:23] something like this could work and the reality is it does work and we know it
[0:15:29] works because this is actually how we got to the moon there were teams of
[0:15:34] experts teams of experts with faces that looked like that and faces that looked
[0:15:40] like that each of them with different skills and capabilities and faces that
[0:15:45] looked like that this is the Apollo 11 launch day and look right here there's
[0:15:49] an agent I just found an agent sitting right there that brain of his is that's
[0:15:55] his LLM and here's his tools right there on the dashboard those are the tools now
[0:16:00] Now, he didn't have all the tools.
[0:16:01] He just had those tools.
[0:16:03] And he was really, really, really good at them.
[0:16:06] And then, look at that mouth.
[0:16:07] That's the messages.
[0:16:09] We are used to this.
[0:16:11] We can understand this.
[0:16:12] It implicitly works.
[0:16:14] It's almost a form of biomimicry for the agentic world.
[0:16:18] It works.
[0:16:20] And I call them domain-specific agents.
[0:16:23] I don't think I was the first person
[0:16:24] to utter the words domain-specific agents.
[0:16:26] Certainly not the first person to have this idea.
[0:16:30] But that is what I want to talk to you about, agents that are just targeted to very specific domain.
[0:16:37] And we over here at Standard Agents have been building this ecosystem for quite some time.
[0:16:43] So we've gotten to have a really good inside look at how they actually work.
[0:16:47] And I'm not ready to come out here and announce a product or anything like that, but I can give you a little bit of a peek.
[0:16:52] First of all, they are far more token efficient, far more token efficient.
[0:16:57] We regularly see over 80% token efficiency for any given task
[0:17:03] Now it's a little more complicated because you have to define those tasks a little bit more ahead of time
[0:17:09] But if you can have an agent portability where I can take that gmail agent
[0:17:14] Squeeze it up and then send it to somebody else
[0:17:17] We can create an ecosystem where we don't have to create every one of these skills and capabilities
[0:17:22] But within that domain you're going to get dramatic efficiency
[0:17:28] And part of the reason is, if you think about the way that the context works, I don't need
[0:17:33] to have the entire context of the conversation when I make a choice to do something.
[0:17:39] Instead, my primary coordinator level can just ask the Gmail, hey, get that last email
[0:17:46] from Debbie.
[0:17:47] And that is the totality of the context.
[0:17:49] It literally just has the system message, its tools, and that message that came in.
[0:17:55] and so it is then able to perform this very targeted very specialized tiny
[0:18:00] little thing without all of the surrounding context it's also far more
[0:18:08] practical with small language models if you look at the difference in two models
[0:18:15] like deep seek v4 flash and fable five the cost difference is mind-boggling it
[0:18:25] is a hundred and thirty seven times cheaper than fable per task a hundred
[0:18:34] and thirty seven times now granted if deep seek v4 flash fails over and over
[0:18:42] and over again to do the job then not only is it going to be you know not that
[0:18:47] much cheaper it's also going to be much more annoying to use it but that's why
[0:18:52] domain specific agents are so great because you don't need to have the v4
[0:18:57] flash do everything instead it only needs to do the tasks that have been
[0:19:03] specifically picked for it to do and with a very minimal context it can
[0:19:08] and execute those very faithfully.
[0:19:11] So you get these dramatic cost reductions,
[0:19:14] not only with the token efficiency,
[0:19:16] but also because you can use much smaller language models
[0:19:19] and even non-language models.
[0:19:21] You can use image generation and diffusion models.
[0:19:24] You can use all kinds of other models for smaller tasks.
[0:19:29] You can also enforce really strict limits
[0:19:32] on the capabilities.
[0:19:33] And I think you know what I'm talking about.
[0:19:36] I'm talking about this.
[0:19:36] we are all flying awfully close to the Sun nowadays where everybody's just
[0:19:42] bypassing permissions left and right and of course you have to because a coding
[0:19:47] agent with a big model can do anything and so we use it to do everything in a
[0:19:56] world that would be powered by smaller domain specific agents those agents
[0:20:00] can't do everything they can only do the things that are already explicitly
[0:20:04] approved for them to do it doesn't mean that you still can't have permissions
[0:20:08] and permission dialogues but you are opting into a much more controlled
[0:20:13] ecosystem and I promise you when you explain that to Doug in IT he it puts
[0:20:21] his heart at ease understanding the difference between those two and fourth
[0:20:26] these have excellent scaling characteristics because each of these
[0:20:30] agents is its own small little execution environment you can parallelize them you
[0:20:35] can put them on the cloud very easily without needing like a giant VPC up
[0:20:39] there you can run thousands of instances all at the same time in in all kinds of
[0:20:46] regions of the world they don't actually need to be you know geographically
[0:20:50] co-located or anything like that so they have very very good scaling
[0:20:54] characteristics unfortunately they don't exist that's the downside these domain
[0:21:03] specific agents don't really exist not in a big public way like I said here at
[0:21:10] standard agents we have them we are working with them on a daily basis but
[0:21:15] they are not out there in public very much yet however that's changing that is
[0:21:22] going to change very quickly we're about halfway through 2026 and and I'm here to
[0:21:27] make a public prediction that I think as we roll on from from this point to the
[0:21:32] end of 2026 we are going to see a dramatic uptick in people talking about
[0:21:39] building domain specific agents frameworks around them all kinds of
[0:21:44] things are coming down the pipe and it's not going to be a small trickle it's
[0:21:49] it's going to accelerate rapidly and this will become a one of the main players in the agentic
[0:21:55] ecosystem and 2027 i would say is basically the year of multi-agent orchestration that's another
[0:22:02] word you'll start to hear a lot i think so that's my big bold public prediction i was really excited
[0:22:09] just a few days ago when vercell released eve this is the first time i actually saw the term
[0:22:17] that I had been blasting out into the void
[0:22:19] come back and hit me in my own face.
[0:22:22] The framework for building agents,
[0:22:24] build a company brain, personal assistant,
[0:22:26] or domain-specific agent.
[0:22:29] So there we go.
[0:22:30] About halfway through the year,
[0:22:32] we're going to start picking up steam.
[0:22:34] That's my prediction.
[0:22:37] And there's a number of reasons.
[0:22:38] One of them is something that most people believe right now
[0:22:42] is that the cost of intelligence is going down.
[0:22:44] that trend reversed in 2026 actually we track this on on a website tokens are
[0:22:53] not getting cheaper anymore they are actually going up even when adjusted for
[0:22:58] IQ they're up 29% when you adjust for IQ just this year halfway through the year
[0:23:03] we're already up 30% and that can be caused by lots of different things of
[0:23:08] course we've got this memory crunch and and you know probably the long-term
[0:23:12] trend over a 10-year cycle or something is that intelligence will go down but
[0:23:17] that does not mean that we need to be paying a hundred and thirty seven times
[0:23:21] the cost for something that can be done just as effectively the problem is it's
[0:23:26] harder to break those things apart now if you don't account for IQ tokens are
[0:23:33] up 76% this year almost a hundred percent increase in tokens just this
[0:23:39] this year and we're not even halfway through it.
[0:23:43] So we are really trending upwards on token costs.
[0:23:47] So anything we can do, especially with large businesses
[0:23:50] to bring that down is gonna be really important.
[0:23:52] The other use case to really consider
[0:23:55] is putting AI in front of customers.
[0:23:58] You can't put Fable in front of a customer
[0:24:02] unless that customer has a massive lifetime value.
[0:24:05] It's just too expensive.
[0:24:06] so you need to find a way to create great efficacy while being efficient and
[0:24:13] domain specific agents are gonna be the way to do that so I'm gonna leave you
[0:24:17] here and momentarily but before I do let's just dream a little bit let me dig
[0:24:22] in a little bit deeper to how an agent could be orchestrated and what an ideal
[0:24:29] agent would actually look like and then I promise to leave you alone here we go
[0:24:35] So remember we got that model and we got the system prompt and then at the tool layer
[0:24:40] Let's break that apart a little bit on one hand. We have these like functions
[0:24:44] This would be like an actual function that can get executed like write a file to the file system. Then we have
[0:24:51] prompts
[0:24:53] Prompts are a lot like the system prompt, but they are smaller
[0:24:58] individual prompts that can get injected and
[0:25:01] and sub prompts that can, you know,
[0:25:04] you can run a function that actually calls an LLM.
[0:25:07] So let's say I have a main agent running,
[0:25:10] but I want to use nano banana just to generate an image
[0:25:13] when I'm using GLM, you know, 5.2 as my primary.
[0:25:18] Well, you can just have a tool that's a prompt.
[0:25:20] That would be really cool if you could do that.
[0:25:23] And then another type of tool
[0:25:25] could be another full blown agent,
[0:25:27] like a complete other domain specific agent could just be one of the tools so
[0:25:33] that's the tool layer and then you have hooks what are hooks well in this ideal
[0:25:40] world a hook might be something that can kind of harness or change or mutate or
[0:25:46] perform side effects so let me give you an example LLMs have no idea what time
[0:25:51] it is at any given point in time turns out a really great way to tell them what
[0:25:56] time it is is you inject an artificial message or an artificial tool call in
[0:26:03] the message history so it looks like somebody just said hey what time it is
[0:26:07] and the other person replied oh it's 6 45 p.m. Pacific time pretty simple you
[0:26:15] can do that with a hook or you could fire off some side effect using a hook
[0:26:20] so this is an important piece of an agent and then finally there's there's
[0:26:25] these agent rules and agent rules are kind of complicated it's like how many
[0:26:29] times should one side have a turn like can it go on for 10,000 turns or 10,000
[0:26:37] steps before its turn is up you know there's there's all kinds of interesting
[0:26:40] little rules you know when it calls a tool you know is it required to validate
[0:26:46] the whole thing or not you know all kinds of very specific tools or rules
[0:26:52] that belong to a specific agent and all together if we bundled all that up we
[0:26:57] would call that an agent but it's kind of missing a couple things one every
[0:27:02] agent should really have a file system if you've ever done this with chat GPT
[0:27:08] or Claude or codex if you just ask it you know not inside of a project or
[0:27:13] anything like hey can you make me a PDF for my my son's birthday party well
[0:27:20] Well, it'll do it and it'll store it
[0:27:22] in its own little file system.
[0:27:24] So the big labs have already realized
[0:27:26] that in order to create an effective chat interface,
[0:27:29] not to mention a big agent,
[0:27:30] it needs some sort of file system.
[0:27:33] So every agent should have
[0:27:34] its own little sandbox file system.
[0:27:36] And also every agent should have
[0:27:39] a sandboxed code execution location.
[0:27:42] So it can write files, it can run those files,
[0:27:45] and it can do that safely without exfiltrating anything,
[0:27:48] without interacting with an OS at a higher level that needs to be baked in
[0:27:52] as a primitive to every single domain specific agent okay so let's say that
[0:27:58] that's our ideal agent and now let's talk about that little agent tool there
[0:28:01] what is that well those can be sub agents recursive sub agents even you
[0:28:08] could have an agent that calls a sub agent that calls sub agents that call
[0:28:13] sub agents and there could be one or there could be many of these at
[0:28:17] different levels so for example you could have this coordinator agent that's
[0:28:21] at the very top and then you could have a Salesforce agent and that agent knows
[0:28:25] Salesforce inside and out and knows all of its API's and knows has all the
[0:28:29] credentials to communicate with your Salesforce instance in all the
[0:28:32] appropriate ways and then it needs to communicate with a Google workspace
[0:28:37] agent so it can do all kinds of stuff in there it can run spreadsheets I can say
[0:28:41] hey what are all my tops my top salespeople this year and boom it can
[0:28:46] look in salesforce it can coordinate with the sub-agent create a sheet for you send that back
[0:28:51] perfect but maybe then you need to generate some assets so the salesforce agent actually has
[0:28:56] another sub-agent that it can talk to at any time at once and it's amazing at generating assets
[0:29:02] maybe that sub-agent doesn't just have like you know codex image generation maybe it has
[0:29:07] nano banana maybe it has an svg generator all kinds of stuff so that way it is an amazing
[0:29:13] asset generator and perform some of its own reflection in QA and then our
[0:29:19] primary agent might need a whole legal team agent just so I can check the work
[0:29:24] that's coming out of these other ones and maybe the legal team agent really
[0:29:27] needs a gdpr compliance agent just for those European customers you know the
[0:29:32] main one doesn't have all you know we don't want to have 45 megabytes of
[0:29:36] context just on gdpr so we make that a separate sub agent so you know me and
[0:29:42] And then maybe the legal team also needs like an OSHA compliance agent,
[0:29:46] which is also very complicated.
[0:29:47] And so it has a separate one for that.
[0:29:49] You kind of get the idea.
[0:29:50] You can end up with all kinds of highly efficient, small little agents
[0:29:55] that are all working together, but maintaining small, minimal context
[0:30:01] windows all the way through.
[0:30:04] That's the idea behind domain specific agents.
[0:30:07] So thank you very much.
[0:30:09] I appreciate you listening to my talk.
[0:30:10] again standard agents is where we're working standard agents dot AI you can
[0:30:14] actually sign up on there for early access we are slowly starting to roll
[0:30:20] this out to a few people if your business is super ambitious and really
[0:30:24] wants to try out small domain specific agents then you know you can write me
[0:30:29] info at standard agents and of course I'd appreciate a follow thank you so
[0:30:33] much bye
