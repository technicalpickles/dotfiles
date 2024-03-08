if string match -q (hostname) "josh-nichols"
  set DOTPICKLES_ROLE work
else
  set DOTPICKLES_ROLE home
end

if [ (uname) = Darwin ]
  if [ "$DOTPICKLES_ROLE" = "home" ]
    set asdf_path (brew --prefix asdf)/libexec/asdf.fish
    if test -f $asdf_path
      source $asdf_path
    end
  end

  if test -d "$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin"
    fish_add_path --global --prepend --move "$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin"
  end
end

if test -d "$HOME/workspace/gdev-shell"
  $HOME/workspace/gdev-shell/bin/gdev-shell init - fish | source
end

if test -d "$HOME/Python/3.9/bin"
  fish_add_path --global "$HOME/Python/3.9/bin"
end

# if running in nvim with unception, set the pipe for what neovim-remote will use
if test -n "$NVIM_UNCEPTION_PIPE_PATH"
  set -g NVIM_LISTEN_ADDRESS "$NVIM_UNCEPTION_PIPE_PATH"
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

    if command -q nvim
      alias vim=nvim
    end

    if command -q vivid
      set -g LS_COLORS $(vivid generate one-dark)
    end

    if command -q bat
        set -gx MANPAGER "sh -c 'col -bx | bat --language man --style=plain --paging=always'"
        alias less=bat
    end

    if command -q pstree
      # nicer graphics for pstree
      alias pstree="pstree -g 2"
    end
end

# fix PATH to make sure ruby and node aren't using system ruby
if test -z "$RBENV" -o -z "$NODENV"
  for i in (seq (count $PATH))
    if test $PATH[$i] = "$HOME/.rbenv/shims"
      set rbenv_i $i
    end

    if test $PATH[$i] = "$HOME/.nodenv/shims"
      set nodenv_i $i
    end

    if test $PATH[$i] = "$HOMEBREW_PREFIX/bin"
      set homebrew_i $i
    end

    if test $PATH[$i] = "/usr/bin"
      set bin_i $i
    end
  end

  if test -z "$bin_i" && test "$bin_i" -lt "$rbenv_i" -o "$homebrew_i" -lt "$rbenv_i"
    set -g --prepend PATH "$HOME/.rbenv/shims"
  end

  if test -z "$bin_i" && test "$bin_i" -lt $nodenv_i -o "$homebrew_i" -lt "$nodenv_i"
    set -g --prepend PATH "$HOME/.nodenv/shims"
  end
end

set -g --prepend PATH "$HOME/bin"
