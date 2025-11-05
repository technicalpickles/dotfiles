#!/bin/bash
# Extract current API key from config or logs

set -euo pipefail

# Try config file first
API_KEY=$(grep '"api_key"' ~/.mcpproxy/mcp_config.json 2> /dev/null | cut -d'"' -f4 || echo "")

if [ -n "$API_KEY" ]; then
  echo "$API_KEY"
  exit 0
fi

# Try logs for auto-generated key
echo "No API key in config, checking logs..." >&2
API_KEY=$(grep -i "api key" ~/Library/Logs/mcpproxy/main.log 2> /dev/null | grep -o '"api_key":"[^"]*"' | tail -1 | cut -d'"' -f4 || echo "")

if [ -n "$API_KEY" ]; then
  echo "$API_KEY"
  exit 0
fi

echo "Error: Could not find API key" >&2
exit 1
