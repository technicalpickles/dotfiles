# needs 001-colors.sh

PS1_LINE1="${BRIGHT_GREEN}———————————————— \h \t ————————————————"

if type __git_ps1 | grep -q "is a function"; then
	vcs_prompt="${BRIGHT_CYAN} \$(__git_ps1 '(%s) ')"
fi


if [[ -x ~/.rvm/bin/rvm-prompt ]]; then
	ruby_prompt="${BRIGHT_RED}\$(~/.rvm/bin/rvm-prompt)${RESET} "
fi

if type rbenv | grep -q "is a function" || which -s rbenv; then
	ruby_prompt="${BRIGHT_RED}\$(rbenv version | cut -f1 -d' ')${RESET} "
fi

PS1_LINE2="${ruby_prompt}${BRIGHT_YELLOW}\w${vcs_prompt}"
PS1_LINE3="${BRIGHT_BLUE}\$${RESET} "

export PS1="\n${PS1_LINE1}\n${PS1_LINE2}\n${PS1_LINE3}"
