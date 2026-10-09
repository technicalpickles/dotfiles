#!/bin/zsh
# .zshenv - ALWAYS executed (interactive, non-interactive, login, non-login)
# This is the FIRST file zsh reads, so it's critical for PATH setup
# Keep this minimal - only environment variables needed by ALL shells

# Set up Homebrew environment FIRST (needed by everything else)
#
# Hardened Homebrew (automic-vault, ADR 0058) installs a setuid launcher at
# /usr/local/bin/brew; /opt/homebrew/bin/brew must not be run directly, and
# every launcher run is approval-gated, so set the env statically instead of
# eval'ing `brew shellenv` on every zsh start. When `av harden brew` offers to
# rewrite this file, answer N.
#
# _dotpickles_brew_stub_first moves the launcher's directory to the front of
# PATH, ahead of /opt/homebrew/bin. .zprofile and .zshrc re-prepend
# $HOMEBREW_PREFIX/bin, so they call it again right after (ADR 0058).
_dotpickles_brew_stub_first() {
  local stub="${DOTPICKLES_BREW_STUB:-/usr/local/bin/brew}"
  [[ -u $stub ]] || return 0
  local dir="${stub%/*}"
  PATH=":$PATH:"
  PATH="${PATH//:$dir:/:}"
  PATH="${PATH#:}"
  export PATH="$dir:${PATH%:}"
}

_brew_stub="${DOTPICKLES_BREW_STUB:-/usr/local/bin/brew}"
if [[ -u $_brew_stub ]]; then
  export HOMEBREW_PREFIX=/opt/homebrew
  export HOMEBREW_CELLAR=/opt/homebrew/Cellar
  export HOMEBREW_REPOSITORY=/opt/homebrew
  typeset -U path
  path=("${_brew_stub:h}" /opt/homebrew/bin /opt/homebrew/sbin $path)
  export MANPATH="/opt/homebrew/share/man${MANPATH+:$MANPATH}:"
  export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}"
elif [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi
unset _brew_stub

# Determine role (consistent with install.sh and fish dotpickles-role.fish).
# Precedence: claude-code-remote (cloud is also a container, so it must win) ->
# container -> work (hostname) -> home. See doc/adr/0035 + 0040.
if [[ "$CLAUDE_CODE_REMOTE" == "true" ]]; then
  export DOTPICKLES_ROLE=claude-code-remote
elif [[ -f /.dockerenv ]] || grep -q 'docker\|lxc\|containerd' /proc/1/cgroup 2> /dev/null || [[ -n "$DOCKER_BUILD" ]]; then
  export DOTPICKLES_ROLE=container
elif [[ "$(hostname)" =~ ^josh-nichols- ]]; then
  export DOTPICKLES_ROLE=work
else
  export DOTPICKLES_ROLE=home
fi

# Load local environment customizations if present
if [[ -f "$HOME/.local/bin/env" ]]; then
  source "$HOME/.local/bin/env"
fi

# Load work environment init if present
# IMPORTANT: Gusto init.sh sources mise via a different method and manipulates PATH
# We need to run this BEFORE our own mise activation to avoid conflicts
if [[ -f ~/.gusto/init.sh ]]; then
  # gusto init uses `basename $SHELL` to pick the mise flavor — override it to zsh
  # so it doesn't try to eval fish commands when the login shell is fish
  local _shell_before_gusto="$SHELL"
  export SHELL="$ZSH_NAME"
  source ~/.gusto/init.sh
  export SHELL="$_shell_before_gusto"

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
  # Quiet fnox under Claude Code: skip activation chatter and stop warning
  # about missing secrets the agent doesn't need
  if [[ -n "$CLAUDECODE" ]]; then
    export FNOX_SHELL_OUTPUT=none
    export FNOX_IF_MISSING=ignore
  fi
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
  # ADR 0058: hardened launcher dir must precede $HOMEBREW_PREFIX/bin
  _dotpickles_brew_stub_first
fi
# pinned wrappers (e.g. qmd -> mise exec node@24) must beat mise shims
if [[ -d "$HOME/.pickles/bin" ]]; then
  export PATH="${PATH//$HOME\/.pickles\/bin:/}"
  export PATH="$HOME/.pickles/bin:$PATH"
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
