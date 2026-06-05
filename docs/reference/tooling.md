# Tooling and Integrations

> Informational reference for tools the wiki is designed to work with. Not normative — the wiki functions as plain markdown files in a git repo regardless of tooling.

> This section is informational, not normative. It describes tools the wiki is designed to work with, but does not mandate their installation. The wiki functions as plain markdown files in a git repo regardless of tooling.

### Obsidian (Primary Human Interface)

- **Graph View:** Visualize the wiki's link structure. All intra-wiki links use piped form `[[id|Title]]` — the `id` target resolves reliably in Obsidian (filename/path only), and the `title` displays in reading view.
- **Dataview plugin:** Query frontmatter fields with TABLE/LIST/TASK syntax. All frontmatter fields defined in Section 5 are queryable. Example: `TABLE summary, epistemic_status FROM "wiki-cloud/entities" WHERE status = "active"`.
- **Properties:** Obsidian 1.4+ supports typed frontmatter editing. All base fields render as editable properties in the sidebar.
- **Aliases:** The `aliases` frontmatter field is OPTIONAL — useful for Quick Switcher / autocomplete and as display text in piped links `[[file|Alias]]`, but NOT used for bare `[[X]]` resolution (filename/path only).
- **Backlinks:** Obsidian's backlinks panel shows all pages that link to the current page, complementing the `## Related Pages` section.

### Git (Version Control)

- All changes are tracked in git with conventional commits (Section 3).
- History provides a full audit trail of wiki evolution.
- Branching is available for experimental restructuring (e.g., major domain reorganization).
- The activity log (`wiki-cloud/log.md`) complements git history with human-readable operation summaries.

### Optional Future Tools (Not Required for v1)

- **Local search engine** (e.g., qmd or similar): Hybrid BM25/vector search for faster query workflow when the wiki grows beyond grep's effectiveness.
- **Obsidian Web Clipper:** Source acquisition from the web -- clip articles directly into the `sources/` directory.
- **Marp plugin:** Generate slide decks from wiki content for presentations and reviews.

## See Also

- [AGENTS.md](../../AGENTS.md) — §15 stub (pointer to this file).
- [docs/reference/index.md](index.md)
