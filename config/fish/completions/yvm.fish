set -l yvm_commands ls list use rm help

set -q XDG_DATA_HOME
or set XDG_DATA_HOME ~/.local/share

set -l yvm_fish_data "$XDG_DATA_HOME/yvm_fish"

function __yvm_get_versions

    if not test -e $yvm_fish_data/yarn_releases
        _yvm_get_releases >/dev/null 2>&1
    end

    # https://stackoverflow.com/questions/4493205/unix-sort-of-version-numbers
    set -l versions (cat $yvm_fish_data/yarn_releases | awk '{ print $1 }' | sort -t. -k 1,1nr -k 2,2nr -k 3,3nr -k 4,4nr)
    set -p versions latest

    for v in $versions
        echo $v
    end
end

function __yvm_get_versions_installed
    set -l versions (find $yvm_fish_data -maxdepth 1 -mindepth 1 -type d | xargs -I _ basename _)

    for v in $versions
        echo $v
    end
end

complete --no-files --command yvm --condition "not __fish_seen_subcommand_from $yvm_commands" -a ls -d 'list all available yarn version, indicating which are installed and which is active'
complete --no-files --command yvm --condition "not __fish_seen_subcommand_from $yvm_commands" -a list -d 'list all available yarn version, indicating which are installed and which is active'
complete --no-files --command yvm --condition "not __fish_seen_subcommand_from $yvm_commands" -a use -d 'install yarn <version> and activate by prepending to $fish_user_paths'
complete --no-files --command yvm --condition "not __fish_seen_subcommand_from $yvm_commands" -a rm -d 'remove yarn <version> and remove from $fish_user_paths'
complete --no-files --command yvm --condition "not __fish_seen_subcommand_from $yvm_commands" -a help -d 'print help'

complete -k --no-files --command yvm --condition "__fish_seen_subcommand_from use " -a "(__yvm_get_versions)"
complete --no-files --command yvm --condition "__fish_seen_subcommand_from rm" -a "(__yvm_get_versions_installed)"

complete --no-files --command yvm -s h -l help -d 'print help'
complete --no-files --command yvm -s f -l force-fetch -d 'Force fetch new release data from remote'
