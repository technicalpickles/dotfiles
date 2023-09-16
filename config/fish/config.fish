if [ (uname) = Darwin ]
    set major_version (sw_vers -productVersion | cut -d . -f 1)

    if test -f  $HOMEBREW_PREFIX/opt/asdf/libexec/asdf.fish
      source $HOMEBREW_PREFIX/opt/asdf/libexec/asdf.fish
    end

    if test -d "$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin"
      fish_add_path --global --prepend "$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin"
    end
end

if test -d "$HOME/.cargo/bin"
  fish_add_path --global --prepend "$HOME/.cargo/bin"
end

if status is-interactive
    # use code-insiders by default
    if command -q code-insiders
        alias code=code-insiders
    else
        alias code=code
    end

    if command -q fzf
        set -g CHEAT_USE_FZF true
    end

    if command -q bat
        set -gx MANPAGER "sh -c 'col -bx | bat --language man --plain --paging=always'"
        alias less=bat
    end
end
