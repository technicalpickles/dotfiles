## Worktree Isolation: Prefer `wt` (worktrunk) Over EnterWorktree

When a repo has `wt` on `PATH` (worktrunk is installed globally via [dotfiles](~/github.com/technicalpickles/dotfiles)'s Brewfile), use it for worktree isolation instead of the built-in `EnterWorktree` tool. This is a declared preference per the `superpowers:using-git-worktrees` skill's Step 0 ("has the user already indicated a preference in your instructions? Honor it without asking").

**Why:** worktrunk supports agent workflows directly (`-x` to launch an agent in the new worktree, `--yes`/`--format=json` for non-interactive/scriptable use) and adds lifecycle hooks (bootstrap on create, teardown on remove) that `EnterWorktree` has no equivalent for. It also keeps every worktree -- agent-created or human-created via the herdr-worktrunk picker -- in one place (`~/worktrees/{repo}/{branch}` per dotfiles' `config/worktrunk/config.toml`), so `wt list` and the herdr sidebar both see the full picture instead of agent worktrees living separately under `.claude/worktrees/`.

**How to apply:**

- Create: `wt switch --create <name> --yes --no-cd --format=json` (optionally `--base <ref>`). Parse `.path` from the JSON result and `cd` there explicitly, or pass `-C <path>` to subsequent `wt`/git calls -- don't rely on `wt`'s shell-integration `cd` (that's a shell function from `wt config shell install`; a Bash tool call invokes the raw binary, which doesn't cd the calling shell on its own).
- Remove when done: `wt remove <name> -y` (deletes the worktree and, if merged, the branch). Unlike `EnterWorktree`/`ExitWorktree`, there's no automatic keep/remove prompt at session end -- clean up explicitly, or leave it if the user wants to keep working there.
- **These commands routinely fail under the command sandbox** (`Operation not permitted` -- `~/worktrees` isn't in the sandbox's write-allowlist). This is expected, not a real failure: re-run with the sandbox disabled, same as the `git push` case.
- Fall back to `EnterWorktree` only when `wt` isn't installed, or outside a git repo (worktrunk requires one; `EnterWorktree` delegates to `WorktreeCreate`/`WorktreeRemove` hooks in that case).
