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

Integer task IDs are reused after tasks complete. Never cite them in durable artifacts (commits, memory files, docs, beans). Use the UUID instead.

- `task list` shows a `UUID` column with 8-char short UUIDs
- Short UUIDs work as partial matches in any `task` command: `task b8c4246b info`
- When referencing a task from a commit message, memory file, or bean body, use the UUID form

Integer IDs are fine for interactive terminal use only.

## Same principle: plan step numbers rot

The "integer identifiers drift, stable identifiers don't" rule extends beyond taskwarrior. When writing an implementation plan with multiple steps, use stable kebab-case slugs as step headers (`classifier-scaffold`, `docket-migration`, `external-data-audit`), not integer ordinals (`Task 1`, `Task 11`). Commit messages and downstream references cite the slug.

**Why:** plan step numbers shift when a step is inserted or reordered. Every commit message or cross-reference that said "Task 11" now points at the wrong thing. Slugs are insertion-stable — adding a new step between two existing ones doesn't renumber anything.

**When:** any plan with more than ~3 steps, especially when steps will be executed across multiple commits or referenced from other docs.
