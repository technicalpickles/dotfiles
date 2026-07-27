# 45. Sudoers.d templates for LaunchAgent root actions

Date: 2026-07-26

## Status

Accepted

## Context

Karabiner's remapping (caps->control) takes ~13.8s to reactivate after this machine wakes
from sleep. `/var/log/karabiner/core_service.log` shows the root `Karabiner-Core-Service`
daemon sitting idle for ~10 of those seconds between tearing down its event tap and
retrying its virtual-HID reconnect -- an internal retry/backoff delay, not a driver issue
(confirmed against `virtual_hid_device_service.log`, and matches an unresolved upstream
report: [pqrs-org/Karabiner-Elements#3808](https://github.com/pqrs-org/Karabiner-Elements/issues/3808)).

The fix is to force-restart the daemon on wake instead of waiting through its own delay:
`launchctl kickstart -k system/org.pqrs.service.daemon.Karabiner-Core-Service`. That target
is in the system (root) launchd domain, so the command needs root -- but the only mechanism
for running something on wake is a LaunchAgent driven by `sleepwatcher`, and LaunchAgents run
with no attached terminal, so an interactive `sudo` prompt is a dead end.

`LaunchAgents/README.md` already anticipated this exact situation in its troubleshooting
section ("Sudo password required" -> "Configure sudoers... recommended for specific
commands"), for the existing `disable-spotlight` agent's `mdutil` call. That agent was
shipped without ever actually implementing the sudoers rule, so this is the first time the
pattern is carried through into a tracked, reproducible file rather than a manual `visudo`
edit left to whoever hits the same wall.

## Decision

Add a `config/sudoers.d/` directory holding one file per scoped rule (e.g.
`config/sudoers.d/karabiner-wake-fix`), each granting `NOPASSWD` for exactly one fully
-qualified command -- never a wildcard, never `ALL`. The owning `*config.sh` script (e.g.
`karabinerconfig.sh`) installs it with `sudo install -m 0440 -o root -g wheel` into
`/etc/sudoers.d/<name>` and validates with `sudo visudo -c`, rolling back (`rm`) on failure.

This can't use the repo's usual `link()` symlink helper: `sudo`/`visudo` refuse sudoers.d
entries that are symlinks or that have loose permissions, so the target must be a real
root-owned, mode-440 file, copied and re-validated on every install run (idempotent via a
`cmp` check first).

### Alternatives Considered

1. **Run sleepwatcher itself as a root LaunchDaemon** (so its wake script already has root,
   no sudoers change needed)

   - Pros: no new sudoers surface at all
   - Cons: no existing repo infrastructure for LaunchDaemons (`LaunchAgents/` +
     `launchagents.sh` only manage the user domain); would need a parallel concept for one
     script. Also relies on guessing Homebrew's `brew services --sudo` path/HOME handling
     for a root-mode formula service, which is not well documented.
   - Rejected: more new surface area for less benefit than the already-documented sudoers
     path.

2. **Manual, untracked `sudo visudo` edit** (what `LaunchAgents/README.md` originally
   suggested)
   - Pros: zero new files
   - Cons: not reproducible across machines, not visible in `git log`/PR review, easy to
     forget or drift
   - Rejected: this repo's whole point is roles reproduced from tracked files.

## Consequences

### Positive

- The sudoers-for-LaunchAgents pattern documented since `disable-spotlight` now has a real,
  reviewable implementation other future root-needing agents can copy.
- Each rule is single-command scoped and lives in git, so `git log`/`git blame` show exactly
  when and why a passwordless-sudo grant was added.

### Negative

- Passwordless sudo for a specific command is still a standing privilege escalation path if
  that exact binary/args combination could be abused (low risk here: `launchctl kickstart`
  against one named daemon, no wildcards).
- `config/sudoers.d/*` install logic needs `sudo` at install time, which `install.sh` has
  never previously required -- the first crack in the "install.sh never needs a password"
  assumption.
