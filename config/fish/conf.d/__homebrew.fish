set brew (PATH="/opt/homebrew/bin:/usr/local/bin" command -s brew)
if test -n "$brew"
	eval ($brew shellenv)
end
