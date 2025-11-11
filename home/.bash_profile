#!/usr/bin/env bash

if [[ -f ~/.bashrc ]]; then
  source ~/.bashrc
fi

# make sure to set EDITOR so git, and other things know what to open
# vscode is pretty alright when we're in it
if [[ "$TERM_PROGRAM_VERSION" =~ insider ]] && which code-insiders > /dev/null; then
  export EDITOR="code-insiders -w"
fi
if [ "$TERM_PROGRAM" = vscode ] && which code > /dev/null; then
  export EDITOR="code -w"
# we like vim
elif which mvim > /dev/null; then
  export EDITOR="mvim -f"
elif which -s vim > /dev/null; then
  export EDITOR=vim
elif which -s vi > /dev/null; then
  export EDITOR=vi
fi

if which fzf > /dev/null; then
  export CHEAT_USE_FZF=true
fi

# we like fancy command line things if present
# if which exa >/dev/null; then
#   alias ls=exa
# fi

if which bat > /dev/null; then
  export MANPAGER="sh -c 'col -bx | bat --language man --plain --paging=always'"
  alias less=bat
fi

# always output colors in less
export LESS="-R"

# I am admin, give me the goods!
export PATH=${PATH}:/sbin:/usr/sbin:/usr/local/sbin

# I want all history ever plz
export HISTSIZE=1000000
export HISTFILESIZE=1000000000

# fzf bindings
# created with $(brew --prefix)/opt/fzf/install
if [[ -f ~/.fzf.bash ]]; then
  # shellcheck disable=SC1091
  source "$HOME/.fzf.bash"
fi

current_file="${BASH_SOURCE[0]}"
if [[ -L "${current_file}" ]]; then
  dotfiles=$(dirname "$(dirname "$(readlink "${current_file}")")")

  # shellcheck source=../home/.bash_profile.d/prompt.sh
  . "${dotfiles}/home/.bash_profile.d/prompt.sh"

# 	if [[ -d "${dotfiles}/vendor/sbp" ]]; then
# 		SBP_PATH="${dotfiles}/vendor/sbp"
# 		. "${SBP_PATH}/sbp.bash"
# 	fi
fi

lm_studio_path="$HOME/.cache/lm-studio/bin"
if [[ -d "$lm_studio_path" ]]; then
  export PATH="$PATH:$lm_studio_path"
fi

if [[ -f ~/.gusto/init.sh ]]; then
  # shellcheck disable=SC1091
  source ~/.gusto/init.sh
else
  if [[ -f "$HOME/.cargo/env" ]]; then
    # shellcheck disable=SC1091
    . "$HOME/.cargo/env"
  fi

  which rbenv > /dev/null 2>&1 && eval "$(rbenv init -)"
  which nodenv > /dev/null 2>&1 && eval "$(nodenv init -)"

  if which brew > /dev/null 2>&1; then
    BREW_CELLAR=$(brew --cellar)
    BREW_PREFIX=$(brew --prefix)
    export BREW_CELLAR BREW_PREFIX
  fi
fi

if [[ $- == *i* ]]; then
  welcome2u
fi

. "$HOME/.local/bin/env"

# Establish final PATH priority order
# Prepend in REVERSE order (last prepend = first in PATH):
if [[ -n "$HOMEBREW_PREFIX" ]]; then
  export PATH="$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin:$PATH"
fi
if [[ -d "$HOME/.local/share/mise/shims" ]]; then
  # Remove from PATH first to avoid duplicates
  export PATH="${PATH//:$HOME\/.local\/share\/mise\/shims/}"
  export PATH="$HOME/.local/share/mise/shims:$PATH"
fi
if [[ -d "$HOME/.cargo/bin" ]]; then
  # Remove from PATH first to avoid duplicates
  export PATH="${PATH//:$HOME\/.cargo\/bin/}"
  export PATH="$HOME/.cargo/bin:$PATH"
fi
if [[ -d "$HOME/.local/bin" ]]; then
  # Remove from PATH first to avoid duplicates
  export PATH="${PATH//:$HOME\/.local\/bin/}"
  export PATH="$HOME/.local/bin:$PATH"
fi
if [[ -d "$HOME/bin" ]]; then
  # Remove from PATH first to avoid duplicates
  export PATH="${PATH//:$HOME\/bin/}"
  export PATH="$HOME/bin:$PATH"
fi
