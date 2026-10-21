# prime-agent profile, sourced by bin/safe (ADR 0064). Callers can preset any
# PRIME_AGENT_* var to keep state elsewhere.
#
# Without these prime-agent falls back to ~/.prime/agent, which safehouse denies.
: "${PRIME_AGENT_CODING_AGENT_DIR:=$SAFE_TOOL_ROOT/agent}"
: "${PRIME_AGENT_DAEMON_SOCKET:=$PRIME_AGENT_CODING_AGENT_DIR/daemon.sock}"
: "${PRIME_AGENT_KERNEL_VENV:=$PRIME_AGENT_CODING_AGENT_DIR/kernel-venv}"
mkdir -p "$PRIME_AGENT_CODING_AGENT_DIR"

DO_NOT_TRACK=1
# Marks agent sessions for tools that behave differently under an agent; prime-agent sets no marker itself.
AGENT_SESSION=1
# Dotfiles scripts run inside the sandbox pick their role from this.
DOTPICKLES_ROLE=$role

# The daemon socket lives in the state dir; session workers bind under
# $TMPDIR/prime-agent-<uid>, or /tmp when that path is too long.
uid=$(id -u)
tmp=$(cd "${TMPDIR:-/tmp}" && pwd -P)
SAFEHOUSE_ADD_DIRS="$SAFEHOUSE_ADD_DIRS:$PRIME_AGENT_CODING_AGENT_DIR"
SAFE_SOCKET_DIRS="${SAFE_SOCKET_DIRS:+$SAFE_SOCKET_DIRS:}$(dirname "$PRIME_AGENT_DAEMON_SOCKET"):$tmp/prime-agent-$uid:/private/tmp/prime-agent-$uid"

SAFE_XDG_ISOLATE=1
SAFE_TOOL_ENV="PRIME_AGENT_CODING_AGENT_DIR,PRIME_AGENT_DAEMON_SOCKET,PRIME_AGENT_KERNEL_VENV,DO_NOT_TRACK,AGENT_SESSION,DOTPICKLES_ROLE"
