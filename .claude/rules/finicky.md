---
paths: home/.finicky.ts, home/finicky.d.ts
---

# Finicky Configuration Rules

## URL Rewriting

When returning rewritten URLs from rewrite rules:

- **Return strings, not URL objects** - Finicky's URL object reconstruction is buggy (e.g., `{protocol: 'slack', host: 'channel'}` becomes `slack://undefinedchannel`)
- Return the full URL as a template string: `return \`slack://channel?team=${teamId}&id=${channelId}\``

## Slack Deep Links

For Slack URL rewriting to work correctly:

- **Use team_id (T-prefixed), not enterprise_id (E-prefixed)** - Even on Enterprise Grid, deep links require the workspace's team_id
- Find team_id by opening Slack in browser and checking `boot_data.team_id` in page source
- Deep link format: `slack://channel?team=TXXXXXXXX&id=CXXXXXXXX&message=TIMESTAMP`

## Debugging

- Enable `logRequests: true` in options to write logs to `~/Library/Logs/Finicky/`
- Use `console.log()` for debug output (not `finicky.log` which doesn't exist)
- Clear cache after config changes: `rm -f ~/Library/Caches/Finicky/finicky_bundle_*.js ~/Library/Caches/Finicky/config_cache_*.json`
- Restart Finicky to pick up changes

## Type Definitions

The `finicky.d.ts` file defines types for the config. The global `finicky` object has:

- `finicky.getSystemInfo()` - returns hostname info
- `finicky.getUrlParts(url)` - parses URL string

There is NO `finicky.log()` method - use `console.log()` instead.
