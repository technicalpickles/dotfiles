# @halostatue/fish-direnv/completions/direnv.fish:v1.1.2

set --local allow_commands allow grant permit
set --local deny_commands block deny revoke
set --local file_commands $allow_commands $deny_commands edit
set --local commands $file_commands exec fetchurl help hook prune reload status \
    stdlib version

complete -ec direnv
complete -c direnv -f -d "unclutter your .profile"
complete -c direnv -n "not __fish_seen_subcommand_from $commands" -a "$commands"

for sub in $allow_commands
    complete -c direnv -n __fish_use_subcommand -a $sub \
        -d "Grants permission to load the given .envrc or .env file."

    complete -c direnv -n "__fish_seen_subcommand_from $sub" -F
end

for sub in $deny_commands
    complete -c direnv -n __fish_use_subcommand -a $sub \
        -d "Removes permission to load the given .envrc or .env file"

    complete -c direnv -n "__fish_seen_subcommand_from $sub" -F
end

complete -c direnv -n __fish_use_subcommand -a edit \
    -d "Opens a config file into \$EDITOR with approval on save"

complete -c direnv -n "__fish_seen_subcommand_from edit" -F

complete -c direnv -n __fish_use_subcommand -a exec \
    -d "Executes a command after loading the first .envrc or .env found in DIR"

complete -c direnv -n "__fish_seen_subcommand_from exec" \
    -a "(__fish_complete_directories)" -d "The directory in which to execute COMMAND"

complete -c direnv -n __fish_use_subcommand -a fetchurl \
    -d "Fetches a given URL into direnv's CAS"

complete -c direnv -n __fish_use_subcommand -a help -d "Shows help for direnv"

complete -c direnv -n __fish_use_subcommand -a hook -d "Used to setup the shell hook"

complete -c direnv -n "__fish_seen_subcommand_from hook" -a "bash zsh fish tcsh elvish"

complete -c direnv -n __fish_use_subcommand -a prune -d "removes old allowed files"

complete -c direnv -n __fish_use_subcommand -a reload -d "Triggers an env reload"

complete -c direnv -n __fish_use_subcommand -a status \
    -d "Prints debug status information"

complete -c direnv -n "__fish_seen_subcommand_from status" -l json \
    -d "Formats debug status information as JSON"

complete -c direnv -n __fish_use_subcommand -a stdlib \
    -d "Displays the stdlib available in the .envrc execution context"

complete -c direnv -n __fish_use_subcommand -a version \
    -d "prints the version or checks that direnv is older than VERSION_AT_LEAST"
