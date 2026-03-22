# 25. Use StartCalendarInterval for LaunchAgents

Date: 2026-03-20

## Status

Accepted

Amends [ADR 23](0023-ccusage-for-spend-tracking.md) (scheduling mechanism)

## Context

LaunchAgents in this repo used `StartInterval` to schedule periodic tasks (ccusage-refresh every 300s, qmd-refresh every 900s). This worked in testing but silently broke in practice: after macOS sleep/wake cycles, the `StartInterval` timer would stop firing entirely. The agent would show as loaded with exit code 0, but never trigger again until manually reloaded.

The ccusage-refresh agent stopped firing overnight on 2026-03-18, leaving the tmux spend display stuck at $0 for all of 2026-03-19. The only fix was `launchctl bootout` + `launchctl bootstrap` to restart the timer.

This is a known macOS behavior. `StartInterval` is a relative timer that counts seconds from when the agent last ran. When the system sleeps, the timer pauses, and on wake it sometimes fails to resume. Apple's documentation doesn't guarantee behavior across sleep/wake for `StartInterval`.

## Decision

Switch all LaunchAgents from `StartInterval` to `StartCalendarInterval`. Calendar intervals fire at absolute wall-clock times, which macOS reliably schedules across sleep/wake. If the system was asleep when a trigger was due, launchd fires it shortly after wake.

### Changes

**ccusage-refresh** (every 5 minutes):

```xml
<!-- Before -->
<key>StartInterval</key>
<integer>300</integer>

<!-- After -->
<key>StartCalendarInterval</key>
<array>
    <dict><key>Minute</key><integer>0</integer></dict>
    <dict><key>Minute</key><integer>5</integer></dict>
    <dict><key>Minute</key><integer>10</integer></dict>
    <!-- ... every 5 minutes through 55 -->
</array>
```

**qmd-refresh** (every 15 minutes):

```xml
<!-- Before -->
<key>StartInterval</key>
<integer>900</integer>

<!-- After -->
<key>StartCalendarInterval</key>
<array>
    <dict><key>Minute</key><integer>0</integer></dict>
    <dict><key>Minute</key><integer>15</integer></dict>
    <dict><key>Minute</key><integer>30</integer></dict>
    <dict><key>Minute</key><integer>45</integer></dict>
</array>
```

Also set `RunAtLoad` to `true` on qmd-refresh so it fires immediately at login.

### Reloading

After editing a plist, the agent must be fully cycled. `launchctl load/unload` (legacy API) can hit stale state errors. The reliable sequence:

```bash
launchctl bootout gui/$(id -u)/com.pickles.ccusage-refresh
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.pickles.ccusage-refresh.plist
```

## Consequences

### Positive

- Reliable scheduling across sleep/wake cycles
- No more silent failures where agents stop firing
- Catch-up behavior: missed triggers fire shortly after wake

### Negative

- More verbose plist (12 dict entries for 5-minute intervals vs one integer)
- Fixed to clock minutes, so intervals don't perfectly distribute load (all 5-min agents fire at the same wall-clock times). Not a concern at this scale.

### Rule Going Forward

Any new LaunchAgent in this repo should use `StartCalendarInterval`, not `StartInterval`. The verbosity is worth the reliability.
