# bin/

Scripts and utilities, most used by other scripts, hooks and LaunchAgents. This is an index. Each script's header comment or `--help` has its flags, env vars and details, so read that before changing or running one.

## General Utilities

- `bin/prettier`: npm prettier with this repo's ignore and config paths
- `bin/adr`: adr-tools wrapper (`bin/adr new "title"`, `bin/adr list`)
- `bin/shell`: shell-related helper
- `bin/qmd`: qmd semantic-search CLI under a pinned Node via `mise exec`; works under launchd. Used by the qmd-refresh and qmd-mcp LaunchAgents (the MCP server is `http://localhost:18181/mcp`)
- `bin/cbm-reindex`: hourly codebase-memory-mcp reindex of each repo's default checkout (LaunchAgent `com.technicalpickles.cbm-reindex`)
- `bin/cbm-sweep`: by-hand overnight diagnostic index of the same corpus, with per-repo timeouts and failure captures. Run outside the sandbox
- `bin/cbm-sweep-report`: summarize a `cbm-sweep` run
- `bin/safari-reading-list`: export Safari's Reading List (needs Full Disk Access for the terminal)
- `bin/task-sync-status`: last result of the `com.technicalpickles.task-sync` LaunchAgent
- `bin/dotfiles-doctor`: read-only health check (role, symlinks, LaunchAgents, tools)
- `bin/yt-digest`: video transcript plus on-screen slide text into one `full_context.md` (`uv run --script`)

## Spotlight Management

Spotlight stays enabled (Alfred needs it) with specific directories excluded. See [doc/spotlight-exclusions.md](../doc/spotlight-exclusions.md).

- `bin/spotlight-apply-exclusions`: apply exclusions from `~/.config/spotlight-exclusions`
- `bin/spotlight-expand-patterns`: expand gitignore-style patterns to paths
- `bin/spotlight-add-exclusion`: add a directory via AppleScript UI automation
- `bin/spotlight-list-exclusions`: list current exclusions

## Process Filesystem Activity

- `bin/proc-analyze-activity`: filesystem activity for a background process over a window (presets `spotlight`, `opendirectoryd`, `falcon`, or `-f <pattern>`)
- `bin/proc-monitor-live`: same presets, live view

## Claude Code and Agent Utilities

- `bin/claude-spend-today`: today's Claude spend from the ccusage cache (tmux status bar)
- `bin/claude-status-line`: status line wrapper around claude-powerline
- `bin/claude-ollama`: launch Claude Code on an Ollama model
- `bin/claude-permissions`: query permissions across all Claude Code config locations
- `bin/claude-deploy-quiet-hook`: PreToolUse hook on `just deploy-*` (wired in `claude/roles/home.jsonc`); returns `ask` when a Brent session was active in the last 5 minutes so auto mode prompts before restarting; `HOMELAB_DEPLOY_EVEN_IF_BUSY=1` in the command skips the check, and an unreachable host comes back as context, never a block (picklehome ADR 0003)
- `bin/claude-with`: run Claude with a named, isolated `CLAUDE_CONFIG_DIR`
- `bin/ccusage-refresh`: refresh the ccusage cache (LaunchAgent, every 5 min)
- `bin/tmux-auto-rename-session`: name tmux sessions after their directory
- `bin/setup-agent-ssh-key`, `bin/check-agent-ssh-key`: create and validate a per-role agent SSH identity ([ADR 0031](../doc/adr/0031-role-scoped-agent-git-identity.md))
- `bin/load-agent-ssh-keys`: load agent keys into launchd's ssh-agent at login so scheduled jobs can sign
- `bin/av-ssh-agent-holds-key`, `bin/retire-agent-ssh-key`, `bin/setup-av-signing-key`: Automic Vault key gate, key retirement, and GPG signing-key setup ([ADR 0059](../doc/adr/0059-automic-vault-for-git-signing-and-agent-ssh.md)). `setup-av-signing-key` needs a terminal, `op` and network, so run it outside the sandbox
- `bin/safe <cmd>`: run an agent CLI under agent-safehouse with dotfiles' profiles ([ADR 0060](../doc/adr/0060-agent-safehouse-wrapper.md), [0063](../doc/adr/0063-per-invocation-grants-for-safe.md), [0064](../doc/adr/0064-isolation-policy-for-sandboxed-agents.md))
- `bin/safe-tmux`: drive a `safe` shell from a detached tmux session
- `bin/prime-models`: regenerate `prime/models.home.json` from the Ollama Cloud catalog (needs network, run outside the sandbox)
