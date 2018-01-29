files=$(ls ~/.bash_profile.d/private/*.sh ~/.bash_profile.d/*.sh 2>/dev/null)
for file in ${files}; do
	source "${file}"
done

# Leave these commonented out to trick scripts that check for rbenv and nodenv in .bash_profile :joy:
# eval "$(rbenv init -)"
# eval "$(nodenv init -)"
