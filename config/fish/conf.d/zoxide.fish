# Initialize zoxide for fish shell
# Replaces the fish z plugin with zoxide
# https://github.com/ajeetdsouza/zoxide
if command -q zoxide
    zoxide init fish | source
end
