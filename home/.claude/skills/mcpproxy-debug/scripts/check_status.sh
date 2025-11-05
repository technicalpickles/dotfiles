#!/bin/bash
# Quick health check for MCPProxy

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== MCPProxy Health Check ==="
echo

# Check if mcpproxy is running
echo -n "Process Status: "
if pgrep -x "mcpproxy" > /dev/null; then
  echo -e "${GREEN}Running${NC}"
  ps aux | grep mcpproxy | grep -v grep | head -1
else
  echo -e "${RED}Not Running${NC}"
  exit 1
fi
echo

# Get API key from config
API_KEY=$(grep '"api_key"' ~/.mcpproxy/mcp_config.json 2> /dev/null | cut -d'"' -f4 || echo "")

if [ -z "$API_KEY" ]; then
  echo -e "${YELLOW}Warning: No API key found in config${NC}"
  echo "Checking logs for auto-generated key..."
  API_KEY=$(grep "api_key_prefix" ~/Library/Logs/mcpproxy/main.log 2> /dev/null | tail -1 | grep -o '"api_key":"[^"]*"' | cut -d'"' -f4 || echo "")
fi

if [ -z "$API_KEY" ]; then
  echo -e "${RED}Error: Could not find API key${NC}"
  exit 1
fi

# Check server status via API
echo "Server Status:"
RESPONSE=$(curl -s -H "X-API-Key: $API_KEY" "http://127.0.0.1:8080/api/v1/servers" 2> /dev/null)

if [ -z "$RESPONSE" ]; then
  echo -e "${RED}Error: API returned empty response${NC}"
  exit 1
fi

if echo "$RESPONSE" | python3 -c "import sys, json; data=json.load(sys.stdin); exit(0 if data.get('success', False) else 1)" 2> /dev/null; then
  # Parse and display server info
  echo "$RESPONSE" | python3 << 'PYTHON'
import sys, json

data = json.load(sys.stdin)
stats = data.get('data', {}).get('stats', {})
servers = data.get('data', {}).get('servers', [])

print(f"  Total Servers: {stats.get('total_servers', 0)}")
print(f"  Connected: {stats.get('connected_servers', 0)}")
print(f"  Quarantined: {stats.get('quarantined_servers', 0)}")
print(f"  Total Tools: {stats.get('total_tools', 0)}")
print(f"  Docker Containers: {stats.get('docker_containers', 0)}")
print()

if servers:
    print("Servers:")
    for server in servers:
        status_icon = "✓" if server.get('connected') else "✗"
        name = server.get('name', 'unknown')
        status = server.get('status', 'unknown')
        tools = server.get('tool_count', 0)
        error = server.get('last_error', '')

        print(f"  {status_icon} {name}: {status} ({tools} tools)")
        if error:
            print(f"    Error: {error}")
PYTHON
else
  echo -e "${RED}API Error:${NC}"
  echo "$RESPONSE" | python3 -m json.tool 2> /dev/null || echo "$RESPONSE"
  exit 1
fi

echo
echo "=== Docker Containers ==="
docker ps --filter "name=mcpproxy" --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" || echo "None running"

echo
echo -e "${GREEN}Health check complete!${NC}"
