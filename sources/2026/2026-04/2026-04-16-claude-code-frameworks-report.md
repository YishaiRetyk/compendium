# Claude Code Frameworks & Patterns: A Comparative Report

*Synthesis of 8 parallel web-research investigations, April 2026.*

---

## Executive Summary

The Claude Code ecosystem in early 2026 has converged on a small set of building blocks — **CLAUDE.md/AGENTS.md memory files, slash commands, agent skills, and subagents** — assembled around one architectural principle: **progressive disclosure**. Three frameworks dominate the "opinionated assembly" layer: **Spec Kit** (GitHub, the spec gate), **Superpowers** (Jesse Vincent, the execution discipline), and **GSD** (TÂCHES, the context-engineered orchestrator). They occupy different points on the same axis and increasingly compose rather than compete: *gstack thinks, GSD stabilizes, Superpowers executes, Spec Kit specifies*.

---

## Part I — The Building Blocks

### 1. Agent Skills (`.claude/skills/<name>/SKILL.md`)

Anthropic's flagship abstraction since Oct 16, 2025; opened as a standard at [agentskills.io](https://agentskills.io) in Dec 2025. A skill is a folder containing `SKILL.md` plus optional bundled scripts and references.

**Three-tier loading model:**

| Tier | Loaded | Cost | Content |
|---|---|---|---|
| 1: Metadata | Always | ~100 tokens/skill | `name` + `description` |
| 2: SKILL.md body | When triggered | <5K tokens | Procedure |
| 3: Bundled assets | On demand via bash | Effectively unbounded | Refs, scripts, templates |

**Authoring rules that matter most:**
- Description in third person, with **WHAT and WHEN** ("Extract text from PDFs. Use when the user mentions PDFs, forms, or extraction.")
- SKILL.md body **<500 lines**; references one level deep only
- Forward slashes in paths; fully qualified MCP tool names
- Scripts execute in a VM — *code never enters the context window, only stdout does*

**Common pitfalls:** vague descriptions kill discovery; first-person voice breaks system-prompt injection; bloated bodies tax every turn; deeply nested references get partially read; cross-surface assumption (skills do NOT sync between claude.ai, API, and Claude Code).

### 2. Slash Commands (`.claude/commands/<name>.md`)

Markdown files with optional YAML frontmatter. **Major 2026 change (v2.1.101, April 11):** commands and skills have been *merged* — both `.claude/commands/deploy.md` and `.claude/skills/deploy/SKILL.md` create `/deploy`, with skills taking precedence on conflict. Skills are now the recommended form because they support directories and richer frontmatter.

**Key features:**
- `description`, `allowed-tools`, `argument-hint`, `model`, `disable-model-invocation` frontmatter
- `$ARGUMENTS`, `$1`, `$2` argument expansion
- `` !`bash command` `` for pre-prompt shell execution
- `@path/to/file` for inline file references
- Subdirectory namespacing (`.claude/commands/posts/new.md` → `/posts:new`) — *partially broken in current versions, treat as unreliable*

**Critical security knob:** set `disable-model-invocation: true` on side-effectful commands like `/commit`, `/deploy`. Without it, the SlashCommand tool can auto-trigger them. Always allowlist tightly: `Bash(git diff:*)` not `Bash(*)` (CVE-2025-66032 was a wide-allowlist bypass).

### 3. Subagents (`.claude/agents/<name>.md`)

Isolated Claude instances with their own context window, tool allowlist, and (optionally) model. **The killer feature:** a research subagent can churn through 50 files / 100K tokens, then return a 500-token distilled summary. The parent's context stays clean.

**Routing depends on the description.** Two patterns dramatically increase auto-delegation: **"Use PROACTIVELY"** and **"MUST BE USED"**. Write descriptions as routing rules, not capability summaries.

