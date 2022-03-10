if [ -n "$HOMEBREW_PREFIX" ]
	set -g CHRUBY_ROOT "$HOMEBREW_PREFIX"

	if [ -f "$HOMEBREW_PREFIX/share/chruby/chruby.fish" ]
		source "$HOMEBREW_PREFIX/share/chruby/chruby.fish"
	end

	if [ -f $HOMEBREW_PREFIX/share/chruby/auto.fish ]
		source "$HOMEBREW_PREFIX/share/chruby/auto.fish"
	end
end