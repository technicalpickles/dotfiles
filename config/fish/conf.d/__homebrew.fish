# Hardened Homebrew (automic-vault, ADR 0058) installs a setuid launcher at
# /usr/local/bin/brew. /opt/homebrew/bin/brew must not be run directly, and
# every launcher run is approval-gated, so in that mode set the env statically
# instead of calling brew on every shell start.
set -l brew_stub /usr/local/bin/brew
test -n "$DOTPICKLES_BREW_STUB"; and set brew_stub $DOTPICKLES_BREW_STUB

# avoid running this multiple times to avoid messing with the PATH
if test -z "$HOMEBREW_PREFIX"
    if test -u "$brew_stub"
        set -gx HOMEBREW_PREFIX /opt/homebrew
        set -gx HOMEBREW_CELLAR /opt/homebrew/Cellar
    else
        set -l brew (PATH="/opt/homebrew/bin:/usr/local/bin" command -s brew)
        if test -n "$brew"
            # use our own version of shellenv, to address /opt/homebrew/bin being on the path potentially already, but too late in the PATH
            #eval ($brew shellenv)
            set -gx HOMEBREW_PREFIX ($brew --prefix)
            set -gx HOMEBREW_CELLAR ($brew --cellar)
        end
    end

    if test -n "$HOMEBREW_PREFIX"
        set -gx HOMEBREW_REPOSITORY "$HOMEBREW_PREFIX"
        fish_add_path --move -gP "$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin"
        # the launcher's directory must come before $HOMEBREW_PREFIX/bin
        test -u "$brew_stub"; and fish_add_path --move -gP (dirname "$brew_stub")
        ! set -q MANPATH; and set MANPATH ''
        set -gx MANPATH "$HOMEBREW_PREFIX/share/man" $MANPATH
        ! set -q INFOPATH; and set INFOPATH ''
        set -gx INFOPATH "$HOMEBREW_PREFIX/share/info" $INFOPATH
    end
end
