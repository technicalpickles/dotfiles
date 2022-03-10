# vscode is pretty alright when we're in it
if string match -r -q insider "$TERM_PROGRAM_VERSION" && which code-insiders >/dev/null
    export EDITOR="code-insiders -w"
else if [ "$TERM_PROGRAM" = vscode ] && which code >/dev/null
    set -Ux EDITOR "code -w"
    # use stable while running inside stable
# we like vim. see https://github.com/technicalpickles/pickled-vim for settings
else if which mvim >/dev/null
    set -Ux EDITOR "mvim -f"
else if which -s vim >/dev/null
    set -Ux EDITOR vim
else if which -s vi >/dev/null
    set -Ux EDITOR vi
end