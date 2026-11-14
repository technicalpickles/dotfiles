# prime-agent: telemetry off on every role. On work-coder, hand it the Coder AI
# Bridge token per call. Sorts after dotpickles-role.fish, which sets the role.
# Mirrored in home/.bashrc. See doc/adr/0069-prime-agent-on-work-coder.md.
set -gx PRIME_AGENT_TELEMETRY 0

if test "$DOTPICKLES_ROLE" = work-coder
    function prime-agent --wraps prime-agent --description 'prime-agent with the Coder AI Bridge token'
        set -l settings /etc/claude-code/managed-settings.d/10-coder.json
        if not set -q PRIME_AGENT_CODER_AIGATEWAY_SESSION_TOKEN; and test -r $settings
            set -lx PRIME_AGENT_CODER_AIGATEWAY_SESSION_TOKEN (jq -r '.env.ANTHROPIC_AUTH_TOKEN // empty' $settings)
            command prime-agent $argv
            return $status
        end
        command prime-agent $argv
    end
end
