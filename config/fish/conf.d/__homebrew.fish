set brew (PATH="/opt/homebrew/bin:/usr/local/bin" command -s brew)
# avoid running this multiple times to avoid messing with the PATH
if test -n "$brew" -a -z "$HOMEBREW_PREFIX"
 # use our own version of shellenv, to address /opt/homebrew/bin being on the path potentially already, but too late in the PATH

 #eval ($brew shellenv)
 set -gx HOMEBREW_PREFIX ($brew --prefix)
 set -gx HOMEBREW_CELLAR ($brew --cellar);
 set -gx HOMEBREW_REPOSITORY "$HOMEBREW_PREFIX";
 fish_add_path --move -gP "$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin";
 ! set -q MANPATH; and set MANPATH ''; set -gx MANPATH "$HOMEBREW_PREFIX/share/man" $MANPATH;
 ! set -q INFOPATH; and set INFOPATH ''; set -gx INFOPATH "$HOMEBREW_PREFIX/share/info" $INFOPATH;
end
