#!/bin/zsh
# .zprofile - executed for login shells
# This runs AFTER .zshenv and BEFORE .zshrc
#
# IMPORTANT: /etc/zprofile runs path_helper which RESETS PATH
# So we need to re-establish our PATH priority order here

# Re-establish PATH priority after macOS path_helper mangles it
# Prepend in REVERSE order (last prepend = first in PATH)
# Note: mise activation in .zshenv added mise-managed tool paths, so we preserve those

# Collect all mise tool paths
typeset -a mise_paths
if [[ -d "$HOME/.local/share/mise/installs" ]]; then
  while IFS= read -r mise_path; do
    mise_paths+=("$mise_path")
  done < <(echo "$PATH" | tr ':' '\n' | grep "^$HOME/.local/share/mise/installs")
fi

if [[ -n "$HOMEBREW_PREFIX" ]]; then
  export PATH="${PATH//$HOMEBREW_PREFIX\/bin:/}"
  export PATH="${PATH//$HOMEBREW_PREFIX\/sbin:/}"
  export PATH="$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin:$PATH"
fi

# Re-add mise tool paths at the front (after homebrew)
for mise_path in "${mise_paths[@]}"; do
  export PATH="${PATH//$mise_path:/}"
  export PATH="$mise_path:$PATH"
done

if [[ -d "$HOME/.cargo/bin" ]]; then
  export PATH="${PATH//$HOME\/.cargo\/bin:/}"
  export PATH="$HOME/.cargo/bin:$PATH"
fi
if [[ -d "$HOME/.local/bin" ]]; then
  export PATH="${PATH//$HOME\/.local\/bin:/}"
  export PATH="$HOME/.local/bin:$PATH"
fi
if [[ -d "$HOME/bin" ]]; then
  export PATH="${PATH//$HOME\/bin:/}"
  export PATH="$HOME/bin:$PATH"
fi
