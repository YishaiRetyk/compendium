---
title: "Agentic Search for Context Engineering — Leonie Monigatti, Elastic"
author: "Leonie Monigatti"
channel: "AI Engineer"
publication: "YouTube"
url: "https://www.youtube.com/watch?v=ynJyIKwjonM"
date: 2026-05-08
source_type: transcript
privacy: cloud_safe
---

# Agentic Search for Context Engineering — Leonie Monigatti, Elastic

> Machine-transcribed from the video's audio with the `stt` CLI (faster-whisper large-v3,
> English, auto-detected at 99% confidence). Automatic speaker diarization did NOT run — the
> pipeline's diarizer dependency (TorchCodec) was unavailable — so the committed transcript
> carries no `SPEAKER:` labels. The session is a single-speaker presentation by Leonie
> Monigatti through 0:49:16; the closing Q&A (from 0:49:16) interleaves audience questioners,
> Monigatti, and her Elastic colleague Joe, and is attributable from content where needed.
> The `[H:MM:SS]` timestamps are the STT segment starts.

## Description

Official video description (AI Engineer channel):

> Getting context into an LLM is not just a retrieval problem. It is a search problem. This
> workshop digs into the part of context engineering that usually gets waved away: how agents
> actually decide what to pull from files, databases, memory, and the web, and why that choice
> often matters more than the model itself.
>
> Across semantic search, general-purpose database tools, shell-based retrieval, and agent
> skills, Leonie Monigatti shows where each search interface works, where it breaks, and how to
> combine them into a more effective retrieval stack. If you're building agents and trying to
> make retrieval less brittle, this is a practical guide to the real mechanics behind agentic
> search.

- **Workshop repo:** https://github.com/iamleonie/workshop-agentic-search
- **Speaker:** https://x.com/helloiamleonie · https://www.linkedin.com/in/804250ab/

Chapters (from the video description):

- 0:00:00 — Introduction and Welcome
- 0:00:51 — Defining Context Engineering and the role of Search
- 0:02:21 — Historical context: From RAG to Agentic RAG
- 0:04:30 — Context sources (local files, memory, databases, web)
- 0:06:30 — Introduction to the Shell tool and its versatility
- 0:08:50 — Failure modes in agentic search
- 0:10:41 — The importance of tool descriptions and parameter design
- 0:13:53 — Code Demo: Simple semantic search and its limitations
- 0:23:26 — Code Demo: General purpose database query (ESQL)
- 0:28:36 — Code Demo: Adding Agent Skills for better interaction
- 0:34:42 — Code Demo: Using the Shell tool for file system retrieval
- 0:41:26 — Code Demo: Integrating custom CLIs (Jina grep — rendered "Gina Grap" in the chapters)
- 0:44:42 — Practical recommendations for building a search tool stack
- 0:49:16 — Q&A Session begins

## Transcript

