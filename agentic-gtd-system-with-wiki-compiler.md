# Agentic GTD System With a Wiki-Compiler Memory Layer

## Purpose

This document describes how to use the LLM Wiki Compiler as part of a personal agentic GTD system.

The core idea is:

- use a **task layer** for execution
- use a **working-memory layer** for short-lived context
- use the **wiki compiler** for durable, structured, compounding memory

This is not a proposal to turn the wiki into a task manager or calendar. It is a proposal to make it the long-term memory and review backbone of a personal assistant system.

---

## The Core Fit

### What the wiki compiler is good at

The wiki compiler is a strong fit for:

- reference material
- project support material
- decisions and rationale
- long-term preferences
- patterns across notes, journals, reading, and conversations
- curated source material and synthesized takeaways
- reflective memory that improves over time
- provenance-aware memory where it matters what a belief came from

### What it is less good at

It is a weak fit for:

- next-actions execution
- reminders
- calendar commitments
- rapid transactional updates
- ephemeral conversation state
- high-churn operational lists

So the right framing is:

- **good for durable memory**
- **not good as the only operational layer**

---

## Mapping to GTD

### Strongly compatible GTD areas

The wiki compiler maps well to these parts of GTD:

- **Reference**
- **Project support**
- **Weekly review support**
- **Areas of focus / higher horizons**
- **Decision history**
- **Long-term reflection**
- **Incubation of richer someday/maybe ideas**

### Moderately compatible GTD areas

It can support these if modeled deliberately:

- project pages
- waiting-for tracking
- someday/maybe review
- thematic summaries across active domains

### Less compatible GTD areas

It is not the ideal primary system for:

- inbox capture
- next actions
- calendar
- reminders
- fast daily execution views
- strict transactional workflows

---

## Recommended Three-Layer Architecture

## 1. Task Layer

This is the execution surface.

Use it for:

- inbox
- next actions
- waiting for
- reminders
- calendar-linked commitments

This layer should answer:

- what do I need to do now?
- what am I waiting on?
- what is due today?

The task layer should be fast, lightweight, and easy to update many times per day.

## 2. Working-Memory Layer

This is the short-term, transient layer.

Use it for:

- current session state
- today/this-week focus
- temporary plans
- recent context not yet worth compiling
- active agent thread state

This layer should answer:

- what are we doing right now?
- what changed recently?

This can be daily notes, scratchpads, session files, or agent memory state.

## 3. Wiki-Compiler Layer

This is the durable, structured, compounding memory layer.

Use it for:

- project meaning and support
- decisions
- reference
- preferences
- recurring patterns
- long-term goals and themes
- incubated future ideas
- syntheses from conversations, notes, and source material

This layer should answer:

- what do we know?
- why is the system shaped this way?
- what patterns matter over time?

---

## Recommended GTD Split

### Capture

Capture should happen in the task layer or a daily note, not directly into the wiki by default.

Examples:

- quick tasks
- follow-ups
- ideas
- notes from calls
- things to process later

### Clarify

The agent should clarify each captured item into one of:

- next action
- project
- waiting for
- someday/maybe
- reference
- calendar item

### Organize

Organize by sending each item to the right layer:

- actions -> task layer
- schedules -> calendar/reminder layer
- durable knowledge -> wiki
- transient context -> working memory

### Reflect

The wiki compiler becomes especially useful during review.

The agent can:

- surface stale project support
- summarize what changed this week
- detect contradictions or drift
- show decision history
- identify waiting items that need follow-up
- surface dormant someday/maybe ideas worth revisiting

### Engage

Doing should happen from the task layer, not from the wiki.

The wiki should support action, not replace the action surface.

---

## Projects: Where They Should Live

If the task layer is strong enough, **Projects should live primarily in the wiki**.

Why:

- a project is more than a list of actions
- it has outcome, context, rationale, notes, decisions, support material, constraints, and history
- that is exactly what the wiki is good at

### Recommended split for projects

**Wiki project page**

- desired outcome
- status
- why it matters
- project support notes
- linked sources
- related decisions
- review notes
- links to active next actions

**Task layer**

- current next action(s)
- waiting-for items
- deadlines/reminders
- maybe a lightweight reference to the project page

### Principle

- the wiki is the **source of truth for project meaning**
- the task layer is the **source of truth for executable commitments**

---

## Someday/Maybe: Page vs Metadata

Someday/Maybe should usually be modeled as **both**:

- a compiled review list
- backed by either lightweight metadata entries or full pages

### Lightweight someday/maybe items

Good for:

- small future ideas
- books to read
- hobbies to try
- low-investment possibilities

These can be metadata-driven items compiled automatically into a review list.

### Rich someday/maybe items

Good for:

- future projects with real shape
- possible trips
- business ideas
- long-term life directions
- themes you want to incubate over time

These should be full pages.

### Recommended model

