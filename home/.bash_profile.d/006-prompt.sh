# needs 001-colors.sh

PS1_LINE1="${BRIGHT_GREEN}———————————————— macbook-pro \t ————————————————"

if [[ -x ~/.rvm/bin/rvm-prompt && -x __git_ps1 ]]; then
	PS1_LINE2="${BRIGHT_RED}\$(~/.rvm/bin/rvm-prompt)${RESET} in ${BRIGHT_YELLOW}\w${BRIGHT_CYAN} \$(__git_ps1 '(%s) ')"
else
	PS1_LINE2="${BRIGHT_YELLOW}\w"
fi

PS1_LINE3="${BRIGHT_BLUE}\$${RESET} "

export  PS1="\n${PS1_LINE1}\n${PS1_LINE2}\n${PS1_LINE3}"
