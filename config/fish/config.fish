if string match --quiet --regex '^josh-nichols-' (hostname)
    set -gx DOTPICKLES_ROLE work
else
    set -gx DOTPICKLES_ROLE home
end

if test -f  ~/.gusto/init.fish
  source ~/.gusto/init.fish
else
  if test -z "$MISE_SHELL" && test -d "$HOME/.cargo/bin"
      fish_add_path --global --prepend "$HOME/.cargo/bin"
  end

  if [ (uname) = Darwin ]
    # setup version manager
    if [ -x "$HOMEBREW_PREFIX/bin/mise" ]
      # don't try to auto-install, so we things like the tide prompt don't trigger installations
      set -gx MISE_NOT_FOUND_AUTO_INSTALL false

      # show the ruby installation happening, since it can take awhile
      set -gx MISE_RUBY_VERBOSE_INSTALL true

      set -gx MISE_NODE_COREPACK true

      mise activate --shims fish | source
    end
  end
end

if which op > /dev/null && test -f ~/.config/op/plugins.sh
    source ~/.config/op/plugins.sh
end

if [ -n "$HOMEBREW_PREFIX" ]
    if test -d "$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin"
        fish_add_path --global --prepend --move "$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin"
    end
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
        alias less="bat --style=plain"
    end

    if command -q pstree
        # nicer graphics for pstree
        alias pstree="pstree -g 2"
    end
end

if test -d "$HOME/.local/bin"
  fish_add_path --global --prepend --move "$HOME/.local/bin"
end
fish_add_path --global --prepend --move PATH "$HOME/bin"

set -gx GIT_MERGE_AUTOEDIT no

# Added by LM Studio CLI (lms)
set lm_studio_path "$HOME/.cache/lm-studio/bin"
if test -d "$lm_studio"
    set -gx PATH $PATH "$lm_studio_path"
end