- **list is the review surface**
- **page is the storage unit when the item has substance**

So:

- use metadata for light items
- promote to full page when the idea grows
- compile both into a unified Someday/Maybe review view

---

## Waiting For: Why It Needs Deliberate Modeling

`Waiting For` is only a partial fit for the wiki because GTD expects it to be an active control list, not just stored information.

If you want the wiki to participate in `Waiting For`, it must be modeled explicitly.

### What waiting-for needs

- who you are waiting on
- what you are waiting for
- when it was requested
- follow-up date
- current status
- related project

Without these fields, waiting-for items will get buried in prose and stop being trustworthy.

### Recommendation

Keep the main active `Waiting For` list in the task layer.

Optionally mirror or enrich it in the wiki when:

- there is important supporting context
- delegation history matters
- there is a decision/history trail worth keeping

So the wiki can support `Waiting For`, but should not be the only live control surface unless you explicitly build structured views for it.

---

## Personal Assistant Memory: Where This Fits

This project is a strong fit for a personal assistant’s **durable memory**, but not for all memory.

### Good durable memory

- user preferences
- repeated patterns
- ongoing projects
- areas of focus
- decisions
- curated sources
- recurring issues
- reflective summaries

### Bad fit for sole memory system

- short-term conversational state
- immediate reminders
- unread notifications
- rapidly changing task lists
- “what happened five minutes ago?”

### Best architecture for a personal agent

- **task layer** for action
- **working-memory layer** for recent context
- **wiki compiler** for durable structured memory

---

## Business Documents, Orders, and Invoices

This system is usually **not** the right primary system for:

- issuing invoices
- bookkeeping
- accounts payable / receivable
- payment reconciliation
- tax-compliance recordkeeping

Those are operational systems, not knowledge systems.

### Where it can help

It can still be useful as a **knowledge layer on top of business documents**.

Examples:

- vendor history
- recurring invoice anomalies
- procurement decisions
- customer account context
- operational lessons from orders and invoices

So:

- not good as the transaction system
- useful as the memory/synthesis layer above the transaction system

---

## Suggested Wiki Structure for a GTD-Oriented Personal Agent

Possible top-level structure inside `wiki/`:

```text
wiki/
  projects/
  incubation/
  decisions/
  overviews/
  concepts/
  entities/
  sources/
  maintenance/
  index.md
  log.md
```

### Suggested meanings

- `projects/`
  - active and inactive project pages
- `incubation/`
  - someday/maybe pages and future ideas
- `decisions/`
  - structural and project decision records
- `overviews/`
  - multi-source syntheses and reviews
- `maintenance/`
  - lint reports and other operational wiki artifacts

---

## Suggested Cross-System Integration

### Task layer -> wiki

When an item becomes substantial, the agent should create or update a wiki page.

Examples:

- a project gets enough complexity to justify a page
- a someday/maybe item grows into a real idea
- a repeated task pattern becomes a useful concept page

### Wiki -> task layer

During review, the agent should extract actionable edges from the wiki.

Examples:

- stale project needing a next action
- waiting item needing follow-up
- dormant someday/maybe item worth reconsidering
- contradiction or gap that implies research/action

### Working memory -> wiki

When recent conversations or notes contain durable value, the agent should compile them into the wiki.

Examples:

- stable preference discovered in conversation
- recurring friction pattern
- clarified project scope
- decision with long-term consequences

---

## Weekly Review With This Architecture

A good weekly review loop could look like this:

1. scan the task layer
2. scan the working-memory layer
3. update or compile durable insights into the wiki
4. review project pages in the wiki
5. review incubation/someday pages
6. review decision history and unresolved tensions
7. surface stale or neglected areas
8. push fresh next actions back into the task layer

This makes the wiki the reflective and structural review engine, while the task layer remains the execution engine.

---

## Design Principles

### 1. Don’t force everything into the wiki

The wiki should not absorb every task, reminder, or fleeting note.

### 2. Keep actions and knowledge separate

- actions live in the task layer
- knowledge lives in the wiki

### 3. Let the agent move material between layers

The agent’s job is not only to answer questions, but to classify and route information into the correct layer.

### 4. Use the wiki for meaning, not just storage

The wiki should explain:

- what matters
- why it matters
- how it changed
- what supports it

### 5. Let review produce better structure over time

The system should become more organized and more useful through repeated reviews, not just repeated captures.

---

## Best-Fit Summary

This project is a good fit for:

- a personal assistant’s long-term memory
- GTD reference
- GTD project support
- higher-horizon thinking
- decision history
- incubated future ideas
- reflective weekly reviews

It is a weaker fit for:

- next actions
- reminders
- calendar
- transactional workflows
- fast-changing short-term state

The best combined system is:

- **task layer for doing**
- **working-memory layer for current context**
- **wiki compiler for durable memory and review**

That combination gives you a personal agentic GTD system that is both operationally practical and capable of learning over time.
