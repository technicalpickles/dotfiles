---
name: mcpproxy-debug
description: This skill should be used when debugging, configuring, or troubleshooting MCPProxy (smart-mcp-proxy/mcpproxy-go). It provides workflows for checking server status, diagnosing connection failures, fixing configuration issues, and understanding Docker isolation behavior.
---

# MCPProxy Debug

## Overview

MCPProxy is a Go-based smart proxy for Model Context Protocol (MCP) servers. This skill provides comprehensive debugging workflows, configuration patterns, and troubleshooting procedures for MCPProxy deployments.

## Core Concepts

### Architecture

- **Core Server** (`mcpproxy`): Headless HTTP API server at `127.0.0.1:8080` (default)
- **Tray Application** (`mcpproxy-tray`): Optional GUI management interface
- **Data Directory**: `~/.mcpproxy/` - contains config, database, logs, and search index
- **Configuration**: `~/.mcpproxy/mcp_config.json` - main configuration file
- **Logs**: `~/Library/Logs/mcpproxy/` (macOS) or `~/.mcpproxy/logs/` (Linux)

### Key Files

- `mcp_config.json` - Server configuration and settings
- `config.db` - BBolt database for persistence (locked when mcpproxy is running)
- `index.bleve/` - Full-text search index for tool discovery
- `main.log` - Main application log
- `server-{name}.log` - Per-server logs

## Debugging Workflows

### 1. Check Server Status

**When to use**: Start here for any MCPProxy issue. Verify basic connectivity and server state.

```bash
# Check if mcpproxy is running
ps aux | grep mcpproxy | grep -v grep

# Check server status via API
curl -H "X-API-Key: YOUR_API_KEY" http://127.0.0.1:8080/api/v1/servers | python3 -m json.tool

# Alternative: Use query parameter for API key
curl "http://127.0.0.1:8080/api/v1/servers?apikey=YOUR_API_KEY" | python3 -m json.tool

# Find current API key in config
grep '"api_key"' ~/.mcpproxy/mcp_config.json

# Or check recent logs for auto-generated key
grep -i "api.*key\|API.*key" ~/Library/Logs/mcpproxy/main.log | tail -5
```

**Key status fields**:

- `connected`: Boolean - is the server connected?
- `status`: String - current state (connecting, ready, error)
- `last_error`: String - most recent error message
- `tool_count`: Number - how many tools are available
- `retry_count`: Number - connection retry attempts

### 2. Diagnose Connection Failures

**When to use**: When an MCP server shows `connected: false` or has errors.

#### Step 1: Check server-specific logs

```bash
# List all server logs
ls -lhrt ~/Library/Logs/mcpproxy/server-*.log | tail -10

# Check specific server log (most recent 50 lines)
tail -50 ~/Library/Logs/mcpproxy/server-{SERVER_NAME}.log

# Check for errors
grep -i "error\|failed\|stderr" ~/Library/Logs/mcpproxy/server-{SERVER_NAME}.log | tail -20
```

#### Step 2: Look for common error patterns

**Pattern: "unexpected argument found"** (uvx/npx specific)

- **Cause**: Arguments passed to wrong command (e.g., passing server args to `uvx` instead of the package)
- **Commands affected**: `uvx`, `npx`, `yarn dlx`, `bunx`
- **Fix**: Ensure package name comes first in args array
- **Real example**:

  ```json
  // WRONG - Error: "unexpected argument '--local-timezone' found"
  {"command": "uvx", "args": ["--local-timezone", "America/New_York"]}

  // CORRECT - Package name first, then its args
  {"command": "uvx", "args": ["mcp-server-time", "--local-timezone", "America/New_York"]}
  ```

**Pattern: "the input device is not a TTY"** (Docker specific)

