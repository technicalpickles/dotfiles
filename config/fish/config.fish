# use code-insiders by default
if command -q code-insiders
    alias code=code-insiders
else
    alias code=code
end

# Commands to run in interactive sessions can go here
if status is-interactive
    if command -q fzf
        set -U CHEAT_USE_FZF true
    end

    if command -q bat
        set -gx MANPAGER "sh -c 'col -bx | bat --language man --plain --paging=always'"
        alias less=bat
    end

    if [ (uname) = Darwin ]
        set major_version (sw_vers -productVersion | cut -d . -f 1)
        if test "$major_version" -lt 12
            ssh-add -K
        else
            ssh-add --apple-load-keychain
        end
    end
end
