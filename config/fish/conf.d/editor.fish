# vscode is pretty alright when we're in it
if string match -r -q insider "$TERM_PROGRAM_VERSION" && command -q code-insiders
    set -gx EDITOR "code-insiders -w"
else if [ "$TERM_PROGRAM" = vscode ] && command -q code
    set -gx EDITOR "code -w"
    # use stable while running inside stable
# we like vim. see https://github.com/technicalpickles/pickled-vim for settings
else if command -q nvim
    set -gx EDITOR nvim
else if command -q vim
    set -gx EDITOR vim
else if command -q vi
    set -gx EDITOR vi
end
