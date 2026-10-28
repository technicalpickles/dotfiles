## Track Work in This Repo With Beans

This repo tracks work as beans: markdown files in `.beans/`, managed with the `beans` CLI. Use beans instead of TodoWrite or ad hoc todo lists.

**Why:** bean files live next to the code, so work state survives the session and ships in the same commit as the change.

**How to apply:**

- Before a task, check for an existing bean, then create one if needed: `beans create "Title" -t <type> -d "Description..." -s in-progress`. Always pass `-t`.
- Types: `milestone`, `epic` (a container, don't work on it directly), `feature`, `task`, `bug`. Statuses: `in-progress`, `todo`, `draft`, `completed`, `scrapped`. Priorities (`-p` on create, `--priority` on update): `critical`, `high`, `normal` (the default), `low`, `deferred`.
- Write a useful description, with a `## Checklist` of `- [ ]` items when the work splits. Check items off as you finish them.
- Mark a bean completed (`beans update <id> --status completed`) only when no unchecked items remain.
- Commit the bean file together with the code change.
- Work you spot after finishing the request becomes a new bean, not more scope.
- Prefix bean titles with their IDs when showing them to the user.
- Run `beans archive` only when the user asks.
- Query with GraphQL: `beans query '<query>'` (same as `beans graphql`), `--json` for parsing. Actionable work: `beans query '{ beans(filter: { excludeStatus: ["completed", "scrapped", "draft"], isBlocked: false }) { id title status type priority } }'`. Relationships: `beans update <id> --parent <id>` or `--blocking <id>`.
- Field and filter names: `beans query --schema`. The upstream agent guide: `beans prime`.
