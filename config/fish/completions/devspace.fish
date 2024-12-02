
# complete -c devspace -n "not __fish_seen_subcommand_from $devspace_commands" \
#     -a "$devspace_commands"

function __fish_devspace_commands
  devspace help | sed \
    # delete up to and including Available Commands
    -e '1,/^Available Commands:$/d' \
    # delete Flags and after
    -e '/Flags:/,$d' \
    # delete empty lines
    -e '/^$/d' \
    # remove leading spaces
    -e 's/^  //' | \
    # print tab between command and description
    awk 'BEGIN { FS="  +"}; {print $1 "\t" $2}'
end

function __fish_devspace_run_commands
  devspace list commands | \
    # first 3 lines are whitespace and headers
    tail -n +3 | \
    # output's columns are divided by 3 or more spaces
    # column 1 is the name of the command
    # column 2 is the command
    # column 3 is the description
    #
    # complete takes the first part of its input as a thing to complete
    # then a tab, and then a description of what the command is
    awk 'BEGIN { FS = "  +" } ; { if ($1 != "") print $1 "\t" $3 }' | \
    # remove leading space
    sed -e 's/^ //'
end

for command in devspace devspace-beta
  complete -f -c $command -n "not __fish_seen_subcommand_from $devspace_commands" -a "(__fish_devspace_commands)"

  complete -f -c $command -n "__fish_seen_subcommand_from run" \
    -a "(__fish_devspace_run_commands)"
end
