# Pitchfork daemon manager
# Adds the cd hook that drives `auto = ["start", "stop"]` in pitchfork.toml
# https://github.com/endevco/pitchfork
if command -q pitchfork
    # `pitchfork activate fish` emits the __pitchfork PWD handler and then calls it
    # eagerly. That call is a ~60ms blocking round-trip to the supervisor and nothing
    # in the shell reads its result, so strip it and fire the same call in the
    # background instead (measured 583ms -> 467ms startup). Backgrounding the
    # __pitchfork *function* instead of the binary only bought ~20ms -- fish forks
    # the whole shell state for that, which costs about as much as it saves.
    #
    # The PWD handler stays synchronous: backgrounding it would let rapid cds land
    # out of order and leave the supervisor tracking a stale directory.
    #
    # This duplicates activate's invocation, so if upstream changes the args this
    # silently no-ops -- the PWD handler still fires on the first cd, so the worst
    # case is the initial directory not being reported.
    pitchfork activate fish | string match --invert --regex '^__pitchfork$' | source

    pitchfork cd --shell-pid $fish_pid >/dev/null 2>&1 &
    disown
end
