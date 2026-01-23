# Fast path for minimal shell (tmux popups, etc.) - skip heavy init
if test -n "$DOTPICKLES_MINIMAL"
    # Minimal PATH setup for basic commands
    if test -d /opt/homebrew/bin
        fish_add_path --global --prepend /opt/homebrew/bin
    end
    return
end

if [ -f /.dockerenv ] || grep -q 'docker\|lxc\|containerd' /proc/1/cgroup 2>/dev/null || [ -n "$DOCKER_BUILD" ]
    set -gx DOTPICKLES_ROLE container
else if string match --quiet --regex '^josh-nichols-' (hostname)
    set -gx DOTPICKLES_ROLE work
else
    set -gx DOTPICKLES_ROLE personal
end

if which fnox >/dev/null
    fnox activate fish | source
end

if test -f ~/.gusto/init.fish
    source ~/.gusto/init.fish

    # Gusto init sources mise via bass, which overwrites PATH
    # Ensure homebrew is at the front again
    if test -n "$HOMEBREW_PREFIX"
        fish_add_path --move --global --prepend "$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin"
    end

    # init.fish activates, but only does shims
    # use this to get environment variable management among other things
    # mise activate fish | source
else
    if [ (uname) = Darwin ]
        # setup version manager
        if [ -x "$HOMEBREW_PREFIX/bin/mise" ]
            # don't try to auto-install, so we things like the tide prompt don't trigger installations
            set -gx MISE_NOT_FOUND_AUTO_INSTALL false

            # show the ruby installation happening, since it can take awhile
            set -gx MISE_RUBY_VERBOSE_INSTALL true

            set -gx MISE_NODE_COREPACK true

            mise activate fish | source
        end
    end
end

if which op >/dev/null && test -f ~/.config/op/plugins.sh
    source ~/.config/op/plugins.sh
end

if [ -n "$HOMEBREW_PREFIX" ]
    if test -d "$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin"
        fish_add_path --global --prepend --move "$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin"
    end
end

if status is-interactive
    # Use envsense to set code alias based on IDE context
    # See https://github.com/technicalpickles/envsense for detection logic
    if which envsense >/dev/null
        # Get the IDE id once and use it to set the appropriate alias
        set -l ide_id (envsense info --json 2>/dev/null | jq -r '.traits.ide.id // empty')

        if test "$ide_id" = cursor && which cursor >/dev/null
            alias code=cursor
        else if test "$ide_id" = vscode-insiders && which code-insiders >/dev/null
            alias code=code-insiders
        else if test "$ide_id" = vscode && which code >/dev/null
            alias code=code
        end
    else
        # Fallback: prefer code-insiders if available
        if command -q code-insiders
            alias code=code-insiders
        else if command -q code
            alias code=code
        end
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

# Homebrew PATH - must be in fish since HOMEBREW_PREFIX varies by architecture
# Other paths (~/bin, ~/.local/bin, ~/.cargo/bin) are managed by mise via _.path
if test -n "$HOMEBREW_PREFIX"
    fish_add_path --move --global --prepend "$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin"
end

set -gx GIT_MERGE_AUTOEDIT no

# force an explicit path, otherwise it defaults to ~/Library/Application Support/eza on macOS vs ~/.config/eza on linux
set -gx EZA_CONFIG_DIR "$HOME/.config/eza"
