---
# dotfiles-g38g
title: Rex Claude integration and agent SSH to Coder workspaces
status: completed
type: task
created_at: 2026-11-18T15:49:59Z
updated_at: 2026-11-18T15:49:59Z
---

Wire up Rex (superlogical.com/rex) for Claude and make agent sessions able to SSH to Coder workspaces.

## Checklist
- [x] claudeconfig.sh: reinstall the rex skill + SessionStart hook each run (like herdr); remove the stale skill when rex is gone
- [x] Agent SSH relay: *.coder resolved client-side by ncat (gost skips macOS split DNS), allowlist Coder's fd60:627a:a42b::/48
- [x] sshconfig.sh: link auth and agent-relay only on macOS; their escaped-quote Match exec lines break OpenSSH 9.6 on Ubuntu 24.04 (every ssh command failed on Coder workspaces)