[0:00:17] Welcome to AI engineer. Thanks for joining my session. We are going to be talking about
[0:00:24] agentic search for context engineering today. My name is Leonie. I work at Elastic, the
[0:00:31] company behind Elastic Search. And usually I like to talk about retrieval on Twitter.
[0:00:38] today I'm super excited to be doing this in person a little bit of housekeeping
[0:00:43] if you want to access the slides and the code we will be looking at you can scan
[0:00:48] the QR code so let's start with why I'm excited about search and retrieval and
[0:00:56] hopefully why you are excited about it by the end of this workshop as well who
[0:01:02] Who here has built an agent or some form of it before?
[0:01:07] Awesome.
[0:01:08] Then you've probably,
[0:01:10] then you're probably not intimidated by this image.
[0:01:13] You've probably seen some alternative to this one before.
[0:01:17] This is essentially what context engineering looks like.
[0:01:20] So context engineering, when you talk about it,
[0:01:23] is the art or engineering techniques about
[0:01:27] how from all of the possible context sources we have,
[0:01:30] have, how do we actually decide what goes into the context window so our LLMs can generate
[0:01:37] the best responses?
[0:01:39] Often when we talk about this, we talk about context curation and we mean this little arrow
[0:01:46] from context sources to context window, but we're not giving this little arrow right there
[0:01:52] enough credit in my opinion because what's powering this is the search tool
[0:01:59] or search tools that actually decide what goes from context sources to the
[0:02:05] context window and today we're going to be looking at the different search tools
[0:02:09] we have so this is my personal hot take I'd like to say that context engineering
[0:02:15] is about 80% agentic search because it's this little box right here all
[0:02:21] All right, let's start with a little bit of history.
[0:02:24] And when I say history, I mean the last three years.
[0:02:29] RAG, when we started with RAG,
[0:02:32] the original idea was that we had
[0:02:34] a fixed retrieval pipeline.
[0:02:36] So the user message would usually,
[0:02:40] more or less verbatim, be used as a search query,
[0:02:45] to be used usually as a vector search query
[0:02:48] to pull some data or chunks from a database.
[0:02:53] And together with a retrieved context,
[0:02:55] the user message would go into the context window
[0:02:58] and then it would be fed to the LLM.
[0:03:01] Nice.
[0:03:03] This has clearly many limitations.
[0:03:06] So since this is a fixed pipeline,
[0:03:09] whether or not you actually need any context,
[0:03:11] you're still retrieving additional information.
[0:03:15] And in the worst case,
[0:03:15] case that can actually confuse your LLM, right?
[0:03:19] On the other hand, if you're only retrieving once, let's say you need some multi-hop retrieval,
[0:03:26] you're asking your LLM something more complex, then if you're only retrieving once, maybe
[0:03:32] the retrieved chunks reveal some information about another search query you need, then
[0:03:37] you would actually might want to have a second round of search, right?
[0:03:42] so that's why we then moved on to agentic rag so we replace the fixed
[0:03:49] pipeline with now a search tool so now the agent can decide by himself by
[0:03:57] itself whether or not to call the search tool and retrieve some information so we
[0:04:03] don't have the problem anymore of do I actually need any information and when I
[0:04:08] actually retrieve information? Is this even relevant? Do I need to retrieve more?
[0:04:15] Do I actually have to retrieve something, rewrite the search query? Yeah. So we
[0:04:25] still only have one context source in this case, one database. Now when we look
[0:04:31] at context engineering, the context lies in many different places, right? So we
[0:04:37] we have context sources in local files.
[0:04:40] So when you think about your coding agent,
[0:04:43] you probably have your coding project in,
[0:04:46] or code files laying around in your local file system.
[0:04:50] Maybe you're using some kind of working memory,
[0:04:54] like a scratch pad, so you're planning with your agent
[0:04:58] what you want to do, then you probably have something
[0:05:00] like a plan.md file.
[0:05:03] When you have agent skills, you also have them
[0:05:06] them usually in a local folder somewhere.
[0:05:09] We still have databases because many enterprises
[0:05:12] have their data stored in databases.
[0:05:16] We have the web as another context source
[0:05:20] and I know this is a super controversial image here
[0:05:23] because I did not commit to having the long-term memory
[0:05:26] in the local file system or the databases.
[0:05:29] I think they're currently a very big discussion.
[0:05:32] We can get into this in the Q&A if you like.
[0:05:34] like, but we also have longterm memory as another context source,
[0:05:39] right? So how do we actually retrieve context from
[0:05:44] these? Usually we have a set of, um,
[0:05:48] let's say context source in native search tools. So for the local files,
[0:05:53] you usually have something like, um, a search files, um,
[0:05:57] tool for skills. You usually have a skill loading tool.
[0:06:01] tool. When you think about databases, we have a little bit more custom tools. So something
[0:06:10] like a semantic search tool. Maybe you also have something more general purpose like a
[0:06:16] tool that lets you execute entire search queries against the database like SQL, for example.
[0:06:22] For web, you have web search tools. And for memory, you have something like a dedicated
[0:06:27] memory tool. If that's not overwhelming enough, we now also have something called
[0:06:33] a shell tool. Langchain calls it shell tool, Anthropic calls it the bash tool. If
[0:06:42] you've experienced, if you've played around with OpenClaw, it's called the exec
[0:06:45] tool, but what all of these tools do is they let your agent run commands in the
[0:06:51] the terminal and that actually makes them super versatile because now you can let your
[0:06:58] agent use CLIs to navigate and explore your local files so you can just run LS and grep
[0:07:06] to find data in your local file system.
[0:07:11] If your database has a custom CLI you can actually let the agent also use the shell
[0:07:18] shell tool and interact with the database.
[0:07:22] You could also let your agent write an entire script
[0:07:27] from scratch, like connect to your database,
[0:07:29] run a search query.
[0:07:32] If your database is exposed via HTTPS,
[0:07:35] you can just run a curl command,
[0:07:37] interact with the database through the shell tool.
[0:07:41] Speaking of curl commands, you can also
[0:07:43] do web searches if you like.
[0:07:45] like. So this shell tool is super versatile, right?
[0:07:50] So the question and the topic of today is what search tool do we actually need?
[0:07:57] Do we only need a shell tool? Do I need all of these?
[0:08:04] And if you take home only one thing from today is that doing good search is
[0:08:09] incredibly difficult and that's why we have many different techniques to do
[0:08:15] search right we have vector search we have keyword search even in a vector
[0:08:19] search we have dense embedding sparse embeddings multi vector embeddings then
[0:08:25] we have many different indexing techniques so depending on what kind of
[0:08:30] search requirements and latency requirements you have you will need to
[0:08:36] curate your own stack of search tools right so today we're going to be looking
[0:08:43] at a few of these. Unfortunately we only have one hour so I cannot show you all of them.
[0:08:50] Before we get into some code I want to give you a few fundamentals of building good search tools
[0:09:01] because agentic search at the surface level seems very straightforward. The user makes a request,
[0:09:08] request. The agent calls the right tool with the right parameters. I see someone laughing.
[0:09:16] The retrieval tool gives you the tool response and then your agent responds to you with the
[0:09:22] correct answer. At Elastic, we help a lot of internal and external teams build agents
[0:09:29] based to interact with Elasticsearch data and the reality is that this can break in
[0:09:36] in many different ways.
[0:09:38] I'm just going to show you three today.
[0:09:41] So the first is the agent doesn't call any tool.
[0:09:45] So this means the agent decides,
[0:09:48] I actually can answer this question
[0:09:49] based on my parametric knowledge.
[0:09:51] I don't need to use any context retrieval tool.
[0:09:56] And the other problem is that the agent
[0:09:58] calls the wrong tool.
[0:10:00] I was recently talking to a colleague of mine,
[0:10:02] was asking him what was your the most challenging aspect of your project and
[0:10:08] he was like you won't believe it but it was really difficult to get the agent to
[0:10:12] actually not call the web search tool but call the database search tool right
[0:10:19] and then depending on how complex your parameters are for your search tools it
[0:10:25] can also be quite challenging to get your agent to generate the right search
[0:10:31] search parameters, right?
[0:10:34] There's many more failure cases,
[0:10:35] but we're gonna limit this to these three today.
[0:10:40] So, I personally hate this slide
[0:10:42] because I feel like everyone in this room probably knows
[0:10:46] that the tool description is the most important aspect.
[0:10:49] But anytime I see a tool description,
[0:10:52] it's like the least effort, one sentence,
[0:10:55] and then you're wondering why your agent
[0:10:57] isn't calling the right tool.
[0:10:59] So arguably, this is a very long tool description. I'm not saying you have to write it like this. I'm
[0:11:06] just saying if you just start with a core purpose, if it works fine, great. But if you add more
[0:11:14] parameters or more tools and your agent is starting to struggle with calling the right
[0:11:21] tool, then maybe add some trigger condition. When should this tool be used? When should this tool
[0:11:28] will not be used, especially if you have multiple tools.
[0:11:33] Adding something like relationships is super important,
[0:11:36] like first call this agent skill
[0:11:38] before you actually call this tool
[0:11:40] or get some confirmation before you call this tool.
[0:11:46] If you have the perfect tool description
[0:11:47] and your agent still doesn't call the right tool,
[0:11:50] then reinforce it in the agent system prompt
[0:11:53] that should actually help out in most cases.
[0:11:57] then I want to quickly touch on some on the parameter complexity if you have a
[0:12:06] search tool that's just very simple and in the sense that something like get
[0:12:10] customer by ID it should be fairly straightforward for the agent to
[0:12:15] generate an ID parameter given that it's a valid ID same for if you're doing a
[0:12:22] semantic search right generating some valid string should be shouldn't cause
[0:12:28] any any issues but let's say if you want to have a semantic search tool and
[0:12:34] instead of just giving a topic you now also want to give it some filter
[0:12:40] conditions maybe you want to define the top K then you start to have more
[0:12:44] parameters right this isn't very complex here but the longer the list of
[0:12:50] of parameters you have, the more difficult it's going to get
[0:12:53] for the agent to generate the right ones.
[0:12:57] And I think a very complex one for an agent is to,
[0:13:00] when you have something that's more general purpose,
[0:13:03] like letting the agent execute entire search queries
[0:13:09] against the database.
[0:13:10] So here I have ESQL,
[0:13:12] which is the Elastic Search Query Language,
[0:13:14] could be SQL as well.
[0:13:16] So, letting the agent write an entire SQL query from scratch can be quite challenging.
[0:13:21] Most are pretty good, but some aren't.
[0:13:25] So, just keep in mind, let's say the complexity of the parameter also is kind of a failure
[0:13:34] mode and you might need to help the agent out with a few of these if they are more complex.
[0:13:43] Good.
[0:13:45] Let's look at some code.
[0:13:53] Okay, so quick show of hands, who here has built some sort of agentic rag, agentic search before?
[0:14:09] Okay, about half, that's good. So we're going to be looking at three things. I'm going to give you
[0:14:17] a quick recap or intro to the very vanilla agentic search demo and then I'm going to show you how
[0:14:24] how easy it is to break this usual demo.
[0:14:28] And then we're replacing the semantic search tool
[0:14:31] with something more general purpose.
[0:14:34] So we're letting the agent write
[0:14:36] an entire search query from scratch.
[0:14:39] And for these two examples,
[0:14:42] we will be using a local elastic search cluster
[0:14:45] as a context source.
[0:14:47] And then for the third part, I'm switching gears
[0:14:50] and I'm going to be showing you
[0:14:51] how search over local file system works with the bash tool and then I'm also
[0:14:58] going to show the shell tool and then I'm also going to show you some
[0:15:03] limitations of the shell tool and how you can expand it with custom CLIs.
[0:15:07] Alright the example that we'll be doing today is I have the conference session
[0:15:17] session data of this conference here and let me show you this one. So just a quick recap.
[0:15:26] We have elastic search database and we're going to be writing a semantic search tool.
[0:15:36] And for in the database I have the conference session already chunked. You probably already
[0:15:45] know how to chunk and store data in a database so we're skipping this part
[0:15:50] this is not the important aspect so what do we need for an agent and LLM oh sorry
[0:16:01] we're going to be using langchain for this session just because it wraps a lot
[0:16:07] of the complexity and I don't like it lets us concentrate on the high level
[0:16:14] of a concepts also has some nice built-in features like the shell tool is
[0:16:19] built in and it has some code samples for skill loading tools which we will be
[0:16:24] looking at later okay switching back I'm using GPT 5.4 nano for this demo then
[0:16:34] we're defining a very simple system prompt so the usual you are a search
[0:16:39] agent task with answering questions you have access to different context
[0:16:46] retrieval tools and before answering a question let's decide whether or not you
[0:16:51] need to retrieve additional context to help the agent a little bit I have some
[0:16:56] information about how the data is structured in Elasticsearch so here we
[0:17:02] have a text field it's comprised of the title of each session and the
[0:17:07] the description of each session,
[0:17:09] and the text field is what actually gets embedded
[0:17:12] as the vector embeddings for semantic search.
[0:17:16] And then I also have some metadata fields,
[0:17:19] so for example, the day, the time, the room,
[0:17:22] the speaker's name.
[0:17:24] So since the metadata is not embedded,
[0:17:27] I can only run filters over them,
[0:17:30] but not any semantic search, just for your information.
[0:17:35] Okay.
[0:17:37] Now the interesting part. Let's build a semantic search tool. So how that works in
[0:17:43] Langchain is I have to first define an embedding model. In this case I'm using
[0:17:48] the new Gina embeddings v5 model. This is used to embed the search queries at query time
[0:17:59] and the embedding model I'm putting in with putting it into my elastic search store
[0:18:06] together with elastic data to create a vector store and then I can create a
[0:18:16] search tool so in this case I have all I have to do is I call the similarity
[0:18:24] search method it takes in a search query and in this case I'm setting the limits
[0:18:30] or the top K to 3 this is a little bit of foreshadowing because I'm limiting
[0:18:35] the capabilities of this tool
[0:18:38] to just returning three search results, right?
[0:18:43] What's nice in Langchain as well
[0:18:45] is that when you use the tool decorator up here,
[0:18:48] it lets you convert any Python function
[0:18:51] into a search tool, sorry, into an agent tool.
[0:18:55] So by default, it takes the functions,
[0:19:00] Python functions name as the tool name
[0:19:04] and the doc string down here is going to convert going to get converted into the
[0:19:10] tool description you can see I'm breaking my own rule by having a very
[0:19:15] short tool description here why this works is because I only have one search
[0:19:22] tool here right so you will see I'm adding a few things later on but it's
[0:19:28] not going to get very descriptive in this demo here. So now we can run a test and test it for
[0:19:36] a search query of regulatory constraints and you can see it finds a talk by my friend Birgit
[0:19:43] on engineering AI systems under sovereignty constraints and it also finds some more talks,
[0:19:50] one by Tejas and one by Pedro. All right let's plug it in. So we're plugging in
[0:20:00] the alarm, the system prompt and the search tool. I'm leaving out memory
[0:20:04] obviously this would be another core component of an agent. In this case I'm
[0:20:08] leaving it out to keep it kind of concise. Now I can run a simple question
[0:20:19] like which sessions discuss regulatory constraints
[0:20:22] in AI systems.
[0:20:24] And you can see the agent first
[0:20:28] calls my semantic search tool.
[0:20:30] It wrote a quite extensive search query in my opinion,
[0:20:36] but it works.
[0:20:37] It finds the right talk by Bilge.
[0:20:41] Then it decided that that apparently wasn't enough.
[0:20:44] So it rewrote the search query,
[0:20:47] but decided, but got the very similar search results back.
[0:20:53] So after that, it decided that, sorry,
[0:20:57] it decided that it's now able to respond
[0:21:02] with the right talks.
[0:21:06] This is where most agentic search demos fail,
[0:21:10] but this is very brittle.
[0:21:12] Does anyone have an idea how we can break this?
[0:21:15] Yes, that's a good idea.
[0:21:25] Anything else?
[0:21:30] Asking it something that's not in the database
[0:21:32] would be something great.
[0:21:34] What about asking it something where semantic search
[0:21:39] actually falls short?
[0:21:40] Maybe something where we want to look for a keyword,
[0:21:44] a specific keyword.
[0:21:48] Also doing something like filtering
[0:21:50] because in this search tool we don't have any
[0:21:52] filters implemented, right?
[0:21:56] So,
[0:21:56] So, my choice of search query is which sessions should I visit to learn more about GEPA?
[0:22:08] I'm not even sure, like I've heard people talk about GEPA, I'm not even sure if I'm
[0:22:13] pronouncing it correctly, sorry, that's why I need to definitely attend this session.
[0:22:20] So, what you can see is the agent now calls the semantic search tool and this time it's
[0:22:28] looking for GEPA.
[0:22:29] So far so good.
[0:22:32] But now you can see it's actually returning a talk for DeepMind's Gemma models, I guess
[0:22:41] Yes, from a tokenization perspective,
[0:22:45] it could be similar to GPA or JEPA, I don't know.
[0:22:49] Then it returns something on harness engineering.
[0:22:52] Not sure if that's necessarily related.
[0:22:55] And then a third one,
[0:22:58] clearly none of these are related to GPA.
[0:23:03] Spoiler alert, I know there's a talk about GPA or JEPA.
[0:23:07] Again, I think it's right after this one.
[0:23:10] on. So we can see the search tool we just created, it's not very useful, or at least
[0:23:19] useful only for a very narrow scope of use cases, right? What if we let the agent now
[0:23:27] write an entire search query from scratch? Let me show you how we can do this. So we're
[0:23:35] We're now replacing the database tool that we had with an execute query tool.
[0:23:41] So we're letting the agent not only take in like a topic, but this time we're giving it
[0:23:48] an entire, the search tool, an entire search query.
[0:23:53] And I'm going to show you, because this is quite difficult for an agent, we're also combining
[0:24:00] it with a skill loading tool.
[0:24:01] tool. So doing the same thing, I'm setting up my LLM. You've probably noticed I'm switching
[0:24:12] to a little bit more powerful model here. So I'm switching from the GPT 5.4 nano to
[0:24:18] the mini because I am now anticipating that writing search queries is a little bit more
[0:24:23] difficult so the nano is probably not powerful enough. I'm using the exact same system prompt
[0:24:32] as before. And now I'm creating a general purpose database query tool. Since I'm using Elastic
[0:24:42] Search, I'm going to be using the Elastic Search query language, which is a piped query language
[0:24:48] for filtering, transforming and analyzing data. It looks something like this. Maybe it reminds
[0:24:55] you of SQL. It's a little bit different. It has different capabilities. Not important for this
[0:25:01] session but you can see when I connect to my client and then I use this query
[0:25:08] method from the SQL class and run this query you can actually see that there is
[0:25:16] a session by Samuel which talks a lot about GPA and see here is a match here
[0:25:23] Here's another match.
[0:25:26] So let's wrap this into a search tool.
[0:25:33] You can see this time,
[0:25:36] I just used the query method again here,
[0:25:40] and the agent takes in the ESQL query as a parameter.
[0:25:47] And I exchanged the tool description
[0:25:51] with something that's called execute an ESQL query
[0:25:54] against the conference schedule index in Elasticsearch.
[0:25:59] notice anything different about how I wrote this search tool versus the other one. This time I
[0:26:14] added a try accept block here for error handling. Generally speaking, you should have error
[0:26:22] handling. But since I'm anticipating that writing a good SQL query or a valid one is going to cause
[0:26:29] more problems for the tool, I don't want the agent to just fail and then the whole system
[0:26:36] them to crash so instead of instead I return the error response to the agent so it can kind of
[0:26:43] self-correct rewrite the query generally speaking super important to have this right so the agent
[0:26:50] can self-correct so when we can test this here this is not important then I'm plugging in the
[0:26:58] LLM the system prompt and my not new search tool into the agent again and when I now ask
[0:27:05] ask it the exact same question as before,
[0:27:08] which session should I visit to learn more about GPA?
[0:27:12] You can see it calls the execute ESQL query tool
[0:27:16] and it generates something that looks like valid ESQL.
[0:27:23] I'm not expecting anyone to be very familiar with ESQL.
[0:27:27] What's wrong with this is that ESQL doesn't use
[0:27:31] the percentage sign as a wildcard character.
[0:27:34] and in SQL you would use the asterisk so in this case it's actually looking for percentage sign
[0:27:42] GPA percentage sign in the data as an exact match so that's why it's actually returning
[0:27:49] zero search results and this is when you're working with search tools also super important
[0:27:55] to think about is returning zero search results actually a valid response or is it a failure mode
[0:28:02] mode. Okay. How could I overcome this? I could probably write a more descriptive tool description,
[0:28:17] give it a little bit more help on how to write better parameters. I could reinforce it in
[0:28:24] the system prompt, give it more instructions there. Or I could use an agent skill because
[0:28:30] because you need more documentation
[0:28:33] than just like a one-liner, right?
[0:28:36] So now I'm going to show you how to add an agent skill.
[0:28:43] So in this case, I'm going to be writing
[0:28:47] my own very short custom agent skill.
[0:28:51] Quick question, who has used
[0:28:53] and played with agent skills before?
[0:28:57] Okay, good amount.
[0:29:00] So I'm gonna be writing a very short one here.
[0:29:07] There is official Elasticsearch agent skills available
[0:29:11] if you want to play around with it.
[0:29:13] In this case, I'm just using my own custom ones.
[0:29:17] So how that works is you have the skill name
[0:29:23] and then also a skill description
[0:29:25] which gets injected into the system prompt.
[0:29:28] So only the, if you write it in markdowns,
[0:29:32] I think the front matter, right?
[0:29:34] That gets injected into the system prompt.
[0:29:37] And then when you need it,
[0:29:41] more information on the agent skill is loaded
[0:29:43] into the context window, right?
[0:29:45] So it's called something like progressive disclosure
[0:29:48] where you kind of add more information
[0:29:50] about the skill as you as needed.
[0:29:52] needed. So in this case I have some minimal instructions like here's the basic structure
[0:30:02] of an ESQL query, ESQL uses double quotes for string literals, just some very basic
[0:30:11] syntax rules and I also added some more information about the wildcard pattern so it's not making
[0:30:18] this mistake again and then as I mentioned Langchain has some boilerplate code you can
[0:30:25] just copy and reuse for using agent skills I'm skipping over this all you have to know is we have
[0:30:34] a tool a skill loading tool and it's get it's getting inject sorry it gets combined with us
[0:30:42] something called a skill middleware skipping over this because this is not relevant for our session
[0:30:50] And now all I have to do is edit the tool description of my general purpose search tool.
[0:31:01] So this is the exact same tool that I had before except this time I'm now adding some
[0:31:11] relationship to I'm saying always use the Elasticsearch ESQL skill to generate the ESQL
[0:31:18] query before using this tool because otherwise if the agent then still uses
[0:31:24] this tool first without using the agent skill then that would be a shame
[0:31:31] right. I'm doing the exact same so I'm reinforcing this now in the system
[0:31:37] prompt I'm saying the same thing to use the Elasticsearch agent skill first
[0:31:43] before calling the general purpose search tool and now I'm plugging it into
[0:31:48] to the agent again so this time LLM system prompt for the skill loading tool I have the skill
[0:31:55] middleware and then my general purpose ESQL query tool and now when I let the ask when I ask the
[0:32:04] agent which session should I visit to learn more about GEPA you can see it first first loads the
[0:32:10] the skill. So it actually loads everything that's kind of in the body part of the skill
[0:32:18] into my context window and then it generates this time a very valid ESQL with the asterisks
[0:32:31] as my percentage as my wildcard characters and you can see it actually finds the right
[0:32:38] session and now it tells me that at 1040 so after this session I should be going
[0:32:46] to this session to learn more about GPA and learn how to pronounce it correctly
[0:32:52] okay what's also cool about this is now the agent can do a lot of things right
[0:33:00] it can also do aggregations so if I ask it something like how many sessions are
[0:33:08] are on April 8th.
[0:33:09] You can see again, it loads the Elasticsearch ESQL tool.
[0:33:17] And then it writes an ESQL query, whoops.
[0:33:22] It writes an ESQL query that's using a filter,
[0:33:26] so it's filtering for April 8th.
[0:33:29] And then it also does an aggregation, some counting.
[0:33:33] It tells me today there are 27 sessions.
[0:33:36] sessions. This is nice because if I just do a search, let's say I ask it to tell me which
[0:33:48] sessions are on April 8th and it only runs a filtered search, right? So just imagine
[0:33:53] it would give me a list of all 27 sessions that are today and we let the agent count
[0:34:00] how many sessions there are. That would probably not be so good because we all know agents
[0:34:06] agents or LLMs are notoriously bad at counting things.
[0:34:10] And also it would fill up your context window, right?
[0:34:14] So by letting the agent do its own calculation,
[0:34:19] so outsourcing the calculation part into the search tool,
[0:34:24] it's actually quite an efficient way to do this, right?
[0:34:30] Any questions so far?
[0:34:39] Okay.
[0:34:42] Let's switch gears.
[0:34:42] years. This is a very prominent topic at the moment. Maybe you've heard the discussion
[0:34:50] about all an agent needs is a shell tool and a file system. So I work at Elastic but I
[0:34:58] don't discriminate. Let's look at file systems and how to do this because I think it's a
[0:35:04] very interesting topic in general so what I did here I prepared the data this
[0:35:12] time in a local file system so I have a folder called session data and in here I
[0:35:20] have for each type of session like keynotes and workshops I have another
[0:35:25] folder and in there there's per session one file looks something like this so
[0:35:32] So with the title, some metadata and description.
[0:35:38] And now I'm going to show you how you can use
[0:35:41] the shell tool with this.
[0:35:47] So I'm switching back to the GPT 5.4 nano
[0:35:50] because LLMs are just generally good at
[0:35:54] navigating file systems, writing shell commands.
[0:35:58] So GPT 5.4 nano is sufficient in this case.
[0:36:05] I define another system prompt.
[0:36:07] prompt. So the first part of the system prompt is exactly the same as the one we had before.
[0:36:18] And what I'm replacing this time is instead of explaining how the data is structured in
[0:36:24] Elasticsearch, I'm explaining how the data is structured in my local file system. Okay.
[0:36:31] Okay, so let's use the shell tool.
[0:36:37] I have to give you a disclaimer,
[0:36:39] using the shell tool can be risky
[0:36:41] since giving your agent access to a terminal
[0:36:47] can make it delete files or do other things
[0:36:51] you don't want it to do,
[0:36:52] so always recommend it to use it in a sandbox environment.
[0:36:57] Also in Langchain it doesn't have any safeguards by default
[0:37:01] so please be careful when using this but other than that it's very easy to use so
[0:37:07] you can just use import the shell tool and instantiate it here and here you can
[0:37:14] see how you would use it so it takes in the commands parameter so when I say
[0:37:20] echo hello world you can see down here it actually prints hello world into my
[0:37:25] my terminal and then all you have to do again plug in the LLM the system prompt
[0:37:32] and the shell tool and now you can ask it this exact same thing we had earlier
[0:37:39] so are there any sessions about GPA and you can say as you can see here it's
[0:37:45] called the terminal here but it's the agent calls the shell tool
[0:37:51] and it actually writes a few commands.
[0:37:54] So first it's looking at the folder structure
[0:37:58] and then it runs some grab commands.
[0:38:01] So it's looking for GPA in the session data
[0:38:04] and I think it's looking for the first 50 entries.
[0:38:09] So you can see it saw the folder structure
[0:38:14] and then it also found the one session
[0:38:17] we were talking about earlier.
[0:38:19] But since I was only looking at the first 50 and only found one session, I decided that
[0:38:27] it should probably look at the entire session data.
[0:38:30] So it finds the exact same session again.
[0:38:34] So this time it decides, okay, then I should probably look at the contents of this session.
[0:38:38] session. So now it reads the entire file content and you can see the session information as
[0:38:52] a tool response. And then at the end the agent tells me which session I should visit. Okay.
[0:39:01] Okay, grep works based on exact matches, right?
[0:39:08] And regex.
[0:39:11] And I just want to show you this
[0:39:13] because I think it's funny
[0:39:14] how surprisingly good agents are with bash
[0:39:19] because they kind of can cheat at semantic search.
[0:39:22] Let me show you this.
[0:39:30] So when I ask it,
[0:39:32] which sessions discuss handling regulatory constraints?
[0:39:35] This was our semantic search query from the beginning.
[0:39:39] You can see it again looks at the folder structure
[0:39:43] and then the first command or the first search it does,
[0:39:48] it's looking for regulat, it's fair.
[0:39:50] It's looking for regulation, for regulatory.
[0:39:54] I guess that's a fair start, but then it goes ahead
[0:39:59] and now it just chains a bunch of synonyms together.
[0:40:02] So it's looking for compliance,
[0:40:03] science, it's looking for constraints, it's looking for GDPR, it's looking for governance.
[0:40:09] Yeah, I guess that's fair. I think it actually finds a bunch of sessions. So it's like, okay,
[0:40:18] let me try a bunch of other synonyms. So now it's looking again for regular compliance,
[0:40:25] compliance, GDPR, serenity.
[0:40:29] I think, yeah, the list goes on.
[0:40:31] It's just looking at a bunch of different synonyms.
[0:40:34] And it actually is successful with this.
[0:40:38] And it finds the session by Bilge
[0:40:40] and returns the session information
[0:40:45] and then is able to respond correctly.
[0:40:51] I guess it works.
[0:40:52] Is that the most efficient way to do this?
[0:40:56] Probably not.
[0:40:57] I mean, just as an example, so let's say you want
[0:41:01] to search for something like movies
[0:41:05] with animal superheroes or something.
[0:41:08] Do you really want to do your agent to search
[0:41:10] for a list of all the animals possible
[0:41:13] when you find all those superhero movies
[0:41:16] with animal superheroes?
[0:41:18] Probably not, so it works.
[0:41:23] Is it the best?
[0:41:24] I let you decide. So at the moment there's many different semantic search
[0:41:31] alternatives to grep. I think there's one by Lama index called semtools. There's a
[0:41:40] really cool one by lighton which is called colgrep based on multivector
[0:41:45] embeddings. Also there's one by our own Gina that's called ginagrep. So today
[0:41:52] Today I'm going to show you how easy it is to actually use this together with your agent.
[0:41:58] So all you have to do is go ahead and install the GinaGrab CLI.
[0:42:06] And then all you have to do is tell your agent that it now has access to this CLI.
[0:42:14] So this is the exact same system prompt as I had earlier.
[0:42:19] earlier. Now with the difference that I'm explaining to it that it has Gina grab and
[0:42:26] how Gina grab works how it should use it. Here are some examples of how you would use
[0:42:34] Gina grab. Just a disclaimer Gina grab has many different modes you can use it for classification
[0:42:42] you can use it for re-ranking today I'm just showing you how to use it for semantic search
[0:42:46] search and at the end I'm also explaining to the agent when it should use grep and when
[0:42:54] it should use gina grep just so it knows for exact matches you probably still want to use
[0:42:59] grep and for more semantic search or fuzzy queries use gina grep and then plugging this
[0:43:09] in to my agent again and when I now run the exact same semantic search query we had earlier
[0:43:17] so which sessions discuss handling regulatory constraints.
[0:43:23] You can see the same behavior,
[0:43:26] so it calls the terminal tool.
[0:43:28] It first explores the folder structure
[0:43:31] and then it actually, on the first try,
[0:43:34] is able to correctly use gnag rep,
[0:43:37] so it's looking for regulatory constraints.
[0:43:40] And boom, it actually finds the session
[0:43:44] by Billge on the first try.
[0:43:46] try, finds a few others because it's looking for 10. It says returned top K of 10. And
[0:43:56] then it's able to answer me correctly. Nice. All right. Any questions so far? Good. Then
[0:44:07] I'm switching back. So we were looking at a bunch of different tools today. We saw how
[0:44:28] how big the tool landscape is.
[0:44:30] I showed you a few of the search tools we have.
[0:44:34] Now, some practical recommendations
[0:44:37] on when should you actually use what.
[0:44:41] So, maybe let's start with this.
[0:44:45] If you're looking for just one silver bullet tool,
[0:44:48] that's probably not the right way to go.
[0:44:52] Again, if you think about it,
[0:44:55] doing good search is incredibly difficult.
[0:44:58] called. So ideally you want to have or curate the right set of search tools for
[0:45:05] your agents search behaviors and you want to have a combination of specialized
[0:45:11] tools and a combination and general-purpose tools. So specialized
[0:45:17] tools are something that the agent can use out of the box, something with a very
[0:45:23] simple parameter. Something where you're not, where you don't need a very powerful
[0:45:29] LLM, you know the agent isn't going to make a lot of mistakes, the agent can
[0:45:33] just use this tool out of the box. So at Elastic we like to think about this,
[0:45:38] about having a low floor. So this is a concept from user experience where the
[0:45:44] agent can just use a tool, doesn't make many mistakes, it's also efficient so it
[0:45:52] it doesn't have to run your tool multiple times.
[0:45:55] You can think about this as the semantic search tool
[0:45:58] we had earlier.
[0:45:59] Maybe you need to look up customers by ID
[0:46:03] a lot of the time, then having a specialized tool
[0:46:06] for that exact operation would be helpful.
[0:46:10] But then you also want to give the agent a high ceiling.
[0:46:14] That means for unexpected queries, for complex questions,
[0:46:20] You want the agent to still be able
[0:46:23] to handle these questions, right?
[0:46:26] And not have these limited specialized tools
[0:46:30] and be like, I cannot solve this.
[0:46:32] So for this case, something like a shell tool
[0:46:35] or the very general purpose one we had earlier
[0:46:39] of a query execution tool would be very helpful.
[0:46:45] But the problem with the query execution tool
[0:46:47] or the shell tool you saw earlier is,
[0:46:50] since it's sole general purpose,
[0:46:52] the agent sometimes might need more iterations
[0:46:55] to actually get to the right answer, right?
[0:47:01] So this was my practical recommendation
[0:47:04] of having a balanced set of search tools
[0:47:09] of a low floor and high ceiling.
[0:47:13] This is all nice when you already know your agent's behavior,
[0:47:16] behavior. But if you don't know your agent's query behavior yet, then I would recommend
[0:47:23] to start with a general purpose tool. Then log your agent's behavior. Generally speaking,
[0:47:33] logging your agent's behavior, I recommend it. But if you notice maybe your agent is
[0:47:39] taking four or five tool calls per question, that's too many tool calls. Then you probably
[0:47:47] that's probably an indicator that the tool your agent has
[0:47:51] is too difficult for it to use.
[0:47:54] Then definitely look at what the agent's
[0:47:56] actually trying to solve,
[0:47:58] maybe scope out something more specialized in that case.
[0:48:02] Also if you notice specific query behaviors.
[0:48:10] This is what I personally did with my test OpenClaw.
[0:48:14] I was, it has the exec tool
[0:48:16] and I started logging its behavior
[0:48:19] and obviously I was playing around with databases.
[0:48:23] So after three days I was asking it
[0:48:25] what kind of interesting patterns do you see
[0:48:27] and was recommending me actually to implement
[0:48:30] some specific search tools to interact with the database
[0:48:35] because it was out of the box only using the exec tool.
[0:48:40] All right, start with general purpose tools.
[0:48:42] If you don't know your user's behavior yet,
[0:48:44] log what breaks and add purpose built interfaces.
[0:48:46] basis. Yeah, that was a lot to take in. I'm sure you have lots of questions, so I'm opening
[0:48:56] it up for Q&A and otherwise on your way out, don't forget to grab yourself some stickers
[0:49:01] and then thank you for joining my session. There's a mic coming.
[0:49:20] Thank you. So would you say the tool stack you need is also mostly dependent on the model
[0:49:25] you're willing to use? So if you're using a very good model, it might be fine using
[0:49:30] the shell tool or search tool but a very small model and light agent might need more specialized
[0:49:36] tools or yeah actually we i think in our internal testing we noticed that a more powerful tool
[0:49:43] actually reduces the error rate of for the parameters by i don't know the numbers exactly
[0:49:50] but it was a very big amount where it reduced the error rate so having a stronger model definitely
[0:49:56] definitely helps for the general purpose tools,
[0:50:01] but I think you cannot expect,
[0:50:03] just because you have a very strong model,
[0:50:05] that there's gonna be no errors, if that makes sense.
[0:50:09] Thanks for a nice talk.
[0:50:20] I have one question, maybe it's slightly off topic,
[0:50:23] but so now we are talking about agentic rack,
[0:50:27] but it comes with the drawback of having higher latency
[0:50:31] against typical rack.
[0:50:32] so would you recommend of having like a second pathway for simple rack for fast
[0:50:40] answers and how would you like guide the agent to actually choose the right one
[0:50:45] because I think it's hard to say which question should be answered by a
[0:50:51] gentic rack or by simple rack that's a good question I don't think I have a
[0:51:00] have a good answer on like on the top of my head right now I think I was maybe
[0:51:07] something related I was asked recently if you have a rack system should you
[0:51:11] replace it with a genetic rag and I guess this is kind of going in the same
[0:51:15] direction of when do you actually need agentic rag right probably for a lot of
[0:51:27] of use cases, I know RAG has been killed many times,
[0:51:31] but I think the reality is that RAG is still very effective
[0:51:35] for many use cases.
[0:51:39] How would you actually switch between RAG and agentic RAG?
[0:51:45] I'm not sure because I assume it's, again,
[0:51:47] it needs some kind of almost agentic logic
[0:51:51] of switching between them.
[0:51:52] So I'm not sure, I'm sorry.
[0:51:56] Sorry.
[0:51:56] In such cases like when you have the wildcard in the GAPA
[0:52:16] example, why can't we just perform a hybrid tool that
[0:52:24] maybe search and replaces common wrong wildcard symbols coming
[0:52:31] coming from SQL with the correct ones, for instance?
[0:52:38] I'm not sure if I understand your question correctly.
[0:52:41] I mean, there are cases in which the agent
[0:52:48] doesn't know how to write the correct query
[0:52:52] because maybe he thinks the placeholders
[0:52:56] coming from SQL apply it to ESQL,
[0:53:03] but so why don't we perform a hybrid tool
[0:53:08] that determine search and replaces the wrong placeholder,
[0:53:18] the percentage symbol with the asterisks.
[0:53:22] Yeah, actually, so the example I showed you of using the agent skill wasn't necessarily
[0:53:29] the necessary solution for it.
[0:53:33] You can also add just some very simple instructions on for ESQL don't use the percentage sign
[0:53:43] as a wildcard character.
[0:53:44] It actually works.
[0:53:45] I tried it when I was building the demo.
[0:53:49] But then when the agent now runs in the next issue, then you start adding the next piece
[0:53:55] of documentation, then you can kind of start writing the entire ESQL documentation from
[0:54:00] scratch into your system prompt.
[0:54:02] And yes, for the demo purposes, it would have worked, but it's probably not how you would
[0:54:08] do it necessarily when you're building something more robust, right?
[0:54:12] right, because if you just add little band aids
[0:54:17] every time you run into an error,
[0:54:20] then what happens when you run into the next edge case?
[0:54:24] Does that make sense, yeah?
[0:54:26] Hi, thank you for a really wonderful presentation.
[0:54:36] I have a question.
[0:54:38] In the demo, we have walked through the agentic search
[0:54:41] with dbqrisk tool and also another one with shell tool.
[0:54:45] Would you recommend in the practical use
[0:54:47] we can also kind of use, combine both tool
[0:54:52] and then we validate the result from each of tool
[0:54:55] and then we kind of add the confidence
[0:54:57] of the result from the LM.
[0:54:59] Would you like recommend doing this in a practical use?
[0:55:01] Yes, yes, that's a great question.
[0:55:03] Also, again, I'm kind of cheating in this demo, right?
[0:55:07] Because I'm only showing you one tool per demo.
[0:55:10] In reality, you would have something more
[0:55:13] like a bunch of different tools
[0:55:15] where you then have to decide which or the agent has to decide which tool to
[0:55:20] use I think there was a very interesting blog post by Vercel I believe and they
[0:55:27] did an experiment I think it's called if you want to look it up I think it's
[0:55:31] called testing is if bash is all you need is the title I think of the blog
[0:55:35] post and they actually kind of benchmark or tested an agent with a bash tool an
[0:55:43] an agent with just file search tools, I believe,
[0:55:46] and an agent with database tools.
[0:55:50] And in the end, they also had one agent with a bash tool
[0:55:54] and the database tool,
[0:55:56] and they noticed that was super interesting
[0:56:00] for a specific set of queries
[0:56:03] where you have analytical queries.
[0:56:07] This is a specific use case.
[0:56:09] Actually, the database tool was more effective,
[0:56:11] but on the other hand the file search was very effective as you saw for just
[0:56:17] quickly finding things but the very interesting aspect was the hybrid agent
[0:56:23] with the bash tool and the database tool was actually achieving the highest like
[0:56:31] highest accuracy because at first I believe it was first using the database
[0:56:35] tool and then verifying the results with the shell with the shell tool and that
[0:56:41] that led the agent to actually achieve better accuracy.
[0:56:44] So I think that was a very interesting way
[0:56:47] and behavior to see in agents.
[0:56:51] Thanks for sharing.
[0:57:04] One second question.
[0:57:06] So if we use the semantic search tool,
[0:57:09] I think in practice you probably would use
[0:57:12] some kind of threshold to cut the results,
[0:57:16] to not get something if there's no answer.
[0:57:20] But in the agentic regime,
[0:57:22] would you then say, okay, let's put a conservative threshold
[0:57:26] such that we don't confuse our agent,
[0:57:29] or would you say the agent is smart enough
[0:57:32] even if we retrieve results that are not really relevant,
[0:57:35] it will be good enough to notice that?
[0:57:39] Yeah, that's a great question actually.
[0:57:43] So in the examples you probably saw some
[0:57:46] where the agent was returning,
[0:57:48] I think in the last Gina grab example,
[0:57:50] you see it's actually returning the top K results
[0:57:53] where only the first one is the actual relevant one.
[0:57:57] And I think because the agent does a little bit
[0:58:00] of reasoning over whether the search results
[0:58:03] are relevant to the search query,
[0:58:05] I think it's much better or they're much better today
[0:58:08] at kind of weeding out what's not relevant.
[0:58:11] But then you kind of run into the risk
[0:58:13] if you have longer running conversations
[0:58:15] that kind of these search results sit in your context window
[0:58:19] though long-term could have the problem of confusing your agent long-term so I
[0:58:24] think it kind of it depends on your use case of how you're like how your agent
[0:58:35] can handle like irrelevant search results but generally speaking based on
[0:58:41] search results it can filter out what's irrelevant thank you for the talk
[0:58:58] amazing are you utilizing sub-agents for these search queries because yeah if we
[0:59:06] let them decide to is it relevant to use a question like it's done in Regex
[0:59:10] framework for example for evaluation I mean sub-agents would help a lot do we
[0:59:15] have any experience with them unfortunately not I have not played
[0:59:19] around with sub-agents yet I can only tell you that I know for example I
[0:59:24] I believe in cloud code they're using subagents for doing specific search tasks.
[0:59:29] I think there was a blog post on how they're actually using a subagent to answer
[0:59:35] specific questions about cloud code because it's kind of like a niche question a
[0:59:41] user would ask. So in this case they kind of outsourced the expertise to a
[0:59:47] subagent.
[0:59:47] So having a subagent for specific niche questions I think would be interesting,
[0:59:52] interesting, but I don't have too much experience on it.
[0:59:57] Okay, thanks.
[0:59:58] Can I ask another question?
[1:00:00] Sure.
[1:00:04] Damn, I forget, sorry.
[1:00:06] I try to catch up later.
[1:00:26] You're kindly off topic, but you talked about skills,
[1:00:31] and the big benefit of skills is just have the description
[1:00:35] in the system prompt, and whenever needed,
[1:00:39] we need to load this full skill.
[1:00:42] Do you have any recommendation when and how to clear the system prompt again?
[1:00:47] So because we want to keep the context window small and maybe for a long session we might
[1:00:55] have up to ten skills, full skills in the context and yeah.
[1:01:00] I'm not sure, Joe do you have a better answer, like have an idea?
[1:01:36] But yeah, so like the way that we are doing it behind the scenes is that we're providing
[1:01:42] like that kind of progressive disclosure of skills so we're providing those the
[1:01:48] skill names and descriptions the location within the file store and then
[1:01:53] from the file store we're loading into the context window when we need that
[1:01:57] skill and then we offload it once it's once it's the program you know the
[1:02:01] context window progresses ahead of time around that so we have this kind of more
[1:02:06] on-demand one around that that's the same with our like compaction like
[1:02:11] of context and that's what I would advise you to do like some of the
[1:02:15] questions do try and use the file store as much as you can and have those tools
[1:02:20] as well like being able to grab the file store for when you want to see previous
[1:02:25] tool results and then and then use it from that thanks this is my colleague
[1:02:34] Joe from Elastic as well awesome there are no more question I will let you guys
[1:02:45] go into the coffee break again don't forget to grab yourself some stickers
[1:02:49] and happy to catch up in the halls if anyone's interested thanks so much
