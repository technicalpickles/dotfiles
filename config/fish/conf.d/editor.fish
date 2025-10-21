# Use envsense to detect IDE context if available
# See https://github.com/technicalpickles/envsense for detection logic
if which envsense >/dev/null
    # Get the IDE id once and use it multiple times
    set -l ide_id (envsense info --json 2>/dev/null | jq -r '.traits.ide.id // empty')

    # Check which IDE we're running in and set the appropriate editor
    if test "$ide_id" = cursor && which cursor >/dev/null
        set -gx EDITOR "cursor -w"
    else if test "$ide_id" = vscode-insiders && which code-insiders >/dev/null
        set -gx EDITOR "code-insiders -w"
    else if test "$ide_id" = vscode && which code >/dev/null
        set -gx EDITOR "code -w"
    end
end

# Fallback to terminal editors if no IDE detected or IDE editor not found
# we like vim. see https://github.com/technicalpickles/pickled-vim for settings
if not set -q EDITOR
    if which -s nvim >/dev/null
        set -gx EDITOR nvim
    else if which -s vim >/dev/null
        set -gx EDITOR vim
    else if which -s vi >/dev/null
        set -gx EDITOR vi
    end
end
