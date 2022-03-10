# init.fish - Custom script sourced after shell start

# sup sbin
fish_add_path -g /usr/local/sbin

# use code-insiders by default
if which code-insiders >/dev/null
  alias code=code-insiders
else
  alias code=code
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

set -x GOPATH ~/golang
set PATH $PATH $GOPATH/bin

if [ (uname) = "Darwin" ]
  set HB_CNF_HANDLER (brew --repository)"/Library/Taps/homebrew/homebrew-command-not-found/handler.fish"
  if test -f $HB_CNF_HANDLER
    source $HB_CNF_HANDLER
  end
end

if [ (uname) = "Darwin" ]
  ssh-add --apple-load-keychain
end