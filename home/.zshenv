#!/bin/zsh
# .zshenv - ALWAYS executed (interactive, non-interactive, login, non-login)
# This is the FIRST file zsh reads, so it's critical for PATH setup
# Keep this minimal - only environment variables needed by ALL shells

# Set up Homebrew environment FIRST (needed by everything else)
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# Determine role based on hostname (consistent with fish config.fish)
if [[ -f /.dockerenv ]] || grep -q 'docker\|lxc\|containerd' /proc/1/cgroup 2> /dev/null || [[ -n "$DOCKER_BUILD" ]]; then
  export DOTPICKLES_ROLE=container
elif [[ "$(hostname)" =~ ^josh-nichols- ]]; then
  export DOTPICKLES_ROLE=work
else
  export DOTPICKLES_ROLE=personal
fi

# Load local environment customizations if present
if [[ -f "$HOME/.local/bin/env" ]]; then
  source "$HOME/.local/bin/env"
fi

# Load work environment init if present
# IMPORTANT: Gusto init.sh sources mise via a different method and manipulates PATH
# We need to run this BEFORE our own mise activation to avoid conflicts
if [[ -f ~/.gusto/init.sh ]]; then
  source ~/.gusto/init.sh

  # Gusto init sources mise, but we want full activation for consistency with fish
  # Re-run mise activation to ensure we have environment variable management
  if command -v mise &> /dev/null; then
    eval "$(mise activate zsh)"
  fi
else
  # Non-Gusto environment: standard mise activation
  if command -v mise &> /dev/null; then
    export MISE_NOT_FOUND_AUTO_INSTALL=false
    export MISE_RUBY_VERBOSE_INSTALL=true
    export MISE_NODE_COREPACK=true
    eval "$(mise activate zsh)"
  fi
fi

# Fnox setup (CLI tool runner)
if command -v fnox &> /dev/null; then
  eval "$(fnox activate zsh)"
fi

# broot file manager
if [[ -f ~/.config/broot/launcher/bash/br ]]; then
  source ~/.config/broot/launcher/bash/br
fi

# Establish final PATH priority order
# This runs AFTER Gusto/mise/fnox to ensure our preferred order
# Prepend in REVERSE order (last prepend = first in PATH)

if [[ -n "$HOMEBREW_PREFIX" ]]; then
  # Remove duplicates and re-add at front
  export PATH="${PATH//$HOMEBREW_PREFIX\/bin:/}"
  export PATH="${PATH//$HOMEBREW_PREFIX\/sbin:/}"
  export PATH="$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin:$PATH"
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

# Global environment variables (needed by both interactive and non-interactive shells)
export GIT_MERGE_AUTOEDIT=no
export EZA_CONFIG_DIR="$HOME/.config/eza"
