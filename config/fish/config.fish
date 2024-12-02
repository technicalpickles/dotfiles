if string match -q (hostname) josh-nichols
    set DOTPICKLES_ROLE work
else
    set DOTPICKLES_ROLE home
end

function fish_greeting
    if type welcome2u >/dev/null 2>&1
        welcome2u
    end
end

if [ (uname) = Darwin ]
    # setup version manager
    if [ -x "$HOMEBREW_PREFIX/bin/mise" ]
        # don't try to auto-install, so we things like the tide prompt don't trigger installations
        set -gx MISE_NOT_FOUND_AUTO_INSTALL false

        # show the ruby installation happening, since it can take awhile
        set -gx MISE_RUBY_VERBOSE_INSTALL true

        mise activate --shims fish | source
    else if test -d "$HOME/workspace/gdev-shell"
        $HOME/workspace/gdev-shell/bin/gdev-shell init - fish | source
        # if command -q pyenv
        #   set -Ux PYENV_ROOT $HOME/.pyenv
        #   set -U fish_user_paths $PYENV_ROOT/bin $fish_user_paths
        #
        #   pyenv init - | source
        # end
    else if [ "$DOTPICKLES_ROLE" = home ]
        set asdf_path (brew --prefix asdf)/libexec/asdf.fish
        if test -f $asdf_path
            source $asdf_path
        end
    end

    if test -d "$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin"
        fish_add_path --global --prepend --move "$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin"
    end
end

# if running in nvim with unception, set the pipe for what neovim-remote will use
if test -n "$NVIM_UNCEPTION_PIPE_PATH"
    set -g NVIM_LISTEN_ADDRESS "$NVIM_UNCEPTION_PIPE_PATH"
end


if test -z "$MISE_SHELL" && test -d "$HOME/.cargo/bin"
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
        alias less="bat --style=plain"
    end

    if command -q pstree
        # nicer graphics for pstree
        alias pstree="pstree -g 2"
    end
end

# fix PATH to make sure ruby and node aren't using system or homebrew ruby
if test -n "$RBENV_SHELL"
    fish_add_path -g --prepend --move PATH "$HOME/.rbenv/shims"
end

if test -n "$NODENV_SHELL"
    fish_add_path -g --prepend --move PATH "$HOME/.nodenv/shims"
end

# if test -n "$PYENV_ROOT"
#   fish_add_path -g --prepend --move PATH "$PYENV_ROOT/shims"
# end

set -g --prepend PATH "$HOME/bin"

set -gx GIT_MERGE_AUTOEDIT no

# Added by LM Studio CLI (lms)
set lm_studio_path "$HOME/.cache/lm-studio/bin"
if test -d "$lm_studio"
    set -gx PATH $PATH "$lm_studio_path"
end
