---
# dotfiles-gfb7
title: 'ADR: how tmux handles clickable URLs and OSC 8 hyperlinks'
status: completed
type: task
priority: normal
created_at: 2026-07-26T22:07:17Z
updated_at: 2026-07-27T01:18:09Z
---

Document the two complementary mechanisms for opening links from a tmux pane: bare-text URLs via tmux-open plugin (double-click + 'o'), and OSC 8 hyperlinks (e.g. Claude Code issue/PR titles) via tmux terminal-features passthrough + Shift+Cmd+Click in Ghostty (mouse on captures plain clicks). Also remove bin/tmux-smart-open, which was orphaned (unbound since commit 963038f) and whose bin/CLAUDE.md description was stale.

## Checklist
- [x] Write ADR 0044 documenting both URL-opening paths and why Shift+Cmd+Click is needed
- [x] Update doc/adr/README.md with the new entry
- [x] Remove dead bin/tmux-smart-open and its bin/CLAUDE.md entry
- [x] Commit the pending home/.tmux.conf terminal-features change alongside the ADR
