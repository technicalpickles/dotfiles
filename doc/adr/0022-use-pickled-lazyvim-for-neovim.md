# 22. Use pickled-lazyvim for Neovim Configuration

Date: 2026-02-01

## Status

Accepted

Supersedes the previous AstroVim-based configuration (pickled-astronvim).

## Context

The dotfiles repository previously used AstroVim as the Neovim distribution, maintained in a separate `pickled-astronvim` repository. While functional, this setup had become unmaintained and accumulated cruft over time.

The primary use case for Neovim in this workflow is **code exploration** rather than heavy editing—Claude Code handles most editing tasks. This shifts the requirements toward:

- Fast fuzzy finding across large codebases
- Easy command discoverability (which-key)
- Minimal configuration overhead
- Works well alongside tmux session management

LazyVim emerged as a better fit because:

- Active maintenance with regular updates
- Batteries-included defaults that work out of the box
- Built-in which-key for command discovery
- Telescope for fuzzy finding (with fzf-lua as optional upgrade)
- Minimal configuration needed—LazyVim handles the complexity

## Decision

Create a new `pickled-lazyvim` repository following the same pattern as pickled-astronvim:

1. **Separate repository**: Neovim config lives in `~/workspace/pickled-lazyvim/`, not in dotfiles
2. **Symlinked**: `~/.config/nvim` → `~/workspace/pickled-lazyvim`
3. **LazyVim starter**: Based on the official LazyVim starter template
4. **Minimal customization**: Accept LazyVim defaults, customize only when needed

This pattern allows:

- Independent version control for nvim config
- Easy switching between configurations (change symlink target)
- Clean separation of concerns from main dotfiles

## Consequences

### Positive

- **Zero maintenance**: LazyVim handles plugin updates and compatibility
- **Better defaults**: Telescope, neo-tree, which-key all preconfigured
- **Active community**: Issues get resolved, new features added
- **Easy extensibility**: `:LazyExtras` for optional features, `lua/plugins/` for custom plugins
- **Consistent pattern**: Same "pickled-\*" approach as before

### Negative

- **Learning curve**: Different keybindings from AstroVim (though which-key helps)
- **Two repositories**: pickled-astronvim preserved but no longer active
- **Plugin manager same**: Both use lazy.nvim, so no simplification there

### Migration Notes

- AstroVim config preserved in `pickled-astronvim` repository (unchanged)
- Data backup at `~/.local/share/nvim.backup-astronvim` (can be removed after stability confirmed)
- Old vim files in dotfiles (`home/.vimrc`, `home/.vim/`) remain as fallback

## References

- pickled-lazyvim: https://github.com/technicalpickles/pickled-lazyvim
- LazyVim documentation: https://www.lazyvim.org
- LazyVim keymaps: https://www.lazyvim.org/keymaps
- LazyVim starter: https://github.com/LazyVim/starter
