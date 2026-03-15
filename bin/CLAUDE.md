# bin/

Scripts and utilities. Most are wrappers or helpers used by other scripts and hooks.

## General Utilities

- `bin/prettier`: Wraps npm prettier with custom ignore and config paths
- `bin/adr`: Wrapper for adr-tools (`bin/adr new "title"`, `bin/adr list`)
- `bin/shell`: Helper for shell-related operations

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
- `bin/ccusage-refresh`: Refresh ccusage cache (run by LaunchAgent every 5 min)
- `bin/tmux-smart-open`: Open URLs/files on double-click in tmux
- `bin/tmux-auto-rename-session`: Auto-name sessions after their directory