- **Cause 1**: Using `-it` flags with Docker when MCPProxy needs stdin pipe only
- **Cause 2**: Docker isolation is wrapping a Docker command (Docker-in-Docker conflict)
- **Commands affected**: `docker run`
- **Fix for Cause 1**: Use `-i` (stdin) without `-t` (TTY allocation)

  ```json
  // WRONG - Error: "the input device is not a TTY"
  {"command": "docker", "args": ["run", "-it", "--rm", "image:tag"]}

  // CORRECT - Only -i for stdin pipe
  {"command": "docker", "args": ["run", "-i", "--rm", "image:tag"]}
  ```

- **Fix for Cause 2**: Explicitly disable isolation for Docker-based servers
  ```json
  {
    "command": "docker",
    "args": ["run", "-i", "--rm", "image:tag"],
    "isolation": {
      "enabled": false
    }
  }
  ```
- **Why**: MCPProxy communicates via stdio pipes, not terminal TTY sessions. Docker isolation may wrap Docker commands despite intended auto-skip logic.

**Pattern: "context deadline exceeded" / "transport error"**

- **Cause**: Server failed to start or initialize within timeout
- **Common reasons**:
  - Missing package name in args (for uvx/npx) - check stderr for "unexpected argument"
  - Docker `-it` instead of `-i` - check stderr for "not a TTY"
  - Docker image not found or pulling failed - check stderr for "pull" or "not found"
  - Server crashed during startup - check stderr for stack traces or error messages
  - Network issues (for HTTP servers) - check for connection refused/timeout
  - Missing environment variables - check stderr for "missing" or "required"
- **Investigation**:

  ```bash
  # Check stderr output in server log (most revealing)
  grep "stderr" ~/Library/Logs/mcpproxy/server-{SERVER_NAME}.log | tail -20
  
  # Check Docker logs if isolation is enabled
  docker ps | grep mcpproxy
  docker logs CONTAINER_ID
  
  # Check if process started at all
  grep "Docker isolation setup\|Starting connection" ~/Library/Logs/mcpproxy/server-{SERVER_NAME}.log | tail -5
  ```

**Pattern: "database is locked"**

- **Cause**: Another mcpproxy instance is running
- **Fix**: Kill all mcpproxy instances before starting
  ```bash
  pkill mcpproxy
  # Wait a moment, then restart
  open /Applications/mcpproxy.app
  ```

#### Step 3: Check Docker isolation (if enabled)

```bash
# List MCPProxy containers
docker ps | grep mcpproxy

# Check specific container logs
docker logs -f CONTAINER_NAME

# Check if container exited
docker ps -a | grep mcpproxy

# See Docker command being used
grep "docker_run_args\|container_command" ~/Library/Logs/mcpproxy/server-{SERVER_NAME}.log | tail -5
```

### 3. Fix Configuration Issues

**When to use**: When adding new servers or updating configuration.

#### Configuration Structure for MCP Servers

**Command-Specific Patterns**:

**uvx/npx servers** (Package managers):

```json
{
  "name": "server-name",
  "protocol": "stdio",
  "command": "uvx", // or "npx"
  "args": [
    "package-name", // CRITICAL: Package name MUST be first
    "--arg1",
    "value1", // Then package arguments
    "--arg2",
    "value2"
  ],
  "enabled": true
}
```

**Docker servers** (Pre-built images):

```json
{
  "name": "server-name",
  "protocol": "stdio",
  "command": "docker",
  "args": [
    "run",
    "-i", // CRITICAL: Use -i (not -it) for stdin pipe
    "--rm", // Clean up container after exit
    "-e",
    "VAR_NAME", // Pass environment variables
    "image:tag", // Image name
    "subcommand" // Optional: server subcommand (e.g., "stdio")
  ],
  "env": {
    "VAR_NAME": "value" // Values for -e flags
  },
  "isolation": {
    "enabled": false // CRITICAL: Disable isolation for Docker commands
  },
  "enabled": true
}
```

**Stdio Servers (uvx, npx, local commands)**:

