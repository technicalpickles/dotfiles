#!/usr/bin/env bash

set -e

# shellcheck source=./functions.sh
source functions.sh

echo "🐳 configuring docker"
if running_macos && command_available colima; then
  echo "  → checking for running Colima instances"

  # Get list of running Colima instances
  running_instances=$(colima list --json 2> /dev/null | jq -r 'select(.status == "Running") | .name' 2> /dev/null)

  if [ -n "$running_instances" ]; then
    # Use the first running instance (or you could modify this logic)
    instance_name=$(echo "$running_instances" | head -n1)
    echo "  → found running instance: $instance_name"

    # Get the Docker socket from the instance status
    docker_socket=$(colima status "$instance_name" --json 2> /dev/null | jq -r '.docker_socket' 2> /dev/null)

    if [ -n "$docker_socket" ] && [ "$docker_socket" != "null" ]; then
      echo "  → setting DOCKER_HOST to: $docker_socket"

      if command_available fish; then
        fish -c "set --universal --export DOCKER_HOST $docker_socket"
      else
        export DOCKER_HOST="$docker_socket"
      fi
    else
      echo "  → could not determine Docker socket for instance: $instance_name"
    fi
  else
    echo "  → no running Colima instances found"
  fi
fi
