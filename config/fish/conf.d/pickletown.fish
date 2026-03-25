# Pickletown workspace manager
# Adds ~/pickleton/cli/bin to PATH so `pickletown` and `pt` are available
if test -d "$HOME/pickleton/cli/bin"
    fish_add_path --global "$HOME/pickleton/cli/bin"
end
