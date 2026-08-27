# bin/

Scripts and utilities. Most are wrappers or helpers used by other scripts and hooks.

## General Utilities

- `bin/prettier`: Wraps npm prettier with custom ignore and config paths
- `bin/adr`: Wrapper for adr-tools (`bin/adr new "title"`, `bin/adr list`)
- `bin/shell`: Helper for shell-related operations
- `bin/qmd`: Runs the qmd semantic-search CLI (`@tobilu/qmd` via npx) under a pinned Node version with `mise exec`. Locates mise itself so it works under launchd (no PATH/mise activation). Used by the qmd-refresh and qmd-mcp LaunchAgents. Override version with `QMD_NODE_VERSION` (default `24`). The qmd-mcp agent runs `qmd mcp --http --port 8181` (localhost-only HTTP MCP server); register with Claude via `claude mcp add --transport http qmd http://localhost:8181/mcp --scope user`.
- `bin/safari-reading-list`: Exports Safari's Reading List by parsing `~/Library/Safari/Bookmarks.plist` directly (stdlib `plistlib`, no deps). Requires exactly one mode flag -- `--all`, `--read`, `--unread`, or `--debug` (dumps one raw item's plist keys for troubleshooting); running with none prints usage. Human-readable title/url list by default, `--json` for full JSON (title, url, preview, date_added, unread). Requires Full Disk Access for the terminal app running it -- macOS TCC blocks reading Safari's data otherwise.

## Spotlight Management

Spotlight is kept enabled (Alfred requires it) but specific directories are excluded. See [doc/spotlight-exclusions.md](../doc/spotlight-exclusions.md) for full usage.

- `bin/spotlight-apply-exclusions`: Apply exclusions from `~/.config/spotlight-exclusions` pattern file
- `bin/spotlight-expand-patterns`: Expand gitignore-style patterns to concrete paths
- `bin/spotlight-add-exclusion`: Add a directory via AppleScript UI automation
- `bin/spotlight-list-exclusions`: List current exclusions from VolumeConfiguration.plist
- `bin/spotlight-analyze-activity`: Identify high-activity directories Spotlight is indexing
- `bin/spotlight-monitor-live`: Live monitoring of Spotlight process activity

## Claude Code Utilities

- `bin/claude-spend-today`: Read today's Claude spend from ccusage cache (for tmux status bar)
- `bin/claude-status-line`: Status line wrapper (fixes Opus context window size, formats model name, wraps claude-powerline with capsule style)
- `bin/claude-ollama`: Launch Claude Code with ollama models. Auto-sets `CLAUDE_CODE_AUTO_COMPACT_WINDOW` to 80% of the model's context_length (queried from ollama API). Use `OLLAMA_MODEL` env or pass model as first arg.
- `bin/claude-permissions`: Query Claude Code permissions across all known config locations
- `bin/claude-with`: Run Claude with a named environment (isolated `CLAUDE_CONFIG_DIR` per env under `~/.local/share/claude-env/<name>/`)
- `bin/analyze-claude-sessions`: Analyze Claude Code sessions (via cq) to identify projects and skill usage
- `bin/ccusage-refresh`: Refresh ccusage cache (run by LaunchAgent every 5 min)
- `bin/tmux-auto-rename-session`: Auto-name sessions after their directory
- `bin/setup-agent-ssh-key`: Generate a per-role agent SSH identity (see [ADR 0031](../doc/adr/0031-role-scoped-agent-git-identity.md)). Accepts `--email <addr>` to override the default `joshua.nichols+<role>-agent@gmail.com` (e.g. for the work role: `--email josh.nichols+agent@gusto.com`).
- `bin/load-agent-ssh-keys`: Load every `~/.ssh/agents/*/id_ed25519` into the ssh-agent, skipping ones already there. Run at login by the `com.technicalpickles.agent-ssh-keys` LaunchAgent so _launchd's_ agent gets populated, not just the fish shell's -- without it, scheduled jobs can't sign commits (see [LaunchAgents/README.md](../LaunchAgents/README.md)).
- `bin/check-agent-ssh-key`: Validate an agent SSH identity setup (local files, Keychain, GitHub registration, Claude settings, and -- for the work role -- per-org SAML SSO authorization). Pass the same `--email` used at setup time. When the identity name differs from the role (the `home` role signs as the `personal` identity, per [ADR 0035](../doc/adr/0035-canonical-dotpickles-role-names.md)), pass `--key <path>` so it checks the real key (claudeconfig.sh derives this from the role's gitconfig include automatically).
