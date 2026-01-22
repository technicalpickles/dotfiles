# Plan: Create pickled-lazyvim Repo (Fresh LazyVim Setup)

**Date:** 2025-01-22
**Status:** Design
**Related Bean:** dotfiles-4any--switch-to-lazyvim-for-nvim-config.md

## Context

### Current Architecture

**Neovim Configuration:**

- **Location:** `~/.config/nvim/` (git repo)
- **Repo:** `git@github.com:technicalpickles/pickled-astronvim.git`
- **Distribution:** AstroVim
- **Status:** Working but unmaintained, haven't kept up with updates
- **Already preserved:** In its own git repository!

**Pattern:** Separate nvim config repos (not in main dotfiles)

**Legacy Vim Files (in dotfiles repo, unused):**

- `home/.vimrc`, `home/.vim/`, `home/.gvimrc` - old vim config
- User only uses nvim, not vim
- Can be archived or removed

### Motivation for Change

1. **Use case changed:** Now using nvim primarily for code exploration in tmux, not as primary editor
2. **Haven't kept up:** AstroVim config is stale
3. **Over-configured:** Don't need heavy LSP features (Claude handles most editing)
4. **Fresh start:** LazyVim provides modern defaults, less maintenance

### Target Architecture

```
Current:
~/.config/nvim/ -> pickled-astronvim (git repo)
  └── AstroVim configuration

Target:
~/.config/nvim/ -> pickled-lazyvim (NEW git repo)
  └── LazyVim configuration

Preserved:
pickled-astronvim repo remains untouched (already in git)
```

**New Repo:** `pickled-lazyvim`

- Fresh LazyVim configuration
- Optimized for exploration workflow
- Minimal LSP, fast fuzzy finding
- Separate from main dotfiles (follows existing pattern)

## Goals

1. **Preserve AstroVim:** Already done! `pickled-astronvim` repo stays intact
2. **Create fresh LazyVim repo:** New `pickled-lazyvim` following same pattern
3. **Zero-friction setup:** Install LazyVim and get productive immediately
4. **Minimal maintenance:** Let LazyVim handle plugin updates
5. **Performance:** Fast fuzzy finding in large codebases
6. **Easy switching:** Can always go back to AstroVim by checking out that repo

## Non-Goals

- Heavy LSP configuration (Claude does most editing)
- Custom plugin development
- Vim (not Neovim) support
- Merging nvim config into main dotfiles repo (keep separate)

## Implementation Plan

### Phase 1: Create pickled-lazyvim Repository

**Goal:** New git repo with LazyVim starter

1. **Create repo on GitHub:**

   ```bash
   # Via gh CLI
   gh repo create pickled-lazyvim --private --description "LazyVim configuration for code exploration"
   
   # Or create via GitHub web UI
   ```

2. **Clone LazyVim starter locally:**

   ```bash
   cd ~/workspace
   git clone https://github.com/LazyVim/starter pickled-lazyvim
   cd pickled-lazyvim
   
   # Remove LazyVim's git history
   rm -rf .git
   
   # Initialize our own repo
   git init
   git add .
   git commit -m "Initial commit: LazyVim starter"
   ```

3. **Connect to GitHub:**
   ```bash
   git remote add origin git@github.com:technicalpickles/pickled-lazyvim.git
   git branch -M main
   git push -u origin main
   ```

### Phase 2: Customize for Exploration Workflow

**Goal:** Configure LazyVim for your use case

1. **Reduce LSP overhead:**

   **File:** `lua/config/lazy.lua`

   ```lua
   require("lazy").setup({
     spec = {
       { "LazyVim/LazyVim", import = "lazyvim.plugins" },
       { import = "plugins" },
     },
     defaults = {
       lazy = true,
     },
     performance = {
       rtp = {
         disabled_plugins = {
           "gzip",
           "tarPlugin",
           "tohtml",
           "tutor",
           "zipPlugin",
         },
       },
     },
   })
   ```

