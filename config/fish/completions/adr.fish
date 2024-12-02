function __fish_adr_commands
  adr --help 2>&1 | sed \
    # delete up to and including: COMMAND is one of:
    -e '1,/^COMMAND/d' \
    # delete "Run 'adr help COMMAND' for help on a specific command." and onwards
    -e '/Run /,$d' \
    # remove leading spaces
    -e 's/^  //'
end


function __fish_adr_numbers
  adr list | sed \
    # delete up to last slash, ie doc/adr/
    -e 's/^.*\///' \
    # delete after first dash, ie -record-architecture-decisions.md
    -e 's/-.*//'
end

complete --no-files --command adr --condition "not __fish_seen_subcommand_from (__fish_adr_commands)" -a new -d 'Creates a new, numbered ADR'
complete --no-files --command adr --condition "not __fish_seen_subcommand_from (__fish_adr_commands)" -a link -d 'Creates a link between two ADRs'
complete --no-files --command adr --condition "not __fish_seen_subcommand_from (__fish_adr_commands)" -a list -d 'List ADRs'
complete --no-files --command adr --condition "not __fish_seen_subcommand_from (__fish_adr_commands)" -a init -d 'Initialize the directory of ADRs'
complete --no-files --command adr --condition "not __fish_seen_subcommand_from (__fish_adr_commands)" -a generate -d 'Generates summary documentation about the ADRs'
complete --no-files --command adr --condition "not __fish_seen_subcommand_from (__fish_adr_commands)" -a upgrade-repository -d 'Upgrades the ADRs to the latest format'

# TODO use __fish_adr_numbers or similar to autocomplete
complete --no-files --command adr --condition "__fish_seen_subcommand_from new" -s l -d 'Links new ADR to a previous ADR' -a '(__fish_adr_numbers)'
complete --no-files --command adr --condition "__fish_seen_subcommand_from new" -s s -d 'A reference (number or partial filename) of a previous decision that the new decision supercedes.' -a '(__fish_adr_numbers)'
# don't autocomplete on file names for new command
complete --no-files --command adr --condition "__fish_seen_subcommand_from new"
complete --no-files --command adr --condition "__fish_seen_subcommand_from help" -a "(__fish_adr_commands)"
# complete --no-files --command adr -s h -l help -d 'print help'
