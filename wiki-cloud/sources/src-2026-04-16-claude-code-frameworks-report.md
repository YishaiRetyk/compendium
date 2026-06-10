---
id: src-2026-04-16-claude-code-frameworks-report
title: "Claude Code Frameworks & Patterns: A Comparative Report"
type: source
status: active
summary: "A synthesis of 8 parallel web-research investigations (April 2026) mapping
  the Claude Code ecosystem: the four building blocks (skills, slash commands,
  subagents, CLAUDE.md/AGENTS.md) unified by progressive disclosure, and a head-to-head
  comparison of the three dominant orchestration frameworks — Spec Kit (the spec
  gate), Superpowers (execution discipline), and GSD (context engineering) — with a
  comparative matrix, cross-cutting themes, and a decision guide."
created_at: 2026-06-09
updated_at: 2026-06-10
sources: []
epistemic_status: mixed
tags:
- claude-code
- agentic-frameworks
- spec-kit
- superpowers
- gsd
- spec-driven-development
- subagents
domains:
- ai-agents
- software
supersedes: null
superseded_by: null
aliases:
- "Claude Code Frameworks & Patterns: A Comparative Report"
- "Claude Code Frameworks Report"
- "src-2026-04-16-claude-code-frameworks-report"
has_contradictions: false
knowledge_domain: software
example: false
path: sources/2026/2026-04/2026-04-16-claude-code-frameworks-report.md
content_hash: "sha256:f47a04313f42b98b4555a3d23ed1e8321c69ab7b7fc378d0c043402fe3e2ff6e"
ingested_at: 2026-06-09
source_type: research-report
compilation_status: compiled
compiled_against_hash: "sha256:f47a04313f42b98b4555a3d23ed1e8321c69ab7b7fc378d0c043402fe3e2ff6e"
compiled_targets:
- spec-kit
- superpowers
- gsd
- claude-code-orchestration-frameworks
- spec-driven-development
- subagents
- progressive-disclosure
- claude-code
- agent-skills
---

## TL;DR

A comparative report (April 2026) synthesizing 8 parallel web-research investigations into the Claude Code ecosystem. Part I catalogs four building blocks — Agent Skills, slash commands, subagents, and CLAUDE.md/AGENTS.md memory files — assembled around one architectural principle, progressive disclosure. Part II profiles the three dominant "opinionated assembly" frameworks: Superpowers (Jesse Vincent — execution discipline via a mandatory brainstorm→plan→implement→review skill chain), GSD (TÂCHES — context engineering via fresh-subagent-per-task and a `.planning/` artifact tree), and Spec Kit (GitHub — spec-driven development where the spec is the version-controlled source of truth and code is regenerable). Parts III–V give a comparative matrix, cross-cutting themes (where they agree/diverge), composability ("Spec Kit specifies, GSD stabilizes, Superpowers executes"), and a situation→framework decision guide. The report is a secondary synthesis; its star counts and some version/date specifics are point-in-time and treated as tentative.

## Key Takeaways

