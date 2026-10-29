# prime-agent's models.json (written by the Coder template) reads its AI Gateway token from
# PRIME_AGENT_CODER_AIGATEWAY_SESSION_TOKEN, but the template only sets it when the workspace
# harness is prime_agent. Claude Code's token reaches the same gateway, so borrow it.
# Named prime-* so it sorts after dotpickles-role.fish, which sets DOTPICKLES_ROLE.
# Mirrors home/.bashrc.
if test "$DOTPICKLES_ROLE" = work-coder; and not set -q PRIME_AGENT_CODER_AIGATEWAY_SESSION_TOKEN; and set -q ANTHROPIC_AUTH_TOKEN
    set -gx PRIME_AGENT_CODER_AIGATEWAY_SESSION_TOKEN $ANTHROPIC_AUTH_TOKEN
end
