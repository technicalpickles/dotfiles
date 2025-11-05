#!/bin/bash
# Compare two servers (one working, one broken) to find differences
# Usage: ./compare_servers.sh <working-server> <broken-server>

set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: $0 <working-server-name> <broken-server-name>"
  echo "Example: $0 glean buildkite"
  exit 1
fi

WORKING="$1"
BROKEN="$2"

echo "=== Comparing Servers: $WORKING (working) vs $BROKEN (broken) ==="
echo

# Compare configurations
echo "Configuration Comparison"
echo "------------------------"
echo "Working server ($WORKING):"
grep -A 15 "\"name\": \"$WORKING\"" ~/.mcpproxy/mcp_config.json | head -20
echo
echo "Broken server ($BROKEN):"
grep -A 15 "\"name\": \"$BROKEN\"" ~/.mcpproxy/mcp_config.json | head -20
echo

# Compare connection status
echo "Connection Status Comparison"
echo "----------------------------"
echo "$WORKING status:"
grep "$WORKING" ~/Library/Logs/mcpproxy/main.log 2> /dev/null | grep -i "connected\|initialized" | tail -3 \
  || grep "$WORKING" ~/.mcpproxy/logs/main.log 2> /dev/null | grep -i "connected\|initialized" | tail -3 \
  || echo "No connection info found"
echo

echo "$BROKEN status:"
grep "$BROKEN" ~/Library/Logs/mcpproxy/main.log 2> /dev/null | grep -i "error\|failed" | tail -3 \
  || grep "$BROKEN" ~/.mcpproxy/logs/main.log 2> /dev/null | grep -i "error\|failed" | tail -3 \
  || echo "No error info found"
echo

# Compare stderr output
echo "Stderr Comparison"
echo "-----------------"
echo "$WORKING recent stderr:"
grep "stderr" ~/Library/Logs/mcpproxy/server-${WORKING}.log 2> /dev/null | tail -5 \
  || grep "stderr" ~/.mcpproxy/logs/server-${WORKING}.log 2> /dev/null | tail -5 \
  || echo "No stderr output"
echo

echo "$BROKEN recent stderr:"
grep "stderr" ~/Library/Logs/mcpproxy/server-${BROKEN}.log 2> /dev/null | tail -5 \
  || grep "stderr" ~/.mcpproxy/logs/server-${BROKEN}.log 2> /dev/null | tail -5 \
  || echo "No stderr output"
echo

# Docker container comparison
echo "Docker Container Comparison"
echo "---------------------------"
echo "$WORKING container:"
docker ps --filter "name=mcpproxy-${WORKING}" --format "{{.Names}}\t{{.Status}}\t{{.Image}}" 2> /dev/null || echo "No container"
echo

echo "$BROKEN container:"
docker ps --filter "name=mcpproxy-${BROKEN}" --format "{{.Names}}\t{{.Status}}\t{{.Image}}" 2> /dev/null || echo "No container"
echo

echo "=== Key Differences to Investigate ==="
echo "1. Check 'command' and 'args' differences in config"
echo "2. Check if error patterns match known issues (uvx package, Docker -it)"
echo "3. Check stderr for specific error messages"
echo "4. Check if Docker container is running for working but not broken"
