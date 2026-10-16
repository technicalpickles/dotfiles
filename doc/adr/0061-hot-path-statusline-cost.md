# 61. Keep the Claude Code statusline cheap: mise install, no npx, HEAD/index-keyed git cache

Date: 2026-10-16

## Status

Accepted

## Context

The statusline command in `claude/roles/base.jsonc` reruns every time a Claude Code session's conversation updates, in every session. That's easy to forget, because one run is cheap. With 15-20 agent sessions open at once, though, `npm exec ccstatusline` showed up in most `ps` snapshots taken during two load-spike investigations (2026-10-12 and 2026-10-16), at 20-80% CPU and 70-110MB RSS each.

It started as `npx -y ccstatusline@latest`. Tracing one refresh in a large repo (pickleton, ~6,600 tracked files) showed where the time goes:

- **npm startup.** `npx` starts Node, resolves the package, then starts a second Node for ccstatusline itself. Pinning the version (`ccstatusline@2.2.32`, PR #58) skips the "latest" registry lookup but not the npm startup. With a warm npm cache, pinned and `@latest` benchmarked the same: ~1.2s wall and ~0.7s CPU per run.
- **Node startup for ccstatusline itself:** ~120ms user CPU on every run.
- **Child processes on a git-cache miss.** The `git-branch` and `git-changes` widgets run `git rev-parse`, `git symbolic-ref HEAD`, `git diff --shortstat` and `git diff --cached --shortstat`, and terminal-width detection runs `ps`. Every spawn pays endpoint security software's exec scan, so even a trivial `git rev-parse` cost ~100ms wall for ~19ms of CPU.
- **Full worktree stats.** ccstatusline passes `-c core.fsmonitor=` to every git call (so it never starts fsmonitor daemons), which means each `git diff` stats every tracked file: ~200ms of kernel time per call, with every file access also going through the endpoint-security hooks.

ccstatusline caches git output on disk (`~/.cache/ccstatusline/git-cache`), keyed by the mtimes of `.git/HEAD` and `.git/index`. By default (`gitCacheTtlSeconds: 5`) an entry also expires after 5 seconds, so an unchanged repo still reruns all four git calls every 5 seconds per session.

All of this work is process spawns and syscalls, the two things that get slowest when the machine is already loaded, so the statusline added the most load exactly when there was least to spare.

## Decision

Three changes, each addressing a different layer:

1. **Pin the version.** `ccstatusline@2.2.32` instead of `@latest`, so the statusline doesn't upgrade itself between sessions. This is a reproducibility fix; it made no measurable difference to cost.
2. **Install it with mise and call it by name.** `"npm:ccstatusline" = "2.2.32"` lives in `config/mise/conf.d/dotfiles.toml`, and the statusline command is bare `ccstatusline`, resolved through the mise shim the same way the `codebase-memory-mcp` hooks are. This drops npm from the hot path. User CPU per run went from ~320ms to ~135ms, and the shim added ~5% wall time over calling the binary directly. (PR #66)
3. **Set `gitCacheTtlSeconds: 0`** in `config/ccstatusline/settings.json`. Zero doesn't disable the cache. It keeps a cached entry valid until `.git/HEAD` or `.git/index` changes, so an idle repo makes no git calls at all. In pickleton, a warm-cache run is ~150ms with no child processes, against ~690ms for a cold one. (PR #67)

The general rule this follows: anything on a hot path (the statusline, hooks, anything run per tool call) shouldn't go through `npx`/`uvx`, and should avoid spawning processes it can cache.

### Alternatives Considered

1. **Keep `npx`, just pinned**

   - Pros: no install step; nothing to keep in sync across machines.
   - Cons: npm's startup is the cost, and pinning doesn't remove it.
   - Rejected: measured no improvement over `@latest`.

2. **Switch to a Rust statusline.** Benchmarked in pickleton, 30 runs each, load average ~11:

   | Tool                                                                                                  | Wall   | User CPU | Sys CPU | Child processes |
   | ----------------------------------------------------------------------------------------------------- | ------ | -------- | ------- | --------------- |
   | ccstatusline, warm git cache                                                                          | ~150ms | ~120ms   | ~20ms   | none            |
   | ccstatusline, cold git cache                                                                          | ~690ms | ~170ms   | ~260ms  | 4 git + 1 ps    |
   | [statusline-rs-cc](https://github.com/Darkwing4/statusline-rs-cc)                                     | ~280ms | ~20ms    | ~300ms  | 1 `git status`  |
   | [claude-code-statusline-pro](https://github.com/Wangnov/claude-code-statusline-pro) (`show_dirty` on) | ~290ms | ~30ms    | ~200ms  | none (libgit2)  |

   - Pros: almost no user CPU, few or no child processes. claude-code-statusline-pro does git in-process through libgit2.
   - Cons: the worktree walk is the kernel-time cost no matter which tool does it, and neither keeps a git cache across runs (claude-code-statusline-pro's cache is in-process, so it dies after every refresh). claude-code-statusline-pro's much faster default numbers come from `show_dirty` defaulting to off, which skips the dirty check entirely.
   - Rejected for now: ccstatusline with a warm cache does less kernel work per refresh. Worth revisiting if Node's ~120ms user CPU per refresh becomes the bottleneck, or if one of them adds a persistent cache.

3. **`gitCacheTtlSeconds` of 30-60** (60 is the maximum)

   - Pros: the `+/-` counts are never more than a minute stale.
   - Cons: still reruns git once a minute per session for repos that haven't changed.
   - Rejected: I rarely look at the counts. Slightly stale is better than paying for them constantly.

4. **Drop the `git-changes` widget**
   - Pros: removes the two worktree-stat diffs entirely.
   - Cons: loses the counts. With TTL 0 they're nearly free anyway.

## Consequences

### Positive

- An idle session's statusline costs one Node startup, with no npm, git, or `ps` processes.
- The version only changes when it's bumped in `dotfiles.toml`.
- The per-refresh cost is written down, so the next "why is the statusline in my `ps` output" doesn't start from zero.

### Negative

- **Rollout order matters.** On each machine: pull, `mise install`, then `./claudeconfig.sh`. If `claudeconfig.sh` runs first, the statusline shows "command not found" until mise has installed it.
- **The `+/-` counts can lag.** An unstaged edit doesn't show up until something rewrites `.git/index`. A plain `git status`, `diff`, or `add` does that. Tools that run git with `--no-optional-locks` (or `GIT_OPTIONAL_LOCKS=0`) don't, and neither does editing a file without touching git.
- **`config/ccstatusline/settings.json` is still a hand-copied twin** of `~/.config/ccstatusline/settings.json`, not a symlink (see the comment in `.config/prettier/ignore`). Changes have to be copied by hand in whichever direction they were made.
- **Other `npx …@latest` calls remain:** `bin/claude-status-line` (claude-powerline) and `bin/ccusage-refresh` ([ADR 0023](0023-ccusage-for-spend-tracking.md)). Neither is on the per-refresh path today.

## Related

- [ADR 0013](0013-claude-code-configuration-management.md): how `claude/roles/*.jsonc` becomes `~/.claude/settings.json`
- [ADR 0017](0017-claude-spend-tmux-status.md): the switch to ccstatusline
