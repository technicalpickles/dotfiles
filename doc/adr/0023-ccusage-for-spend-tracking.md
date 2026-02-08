# 23. Switch to ccusage for Claude Spend Tracking

Date: 2026-02-08

## Status

Accepted

Supersedes implementation details in [ADR 17](0017-claude-spend-tmux-status.md)

## Context

[ADR 17](0017-claude-spend-tmux-status.md) established Claude spend tracking in the tmux status bar by parsing JSONL transcript files directly from `~/.claude/projects/`. While functional, this approach had accuracy concerns:

1. **Pricing assumptions**: The script assumed Opus pricing for all requests, but Claude Code uses multiple models (Opus, Sonnet, Haiku)
2. **Format brittleness**: Direct parsing of transcript files could break if Claude Code changes its internal format
3. **Maintenance burden**: Keeping pricing tables up-to-date requires manual updates

The `ccusage` tool ([npm package](https://www.npmjs.com/package/ccusage)) is a dedicated Claude Code usage tracker that:
- Properly identifies and prices each model
- Is maintained specifically for Claude Code usage tracking
- Provides accurate aggregated costs

However, ccusage takes ~15 seconds to run, making it unsuitable for direct tmux status bar calls (which expect sub-second responses).

## Decision

Replace direct JSONL parsing with ccusage, using a LaunchAgent to cache results periodically.

### Architecture

```
LaunchAgent (every 5 min)
    |
    v
ccusage-refresh
    | runs: npx ccusage@latest daily --offline --since <yesterday> --json
    v
~/.claude/powerline/usage/ccusage-daily.json
    ^
    |
claude-spend-today (reads cache, formats for tmux)
    ^
    |
tmux status bar
```

### Components

1. **`bin/ccusage-refresh`**: Wrapper script that runs ccusage and saves output to cache
   - Includes locking to prevent concurrent runs
   - Logs operations for debugging
   - Validates JSON output before replacing cache

2. **`LaunchAgents/com.pickles.ccusage-refresh.plist`**: macOS LaunchAgent
   - Runs every 5 minutes (`StartInterval: 300`)
   - Runs at load for immediate first refresh
   - Logs to `/tmp/com.pickles.ccusage-refresh.{out,err}`

3. **`bin/claude-spend-today`**: Simplified display script
   - Reads from ccusage cache (instant)
   - Extracts today's cost from the daily array
   - Same output formats: `cost`, `tokens`, `both`

### Cache Files

- `~/.claude/powerline/usage/ccusage-daily.json`: Raw ccusage JSON output
- `~/.claude/powerline/usage/ccusage-refresh.log`: Refresh operation log
- `~/.claude/powerline/usage/.ccusage-refresh.lock`: Lock file during refresh

## Consequences

### Positive

- **Accurate costs**: Proper per-model pricing (Opus, Sonnet, Haiku)
- **Simpler display script**: No parsing logic, just JSON field extraction
- **Maintained upstream**: ccusage handles format changes and pricing updates
- **Debuggable**: Separate refresh script with logging

### Negative

- **5-minute staleness**: Data is up to 5 minutes old vs 60 seconds with direct parsing
- **npm dependency**: Requires npx available (already standard in dev environments)
- **Background process**: LaunchAgent must be loaded and running

### Migration

The old cache file (`tmux-today.json`) is no longer used. The new cache file (`ccusage-daily.json`) is populated by the LaunchAgent.

To activate:
```bash
# Symlink and load the LaunchAgent
ln -sf ~/.pickles/LaunchAgents/com.pickles.ccusage-refresh.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.pickles.ccusage-refresh.plist

# Or run refresh manually
ccusage-refresh

# Check status
ccusage-refresh --status
```
