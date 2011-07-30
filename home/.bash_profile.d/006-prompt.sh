# needs 001-colors.sh

PS1_LINE1="${BRIGHT_GREEN}———————————————— macbook-pro \t ————————————————"
PS1_LINE2="${BRIGHT_RED}\$(~/.rvm/bin/rvm-prompt)${RESET} in ${BRIGHT_YELLOW}\w${BRIGHT_CYAN} \$(__git_ps1 '(%s) ')"
PS1_LINE3="${BRIGHT_BLUE}\$${RESET} "

export  PS1="\n${PS1_LINE1}\n${PS1_LINE2}\n${PS1_LINE3}"
