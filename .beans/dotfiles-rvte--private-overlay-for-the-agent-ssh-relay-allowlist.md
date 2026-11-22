---
# dotfiles-rvte
title: Private overlay for the agent SSH relay allowlist
status: todo
type: task
created_at: 2026-11-22T14:54:45Z
updated_at: 2026-11-22T14:54:45Z
---

The relay allowlist in config/gost/agent-ssh-relay.yml is public, and every host in it is a name someone can read. #148 trimmed one private-ish name by switching to a tailnet wildcard, but work hosts and other internal targets should not land here at all.

The Claude role config already has a private overlay (`~/.config/dotpickles/roles/<role>.jsonc`, see dotfiles-1bx8). Do the same for the relay: keep the public file as the base, and merge an optional private file over it when the LaunchAgent starts.

## Checklist
- [ ] Pick the overlay path (next to the role overlays under `~/.config/dotpickles/`) and how it merges: gost takes one `-C` file, so the merge probably has to happen in the LaunchAgent wrapper or a generated file
- [ ] Teach `launchagents.sh` (or the relay wrapper) to build the merged config, and fall back to the public file alone when no overlay exists
- [ ] Decide whether the overlay can add matchers only, or also override the public ones
- [ ] Move any host that should not be public into the overlay on the machines that need it
- [ ] Update ssh/CLAUDE.md and ADR 0055 with the overlay path, and note the kickstart reload still applies
- [ ] Verify with a throwaway gost on a spare port: overlay host allowed, off-list host refused, no-overlay machine unchanged
