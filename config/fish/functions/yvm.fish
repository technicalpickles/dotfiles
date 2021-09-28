set -g yvm_fish 0.10.0
set -g yvm_fish_release_prefixes yarn kpm fb-kpm

set -q XDG_DATA_HOME
or set XDG_DATA_HOME ~/.local/share

set -g yvm_fish_data $XDG_DATA_HOME/yvm_fish

set -g yvm_releases "$yvm_fish_data/yarn_releases"

set -q yvm_fish_yarn_releases_url
or set -g yvm_fish_yarn_releases_url "https://d236jo9e8rrdox.cloudfront.net/yarn-releases"
function yvm -a cmd -d "yarn version manager"
    set -l options (fish_opt -s h -l help) (fish_opt -s v -l version)
    argparse $options -- $argv 2>/dev/null

    if test -n "$_flag_h"
        _yvm_help
        return 0
    end

    if test -n "$_flag_v"
        echo "$yvm_fish"
        return 0
    end

    if not test -d $yvm_fish_data
        mkdir -p $yvm_fish_data
    end

    switch "$cmd"
        case ls list
            set -e argv[1]
            _yvm_ls $argv
        case use
            set -e argv[1]
            _yvm_use $argv
        case rm
            set -e argv[1]
            _yvm_rm $argv
        case "help"
            _yvm_help
        case \*
            echo "yvm: unknown flag or command \"$cmd\""
            _yvm_help
            return 1
    end
end

