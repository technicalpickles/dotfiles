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

## Chrome PWA Shims Drop URLs

Never route a handler at a Chrome app shim in `~/Applications/Chrome Apps.localized/`
(`Google Meet.app`, `Google Calendar.app`, etc).

Those bundles declare no `CFBundleURLTypes`, so they don't claim `https`. macOS
can't pass them a URL:

- sandboxed callers get `kLSAppDoesNotClaimTypeErr` (`open` exits 1)
- unsandboxed, `open` exits 0 and silently drops the URL

Either way the shim launches its hardcoded `CrAppModeShortcutURL` instead
(`meet.google.com/landing?lfhs=2`, `calendar.google.com/calendar/r`).

Two goals are in tension: landing on the **actual URL**, and getting the app's
**own dock icon / cmd-tab entry** (which only the shim provides). All four
obvious approaches were measured; only the last does both:

| Launch                                       | Right URL | Own cmd-tab entry |
| -------------------------------------------- | --------- | ----------------- |
| shim via `open -a`                           | no        | yes               |
| `--app=<url>`                                | yes       | no (it's Chrome)  |
| `--app-id=<id>`                              | no        | yes               |
| plain Chrome, rely on link capturing         | yes       | no                |
| `--app-id=<id>` + `--app-launch-url-for-...` | yes       | yes               |

Notes on the losing options, so they don't get retried:

- `--app=` windows belong to the Chrome process, so they never cmd-tab separately.
- `--app-id=` launches the real shim but silently ignores both a positional URL
  and `--app=`.
- **PWA link capturing does not help here.** `captures_links: true` in
  `web_apps.daily_metrics.<start_url>` only means the capability is enabled; it
  applies to navigations _inside_ Chrome, not to a URL handed to Chrome from the
  OS. Verified on a single clean Chrome instance: the shim never spawned and the
  URL opened as an ordinary tab.

The winning pair is `--app-id` plus `--app-launch-url-for-shortcuts-menu-item`.
That second switch is nominally plumbing for shortcuts-menu items, but it is the
only way found to point an installed PWA window at a chosen URL:

```ts
args: [
  `--app-id=${appId}`,
  `--app-launch-url-for-shortcuts-menu-item=${url.href}`,
],
```

App IDs come from `CrAppModeShortcutID` in the shim's `Info.plist`. Keep
`profile:` explicit, since the PWA is only installed in the work profile.

**Finicky omits the positional URL when `args` are set.** Confirmed from its own
log, so there's no duplicate tab to work around:

```
open -a 'Google Chrome' -n --args --profile-directory=Default \
  --app-id=<id> --app-launch-url-for-shortcuts-menu-item=<url>
```

## Verifying a Routing Change

Read this before trusting any measurement here; three separate false conclusions
came out of skipping it.

**Check for Chrome version skew first.** Chrome auto-updates on disk while your
instance keeps running the old framework. A `-n` launch of the new binary can't
join the old instance's singleton, so you get **two Chrome processes**, and
AppleScript talks to one while your probes land in the other. Every window
observation is garbage until this is resolved. Quit Chrome fully and relaunch.

```bash
/bin/ps ax -o args= | grep -oE 'Versions/[0-9.]+' | sort -u # want exactly one
```

**AppleScript does see app-mode windows.** A PWA window appears as
`mode=normal` with exactly 1 tab, indistinguishable by shape from a 1-tab browser
window. So "not in any scriptable tab" is _not_ evidence of an app window. Ground
truth for app identity is whether a shim process exists:

```bash
/bin/ps ax -o pid=,args= | grep -F 'MacOS/app_mode_loader' | grep -v grep
```

**History lags up to ~15s**, so an absent row right after a probe means nothing.
Re-query before concluding:

```bash
cp "$HOME/Library/Application Support/Google/Chrome/Default/History" /tmp/h.db
sqlite3 /tmp/h.db "SELECT datetime(last_visit_time/1000000-11644473600,'unixepoch','localtime'), url \
  FROM urls ORDER BY last_visit_time DESC LIMIT 5;"
```

**Probe safely and one action at a time.** Use an obviously invalid meeting code
(`meet.google.com/probe-xyz`) so a probe can never join a real meeting; Meet
redirects to `/_meet/whoops?sc=232`. Quit the app under test first
(`osascript -e 'quit app "Google Meet"'`) so a relaunching shim is a clean
signal, and close leftover windows between runs, since a stale window for the
same origin gets reused. Tab counts are useless as a control while a human is
using the browser.

Finicky's own log is the fastest way to see what it actually ran. Set
`options.logRequests: true`, restart Finicky (`kill` it and `open -a Finicky`;
it ignores AppleScript `quit`), then read the newest file in
`~/Library/Logs/Finicky/` and grep for `Run command`. Turn it back off when
done, since it writes every URL you open to disk. Finicky also caches its
compiled config, so clear
`~/Library/Caches/Finicky/{finicky_bundle_*.js,config_cache_*.json}` and restart
it; editing the config alone does not reliably reload it.

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
