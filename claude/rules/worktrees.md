## Worktree Isolation: Prefer `wt` (worktrunk) Over EnterWorktree

When a repo has `wt` on `PATH`, use it for worktree isolation instead of the built-in `EnterWorktree` tool. Treat this as the user's declared worktree preference (the `superpowers:using-git-worktrees` skill honors one without asking).

**Why:** worktrunk has non-interactive flags and lifecycle hooks (bootstrap on create, teardown on remove) that `EnterWorktree` lacks. Its `worktree-path` puts worktrees at `<repo>/.claude/worktrees/<branch>`, the same place `EnterWorktree` uses, and inside the session's cwd so the command sandbox allows writes there ([ADR 0051](../../doc/adr/0051-nest-wt-worktrees-inside-the-repo.md)).

**How to apply:**

- Create: `wt switch --create <name> --yes --no-cd --format=json` (optionally `--base <ref>`). Parse `.path` and `cd` there explicitly, or pass `-C <path>`. The raw binary can't `cd` your shell.
- Remove: `git fetch` first, then `wt remove <name> -y`. `wt remove` never fetches, so after a squash-merge stale refs make it report "Branch unmerged" ([worktrunk#3519](https://github.com/max-sixty/worktrunk/issues/3519)). Nothing cleans up at session end; remove it yourself or leave it if the user is still working there.
- Under the sandbox, an `Operation not permitted` in a worktree is usually the path denylist (`.claude/agents/*`, `.claude/commands/*`, `.mcp.json`, `.git/hooks/*`, rc files), not the worktree location. If `wt switch --create` fails that way, retry with `wt switch <name>` (no `--create`) unsandboxed; the branch already exists.
- Agent branches have no upstream tracking, so don't add it ([#93](https://github.com/technicalpickles/dotfiles/pull/93)). Push with plain `git push`, never `-u`/`--set-upstream`. Open PRs with `gh pr create --head <branch>`. Pull with `git pull origin <branch>`. Under the sandbox, `git branch -m` and branch deletes land the ref change and then fail on the `.git/config` write; re-run unsandboxed if the config matters.
- Fall back to `EnterWorktree` only when `wt` isn't installed or you're outside a git repo. If you use it, pass a branch name you'd keep (it prefixes `worktree-`), keep Bash commands simple (its guard rejects `&&`, `$(...)`, multi-line), and check `git log origin/main..main` first, since it branches from `origin/<default>` and drops local-only commits.