```json
{
  "name": "server-name",
  "protocol": "stdio",
  "command": "uvx", // or "npx", "python", etc.
  "args": [
    "package-name", // Package name FIRST
    "--arg1",
    "value1", // Then server arguments
    "--arg2",
    "value2"
  ],
  "env": {
    // Optional environment variables
    "API_KEY": "secret"
  },
  "working_dir": "/path/to/dir", // Optional working directory
  "enabled": true,
  "quarantined": false
}
```

**HTTP/SSE Servers**:

```json
{
  "name": "http-server",
  "protocol": "http", // or "sse"
  "url": "https://api.example.com/mcp",
  "headers": {
    // Optional headers
    "Authorization": "Bearer token"
  },
  "enabled": true,
  "quarantined": false
}
```

**Docker-based Servers**:

```json
{
  "name": "docker-server",
  "protocol": "stdio",
  "command": "docker",
  "args": [
    "run",
    "-i",
    "--rm",
    "-e",
    "API_KEY=secret", // Environment vars in Docker args
    "image:tag"
  ],
  "isolation": {
    "enabled": false // CRITICAL: Disable isolation for Docker commands
  },
  "enabled": true,
  "quarantined": false
}
```

#### Common Configuration Mistakes

1. **Missing package name for uvx/npx**

   - Symptom: "unexpected argument found" error
   - Fix: Add package name as first arg

2. **Wrong protocol for server type**

   - Symptom: Connection hangs or fails
   - Fix: Use "stdio" for commands, "http"/"sse" for URLs

3. **Quarantined server**

   - Symptom: Tools return security analysis instead of executing
   - Fix: Set `"quarantined": false` in config

4. **Docker isolation interfering with Docker commands**

   - Symptom: "the input device is not a TTY" error for Docker-based servers
   - Fix: Add `"isolation": {"enabled": false}` to the server config
   - **IMPORTANT**: Always disable isolation for Docker-based MCP servers to prevent Docker-in-Docker conflicts

5. **Docker isolation interfering with file access**
   - Symptom: Local file paths not accessible, permission errors
   - Fix: Either disable isolation for that server, or mount volumes

#### Trigger Configuration Reload

After editing config:

```bash
# Option 1: Touch the config file to trigger file watcher
touch ~/.mcpproxy/mcp_config.json

# Option 2: Restart mcpproxy
pkill mcpproxy && open /Applications/mcpproxy.app

# Option 3: Check if reload happened
grep -i "config.*reload\|upstream.*config.*changed" ~/Library/Logs/mcpproxy/main.log | tail -3
```

### 4. Docker Isolation Debugging

**When to use**: When Docker isolation is enabled and servers are failing to start.

#### Understanding Docker Isolation

MCPProxy can run stdio MCP servers in Docker containers for security isolation.

**How it works**:

1. Detects runtime (uvx→Python, npx→Node.js, etc.)
2. Selects appropriate Docker image
3. Wraps command in `docker run`
4. Tracks container lifecycle

**Configuration**:

```json
{
  "docker_isolation": {
    "enabled": true,
    "memory_limit": "512m",
    "cpu_limit": "1.0",
    "timeout": "30s",
    "default_images": {
      "uvx": "python:3.11",
      "npx": "node:20",
      "python": "python:3.11"
    }
  }
}
```

#### Check Docker Isolation Status

```bash
# See if isolation is enabled for a server
grep -i "docker isolation enabled\|docker isolation setup" ~/Library/Logs/mcpproxy/server-{SERVER_NAME}.log | tail -5

# Check the actual Docker command being executed
grep "docker_run_args" ~/Library/Logs/mcpproxy/main.log | tail -3

# List running containers
docker ps | grep mcpproxy

# Check container health
docker inspect --format='{{.State.Status}}' CONTAINER_ID
```

#### Docker Context (Colima Support)

MCPProxy uses the system's default Docker context. For Colima:

