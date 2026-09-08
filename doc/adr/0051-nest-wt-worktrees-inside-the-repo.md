# 51. nest-wt-worktrees-inside-the-repo

Date: 2026-09-01

## Status

Accepted

## Context

`config/worktrunk/config.toml` set `worktree-path = "~/worktrees/{{ repo }}/{{ branch | sanitize }}"`, centralizing every `wt`-created worktree (agent- and human-created alike) under one `~/worktrees` hub, outside any repo's own tree. `claude/rules/worktrees.md` documented this as the reason to prefer `wt` over the built-in `EnterWorktree` tool: one place for `wt list` and the herdr sidebar to see everything.

That centralization came at a real cost. `~/worktrees` sits outside every session's working-directory tree, so the sandbox's implicit cwd allowance never covers it. It needed its own `allowWrite` entry in `claude/roles/base.jsonc`, plus a `mkdir -p ~/worktrees` pre-create step in `claudeconfig.sh` (creating the directory itself needs write access to `~`, which isn't and shouldn't be allowlisted). Every new repo cloned into `~/github.com` implicitly depended on that one shared allowlist entry continuing to exist and stay correct.

Meanwhile, Claude Code's own worktree tooling (`EnterWorktree`, and worktrees this agent creates for itself) already uses a different, un-configurable convention: `<repo>/.claude/worktrees/<branch>-<hash>`, nested inside the repo. That path landed in `claude/roles/base.jsonc`'s own commentary as the thing `wt`'s centralized layout was explicitly diverging from ("agent worktrees living separately under `.claude/worktrees/`").

So the repo carried two worktree conventions side by side: `wt`-created worktrees under `~/worktrees/{repo}/{branch}`, and Claude-created worktrees under `<repo>/.claude/worktrees/<branch>`. Having both meant twice the places to check for existing work, and a sandbox allowlist entry that existed solely to work around the chosen layout rather than anything the tools inherently required.

Probing confirmed the nested layout doesn't need a new allowlist entry at all: writes to `<repo>/.claude/worktrees/<subdir>` succeed under the sandbox with no explicit `allowWrite` rule, because they fall under the implicit allowance for the session's own cwd (or a subpath of it, when the session starts at the repo root and `wt switch --create` descends into a subdirectory of that same tree). A write to `~/worktrees` from within a _different_ repo's session, by contrast, reliably EPERMs without the dedicated entry -- that's the failure mode `dotfiles-uxr8`-era work was chasing before the entry was added.

## Decision

Change `config/worktrunk/config.toml`'s `worktree-path` to:

```
worktree-path = "{{ repo_path }}/.claude/worktrees/{{ branch | sanitize }}"
```

matching Claude Code's own convention. Remove the now-unneeded `~/worktrees` entry from `claude/roles/base.jsonc`'s `sandbox.filesystem.allowWrite`, and remove the matching `mkdir -p "$HOME/worktrees"` pre-create step from `claudeconfig.sh`. Update `claude/rules/worktrees.md` to describe the nested layout and drop the stale "keeps everything in one place" rationale.

Existing worktrees already created under `~/worktrees` are left in place; they are not migrated. Only newly created worktrees pick up the new location. `~/worktrees` itself is not deleted.

## Consequences

### Positive

- One worktree convention across the repo instead of two: `wt`-created and Claude-created worktrees now land in the same place, `<repo>/.claude/worktrees/<branch>`.
- No sandbox `allowWrite` entry needed for worktree creation or use -- nested paths are already covered by the cwd allowance, so `claude/roles/base.jsonc` sheds an entry (and the noise/EPERM-risk that entry existed to route around) entirely.
- `claudeconfig.sh` sheds a directory pre-create step that existed only to support the old layout.
- New worktrees are physically colocated with the repos they belong to, discoverable by anyone who happens to look in `<repo>/.claude/worktrees/`.

### Negative

- Loses the single `~/worktrees` hub for bulk-inspecting or bulk-cleaning worktrees across every repo at once. `wt list --branches` (or running `wt list` per-repo) covers most of the same need, but not in one shot across repos.
- `.claude/worktrees/` had been reserved for tooling-created worktrees (`EnterWorktree`, agent self-service). `wt`-created worktrees now share that directory, so `.gitignore`/tooling assumptions that treated it as exclusively Claude-managed need to tolerate `wt`'s worktrees living there too.
- Existing worktrees under `~/worktrees` are orphaned from the documented convention going forward. They still work, but `wt list` run from a repo won't surface a sibling `~/worktrees` entry for that repo unless it's the one the command was run from -- anyone with long-lived work parked there needs to know to look in the old location or migrate it (`wt remove` the old one, recreate under the new path) by hand.
