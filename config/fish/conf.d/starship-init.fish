# Configure startship for fish

# see https://starship.rs/installing/ for installation

if status --is-interactive
    if type -q starship
       # https://starship.rs/config/
       starship init fish | source

       # https://starship.rs/advanced-config/#transientprompt-and-transientrightprompt-in-fish
       # define these yourself, since it will be 
       if type -q starship_transient_prompt_func || type -q starship_transient_rprompt_func
            enable_transience
       end
    end
end
