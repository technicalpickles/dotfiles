if [ (uname) = Darwin ]
    if test -f  $HOMEBREW_PREFIX/opt/asdf/libexec/asdf.fish
      source $HOMEBREW_PREFIX/opt/asdf/libexec/asdf.fish
    end

    if test -d "$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin"
      fish_add_path --global --prepend "$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin"
    end
end

if [ "$DOTPICKLES_ROLE" = "home" ]
  if test -f  $HOMEBREW_PREFIX/opt/asdf/libexec/asdf.fish
      source $HOMEBREW_PREFIX/opt/asdf/libexec/asdf.fish
  end
end

status --is-interactive; and /Users/josh.nichols/workspace/gdev-shell/bin/gdev-shell init - fish | source

# if test -d "$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin"
#   fish_add_path --global --prepend "$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin"
# end

if test -d "$HOME/.cargo/bin"
  fish_add_path --global "$HOME/.cargo/bin"
end

if test -d "$HOME/Python/3.9/bin"
  fish_add_path --global "$HOME/Python/3.9/bin"
end

# if running in nvim with unception, set the pipe for what neovim-remote will use
if test -n "$NVIM_UNCEPTION_PIPE_PATH"
  set -g NVIM_LISTEN_ADDRESS "$NVIM_UNCEPTION_PIPE_PATH"
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

    if command -q nvim
      alias vim=nvim
    end

    if command -q vivd
      set -g LS_COLORS $(vivid generate molokai)
    end

    if command -q bat
        set -gx MANPAGER "sh -c 'col -bx | bat --language man --plain --paging=always'"
        alias less=bat
    end
end
