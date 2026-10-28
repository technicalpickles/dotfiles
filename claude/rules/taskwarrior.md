<!-- dotpickles_role: home -->

## Backlog & Task Tracking

Taskwarrior is the backlog system. Use `task` directly (config at `~/.taskrc`, data at `~/.task`).

- When the user asks about tasks, backlog, "what's next", or similar, use `task` commands. Don't use agent task tools (TaskCreate/TodoWrite) for project backlog items.
- When working in a project, check taskwarrior for relevant open tasks before starting. See the project's CLAUDE.md for which tags/projects to query.
- After completing work, capture any identified followups as taskwarrior tasks rather than leaving them as mental notes or memory entries.
- For dense query recipes (listings, single-field lookups, batched multi-task lookups, full-text search), invoke the `taskwarrior` skill from the `pickled-claude-plugins` marketplace.

**Taskwarrior vs memory vs parked sessions:**

- Taskwarrior: concrete actionable items (things to do, with optional dates)
- Memory (project/reference): state facts, architectural decisions, non-actionable context
- Parked sessions: mid-work state saves for resuming later

## Stable Task References: Use UUIDs

Integer task IDs are reused after tasks complete or the pending list otherwise reorders. Never cite them in durable artifacts (commits, memory files, docs, beans, handoffs) — use the UUID instead. Integer IDs are fine for interactive terminal use only.

For the full detail (why, how to verify a citation before it goes stale, re-resolving a cached ID mid-session) invoke the `taskwarrior` skill from the `pickled-claude-plugins` marketplace — see its "Durable references" section.

## Plan Steps Get Slugs, Not Numbers

In a plan with more than about 3 steps, name each step with a stable kebab-case slug (`docket-migration`), not an ordinal (`Task 11`), and cite the slug in commits and cross-references.

**Why:** same drift as task IDs. Inserting or reordering a step renumbers every ordinal after it; a slug doesn't move.
