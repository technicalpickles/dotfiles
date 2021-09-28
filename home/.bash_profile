# make sure to set EDITOR so git, and other things know what to open
# vscode is pretty alright when we're in it
if [[ "$TERM_PROGRAM_VERSION" =~ insider ]] && which code-insiders >/dev/null; then
	export EDITOR="code-insiders -w"
fi
if [ "$TERM_PROGRAM" = vscode ] && which code >/dev/null; then
	export EDITOR="code -w"
# we like vim
elif which mvim >/dev/null; then
	export EDITOR="mvim -f"
elif which -s vim >/dev/null; then
	export EDITOR=vim
elif which -s vi >/dev/null; then
	export EDITOR=vi
fi


if which fzf >/dev/null; then
  export CHEAT_USE_FZF=true
fi

# we like fancy command line things if present
if which exa >/dev/null; then
  alias ls=exa
fi

if which bat >/dev/null; then
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
[[ -f ~/.fzf.bash ]] && source ~/.fzf.bash

which rbenv >/dev/null 2>&1 && eval "$(rbenv init -)"
which nodenv >/dev/null 2>&1 && eval "$(nodenv init -)"

if which brew >/dev/null 2>&1; then
	BREW_CELLAR=$(brew --cellar)
	BREW_PREFIX=$(brew --prefix)
	export BREW_CELLAR BREW_PREFIX
fi

current_file="${BASH_SOURCE[0]}"
if [[ -L "${current_file}" ]]; then
	dotfiles=$(dirname "$(dirname "$(readlink "${current_file}")")")

	. "${dotfiles}/home/.bash_profile.d/prompt.sh"

# 	if [[ -d "${dotfiles}/vendor/sbp" ]]; then
# 		SBP_PATH="${dotfiles}/vendor/sbp"
# 		. "${SBP_PATH}/sbp.bash"
# 	fi
fi