```bash
# Check current Docker context
docker context show

# List available contexts
docker context ls

# MCPProxy will use whichever context is marked with *
# To change: docker context use colima-PROFILE
```

#### Disable Docker Isolation

**Per-server** (in config):

```json
{
  "name": "server-name",
  "isolation": {
    "enabled": false
  }
}
```

**Globally** (in config):

```json
{
  "docker_isolation": {
    "enabled": false
  }
}
```

#### Docker-in-Docker Prevention

MCPProxy is intended to automatically skip isolation for Docker commands, but this auto-detection may fail. **Best practice**: Always explicitly disable isolation for Docker-based servers:

```json
{
  "command": "docker",
  "args": ["run", "-i", "--rm", "image:tag"],
  "isolation": {
    "enabled": false // Explicitly disable to prevent Docker-in-Docker
  }
}
```

**Why explicit is better**: The auto-skip logic may not catch all cases, leading to "the input device is not a TTY" errors. Explicit configuration prevents these issues.

### 5. View Available Tools

**When to use**: Verify a server is providing tools correctly.

```bash
# Via API (requires API key)
curl -H "X-API-Key: YOUR_API_KEY" "http://127.0.0.1:8080/api/v1/tools" | python3 -m json.tool

# Via API with query param
curl "http://127.0.0.1:8080/api/v1/tools?apikey=YOUR_API_KEY" | python3 -m json.tool

# Check tool count in logs
grep "tool_count" ~/Library/Logs/mcpproxy/main.log | tail -10

# Check tool indexing
grep -i "discovered tools\|indexing tools" ~/Library/Logs/mcpproxy/main.log | tail -5
```

### 6. Environment Variables and API Keys

**MCPProxy respects these environment variables**:

- `MCPPROXY_LISTEN` - Override bind address (e.g., `:8080`, `127.0.0.1:9091`)
- `MCPPROXY_API_KEY` - Set API key for REST API (overrides config file)
- `MCPPROXY_DEBUG` - Enable debug mode
- `HEADLESS` - Run without launching browser

**API Key Priority** (highest to lowest):

1. `MCPPROXY_API_KEY` environment variable (if set)
2. `api_key` field in `~/.mcpproxy/mcp_config.json`
3. Auto-generated key (logged on startup if neither above is set)

**Finding the current API key**:

```bash
# Check if environment variable is set (takes precedence)
echo $MCPPROXY_API_KEY

# From config file (second priority)
grep '"api_key"' ~/.mcpproxy/mcp_config.json

# From logs (shows which source was used)
grep -i "api key" ~/Library/Logs/mcpproxy/main.log | grep -i "environment\|config\|auto-generated" | tail -3

# Look for API key prefix in logs (for verification)
grep "api_key_prefix" ~/Library/Logs/mcpproxy/main.log | tail -1
```

**Common API Key Issue**: If API calls fail after restart with "Invalid or missing API key", check if `MCPPROXY_API_KEY` environment variable is set. The tray app may set this, causing it to differ from the config file value.

## Quick Reference Commands

### Essential Checks

```bash
# Status check
curl -s "http://127.0.0.1:8080/api/v1/servers?apikey=$(grep api_key ~/.mcpproxy/mcp_config.json | cut -d'"' -f4)" | python3 -m json.tool

# Latest errors across all servers
tail -100 ~/Library/Logs/mcpproxy/main.log | grep ERROR

# Connection attempts in progress
grep -i "connecting\|attempting" ~/Library/Logs/mcpproxy/main.log | tail -10

# Docker containers
docker ps --filter "name=mcpproxy" --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
```

### Restart Procedures

```bash
# Clean restart
pkill mcpproxy
sleep 2
open /Applications/mcpproxy.app

# Verify restart
sleep 5
ps aux | grep mcpproxy | grep -v grep
```

### Log Investigation

