#if ! test -f /opt/homebrew/bin/gdev-shell
#  set brew (PATH="/opt/homebrew/bin:/usr/local/bin" command -s brew)
#  # avoid running this multiple times to avoid messing with the PATH
#  if test -n "$brew" -a -z "$HOMEBREW_PREFIX"
#    eval ($brew shellenv)
#  end
#end
