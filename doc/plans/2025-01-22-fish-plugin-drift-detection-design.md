# Fish Plugin Drift Detection

## Problem

`fish.sh` manages fish plugins during dotfiles installation. Currently it:

1. Deletes `~/.config/fish/fish_plugins`
2. Reinstalls plugins from a hardcoded bash array

This destroys any plugins added manually via `fisher install` after initial setup. The files remain on disk, but fisher loses track of them, causing confusing state where plugins work but `fisher list` doesn't show them.

## Solution

Detect "drift" - plugins in `fish_plugins` that aren't in the core list - and handle them appropriately:

- **Interactive sessions**: Prompt user to keep or drop extra plugins
- **Non-interactive sessions**: Auto-preserve extra plugins

## Design

### Core Plugins File

Create `config/fish/core_plugins` (symlinked to `~/.config/fish/core_plugins`):

```
jorgebucaran/fisher
jethrokuan/z
jorgebucaran/autopair.fish
patrickf1/fzf.fish
halostatue/fish-direnv
```

- One plugin per line
- Comments (`#`) and blank lines ignored
- Mirrors `fish_plugins` format for consistency
- Conditionals (e.g., fzf.fish requires fzf) stay in `fish.sh`, not this file

### Logic Flow

When `fish.sh` runs:

1. **Read core plugins** from `config/fish/core_plugins`
2. **Apply conditionals** - filter out plugins where dependencies aren't met
3. **Read current `fish_plugins`** (if exists)
4. **Detect drift** - find plugins in `fish_plugins` not in core list
5. **Handle drift:**
   - Interactive: prompt user
   - Non-interactive: auto-preserve
6. **Rebuild** - install core + preserved extras via fisher

### Interactive Prompt

```
Core plugins (4):
  jorgebucaran/fisher
  jethrokuan/z
  jorgebucaran/autopair.fish
  patrickf1/fzf.fish

Extra plugins found (4):
  jorgebucaran/nvm.fish
  gazorby/fish-abbreviation-tips
  danhper/fish-ssh-agent
  wawa19933/starship.fish

Keep extra plugins? [Y/n]
```

- `Y` (default): keep all extras
- `n`: drop all extras

### Non-Interactive Output

```
Core plugins (4):
  jorgebucaran/fisher
  jethrokuan/z
  jorgebucaran/autopair.fish
  patrickf1/fzf.fish

Extra plugins found (4), auto-preserving:
  jorgebucaran/nvm.fish
  gazorby/fish-abbreviation-tips
  danhper/fish-ssh-agent
  wawa19933/starship.fish
```

No prompt, logs actions, preserves extras automatically.

## Implementation Notes

1. **Fisher required** - `jorgebucaran/fisher` must always be in `core_plugins`
2. **Case-insensitive comparison** - fisher normalizes names, so `PatrickF1/fzf.fish` matches `patrickf1/fzf.fish`
3. **Conditionals before diff** - if fzf isn't installed, fzf.fish won't be "expected", so it shows as extra (correct behavior)
4. **Order preserved** - extras appended after core, predictable `fish_plugins` structure

## Files Changed

- `config/fish/core_plugins` - new file, core plugin list
- `fish.sh` - rewrite plugin management logic
- `symlinks.sh` - may need update if core_plugins needs explicit symlinking (TBD - check if config/fish/\* is already handled)
