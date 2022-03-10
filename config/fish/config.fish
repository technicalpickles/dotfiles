# use code-insiders by default
if which code-insiders >/dev/null
    alias code=code-insiders
else
    alias code=code
end

# Commands to run in interactive sessions can go here
if status is-interactive
    if which fzf >/dev/null
        set -U CHEAT_USE_FZF true
    end

    if which bat >/dev/null
        set -gx MANPAGER "sh -c 'col -bx | bat --language man --plain --paging=always'"
        alias less=bat
    end

    if [ (uname) = Darwin ]
        ssh-add --apple-load-keychain
    end
end
