# before.init.fish - Custom script sourced before shell start

if test -x /opt/homebrew/bin/brew
	set brew /opt/homebrew/bin/brew
else if test -x /usr/local/bin/brew
	set brew /usr/local/bin/brew
end

if test -n "$brew"
	eval ($brew shellenv)
end
