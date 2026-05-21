# Pitchfork daemon manager
# Adds the cd hook that drives `auto = ["start", "stop"]` in pitchfork.toml
# https://github.com/endevco/pitchfork
if command -q pitchfork
    pitchfork activate fish | source
end