function _yvm_get_releases
    set -l options (fish_opt -s f -l force-fetch)
    argparse $options -- $argv

    set -q yvm_last_updated
    or set -g yvm_last_updated 0

    set -l releases_temp (mktemp)

    if test -n "$_flag_f"
        or test ! -e $yvm_releases -o (math (date +%s) - $yvm_last_updated) -gt 120

        echo "Fetching releases from $yvm_fish_yarn_releases_url"

        # I used to download and redirect this into a file directly, using -s
        # to strip all curl output. But this also appears to swallow errors. In
        # other words -s really silences it. This lead to hard to debug issues
        # because users saw an error message that didn't tell them anything.
        # Using a temporary file as an intermediary and letting curl output its
        # progress and errors is much easier.
        curl -s $yvm_fish_yarn_releases_url -o $releases_temp || return 1

        cat $releases_temp\
                | tr ',' '\n'\
                | awk -F'":"' '
                    BEGIN {
                      version = "";
                    }
                    {
                      gsub(/"/, "", $2)
                      if ($1 ~ /name/ ) { version = $2 }
                      if ($1 ~ /tarball/) { gsub(/v/, "", version); print version, $2; }
                    }
                ' >$yvm_releases

        set -g yvm_last_updated (date +%s)
    end
end

function _yvm_get_url_for_version -d "Tries different prefixes to generate a valid tarball url"
    set -l v $argv
    set -l basenames "https://github.com/yarnpkg/yarn/releases/download/v$v" "https://github.com/yarnpkg/yarn/releases/download/$v"

    for b in $basenames
        # For example with the prefixes yarn and kpm this will try things like
        # yarn-v1.0.0.tar.gz and kpm-v1.0.0.tar.gz
        for p in $yvm_fish_release_prefixes
            set -l tarball_name "$p-v$v"
            set -l url "$b/$tarball_name.tar.gz"

            if curl -L --output /dev/null --silent --fail -r 0-0 "$url"
                echo $url
                break
            end
        end
    end
end

function _yvm_postinstall -d "Write version to file and modify fish_user_paths"
    set -l version_to_install $argv

    if test -e "$yvm_fish_data/version"
        read -l last <"$yvm_fish_data/version"

        if set -l i (contains -i -- "$yvm_fish_data/$last/bin" $fish_user_paths)
            set -e fish_user_paths[$i]
        end
    end

    echo $version_to_install >$yvm_fish_data/version

    if not contains -- "$yvm_fish_data/$version_to_install/bin" $fish_user_paths
        set -g fish_user_paths "$yvm_fish_data/$version_to_install/bin" $fish_user_paths
    end
end

function _yvm_use
    set -l options (fish_opt -s f -l force-fetch)
    argparse $options -- $argv

    set -l version_to_install "$argv"

    if test -d "$yvm_fish_data/$version_to_install"
        _yvm_postinstall $version_to_install
        return 0
    end

    _yvm_get_releases "$_flag_f" || return 1

    if test $version_to_install = "latest"
        set version_to_install (cat $yvm_releases | head -n 1 | awk '{ print $1 }')
    end

    if not grep -q "^$version_to_install" $yvm_releases
        echo "Version $version_to_install not found. Consider running \"yvm ls\" and check that the version is correct."
        return 1
    end

    if not test -d "$yvm_fish_data/$version_to_install"
        set -l url (_yvm_get_url_for_version $version_to_install)

        if test -z "$url"
            echo "Couldn't generate a valid tarball URL"
            echo -e "Maybe you are offline, or the version you're trying to install needs to be built from source?"
            echo "Check the yarn releases page https://github.com/yarnpkg/yarn/releases"
            echo "Sorry :("
            return 1
        end

        echo "fetching $url..." >&2

        set -l temp_dir (mktemp -d -t "yvm-yarn-$version_to_install-XXXXXXXXXXXXX")
        set -l temp_file (mktemp "yvm-yarn-$version_to_install-tarball-XXXXXXXXXX")

        if not curl -L --fail --progress-bar $url -o $temp_file 2>/dev/null
            rm -rf $temp_dir
            rm $temp_file

            echo "Couldn't download the tarball from url:"
            echo "$url"
            echo "Are you offline?"
            return 1
        end

        mkdir -p "$yvm_fish_data/$version_to_install/"

        tar -xzf $temp_file -C $temp_dir

        set -l yarn_pkg_path (find $temp_dir -maxdepth 1 -mindepth 1 -type d)
        mv $yarn_pkg_path/* "$yvm_fish_data/$version_to_install/"

        rm -r $temp_dir
        rm $temp_file
    end

    if not test -d "$yvm_fish_data/$version_to_install/"
        echo "Failed to install yarn version \"$version_to_install\", but curl didn't error. Please report this bug."
        return 1
    else
        _yvm_postinstall $version_to_install
    end
end

function _yvm_rm
    set -l options (fish_opt -s f -l force-fetch)
    argparse $options -- $argv

    _yvm_get_releases "$_flag_f" || return 1

    set -l yarn_version $argv[1]
    read -l active_version <"$yvm_fish_data/version"

    if test $yarn_version = "latest"
        set yarn_version (cat $yvm_releases | head -n 1 | awk '{ print $1 }')
    end

    if test -n "$active_version"
        and test "$active_version" = "$yarn_version"
        echo "" >"$yvm_fish_data/version"
    end

    if set -l i (contains -i -- "$yvm_fish_data/$yarn_version/bin" $fish_user_paths)
        set -e fish_user_paths[$i]
    end

    if not test -d "$yvm_fish_data/$yarn_version/"
        echo "No version \"$yarn_version\" found on file system in \"$yvm_fish_data/$yarn_version/\""
    else
        rm -r "$yvm_fish_data/$yarn_version/"
    end

    return 0
end

function _yvm_ls
    set -l options (fish_opt -s f -l force-fetch)
    argparse $options -- $argv

    _yvm_get_releases "$_flag_f" || return 1
    set -l yarn_version

    if test -f "$yvm_fish_data/version"
        read yarn_version <"$yvm_fish_data/version"
    end

    set -l seen

    # https://github.com/jorgebucaran/fish-cookbook#how-do-i-read-from-a-file-in-fish
    while read -la release
        # Some releases are listed twice
        if contains $release $seen
          continue
        end
        set -a seen $release

        set -l parts (string split " " $release)
        set -l release_version $parts[1]
        set -l is_installed 0

        if test -d "$yvm_fish_data/$release_version"
            set is_installed 1
        end

        echo -n $release_version

        if test "$is_installed" -eq 1
            echo -n \t "installed"
        end

        if test -n $yarn_version
            and test "$yarn_version" = "$release_version"
            echo -n \t "active"
        end

        echo \t
    end <$yvm_releases
end

function _yvm_help
    echo "usage: yvm help/--help/-h   Show this help"
    echo "       yvm --version        Show the current version of yvm"
    echo "       yvm use <version>    Download <version> and modify PATH to use it."
    echo "                            Needs to be the exact version from ls."
    echo "       yvm ls/list          List all versions including if they're installed and/or active"
    echo "       yvm rm               Remove specified version from file system and PATH."
    echo "                            Needs to be the exact version from ls."
    echo "       -f/--force-fetch     Force fetch the releases from remote before \"use\" or \"ls\""
    echo "                            Release data is cached for 120 seconds"
    echo ""
    echo "examples:"
    echo "       yvm use 1.17.3"
    echo "       yvm use latest"
    echo "       yvm ls"
    echo "       yvm ls -f"
end