```bash
# Tail main log with filters
tail -f ~/Library/Logs/mcpproxy/main.log | grep -v "Status updated"

# Tail specific server
tail -f ~/Library/Logs/mcpproxy/server-{SERVER_NAME}.log

# Find all errors in last hour
find ~/Library/Logs/mcpproxy/ -name "*.log" -mmin -60 -exec grep -l ERROR {} \;

# See recent connection state changes
grep -i "state transition\|connected\|error" ~/Library/Logs/mcpproxy/main.log | tail -20
```

## Common Issues and Solutions

### Issue: "the input device is not a TTY" for Docker-based MCP server

**Symptom**: Docker MCP server shows "the input device is not a TTY" error in logs and fails to connect.

**Root Cause**: Docker isolation is attempting to wrap a Docker command in another Docker container (Docker-in-Docker).

**Solution**: Add explicit isolation disable to the server config:

```json
{
  "name": "your-docker-server",
  "command": "docker",
  "args": ["run", "-i", "--rm", "image:tag"],
  "isolation": {
    "enabled": false
  }
}
```

After editing config, restart mcpproxy: `pkill mcpproxy && open /Applications/mcpproxy.app`

### Issue: "Server not connecting after config change"

**Solution**: Config file watcher might not have triggered. Touch the file or restart mcpproxy.

### Issue: "Tools showing 0 despite server being connected"

**Solution**: Check tool indexing in logs. May need to wait for periodic refresh (every 15 minutes) or restart.

### Issue: "Docker containers piling up"

**Solution**: MCPProxy should clean up containers automatically. If not:

```bash
docker ps -a | grep mcpproxy
docker rm -f $(docker ps -a -q --filter "name=mcpproxy")
```

### Issue: "Can't access local files from Docker isolated server"

**Solution**: Either disable isolation for that server, or the server needs to use URLs/APIs instead of file paths.

### Issue: "Different API key on each restart"

**Solution**: Set `api_key` in config file or use `MCPPROXY_API_KEY` environment variable to persist it.

### Issue: "Invalid or missing API key" after restart

**Solution**: Check if `MCPPROXY_API_KEY` environment variable is set, as it overrides the config file. The tray app may set this. Get the current key from logs: `grep "api_key_prefix" ~/Library/Logs/mcpproxy/main.log | tail -1`

## Resources

### references/

Additional documentation for deeper investigation:

**`debugging-examples.md`** - Real-world debugging walkthroughs

- Detailed case studies from actual debugging sessions
- Complete diagnostic workflows with root cause analysis
- Pattern recognition guides for common failure modes
- Use when encountering complex issues that need detailed investigation

### scripts/

Helper scripts for common debugging tasks:

**`check_status.sh`** - Quick health check

- Checks if mcpproxy is running
- Displays server status and connection info
- Shows Docker containers
- Usage: `~/.claude/skills/mcpproxy-debug/scripts/check_status.sh`

**`get_api_key.sh`** - Extract current API key

- Checks config file first
- Falls back to log file if needed
- Usage: `API_KEY=$(~/.claude/skills/mcpproxy-debug/scripts/get_api_key.sh)`

**`diagnose_server.sh`** - Comprehensive server diagnosis

- Checks connection status in main log
- Extracts stderr messages (most revealing)
- Detects common error patterns automatically
- Shows Docker container status
- Usage: `~/.claude/skills/mcpproxy-debug/scripts/diagnose_server.sh <server-name>`
- Example: `~/.claude/skills/mcpproxy-debug/scripts/diagnose_server.sh buildkite`

**`compare_servers.sh`** - Compare working vs broken server

- Shows config differences side-by-side
- Compares connection status
- Compares stderr output
- Compares Docker container status
- Usage: `~/.claude/skills/mcpproxy-debug/scripts/compare_servers.sh <working-server> <broken-server>`
- Example: `~/.claude/skills/mcpproxy-debug/scripts/compare_servers.sh glean buildkite`

All scripts work on both macOS (`~/Library/Logs/mcpproxy/`) and Linux (`~/.mcpproxy/logs/`).