2. **Add fzf-lua for large codebases (optional):**

   **File:** `lua/plugins/fzf-lua.lua`

   ```lua
   -- Test Telescope first, add this only if performance issues
   return {
     {
       "ibhagwan/fzf-lua",
       cmd = "FzfLua",
       opts = {
         winopts = {
           height = 0.85,
           width = 0.80,
         },
       },
       keys = {
         { "<leader>ff", "<cmd>FzfLua files<cr>", desc = "Find Files (fzf-lua)" },
         { "<leader>sg", "<cmd>FzfLua live_grep_native<cr>", desc = "Grep (fzf-lua)" },
         { "<leader>,", "<cmd>FzfLua buffers<cr>", desc = "Buffers" },
         { "<leader>sk", "<cmd>FzfLua keymaps<cr>", desc = "Keymaps" },
       },
     },
   }
   ```

3. **Configure minimal LSP (optional):**

   **File:** `lua/plugins/lsp.lua`

   ```lua
   -- Only enable LSPs you actually need
   return {
     {
       "neovim/nvim-lspconfig",
       opts = {
         servers = {
           lua_ls = {},  -- For nvim config editing
           -- Add others as needed, keep minimal
         },
       },
     },
   }
   ```

4. **Commit customizations:**
   ```bash
   git add .
   git commit -m "feat: customize for code exploration workflow
   ```

- Reduce LSP overhead
- Add fzf-lua for large codebases
- Minimal server configuration

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
git push

````

### Phase 3: Switch to pickled-lazyvim

**Goal:** Point `~/.config/nvim` to new repo

