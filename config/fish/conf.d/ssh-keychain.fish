# Load SSH keys from macOS keychain into the agent on first shell after reboot.
# The fish-ssh-agent plugin manages the agent socket; this just loads stored keys.
#
# --apple-load-keychain costs ~750ms of CPU: the stored key is bcrypt-encrypted,
# so ssh-add runs the KDF every time, even when the agent already holds the key.
# `ssh-add -l` answers "is the agent already populated?" for free, which is a good
# enough proxy for "have we done this since boot" -- exit 1 (agent up but empty)
# and exit 2 (no agent at all) both fall through to the load.
if test (uname) = Darwin
    if not ssh-add -l >/dev/null 2>&1
        ssh-add --apple-load-keychain 2>/dev/null
    end
end
