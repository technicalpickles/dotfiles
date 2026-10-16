---
# dotfiles-ubwz
title: Add role-home.sb for safe wrapper
status: completed
type: task
priority: normal
created_at: 2026-10-16T15:03:07Z
updated_at: 2026-10-16T15:03:42Z
---

bin/safe on the home role only gets common.sb. Smoke test (2026-10-16, picklebook-air) showed ~/.pickles/bin and ~/.gitconfig.d/claude-agent-home are EPERM: the symlink targets live in ~/github.com/technicalpickles/dotfiles, which nothing grants. Add config/agent-safehouse/role-home.sb with a read-only grant on the checkout, update ADR 0060.

## Checklist
- [x] role-home.sb
- [x] re-run smoke test under safe
- [x] ADR 0060 consequences updated
- [x] PR
