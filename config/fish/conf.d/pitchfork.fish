# Pitchfork daemon manager -- shell integration intentionally NOT activated.
# https://github.com/endevco/pitchfork
#
# `pitchfork activate fish` installs a PWD handler that calls `pitchfork cd` on
# every directory change. Its only job is driving `auto = ["start", "stop"]`, and
# that cost ~60-100ms on every single cd (about two thirds of a 153ms cd).
#
# It also tied daemon lifetime to shell presence, so any transient fish in a
# project (agent session, script, one-off command) would start its daemons and
# stop them again one autostop_delay later. pickleton's pt-serve bounced three
# times in one afternoon that way.
#
# Daemons that should always be up now use `boot_start = true` instead, which the
# supervisor honours at login via the LaunchAgent (`supervisor run --boot`). See
# pickleton docs/pitchfork.md. Start things by hand with `pitchfork start <name>`.
#
# To re-enable: `pitchfork activate fish | source`
