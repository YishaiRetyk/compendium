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
privacy: cloud_safe
knowledge_domain: software
---

# Log

Append ingest entries here, newest at bottom, per AGENTS.md §12.

## [2026-04-16] reflect | progressive disclosure extraction

result: extracted §4 worked examples (6 files) to schema/examples/ and §16 appendices A, B to docs/reference/; DR dr-2026-04-16-progressive-disclosure-extraction records the framing shift.
reason: reduce spec context size while preserving "sole authoritative specification" framing via uniform `See:` pointers.

## [2026-04-20] reflect | Phase 11 brownfield apply-vs-advisory architecture + review-feedback hardenings

Structural reasoning captured in Tier-1 decision record [[Brownfield Apply-vs-Advisory Architecture + Review-Manifest Pattern]] (`dr-2026-04-20-brownfield-apply-vs-advisory`). Documents the apply-class vs advisory-class split (D-01), review-manifest pattern for 01-page-typing (D-02, D-04), bootstrap_stage lifecycle gate via verify --promote (D-13, D-14, D-15), and review-feedback hardenings: root resolution (item 1), paired immutable inputs (item 2), shared walker (item 3), EOF-safe review-typing (item 4), top-level-bullets-only regex (item 5), aggregator per-plan gate split (item 6), widened D-03 auto-approve (item 7), hashlib portability (item 8), operational D-09 enforcement (item 9), per-script applied.log variance (item 10), override-label validation (item 11). Alternatives rejected (chain-runner, per-page prompts, scanner-driven privacy promotion, $(pwd) root default, decisions-only-without-candidates, shell sha256sum, decorative D-09 metadata, unified applied.log schema).

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

Created decision record [[dr-2026-05-01-complementary-systems-boundary]] (`trigger_type: schema-update`, `affected_pages: []`) capturing that compendium owns durable, provenance-backed wiki memory and review support, while complementary systems own task execution, reminders, calendars, and transactional state. Created `docs/reference/three-layer-model.md` with the 3-layer model, capture/clarify/organize/review routing table, and anti-features section. Added README pointer under "What this is", `docs/reference/index.md` bullet, and the Decisions entry above. Supports BOUND-01, BOUND-02, BOUND-03; verification closes them in Plan 12-04 (`bin/requirements-sync.sh --strict --phase 12` exits 0). Unblocks the CLOSE-04 scope-leak gate for v1.1 closure.

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
notes: foundational ingest seeding the AI-agents domain. All three sources are publicly fetched Anthropic platform docs → privacy: cloud_safe. Single-author repo, contributor field omitted per §11.1 step 9a. Adjacent existing entity [[Anthropic Financial Services]] (a Claude Code plugin marketplace) is now properly cross-linked to its umbrella concepts. The wiki page [[Agent Skills]] is structurally an overview because it synthesizes across three sources and ties together a sub-concept ([[Progressive Disclosure]]) with three surface entities ([[Anthropic]], [[Claude Code]], [[Claude API]]) — same pattern as [[Domain-Driven Design]]. No contradictions detected vs. prior wiki content.

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
