# init.fish - Custom script sourced after shell start
#
# It's highly recommended that your custom startup commands go into init.fish
# file instead of ~/.config/fish/config.fish, as this allows you to keep the
# whole $OMF_CONFIG directory under version control.

# sup sbin
set -g fish_user_paths "/usr/local/sbin" $fish_user_paths

# untracked files in git can be slow in large repos
set -g theme_display_git_untracked no


# use code-insiders by default
if which code-insiders >/dev/null
  alias code=code-insiders
else
  alias code=code
end

# vscode is pretty alright when we're in it
if string match -r -q insider "$TERM_PROGRAM_VERSION" && which code-insiders >/dev/null
    export EDITOR="code-insiders -w"
else if [ "$TERM_PROGRAM" = vscode ] && which code >/dev/null
    set -Ux EDITOR "code -w"
    # use stable while running inside stable
# we like vim. see https://github.com/technicalpickles/pickled-vim for settings
else if which mvim >/dev/null
    set -Ux EDITOR "mvim -f"
else if which -s vim >/dev/null
    set -Ux EDITOR vim
else if which -s vi >/dev/null
    set -Ux EDITOR vi
end

if which fzf >/dev/null
  set -U CHEAT_USE_FZF true
end

# we like fancy command line things if present
if which exa >/dev/null
  alias ls=exa
end

if which bat >/dev/null
  set -Ux MANPAGER "sh -c 'col -bx | bat --language man --plain --paging=always'"
  alias less=bat
end

# bobthefish theme
# https://github.com/oh-my-fish/oh-my-fish/blob/master/docs/Themes.md#bobthefish-1
set theme_color_scheme terminal2-dark-white

set -x GOPATH ~/golang
set PATH $PATH $GOPATH/bin

if [ (uname) = "Darwin" ]
  set HB_CNF_HANDLER (brew --repository)"/Library/Taps/homebrew/homebrew-command-not-found/handler.fish"
  if test -f $HB_CNF_HANDLER
    source $HB_CNF_HANDLER
  end
end

if [ -n "$HOMEBREW_PREFIX" ]
  set -g CHRUBY_ROOT "$HOMEBREW_PREFIX"

  if [ -f "$HOMEBREW_PREFIX/share/chruby/chruby.fish" ]
    source "$HOMEBREW_PREFIX/share/chruby/chruby.fish"
  end

  if [ -f $HOMEBREW_PREFIX/share/chruby/auto.fish ]
    source "$HOMEBREW_PREFIX/share/chruby/auto.fish"
  end
end
