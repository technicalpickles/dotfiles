#!/bin/bash
# Diagnose a specific MCP server following mcpproxy-debug skill workflow
# Usage: ./diagnose_server.sh <server-name>

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <server-name>"
  echo "Example: $0 buildkite"
  exit 1
fi

SERVER_NAME="$1"
LOG_FILE="$HOME/Library/Logs/mcpproxy/server-${SERVER_NAME}.log"

# Check if log file exists (Linux fallback)
if [ ! -f "$LOG_FILE" ]; then
  LOG_FILE="$HOME/.mcpproxy/logs/server-${SERVER_NAME}.log"
fi

if [ ! -f "$LOG_FILE" ]; then
  echo "Error: Log file not found for server '$SERVER_NAME'"
  echo "Checked locations:"
  echo "  - ~/Library/Logs/mcpproxy/server-${SERVER_NAME}.log (macOS)"
  echo "  - ~/.mcpproxy/logs/server-${SERVER_NAME}.log (Linux)"
  exit 1
fi

echo "=== MCPProxy Server Diagnosis: $SERVER_NAME ==="
echo

# Step 1: Check connection status
echo "Step 1: Connection Status"
echo "-------------------------"
grep -i "connected\|error\|failed" ~/Library/Logs/mcpproxy/main.log 2> /dev/null | grep "$SERVER_NAME" | tail -5 \
  || grep -i "connected\|error\|failed" ~/.mcpproxy/logs/main.log 2> /dev/null | grep "$SERVER_NAME" | tail -5 \
  || echo "No recent connection status found in main log"
echo

# Step 2: Check for stderr messages (most revealing)
echo "Step 2: Recent stderr output (shows actual errors)"
echo "---------------------------------------------------"
grep "stderr" "$LOG_FILE" | tail -10
echo

# Step 3: Check for error patterns
echo "Step 3: Error Pattern Detection"
echo "--------------------------------"

if grep -q "unexpected argument" "$LOG_FILE"; then
  echo "❌ Found: 'unexpected argument' error"
  echo "   → Likely cause: Missing package name for uvx/npx"
  echo "   → Fix: Add package name as first argument"
  echo
fi

if grep -q "not a TTY" "$LOG_FILE"; then
  echo "❌ Found: 'input device is not a TTY' error"
  echo "   → Likely cause: Using -it flag with Docker"
  echo "   → Fix: Use -i only (not -it) for stdin pipe"
  echo
fi

if grep -q "context deadline exceeded" "$LOG_FILE"; then
  echo "❌ Found: 'context deadline exceeded' error"
  echo "   → Likely cause: Server failed to initialize within timeout"
  echo "   → Check stderr above for specific reason"
  echo
fi

if grep -q "Successfully connected" "$LOG_FILE"; then
  echo "✅ Server successfully connected at some point"
  grep "Successfully connected" "$LOG_FILE" | tail -1
  echo
fi

# Step 4: Check Docker container status
echo "Step 4: Docker Container Status"
echo "--------------------------------"
if docker ps --filter "name=mcpproxy-${SERVER_NAME}" --format "{{.Names}}\t{{.Status}}\t{{.Image}}" 2> /dev/null | grep -q .; then
  docker ps --filter "name=mcpproxy-${SERVER_NAME}" --format "{{.Names}}\t{{.Status}}\t{{.Image}}"
else
  echo "No running Docker container found for $SERVER_NAME"
fi
echo

# Step 5: Recent log activity
echo "Step 5: Last 10 log entries"
echo "----------------------------"
tail -10 "$LOG_FILE"
echo

echo "=== End of Diagnosis ==="