1. **Backup AstroVim data:**
```bash
# Backup plugin data
mv ~/.local/share/nvim ~/.local/share/nvim.backup-astronvim
mv ~/.local/state/nvim ~/.local/state/nvim.backup-astronvim
mv ~/.cache/nvim ~/.cache/nvim.backup-astronvim
````

2. **Switch repos:**

   ```bash
   # Move current AstroVim aside
   mv ~/.config/nvim ~/.config/nvim.astronvim
   
   # Clone pickled-lazyvim
   git clone git@github.com:technicalpickles/pickled-lazyvim.git ~/.config/nvim
   ```

3. **Launch nvim:**
   ```bash
   nvim
   # LazyVim will auto-install all plugins
   # Wait for installation to complete (~1-2 minutes)
   ```

### Phase 4: Test Thoroughly

**Goal:** Verify LazyVim works for your workflow

**Test checklist:**

- [ ] LazyVim installs plugins automatically
- [ ] File fuzzy finding works (`<leader>ff` or `<leader><space>`)
- [ ] Grep search works (`<leader>sg`)
- [ ] Keymap search works (`<leader>sk`)
- [ ] which-key popup appears (press `<leader>` and wait)
- [ ] neo-tree file explorer works (`<leader>e`)
- [ ] Buffer navigation works (`<leader>,`)
- [ ] Test in large codebase (check performance)
- [ ] Test with tmux (no keybinding conflicts)
- [ ] Verify no AstroVim keybinding muscle memory issues

**Performance test:**

```bash
cd ~/workspace/[large-monorepo]
nvim
# Try fuzzy finding, grep, navigation
# If Telescope is slow, activate fzf-lua plugin
```

### Phase 5: Document Setup

**Goal:** Update documentation to reference new repo

1. **Update dotfiles CLAUDE.md:**

   Add section:

   ````markdown
   ## Neovim Configuration

   Using LazyVim distribution via separate git repository.

   **Repo:** `git@github.com:technicalpickles/pickled-lazyvim.git`
   **Location:** `~/.config/nvim/` (git clone of pickled-lazyvim)

   **Key features:**

   - Fuzzy finding: `<leader>ff` or `<leader><space>` (files), `<leader>sg` (grep)
   - Command palette: `<leader>sk` (search keymaps)
   - File explorer: `<leader>e` (neo-tree)
   - Buffer navigation: `<leader>,`
   - which-key: Press `<leader>` and wait to see available commands

   **Customization:**

   - Edit files in pickled-lazyvim repo
   - Commit and push changes
   - Add plugins: `lua/plugins/*.lua`
   - Custom keymaps: `lua/config/keymaps.lua`

   **Notes:**

   - Optimized for code exploration, minimal LSP overhead
   - Using [Telescope/fzf-lua] for fuzzy finding
   - Previous AstroVim config preserved in pickled-astronvim repo

   **To switch back to AstroVim:**

   ```bash
   mv ~/.config/nvim ~/.config/nvim.lazyvim
   git clone git@github.com:technicalpickles/pickled-astronvim.git ~/.config/nvim
   # Restore data: mv ~/.local/share/nvim.backup-astronvim ~/.local/share/nvim
   ```
   ````

   ```

   ```

2. **Create ADR in dotfiles repo:**

   **File:** `doc/adr/00XX-use-pickled-lazyvim.md`

   ```markdown
   # XX. Use pickled-lazyvim for Neovim Configuration

   Date: 2025-01-22

   ## Status

   Accepted

   ## Context

   Current nvim setup uses pickled-astronvim (AstroVim) but:

   - Haven't kept up with updates
   - Over-configured for current needs (exploration vs. editing)
   - Use case changed: Claude handles most editing, nvim used for exploration
   - Want minimal maintenance

   Nvim configuration is maintained in separate git repository (not in dotfiles),
   following pattern: `~/.config/nvim/` -> git clone of pickled-\* repo

   ## Decision

   Create new `pickled-lazyvim` repository with fresh LazyVim configuration.

   Switch `~/.config/nvim/` to point to pickled-lazyvim instead of pickled-astronvim.

   Preserve pickled-astronvim repo as-is for reference (can switch back anytime).

   ## Consequences

   ### Positive

   - LazyVim provides modern defaults with minimal configuration
   - Auto-updates plugins
   - Better command discoverability (which-key built-in)
   - Optimized for current workflow (exploration vs. editing)
   - Clean slate allows removing unused plugins/features
   - pickled-astronvim preserved, can switch back anytime
   - Follows existing pattern of separate nvim config repos

   ### Negative

   - Need to re-learn some keybindings (though LazyVim is similar to AstroVim)
   - Lost time invested in AstroVim configuration
   - May need to add fzf-lua if Telescope slow in large repos

   ### Neutral

   - Two nvim config repos to maintain (pickled-astronvim and pickled-lazyvim)
   - Easy to switch between them if needed
   ```

3. **Update pickled-lazyvim README:**

   **File:** `README.md` in pickled-lazyvim repo

   ````markdown
   # pickled-lazyvim

   LazyVim configuration optimized for code exploration in tmux.

   ## Features

   - Minimal LSP configuration (Claude handles most editing)
   - Fast fuzzy finding with Telescope (or fzf-lua for large codebases)
   - Built-in command palette (which-key)
   - Optimized for navigation and exploration

   ## Installation

   ```bash
   # Clone to standard nvim config location
   git clone git@github.com:technicalpickles/pickled-lazyvim.git ~/.config/nvim
   
   # Launch nvim (plugins auto-install)
   nvim
   ```
   ````

   ## Customization

   - Add plugins: `lua/plugins/*.lua`
   - Custom keymaps: `lua/config/keymaps.lua`
   - Options: `lua/config/options.lua`

   ## Key Keybindings

   - `<leader>ff` or `<leader><space>` - Find files
   - `<leader>sg` - Live grep
   - `<leader>sk` - Search keymaps (command palette)
   - `<leader>e` - File explorer
   - `<leader>,` - Buffer list
   - `<leader>` (wait) - which-key popup with all commands

   ## Switching Back to AstroVim

   ```bash
   mv ~/.config/nvim ~/.config/nvim.lazyvim
   git clone git@github.com:technicalpickles/pickled-astronvim.git ~/.config/nvim
   ```

   ```

   ```

### Phase 6: Cleanup (Optional)

**Goal:** Remove unused vim configuration from dotfiles

1. **Archive old vim files:**

   ```bash
   cd ~/workspace/dotfiles

   # Archive
   mkdir -p home/.archive
   git mv home/.vimrc home/.archive/
   git mv home/.gvimrc home/.archive/
   git mv home/.vim home/.archive/
   git mv vim.sh home/.archive/

   git commit -m "chore(vim): archive unused vim configuration
   ```

Only using nvim (not vim), archiving legacy vim config files.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"

````

2. **Or delete entirely** (after confirming LazyVim is stable):
```bash
git rm -r home/.vimrc home/.gvimrc home/.vim vim.sh
git commit -m "chore(vim): remove unused vim configuration"
````

## Rollback Strategy

### Switch Back to AstroVim

```bash
# Move LazyVim aside
mv ~/.config/nvim ~/.config/nvim.lazyvim

# Restore AstroVim
mv ~/.config/nvim.astronvim ~/.config/nvim
# OR re-clone: git clone git@github.com:technicalpickles/pickled-astronvim.git ~/.config/nvim

# Restore data directories
rm -rf ~/.local/share/nvim
mv ~/.local/share/nvim.backup-astronvim ~/.local/share/nvim

# Launch nvim (AstroVim back in action)
nvim
```

### Keep Both (Easy Switching)

```bash
# Add aliases to switch between configs
alias nvim-astro='NVIM_APPNAME=nvim.astronvim nvim'
alias nvim-lazy='NVIM_APPNAME=nvim nvim'

# Or use shell script to swap
# ~/bin/switch-nvim {astronvim|lazyvim}
```

## Success Criteria

- [ ] pickled-lazyvim repo created on GitHub
- [ ] LazyVim customized for exploration workflow
- [ ] ~/.config/nvim points to pickled-lazyvim
- [ ] LazyVim installs and runs without errors
- [ ] Fuzzy finding is fast in large codebases
- [ ] Can find commands easily via `<leader>sk` or which-key
- [ ] Works well with tmux (no keybinding conflicts)
- [ ] Documentation updated (CLAUDE.md, ADR, pickled-lazyvim README)
- [ ] pickled-astronvim preserved (can switch back anytime)

## Timeline

- **Phase 1 (Create repo):** 30 minutes
- **Phase 2 (Customize):** 1 hour
- **Phase 3 (Switch):** 15 minutes
- **Phase 4 (Testing):** 2-3 hours
- **Phase 5 (Documentation):** 1 hour
- **Phase 6 (Cleanup):** 30 minutes (optional)
- **Total:** ~4-6 hours of focused work

## Open Questions

1. **Public or private repo?**

   - **Decision:** Private (following pickled-astronvim pattern)

2. **Fuzzy finder:** Start with Telescope or pre-configure fzf-lua?

   - **Decision:** Start with Telescope, add fzf-lua only if performance issues

3. **LSP configuration:** Disable all LSPs or keep minimal set?

   - **Decision:** Keep LazyVim defaults, disable per-language via `:LazyExtras` if too heavy

4. **Old vim config:** Archive or delete `home/.vim*` files?

   - **Decision:** Archive after LazyVim is stable, delete after confirming unused

5. **Installation script in dotfiles?**
   - **Decision:** Optional - add helper script to clone pickled-lazyvim if desired

## References

- LazyVim docs: https://www.lazyvim.org
- LazyVim keymaps: https://www.lazyvim.org/keymaps
- LazyVim plugins: https://www.lazyvim.org/plugins
- LazyVim starter: https://github.com/LazyVim/starter
- Current repo: https://github.com/technicalpickles/pickled-astronvim (private)
- Research bean: `.beans/dotfiles-ox24--research-neovim-distributions-for-code-exploration.md`
- Tracking bean: `.beans/dotfiles-4any--switch-to-lazyvim-for-nvim-config.md`

## Next Steps

1. Execute Phase 1: Create pickled-lazyvim repo on GitHub
2. Execute Phase 2: Customize LazyVim for exploration workflow
3. Execute Phase 3: Switch ~/.config/nvim to pickled-lazyvim
4. Test thoroughly (Phase 4)
5. Update documentation (Phase 5)
6. Update tracking bean with progress
