# Load SSH keys from macOS keychain into the agent on first shell after reboot.
# The fish-ssh-agent plugin manages the agent socket; this just loads stored keys.
if test (uname) = Darwin
    ssh-add --apple-load-keychain 2>/dev/null
end
