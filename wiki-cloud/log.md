---
id: log
title: Log
type: overview
status: active
summary: "Append-only operations log."
created_at: 2026-04-15
updated_at: 2026-05-06
sources: []
epistemic_status: sourced
tags:
- meta
domains:
- wiki-infrastructure
knowledge_domain: software
neutrality_exempt: true  # Append-only activity log; a historical lint narration entry legitimately names a denylisted term and AGENTS.md §12 forbids rewriting log entries. Per-file exemption per the established neutrality_exempt precedent.
---

# Log

Append ingest entries here, newest at bottom, per AGENTS.md §12.

## [2026-04-16] reflect | progressive disclosure extraction

result: extracted §4 worked examples (6 files) to schema/examples/ and §16 appendices A, B to docs/reference/; DR dr-2026-04-16-progressive-disclosure-extraction records the framing shift.
reason: reduce spec context size while preserving "sole authoritative specification" framing via uniform `See:` pointers.

## [2026-04-20] reflect | Phase 11 brownfield apply-vs-advisory architecture + review-feedback hardenings

Structural reasoning captured in Tier-1 decision record [[dr-2026-04-20-brownfield-apply-vs-advisory|Brownfield Apply-vs-Advisory Architecture + Review-Manifest Pattern]] (`dr-2026-04-20-brownfield-apply-vs-advisory`). Documents the apply-class vs advisory-class split (D-01), review-manifest pattern for 01-page-typing (D-02, D-04), bootstrap_stage lifecycle gate via verify --promote (D-13, D-14, D-15), and review-feedback hardenings: root resolution (item 1), paired immutable inputs (item 2), shared walker (item 3), EOF-safe review-typing (item 4), top-level-bullets-only regex (item 5), aggregator per-plan gate split (item 6), widened D-03 auto-approve (item 7), hashlib portability (item 8), operational D-09 enforcement (item 9), per-script applied.log variance (item 10), override-label validation (item 11). Alternatives rejected (chain-runner, per-page prompts, scanner-driven privacy promotion, $(pwd) root default, decisions-only-without-candidates, shell sha256sum, decorative D-09 metadata, unified applied.log schema).

## [2026-04-30] lint | wiki health check

findings: 5 total (0 errors, 3 warnings, 2 info)
auto_fixes: 0 applied
report: wiki/maintenance/lint-report.md

## [2026-04-30] lint | wiki health check

findings: 5 total (0 errors, 3 warnings, 2 info)
auto_fixes: 0 applied
report: wiki/maintenance/lint-report.md

## [2026-05-01] lint | wiki health check

