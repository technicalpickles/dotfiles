# Init starship prompt
#
# doc: https://starship.rs
# Quick install: `curl -fsSL https://starship.rs/install.sh | bash`
 
# if not type -q starship
#     curl -fsSL https://starship.rs/install.sh -o /tmp/starship-install.sh
#     mkdir -p ~/.local/bin
#     bash /tmp/starship-install.sh -b $HOME/.local/bin -y
#     rm /tmp/starship-install.sh
# end

if status --is-interactive
    if type -q starship
        set -l ctx (set -q DOTPICKLES_ROLE; and echo $DOTPICKLES_ROLE; or echo personal)
        if test -f /.dockerenv; or test -n "$REMOTE_CONTAINERS"; or test -n "$CODESPACES"
            set -gx STARSHIP_CTX "$ctx | devcontainer"
        else
            set -gx STARSHIP_CTX $ctx
        end

        starship init fish | source
    end
end
