# prime-agent profile, sourced by bin/safe (ADR 0064). Agent state (sessions,
# settings, skills) is the real ~/.prime/agent, granted in prime-agent.sb, like
# pi's ~/.pi. The daemon socket and kernel venv stay in the tool's private root,
# so the sandboxed daemon never shares a socket with an unsandboxed one and the
# venv (code the tool runs) can't be written for an unsandboxed run to import.
# Callers can preset any PRIME_AGENT_* var to move them.
: "${PRIME_AGENT_DAEMON_SOCKET:=$SAFE_TOOL_ROOT/daemon.sock}"
: "${PRIME_AGENT_KERNEL_VENV:=$SAFE_TOOL_ROOT/kernel-venv}"

# The state dir is created by prime.sh, but this hook runs unsandboxed, so a
# fresh machine works without it: the sandbox can't make ~/.prime itself.
mkdir -p "$HOME/.prime/agent"

# Home logs in with /login (the credential lives in ~/.prime/agent). Other roles
# resolve a provider key with fnox. Set SAFE_FNOX_KEYS (or empty) to change it.
[ "$role" = home ] || : "${SAFE_FNOX_KEYS=OPENROUTER_API_KEY}"

DO_NOT_TRACK=1
# Marks agent sessions for tools that behave differently under an agent; prime-agent sets no marker itself.
AGENT_SESSION=1
# Dotfiles scripts run inside the sandbox pick their role from this.
DOTPICKLES_ROLE=$role

# The daemon socket lives in the private root; session workers bind under
# $TMPDIR/prime-agent-<uid>, or /tmp when that path is too long.
uid=$(id -u)
tmp=$(cd "${TMPDIR:-/tmp}" && pwd -P)
SAFE_SOCKET_DIRS="${SAFE_SOCKET_DIRS:+$SAFE_SOCKET_DIRS:}$(dirname "$PRIME_AGENT_DAEMON_SOCKET"):$tmp/prime-agent-$uid:/private/tmp/prime-agent-$uid"

SAFE_TOOL_ENV="PRIME_AGENT_DAEMON_SOCKET,PRIME_AGENT_KERNEL_VENV,DO_NOT_TRACK,AGENT_SESSION,DOTPICKLES_ROLE"
