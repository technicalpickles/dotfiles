---
# dotfiles-mzeo
title: Set up herdr-nvim plugin
status: completed
type: task
created_at: 2026-08-05T00:46:19Z
updated_at: 2026-08-05T00:46:19Z
---

Installed and wired up ChmaraX/herdr-nvim (nvim sidebar + file picker for herdr).

## Checklist
- [x] herdr plugin install ChmaraX/herdr-nvim
- [x] Bound prefix+e (toggle) and prefix+o (pick-file) in config/herdr/config.toml
- [x] Added lua/plugins/herdr-nvim.lua to ~/.config/nvim with setup opts
- [x] Installed the plugin via headless `Lazy! install` (scoped -- did not bump other plugins)
- [x] Verified module loads cleanly in nvim

Note: ~/.config/nvim is a separate git repo from dotfiles, not managed by this repo's symlink system -- edited directly. User needs to reload herdr config (prefix+shift+r) to pick up the new keybindings.
