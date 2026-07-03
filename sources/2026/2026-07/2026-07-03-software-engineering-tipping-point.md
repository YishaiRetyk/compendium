---
title: "Software Engineering at the Tipping Point — Adam Bender, Google I/O 2026"
author: "Adam Bender"
channel: "Google for Developers"
publication: "YouTube"
url: "https://www.youtube.com/watch?v=2n41YjR5QfU"
date: 2026-05-21
source_type: transcript
privacy: cloud_safe
---

# Software Engineering at the Tipping Point — Adam Bender, Google I/O 2026

> Machine-transcribed from the video's audio with the `stt` CLI (faster-whisper large-v3,
> English, user-specified). Automatic speaker diarization did NOT run — the pipeline's diarizer
> dependency (TorchCodec) was unavailable — so the committed transcript carries no `SPEAKER:`
> labels. This is a single-speaker recorded conference talk by Adam Bender at Google I/O 2026
> (published on the Google for Developers channel), so speaker labels are not required. The
> `[H:MM:SS]` timestamps are the STT segment starts. The speaker's name and the talk's framing are
> confirmed against the official video description (via `yt-dlp`). The audio is clean studio
> conference narration and the proper nouns transcribe accurately (e.g. "Conway's Law," "Jeff
> Atwood," "Jevons paradox," the "Flamingo book"); one canonical spelling to note is that the STT
> renders **DORA** (Google's DevOps Research and Assessment group) as "Dora."

## Description

Official video description (Google for Developers channel):

> Learn to use systems thinking to understand how developer ecosystems guide the evolution of your
> software systems. Improve your intuition for the systemic impacts of AI-driven software
> development and understand how you can better prepare for the exciting changes coming to our
> industry.

- **Speaker:** Adam Bender
- **Event:** Google I/O 2026
- **Products mentioned:** AI/Machine Learning, Cloud
- Professional Development sessions from Google I/O 2026: https://goo.gle/professional-developement-IO26
- Google for Developers: https://goo.gle/developers

## Transcript

﻿[0:00:06] Hey, everybody, how are you doing? Hey, that's pretty good. That's pretty good. 3 p.m. on
[0:00:15] a Wednesday. That's a Wednesday. Not so bad. Welcome to software engineering at the tipping
[0:00:21] point. My name is Adam Bender, and today I'm going to talk to you about something called
[0:00:26] software ecology, a term you might not have heard before. I want to talk about it because
[0:00:31] it will tell us something about the impact of AI on our developer ecosystems, the developer
[0:00:35] ecosystems you work in every day. Now, I don't know if you guys have noticed this,
[0:00:39] but things are getting pretty weird out there, right? Your job in 2026 does not
[0:00:44] look like what you thought it would in 2020, I assure you that. If you tried to
[0:00:48] explain to 2020 me what this was gonna be, I would not have believed you. It can
[0:00:53] be a bit overwhelming to try and figure out where all this change is taking us,
[0:00:57] right? And while I can't predict the future, I think that if we study our
[0:01:02] software ecosystems as they are today, some of the answers we're looking for are a lot
[0:01:06] closer than we think. I think that software ecology, this idea, it gives us the perfect
[0:01:11] lens for framing this particular moment in our industry. Now, I can hear you asking,
[0:01:16] what is software ecology? And did he just make this up to get on stage? I did not. It
[0:01:22] is a real term. But before I define it, I want to set some context for you. So we're
[0:01:26] going to go a little deep dive on systems thinking. I hope you're okay with that. Hang
[0:01:30] hang with me. I promise you it will all make sense when we get there. So let's start with
[0:01:34] the concept of a system, right? A system. It's a group of interrelated elements that
[0:01:39] act according to a set of rules to form a unified whole. That sounds pretty fancy, but
[0:01:44] you know systems. They look like this. This is a system you're probably pretty grateful
[0:01:47] for today. This is what air conditioning is, right? So you have a thermostat that knows
[0:01:51] what temperature to be, you have an HVAC that's going to jack the temperature up or down,
[0:01:55] and you have a room, and when the temperature is right, the signal stops. That's a system.
[0:02:00] If you're a software engineer, you're probably used to thinking about systems all the time.
[0:02:04] You design them, you build them, you operate them. But one thing you've probably learned
[0:02:08] when working with systems is that everything is connected. Everything. That's a theme you're
[0:02:14] going to hear from me a couple times today. Now let's move on to an ecosystem, which is
[0:02:19] a particular kind of system. This is a long one, so bear with me. An ecosystem is a dynamic
[0:02:25] network of interdependent actors that co-evolve with their environment, characterized by emergent
[0:02:30] behavior and decentralized agency. Ecosystems are complex. They're built from complex components.
[0:02:38] The components themselves are deeply connected. They have agency. They can make decisions.
[0:02:42] They can do things. And critically for us, the environment is a part of that system.
[0:02:47] system, right? The environment is a part of the system. You can't separate the two. So
[0:02:53] ecosystems are also a kind of complex adaptive system. A complex adaptive system, or CAS,
[0:02:58] they're characterized by their ability to grow and change and evolve over time. All
[0:03:03] the cool systems are complex adaptive systems, right? Now, complex adaptive systems, they
[0:03:08] possess this emergence quality as well. An emergent property is something that you can't
[0:03:12] see by looking at any individual piece of the system. You can only see it when the system
[0:03:16] is all put together. And then you see behavior emerge out of it. And it's that constant change,
[0:03:21] that learning, plus the emergence that make it really hard to figure out what's going
[0:03:25] on in an ecosystem. Now, when you think of ecosystems, or at least when you thought of
[0:03:31] them before you walked in here, this is probably what you had in mind. And frankly, I'd like
[0:03:35] to be here right now, right? Looks kind of idyllic. But your internal developer environment,
[0:03:39] it is also a kind of ecosystem. You have all your tools and services. You have complex
[0:03:44] actors, you have people with opinions and things they want to get done, you have
[0:03:47] business constraints. This is a system too, and in fact it's a particular kind
[0:03:52] of system. It's a socio-technical system. A socio-technical system is just kind of
[0:03:57] a fancy way to say a system made of people and technology. Now socio-
[0:04:02] technical systems are incredibly complicated. They're complicated because
[0:04:06] you start with all that technology and then you mix in the people, right? There's
[0:04:11] a pretty good chance though that you've encountered some wisdom about
[0:04:14] about socio-technical systems without even realizing it.
[0:04:17] Have any of you ever heard of Conway's Law?
[0:04:19] Yes, of course, everyone has heard of Conway's Law,
[0:04:21] but briefly, Conway's Law goes like this.
[0:04:24] Organizations build technologies
[0:04:26] that mirror their internal communication structures.
[0:04:28] Or informally, if you have a four-team group
[0:04:31] working on a compiler,
[0:04:32] you're gonna get a four-pass compiler.
[0:04:34] That's just how it works.
[0:04:35] Now at its core, Conway's Law is an observation
[0:04:38] that the way we build technology is inseparable
[0:04:41] from the structure of the organizations that build it.
[0:04:43] it. The organisations shape what gets built. Now, of course, it's not just the organisational
[0:04:49] structure that impacts our developer ecosystems, right? The values and culture of an organisation
[0:04:54] can have just as profound an impact. Your ecosystem builds what your organisation incentivises.
[0:05:00] Your engineering culture creates the environment around your developer ecosystem. See, the
[0:05:06] thing is, once you learn about socio-technical systems, you see them everywhere in software
[0:05:10] software development. From your architectures to your postmortem culture to code review
[0:05:15] to security policy, they're everywhere. The things we build and the way we choose to build
[0:05:19] them are a reflection of what we value. If we're thoughtful, we can use that knowledge
[0:05:24] to amplify our values and put them into the things we build, boosting the kinds of outcomes
[0:05:28] that we want. So now I think I can properly define for you software ecology. Software
[0:05:36] Software ecology is the holistic study of the socio-technical ecosystems that produce
[0:05:40] software.
[0:05:42] All right.
[0:05:42] Now we're all caught up.
[0:05:45] It's okay if all that felt a little abstract, by the way, because now we're going to look
[0:05:48] at a real example.
[0:05:50] We're going to talk about Google's developer ecosystem.
[0:05:53] Google has a very large, and I would argue somewhat complicated, developer ecosystem.
[0:05:58] Because over the last 25 years, we have evolved truly remarkable capabilities and, yes, a
[0:06:04] little complexity.
[0:06:05] Now, as an upfront disclaimer, I'm talking about Google partly because I work there,
[0:06:09] but it is the developer ecosystem I understand the best.
[0:06:11] My intent here is not to tell you you've got to go do what Google did.
[0:06:14] That's not going to be good for you, right?
[0:06:16] You're a different company.
[0:06:17] You're in a different place.
[0:06:19] You have a different set of tradeoffs you're worried about.
[0:06:21] Now, like any engineering organization, Google has made a lot of choices.
[0:06:25] They were very specific to the needs we had at the time we were building our ecosystem.
[0:06:29] Your situation?
[0:06:30] Different.
[0:06:32] So, a few years ago, we wrote a book.
[0:06:33] book. Maybe some of you have seen this book before. Internally, we call it the Flamingo
[0:06:37] book. We wrote this book to give people an understanding of how Google actually worked
[0:06:42] inside. And we spent half this book talking about things like version control and testing.
[0:06:46] But the entire first half of this book was spent on engineering culture. And we used
[0:06:50] to get a lot of questions about that. Why so much on engineering culture? Well, the
[0:06:52] reality is, if you don't understand the culture that Google has, you can't appreciate why
[0:06:57] we have the technical choices that we've made. These things are interlinked. Now, in case
[0:07:02] you didn't read the book, I'm going to give you a brief tour. Don't worry, you don't need
[0:07:05] to read all this. Yes, take pictures. That'll be fine. There's a few things about Google
[0:07:09] that make it somewhat unique. So, for example, we're deeply engineering-led. Engineers are
[0:07:13] always in the room when important decisions are being made. We're big on transparency.
[0:07:17] We try to make all the docs and code that we can available as often as possible. We
[0:07:21] encourage people to be helpful. In fact, if you talk to anyone who's ever left Google,
[0:07:25] the helpfulness of their colleagues will be one of the most important things they cite.
[0:07:28] We treat code review as an opportunity for mentorship and not test grading. We're big
[0:07:33] on standardization, real big on it. We believe in continuous improvement. We're big into
[0:07:39] blameless postmortems. We're big on the idea that sustainability is better than heroics and that
[0:07:43] automation is better than toil. Now, we don't always achieve all of these ideals, but this
[0:07:47] is kind of what we're aiming for culturally. And on the technical side, we have our monolithic
[0:07:52] repository you've probably read about. I'll tell you more about that in a second. We have trunk
[0:07:56] chunk-based development where every change lands at head every time. When you build a
[0:08:01] binary at Google, almost every line of code is built from source. That's pretty wild,
[0:08:05] right? We have a universal build tool chain. Everybody uses it. We have a global test automation
[0:08:09] platform. One place runs all the tests. Billions of tests a day. We have a global signal for
[0:08:15] the last green. I can tell you the state of any build looking at one simple internal website.
[0:08:19] We have a uniform compute environment, so it works on my machine isn't possible, mostly.
[0:08:23] closely. We have opinionated developer frameworks and a small set of core languages. And it's
[0:08:28] this mixture of culture and technology that give rise to what Google is. You can't understand
[0:08:34] one half without the other. Now, if I had to pick one principle, one principle that
[0:08:39] seems to have guided us implicitly if not explicitly at times, it's this thing called
[0:08:43] shared fate. Now, shared fate is a term that describes the degree to which an ecosystem
[0:08:48] ecosystem and its components are tightly linked to each other. In a high shared fate ecosystem,
[0:08:53] one component can affect everything else, right? Now, in a developer ecosystem, shared
[0:08:59] fate is as much a technical choice as a social one. You can't just get shared fate by making
[0:09:04] everyone use the same technology. You also have to develop social contracts for how you're
[0:09:08] going to manage that technology, right? Now, at Google, our shared fate starts with our
[0:09:13] monolithic repository. Every line of code at Google, with a couple notable exceptions
[0:09:17] exceptions, like Android and Chrome, is in one shared repository. Everything. Everything
[0:09:22] is committed to trunk. There are no branches, there are no versions. Everything in one place.
[0:09:27] This kind of shared fate allows us to apply a security patch in one file and know that
[0:09:32] within a week, every application of the company will have been patched. That's like a superpower.
[0:09:37] Ten lines of code in the right place can patch ten billion lines of application and system
[0:09:44] system software. That's pretty impressive, right? Now, shared fate isn't always a good
[0:09:50] thing. Shared fate is a choice. There are places where shared fate might make less sense.
[0:09:55] For example, in our production environment, we don't want one service to take down all
[0:09:59] the other services or one cluster to affect an entire region. So we have worked really
[0:10:04] hard, Google in particular has worked really hard to make sure we don't have the dangerous
[0:10:07] kinds of shared fate that cause things like cascading failures. Again, the point is shared
[0:10:12] shared fate is a trade-off. You have to figure out the right place to put it and then make
[0:10:16] sure that it works well for you. Now, one of the most interesting emergent properties
[0:10:20] of our shared fate environment is this notion of large-scale changes. Now, long before AI,
[0:10:27] way before AI, Google's internal tools have made it possible for a single developer to
[0:10:32] change literally millions of lines of code. Millions of lines of code. Code they will
[0:10:37] never look at, they will never see again, they might know nothing about it. We've built
[0:10:41] tools that make that automatically possible today, and we've been doing it that way for
[0:10:45] at least the last 15 years. This kind of capability has let us evolve our monorepo over time.
[0:10:50] We can update languages and frameworks. It's really what keeps our internal environment
[0:10:54] from becoming stagnant. It's no exaggeration to say that without it, we wouldn't be the
[0:10:59] Google that we are today, right? And the folks who work on those tools would tell you it's
[0:11:02] an unsung hero's kind of job to keep this company moving at the speed it needs to move.
[0:11:09] move. The thing about large-scale changes is you can't appreciate them unless you understand
[0:11:13] the cultural components and the technical parts of our ecosystem that make it possible.
[0:11:17] For example, you need a widespread testing culture. Everybody needs to be writing tests
[0:11:20] for me to be able to do this. We need to have a single platform so I know where to look
[0:11:23] to get the results of those tests. It's good to have common build tools so we're all building
[0:11:27] the same software. I build it, you build it, we get the same outcome. We need a standard
[0:11:31] set of libraries so as we're swapping things out, we're not jumping around trying to find
[0:11:34] which version of this library is working for you and not me right we need standardized code review
[0:11:38] we need transparency in the mono repo itself so i know which code needs to be changed lscs are truly
[0:11:44] the ultimate manifestation of this automation over toil ethos at google and it's only possible
[0:11:49] because of the entire ecosystem you can't point at one part of our developer environment and say
[0:11:53] that's why lscs happen it's everything linked together right now every developer ecosystem
[0:11:59] ecosystem, yours, anyone you've ever worked in, they have these emergent properties. They're
[0:12:03] usually the things that feel somewhat unique to the place that you work. And that's because
[0:12:07] they're usually the result of the constellation of choices you have made to shape how you
[0:12:12] want to work. So every ecosystem has something like this. Google has large-scale changes.
[0:12:16] You have something else. Google's developer ecosystem embedded in our specific engineering
[0:12:22] culture has produced a unique set of trade-offs. They serve our technical and business goals.
[0:12:26] goals. However, Google's ecosystem, like every ecosystem, cannot excel at all tasks. We've
[0:12:32] chosen to optimise for extreme scale, security, performance, right? And we'll do that typically
[0:12:38] even if it comes at the expense of developer productivity sometimes. That's a trade-off
[0:12:41] we're willing to make in our ecosystem. The developer ecosystem of other places, like
[0:12:46] say a five-person start-up, is going to look different, and that's okay. And a five-person
[0:12:50] start-up, velocity and agility are like the most important things you can possibly have.
[0:12:53] have. Somewhere in between a five-person startup and Google is where you are, right? Most of
[0:12:59] you are inhabiting an ecosystem that's somewhere between five people and 200,000. The tradeoffs
[0:13:04] you're going to make are really important to pay attention to, because when you look
[0:13:07] at the tradeoffs being made, you can begin to understand the values of the organization.
[0:13:10] What does it really care about? Not what does it say it cares about, but what does your
[0:13:14] organization actually care about? And when you understand those values, you can begin
[0:13:18] to shape the transformation as it begins to unfold. We're all experiencing a lot of transformation
[0:13:23] good to understand where we're going. I hope by now the concept of a software ecosystem
[0:13:28] is a bit more clear, and I think it's time we talk about the token-eating elephant in
[0:13:33] the room. What does an AI-first developer ecosystem actually look like? Now, it would
[0:13:39] be nice to build one of these out from scratch, a greenfield ecosystem, but I would bet none
[0:13:44] of you have that luxury, right? You all have to continue shipping software, doing what
[0:13:48] it is you're doing today, while you're replacing literally every part of it. No big deal, right?
[0:13:52] Your company is depending on you to continue delivering
[0:13:54] value and make sure that nothing breaks.
[0:13:57] So to make sure nothing breaks,
[0:13:59] let me ask you a question.
[0:14:00] How well do you understand your developer ecosystem today?
[0:14:04] Can you map it all out?
[0:14:07] Do you know where all the pieces are?
[0:14:08] Not just the technical ones, but the social ones.
[0:14:10] Can you enumerate what your ecosystem is actually built from?
[0:14:13] How well do others in your organization understand it?
[0:14:15] What are its strengths or its weaknesses?
[0:14:17] Where are your bottlenecks?
[0:14:19] Where are you constrained or where are you free? What optionality do you have? What kind of
[0:14:24] emergent properties have you seen in your own ecosystems? And perhaps most importantly, if your
[0:14:28] ecosystem suddenly had to grow by, I don't know, 10 to 15x in the next 18 months, do you know what
[0:14:34] would break first? See, the thing about that last question is we're all going to have to answer it
[0:14:39] real quick. Because every developer ecosystem on earth is going through a radical transformation.
[0:14:45] information. Maybe it hasn't gotten to everywhere you are yet, but it's coming. Every single
[0:14:51] developer ecosystem is going to have to wrestle with this idea of this 10x moment. I wish
[0:14:56] I could tell you there was a way out of this, but it's coming, right? These are incredible
[0:15:00] times, but they are also somewhat confusing. All the tradeoffs we have deliberately evolved
[0:15:05] over the last 25 years are going to get rebalanced. You've heard that from probably every speaker
[0:15:10] here in some form or another. We don't know yet what the future is going to be. We're
[0:15:13] we're trying to figure it out.
[0:15:14] Some folks are predicting productivity
[0:15:15] that looks like 10x, 100x.
[0:15:18] We're measuring things in orders of magnitude.
[0:15:21] That's a lot, right?
[0:15:22] Suddenly the question of 10x growth
[0:15:24] is not just a thought exercise.
[0:15:27] It's like a code red moment for you and your company.
[0:15:29] You're gonna have to figure this out.
[0:15:31] If not today, certainly in the next 12 months.
[0:15:34] Now, before I go much farther,
[0:15:35] I really wanna stress that I understand
[0:15:37] there's a big difference between generating code
[0:15:39] 10 times faster and engineering 10 times faster.
[0:15:43] These are different things.
[0:15:44] And in fact, at Google, we often say
[0:15:46] that engineering is programming integrated over time.
[0:15:49] But the thing is, we're speeding up programming a lot.
[0:15:52] We're making the code machine go fast.
[0:15:54] So we're going to have to figure out how we engineer around that
[0:15:57] code machine in order to deliver real results to our customers.
[0:16:01] No one knows yet how far we can push this productivity growth.
[0:16:04] I really don't know.
[0:16:05] We could stop next week.
[0:16:06] I don't think so.
[0:16:07] But one thing's for sure, we're going up from here.
[0:16:10] The problem is, I think we have a lot of work to do,
[0:16:13] because I would bet very good money that what we're doing today doesn't work at 10x. I would
[0:16:17] bet the way you're building software, the way I'm shipping software, doesn't work at 10 or 100x
[0:16:21] velocity. Something's going to have to change. Well, let's start by looking at a standard
[0:16:27] developer ecosystem. It's simplified, I know. Hopefully you'll recognize some of these terms
[0:16:31] up here, but let me put them in a form you're more used to seeing them. A complex graph, right?
[0:16:35] In a world with 10x more productivity, or 10x more activity rather, what has to change? Well,
[0:16:40] Well, let's start with the nodes related to getting code into the code base.
[0:16:43] Now, notably, I've excluded testing and version control, we'll get to those in a second.
[0:16:47] What happens if the green nodes suddenly have to do ten times more stuff?
[0:16:53] Well, let's start with writing source code.
[0:16:55] If everyone gets a lot faster at writing code, there's probably going to be a lot more of
[0:16:58] it, right?
[0:16:59] That's not good.
[0:17:00] Now seems like a very good time to remind you of an old Jeff Atwood quote, software
[0:17:04] is a liability, right?
[0:17:06] Right? So right off the bat, 10x more code, 10x more liability. We're not into a good
[0:17:12] place. By the way, you've probably noticed that you can't just hand everyone a bunch
[0:17:16] of tokens and say good luck. So I hope you're investing in retraining. You are investing
[0:17:19] in retraining, right? Do you know where all your engineering practices are documented?
[0:17:24] Would you know how to evolve them if you had to? Okay. Well, something to think about when
[0:17:28] you get home. Let's move on to the build system really fast. At a minimum, more code is going
[0:17:33] going to mean more compile time, right? Bigger system, more compile time. Just what we needed.
[0:17:38] I'm sure no one at your company has ever complained about slow compiles. Well, guess what? They're
[0:17:42] going to get slower. And if agents are driving a lot of work, that means more compiles. So not
[0:17:45] just bigger, but more. Compilation isn't free in time or compute. And it's possible you've never
[0:17:52] noticed how much time you spend on compilation, but I can assure you, 10 times larger, you're
[0:17:56] going to notice something, right? What about the design of all that code? Do you have the right
[0:18:01] agentic skills to encourage decoupling? What about the right server frameworks to ensure
[0:18:05] that you can compose capabilities quickly and safely? Come to think of it, do you know how
[0:18:09] many ways web applications are served in your company today? Do you know how many different
[0:18:14] server frameworks you're actually running? I don't, actually. How are you going to manage
[0:18:19] component reuse if agents are writing all of that code? Maybe you're betting it won't matter.
[0:18:24] Don't be surprised, though, if agents write code that is easy to write and hard for you to
[0:18:28] to maintain. That seems to be the benchmark right now. Agents are good at writing code,
[0:18:32] but they're not always thinking long-term the same way you and I need to. That code,
[0:18:36] I'm sure, won't be well factored. That's okay. We'll figure that part out, but the truth
[0:18:41] of it is agents are doing a lot of work for us now, and we're going to have to figure
[0:18:46] out how we apply that most effectively every single day. At some point, all that agentic
[0:18:53] work could make your binaries so big you can't compile them anymore. Or maybe they get so
[0:18:58] so big you can't ship them on phones anymore. Have you ever asked the question what is the
[0:19:03] largest binary you can compile? I actually don't know what the answer is, but I know
[0:19:08] we're bumping into limits at Google. We're getting our binaries so big in some places
[0:19:11] we can't compile them anymore. We'll figure it out, I'm sure of that, but the truth is
[0:19:16] big has lots of consequences. Scale has impacts everywhere. Now perhaps you're more of a microservices
[0:19:23] shop and you're looking at me going why would I ever build a service that big? All my services
[0:19:26] services are tiny. That's cool for you, except now I have a question. What's going to happen
[0:19:31] with 10x more network traffic? 10x more services? 10x more chatter? 10x more network traffic?
[0:19:36] Are you ready for that? No-one gets out of this unscathed. Scale has effects everywhere.
[0:19:43] Now let's say you can reliably compile all this code. I'm sure you can, right? What happens
[0:19:46] to your code review process? Everyone is worried about code review right now, and I think that's
[0:19:50] for good reason. We're putting a lot of pressure on this very human process, right? And in
[0:19:56] In many cases, it is becoming a bottleneck.
[0:19:57] One thing I know about people, they do not like to be bottlenecks.
[0:20:02] They act funny when you put pressure on them.
[0:20:04] With 10x more code, you're going to get one of two things, 10x larger changes or 10x more
[0:20:08] of them.
[0:20:09] So what does that mean for your code reviewers?
[0:20:11] Well, I'd be willing to bet most of your tech leads cannot sustain the review velocity necessary
[0:20:15] to see, I don't know, even five of these 10x developers through a day, right?
[0:20:19] That's a lot of work.
[0:20:21] So what they're going to do in order to not become a bottleneck is they're going to start
[0:20:24] They're gonna start rearranging their process.
[0:20:26] They're gonna start cutting corners
[0:20:27] to make sure they don't block anyone
[0:20:28] because no one wants to be a blocker.
[0:20:30] Now you may be able to solve part of this with AI.
[0:20:33] I'll give you that.
[0:20:34] You may be able to deploy AI
[0:20:35] to make your review process better, okay?
[0:20:38] But that only solves part of your problem
[0:20:40] because if the people on your team aren't writing code,
[0:20:42] then the only time they're encountering it
[0:20:44] is during review.
[0:20:45] But they're not paying as much attention during review.
[0:20:47] That's what we just said.
[0:20:48] So who's paying attention to the code base as it evolves?
[0:20:51] Well, no one, right?
[0:20:52] Pretty soon your code base is gonna be a mess
[0:20:54] that no one can understand. Now, in addition to all that source code, we have to think
[0:21:00] about token management. Because tokens are expensive, as some of you probably know, right?
[0:21:04] At scale, tokens are a real cost we have to factor. What happens if everyone in your company
[0:21:08] starts using ten times more tokens? Or 100 times more tokens? Or what if you accidentally
[0:21:12] spend your monthly budget in a day? A thing that has happened to a friend of mine, right?
[0:21:17] If you had to prioritize where you're going to put that spend, do you know where you'd
[0:21:20] put it do you even have the visibility to know where the tokens are going right now
[0:21:25] see even in just the first few nodes of this system this simple system we're already finding
[0:21:29] problems and it is very clear that there's going to be some challenging second order impacts
[0:21:34] now let's move on to testing inversion control these are a little bit special have you ever
[0:21:38] looked at how much compute your testing infrastructure takes i do not know about you
[0:21:42] but at google i never have fast enough tests i've never said boy my tests are going faster than i
[0:21:47] needed to today. I don't have enough capacity as it is. Right? Every change that lands in
[0:21:52] version control has to be tested, though. But also, agents love running tests because
[0:21:56] it tells them whether or not they're doing good work. So, again, the agents are doing
[0:22:00] additional work, and I have more work to do. So with ten times more commits and agents
[0:22:04] doing all that work, now how much test compute are you using? Actually, it turns out it could
[0:22:09] be worse than that. Because what we've seen at Google is that as your code base grows,
[0:22:13] grows, your dependency graph grows quadratically, not linearly with the size of your code base.
[0:22:19] So if your code base is ten times larger and you're trying to test all the dependencies
[0:22:23] so that you're sure nothing will break, you may have upwards of 100 times as many tests
[0:22:27] running. Maybe it's 1,000 times as many tests running. That's going to be a really interesting
[0:22:32] challenge and it's going to be a line item in your budget at some point. That's something
[0:22:36] you should be thinking about. So now you're not just running tests more often. They may
[0:22:42] They may be 100 times bigger, and quite frankly, if they're not going to get that big, if you're
[0:22:46] not worried about how much test compute you're spending, I'm more worried, because that means
[0:22:50] you probably don't have enough tests to begin with, and those agents are YOLOing all over your
[0:22:54] code base with no way to know what is working. All right? Now, let's assume you figure that out.
[0:23:00] You've solved compile. You've solved testing. Let's talk about your version control system.
[0:23:03] Most popular version control systems are not optimized for performance.
[0:23:06] performance? Not at all. They're optimized for consistency, ordering, right? That's their
[0:23:12] job. Their job is to keep a complete record, not to go real fast. What's the performance
[0:23:16] of your version control system? How many commits can it take a minute? I assure you it is less
[0:23:21] than you think, right? It's not going to scale to 10x the velocity that you need it to. When
[0:23:28] was the last time you even thought about the performance of your version control system?
[0:23:31] system. Ever. Not unless you work on Git, right? Honestly, if we're talking about version
[0:23:36] control performance, something has gone horribly wrong. We are in the bowels of the developer
[0:23:41] experience here. The bowels. But that's what happens when you see systemic change. Systemic
[0:23:46] change finds every corner of your system and says, hey, you paying attention? Because here's
[0:23:51] something that you weren't expecting. And by the way, for those of you who think you're
[0:23:54] going to solve this version control problem with a lot of little repos, I got some news
[0:23:58] for you talk to anyone who's run that strategy who has hundreds or thousands of little repos and i
[0:24:02] can assure you it's just an entirely new set of challenges none of which ai is going to necessarily
[0:24:06] make easier for you right so far we've hit problems in every node we've looked at and believe
[0:24:12] it or not we've only looked at the relatively easy to find capacity nodes these are all things you
[0:24:16] could just find like you just you know take a number multiply it by 10 and ask will that go
[0:24:20] good or bad there's a lot of other unexpected challenges so we're going to go through a really
[0:24:24] really quick list of some things I think you want to be worried about. So first, validation beyond
[0:24:30] just your compute. The validation strategy you use today is probably something like a lot of unit
[0:24:34] tests and maybe some integration tests. But with 10x more code and 10x more services, integration
[0:24:38] tests are going to become the most important part of your quality strategy. How many of you are
[0:24:42] happy with your integration testing setup today? I will note for the live stream, there is not a
[0:24:48] single hand up. Okay, good. That's what I thought. I am also not happy, right? Integration testing is
[0:24:54] have the tools to do it the way I would like to right now. Then you have this problem that I
[0:24:58] refer to as the conjunction of Booleans. In order to ship software today, you request that every
[0:25:02] test pass. All the Booleans turn green. Everything is good before you ship. That's a reasonable thing
[0:25:07] to do. What happens when you have a million tests and the actual reliability of the underlying test
[0:25:11] infrastructure to run a million tests is in question? It might not be possible to ship
[0:25:16] software where every Boolean has to be true. So now you're going to need a new strategy. It's
[0:25:20] probably something statistical to figure out what are the right tests to run because I can't run
[0:25:24] everything, okay? What about super extra large changes? It's really exciting that
[0:25:29] we can refactor and change languages and frameworks everywhere. Everyone can do it.
[0:25:32] Do you have the workflows or the social contracts to enable people to manage
[0:25:35] merge conflicts that are measured in the tens of thousands of lines, hundreds of
[0:25:38] thousands of lines, millions of lines? Probably not. So we're gonna need to
[0:25:43] figure out how do we build the workflows that support very large change sets
[0:25:47] moving past each other. If everyone at the company can do it, we're gonna need a
[0:25:51] a new strategy. And by the way, have you ever seen an agentic edit work? Where one edit, an agent
[0:25:56] makes a change, and then another agent comes in and says, no, I don't like that change. Let's do
[0:26:00] a different change. Now, it's funny to watch until you realize you're paying for the tokens on both
[0:26:03] sides of that, right? Let's move on to release. How many times do you release to your customers
[0:26:09] today? Daily? If you're doing daily, you're doing pretty good. If you're not, here's a problem for
[0:26:14] you. You're going to get 10x more software, and that software has to land somewhere. And if you're
[0:26:19] you're not releasing daily, my guess is that each change is now going to get a lot bigger.
[0:26:24] And if there's one thing my SRE friends will tell me, it is that very large changes are very scary.
[0:26:29] Let's not do that. But the code has to go somewhere. It needs to get deployed to be valuable.
[0:26:33] So one thing you're probably going to try to do is release more frequently. And that's good.
[0:26:37] Our friends at Dora would be proud. They would say, yes, please release more. But at some point,
[0:26:41] you're going to release diminishing returns. Releasing every second is probably not going
[0:26:45] to provide a lot of value to you. So somewhere between releasing every second and I'm not quite
[0:26:49] to a releasing a day is the right balance, but still the code will grow.
[0:26:52] And we're going to need to figure out where do we put that code so that we don't create
[0:26:56] more risk.
[0:26:59] How about your internal APIs?
[0:27:01] We've been talking about building software, but what about the internal developer environment
[0:27:05] with all the APIs and data?
[0:27:06] What I've been telling my friends that I work with is all of your APIs suddenly just became
[0:27:10] public.
[0:27:11] They need the same kind of hardening that you would put on anything that you're going
[0:27:15] to send out to the public internet.
[0:27:16] Why?
[0:27:16] Because agents aren't going to negotiate with you.
[0:27:18] They're going to find an API.
[0:27:19] They're going to start calling it.
[0:27:20] and if they can get access to your data, they're going to do it. I guarantee it. If an agent
[0:27:25] can access a data set, it's available to them. So if you haven't put the same thought into
[0:27:29] your internal data sets and your internal APIs, you're going to run into some very interesting
[0:27:32] challenges because agents are going to find things you probably didn't want them to. Well,
[0:27:36] how about Jevons paradox? This is a word we all learned in the last probably 12 months.
[0:27:40] No one knew what this was or even how to pronounce it. But now we all know about Jevons. Jevons
[0:27:43] says the cheaper and more efficient a resource gets, the more we use it. And boy, do you
[0:27:48] You see that with tokens.
[0:27:48] We are putting them everywhere.
[0:27:50] And it's changing how we work
[0:27:51] and how we think about how we work.
[0:27:53] We're now optimizing, or not optimizing,
[0:27:55] we are putting a cost on previously hidden productivity work
[0:27:59] that was invisible before.
[0:28:00] So what is that gonna do to the way we behave?
[0:28:02] I don't know yet, right?
[0:28:05] By the way, you need to be careful
[0:28:06] where you put those token engines.
[0:28:08] If you put load-bearing token engines in place,
[0:28:10] weird things can happen.
[0:28:12] Like for example, what if your rollback process
[0:28:13] depends on an agent to have enough capacity?
[0:28:15] If someone ran that agent out down the end of its token budget and now you can't roll back, that's probably a bad thing.
[0:28:21] And speaking of rollbacks, do you guys know why rollbacks work today, basically?
[0:28:26] It's because you release software slightly slower than it takes you to detect a problem in production.
[0:28:32] If you can release software really, really fast, faster than you can detect anything is wrong, what does that mean for your rollback posture?
[0:28:39] Every rollback will now have to contend with multiple conflicting changes landing on top of it.
[0:28:43] it. So it's not just enough to release faster. We have to consider the whole system, the rollback
[0:28:47] as well. That's a really important safety valve. How about the idea that everyone's a builder?
[0:28:51] This has been a big conference for celebrating the idea that everyone's a builder. And I think
[0:28:54] it's cool. Democratizing engineering is cool until you realize you have democratized engineering.
[0:29:00] You know that tool that you don't like, that you wish you could replace at your company? I don't
[0:29:05] care what it is, and I won't name names up here, but I'm sure there's a tool you just wish I could
[0:29:09] could Vibe code up a replacement for?
[0:29:10] Okay, multiply that by everyone at your company
[0:29:12] for every tool they use.
[0:29:13] What happens to the social fabric of your company
[0:29:15] when everyone is using completely different tools?
[0:29:18] Now, if you're lucky, you have a common data substrate,
[0:29:20] that's a good thing, right?
[0:29:21] Then all the data's going into the same place,
[0:29:23] but what if you don't, right?
[0:29:24] Everyone's a builder is cool until you have to maintain
[0:29:27] all the stuff that everyone built.
[0:29:29] And let's spare a thought
[0:29:30] for the technical leadership speed run
[0:29:31] we're gonna put all our junior developers through.
[0:29:34] The reason that it takes so long to become a lead
[0:29:36] is because you have to build intuition and judgment
[0:29:38] judgment and expertise to help you make calls because when you're leading a team, there's a
[0:29:43] blast radius that is much larger than when you're just doing it yourself. When a new grad steps into
[0:29:47] an environment where they have 50 agents at their disposal but none of the intuition and none of the
[0:29:51] judgment, what's going to go wrong? How do I teach 10 years of experience in six months? I don't know
[0:29:57] yet. And this last one you've heard a lot about, especially in the last talk if you were here.
[0:30:03] Human attention is the most precious resource we have and right now there's a lot of noise. There's
[0:30:07] there's so many agents, so many things demanding our attention.
[0:30:09] We're going to have to figure out how to manage
[0:30:11] this because we don't know how to do it really well right now.
[0:30:13] We've benefited from the fact that we couldn't make more trouble for
[0:30:15] ourselves than we could pay attention to,
[0:30:17] and now that is not the case.
[0:30:20] So that seems like a lot.
[0:30:21] That's because in the system,
[0:30:23] everything is connected.
[0:30:24] All of the challenges I just mentioned, by the way,
[0:30:26] you can't resolve any of these by just
[0:30:27] looking at a single node in the system.
[0:30:30] You have to look at the whole system.
[0:30:32] In order to adapt to agentic development,
[0:30:34] I think we're going to all have to start learning
[0:30:36] learning to think in systems all the time. So I'm not going to go through all of these. Take a
[0:30:41] screenshot of it if you want. But when you're thinking about systems, these are the things
[0:30:45] you should be worried about. Things getting bigger. The effects over time. Which direction
[0:30:49] does causality move? Which nodes are talking to all of their neighbors? What does emergence look
[0:30:54] like? What are the things that are coming out of nowhere? What about the incentives, both the social
[0:30:58] and the technical? And that's right. Technical systems can have incentives too. But be careful
[0:31:02] of the incentives in your ecosystem. Capacity. I've said it a couple times. I'll hear it at least
[0:31:05] at least one more time today, feedback loops and bottlenecks. These are the tools of systems
[0:31:10] analysis. Now, it may seem complicated, but you really only need two questions. Why and
[0:31:15] what if? Why do we have so few integration tests? What if we had more integration tests
[0:31:21] than unit tests? Why do we use these specific programming languages? What if AI writes all
[0:31:26] the code, right? Why is the drill that you are going to use to bore into the heart of
[0:31:30] of your system to figure out how it works.
[0:31:32] What if will challenge what you find
[0:31:34] and it will require you to flex your imagination
[0:31:37] a little bit.
[0:31:37] All of you are probably very good at asking why.
[0:31:40] I can see it in your faces.
[0:31:41] You guys know how to ask why.
[0:31:43] Why are we doing this?
[0:31:44] Why are we doing that?
[0:31:44] But what if, what if is more challenging?
[0:31:47] What if can be scary if we're asking you
[0:31:49] to abandon the practices you thought
[0:31:51] were really well designed for the problems that you had?
[0:31:54] What if can be scary?
[0:31:55] What if we didn't test this way?
[0:31:57] What if we didn't write tests at all?
[0:31:58] all, let's not get carried away, right? But if you allow it to be, what if can also be
[0:32:04] pretty exciting. Now, while you're thinking about where these opportunities are, I want
[0:32:08] to talk to you about a pattern that I've seen, right? It's this pattern that AI acts as an
[0:32:13] amplifier. As soon as I learned about this, I started seeing it everywhere. Now, I can't
[0:32:16] take credit for that idea. That actually comes from my friends at Dora and their report last
[0:32:19] year on AI development. They found this sort of relationship among teams that have really
[0:32:27] figured stuff out. They figured out how to make AI an amplifier. AI can do more. AI can
[0:32:33] get you more tests, more documentation, more code, but also more confusion. That's because
[0:32:37] amplification is a magnitude and not a direction. AI doesn't care where all of that stuff goes.
[0:32:42] It's just going to give you more of it. What Dora really found was that teams that had
[0:32:47] good fundamentals could apply that amplification in useful directions, which begs the question,
[0:32:52] how are you feeling about your fundamentals? How's the decision-making culture in your
[0:32:57] What could you do to improve it?
[0:32:57] What about your technical strategies?
[0:33:00] Is anyone looking at developer productivity?
[0:33:02] How well do people in your organization collaborate today?
[0:33:05] What's your security posture look like?
[0:33:07] How's your code health, your release hygiene,
[0:33:09] your reliability?
[0:33:10] AI doesn't solve any of these problems for you by default.
[0:33:13] It can amplify the practices you have if they're good,
[0:33:17] but if they're not good, it's gonna cause more trouble.
[0:33:19] But even with solid fundamentals, we're in for a real ride.
[0:33:22] My guess is, this is a guess,
[0:33:25] you can come check me on it later.
[0:33:26] In 2030, our developer ecosystems today are going to kind of feel like 2001 does to us now.
[0:33:32] And I should point out that in 2001, we were shipping software on CD-ROMs, right?
[0:33:37] That's how far away we might be in 2030.
[0:33:39] Now, as you continue to build your fundamentals, let me give you some other things you can think about along the way.
[0:33:43] First and most importantly, you need to know about infrastructure capacity.
[0:33:46] You can't deploy the AI and you can't deploy the compute if you don't know how much resource you have to spend.
[0:33:50] You need a good way to keep track of this.
[0:33:52] next you need validation because you can't or at least you shouldn't ship
[0:33:56] software that you haven't validated but like I've said before validation is
[0:33:59] going to change so you're gonna need a new validation strategy now it's the
[0:34:02] time to figure that out beyond that you need isolation because you're gonna get
[0:34:05] a lot of code for a lot of different purposes that previously we didn't use
[0:34:08] code for that's okay but you don't want that cool prototype code to actually
[0:34:12] find its way into production so you need to worry about isolation you need to
[0:34:15] make sure the fun stuff doesn't impact the money-making stuff and then finally
[0:34:19] Finally, you need to worry about abstraction. We build abstractions to keep developers from
[0:34:23] making bad choices. That's why we build libraries and frameworks and whatever. We wouldn't build
[0:34:27] a web server from scratch today, there's frameworks, because there's a lot of ways to get things
[0:34:30] wrong. Well, asking agents to make a lot of decisions leads to the same consequences.
[0:34:34] So we need good abstractions for the agents to hold on to. Don't give them bad choices.
[0:34:38] Now you're going to have to accept that engineering practices are not sacrosanct. Practices change,
[0:34:43] it's the principles that matter. It's easier said than done, I get that, especially when
[0:34:47] when some of our principles sort of feel like practices,
[0:34:49] they feel like they're all the same thing,
[0:34:50] like testing, right?
[0:34:52] If you've never really thought about
[0:34:53] why your team tests software the way it does
[0:34:55] or why your release process works the way that it does,
[0:34:57] you're not going to be able to evolve it.
[0:34:59] Understanding the principles is what's gonna give you
[0:35:01] the power and the confidence to change things
[0:35:03] as we move through this 10x moment.
[0:35:05] It is a fascinating time to be a software engineer.
[0:35:07] I'm not gonna lie.
[0:35:08] Every dimension of our work is being redefined.
[0:35:10] We need to flex our creativity more than ever, right?
[0:35:13] We need skills to tackle problems like context management,
[0:35:17] token economics, model drift.
[0:35:19] We need creativity, and we can't get so hung up
[0:35:22] on the temptation to optimize everything.
[0:35:24] We need to encourage exploration.
[0:35:27] There is a problem that's been keeping me up at night
[0:35:29] that I know can't be solved by just optimizing it,
[0:35:31] and that is how are we going to maintain intellectual control
[0:35:33] over our code bases as we grow?
[0:35:35] Intellectual control, by the way, is just a fancy way of saying
[0:35:37] can humans reason about this thing in front of them?
[0:35:39] We've been losing this war for at least the last 15 years.
[0:35:42] Our largest systems are way bigger than any of us can think about today. That's okay. I think AI
[0:35:48] offers us an opportunity, right? I think AI might give us the tools to actually begin to understand
[0:35:53] these very large systems as whole systems. And if, for example, you are not example,
[0:36:00] if by chance you don't believe me when I tell you that we've been losing this war, let me suggest
[0:36:04] an exercise to you. When you go back to your team, ask everyone to draw an architecture diagram for
[0:36:08] your system. See how many different pictures you get. We have been losing this war for
[0:36:13] a long time, so we're going to need help. The thing is, a lot of our software systems
[0:36:17] are really brittle. You can break a million line system with one bad line of code or one
[0:36:21] bad config flag, right? That's the kind of fragile that really makes you think twice
[0:36:25] before you go about making changes. One potential use of AI that I've been really excited about
[0:36:30] is this idea that I can get a continuously updated almost interactive architectural space
[0:36:34] that I can begin to ask questions of, like, what would happen if we took capacity from
[0:36:37] from here and moved it to the East Coast?
[0:36:40] Or what would happen if our user growth suddenly jumped 40%?
[0:36:43] Doing that for even a modestly sized system today
[0:36:45] is functionally impossible.
[0:36:46] There's just too many variables
[0:36:47] and too many things you need to know.
[0:36:48] But AI can make sense of very large sets of data,
[0:36:51] so I think there's something there.
[0:36:52] But the thing I like about this problem
[0:36:53] is that instead of focusing purely
[0:36:55] on making the code machine go,
[0:36:56] we're asking how can we deepen our understanding
[0:36:59] of the things that we have built?
[0:37:00] That's where I think some of the most exciting problems are.
[0:37:03] Now there's no denying that change is happening
[0:37:05] really fast in our industry.
[0:37:06] industry, and it's happening at a pace probably faster than most of you have ever experienced.
[0:37:10] One of the most important things all of you can do right now is offer to help someone
[0:37:15] who is struggling, right? Be a helping hand for someone who has not figured this out yet.
[0:37:20] We're all moving at different speeds. We're all dealing with this change in different
[0:37:24] ways. It is very easy to feel like you're falling behind. Senior engineers, be a mentor.
[0:37:30] Find the people who are stuck and help them. If you have figured out your AI developer
[0:37:33] developer workflow, go share it with people. It's not a precious secret. Help the other people
[0:37:37] around you. If you're a technical lead, you need to get involved. You need to help steer how software
[0:37:43] engineering is happening at your company. And critically, if you care about software quality
[0:37:49] or software design, you have to use your voice to advocate for it. You in this room are the people
[0:37:54] who are going to do that. Your bosses probably aren't, right? Now, at the risk of ending on a
[0:38:00] somewhat clumsy metaphor. If you imagine our developer ecosystems as living ecosystems,
[0:38:05] we have all grown accustomed to staring intently at each individual leaf on each individual
[0:38:11] branch, caring for each tree as though it were some sort of special life form. However,
[0:38:16] it will not be long before we are all not just managing a tree, but an entire forest.
[0:38:21] And you can't manage a forest by looking at individual trees. You have to manage a forest
[0:38:26] by seeing it as an ecosystem, right?
[0:38:29] Now, here's the trouble with systemic change.
[0:38:31] It has this quality of happening to everything, everywhere,
[0:38:33] all at once, of being too big for any of us to influence.
[0:38:38] It can feel right now impossible
[0:38:40] to grab anything to steady yourself
[0:38:42] with the waves of change washing up on us
[0:38:44] what seems like weekly.
[0:38:47] But as we've just discovered,
[0:38:49] in a system, everything is connected.
[0:38:51] Small actions can have big consequences.
[0:38:54] consequences. Despite how it might seem, AI transformation is not the sole domain of your
[0:38:59] company's leaders. They have a role to play, but so do you. As frontline software engineers,
[0:39:04] in this tipping point moment, you are at the heart of deciding what software engineering
[0:39:08] is going to be. From your tools to your workflows, from your engineering practices to your engineering
[0:39:13] culture, if you can see the systems at work, you can look for leverage. You have more agency
[0:39:19] than you think. You really do. Use that agency to create the future for your
[0:39:23] organization, for your team, and for you. Thank you.
