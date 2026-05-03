---
title: "Three artifacts that changed how I build with AI"
author: "Hack (Agentive Stack)"
publication: "YouTube"
url: "https://www.youtube.com/watch?v=ECLDuYkzB8A"
date: 2026-05-04
source_type: transcript
privacy: cloud_safe
---

# Three artifacts that changed how I build with AI

[0:00:00] this 20 year old software engineering book called domain driven design it's a methodology that helps
[0:00:05] bring clarity to business complexity when building software products the thesis behind it is pretty
[0:00:11] straightforward software must reflect a shared understanding of the domain it serves and i think
[0:00:17] this method matters now more than ever and this video explores that i've been rebuilding some
[0:00:26] important parts for the past few weeks in one of our main products inside a genitive stack
[0:00:31] that is clark our ai analytics and experimentation platform now this product went from a vibe coded
[0:00:38] poc to a six apps 30 plus packages and hundreds of files monster in a little over six months
[0:00:47] mostly written by ai and we knew the problems we want to solve what we wanted to build and how it
[0:00:54] was supposed to work we had the big picture but we've fallen into the speed track the ai animal
[0:01:01] phase of adding and adding and adding we had no map not a proper blueprint and as
[0:01:08] a technical co-founder on this project I was in the fog navigating the next 100
[0:01:12] meters while the forest was growing around me and when the AI honeymoon
[0:01:17] phase ended which is usually around the five six month mark I realized I
[0:01:23] couldn't put something like that out there so I started looking for methods
[0:01:28] to create better blueprints proper blueprints for building with AI and I
[0:01:34] found one that helps create these blueprints in an approach to software
[0:01:39] engineering that's 20 years old and it could be more relevant now than ever
[0:01:43] when building with AI in this video I talked about one skill more important
[0:01:52] than prompting and typing code these days I was talking about systems
[0:01:55] systems thinking about how important it is to hold the big picture when AI builds your stuff,
[0:02:01] how you need to become the conductor of your own orchestra. Now lots of you came through with lots
[0:02:06] of comments and many of you asked about the how, how to put this into practice. If comprehension
[0:02:13] debt or cognitive debt is the problem and system thinking is the skill, we still need a method,
[0:02:21] a way to actually practice it day to day session to session like i said i found mine in a place i
[0:02:28] did not expect this 20 year old software engineering book called domain driven design
[0:02:33] written by this guy eric evans back in 2003 if you don't know it it's a methodology that helps
[0:02:39] bring clarity to business complexity when building software products the thesis behind it is pretty
[0:02:45] straightforward. Software must reflect a shared understanding of the domain it serves. And I think
[0:02:51] this method matters now more than ever. So I've been building with AI exclusively for over a year
[0:02:59] now. We have a few products in the pipeline, but Clark is the big project. And yes, using AI helped
[0:03:05] us build things that would have otherwise taken a bigger team and way more time. But while I see its
[0:03:11] powers, I also see its trade-offs. I talked about them in the previous videos and will touch on them
[0:03:16] more in other upcoming videos. The problem I usually encountered wasn't necessarily code
[0:03:22] quality. That's a topic for another video. No, the problem almost all the time was that there
[0:03:27] was no shared vocabulary between me and the AI coding agents inside the system. And this is
[0:03:33] something that happened in every product I started, not just Clark. For example, when I say
[0:03:38] change, do I mean a code commit or a set of DOM mutations applied to a customer website?
[0:03:43] or maybe a feature request from user well in Clark it's the second one
[0:03:48] change means a dot mutation applied to a customer's website a very specific thing
[0:03:53] with a very specific lifecycle but my coding agents don't know that unless I
[0:03:58] tell them every single session if I say user do I mean the person browsing a
[0:04:04] website that's being tracked or the developer installing our SDKs or maybe
[0:04:09] the admin in the dashboard that is one word with three completely different
[0:04:13] concepts now the AI guesses and sometimes it can guess right but
[0:04:17] sometimes does it wrong and when it's wrong it can build you the wrong thing
[0:04:22] with the right name and you don't catch it until a week later because it can
[0:04:26] look correct and yes it can even slip through your reviews it happens and
[0:04:31] there's this trap I see a lot of builders fall into which also happened
[0:04:35] to me AI feels most impressive in the areas where you know the least when
[0:04:40] When you're in your own domain, you can see the gaps.
[0:04:42] And the gaps in your knowledge become its free space to drift.
[0:04:46] And by the time you find the bug, the AI doesn't remember what it did.
[0:04:49] It's a different session with different context.
[0:04:51] Sometimes a different agent altogether.
[0:04:54] And you find yourself just putting through tokens and context.
[0:04:57] You're holding a bug.
[0:04:58] Nobody on your team remembers writing.
[0:05:01] And this is not a new problem.
[0:05:03] This is something we had even before AI coding was a thing.
[0:05:07] i went through it and i'm pretty sure most engineers went through it at some point
[0:05:11] five years ago i worked for a startup as a contractor on a team of 10 engineers building
[0:05:17] this healthcare digital platform 10 different people with 10 different backgrounds and different
[0:05:22] assumptions very common in engineering teams right the most expensive bugs we had never came from bad
[0:05:28] code they always came from misunderstanding from a lack of proper communication and misalignment
[0:05:34] which is in fact a problem in many other areas not just engineering so the lead architect back
[0:05:40] then introduced us to domain driven design now a quick sidebar because i want to head up a pushback
[0:05:47] when i first encountered ddd on that team i thought it was overkill and honestly the way
[0:05:54] we did it back then on that project i still think it was we had 44 bounded contexts with
[0:06:01] With separate modules even for things like invoice and invoices.
[0:06:05] And three layers of nesting inside each.
[0:06:08] That lead architect was a brilliant guy.
[0:06:10] Very, very technical.
[0:06:12] But he built this beautiful architecture that most of us could not navigate.
[0:06:18] Which kind of misses the point of DDD.
[0:06:21] So we've built a structure of DDD without the substance.
[0:06:24] And that whole experience put this approach off for me for a few years.
[0:06:28] But then I came back to it for AI coding and working solo mostly with these coding agents
[0:06:34] because the principles still hold, I think more than ever.
[0:06:39] So today, if we put it simply and strip it down to what actually matters when building
[0:06:45] with AI, DDD is three things.
[0:06:48] One, a shared language, a glossary, every important term in your system defined clearly
[0:06:54] in one sentence, what it is and what it does.
[0:06:57] For example, in Clark, we have over 50 terms written down, organized by area.
[0:07:03] A visitor is a unique user identified by device ID.
[0:07:07] A session is a sequence of events bounded by 30 minutes of inactivity.
[0:07:11] A change is a persistent set of DOM mutations applied to a customer's website.
[0:07:16] These are all written down, one sentence each with no ambiguity.
[0:07:20] Without something like this, every other AI coding session would build the wrong thing
[0:07:24] on the wrong assumption of meaning.
[0:07:25] meaning. This is what DDD calls a ubiquitous language. That shared language which is a
[0:07:30] contract between you and your AI, and your teammates, after all, too.
[0:07:34] Clear boundaries. Your system isn't one monolithic thing, even if it seems that way. It has several
[0:07:41] distinct areas, even a small project. Each area has its own rules and its own data. Each
[0:07:47] one has its own reason for existing. For example, I've mapped Clark into 6 areas so far. We
[0:07:52] We have analytics, experimentation, goals, SDKs, billing, and organizations.
[0:07:58] Each one owns specific concepts.
[0:08:01] When I tell the AI we're working in experimentation today,
[0:08:05] it knows that we'll only touch A-B tests, variants, and statistical analysis.
[0:08:10] We'll not touch billing, auth, or event ingestion.
[0:08:13] In DDD, these are called bounded contexts.
[0:08:17] Think of them as rooms in a building.
[0:08:19] The kitchen has different rules than the bathroom.
[0:08:21] room. You don't need to understand the plumbing of every room to cook your dinner. You just need
[0:08:26] to know which room you're in. The power here is the scope. The AI doesn't need to understand your
[0:08:31] entire system each time if you have the right map in place. Just the slice of that map you're
[0:08:37] working on. And you don't need to hold everything in your head all at once. Just the boundaries.
[0:08:42] 3. Documented contracts. This refers to where the boundaries touch. That handshake written down.
[0:08:49] Our analytics system writes events to a database.
[0:08:52] The experimentation system reads those events to figure out
[0:08:55] which A-B test variant is winning and suggest new ones.
[0:08:58] That's a contract.
[0:09:00] If I change how events are structured, the experimentation system breaks.
[0:09:04] That dependency is now documented.
[0:09:06] This is what breaks if I delete this test I mentioned in the systems thinking video.
[0:09:12] Except now it's written down, available both to me and to the AI agent.
[0:09:16] Now this is the starting ground.
[0:09:17] of course there are many more things to dive into when it comes to ddd and we'll probably address
[0:09:23] more in future videos you can find many free resources around it and eric evans original book
[0:09:29] is probably a solid starting point so these three artifacts are not some kind of magic bullet it's
[0:09:37] just that each ai conversation now starts from a shared understanding instead of a blank slate
[0:09:41] none of this is revolutionary it's just context and documentation we all know we should be doing
[0:09:47] it more the thing is we're not not really and i know it's so easy to fall into one shot prompting
[0:09:53] and ship the next thing fast i've done it a lot in the past and i still find myself reaching for
[0:09:58] it on the small stuff but for the parts that matter like architecture contracts data anything
[0:10:04] that future me or future ai or future teammates will need to read i slow down i open the glossary
[0:10:12] i check the boundary i update the dock when something changes and again it comes down to
[0:10:17] discipline i mentioned in previous videos just because we can ship something 10 times faster now
[0:10:22] doesn't mean we should at the end of the day we are responsible for what we put in our products
[0:10:28] not the ai so three artifacts one discipline that's the shift now like i said these are not
[0:10:36] new ideas in fact they're cousins of practices most engineers have known for decades things like
[0:10:42] Like a PRD, Product Requirements Document, which specs the what and the why before anyone
[0:10:48] writes a line of code.
[0:10:50] Or ADR, an architecture decision record that captures why a technical decision was made
[0:10:56] so future you or future AI, future teammate, can understand the trade-off.
[0:11:02] And the classical TDD, Test Driven Development, which forces you to define behavior before
[0:11:08] you code or your AI codes.
[0:11:09] all of this used to feel like overhead most of the time because senior devs carry the context
[0:11:15] in their heads but ai doesn't carry anything between sessions so that overhead is now the
[0:11:21] cheapest insurance you can buy these are decades old practices but with new urgency and each one
[0:11:27] probably deserves its own video and we'll probably get there but across the ai coding space engineers
[0:11:33] are arriving at this conclusion independently that when ai generates your code the most important
[0:11:39] thing you can produce is not more code. It's that shared understanding of the system. DDD was
[0:11:45] designed for a problem more relevant now than ever. How to maintain a coherent mental model
[0:11:50] of a complex system when the people working on it keep changing. Back then, the people changing
[0:11:56] were new hires joining the team. Today, it's a new AI session every time. I've put this into a set
[0:12:03] of skills that i now use cross projects which helps me to automate parts like specking features
[0:12:10] slicing work and testing new plans against the domain model and the whole project they're open
[0:12:16] source and free to use link below i've been doing this for the past few weeks and using these skills
[0:12:22] and this approach and i have to say it's working better than every other workflow i've tried so
[0:12:28] so far. But I'd be lying if I told you it's the definitive answer. Honestly, I think we're all
[0:12:34] still figuring this out as we craft. We're taking methodologies and approaches that are 20-30 years
[0:12:40] old and applying them to tools that are 2 or 3 years old that keep changing at an incredible
[0:12:46] speed. That fit isn't always clean. And something else that the AI hype cycle won't tell you,
[0:12:52] almost no one
[0:12:54] shipping serious software
[0:12:55] is letting agents write 100% of the code
[0:12:58] at least not the founders I talk to
[0:13:00] not the engineering teams I follow
[0:13:02] every builder I respect is still steering
[0:13:05] still reading and still pushing back
[0:13:07] maybe they're not coding
[0:13:09] like they used to
[0:13:10] but the pushback is still there
[0:13:12] and I think that's our new responsibility
[0:13:14] as builders and engineers
[0:13:16] the agents do accelerate the work
[0:13:18] but they don't replace the judgment
[0:13:20] our problems are still hard the scaffolding the refactors the smaller fixes that's where ai shines
[0:13:27] today but the trade-offs the architecture calls the should this even exist question which i think
[0:13:34] is very underrated these days these are still on us the humans so no we don't throw out the old
[0:13:39] playbook quite the opposite actually a lot of what worked before still works we just need to
[0:13:45] translate it into this new way of building and engineers aren't going anywhere they just have
[0:13:51] new responsibilities the job is shifting but the thinking matters more than ever now and another
[0:13:57] quick note if this is your world we're putting together a community called agentive build
[0:14:02] it's for builders experiencing new technical and non-technical who want to ship ai build products
[0:14:08] responsibly and learn these new ways of doing things inside we will go deeper on this stuff
[0:14:13] the artifacts I just walked you through and many many more link below if you
[0:14:18] want to get on the waste list so to recap comprehension that or
[0:14:24] cognitive that told you the cost of not understanding your code in your system
[0:14:28] systems thinking told you the skill you need now TDD or not you need these three
[0:14:35] artifacts when building with AI you need the shell language clear boundaries and
[0:14:40] documented contracts i'm not saying domain driven design is the solution but it's one solution it's
[0:14:47] not a magic shortcut it's just the craft slightly translated because in a world where everyone can
[0:14:52] shoot fast now i think quality becomes the differentiator craft is what separates you
[0:14:57] from the vibe coded slop and i guess in this new agentic coding landscape engineers are pushed to
[0:15:03] do something most of them used to hate documentation thanks for watching i'm hack see in the next one
[0:15:10] cheers
