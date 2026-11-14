function coder --wraps coder --description 'coder, with a Mocha theme swap around `coder ssh`'
    if test "$argv[1]" != ssh
        command coder $argv
        return $status
    end

    ghostty-theme catppuccin-mocha
    command coder $argv
    set -l s $status
    ghostty-theme reset
    return $s
end