findings: 0 total (0 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki/maintenance/lint-report.md

## [2026-05-01] reflect | Phase 12 complementary-systems boundary

Created decision record [[dr-2026-05-01-complementary-systems-boundary|dr-2026-05-01-complementary-systems-boundary]] (`trigger_type: schema-update`, `affected_pages: []`) capturing that compendium owns durable, provenance-backed wiki memory and review support, while complementary systems own task execution, reminders, calendars, and transactional state. Created `docs/reference/three-layer-model.md` with the 3-layer model, capture/clarify/organize/review routing table, and anti-features section. Added README pointer under "What this is", `docs/reference/index.md` bullet, and the Decisions entry above. Supports BOUND-01, BOUND-02, BOUND-03; verification closes them in Plan 12-04 (`bin/requirements-sync.sh --strict --phase 12` exits 0). Unblocks the CLOSE-04 scope-leak gate for v1.1 closure.

## [2026-05-01] lint | wiki health check

findings: 0 total (0 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki/maintenance/lint-report.md

## [2026-05-01] lint | wiki health check

findings: 5 total (0 errors, 5 warnings, 0 info)
auto_fixes: 0 applied
report: wiki/maintenance/lint-report.md

## [2026-05-04] query | TA/FA capabilities of financial-AI repos (with delta ingestion of 6 investigation sources)

answer: mapped 6 repos along technical-analysis and fundamental-analysis dimensions via direct GitHub repository inspection — TradingAgents and OpenBB ship both TA and FA; Dexter and Anthropic Financial Services are FA-only; FinRL is TA-first with a partial fundamentals example; Financial-Models-Numerical-Methods is neither.
write_back: WRITE-BACK: corrections to wiki claims contradicted by ground truth + 6 new investigation sources ingested via append-then-synthesize per §10 Pass 3
delta_compiled: src-2026-05-04-openbb-investigation, src-2026-05-04-finrl-investigation, src-2026-05-04-tradingagents-investigation, src-2026-05-04-fmnm-investigation, src-2026-05-04-dexter-investigation, src-2026-05-04-anthropic-financial-services-investigation
pages_affected: openbb, dexter, finrl, tradingagents, anthropic-financial-services, financial-models-numerical-methods, financial-ai-repository-tradeoffs, financial-ai-repository-landscape, index
notes: superseded "financial reasoning must be built on top" claim on OpenBB (TA + FA endpoints ship natively); superseded "mostly instructions and configuration" weakness on Anthropic Financial Services (Python validators, Excel templates, populated SKILL.md prompts ship). Both stale-marked with supersession pointers; original claims preserved per provenance trail rule. Index synced with existing wiki content at the same time.

## [2026-05-04] lint | wiki health check

findings: 20 total (0 errors, 17 warnings, 3 info)
auto_fixes: 0 applied
report: wiki/maintenance/lint-report.md

## [2026-05-04] query | FinRL training data sources and training-from-scratch paradigm

answer: FinRL fetches data live at runtime from 14+ external market-data APIs via per-provider processors under finrl/meta/data_processors/; no bundled OHLCV. RL agents train from scratch with random initialization (no fine-tuning) on A2C/DDPG/PPO/TD3/SAC across three swappable backends (SB3, ElegantRL, RLlib). PPO.load only appears in inference scripts; shipped actor.pth files are demo outputs, not training inputs. Transfer/curriculum learning absent from standard pipeline.
write_back: WRITE-BACK: extended src-2026-05-04-finrl-investigation with sec:data-sources and sec:training-paradigm sections; updated finrl entity TL;DR + Key Facts + Detail
delta_compiled: src-2026-05-04-finrl-investigation (re-compiled after extension; content_hash updated to sha256:490c12bb...)
pages_affected: finrl, src-2026-05-04-finrl-investigation

## [2026-05-04] ingest | Hack — "Is this the only skill left?" (YouTube transcript)

source: src-2026-05-03-is-this-the-only-skill-left
classification: transcript (YouTube monologue, ~22 min)
result: created source summary plus 4 concept pages (systems-thinking, comprehension-debt, programming-as-theory-building, jagged-frontier) and 2 entity pages (peter-naur, hack-agentive-stack)
pages_affected: src-2026-05-03-is-this-the-only-skill-left, systems-thinking, comprehension-debt, programming-as-theory-building, jagged-frontier, peter-naur, hack-agentive-stack
reason: foundational ingest seeding the AI-assisted-development domain; argues systems thinking is the durable skill in AI-coding and grounds the frame in Naur 1985.
notes: validity assessment in source Notes section flags two unverified empirical claims — "Hosini and Liftinger" study (speaker hedges names) and the IBM/Salesforce/Indeed industry-trend numbers — as tentative. Naur 1985 reference is accurate; jagged-frontier attribution is partially correct (Dell'Acqua et al., 2023, HBS).

## [2026-05-04] ingest | Hack — "Three artifacts that changed how I build with AI" (YouTube transcript)

source: src-2026-05-04-three-artifacts-build-with-ai
classification: transcript (YouTube monologue, ~15 min); explicitly references the prior video as "the previous video"
result: created source summary, 1 overview page (domain-driven-design), 3 concept pages (ubiquitous-language, bounded-context, documented-contract), 1 entity page (eric-evans); UPDATE on systems-thinking (added DDD as operational successor + second source), comprehension-debt (added second source), hack-agentive-stack (added second source + Clark/editorial detail)
pages_affected: src-2026-05-04-three-artifacts-build-with-ai, domain-driven-design, ubiquitous-language, bounded-context, documented-contract, eric-evans, systems-thinking, comprehension-debt, hack-agentive-stack
reason: companion ingest to 2026-05-03 video; argues DDD reduced to three artifacts is the practical method for paying down comprehension debt in AI-assisted workflows.
notes: validity assessment in source Notes section flags Hack's three-artifact reduction as a deliberate pedagogical simplification of Evans' larger DDD vocabulary (aggregates, value objects, anti-corruption layers, context maps absent). Evans 2003 attribution is accurate. "Documented contracts" is closest to Evans' Context Map / Published Language but is non-canonical phrasing.

## [2026-05-04] lint | wiki health check

findings: 0 total (0 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki/maintenance/lint-report.md

## [2026-05-04] lint | wiki health check

findings: 28 total (0 errors, 25 warnings, 3 info)
auto_fixes: 0 applied
report: wiki/maintenance/lint-report.md

## [2026-05-04] query | FinRL hardware requirements for training

answer: Repository states no hardware requirements (Python ≥3.7 + macOS/Ubuntu/Windows 10 only); no GPU/CPU/RAM section, no Colab badge. Training runs CPU-only out of the box: SB3 path uses default device="auto" (CUDA if available, else CPU); ElegantRL path doesn't set gpu_id/learner_gpus in get_model; vectorization is single-process DummyVecEnv. Default hyperparameters modest (20k steps in examples; 1M in finrl/train.py defaults). Largest memory item is TD3's 1M-step replay buffer (~hundreds of MB). GPU recommended but not required — meaningfully helps only ElegantRL backend and long 1M-step SB3 runs.
write_back: WRITE-BACK: extended src-2026-05-04-finrl-investigation with sec:hardware-requirements; updated finrl entity Key Facts + Detail
delta_compiled: src-2026-05-04-finrl-investigation (re-compiled after extension; content_hash updated to sha256:bde68e63...)
pages_affected: finrl, src-2026-05-04-finrl-investigation

## [2026-05-04] lint | wiki health check

findings: 0 total (0 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki/maintenance/lint-report.md

## [2026-05-06] ingest | Anthropic Agent Skills — overview, quickstart, best-practices (3 platform docs)

sources: src-2026-05-06-anthropic-agent-skills-overview, src-2026-05-06-anthropic-agent-skills-quickstart, src-2026-05-06-anthropic-agent-skills-best-practices
classification: 3 articles (Anthropic platform documentation, captured 2026-05-06 from platform.claude.com/docs/en/agents-and-tools/agent-skills/)
result: created 3 source summaries; 1 overview page (agent-skills); 1 concept page (progressive-disclosure); 3 entity pages (anthropic, claude-code, claude-api); UPDATE on anthropic-financial-services (Related Pages cross-link to new entities/overview, updated_at bumped — no new claims since the docs don't say new things specifically about anthropics/financial-services-plugins).
write_back: WRITE-BACK — new sources establish the canonical model for Skills, the Skills-vs-prompts distinction, and the surface-specific runtime/sharing rules; not present in wiki before this ingest.
delta_compiled: src-2026-05-06-anthropic-agent-skills-overview, src-2026-05-06-anthropic-agent-skills-quickstart, src-2026-05-06-anthropic-agent-skills-best-practices (all flipped pending → compiled with compiled_against_hash + compiled_targets populated per §5 invariants).
pages_affected: agent-skills, progressive-disclosure, anthropic, claude-code, claude-api, anthropic-financial-services, src-2026-05-06-anthropic-agent-skills-overview, src-2026-05-06-anthropic-agent-skills-quickstart, src-2026-05-06-anthropic-agent-skills-best-practices, index
notes: foundational ingest seeding the AI-agents domain. All three sources are publicly fetched Anthropic platform docs → privacy: cloud_safe. Single-author repo, contributor field omitted per §11.1 step 9a. Adjacent existing entity [[anthropic-financial-services|Anthropic Financial Services]] (a Claude Code plugin marketplace) is now properly cross-linked to its umbrella concepts. The wiki page [[agent-skills|Agent Skills]] is structurally an overview because it synthesizes across three sources and ties together a sub-concept ([[progressive-disclosure|Progressive Disclosure]]) with three surface entities ([[anthropic|Anthropic]], [[claude-code|Claude Code]], [[claude-api|Claude API]]) — same pattern as [[domain-driven-design|Domain-Driven Design]]. No contradictions detected vs. prior wiki content.

## [2026-05-06] lint | wiki health check

findings: 33 total (0 errors, 29 warnings, 4 info)
auto_fixes: 0 applied
report: wiki/maintenance/lint-report.md

## [2026-05-06] lint | wiki health check

findings: 32 total (0 errors, 29 warnings, 3 info)
auto_fixes: 0 applied
report: wiki/maintenance/lint-report.md

## [2026-05-06] ingest | Anthropic claude-cookbooks Skills notebooks 01 + 03

sources: src-2026-05-06-anthropic-claude-cookbook-skills-introduction, src-2026-05-06-anthropic-claude-cookbook-skills-custom-development
classification: 2 articles (Jupyter notebook tutorials from github.com/anthropics/claude-cookbooks @ d28edf17, rendered to source.md from notebook.ipynb in bundle dirs alongside the original notebooks)
result: created 2 source summaries; UPDATEd 3 existing wiki pages via append-then-synthesize (§10 Pass 3): agent-skills, progressive-disclosure, claude-api. No new entity/concept pages — these notebooks operationalize existing wiki entities/concepts with concrete SDK code rather than introducing new abstractions.
write_back: WRITE-BACK — new sources add (a) the SDK invocation pattern (client.beta.messages.create + betas= parameter, anthropic>=0.71.0), (b) the custom-Skill lifecycle (skills.create + files_from_dir, versions.create/list/delete, display_title workspace-uniqueness), (c) the type:"custom" container discriminator and skill composition pattern, (d) the "all top-level .md files load at L2" refinement to the Progressive Disclosure model, (e) the "98% savings is initial-context-only" disambiguation, and (f) observed generation times (Excel/PPT ~1-2 min, PDF ~40-60s) and container-reuse via container.id.
delta_compiled: src-2026-05-06-anthropic-claude-cookbook-skills-introduction → [agent-skills, progressive-disclosure, claude-api]; src-2026-05-06-anthropic-claude-cookbook-skills-custom-development → [agent-skills, progressive-disclosure, claude-api]. Both flipped pending → compiled.
pages_affected: agent-skills, progressive-disclosure, claude-api, src-2026-05-06-anthropic-claude-cookbook-skills-introduction, src-2026-05-06-anthropic-claude-cookbook-skills-custom-development, index
notes: privacy: cloud_safe (public Anthropic cookbook). Source files stored as bundle dirs (sources/2026/2026-05/2026-05-06-<slug>/) containing both source.md (markdown rendering of cells) and notebook.ipynb (the original) — schema §2 bundle pattern, with content_hash computed against source.md per the established compilation-tracking semantics. Single-author repo, contributor field omitted per §11.1 step 9a. No contradictions vs. prior wiki content; the cookbook claims extend rather than supersede the platform-doc claims.

## [2026-05-06] lint | wiki health check

findings: 45 total (0 errors, 42 warnings, 3 info)
auto_fixes: 0 applied
report: wiki/maintenance/lint-report.md

## [2026-05-06] lint | wiki health check

findings: 45 total (0 errors, 42 warnings, 3 info)
auto_fixes: 0 applied
report: wiki/maintenance/lint-report.md

## [2026-05-06] lint | wiki health check

findings: 51 total (1 errors, 42 warnings, 8 info)
auto_fixes: 0 applied
report: wiki/maintenance/lint-report.md

## [2026-05-06] lint | wiki health check

findings: 49 total (0 errors, 42 warnings, 7 info)
auto_fixes: 0 applied
report: wiki/maintenance/lint-report.md

## [2026-05-06] ingest | The Ralph Playbook (Clayton Farr's how-to-ralph-wiggum)

source: src-2026-05-06-ralph-playbook
classification: 1 article (long-form playbook README from github.com/ghuntley/how-to-ralph-wiggum @ 88d488a, authored by Clayton Farr <contact@claytonfarr.com>, synthesizing Geoffrey Huntley's Ralph technique). Bundled with supporting files: AGENTS.md/IMPLEMENTATION_PLAN.md/PROMPT_build.md/PROMPT_plan.md/loop.sh templates plus references/sandbox-environments.md and figures.
result: created source summary at wiki/sources/src-2026-05-06-ralph-playbook.md. Created 1 new entity (geoffrey-huntley) and 2 new concepts (ralph-loop, backpressure) — Ralph and Huntley are net-new to the wiki. UPDATEd wiki/entities/claude-code.md via append-then-synthesize (§10 Pass 3) to add the canonical Ralph CLI invocation pattern (`claude -p --dangerously-skip-permissions --output-format=stream-json --model opus --verbose`) and the `--dangerously-skip-permissions` security caveat (sandbox is the only remaining boundary).
write_back: WRITE-BACK — new sources add (a) the Ralph autonomous-coding-loop pattern as a discoverable concept, (b) Geoffrey Huntley as the originating entity, (c) "backpressure" as a generalizable agentic-loop concept worth its own page (tests/typechecks/lints/builds + LLM-as-judge), (d) the canonical Claude Code autonomous-mode CLI flag set, and (e) the JTBD → topics-of-concern → specs cardinality and "one sentence without 'and'" topic-scope test as durable framing for downstream ingests.
delta_compiled: src-2026-05-06-ralph-playbook → [geoffrey-huntley, ralph-loop, backpressure, claude-code]. Compilation flipped pending → compiled with all 4 targets recorded.
pages_affected: src-2026-05-06-ralph-playbook, geoffrey-huntley, ralph-loop, backpressure, claude-code, index
notes: privacy: cloud_safe (public GitHub repo, no PII). Source bundle stored at sources/2026/2026-05/2026-05-06-ralph-playbook/ containing source.md (rendered from README.md, content_hash sha256:55980d42…), the prompt/loop/agents templates, and the references/ subdir; the redundant 138 KB index.html (rendered README) was excluded. Single-author repo, contributor field omitted per §11.1 step 9a. Clayton Farr is the playbook author but not yet a recurring wiki figure — surfaced in source Notes/Source Metadata, no entity page yet (revisit if future sources cite him). No contradictions vs prior wiki content; the playbook adds new framing rather than challenging existing claims. The lint flagged one contradiction-candidate on claude-code.md (Key Facts now draws from skills-overview + ralph-playbook) — reviewed and confirmed complementary, not contradictory.

## [2026-05-06] lint | wiki health check

findings: 56 total (1 errors, 48 warnings, 7 info)
auto_fixes: 0 applied
report: wiki/maintenance/lint-report.md

## [2026-05-06] lint | wiki health check

findings: 55 total (0 errors, 48 warnings, 7 info)
auto_fixes: 0 applied
report: wiki/maintenance/lint-report.md

## [2026-05-06] query | Ralph loop creator skill spec

answer: reviewed the Agent Skills cluster, Ralph cluster, adjacent AI-coding skills pages, and raw Ralph bundle templates to specify a custom skill that scaffolds Ralph loop artifacts without launching autonomous execution.
write_back: WRITE-BACK: trigger met -> CREATE ralph-loop-creator-skill as a reusable synthesis artifact.
delta_compiled: none; all relevant source summaries were already compiled.
pages_affected: ralph-loop-creator-skill, index, log
notes: The spec combines the Skill authoring/progressive-disclosure constraints with Ralph's files contract, backpressure model, sandbox warning, and systems-thinking/DDD context-preservation guidance. It treats the skill as a scaffold generator rather than an autonomous loop runner.

## [2026-05-06] lint | wiki health check

findings: 72 total (1 errors, 64 warnings, 7 info)
auto_fixes: 0 applied
report: wiki/maintenance/lint-report.md

## [2026-05-06] lint | wiki health check

findings: 56 total (1 errors, 48 warnings, 7 info)
auto_fixes: 0 applied
report: wiki/maintenance/lint-report.md

## [2026-05-06] lint | wiki health check

findings: 55 total (0 errors, 48 warnings, 7 info)
auto_fixes: 0 applied
report: wiki/maintenance/lint-report.md

## [2026-05-07] lint | wiki health check

findings: 55 total (0 errors, 48 warnings, 7 info)
auto_fixes: 0 applied
report: wiki/maintenance/lint-report.md

## [2026-06-01] query | How does progressive disclosure operate as a shared design principle across Anthropic Agent Skills and the Ralph autonomous-loop playbook?

answer: Both systems apply the same context-engineering discipline — keep the always-loaded layer minimal and defer detail to on-demand reads. Agent Skills express it as the L1/L2/L3 three-level model; the Ralph loop expresses it by keeping AGENTS.md concise (~60 lines, operational-only) with status/progress deferred to IMPLEMENTATION_PLAN.md, plus a budgeted ~5k-token up-front spec load matching the L2 budget.
write_back: WRITE-BACK: new connection between existing pages -> UPDATE progressive-disclosure
delta_compiled: none (both source summaries already compiled)
pages_affected: progressive-disclosure, log
notes: Cross-source synthesis cites >=2 distinct source_ids (src-2026-05-06-ralph-playbook AND src-2026-05-06-anthropic-agent-skills-overview). The connection is interpretive (inferred) — neither source references the other; appended as a new Detail subsection per append-then-synthesize (CLAUDE.md Section 10 Pass 3) and surfaced in TL;DR + a new Key Fact. Privacy: both sources cloud_safe -> target stays cloud_safe.

## [2026-06-01] lint | wiki health check

findings: 0 total (0 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki/maintenance/lint-report.md

## [2026-06-02] reflect | SC1 reframing decision record (examples/ isolable sub-graph)

Created decision record [[dr-2026-06-02-sc1-examples-isolable-subgraph|dr-2026-06-02-sc1-examples-isolable-subgraph]] (`trigger_type: reframing`, `affected_pages: []`) formalizing the Phase 13.1 SC1 renegotiation: "graph not contaminated by examples/" → "examples/ forms a visually isolable sub-graph." Forced by Obsidian's single Excluded-files mechanism, which governs both Dataview indexing and graph membership — the fixtures must stay indexed for the DEBT-01 render-count verification, so they necessarily appear in the graph; isolability (a disconnected component) is the deliverable bar. Registered under Decisions in wiki/index.md. Authored as part of the Phase 13.2 v1.1 closure gate (Plan 13.2-03).

## [2026-06-02] lint | wiki health check

findings: 0 total (0 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki/maintenance/lint-report.md

## [2026-06-02] lint | wiki health check

findings: 0 total (0 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki/maintenance/lint-report.md

## [2026-06-02] lint | wiki health check

findings: 13 total (0 errors, 8 warnings, 5 info)
auto_fixes: 0 applied
report: wiki/maintenance/lint-report.md

## [2026-06-02] lint | wiki health check

findings: 0 total (0 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki/maintenance/lint-report.md

## [2026-06-02] reflect | schema-update: Obsidian filename + alias resolution

UPDATE wiki/decisions/dr-2026-06-02-obsidian-filename-alias-resolution.md
source: n/a (internal schema decision)
result: authored schema-update DR; corrected AGENTS.md §8 + §5 (self-alias invariant); updated 12 schema templates; registered in wiki/index.md
reason: Obsidian resolves `[[X]]` by filename stem + aliases, not title; 31/49 pages were graph orphans due to missing self-aliases; convention now correct and enforced by linkres lint category (Plan 02)

## [2026-06-03] lint | wiki health check

findings: 1 total (1 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki/maintenance/lint-report.md

## [2026-06-03] lint | wiki health check

findings: 1 total (1 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki/maintenance/lint-report.md

## [2026-06-03] lint | wiki health check

findings: 0 total (0 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki/maintenance/lint-report.md

## [2026-06-03] lint | wiki health check

findings: 0 total (0 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki/maintenance/lint-report.md

## [2026-06-03] lint | wiki health check

findings: 0 total (0 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki/maintenance/lint-report.md

## [2026-06-03] lint | wiki health check

findings: 0 total (0 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki/maintenance/lint-report.md

## [2026-06-03] lint | wiki health check

findings: 339 total (339 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki/maintenance/lint-report.md

## [2026-06-03] lint | wiki health check

findings: 384 total (339 errors, 0 warnings, 45 info)
auto_fixes: 45 applied
report: wiki/maintenance/lint-report.md

## [2026-06-03] lint | wiki health check

findings: 1 total (1 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki/maintenance/lint-report.md

## [2026-06-03] lint | linkres: self-alias backfill + variant reconciliation

result: ran `--fix` over wiki/ (45 pages updated) + examples/ (8 lint-visible kahneman pages updated); hand-edited 10 dataview-fixture content pages (example:true, --fix-unreachable) to add literal self-aliases (LINK-09); 2 scaffolding files (README.md, log.md) exempt; manually reconciled `Ralph Playbook` link → `The Ralph Playbook` alias (call-site edit in progressive-disclosure.md, D-07); `Bounded Contexts` plural variant was already absent from wiki/
pages_affected: wiki/overviews/domain-driven-design.md, wiki/concepts/progressive-disclosure.md, all wiki pages backfilled with self-aliases, 8 lint-visible kahneman pages, 10 examples/dataview-fixtures/fixture-*.md
write_back: NO-WRITE-BACK (remediation operation, not a query synthesis)
delta_compiled: none

## [2026-06-03] reflect | Phase 14 schema-update DR

reflect recommended: schema-update — Phase 14 re-plan from corrected premise (piped links)
pages_affected: dr-2026-06-03-uniform-piped-links, dr-2026-06-02-obsidian-filename-alias-resolution

## [2026-06-03] lint | wiki health check

findings: 1 total (1 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki/maintenance/lint-report.md

## [2026-06-03] lint | wiki health check

findings: 1 total (1 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki/maintenance/lint-report.md

## [2026-06-03] lint | wiki health check

findings: 0 total (0 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki/maintenance/lint-report.md

## [2026-06-03] lint | wiki health check

findings: 0 total (0 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki/maintenance/lint-report.md

## [2026-06-03] lint | wiki health check

findings: 0 total (0 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki/maintenance/lint-report.md

## [2026-06-03] lint | wiki health check

findings: 462 total (417 errors, 0 warnings, 45 info)
auto_fixes: 45 applied
report: wiki/maintenance/lint-report.md

## [2026-06-03] lint | wiki health check

findings: 0 total (0 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki/maintenance/lint-report.md

## [2026-06-03] lint | wiki body-link rewrite to uniform piped form

pages_affected: all wiki/ + examples/ body links rewritten to `[[id|Title]]` form
result: 0 bare `[[Title]]` links remain; `bin/lint.sh --ci --category linkres` exits 0 over wiki/
reason: Phase 14 re-plan (LINK-07, LINK-08, LINK-09) — piped-link migration

## [2026-06-03] lint | wiki health check

findings: 0 total (0 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki/maintenance/lint-report.md

## [2026-06-04] reflect | privacy asymmetric two-dir

result: Authored dr-2026-06-04-privacy-asymmetric-two-dir (trigger_type: schema-update) recording the three weighed options and why asymmetric two-directory model won.
write_back: WRITE-BACK: structural schema change -> CREATE dr-2026-06-04-privacy-asymmetric-two-dir
pages_affected: dr-2026-06-04-privacy-asymmetric-two-dir, index

## [2026-06-04] lint | wiki-cloud health check

findings: 62 total (0 errors, 56 warnings, 6 info)
auto_fixes: 0 applied
report: wiki-cloud/maintenance/lint-report.md

## [2026-06-04] lint | wiki-cloud health check

findings: 0 total (0 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki-cloud/maintenance/lint-report.md

## [2026-06-04] lint | wiki-cloud health check

findings: 0 total (0 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki-cloud/maintenance/lint-report.md

## [2026-06-04] lint | wiki-cloud health check

findings: 0 total (0 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki-cloud/maintenance/lint-report.md

## [2026-06-04] lint | wiki-cloud health check

findings: 0 total (0 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki-cloud/maintenance/lint-report.md

## [2026-06-04] lint | wiki-cloud health check

findings: 0 total (0 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki-cloud/maintenance/lint-report.md

## [2026-06-04] lint | wiki-cloud health check

findings: 0 total (0 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki-cloud/maintenance/lint-report.md

## [2026-06-04] lint | wiki-cloud health check

findings: 62 total (0 errors, 56 warnings, 6 info)
auto_fixes: 0 applied
report: wiki-cloud/maintenance/lint-report.md

## [2026-06-05] lint | wiki-cloud health check

findings: 64 total (0 errors, 62 warnings, 2 info)
auto_fixes: 0 applied
report: wiki-cloud/maintenance/lint-report.md

## [2026-06-05] lint | wiki-cloud health check

findings: 0 total (0 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki-cloud/maintenance/lint-report.md

## [2026-06-04] schema | reference extraction (Phase 16 complete)

UPDATE index: added dr-2026-06-04-reference-extraction entry
UPDATE log: this entry
result: §4/§5/§6/§7/§8/§13/§14/§15/§16 extracted to schema/reference/*.md + schema/workflows/lint.md (seed) + docs/reference/scaling.md + docs/reference/tooling.md; AGENTS.md routing table added; D-09 framing applied; AGENTS.template.md mirrored
pages_affected: dr-2026-06-04-reference-extraction, index, log

## [2026-06-05] lint | wiki-cloud health check

findings: 63 total (18 errors, 45 warnings, 0 info)
auto_fixes: 0 applied
report: wiki-cloud/maintenance/lint-report.md

## [2026-06-05] lint | wiki-cloud health check

findings: 0 total (0 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki-cloud/maintenance/lint-report.md

## [2026-06-07] lint | wiki-cloud health check

findings: 21 total (12 errors, 9 warnings, 0 info)
auto_fixes: 0 applied
report: wiki-cloud/maintenance/lint-report.md

## [2026-06-07] lint | wiki-cloud health check

findings: 9 total (0 errors, 9 warnings, 0 info)
auto_fixes: 0 applied
report: wiki-cloud/maintenance/lint-report.md

## [2026-06-07] lint | wiki-cloud health check

findings: 0 total (0 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki-cloud/maintenance/lint-report.md

## [2026-06-07] lint | wiki-cloud health check

findings: 0 total (0 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki-cloud/maintenance/lint-report.md

## [2026-06-07] lint | wiki-cloud health check

findings: 0 total (0 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki-cloud/maintenance/lint-report.md

## [2026-06-07] reflect | workflow extraction (Phase 17)

Created dr-2026-06-05-workflow-extraction (trigger_type: schema-update) recording the §9–§12 → schema/workflows + log-format.md extraction, the solo-op commit-prefix (D-01), the abolish-§N routing guard (D-05), and the inclusion-audit tripwire (D-09..D-12). affected_pages: schema/workflows/operations.md, schema/workflows/pipeline.md, schema/workflows/ingest.md, schema/workflows/query.md, schema/workflows/reflect.md, schema/workflows/brownfield.md, schema/workflows/release.md, schema/workflows/audit.md, schema/reference/log-format.md.

## [2026-06-07] lint | wiki-cloud health check

findings: 0 total (0 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki-cloud/maintenance/lint-report.md

## [2026-06-08] reflect | skills overlay decision record

Created dr-2026-06-08-skills-overlay (trigger_type: schema-update) recording the Phase 18 Skills Overlay: four thin .claude/skills/{op}/SKILL.md pointer routers generated by bin/gen-skills.sh, the two-layer Source-of-Truth model (behavioral SOT = schema/workflows/{op}.md; artifact SOT = the generator template + description data), the --check regenerate-diff + structural-assertion drift gate (D-06/D-07), and the model-invocation-enabled choice (D-05). Registered in wiki-cloud/index.md Decisions section. affected_pages: [].

## [2026-06-08] lint | wiki-cloud health check

findings: 0 total (0 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki-cloud/maintenance/lint-report.md

## [2026-06-09] ingest | PDF-to-Text Extraction and LLM PDF Ingestion — State of the Art (2025–2026)

source: src-2026-06-09-pdf-to-text-llm-ingestion-sota
classification: article (synthesized deep-research report; secondary synthesis over 21 public web sources, 22/25 sampled claims survived 3-vote adversarial verification)
result: created source summary; 1 overview (pdf-text-extraction-for-llm-ingestion); 1 comparison (ocr-pipeline-vs-vlm-ingestion); 2 entities (olmocr, omnidocbench); 1 concept (vlm-ocr-hallucination). Net-new "document AI / PDF extraction" domain — no existing wiki pages overlapped, so no UPDATEs to prior pages.
write_back: WRITE-BACK — new sources establish the three-camp taxonomy (traditional OCR / pipeline tools / VLM-OCR), the extraction-vs-native-vision paradigm debate, OmniDocBench + olmOCR-Bench as accuracy references, the per-page cost picture across self-hosted and commercial tiers, the VLM hallucination failure mode, and a concrete Markdown-pipeline recommendation. None present in the wiki before this ingest.
delta_compiled: src-2026-06-09-pdf-to-text-llm-ingestion-sota → [pdf-text-extraction-for-llm-ingestion, ocr-pipeline-vs-vlm-ingestion, olmocr, omnidocbench, vlm-ocr-hallucination]. Flipped pending → compiled with compiled_against_hash + compiled_targets populated per frontmatter §Compilation Tracking invariants.
pages_affected: src-2026-06-09-pdf-to-text-llm-ingestion-sota, pdf-text-extraction-for-llm-ingestion, ocr-pipeline-vs-vlm-ingestion, olmocr, omnidocbench, vlm-ocr-hallucination, index
notes: privacy cloud_safe (public technology and public sources; no PII). Single-author repo, contributor field omitted per ingest §9a. Time-sensitivity is the dominant caveat — benchmark-leaderboard positions and per-page prices move monthly, so edit-distance numbers, the v1.5 leaderboard ordering, olmOCR-Bench scores, the human-eval ELO, and the price table are marked [epistemic:: tentative] (also reflecting first-party/aggregator sourcing), while the structural taxonomy, paradigm split, and hallucination failure mode are [epistemic:: sourced]. olmOCR-Bench and the olmOCR human eval are Ai2-authored (first-party). Three vendor/leaderboard accuracy claims were REFUTED in verification and excluded from findings — recorded in the source summary Notes and the raw source #sec:refuted for the provenance trail. MinerU and Marker referenced as red links (knowledge-gap pages not yet written). Gaps: Docling, LlamaParse, Reducto, Unstructured were in scope but no verified accuracy/cost claims survived — candidates for a follow-up query.

## [2026-06-09] lint | wiki-cloud health check

findings: 66 total (19 errors, 47 warnings, 0 info)
auto_fixes: 0 applied
report: wiki-cloud/maintenance/lint-report.md

## [2026-06-09] lint | wiki-cloud health check

findings: 65 total (18 errors, 47 warnings, 0 info)
auto_fixes: 0 applied
report: wiki-cloud/maintenance/lint-report.md

## [2026-06-09] lint | wiki-cloud health check

findings: 65 total (18 errors, 47 warnings, 0 info)
auto_fixes: 0 applied
report: wiki-cloud/maintenance/lint-report.md

## [2026-06-09] ingest | Claude Code Frameworks & Patterns: A Comparative Report

source: src-2026-04-16-claude-code-frameworks-report
classification: article (secondary synthesis of 8 parallel web-research investigations, authored April 2026 — file dated 2026-04-16; ingested 2026-06-09). Raw source stored verbatim at sources/2026/2026-04/2026-04-16-claude-code-frameworks-report.md (content_hash sha256:f47a0431…).
result: created source summary; 3 entities (spec-kit, superpowers, gsd); 1 comparison (claude-code-orchestration-frameworks); 2 concepts (spec-driven-development, subagents). UPDATEd 3 existing pages via append-then-synthesize (§Incremental Update Policy): progressive-disclosure (added Nielsen-1995 origin, the full Claude-Code load hierarchy, the auto-activation anti-pattern + Vercel 56% finding, frameworks-backbone framing), claude-code (added building blocks beyond Skills — slash commands + v2.1.101 commands/skills merge, subagents, CLAUDE.md length + router pattern, AGENTS.md non-native read #6235), agent-skills (added Oct-2025 launch / agentskills.io standard + frameworks-assemble-skills cross-link).
write_back: WRITE-BACK — net-new "Claude Code orchestration framework" cluster (Spec Kit, Superpowers, GSD), the spec-driven-development methodology, and subagents as a first-class building block; plus extension of the existing progressive-disclosure / claude-code / agent-skills cluster with cross-framework framing. None present in the wiki before this ingest.
delta_compiled: src-2026-04-16-claude-code-frameworks-report → [spec-kit, superpowers, gsd, claude-code-orchestration-frameworks, spec-driven-development, subagents, progressive-disclosure, claude-code, agent-skills]. Flipped pending → compiled.
pages_affected: src-2026-04-16-claude-code-frameworks-report, spec-kit, superpowers, gsd, claude-code-orchestration-frameworks, spec-driven-development, subagents, progressive-disclosure, claude-code, agent-skills, index
notes: privacy cloud_safe (public frameworks + public Claude Code features; no PII). Single-author repo, contributor field omitted per §9a. Source is a SECONDARY synthesis → epistemic_status mixed; structural claims (theses, architectures, workflow shapes, building-block roles) marked [epistemic:: sourced], while point-in-time figures (star counts, version numbers, dates, the commands/skills-merge specifics, the Vercel 56% finding) marked [epistemic:: tentative]. The Superpowers ~156K-star figure is unusually high and single-sourced — flagged tentative with explicit caution. Where the report restates already-documented Anthropic-primary facts (three-tier loading model, skill authoring rules) those were NOT re-extracted — existing primary-sourced claims stand; only net-new material was merged. No contradictions vs prior wiki content (the report extends rather than challenges). Authors (Jesse Vincent, TÂCHES, Den Delimarsky, John Lam) surfaced in-body but NOT given entity pages — same precedent as Clayton Farr; revisit if recurring. GSD described as the public open-source framework only (no reference to this repo's private .planning/).

## [2026-06-09] lint | wiki-cloud health check

findings: 78 total (24 errors, 54 warnings, 0 info)
auto_fixes: 0 applied
report: wiki-cloud/maintenance/lint-report.md

## [2026-06-09] lint | wiki-cloud health check

findings: 72 total (18 errors, 54 warnings, 0 info)
auto_fixes: 0 applied
report: wiki-cloud/maintenance/lint-report.md

## [2026-06-10] lint | wiki-cloud health check

findings: 73 total (0 errors, 69 warnings, 4 info)
auto_fixes: 0 applied
report: wiki-cloud/maintenance/lint-report.md

## [2026-06-10] lint | wiki-cloud health check

findings: 0 total (0 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki-cloud/maintenance/lint-report.md

## [2026-06-10] lint | wiki-cloud health check

findings: 0 total (0 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki-cloud/maintenance/lint-report.md

## [2026-06-10] lint | wiki-cloud health check

findings: 73 total (0 errors, 69 warnings, 4 info)
auto_fixes: 0 applied
report: wiki-cloud/maintenance/lint-report.md

## [2026-06-10] lint | wiki-cloud health check

findings: 0 total (0 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki-cloud/maintenance/lint-report.md

## [2026-06-10] UPDATE | PDF-to-Text Extraction and LLM PDF Ingestion: State of the Art (2025–2026)

source: src-2026-06-09-pdf-to-text-llm-ingestion-sota | result: source_type article → research-report; ## References block added (r1–r12) | reason: retro-classify as secondary source per Phase 19 research-report type (RPT-06)

## [2026-06-10] UPDATE | Claude Code Frameworks & Patterns: A Comparative Report

source: src-2026-04-16-claude-code-frameworks-report | result: source_type article → research-report; ## References block added (r1–r15) | reason: retro-classify as secondary source per Phase 19 research-report type (RPT-06)

## [2026-06-11] lint | wiki-cloud health check

findings: 73 total (0 errors, 69 warnings, 4 info)
auto_fixes: 0 applied
report: wiki-cloud/maintenance/lint-report.md

## [2026-06-11] lint | wiki-cloud health check

findings: 1 total (1 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki-cloud/maintenance/lint-report.md

## [2026-06-11] UPDATE | OCR Pipeline vs VLM Ingestion

source: src-2026-06-09-pdf-to-text-llm-ingestion-sota
result: rewrote 10 table-cell \|direct\| markers to \|derived\| (escaped-pipe blind spot from Plan 03 sweep; RPT-03 gap closure)
reason: table-cell markdown escapes pipes as \|; Plan 03 grep pattern targeted unescaped |direct| and missed these markers

## [2026-06-11] UPDATE | Claude Code Orchestration Frameworks

source: src-2026-04-16-claude-code-frameworks-report
result: rewrote 1 table-cell \|direct\| marker to \|derived\| (escaped-pipe blind spot from Plan 03 sweep; RPT-03 gap closure)
reason: same table-cell pipe-escaping blind spot as ocr-pipeline-vs-vlm-ingestion.md

## [2026-06-11] UPDATE | Source-Type Extension Contract + research-report Secondary Source Type

source: dr-2026-06-10-source-type-contract
result: corrected pre-sweep total count from 103 to 114 (103 prose + 11 table-cell); added gap-closure note to Claims sweep paragraph
reason: original count was produced by the same unescaped grep used in the sweep; actual total was 114

## [2026-06-11] lint | wiki-cloud health check

findings: 0 total (0 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki-cloud/maintenance/lint-report.md

## [2026-06-11] lint | wiki-cloud health check

findings: 77 total (0 errors, 69 warnings, 8 info)
auto_fixes: 0 applied
report: wiki-cloud/maintenance/lint-report.md

## [2026-06-11] UPDATE | Financial AI and Quant Finance Repository Comparison Report

source: src-2026-05-04-financial-ai-repo-comparison-report
result: source_type article → research-report; epistemic_status sourced → mixed; no ## References block (raw source has no bibliography — graceful degradation, #sec: locators only)
reason: post-Phase-19 code review (WR-07) found this LLM-authored synthesis matches the research-report classification rule but was missed by the RPT-06 retro-classification

## [2026-06-11] UPDATE | Financial AI downstream pages (8-page sweep)

source: src-2026-05-04-financial-ai-repo-comparison-report
result: swept 46 |direct| markers to |derived| across dexter, openbb, tradingagents, finrl, anthropic-financial-services, financial-models-numerical-methods, financial-ai-repository-tradeoffs, financial-ai-repository-landscape; re-graded 6 entity pages epistemic_status sourced → mixed (half their markers now derived)
reason: derived-never-direct mandate (D-08) applies once the source is classified research-report; sweep lands atomically with the classification flip to keep lint green

## [2026-06-11] UPDATE | Source-Type Extension Contract + research-report Secondary Source Type

source: dr-2026-06-10-source-type-contract
result: recorded the third-report retro-classification under RPT-06; updated D-08/D-09 descriptions to the hardened 1.9.1 behavior (self-citation-only exemption, non-derived flagged, empty source_type flagged); marked PDF/video sub-case verdicts provisional (finalized in Phases 20/21)
reason: code review found the DR overstated settled verdicts and described a D-08 exemption that did not match the implementation

## [2026-06-11] UPDATE | Claude Code (entity) + Claude Code Frameworks report locator fix

source: src-2026-04-16-claude-code-frameworks-report
result: corrected 5 unresolvable #sec: locators (3 on the entity page, 2 self-citations on the source summary) to match the raw heading slug
reason: audit derived-report tier could not resolve the authored slug against the raw source heading (dot-collapsing in slugify); locator now token-matches

## [2026-06-11] lint | wiki-cloud health check

findings: 0 total (0 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki-cloud/maintenance/lint-report.md

## [2026-06-12] ingest | A Multi-Agent System for Automating Scientific Discovery (Robin)

First real PDF acquired end-to-end via the Phase 20 pipeline (PDF-04). Acquired with bin/pdf-extract.sh (olmOCR-2 weights over Ollama, 36 pages → <!-- page: N --> markers), ingested with bin/ingest.sh --asset to co-locate the original PDF in the dated bundle dir.

CREATED:
- src-2026-06-12-multi-agent-scientific-discovery (source summary; source_type: paper; four extraction fields; #p|direct claims; born-digital sourced tier)
- robin-multi-agent-discovery-system (overview; Robin's three-agent lab-in-the-loop architecture + dAMD proof of concept)
- llm-agent-scientific-discovery (concept; the paradigm Robin instantiates)
- ai-for-drug-repurposing (concept; the application area Robin demonstrated)
UPDATED:
- index.md (catalog entries for the source + 2 concepts + overview)

Rationale: validates the PDF format-orthogonal sub-case convention in anger — the conditional lint extraction-field check now fires non-vacuously on a real original_asset=*.pdf source; #p page locators resolve against the acquisition's page markers. The Nature paper (Ghareeb et al., doi:10.1038/s41586-026-10652-y) classifies to its parent type `paper`, not a `pdf` source_type.

## [2026-06-12] lint | wiki-cloud health check

findings: 0 total (0 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki-cloud/maintenance/lint-report.md

## [2026-06-12] reflect | PDF sub-case schema decision

Created decision record [[dr-2026-06-11-pdf-ingestion|PDF as Format-Orthogonal Source Sub-Case + First Local-Model Acquisition Script]] (`trigger_type: schema-update`, `affected_pages: []`) capturing the five coupled Phase 20 decisions: PDF as a format-orthogonal acquisition sub-case rather than a new source_type (D-05); lazy-loaded authoritative pdf-ingestion.md + lean registry-row pointer (D-01/D-02); four flat extraction frontmatter fields under conditional lint enforcement, with extraction_date kept distinct from ingested_at (D-06/D-07); tiered VLM-hallucination epistemic policy with support_type staying direct (D-08/D-09); and bin/pdf-extract.sh as the first repo script to invoke a local model, establishing the per-script "no LLM calls" charter (D-10/D-11). Aids Phase 21 (video), which inherits the format-orthogonal pattern. Indexed under Decisions.

## [2026-06-12] lint | wiki-cloud health check

findings: 0 total (0 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki-cloud/maintenance/lint-report.md

## [2026-06-12] UPDATE | src-2026-06-12-multi-agent-scientific-discovery (+ robin-multi-agent-discovery-system, llm-agent-scientific-discovery, ai-for-drug-repurposing)

source: src-2026-06-12-multi-agent-scientific-discovery
result: refined claim epistemics across all four Robin pages per human verification — reframed efficiency/time-on-task numbers as author estimates (support_type direct→tentative on the ~200-fold and 872–937h claims), scoped the $10.76 cost (Finch excluded as negligible), added the 151→~400-paper two-stage nuance, reframed the ABCA1 dAMD link as the paper's mechanistic interpretation (epistemic inferred), softened ripasudil's "favorable" safety to relative-to-Y-27632, qualified KL001 novelty as "to the authors' knowledge", scoped the 44.5% hallucination figure to 15 Crow-ablated assay proposals, added the no-harness/no-data/no-code caveat to the BixBench Sonnet 3.7 baseline, scoped the Deep Research baseline (June 2025 ChatGPT, 17 unique candidates), and added preclinical/in-vitro framing throughout; bumped source + overview epistemic_status sourced→mixed. All #p locators preserved.
reason: human verification confirmed the claims are faithful AS reports of what the Nature accelerated-article-preview states, but not independently-validated or clinically-validated facts; epistemic framing tightened accordingly.

## [2026-06-14] ingest | FULL DISCUSSION: Google's Demis Hassabis, Anthropic's Dario Amodei Debate the World After AGI

First real YouTube video acquired end-to-end via the Phase 21 video pipeline (VID-04). Acquired locally with the tool-generic STT contract (a video downloader + a timestamped speech-to-text engine, D-04) into a single timestamped transcript; ingested with bin/ingest.sh as a SINGLE .md file (no bundle, no --asset — D-05). The video is multi-speaker (3 speakers), deliberately chosen to exercise the SPEAKER: labeling path (D-03). Raw diarization (SPEAKER_00/01/02) was mended at ingest to meaningful labels — HOST / HASSABIS / AMODEI / AUDIENCE — by attributing each segment from its content (D-03 permits mapping raw labels at ingest); a few question→answer segments the diarizer merged were split at their natural boundary.

CREATED:
- src-2026-06-14-hassabis-amodei-day-after-agi (source summary; source_type: transcript video sub-case; five video fields title/channel/publish_date/duration from yt-dlp + watch-page cross-check, VID-02; #t|direct claims; sourced tier with claim-level hedging on proper nouns/numbers, D-09)
- demis-hassabis (entity; Google DeepMind CEO, cautious-timeline position)
- dario-amodei (entity; Anthropic CEO, faster-timeline position + no-chips-to-adversaries policy)
- agi-timelines (concept; the central debate axis — Amodei faster vs Hassabis cautious, agree on direction)
- ai-self-improvement-loop (concept; the coding/AI-research loop whose closure rate sets the timeline)
UPDATED:
- anthropic (added Dario Amodei backlink in Related Pages)
- index.md (catalog entries for the source + 2 entities + 2 concepts)

Rationale: validates the video-as-sub-case-of-transcript convention in anger (VID-04) — the [H:MM:SS] SPEAKER: grammar (D-01) resolves under the existing audit TS_RE with zero resolver change; #t timestamp locators resolve against the committed transcript. yt-dlp metadata (title/channel/upload_date 20260120→ISO 2026-01-20/duration 1871s→31:11) was cross-checked against the YouTube watch page before authoring. A torchcodec dependency missing from the local STT venv blocked the diarization pass on first run and was installed (pinned to the torch-2.10-compatible build) before re-transcribing from the already-downloaded audio. The committed transcript is the durable record; the url is a courtesy pointer that may rot (D-06).

## [2026-06-14] lint | wiki-cloud health check

findings: 0 total (0 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki-cloud/maintenance/lint-report.md
scope: yaml category (the unscoped --ci crossref gate carries a pre-existing backlog out of this phase's scope; the ingest introduced no new crossref errors vs the pre-ingest baseline)

## [2026-06-14] reflect | video sub-case schema decision

Created decision record [[dr-2026-06-14-video-ingestion|Video as Sub-Case of Transcript + Tool-Generic Acquisition (No Repo Script)]] (`trigger_type: schema-update`, `affected_pages: []`) capturing the Phase 21 video-ingestion decisions: video as a sub-case of `transcript` rather than a new source_type, finalizing the provisional registry row (D-14); lazy-loaded authoritative video-ingestion.md + lean registry-row pointer (carried from Phase 20 D-01/D-02); and the four deliberate divergences from the PDF sub-case — a tool-generic acquisition contract with no repo script (D-04), a transcript-only single .md commit with no co-located asset (D-05), a plain link-rot stance with no drift machinery (D-06/VID-03), and convention-only extraction fields that are deliberately not lint-enforced (D-07); plus the tiered epistemic policy with claim-level hedging and support_type staying direct (D-09/D-10/D-11). Alternatives Considered maps the declined options (info-json/thumbnail bundle, archive_url/url_dead rot convention, lint-enforced extraction fields, a repo acquisition script, support_type derived). The personal STT tool is described generically (a timestamped STT engine) to keep this template-public DR neutral; only yt-dlp is named. Mirrors and is forward-referenced by the Phase 20 pdf-ingestion DR. Indexed under Decisions.

## [2026-06-14] lint | wiki-cloud health check

findings: 0 total (0 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki-cloud/maintenance/lint-report.md
scope: yaml category — the unscoped wiki-health total is 0 errors / 69 warnings / 9 info (a pre-existing contradiction/crossref/red-link backlog out of this phase's scope, including the new `google-deepmind` red link from demis-hassabis.md). This phase introduced no new errors and no new crossref errors vs the pre-ingest baseline.

## [2026-06-14] lint | wiki-cloud health check

findings: 78 total (0 errors, 69 warnings, 9 info)
auto_fixes: 0 applied
report: wiki-cloud/maintenance/lint-report.md

## [2026-06-17] ingest | Interpretable Context Methodology: Folder Structure as Agent Architecture

Ingested the ICM arXiv paper (Van Clief & McDermott, arXiv:2603.16021v2 [cs.AI], 18 Mar 2026; 21 pages). Born-digital PDF acquired via the PDF runbook's tool-agnostic generic contract (D-04): extracted with `pdftotext` (poppler 24.02.0) in a per-page loop that prepends `<!-- page: N -->` markers, NOT the olmOCR worked instance — for a born-digital paper the embedded text layer is authoritative, so a VLM-OCR pass would only add hallucination risk (and the plan-named `richardyoung/olmocr2` model is broken under current Ollama). Single-column reading order verified clean, no column interleaving. Scaffolded with `bin/ingest.sh --asset` (extracted markdown as source.md, original PDF co-located as 2603.16021v2.pdf). Born-digital → `sourced` default per the tiered epistemic policy; no spot-verification mandate.

CREATED:
- src-2026-06-17-interpretable-context-methodology (source summary; source_type: paper, PDF sub-case; four extraction_* fields with extraction_tool: pdftotext / extraction_model: poppler-24.02.0; #p|direct claims; epistemic_status mixed — architecture sourced, practitioner-experience claims tentative, efficacy unmeasured)
- interpretable-context-methodology (concept; filesystem-as-orchestrator method, five-layer context hierarchy, stage contracts, multi-pass-compilation analogy, scope boundaries)
- context-engineering (concept; the previously-missing hub — Karpathy coinage, Lance Martin write/select/compress/isolate, Willison, lost-in-the-middle, MCP distinction)
UPDATED:
- progressive-disclosure (added ICM as a third independent instance of the principle at folder granularity — Key Fact bullet + TL;DR clause + Related Pages links to ICM and context-engineering; added the ICM source to frontmatter + body Sources)
- index.md (catalog entries: 2 concepts + 1 source)

Rationale: ICM slots into the existing AI-agent-orchestration cluster (progressive-disclosure, subagents, the Claude Code orchestration frameworks). Its "layered context loading" is progressive disclosure applied at folder granularity, which motivated both the cross-reference UPDATE and the creation of the `context-engineering` concept page as the shared conceptual root (the term was already a tag on progressive-disclosure and subagents but had no page). Quantitative/practitioner claims (52-member community, the 30/33 U-shape, three no-coding users) are graded tentative because the paper itself flags them as self-reported and un-instrumented, and the central scoped-context-improves-quality claim is explicitly unmeasured (no controlled comparison). Second PDF-acquired source overall, and the first to use pdftotext rather than the olmOCR pipeline (exercising the D-04 tool-agnostic contract for born-digital input).

## [2026-07-03] ingest | open-gsd/gsd-core — GSD Core repository snapshot

First repository acquired end-to-end via the Phase 22 repository pipeline (REPO-06). Acquired with `bin/repo-snapshot.sh` (shallow clone → metadata harvest → README + Excerpts skeleton) into a snapshot bundle, then curated: badge shields and star-history embed trimmed (noted inline), five code excerpts added under `## Excerpts` with exact `path:Lnn-Lnn` headings so every `#path:` claim is offline-resolvable (D-04).

Discovery detour worth recording: the wiki's documented home for GSD (`gsd-build/get-shit-done`, from the April 2026 frameworks report) turned out to be an ARCHIVED redirect stub — the project renamed to `@opengsd/gsd-core` under the OpenGSD org. The live repository was snapshotted instead (commit `69fef7c0`, branch `next`), and the rename/lineage evidence is anchored to the snapshot's own CHANGELOG excerpt. A textbook external-drift case, live, one phase before the drift detector ships.

CREATED:
- src-2026-07-03-gsd-core-repo (source summary; source_type: repository — FIRST of its type; repo_url/commit_sha/default_branch required fields, license/primary_language recommended; #path:/#commit:/#sec: direct claims; epistemic split exercised — code/metadata claims sourced, README self-descriptions hedged claim-level tentative per D-08)
UPDATED:
- gsd (entity; rename/continuation claims with direct primary provenance; TL;DR re-synthesized; solo-author/version/repo-home point-in-time facts marked superseded-in-part with pointers to the new claims; decision_history backlink added)
- index.md (source catalog entry + refreshed gsd entity line)

Rationale: validates the repository source type in anger (REPO-06) — the extension contract's first PRIMARY new-type instance (D-01: locator, drift, acquisition change unconditionally; epistemics structurally). The `#path:` locators resolve against the Excerpts registry and `#commit:` against Snapshot Metadata via the new audit resolvers (22-02); the upgrade path from report-derived to repository-direct claims (Model C promotion story) is exercised on a real page.

## [2026-07-03] reflect | repository source type schema decision

Created decision record [[dr-2026-07-03-repository-source-type|Repository as a New Primary Source Type (#path/#commit Locators + Excerpt Registry)]] (`trigger_type: schema-update`, `affected_pages: [gsd, src-2026-07-03-gsd-core-repo]`) capturing the Phase 22 decisions: repository as a NEW primary `source_type` — the extension contract's first primary new-type instance and the inverse verdict of the pdf/video sub-case evaluations, reached by the same rule (D-01: locator, drift, acquisition change unconditionally; epistemics structurally); the minimal `#path:`/`#commit:` locator grammar with `#issue:`/`#pr:` deferred (D-02); the curated-snapshot-bundle-never-a-full-clone raw source whose `## Excerpts` registry makes `#path:` audit-resolvable offline (D-03/D-04); `#commit:` valid only for the snapshot's own commit (D-05); lint-required drift-anchor frontmatter repo_url/commit_sha/default_branch (D-06, LINT_VERSION 1.11.0); the within-source epistemic split with support_type staying direct (D-08); the fields-now-machinery-next drift stance (D-07); and mechanical-only acquisition glue (D-09). Alternatives Considered maps the declined options (article/data sub-case, full clone, clone-resolved #path, issue/pr locators now, video-style lint-optional fields). Consequences records the fence-aware `_resolve_path` fix found live on the first ingest. Indexed under Decisions.

## [2026-07-03] lint | wiki-cloud health check

findings: 86 total (0 errors, warnings/info only)
auto_fixes: 0 applied
report: wiki-cloud/maintenance/lint-report.md
scope: full run — 0 errors after the first repository ingest; the delta vs the pre-phase baseline (78) is the designed section-level contradiction-candidate flags on gsd.md (old report-derived vs new repository-direct project facts sharing sections — the supersession is annotated inline) plus crossref suggestions around the new source page. No new errors.

## [2026-07-03] UPDATE | src-2026-07-03-gsd-core-repo (+ gsd)

source: src-2026-07-03-gsd-core-repo | result: same-phase curation amendment from the Phase 22 code review — snapshot's embedded README H1 demoted to a comment (so `#sec:readme` resolves to the real preamble passage instead of a hollow 9-char heading), a tree-stats line added to `## Snapshot Metadata` (so the `#commit:`-anchored agent/command-count claims resolve to a passage that contains the counts), `content_hash`/`compiled_against_hash` recomputed on the source summary; on `gsd`, the report-derived "35+ agents / 50+ commands" bullet annotated counts-superseded (34/69 at the snapshot) and the "mechanics remain accurate" sentence scoped to core mechanics | reason: the review's adversarial pass proved two claim families audited as "resolved" while handing the verifier unusable passages (hollow `#sec:readme`; counts absent from the `#commit:` passage) — the wiki's own verify-the-verification-machinery lesson (v1.3 retrospective) applied to the phase that shipped hours earlier. Duplicate 2026-07-03 lint log entry (tool-appended alongside the hand-written one) also removed.

## [2026-07-03] reflect | external source drift schema decision

Created decision record [[dr-2026-07-03-external-source-drift|External Source Drift: Surface, Don't Mark (Opt-in --network Lint Checks)]] (`trigger_type: schema-update`, `affected_pages: []` — the checks are review-only by design) capturing the Phase 23 decisions: landing in the Phase-9-pre-plumbed `drift-external` lint subcategory behind an opt-in `--network` flag rather than a standalone script (D-01); three check families with fixed sub-error severities (D-02); the headline narrowing — the 999.5 backlog sketch's "mark affected source summaries stale" consciously reduced to SURFACE-ONLY, because upstream drift changes currency, not claim faithfulness against the immutable ingested snapshot (D-03); videos excluded per their settled link-rot stance (D-04); graceful tool degradation (D-05). Alternatives Considered maps the declined options (auto-stale, standalone drift-check script, content-hash diffing, default-path network). Indexed under Decisions.

## [2026-07-03] lint | first --network external drift run (drift-external)

findings: 2 new external findings (both info) + pre-existing local drift backlog; 0 errors
scope: --dry-run --network --category drift over wiki-cloud/ — the first live run of the Phase 23 checks
triage: repository source src-2026-07-03-gsd-core-repo verified CURRENT (upstream next HEAD 69fef7c0 == snapshot commit — true negative, independently confirmed via git ls-remote); two `source url moved` infos are benign redirect patterns (github.com repo-rename redirect on the financial-services plugins source; doi.org on the Robin paper source — DOI resolvers redirect by design); zero dead URLs; zero citation-registry rot (sampled registries all alive). No follow-up ops required. Known-noise candidate recorded in the DR: permanent redirectors (doi.org) will always emit a moved-info; skip-list is a future refinement if the noise grows.

## [2026-07-03] lint | wiki-cloud health check

findings: 92 total (0 errors, 83 warnings, 9 info)
auto_fixes: 0 applied
report: wiki-cloud/maintenance/lint-report.md

## [2026-07-04] reflect | bash-to-python migration decision

Created decision record [[dr-2026-07-04-python-migration|Bash-to-Python Migration: Shim-and-Swap Behind a Byte-Parity Oracle]] (`trigger_type: schema-update`) capturing the v1.5 re-platform: all sixteen in-scope `bin/` tools now run as a Python package behind self-bootstrapping `.sh` exec-shims with every CLI contract byte-preserved (behavior parity enforced by a 4-channel oracle against a held-fixed worktree); the frozen `compendium.common` core retires the lint/audit page-primitive byte-copy; the two-layer test strategy keeps the black-box suites as the parity instrument and grows module-level pytest per cluster; `migrate-privacy-dirs` retired, `install-hooks` stays bash; the release allowlist ships `src/` + `pyproject.toml` + `tests/lib` so template checkouts stay functional; SHIMOUT/LIBSWAP/pytest-conversion deferred. Known tool bugs ported faithfully, not fixed. Indexed under Decisions.

## [2026-07-03] lint | wiki-cloud health check

findings: 0 total (0 errors, 0 warnings, 0 info)
auto_fixes: 0 applied
report: wiki-cloud/maintenance/lint-report.md
