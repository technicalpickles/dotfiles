if string match -q (hostname) "josh-nichols"
  set DOTPICKLES_ROLE work
else
  set DOTPICKLES_ROLE home
end

function fish_greeting
  if test -d ~/workspace/fancy-motd
    # fancy-motd uses `declare -A`, which isn't available on the default macOS bash (3.2.57)
    # seems it is 4.0+? https://github.com/bminor/bash/blob/f3b6bd19457e260b65d11f2712ec3da56cef463f/CHANGES#L5262-L5263
    set bash (brew --prefix bash)
    if test -n "$bash"
      $bash/bin/bash ~/workspace/fancy-motd/motd.sh
    end
  end
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

# fix PATH to make sure ruby and node aren't using system or homebrew ruby
if test -n "$RBENV"
  set -g --prepend --move PATH "$HOME/.rbenv/shims"
end

if test -n "$NODENV"
  set -g --prepend --move PATH "$HOME/.nodenv/shims"
end

set -g --prepend PATH "$HOME/bin"
