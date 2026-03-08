#!/bin/zsh
# .zshrc - executed for interactive shells
# Note: .zshenv has already run and set up PATH, DOTPICKLES_ROLE, mise activation, etc.

# Starship prompt
if command -v starship &> /dev/null; then
  eval "$(starship init zsh)"
fi

# 1Password CLI plugins
if command -v op &> /dev/null && [[ -f ~/.config/op/plugins.sh ]]; then
  source ~/.config/op/plugins.sh
fi

# GNU coreutils (prefer over macOS versions)
if [[ -n "$HOMEBREW_PREFIX" && -d "$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin" ]]; then
  export PATH="$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin:$PATH"
fi

# broot file manager
if [[ -f ~/.config/broot/launcher/bash/br ]]; then
  source ~/.config/broot/launcher/bash/br
fi

# Interactive shell settings
if [[ -o interactive ]]; then
  # Code editor alias based on environment (similar to fish config)
  if command -v envsense &> /dev/null; then
    ide_id=$(envsense info --json 2> /dev/null | jq -r '.traits.ide.id // empty')
    if [[ "$ide_id" = "cursor" ]] && command -v cursor &> /dev/null; then
      alias code=cursor
    elif [[ "$ide_id" = "vscode-insiders" ]] && command -v code-insiders &> /dev/null; then
      alias code=code-insiders
    elif [[ "$ide_id" = "vscode" ]] && command -v code &> /dev/null; then
      alias code=code
    fi
  else
    # Fallback: prefer code-insiders if available
    if command -v code-insiders &> /dev/null; then
      alias code=code-insiders
    fi
  fi

  # fzf integration
  if command -v fzf &> /dev/null; then
    export CHEAT_USE_FZF=true
  fi

  # neovim as vim
  if command -v nvim &> /dev/null; then
    alias vim=nvim
  fi

  # vivid for LS_COLORS
  if command -v vivid &> /dev/null; then
    export LS_COLORS="$(vivid generate one-dark)"
  fi

  # bat as pager
  if command -v bat &> /dev/null; then
    export MANPAGER="sh -c 'col -bx | bat --language man --style=plain --paging=always'"
    alias less="bat --style=plain"
  fi

  # nicer pstree graphics
  if command -v pstree &> /dev/null; then
    alias pstree="pstree -g 2"
  fi
fi

# Establish final PATH priority order (prepend in reverse order)
if [[ -n "$HOMEBREW_PREFIX" ]]; then
  export PATH="$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin:$PATH"
fi
if [[ -d "$HOME/.local/share/mise/shims" ]]; then
  # Remove duplicates and re-add at front
  export PATH="${PATH//$HOME\/.local\/share\/mise\/shims:/}"
  export PATH="$HOME/.local/share/mise/shims:$PATH"
fi
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

export GIT_MERGE_AUTOEDIT=no

# eza config directory (consistent across platforms)
export EZA_CONFIG_DIR="$HOME/.config/eza"

# git-ai
if [[ -d "$HOME/.git-ai/bin" ]]; then
  export PATH="$HOME/.git-ai/bin:$PATH"
fi

# bun
if [[ -d "$HOME/.bun/bin" ]]; then
  export PATH="$HOME/.bun/bin:$PATH"
fi
