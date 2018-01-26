# needs 001-colors.sh

PS1_LINE1="${BRIGHT_GREEN}———————————————— \h \t ————————————————"

if type __git_ps1 | grep -q "is a function"; then
	vcs_prompt="${BRIGHT_CYAN} \$(__git_ps1 '(%s) ')"
fi


if [[ -x ~/.rvm/bin/rvm-prompt ]]; then
	ruby_prompt="${BRIGHT_RED}\$(~/.rvm/bin/rvm-prompt)${RESET} "
fi

if type rbenv | grep -q "is a function" || which -s rbenv; then
	function rbenv_ps1_display() {
		if [[ -n $RBENV_VERSION || -f .ruby-version ]]; then
			version=$(rbenv version | cut -f1 -d' ')
			echo "$version "
		fi
	}
	ruby_prompt="${BRIGHT_RED}\$(rbenv_ps1_display)${RESET}"
fi


if type nodenv | grep -q "is a function" || which -s nodenv; then
	function nodenv_ps1_display() {
		if [[ -n $NODENV_VERSION || -f .node-version ]]; then
			version=$(nodenv version | cut -f1 -d' ')
			echo "$version "
		fi
	}
	node_prompt="${BRIGHT_GREEN}\$(nodenv_ps1_display)${RESET}"
fi


PS1_LINE2="${ruby_prompt}${node_prompt}${BRIGHT_YELLOW}\w${vcs_prompt}"
PS1_LINE3="${BRIGHT_BLUE}\$${RESET} "

export PS1="\n${PS1_LINE1}\n${PS1_LINE2}\n${PS1_LINE3}"

# force PS1 on new line http://jonisalonen.com/2012/your-bash-prompt-needs-this/
export PS1="\[\033[G\]$PS1"
