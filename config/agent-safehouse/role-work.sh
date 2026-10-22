# Work-role hook, sourced by bin/safe after the tool's own (ADR 0064). Append to
# SAFE_TOOL_ENV, don't assign it.

# gusto-config fetches secrets from AWS at Rails boot. Export short-lived creds
# here and pass them as env, so ~/.aws (config, and the SSO token cache with its
# refresh secret) stays unreadable inside the sandbox. gusto-config skips the
# profile lookup when AWS_SECRET_ACCESS_KEY is set. Skipped when AWS_PROFILE is
# unset; if the SSO login has lapsed the tool still starts, without creds.
if [ -n "${AWS_PROFILE:-}" ]; then
  if aws_creds=$(aws configure export-credentials --profile "$AWS_PROFILE" --format process 2>&1); then
    AWS_ACCESS_KEY_ID=$(printf '%s' "$aws_creds" | jq -r .AccessKeyId)
    AWS_SECRET_ACCESS_KEY=$(printf '%s' "$aws_creds" | jq -r .SecretAccessKey)
    AWS_SESSION_TOKEN=$(printf '%s' "$aws_creds" | jq -r .SessionToken)
    SAFE_TOOL_ENV="${SAFE_TOOL_ENV:+$SAFE_TOOL_ENV,}AWS_ACCESS_KEY_ID,AWS_SECRET_ACCESS_KEY,AWS_SESSION_TOKEN"
    AWS_REGION="${AWS_REGION:-$(aws configure get region --profile "$AWS_PROFILE")}"
    [ -n "$AWS_REGION" ] && SAFE_TOOL_ENV="$SAFE_TOOL_ENV,AWS_REGION"
  else
    echo "safe: couldn't export AWS credentials for $AWS_PROFILE:" >&2
    echo "$aws_creds" >&2
    echo "Try: aws sso login --profile $AWS_PROFILE" >&2
  fi
  unset aws_creds
fi

# SAFE_DOCKER=1 lets the tool reach colima's docker daemon. Root-equivalent in
# the VM (it can bind-mount any shared host path), so it's opt-in. Grants
# connect() on the one socket: safehouse's --enable=docker would open all of
# ~/.docker and ~/.colima (VM disks, ssh keys). DOCKER_CONFIG is a copy of
# ~/.docker/config.json minus `auths`.
if [ "${SAFE_DOCKER:-}" = 1 ] && [ -n "$SAFE_TOOL_ROOT" ]; then
  docker_sock="${SAFE_DOCKER_SOCK:-$HOME/.colima/gusto/docker.sock}"
  safe_profile_add "(allow file-read* (literal \"$docker_sock\"))"
  safe_profile_add "(allow network-outbound (remote unix-socket (path-literal \"$docker_sock\")))"
  mkdir -p "$SAFE_TOOL_ROOT/docker-config"
  if [ -f "$HOME/.docker/config.json" ]; then
    jq 'del(.auths)' "$HOME/.docker/config.json" > "$SAFE_TOOL_ROOT/docker-config/config.json"
  else
    echo '{}' > "$SAFE_TOOL_ROOT/docker-config/config.json"
  fi
  DOCKER_HOST="unix://$docker_sock"
  DOCKER_CONFIG="$SAFE_TOOL_ROOT/docker-config"
  SAFE_TOOL_ENV="${SAFE_TOOL_ENV:+$SAFE_TOOL_ENV,}DOCKER_HOST,DOCKER_CONFIG"
fi
