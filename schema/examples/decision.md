---
id: dr-2026-04-14-phase6-decision-type
title: "Introduce Decision Record Page Type"
type: decision
status: active
summary: "Decision records are a dedicated page type (type: decision) with their own template, directory (wiki/decisions/), and index category, rather than overloading the overview type."
created_at: 2026-04-14
updated_at: 2026-04-14
sources: []
epistemic_status: sourced
tags:
  - meta
  - schema
domains:
  - wiki-infrastructure
privacy: cloud_safe
knowledge_domain: software
trigger_type: schema-update
affected_pages: []
example: true
---

## TL;DR

Decision records get a dedicated `type: decision` page type with their own template, directory, and index category, replacing the prior convention of storing them as overview pages.

## Decision

Created `wiki/decisions/` as a first-class content directory, `schema/templates/decision.md` as the canonical template, and added `decision` to the `type` enum. Decision records use a fixed section ordering and introduce two type-specific frontmatter fields (`trigger_type`, `affected_pages`).

## Why

The previous reflect workflow stored decision records as overview pages in `wiki/overviews/`, conflating structural reasoning with topic synthesis. The framing adopted is "decision records as a first-class page type." The framing it replaced is "decision records overloaded onto the overview type."

(...remaining sections: Alternatives Considered, Consequences, Affected Pages, Sources.)
