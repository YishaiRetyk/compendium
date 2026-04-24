# OpenBrain vs Compendium Critique Summary

Captured from the Nate/OpenBrain vs Karpathy wiki discussion and subsequent
roadmap review on 2026-04-24.

## Useful Critique

- Heavy-write ingest and cheap-read query is a chosen compendium tradeoff, not
  a defect to erase. Inverting that model becomes a different product.
- Relational queries, high-frequency event streams, Slack/ticket ingest, and
  operational task state are outside the compendium's core job.
- The durable design envelope is personal-to-small-team, curated, high-signal
  knowledge. Scaling tiers should remain deferred until real page counts demand
  them.
- The AI's first framing choice cannot be eliminated. The right defense is
  auditability: provenance, decision records, append-then-synthesize, and later
  claim-faithfulness audits.
- Sources remain the outside world's source of truth; the wiki is a compiled
  artifact regenerated from sources and provenance.

## Roadmap Consequences

- Add a complementary-systems boundary phase before v1.1 closes.
- Add a local write gate for zero-provenance new synthesized pages.
- Add a claim-faithfulness audit to check semantic support, not just marker
  syntax.
- Add a final closure gate after all new v1.1 phases, not before them.
- Keep external-source drift detection and GTD review patterns in backlog until
  usage justifies promotion.

## Explicit Non-Goals

- Do not add a SQL/query layer preemptively.
- Do not add task, reminder, calendar, inbox, waiting-for, Slack, ticket, or
  event-stream ownership inside the compendium.
- Do not ship canonical GTD dashboards or review templates before observing
  repeated real use.
- Do not treat multi-agent merge UX as a current blocker while git/PR discipline
  is sufficient.
