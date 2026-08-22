# 49. role-gated-launchagents

Date: 2026-08-22

## Status

Accepted

## Context

`LaunchAgents/` already had a platform-gating mechanism (ADR-adjacent, documented in `LaunchAgents/README.md`): a predicate in `functions.sh` (`running_arm64_macos`) paired with a matching subdirectory (`arm64-macos/`) and a linking loop in `symlinks.sh`. This let agents that only make sense on specific hardware opt in without affecting other machines.

There was no equivalent for agents that only make sense on a specific `DOTPICKLES_ROLE` (see [doc/architecture.md](../architecture.md) for the role system). The `karabiner-wake-fix` agent needed this same gating (Karabiner is a home-role-only tool), but it worked around the gap by living in `LaunchAgents/*.plist` (linked unconditionally by `symlinks.sh` on any macOS host) and having its _sudoers_ setup skipped by role inside `karabinerconfig.sh` -- the plist itself still gets symlinked into `~/Library/LaunchAgents` on non-home roles, it just fails harmlessly without the sudo rule.

A new need came up: sync Taskwarrior (TaskChampion) history on a recurring schedule via `task sync`. The sync server credentials come from the personal `picklehome` 1Password vault (`taskrc.sh`), so this agent has no meaning on the work role and shouldn't even be linked there.

## Decision

Add role-gating as a second, parallel axis to the existing platform-gating mechanism, using the identical mechanics:

- A `running_home_role()` predicate in `functions.sh`, checking `DOTPICKLES_ROLE` (defaulting to `home` to match the rest of the role-detection code).
- A `LaunchAgents/home/` subdirectory for plists that should only be linked on the home role.
- A matching gated loop in `symlinks.sh`, run only when `running_macos && running_home_role`.

The first agent placed here is `com.technicalpickles.task-sync.plist`, which runs `task sync` every 30 minutes via `StartCalendarInterval` (per [ADR 0025](0025-use-startcalendarinterval-for-launchagents.md), not `StartInterval`).

Documented in `LaunchAgents/README.md` as a "Role-gated agents" section, alongside the existing "Platform-gated agents" section, so both gates are discoverable and the extension pattern (add a predicate, add a subdirectory, add a loop) stays obvious for future agents.

### Alternatives Considered

1. **Follow the karabiner-wake-fix precedent** (unconditional plist symlink, role check happens inside a separate config script)

   - Pros: no new mechanism needed
   - Cons: the plist gets linked into `~/Library/LaunchAgents` on every role even when it will never do anything useful there; role gating lives implicitly in a script instead of being visible from the LaunchAgents directory structure. Not worth replicating as the pattern.

2. **Single `functions.sh` predicate checked inline in the main `LaunchAgents/*.plist` loop** (e.g. skip specific filenames by role)
   - Pros: no new subdirectory
   - Cons: role-to-agent mapping would live as a special case in `symlinks.sh` rather than being visible from the directory layout; doesn't compose with future role-specific agents.

## Consequences

### Positive

- Role-gating is now a first-class, documented mechanism symmetric with platform-gating -- adding the next role-only agent is a three-line predicate, a subdirectory, and a loop, matching an established pattern instead of improvising.
- `task-sync` never touches `~/Library/LaunchAgents` on the work role, so there's nothing to silently fail there.

### Negative

- Two parallel gating mechanisms (platform, role) exist in `symlinks.sh` now instead of one generalized one. Acceptable at this scale (one or two agents per axis); worth revisiting if a third gating axis shows up.