- The Claude Code ecosystem has converged on four building blocks (skills, slash commands, subagents, CLAUDE.md/AGENTS.md) unified by progressive disclosure as the architectural backbone. [prov:src-2026-04-16-claude-code-frameworks-report#sec:executive-summary|direct|2026-06-09]
- Three frameworks dominate the orchestration layer and increasingly compose rather than compete: Spec Kit (spec gate), Superpowers (execution discipline), GSD (context engineering). [prov:src-2026-04-16-claude-code-frameworks-report#sec:executive-summary|direct|2026-06-09]
- Superpowers forces a mandatory brainstorm→plan→implement→review progression hard-wired into ~14 composable skills, with a SessionStart hook that re-primes after clear/compact. [prov:src-2026-04-16-claude-code-frameworks-report#sec:superpowers|direct|2026-06-09]
- GSD's thesis is that context rot degrades quality past ~50% context fill, so every task runs in a fresh 200K-token subagent context against a `.planning/` artifact tree. [prov:src-2026-04-16-claude-code-frameworks-report#sec:gsd|direct|2026-06-09]
- Spec Kit's thesis is "specifications don't serve code — code serves specifications": the spec is the version-controlled artifact and is tool-agnostic across 20+ agents. [prov:src-2026-04-16-claude-code-frameworks-report#sec:spec-kit|direct|2026-06-09]
- Subagents' killer feature is context isolation: a research subagent can process 100K tokens and return a ~500-token distilled summary, keeping the parent context clean; routing depends on the description ("Use PROACTIVELY", "MUST BE USED"). [prov:src-2026-04-16-claude-code-frameworks-report#sec:subagents|direct|2026-06-09]

## Extracted Claims

### Building blocks and progressive disclosure

- The Claude Code ecosystem in early 2026 converged on four building blocks — CLAUDE.md/AGENTS.md memory files, slash commands, agent skills, and subagents — assembled around one architectural principle, progressive disclosure. [prov:src-2026-04-16-claude-code-frameworks-report#sec:executive-summary|direct|2026-06-09] [epistemic:: sourced]
- Progressive disclosure originated as a Jakob Nielsen UX pattern (1995); Anthropic elevated it to the architectural backbone of Claude Code — for humans it improves learnability, for LLMs it is an architectural necessity given context rot, attention dilution, and cache economics. [prov:src-2026-04-16-claude-code-frameworks-report#sec:progressive-disclosure|direct|2026-06-09] [epistemic:: sourced]
- The progressive-disclosure load hierarchy runs: enterprise policy → ~/.claude/CLAUDE.md (always) → ./CLAUDE.md (always) → subdir CLAUDE.md (lazy on file access) → skill metadata (always, ~100 tokens each) → skill body (on trigger, <5K) → bundled references/scripts (on demand, unbounded) → subagent contexts (forked, compressed on return). [prov:src-2026-04-16-claude-code-frameworks-report#sec:progressive-disclosure|direct|2026-06-09] [epistemic:: sourced]
- A key documented anti-pattern is over-reliance on auto-activation: Vercel found skills were never invoked in 56% of test cases, and explicit "IMPORTANT: read X" pointers outperformed pure auto-discovery. [prov:src-2026-04-16-claude-code-frameworks-report#sec:progressive-disclosure|direct|2026-06-09] [epistemic:: tentative]

### Slash commands and the commands/skills merge

- Slash commands are markdown files at `.claude/commands/<name>.md` with optional YAML frontmatter (description, allowed-tools, argument-hint, model, disable-model-invocation), supporting `$ARGUMENTS`/`$1`/`$2` expansion, pre-prompt shell via `` !`cmd` ``, and `@path` file references. [prov:src-2026-04-16-claude-code-frameworks-report#sec:slash-commands|direct|2026-06-09] [epistemic:: tentative]
- As of v2.1.101 (April 11, 2026) commands and skills were merged: both `.claude/commands/deploy.md` and `.claude/skills/deploy/SKILL.md` create `/deploy`, with skills taking precedence on conflict; skills are now the recommended form (directories + richer frontmatter). [prov:src-2026-04-16-claude-code-frameworks-report#sec:slash-commands|direct|2026-06-09] [epistemic:: tentative]
- Security knob: set `disable-model-invocation: true` on side-effectful commands (`/commit`, `/deploy`) or the SlashCommand tool can auto-trigger them; allowlist tightly (`Bash(git diff:*)` not `Bash(*)` — CVE-2025-66032 was a wide-allowlist bypass). [prov:src-2026-04-16-claude-code-frameworks-report#sec:slash-commands|direct|2026-06-09] [epistemic:: tentative]

### Subagents

- Subagents (`.claude/agents/<name>.md`) are isolated Claude instances with their own context window, tool allowlist, and optionally model; the killer feature is that a research subagent can churn through 50 files / 100K tokens and return a ~500-token distilled summary while the parent context stays clean. [prov:src-2026-04-16-claude-code-frameworks-report#sec:subagents|direct|2026-06-09] [epistemic:: sourced]
- Subagent routing depends on the description; "Use PROACTIVELY" and "MUST BE USED" markedly increase auto-delegation — descriptions should be written as routing rules, not capability summaries. [prov:src-2026-04-16-claude-code-frameworks-report#sec:subagents|direct|2026-06-09] [epistemic:: sourced]
- Subagent best practices: single responsibility with self-contained prompts (subagents see no parent history), least-privilege tools per role (read-only auditors get Read/Grep/Glob; implementers add Write/Edit/Bash), explicit output schemas, and the Explore→Plan→Execute three-phase pipeline as the most reliable pattern. [prov:src-2026-04-16-claude-code-frameworks-report#sec:subagents|direct|2026-06-09] [epistemic:: sourced]
- Subagent pitfalls: agent sprawl dilutes routing, subagents are black boxes with no mid-stream interaction, over-parallelization wastes tokens, and rejected output cannot be iterated — the parent spawns a fresh copy with no internal state. [prov:src-2026-04-16-claude-code-frameworks-report#sec:subagents|direct|2026-06-09] [epistemic:: sourced]

### CLAUDE.md / AGENTS.md

- CLAUDE.md loads on every session and every turn; AGENTS.md is the cross-tool open standard (agents.md) used by 60,000+ repos and supported natively by Codex, Cursor, Aider, Jules, Windsurf, Zed, OpenCode — but Claude Code does not yet read AGENTS.md natively (issue #6235), so teams symlink CLAUDE.md → AGENTS.md. [prov:src-2026-04-16-claude-code-frameworks-report#sec:claude-md|direct|2026-06-09] [epistemic:: tentative]
- Length is the single most important CLAUDE.md variable — Anthropic's diagnostic: "If Claude keeps doing something despite a rule against it, the file is probably too long." Community ceiling <300 lines, ~60 lines as the gold standard (HumanLayer's production root file); the router pattern keeps CLAUDE.md a thin index pointing to deeper docs via `@path` imports. [prov:src-2026-04-16-claude-code-frameworks-report#sec:claude-md|direct|2026-06-09] [epistemic:: sourced]

### Superpowers

- Superpowers (obra/superpowers) by Jesse Vincent (creator of Request Tracker) released v1 Oct 9, 2025 (the day Anthropic shipped the plugin system); accepted into Anthropic's official marketplace Jan 15, 2026. Its thesis: stock agents skip steps and lie about success, so force a mandatory brainstorm→plan→implement→review progression. [prov:src-2026-04-16-claude-code-frameworks-report#sec:superpowers|direct|2026-06-09] [epistemic:: tentative]
- Superpowers architecture: ~14 composable skills (brainstorming, writing-plans, executing-plans, test-driven-development, systematic-debugging, verification-before-completion, requesting-code-review, using-git-worktrees, dispatching-parallel-agents, …) + 3 commands + 1 code-reviewer subagent + a SessionStart hook that re-injects priming after clear/compact. [prov:src-2026-04-16-claude-code-frameworks-report#sec:superpowers|direct|2026-06-09] [epistemic:: sourced]
- Superpowers' distinctive moves: "invoke a skill whenever there's even a 1% chance one applies"; hard-coded priority (user instructions → Superpowers skills → default); TDD enforcement ("if you didn't watch the test fail, you don't know if it tests the right thing"); skills constrain which skill runs next; code review in a fresh subagent context; git worktrees for parallel isolation; zero-dependency by design. [prov:src-2026-04-16-claude-code-frameworks-report#sec:superpowers|direct|2026-06-09] [epistemic:: sourced]

### GSD (Get-Shit-Done)

- GSD (gsd-build/get-shit-done) by TÂCHES, first commit Dec 2025, MIT-licensed; its thesis is that the dominant failure mode in long sessions is context rot (quality degrades past ~50% context fill), solved by running every task in a fresh 200K-token subagent context so Task 50 has the same quality budget as Task 1. [prov:src-2026-04-16-claude-code-frameworks-report#sec:gsd|direct|2026-06-09] [epistemic:: tentative]
- GSD architecture: 35+ specialized agents and 50+ slash commands orchestrated around a `.planning/` artifact tree on disk (PROJECT.md, REQUIREMENTS.md, ROADMAP.md, STATE.md; research/codebase/intel; phases/XX-name/ with CONTEXT/RESEARCH/PLAN/SUMMARY/VERIFICATION/VALIDATION; seeds/threads/todos/debug/workstreams). [prov:src-2026-04-16-claude-code-frameworks-report#sec:gsd|direct|2026-06-09] [epistemic:: sourced]
- GSD's distinctive moves: "plans are prompts, not documents" (PLAN.md executable by a fresh subagent); target ~50% context fill not 80%; atomic per-task commits with phase/plan IDs; wave-based parallelism with strict file-overlap rejection; goal-backward "Nyquist" verification mapping every requirement to an automated test command before code is written; per-agent model profiles (quality/balanced/budget/inherit); 11+ runtimes. [prov:src-2026-04-16-claude-code-frameworks-report#sec:gsd|direct|2026-06-09] [epistemic:: sourced]

### Spec Kit

- Spec Kit (github/spec-kit) is an official GitHub project led by Den Delimarsky (research lineage from John Lam), released Sep 2, 2025, MIT-licensed; its thesis is "specifications don't serve code — code serves specifications" — the spec is the primary version-controlled artifact and code is a regenerable expression. [prov:src-2026-04-16-claude-code-frameworks-report#sec:spec-kit|direct|2026-06-09] [epistemic:: tentative]
- Spec Kit ships a Python CLI named Specify (`uv tool install specify-cli`); `specify init --ai claude` scaffolds `.specify/` with `memory/constitution.md` (a 9-article project DNA), cross-platform scripts, spec/plan/tasks templates, and per-feature `specs/NNN-feature/{spec,plan,tasks}.md`. [prov:src-2026-04-16-claude-code-frameworks-report#sec:spec-kit|direct|2026-06-09] [epistemic:: sourced]
- Spec Kit's namespaced commands run constitution → specify → clarify (≤5 multiple-choice disambiguation questions) → plan → tasks → analyze (read-only quality gate, severities CRITICAL/HIGH/MEDIUM/LOW) → implement; it is tool-agnostic across 20+ agents with cross-agent handoff as a first-class concern, and its constitution articles are non-negotiable (Article III: TDD, tests seen to fail before implementation). [prov:src-2026-04-16-claude-code-frameworks-report#sec:spec-kit|direct|2026-06-09] [epistemic:: sourced]

### Comparison, themes, and composability

- On the comparative matrix, the three frameworks differ on primary constraint (Spec Kit: spec gate; Superpowers: TDD process discipline; GSD: context engineering), artifact location (`.specify/specs/` vs in-session skills+hooks vs `.planning/phases/`), context strategy (specs survive sessions vs SessionStart re-prime vs fresh 200K window per task), and parallelism (manual vs a dispatching skill vs wave-based with file-overlap rejection). [prov:src-2026-04-16-claude-code-frameworks-report#sec:comparative-matrix|direct|2026-06-09] [epistemic:: sourced]
- All three converge on: skills over monolithic prompts; externalizing state to disk; subagent isolation for review/research/parallel work; test-first verification as non-negotiable; and atomic, traceable commits tied to plan/task IDs. [prov:src-2026-04-16-claude-code-frameworks-report#sec:cross-cutting-themes|direct|2026-06-09] [epistemic:: sourced]
- The frameworks are increasingly stacked rather than chosen: Spec Kit for portable, reviewable spec artifacts; GSD for `.planning/` orchestration and fresh-context discipline; Superpowers for in-session execution rigor (TDD, code review) — the dev.to "skills stack" pattern formalizes the combination. [prov:src-2026-04-16-claude-code-frameworks-report#sec:cross-cutting-themes|direct|2026-06-09] [epistemic:: sourced]
- Decision guide: Superpowers alone for a solo developer shipping a focused feature; GSD for multi-day autonomous runs with many phases (and brownfield mapping via `/gsd-map-codebase`); Spec Kit for mixed-tool teams needing cross-agent specs or reviewable stakeholder artifacts; none (vanilla Claude Code) for throwaway single-file prototypes. [prov:src-2026-04-16-claude-code-frameworks-report#sec:decision-guide|direct|2026-06-09] [epistemic:: sourced]

## Notes

- **Source nature:** secondary synthesis of 8 parallel web-research investigations, authored April 2026 (file dated 2026-04-16). It aggregates primary sources (Anthropic engineering blog, platform docs, the framework repos, and third-party comparisons by Pulumi/Medium/dev.to) rather than being a primary source itself — hence `epistemic_status: mixed`.
- **Time-sensitivity:** GitHub star counts (Superpowers ~156K, Spec Kit ~50K, GSD ~35–48K), version numbers (Superpowers v5.0.7, GSD v1.36.0, Claude Code v2.1.101), and specific dates move quickly and are marked `[epistemic:: tentative]`. The structural claims (theses, architectures, workflow shapes, building-block roles) are `[epistemic:: sourced]`. The Superpowers ~156K-star figure is notably high and reported by a single secondary source — treat with particular caution.
- **Partial-broken features noted by the report:** subdirectory command namespacing (`/posts:new`) is "partially broken, treat as unreliable"; these caveats are preserved on the building-block claims.
- **No contradictions** detected against existing wiki pages: the report extends [[progressive-disclosure|Progressive Disclosure]], [[claude-code|Claude Code]], and [[agent-skills|Agent Skills]] (adding the cross-framework framing, anti-patterns, building-block detail, and the commands/skills merge) rather than challenging their existing primary-sourced claims. Where the report restates already-documented primary facts (the three-tier loading model, skill authoring rules), those are NOT re-extracted — the existing Anthropic-primary-sourced claims stand.
- **Authors not given entity pages:** Jesse Vincent, TÂCHES, Den Delimarsky, John Lam are surfaced in-body on the framework entities and here, but no author entity pages were created (same precedent as Clayton Farr — revisit if they recur as wiki figures).
- **Privacy:** `cloud_safe`. Public frameworks and public Claude Code features; no PII or proprietary content. Single-author repo, contributor field omitted per ingest §9a.

## Source Metadata

- **Type:** comparative report (synthesis of 8 parallel web-research investigations)
- **Authored:** April 2026 (file dated 2026-04-16)
- **Source file:** `sources/2026/2026-04/2026-04-16-claude-code-frameworks-report.md`
- **Content hash:** `sha256:f47a04313f42b98b4555a3d23ed1e8321c69ab7b7fc378d0c043402fe3e2ff6e`
- **Ingested:** 2026-06-09
- **Primary sources cited (selected):** Anthropic Engineering (Agent Skills; multi-agent research system), Claude Code platform docs (skills/slash-commands/sub-agents/best-practices), agents.md open standard, obra/superpowers + Jesse Vincent's launch post, gsd-build/get-shit-done + USER-GUIDE, github/spec-kit + spec-driven manifesto, Pulumi and Medium framework comparisons, dev.to skills-stack post.

## References

<!-- r<n> = positional index into "## Sources by Topic" of the raw source -->
<!-- raw source: sources/2026/2026-04/2026-04-16-claude-code-frameworks-report.md -->
<!-- positional numbering: sequential across topic groups (r1-r9 = Building blocks, r10-r15 = Frameworks) -->

- r1:: [Anthropic Engineering: Equipping agents for the real world with Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills) — accessed 2026-06-10 — status: registry
- r2:: [Skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) — accessed 2026-06-10 — status: registry
- r3:: [Slash commands docs](https://code.claude.com/docs/en/slash-commands) — accessed 2026-06-10 — status: registry
- r4:: [Subagents docs](https://code.claude.com/docs/en/sub-agents) — accessed 2026-06-10 — status: registry
- r5:: [Claude Code best practices (CLAUDE.md)](https://code.claude.com/docs/en/best-practices) — accessed 2026-06-10 — status: registry
- r6:: [agents.md open standard](https://agents.md/) — accessed 2026-06-10 — status: registry
- r7:: [How we built our multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system) — accessed 2026-06-10 — status: registry
- r8:: [Stop bloating your CLAUDE.md (alexop.dev)](https://alexop.dev/posts/stop-bloating-your-claude-md-progressive-disclosure-ai-coding-tools/) — accessed 2026-06-10 — status: registry
- r9:: [Writing a good CLAUDE.md (HumanLayer)](https://www.humanlayer.dev/blog/writing-a-good-claude-md) — accessed 2026-06-10 — status: registry
- r10:: [obra/superpowers](https://github.com/obra/superpowers) (also: https://blog.fsck.com/2025/10/09/superpowers/) — accessed 2026-06-10 — status: registry
- r11:: [gsd-build/get-shit-done](https://github.com/gsd-build/get-shit-done) (also: https://github.com/gsd-build/get-shit-done/blob/main/docs/USER-GUIDE.md) — accessed 2026-06-10 — status: registry
- r12:: [github/spec-kit](https://github.com/github/spec-kit) (also: https://github.com/github/spec-kit/blob/main/spec-driven.md) — accessed 2026-06-10 — status: registry
- r13:: [Pulumi: Superpowers, GSD, gstack comparison](https://www.pulumi.com/blog/claude-code-orchestration-frameworks/) — accessed 2026-06-10 — status: registry
- r14:: [Medium: Superpowers vs BMAD vs SpecKit vs GSD](https://medium.com/@richardhightower/the-great-framework-showdown-superpowers-vs-bmad-vs-speckit-vs-gsd-360983101c10) — accessed 2026-06-10 — status: registry
- r15:: [dev.to: Combining Superpowers + gstack + GSD](https://dev.to/imaginex/a-claude-code-skills-stack-how-to-combine-superpowers-gstack-and-gsd-without-the-chaos-44b3) — accessed 2026-06-10 — status: registry
