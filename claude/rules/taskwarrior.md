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

Integer task IDs are reused after tasks complete or the pending list otherwise reorders. Never cite them in durable artifacts (commits, memory files, docs, beans). Use the UUID instead.

- `task list` shows a `UUID` column with 8-char short UUIDs
- Short UUIDs work as partial matches in any `task` command: `task b8c4246b info`
- When referencing a task from a commit message, memory file, or bean body, use the UUID form

Integer IDs are fine for interactive terminal use only.

**Verify before you cite, and re-resolve before you act.**

- Before writing a UUID into a durable artifact (commit, memory, bean, handoff), confirm it actually resolves to the task you mean: `task <uuid> info` (or `_get <uuid>.description`) and read the description back. A UUID is only as trustworthy as the citation that produced it — hand-typed from memory, copied from an earlier message, or captured before the task was edited elsewhere can all silently point at the wrong task despite being correctly *formatted*.
- Before acting on a cached integer ID (`task <id> done`, `annotate`, `modify`, `depends`), re-resolve it if it was captured more than a few commands ago in the same session. The pending list renumbers as other tasks complete or as unrelated background work touches taskwarrior — an ID that was correct three tool calls ago can point at an unrelated task now. Re-run the lookup (`task list`/`task <description-fragment> list`) or resolve by UUID instead of trusting the number still means what it meant earlier.
- This has caused real damage more than once: annotations and `done` calls landing on unrelated tasks in other projects, requiring `task <uuid> denotate -- <text>` cleanup after the fact. Treat a "the ID looks right" feeling as insufficient — confirm it.

## Same principle: plan step numbers rot

The "integer identifiers drift, stable identifiers don't" rule extends beyond taskwarrior. When writing an implementation plan with multiple steps, use stable kebab-case slugs as step headers (`classifier-scaffold`, `docket-migration`, `external-data-audit`), not integer ordinals (`Task 1`, `Task 11`). Commit messages and downstream references cite the slug.

**Why:** plan step numbers shift when a step is inserted or reordered. Every commit message or cross-reference that said "Task 11" now points at the wrong thing. Slugs are insertion-stable — adding a new step between two existing ones doesn't renumber anything.

**When:** any plan with more than ~3 steps, especially when steps will be executed across multiple commits or referenced from other docs.
