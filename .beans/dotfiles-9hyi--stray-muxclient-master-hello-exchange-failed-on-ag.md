---
# dotfiles-9hyi
title: 'Stray ''muxclient: master hello exchange failed'' on agent git pull'
status: draft
type: bug
created_at: 2026-11-22T15:00:11Z
updated_at: 2026-11-22T15:00:11Z
---

Seen 2026-11-22 in a sandboxed agent session: `git pull -q origin main` (SSH to github.com through the agent-ssh-relay) printed `muxclient: master hello exchange failed` and then succeeded. The line is ssh falling back after a bad ControlMaster socket, so the pull was not affected, but it is noise and may mean a stale or half-dead master in the agent socket directory.

Not reproduced or investigated yet. `ls ~/.ssh/cm-agent` showed nothing afterwards. It happened before the relay LaunchAgent was restarted, so the restart is not the cause. Context for the multiplexing fragment is in ssh/CLAUDE.md (agent sessions only, own socket directory).

## Checklist
- [ ] Try to reproduce: repeated sandboxed `git pull`/`ls-remote` in an agent session, watching `~/.ssh/cm-agent` and `ssh -O check`
- [ ] Find out whether a master left over from an earlier session or from before a relay restart is the trigger
- [ ] If so, decide on cleanup (ControlPersist length, a stale-socket sweep, or both); if not reproducible, scrap this bean
