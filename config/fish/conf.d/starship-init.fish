# Configure starship for fish automatically
#
# see https://starship.rs/installing/ for installing starship itself

if status --is-interactive
    if type -q starship
       # https://starship.rs/config/
       starship init fish | source

       # https://starship.rs/advanced-config/#transientprompt-and-transientrightprompt-in-fish
       # you will need to define these yourself, since it will be particular to your setup
       # we can detect if they are defined, and enable transience if they are at least
       if type -q starship_transient_prompt_func || type -q starship_transient_rprompt_func
            enable_transience
       end
    end
end
