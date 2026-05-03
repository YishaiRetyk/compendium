---
title: "Is this the only skill left?"
author: "Hack (Agentive Stack)"
publication: "YouTube"
url: "https://www.youtube.com/watch?v=7zCsfe57tpU"
date: 2026-05-03
source_type: transcript
privacy: cloud_safe
---

# Is this the only skill left?

[0:00:00] It's a skill that all senior devs build by accident over years.
[0:00:05] And it looks like it's the whole job now.
[0:00:08] That skill is systems thinking.
[0:00:10] These days, in a world where AI generates code you didn't write,
[0:00:14] you kinda need it on day one.
[0:00:16] That's the actual shift.
[0:00:18] If you're new here, welcome.
[0:00:19] I'm Hack.
[0:00:20] I'm a product engineer turned founder.
[0:00:22] And I've been building software for over 20 years.
[0:00:25] Writing code the old way and now building with AI daily.
[0:00:28] I run Agentive Stack, a product studio where we build software that runs itself, and where
[0:00:34] we explore this new wave of agentic products and AI building.
[0:00:38] This channel is about that exploration, what actually works and what's breaking, quietly
[0:00:43] sometimes along the way.
[0:00:44] Now let's get into it.
[0:00:47] In 1985, a Danish computer scientist by the name of Peter Naur wrote a paper called Programming
[0:00:54] as Theory Building.
[0:00:55] League. That paper touched on a simple but very interesting argument, that the code isn't the
[0:01:02] program. The program is what lives inside the programmer's head, how the pieces connect, why
[0:01:07] they connect in the ways they connect, and what happens if you pull one out. That's the program.
[0:01:13] The code is just the shadow of it, as Peter Nauer puts it. Four years later, today, we have AI coding
[0:01:21] agents that generate that shadow on demand for us. But the program isn't gone. We just start
[0:01:28] building the theory of it because these new tools that we have at our disposal makes us confuse the
[0:01:34] two. Last week I put out a video on comprehension debt or cognitive debt as a lot of you pointed
[0:01:42] out in the comments. The tax we pay when we ship AI generated code we don't understand. Now the
[0:01:48] The video got a lot of traction, I have to say.
[0:01:51] Thousands of views and hundreds of comments.
[0:01:54] But one question kept surfacing,
[0:01:56] coming from some of the juniors and people early in their career,
[0:01:59] asking, if AI writes the code,
[0:02:02] how do we build the judgment we evaluate?
[0:02:05] Should I still learn code these days?
[0:02:08] That's a very fair question.
[0:02:09] And it's a question everyone building software with AI should be asking.
[0:02:13] I think we've been focused on the wrong skill.
[0:02:15] Because when the code got cheap to prove,
[0:02:18] No, cheap is not the right word here.
[0:02:22] Easy.
[0:02:23] When code got easy to produce, to generate,
[0:02:27] everyone doubled down on prompting.
[0:02:28] Better prompts, better models, better tools.
[0:02:32] The prompting is the easy layer now,
[0:02:34] and it's only getting easier
[0:02:35] because new models promise to understand user intent better
[0:02:40] without too much context,
[0:02:42] although the output is still disputable.
[0:02:45] But as we move forward with this new way of building software,
[0:02:48] there's one skill that still matters and it will continue to matter for a good while that skill
[0:02:55] is systems thinking or systems design and architectural thinking if we spread it wider
[0:03:02] it's a skill that all senior devs build by accident over years and it looks like it's the
[0:03:10] whole job now we're moving up a layer beyond mere code so let's do a quick definition because we can
[0:03:18] draw words around loosely. A system is not just a bunch of parts put together. A system is a pattern
[0:03:25] of how those parts affect each other over time. Change one and the others react. Miss a connection
[0:03:31] and the pattern breaks. These come from systems dynamics. Let's think of it like an orchestra.
[0:03:38] Code is the instruments. The system is the music. AI can play any instrument on the mat. Violin,
[0:03:46] drums brass often better than a human can now music people please don't backlash on this
[0:03:53] i'm using it as an analogy only ai cannot replace you but someone still has to conduct someone still
[0:04:00] has to know how the parts fit together when the strings should hold back when the brass should
[0:04:05] come in that's the conductor now that's you no matter if you're a senior junior or non-technical
[0:04:13] you need to know how to conduct the orchestra ai is the orchestra but it will never be the
[0:04:19] conductor and let's be honest about where we are right now because we're not going back that's for
[0:04:28] sure agentic engineering is here to stay the giants and the incumbents all push for it the
[0:04:35] always are pretty much gone spec driven workflows coding agents ai pair programmers agent harnesses
[0:04:43] that's the stack now but the accumulated experience still applies more than we like to
[0:04:50] admit we just need to adapt to this new way the job description of a developer has already changed
[0:04:56] it just hasn't updated in most people's head yet harvard researchers coined the term
[0:05:01] jacked frontier which describes the fact that the tech is sharp in some places
[0:05:06] and surprisingly dull in others sometimes in the same session knowing where those edges sit
[0:05:14] like what the model nails or what equally gets wrong that's now a core developer skill it's part
[0:05:21] of the new literacy so let's make this more concrete for builders systems thinking comes
[0:05:28] down to three questions you should be able to answer without running the code one where does
[0:05:35] meaning who owns the truth in the system if two pieces each think they own it you already have a
[0:05:42] bug you have an issue you just haven't triggered it yet two where does feedback live what tells
[0:05:48] you the system is working or not how do you know logs metrics errors all bubbling up somewhere
[0:05:56] if nothing tells you that the system isn't working probably is pretending to work three
[0:06:01] what breaks if I delete this can you trace the blast radius of any component
[0:06:08] or part of the system in your head before you touch it that's the theory
[0:06:13] know what was talking about now I've been auditing AI build apps over the
[0:06:19] past few months and the most recent one was a lovable base product built by a
[0:06:24] non-technical founder the product was already live for a few weeks with real
[0:06:29] You'll pay customers in quite a handful of third-party integrations,
[0:06:33] which was impressive, I have to say.
[0:06:36] That's what we want after all, as builders.
[0:06:39] We want people using our products.
[0:06:41] But the code base was a mess.
[0:06:43] There was this one file, which was 7,000 lines long,
[0:06:48] with several user flows and business logic,
[0:06:50] all tied up into one.
[0:06:52] Logs were empty.
[0:06:53] There was no rate limiting, no proper error handling.
[0:06:56] but the app was apparently working until it didn't every single failure mode in there
[0:07:03] was a systems thinking failure not a coding one where does state live well everywhere all at
[0:07:09] months where does feedback live nowhere we're blind what breaks if i delete this never asked
[0:07:16] never cared the system was incoherent my audit report had a lot of critical stuff that needed
[0:07:22] to be addressed ASAP before adding more customers or this thing will crumble as a house of cards.
[0:07:28] Now we haven't touched base ever since but it looks like they decided to rebuild it from scratch
[0:07:33] which was probably a good decision. So AI can write an individual piece and still have the
[0:07:40] whole thing be nonsense if not done correctly. Now I need to address something because in the
[0:07:46] the last video the main pushback in the comments was around how ai is just the next abstraction
[0:07:52] layer and just like we move from assembly to c to python ai is the next step yes i agree thank god
[0:08:02] we don't write assembly anymore and i get the argument but i also think it's wrong here's right
[0:08:09] when you write python code and the compiler produces machine code that translation is
[0:08:14] deterministic for your input you get the same output provably correct you don't
[0:08:21] need to understand what the compiler did behind the scenes because the compiler
[0:08:24] guarantees it did the right thing that's what makes it a trustworthy abstraction
[0:08:29] an LLM is not that it's just a probabilistic translator it's stochastic
[0:08:36] by nature for the same input you get different outputs almost each time no
[0:08:41] No guarantees.
[0:08:42] This compiler could introduce a security vulnerability, a race condition or a wrong business rule
[0:08:48] without your knowing.
[0:08:49] A compiler is a layer you can trust without understanding.
[0:08:52] An LLM is a collaborator you can only trust by understanding what it did.
[0:08:58] They're not the same kind of tool.
[0:09:00] The abstraction argument only works when the layer below you is verifiable.
[0:09:04] This one is not.
[0:09:06] Not in the traditional way.
[0:09:07] Now, systems thinking was always critical.
[0:09:10] it just used to be something engineers build up over years these days in a world where ai generates
[0:09:17] code you didn't write you kind of need it on day one that's the actual shift one more thing because
[0:09:25] this matters if you're a junior watching this i don't want you thinking you're the problem you're
[0:09:30] not the reason senior devs have this skill is that they suffered through it we had to every senior i
[0:09:39] I know, me included, built this systems thinking skill by failing publicly on systems we designed
[0:09:45] wrong in the first place. And yeah, we had users shouting, and stakeholders, PMs, product owners,
[0:09:52] breathing down our necks. Sadly, that part hasn't changed much. If anything, it's worse now from
[0:09:59] what I see around. The pressure only went up. Faster shipping, higher expectations, less patience.
[0:10:06] what changed is the escape hatch back then when you hit a wall the only way was through the wall
[0:10:13] you had to sit with the code until you actually understood what you ship
[0:10:18] ai didn't take the pressure away it took the wrestle away that suffering was the curriculum
[0:10:25] back in the day the harvest study by hosini and liftinger and i'm probably butchering the names
[0:10:30] teams had pulled resume data from 62 million workers across 285,000 U.S. firms.
[0:10:38] And they found that after first quarter of 2023, companies adopting generative AI cut
[0:10:44] junior hiring sharply while senior employment kept rising.
[0:10:48] And they named it seniority-biased technological change.
[0:10:53] The industry cut the path that used to turn juniors into seniors.
[0:10:57] but plot twist early 2026 the pendulum started swinging back software engineer postings on
[0:11:04] indeed are up 11 year over year now ibm just announced it's tripling its entry level hiring
[0:11:11] in the u.s into it is expanding junior recruitment salesforce whose ceos last year they'd stop hiring
[0:11:19] engineers is back to hiring the industry is figuring out quietly that ai is not the shortcut
[0:11:26] how they thought it was they still need people who can oversee these agents on the architecture
[0:11:32] and catch what their models quietly get wrong they broke the pipeline now they're realizing
[0:11:38] they can't live without it so they're back scrambling to rebuild what they just broke
[0:11:43] and next time a cto complains there are no good mid-level engineers remember the industry stopped
[0:11:50] letting anyone be a junior and now they need them back so if you're a junior you're not behind you
[0:11:56] You just got robbed of the forcing function, which means you have to build one on purpose.
[0:12:01] And that's the rest of this video.
[0:12:06] So here's how I think about it.
[0:12:09] AI coding is the fast food of our craft.
[0:12:12] It's cheap and fast.
[0:12:15] Again, we need a better term.
[0:12:16] Cheap is not the right term.
[0:12:18] But it's genuinely useful when you already know what a real meal tastes like.
[0:12:23] Senior devs had to cook every meal themselves for years before AI showed up.
[0:12:28] So they know what the real thing tastes like.
[0:12:31] They also know when the fast food is off.
[0:12:34] Juniors today don't have that baseline.
[0:12:37] Their first hundred meals might come out of a drive-thru.
[0:12:41] And that raises a real concern.
[0:12:43] If nobody cooks anymore, who becomes the chef?
[0:12:47] Will we end up with a generation that never learned the craft?
[0:12:50] honestly i've been sitting with this one and i think yes there will be fewer but the ones who
[0:12:59] will make it will be more valuable than any senior before them if they build the right discipline for
[0:13:05] it let's think about fitness for a second because it's very relatable a hundred years ago everyone
[0:13:11] was fit because manual labor forced it today the average person is less fit because the environment
[0:13:18] does less of the work but the elite athletes today are the fittest humans who have ever existed
[0:13:25] because deliberate training is a thing now in a way that it wasn't then coding is going down the
[0:13:31] same path the average junior in 2026 will probably be less systems fluent than the average junior in
[0:13:38] 2010 but the junior who deliberately trains who chooses to cook or to lift will be more
[0:13:47] differentiated than any junior i came up with so far the industry churns and the disciplined
[0:13:53] minority will compound you just need to pick which side of that you're on and one more real change
[0:14:02] worth naming quickly which is very relatable to me also ai is collapsing these traditional silos
[0:14:09] of back-end front-end ops database a dev who used to be pure backend can now ship full stack
[0:14:16] features without spending six months memorizing react conventions the tools handle pattern
[0:14:22] matching and the developer handles the judgment codes personally i love the craft i love building
[0:14:29] things from scratch software has been my way of expressing that for the past two decades
[0:14:34] i love sketching the idea i love putting pieces together thinking about visuals the user journeys
[0:14:40] how someone actually interacts with my product nitpicking on the details the micro interactions
[0:14:46] But I also love the plumbing behind it, the architecture, the networking, the services, how they all fit together.
[0:14:53] I could never stay in one lane, not front-end, not back-end, not DevOps or whatever roles there were back then.
[0:15:00] If I had to pick one, I'd probably pick front-end, but I knew that I would miss parts of the back-end and DevOps lanes that I love.
[0:15:08] And that shape used to be a problem for me, at least.
[0:15:11] I've worked with a lot of other engineers throughout the years who were a lot smarter
[0:15:16] than me and each one of them was specialized, deep in their own lane.
[0:15:20] Now that shape flipped.
[0:15:22] And AI handles the depth of any of those lanes.
[0:15:26] What it can't do yet, yet, is hold the entire thing in its head, see the big picture and
[0:15:33] decide what actually matters.
[0:15:35] That's the generalist's home base.
[0:15:37] That's their turf.
[0:15:38] that's systems thinking so this new way where generous can work cross-stack more
[0:15:45] easily it fits perfectly at least for me I can finally focus on what I love the
[0:15:51] most the craft but that only works if the judgment is there and that judgment
[0:15:56] is again systems thinking and one more thing I never said that before this
[0:16:05] skill is something we all need to build up and use every builder touching these
[0:16:10] tools not just the juniors or seniors it's the same skill but depending on
[0:16:15] where you're standing the move changes if you're a junior don't stop using AI
[0:16:21] embrace it you have access to tools I used to think as sci-fi when I was at
[0:16:26] your stage but use them as learning tools not like a shortcut AI can be a
[0:16:32] great learning partner if you use it correctly yes prompt generate but then
[0:16:37] Then study what comes back.
[0:16:39] Treat the AI like an infinitely patient senior dev
[0:16:42] and ask it why this approach?
[0:16:45] What breaks if we did it the other way?
[0:16:47] What are the alternatives?
[0:16:48] Then maybe rewrite something by hand every week from memory.
[0:16:53] This forces you to think slower while you write
[0:16:56] so you can build up those mental models.
[0:16:59] Lines of code is a vanity metric, especially these days.
[0:17:02] The next generation of seniors will be juniors
[0:17:05] who use AI to understand better and faster,
[0:17:08] not the ones who ship the most code.
[0:17:10] If you're a mid or senior,
[0:17:13] well, embrace these tools, my friends.
[0:17:15] They're not going anywhere.
[0:17:17] Don't be the person probably saying,
[0:17:18] I still write every line by hand.
[0:17:21] That ship has sailed.
[0:17:23] But you have more important skills than just typing.
[0:17:25] You always had.
[0:17:26] Your edge is the theory you already have.
[0:17:30] The scar tissue from systems you design wrong.
[0:17:32] Use AI to amplify that,
[0:17:34] not subsidy for it let the agents handle the boilerplate the groundwork and you
[0:17:40] stay on the architecture the big picture the push backs and on the tough calls
[0:17:46] only experience makes and if you're a non tech founder operator or PM shipping
[0:17:52] with these tools like lovable bolt or cursor know this what you're doing is
[0:17:58] real non tech builders are shipping in weeks now what used to take teams six
[0:18:03] six months. But remember the audits I mentioned earlier? Built by non-tech founders? Or they
[0:18:11] did nothing wrong, they just didn't know what to look for. Maybe you don't need to learn
[0:18:17] to code anymore, but you still need to learn the thinking systems. And maybe learn the
[0:18:22] languages softer here and there. Ask those three questions before you ship. And know
[0:18:28] Know when to bring someone who does speak code.
[0:18:31] Knowing when is also part of this new skill.
[0:18:34] Like I said, different moves, same skill.
[0:18:38] Quick note, if this is your world,
[0:18:40] we're putting together a community called Agentive Build,
[0:18:43] backed by our product studio,
[0:18:45] and it's for builders, experienced and new,
[0:18:48] technical and non-technical,
[0:18:49] that want to ship AI build products that actually last.
[0:18:53] Inside, we'll touch in more details on things like architecture,
[0:18:57] scaling cost patterns design systems and other parts that vibe coding skips link
[0:19:05] below if you want to get on the waitlist so how do you actually train systems
[0:19:11] thinking when nothing's forcing you how do you stay disciplined when AI is doing
[0:19:16] the typing well I have four unsexy moves for you that compound on each other
[0:19:23] design before you prompt take one page and just draw boxes for components in
[0:19:28] arrow for data flows mark where state lives mark where failures surface if you can't draw it you
[0:19:36] don't really understand it and the ai is going to build whatever you didn't draw which is usually
[0:19:41] the wrong thing 10 minutes can reshape the entire conversation with ai even with all these tools at
[0:19:47] my disposal these days i deliberately slow down and start with pen and paper to brain dump complex
[0:19:55] features before I get into building use specs as scaffolding write the what and
[0:20:02] the why before the AI writes the how even a short spec where you define a
[0:20:08] problem the constraints the success criteria failure modes it's the safest
[0:20:14] vehicle we have right now for working with these coding agents I'll do a full
[0:20:19] video on spec driven development where it thrives and where you can break from
[0:20:23] my experience but for now it's the best scaffold we have for thinking in systems with these ai
[0:20:29] agents run the deletion test pick one component any component that you shipped recently and ask
[0:20:36] if i delete this what breaks and how badly if the answer is i don't know that's your new homework
[0:20:44] that's your study list that's how you rebuild the theory study the generated code don't just accept
[0:20:51] accepted. In each meaningful PR, push back on your AI agent. Walk me through this. What
[0:20:56] alternatives did you consider? I said this before. Once a week, try to rewrite something
[0:21:01] AI generated by hand. That's how you keep those code-reading muscles alive.
[0:21:07] So here's where I land. The people who panic that AI is going to replace developers, they're
[0:21:15] looking at the wrong layer. AI is replacing typing. It's not replacing thinking in systems.
[0:21:20] Nothing replaces that. At least not in this generation of models. Probably not the next
[0:21:25] one either. There's also an uncomfortable part. AI amplifies you if you have this skill
[0:21:33] and exposes you if you don't have it. Juniors who lean on AI without building their theory
[0:21:38] underneath, they move fast right now, but in five years they'll be the people nobody wants
[0:21:44] them on the team non-dev people shipping with plovable and bolt will keep shipping houses of
[0:21:50] cards until one of them falls on paying customers which i've seen real cases the skill is learnable
[0:21:56] it's just not promptable draw the system build a theory
[0:22:00] That's the new curriculum now.
[0:22:02] Thanks for watching.
[0:22:03] I'm Hack, see you in the next one.
[0:22:06] Cheers.
