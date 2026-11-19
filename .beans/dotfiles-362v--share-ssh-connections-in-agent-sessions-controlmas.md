---
# dotfiles-362v
title: Share ssh connections in agent sessions (ControlMaster)
status: in-progress
type: task
created_at: 2026-11-19T02:34:16Z
updated_at: 2026-11-19T02:34:16Z
---

Each new ssh connection through Automic Vault's agent takes ~13s (picklelab 13.6s x3, github.com 14s, 2026-11-18). picklehome's just deploy-openclaw opens ~10, ~2 min of an 11 min deploy. Add agent-session-only ControlMaster fragment with its own socket dir.

## Checklist

- [x] ssh/config.d/agent-mux (agent sessions only, ~/.ssh/cm-agent)
- [x] sshconfig.sh: create dir, macOS-only link
- [x] ssh/CLAUDE.md section
- [x] ADR
- [ ] Human-terminal baseline: time ssh picklelab true outside the sandbox (user to run); decide on a human-side fragment
- [ ] Verify git pushes benefit (GIT_SSH_COMMAND=ssh path)
