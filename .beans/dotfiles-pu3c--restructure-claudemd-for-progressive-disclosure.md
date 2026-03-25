---
# dotfiles-pu3c
title: Restructure CLAUDE.md for progressive disclosure
status: completed
type: task
priority: normal
created_at: 2026-03-15T19:36:17Z
updated_at: 2026-03-15T19:37:55Z
---

Split root CLAUDE.md into tiered docs: global rules stay in root, subsystem details move to subdirectory CLAUDE.md files (lazy-loaded), reference docs move to doc/.

## Checklist

- [ ] Slim root CLAUDE.md to global-only content
- [ ] Create doc/architecture.md (role system, git config, symlinks, shell env, brewfile, launchagents)
- [ ] Create ssh/CLAUDE.md (SSH config details)
- [ ] Create bin/CLAUDE.md (custom binaries + spotlight inventory)
- [ ] Create config/fish/CLAUDE.md (shell environment structure)
- [ ] Move installation/devcontainer/tool choices to doc/
- [ ] Verify claude/CLAUDE.md already covers Claude Code config
