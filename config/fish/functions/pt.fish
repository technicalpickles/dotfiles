# Alias for pickletown CLI
# Provides short `pt` alias since the command was renamed to avoid PATH conflicts
# with tcllib's pt parser tool (/opt/homebrew/bin/pt)
function pt --description 'Pickletown workspace manager (alias)'
    pickletown $argv
end
