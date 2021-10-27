set -l devspace_commands \
add \
analyze \
attach \
build \
cleanup \
completion \
connect \
create \
delete \
deploy \
dev \
enter \
generate \
get \
help \
init \
list \
login \
logs \
open \
print \
purge \
remove \
render \
reset \
restart \
restore \
run \
save \
set \
sleep \
sync \
token \
ui \
update \
upgrade \
use \
wakeup

# complete -c devspace -n "not __fish_seen_subcommand_from $devspace_commands" \
#     -a "$devspace_commands"

function __fish_devspace_commands
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
		awk 'BEGIN { FS = "   +" } ; { if ($1 != "") print $1 "\t" $3 }' | \
		# remove leading space
		sed -e 's/^ //'
end

for command in devspace devspace-beta
	complete -f -c $command -n "not __fish_seen_subcommand_from $devspace_commands" -a "$devspace_commands"

	complete -f -c $command -n "__fish_seen_subcommand_from run" \
    -a "(__fish_devspace_commands)"
end