## Worktree Isolation: Prefer `wt` (worktrunk) Over EnterWorktree

When a repo has `wt` on `PATH`, use it for worktree isolation instead of the built-in `EnterWorktree` tool. Treat this as the user's declared worktree preference (the `superpowers:using-git-worktrees` skill honors one without asking). Load the `git:git-worktrees` skill before you create or remove one: it has the create flags, the remove-after-merge rule, and the sandbox gotchas.

**Why:** worktrunk has non-interactive flags and lifecycle hooks that `EnterWorktree` lacks, and puts worktrees at `<repo>/.claude/worktrees/<branch>`, inside the session's cwd ([ADR 0051](../../doc/adr/0051-nest-wt-worktrees-inside-the-repo.md)). The mechanics live in the skill so they cost context only when a session uses them.

**How to apply, for any agent branch:**

- On `home` and `work`, `git push`/`fetch` over SSH goes through the `com.technicalpickles.agent-ssh-relay` relay for allowlisted hosts ([ADR 0055](../../doc/adr/0055-agent-git-over-ssh-through-the-relay.md)). Don't reach for `dangerouslyDisableSandbox`. A port-22 refusal for a host outside the allowlist is a real deny; check the repo's CLAUDE.md.
- Agent branches have no upstream tracking (`push.default = current`, `branch.autoSetupMerge = false`), so don't add it. Push with plain `git push`, never `-u`. Open PRs with `gh pr create --head <branch>` and pull with `git pull origin <branch>`. Under the sandbox, `git branch -m` and branch deletes land the ref and then fail on the `.git/config` write; re-run unsandboxed if the config matters.
