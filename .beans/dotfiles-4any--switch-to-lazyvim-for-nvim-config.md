---
# dotfiles-4any
title: Switch to LazyVim for nvim config
status: completed
type: task
priority: normal
created_at: 2026-01-22T21:02:10Z
updated_at: 2026-02-01T23:02:05Z
---

Migrate from AstroVim to LazyVim with fresh configuration.

## Context

**Current Neovim Setup (separate repo, NOT in dotfiles):**

- `~/.config/nvim/` - git clone of `pickled-astronvim` repo
- Repo: `git@github.com:technicalpickles/pickled-astronvim.git`
- AstroVim distribution, working but unmaintained
- **Already preserved** in its own git repository

**Pattern:** Keep nvim configs in separate repos (pickled-\*), not in main dotfiles

**Legacy Vim Files (in dotfiles repo, unused):**

- `home/.vimrc`, `home/.vim/`, `home/.gvimrc` - old vim config
- User only uses nvim, not vim
- Can be archived or removed after LazyVim is stable

**Target Setup:**

- Create NEW `pickled-lazyvim` repo (following pickled-astronvim pattern)
- LazyVim distribution optimized for code exploration
- Minimal LSP (Claude handles editing)
- fzf-lua for large codebase fuzzy finding (optional, if Telescope slow)
- Command palette via built-in which-key
- Works well with tmux session management

## Design Doc

📄 See complete design at: `doc/plans/2025-01-22-lazyvim-migration.md`

## Goals

- Minimal configuration required
- Fast fuzzy finding in large codebases
- Easy command discoverability
- Clean, modern setup
- Zero maintenance (LazyVim handles updates)

## Checklist

- [x] **Phase 1: Create pickled-lazyvim Repository**
  - [x] Create repo on GitHub: `gh repo create pickled-lazyvim --private`
  - [x] Clone LazyVim starter to ~/workspace/pickled-lazyvim
  - [x] Remove LazyVim's git history and initialize our own repo
  - [x] Connect to GitHub remote and push
- [ ] **Phase 2: Customize for Exploration Workflow**
  - [ ] Configure minimal LSP in lua/plugins/lsp.lua (optional)
  - [ ] Add fzf-lua plugin in lua/plugins/fzf-lua.lua (optional, test Telescope first)
  - [ ] Commit customizations to pickled-lazyvim repo
- [x] **Phase 3: Switch to pickled-lazyvim**
  - [x] Backup AstroVim data: mv ~/.local/share/nvim ~/.local/share/nvim.backup-astronvim
  - [x] Symlink pickled-lazyvim: ln -s ~/workspace/pickled-lazyvim ~/.config/nvim (note: using symlink instead of clone)
  - [ ] Launch nvim (LazyVim will auto-install plugins)
- [ ] **Phase 4: Test Thoroughly**
  - [ ] LazyVim installs plugins automatically
  - [ ] File fuzzy finding works (<leader>ff or <leader><space>)
  - [ ] Grep search works (<leader>sg)
  - [ ] Keymap search works (<leader>sk)
  - [ ] which-key popup appears (press <leader> and wait)
  - [ ] neo-tree file explorer works (<leader>e)
  - [ ] Buffer navigation works (<leader>,)
  - [ ] Test in large codebase (check performance)
  - [ ] Test with tmux (no keybinding conflicts)
- [ ] **Phase 5: Documentation**
  - [ ] Update dotfiles CLAUDE.md with nvim section
  - [ ] Create ADR in dotfiles repo: doc/adr/00XX-use-pickled-lazyvim.md
  - [ ] Update pickled-lazyvim README with installation and keybindings
- [ ] **Phase 6: Cleanup (Optional)**
  - [ ] Archive old vim files in dotfiles: home/.vimrc, home/.vim/, home/.gvimrc
  - [ ] Capture learnings in Obsidian vault

## Decision Points

1. **Fuzzy finder**: Start with Telescope (default), add fzf-lua if performance issues
2. **LSP configuration**: Keep LazyVim defaults, disable per-language via :LazyExtras if too heavy
3. **Old vim config**: Keep home/.vimrc as fallback, can remove after 6 months if unused
4. **Plugin additions**: Allow customization in lua/plugins/, but prefer LazyVim extras

## Key Insights

- **AstroVim already preserved** - it's in its own git repo (pickled-astronvim), no action needed
- **Pattern:** Keep nvim configs in separate repos (pickled-\*), NOT in main dotfiles
- Create NEW `pickled-lazyvim` repo following same pattern as pickled-astronvim
- LazyVim auto-installs plugins on first launch (via `:Lazy` and `:LazyExtras`)
- Easy switching: can swap between configs by changing what ~/.config/nvim points to
- Old vim files in dotfiles/home/ are unused (user only uses nvim)
- LazyVim uses lazy.nvim (same plugin manager as AstroVim)
- Both LazyVim and AstroVim use which-key for command discoverability

## References

- Design doc: doc/plans/2025-01-22-lazyvim-migration.md
- LazyVim docs: https://www.lazyvim.org
- LazyVim keymaps: https://www.lazyvim.org/keymaps
- Research bean: dotfiles-ox24--research-neovim-distributions-for-code-exploration.md
