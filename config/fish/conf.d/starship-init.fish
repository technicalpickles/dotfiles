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
       starship init fish | source
    end
end