**Best practices:**
- Single responsibility, self-contained prompts (subagents see no parent history)
- Least-privilege tools per role: read-only auditors get `Read, Grep, Glob`; researchers add web tools; implementers add `Write, Edit, Bash`
- Define output schema explicitly — without it, agents return one-sentence verdicts
- The Explore → Plan → Execute three-phase pipeline is the most reliable pattern

**Pitfalls:** agent sprawl dilutes routing; subagents are black boxes with no mid-stream interaction; over-parallelization wastes tokens; rejected subagent output cannot be iterated — the parent spawns a fresh copy with no internal state.

### 4. CLAUDE.md & AGENTS.md

`CLAUDE.md` loads on every session, every turn. `AGENTS.md` is the cross-tool open standard ([agents.md](https://agents.md)) used by 60,000+ repos and supported natively by Codex, Cursor, Aider, Jules, Windsurf, Zed, OpenCode, etc. **Claude Code does not yet read AGENTS.md natively** ([issue #6235](https://github.com/anthropics/claude-code/issues/6235)) — production teams symlink `CLAUDE.md → AGENTS.md` as the workaround.

**Length is the single most important variable.** Anthropic's diagnostic: *"If Claude keeps doing something despite a rule against it, the file is probably too long."* Community ceiling: <300 lines, with ~60 lines as the gold standard (HumanLayer's production root file).

**The router pattern:** keep CLAUDE.md as a thin index pointing to deeper docs in `agent_docs/` or skill folders. Use `@path/to/file` imports for progressive disclosure. Move conventions a linter could enforce into hooks. Move workflows that aren't always relevant into skills.

### 5. Progressive Disclosure (the unifying principle)

Originally a Jakob Nielsen UX pattern (1995), Anthropic has elevated it to the architectural backbone of Claude Code. **For humans, it improves learnability; for LLMs, it is an architectural necessity** because of context rot, attention dilution, and cache economics.

**The hierarchy, top to bottom:**

```
Enterprise policy
~/.claude/CLAUDE.md            (always loaded)
./CLAUDE.md                    (always loaded)
subdir CLAUDE.md               (lazy on file access)
Skill metadata                 (always — ~100 tokens each)
Skill body                     (on trigger — <5K tokens)
Bundled references / scripts   (on demand — unbounded)
Subagent contexts              (forked, compressed on return)
```

**Patterns:** lazy loading, just-in-time references, summary-first/detail-on-demand, index-then-fetch, script-as-tool (only stdout enters context), subagent fan-out / compress-on-return.

**Anti-patterns:** bloated CLAUDE.md, monolithic mega-prompts, eager `Read all of docs/`, over-reliance on auto-activation (Vercel found skills were never invoked in 56% of test cases — explicit `IMPORTANT: read X` pointers outperformed pure auto-discovery), accepting context rot rather than externalizing state.

---

## Part II — The Frameworks

### Superpowers (obra/superpowers)

**Author:** Jesse Vincent (Prime Radiant; creator of Request Tracker). Released v1 on Oct 9, 2025 — same day Anthropic shipped the plugin system. Now v5.0.7 (Mar 2026), ~156K stars, accepted into Anthropic's official marketplace Jan 15, 2026.

**Thesis:** stock agents skip steps and lie about success. Force a mandatory **brainstorm → plan → implement → review** progression by hard-wiring it into 14 composable skills.

**Architecture:** ~14 skills (`brainstorming`, `writing-plans`, `executing-plans`, `test-driven-development`, `systematic-debugging`, `verification-before-completion`, `requesting-code-review`, `using-git-worktrees`, `dispatching-parallel-agents`, etc.) + 3 commands (`/brainstorm`, `/write-plan`, `/execute-plan`) + 1 subagent (`code-reviewer`) + a **SessionStart hook** that re-injects priming after `clear`/`compact`.

**Distinctive moves:**
- "Invoke a skill whenever there's even a 1% chance one applies — not negotiable"
- Hard-coded priority: user instructions → Superpowers skills → default behavior
- TDD enforcement: *"If you didn't watch the test fail, you don't know if it tests the right thing"*
- Skills constrain which skill may run next (brainstorming → writing-plans only)
- Code review in a fresh subagent context to avoid contamination
- Git worktrees for parallel-agent isolation
- 94% PR rejection rate advertised to deter low-effort agent contributions
- Zero-dependency by design

**Strength:** disciplined execution. **Weakness:** token-heavy, can be redundant for trivial tasks. Simon Willison: *"like riding your bike in a higher gear — faster but more effort."*

### GSD / Get-Shit-Done (gsd-build/get-shit-done)

**Author:** TÂCHES (solo dev). First commit Dec 2025; v1.36.0 (Apr 14, 2026) with ~1,693 commits, ~35–48K stars. MIT-licensed. v2 rewrite (`gsd-2`) underway as a standalone CLI on the Pi SDK for direct harness control.

**Thesis:** the dominant failure mode in long sessions is **context rot** — quality degrades past ~50% context fill. Solution: every task runs in a *fresh* 200K-token subagent context. Task 50 has the same quality budget as Task 1.

**Architecture:** 35+ specialized agents, ~50+ slash commands, all orchestrated around a `.planning/` artifact tree on disk:

```
.planning/
  PROJECT.md, REQUIREMENTS.md, ROADMAP.md, STATE.md
  research/, codebase/, intel/         # queryable codebase intelligence
  phases/XX-name/
    CONTEXT.md, RESEARCH.md
    XX-YY-PLAN.md, XX-YY-SUMMARY.md   # atomic plans (2–3 tasks each)
    VERIFICATION.md, VALIDATION.md
  seeds/, threads/, todos/, debug/, workstreams/
```

**Phase workflow:** `/gsd-discuss-phase` → `/gsd-ui-phase` or `/gsd-ai-integration-phase` (optional) → `/gsd-plan-phase` → `/gsd-execute-phase` → `/gsd-code-review` → `/gsd-verify-work` → `/gsd-ship`.

**Distinctive moves:**
- **"Plans are prompts, not documents"** — PLAN.md is written to be executable by a fresh subagent
- Target ~50% context fill, not 80%
- Atomic per-task git commits with phase/plan IDs
- Wave-based parallelism with strict file-overlap rejection
- Goal-backward "Nyquist" verification: every requirement mapped to an automated test command *before code is written*; plan-checker rejects plans without verify commands
- AI Integration phase (v1.35) includes a scored framework-selection matrix (LangGraph vs Mastra vs raw SDK), eval-strategy planning, and retroactive `EVAL-REVIEW.md` scoring
- Model profiles per-agent: `quality` / `balanced` (default) / `budget` / `inherit`
- 11+ runtimes supported (Claude Code, OpenCode, Gemini CLI, Cursor, Copilot, Windsurf, Antigravity, etc.)

**Strength:** keeps agents on-track for hours of autonomous work; resumable across sessions and machines. **Weakness:** rigid atomicity feels over-structured for small tasks.

### Spec Kit (github/spec-kit)

**Author:** Official GitHub project, led by Den Delimarsky with research lineage from John Lam. Released Sep 2, 2025; ~50K stars within months.

**Thesis:** *"Specifications don't serve code — code serves specifications."* The spec is the primary, version-controlled artifact; code is a regenerable expression. SDD inverts the traditional source of truth.

**Architecture:** Python CLI named **Specify** (installed via `uv tool install specify-cli`). `specify init my-project --ai claude` scaffolds:

```
.specify/
  memory/constitution.md       # 9-article project DNA
  scripts/{bash,powershell}/   # Cross-platform parity
  templates/{spec,plan,tasks}-template.md
  specs/001-feature/
    spec.md, plan.md, tasks.md
.<agent>/                      # .claude/, .github/, .cursor/...
```

**Commands** (namespaced `/speckit.*`): `constitution` → `specify` → `clarify` (≤5 multiple-choice questions to disambiguate) → `plan` → `tasks` → `analyze` (read-only quality gate, severities CRITICAL/HIGH/MEDIUM/LOW) → `implement`.

**Distinctive moves:**
- **Tool-agnostic by design** — works with 20+ agents (Claude, Copilot, Cursor, Gemini, Codex, Windsurf, Qwen, Junie, etc.); switch agents mid-project without changing the spec
- **Constitution articles** are non-negotiable: TDD mandatory (Article III: tests must be written, approved, and *seen to fail* before implementation), simplicity (≤3 projects initially), real DBs over mocks
- **Templates as constraints** — they force `[NEEDS CLARIFICATION]` markers, structure thinking via checklists, enforce constitutional compliance at phase gates
- `/speckit.analyze` is read-only — never mutates files, only flags issues
- Markdown specs are git-diffable, reviewable, no proprietary format

**Strength:** portability and version-controlled spec artifacts; the only one of the three with cross-agent handoff as a first-class concern. **Weakness:** "sea of markdown," long runtimes, manual spec↔code reconciliation, maintenance pace concerns ([Discussion #1482](https://github.com/github/spec-kit/discussions/1482)).

---

## Part III — Comparative Matrix

| Axis | **Spec Kit** | **Superpowers** | **GSD** |
|---|---|---|---|
| **Origin** | GitHub (official), Sep 2025 | Jesse Vincent (obra), Oct 2025 | TÂCHES, Dec 2025 |
| **Primary constraint** | The spec gate | Process discipline (TDD) | Context engineering |
| **Mental model** | Specs are truth; code is regenerable | Brainstorm → plan → TDD → review, mandatory | Fresh subagent contexts; atomic plans on disk |
| **Workflow shape** | constitution → specify → clarify → plan → tasks → analyze → implement | brainstorm → write-plan → execute-plan + 14 skills | discuss → (ui/ai) → plan → execute → review → verify → ship |
| **Artifact location** | `.specify/specs/<feature>/` | In-session (skills + hooks) | `.planning/phases/<phase>/` |
| **Context strategy** | Specs survive sessions; agent-agnostic | SessionStart hook re-primes after compact | Every task in a fresh 200K window |
| **Parallelism** | Manual (per task list) | `dispatching-parallel-agents` skill | Wave-based with file-overlap rejection |
| **Verification** | `/speckit.analyze` read-only quality gate | `verification-before-completion` skill + code-reviewer subagent | Nyquist: requirement→test mapped before code |
| **Multi-agent support** | 20+ runtimes (first-class) | Claude Code primary; Cursor/Codex/Copilot/Gemini variants | 11+ runtimes |
| **Distribution** | `uvx specify-cli` | Plugin (Anthropic marketplace + obra/superpowers-marketplace) | `npx get-shit-done-cc` + plugin variant |
| **Stars (~Apr 2026)** | ~50K | ~156K | ~35–48K |
| **License** | MIT | MIT | MIT |
| **Sweet spot** | Multi-agent teams; long-lived projects with reviewable specs | Disciplined feature shipping with tests | Long autonomous runs across many phases |
| **Weakness** | Verbose; manual spec/code sync | Token-heavy; rigid for small tasks | Over-structured for small work |

---

## Part IV — Cross-Cutting Themes

### Where they agree

1. **Skills > prompts.** All three converge on skill-style packaging (file-based, model-discoverable, composable) over monolithic system prompts.
2. **Externalize state to disk.** All three write structured artifacts (specs, plans, summaries) that survive context compaction and session restarts.
3. **Subagent isolation matters.** Code review, research, and parallel execution all happen in forked contexts — a direct application of progressive disclosure across agents.
4. **TDD or test-first verification is non-negotiable.** Superpowers enforces it via skill, Spec Kit via constitutional Article III, GSD via Nyquist plan-checker rejection.
5. **Atomic, traceable commits.** Every framework wants small commits tied to plan/task identifiers.

### Where they diverge

- **Where the spec lives.** Spec Kit: `specs/<feature>/`. Superpowers: ephemeral in skill execution. GSD: `.planning/phases/<phase>/PLAN.md`.
- **Who owns parallelism.** Spec Kit punts to the agent. Superpowers has an explicit skill. GSD orchestrates waves with file-conflict resolution.
- **Auto-invocation vs explicit triggering.** Superpowers' "1% chance" rule is the most aggressive. GSD favors explicit `/gsd-*` commands. Spec Kit splits the difference with namespaced `/speckit.*` calls.
- **Portability ambition.** Spec Kit was designed to outlive any single agent. Superpowers and GSD are pragmatically multi-runtime but Claude-Code-first.

### Composability

The frameworks are increasingly **stacked rather than chosen**: use Spec Kit for the constitution and spec artifacts (portable, reviewable), GSD for the `.planning/` orchestration and fresh-context discipline, Superpowers for the in-session execution rigor (TDD, code review). The dev.to "skills stack" pattern formalizes this combination.

---

## Part V — Decision Guide

| Situation | Recommended approach |
|---|---|
| Solo developer shipping a focused feature in Claude Code | **Superpowers** alone — least overhead, strongest discipline |
| Multi-day autonomous runs with many phases | **GSD** — context isolation is the killer feature |
| Mixed-tool team (Copilot + Claude + Cursor) | **Spec Kit** — only one with cross-agent specs |
| Throwaway prototype, single file | None of these — vanilla Claude Code is fine |
| Brownfield codebase, need to map first | GSD's `/gsd-map-codebase` + `/gsd-intel` is uniquely strong |
| Need reviewable artifacts for stakeholders | Spec Kit's markdown specs in git |
| Frequent context compactions hurting quality | GSD (fresh contexts) or Superpowers (SessionStart hook) |
| Building your own skill/command library | Start from Anthropic's `anthropics/skills` repo + `plugin-dev` skill |

---

## Sources by Topic

**Building blocks:**
- [Anthropic Engineering: Equipping agents for the real world with Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)
- [Skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
- [Slash commands docs](https://code.claude.com/docs/en/slash-commands)
- [Subagents docs](https://code.claude.com/docs/en/sub-agents)
- [Claude Code best practices (CLAUDE.md)](https://code.claude.com/docs/en/best-practices)
- [agents.md open standard](https://agents.md/)
- [How we built our multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system)
- [Stop bloating your CLAUDE.md (alexop.dev)](https://alexop.dev/posts/stop-bloating-your-claude-md-progressive-disclosure-ai-coding-tools/)
- [Writing a good CLAUDE.md (HumanLayer)](https://www.humanlayer.dev/blog/writing-a-good-claude-md)

**Frameworks:**
- [obra/superpowers](https://github.com/obra/superpowers) and [Jesse Vincent's launch post](https://blog.fsck.com/2025/10/09/superpowers/)
- [gsd-build/get-shit-done](https://github.com/gsd-build/get-shit-done) and [USER-GUIDE.md](https://github.com/gsd-build/get-shit-done/blob/main/docs/USER-GUIDE.md)
- [github/spec-kit](https://github.com/github/spec-kit) and [spec-driven.md manifesto](https://github.com/github/spec-kit/blob/main/spec-driven.md)
- [Pulumi: Superpowers, GSD, gstack comparison](https://www.pulumi.com/blog/claude-code-orchestration-frameworks/)
- [Medium: Superpowers vs BMAD vs SpecKit vs GSD](https://medium.com/@richardhightower/the-great-framework-showdown-superpowers-vs-bmad-vs-speckit-vs-gsd-360983101c10)
- [dev.to: Combining Superpowers + gstack + GSD](https://dev.to/imaginex/a-claude-code-skills-stack-how-to-combine-superpowers-gstack-and-gsd-without-the-chaos-44b3)
