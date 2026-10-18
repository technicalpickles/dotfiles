# 62. sync-taskwarrior-with-a-periodic-launchagent

Date: 2026-10-18

## Status

Accepted

## Context

Taskwarrior 3 stores tasks locally and syncs through TaskChampion. It has no auto-sync setting: nothing pushes changes unless something runs `task sync`. The server is a TaskChampion sync server on picklelab, reachable over the tailnet; the client id and encryption secret live in the `picklehome` 1Password vault and are written to `~/.config/task/sync.rc` by `taskrc.sh` (included from `home/.taskrc`).

With nothing syncing, `task` prints "There are N local changes. Sync required." after every command, because `sync` is in the `verbose=` list. A sync agent already existed ([ADR 0049](0049-role-gated-launchagents.md) placed it), so the nag was noise: it appears for the gap between runs, not because anything is broken (task `4ad0fc5e-f555-44b4-a865-4380341ea059`).

Two constraints shape where sync can run:

- The command sandbox can't reach the tailnet host (`Operation not permitted` on connect), so `task sync` fails inside agent sessions.
- Sync should happen without anyone remembering to do it.

## Decision

Sync from a `com.technicalpickles.task-sync` LaunchAgent (`LaunchAgents/home/`, home role only) that runs `task sync` at :00 and :30 and at load, using `StartCalendarInterval` per [ADR 0025](0025-use-startcalendarinterval-for-launchagents.md). It runs outside the sandbox, so the tailnet block doesn't matter.

Drop `sync` from `verbose=` in `home/.taskrc`. The nag was the only feedback channel, and it was wrong most of the time. In its place, `bin/task-sync-status` reports health from the agent's own signals: `launchctl` run count and last exit code, plus the mtimes of the stdout log (written only on success) and stderr log (written only on failure) in `/tmp`.

### Alternatives Considered

1. **`on-exit` hook that runs `task sync` after every command**

   - Pros: changes reach the server immediately.
   - Cons: adds a network round trip to every `task` call, and a down server makes every command slow or noisy. Inside the sandbox it fails every time.

2. **Leave `sync` in `verbose=` and live with the nag**

   - Pros: no change.
   - Cons: a warning that fires on every command in normal operation trains you to ignore it, including the day sync really breaks.

3. **Shorter interval (5 or 10 minutes)**
   - Pros: smaller window of unsynced changes.
   - Cons: nothing here needs that freshness, and it means more failed attempts logged whenever the tailnet is down.

## Consequences

### Positive

- `task` output is quiet; sync happens in the background on a schedule.
- Sync health is checkable on demand with one command, and the signals come from the agent itself rather than a heuristic.

### Negative

- Silent failure is now possible: if the agent stops or the server is unreachable, nothing interrupts you. `bin/task-sync-status` only helps if you run it.
- The logs live in `/tmp`, so a reboot or cleanup resets "last success" and "last failure" to `never`.
- Changes can sit unsynced for up to 30 minutes, which matters if you edit tasks on two machines in quick succession.
