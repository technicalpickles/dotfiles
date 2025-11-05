# Real-World MCPProxy Debugging Examples

This file contains detailed walkthroughs of actual debugging sessions, providing concrete examples of how to diagnose and fix MCPProxy issues.

## Example 1: Buildkite Server - Docker Isolation Conflict

**Date**: October 2025
**Symptom**: Buildkite MCP server failing to connect with "the input device is not a TTY" error
**Server Type**: Docker-based MCP server (`ghcr.io/buildkite/buildkite-mcp-server:latest`)

### Initial Configuration

```json
{
  "name": "buildkite",
  "protocol": "stdio",
  "command": "docker",
  "args": [
    "run",
    "--pull=always",
    "-q",
    "-i",
    "--rm",
    "-e",
    "BUILDKITE_API_TOKEN",
    "ghcr.io/buildkite/buildkite-mcp-server:latest",
    "stdio"
  ],
  "env": {
    "BUILDKITE_API_TOKEN": "${keyring:buildkite_token}"
  },
  "enabled": true,
  "quarantined": false
}
```

### Diagnostic Process

1. **Ran diagnostic script**:

   ```bash
   ~/.claude/skills/mcpproxy-debug/scripts/diagnose_server.sh buildkite
   ```

2. **Key findings from stderr**:

   ```
   "the input device is not a TTY"
   ```

3. **Pattern recognition**: This error typically indicates:

   - Either `-it` flags being used (but config showed `-i` only)
   - OR Docker isolation wrapping a Docker command (Docker-in-Docker)

4. **Checked Docker isolation status**:
   - Global `docker_isolation.enabled` was `true`
   - Server had no explicit isolation override
   - MCPProxy was wrapping the Docker command in another container

### Root Cause

Docker isolation was enabled globally, and MCPProxy was attempting to run:

```
docker run [isolation-wrapper-args] docker run [server-args] ...
```

This creates a Docker-in-Docker situation where the inner Docker command can't allocate a TTY because it's running inside a container.

### Solution

Added explicit isolation disable to the server configuration:

```json
{
  "name": "buildkite",
  "protocol": "stdio",
  "command": "docker",
  "args": [
    "run",
    "--pull=always",
    "-q",
    "-i",
    "--rm",
    "-e",
    "BUILDKITE_API_TOKEN",
    "ghcr.io/buildkite/buildkite-mcp-server:latest",
    "stdio"
  ],
  "env": {
    "BUILDKITE_API_TOKEN": "${keyring:buildkite_token}"
  },
  "isolation": {
    "enabled": false
  },
  "enabled": true,
  "quarantined": false
}
```

### Verification

After restarting mcpproxy:

1. **Process inspection**:

   ```bash
   ps aux | grep mcpproxy
   ```

   Confirmed the buildkite server was now running directly:

   ```
   docker run --cidfile ... --pull=always -q -i --rm -e BUILDKITE_API_TOKEN ghcr.io/buildkite/buildkite-mcp-server:latest stdio
   ```

2. **Connection verification**:

   ```bash
   ~/.claude/skills/mcpproxy-debug/scripts/diagnose_server.sh buildkite
   ```

   Output showed:

   ```
   Successfully connected and initialized
   server_name: "buildkite-mcp-server"
   server_version: "0.7.2"
   tool_count: 28
   ```

3. **No more TTY errors** in recent logs

### Key Lessons

1. **Docker isolation auto-skip may fail**: The intended automatic skip for Docker commands didn't work in this case
2. **Always explicitly disable isolation for Docker commands**: Best practice to prevent Docker-in-Docker issues
3. **Stderr is the most revealing**: The "TTY" error in stderr immediately pointed to the issue
4. **The diagnostic script is highly effective**: Automated pattern detection caught the problem immediately

### Applicable to Other Servers

This same issue and solution applies to any Docker-based MCP server:

- `ghcr.io/github/github-mcp-server`
- `ghcr.io/sooperset/mcp-atlassian:latest`
- Any custom Docker image serving MCP

**Template solution**:

```json
{
  "name": "any-docker-mcp-server",
  "command": "docker",
  "args": ["run", "-i", "--rm", "-e", "ENV_VAR", "image:tag"],
  "isolation": {
    "enabled": false
  }
}
```

## Example 2: API Key Mismatch After Restart

**Symptom**: API calls return "Invalid or missing API key" after restarting mcpproxy

### Diagnostic Process

1. **Check config file API key**:

   ```bash
   grep '"api_key"' ~/.mcpproxy/mcp_config.json
   ```

   Result: `"api_key": "d380462e333f25a1c61bad1d5d3f673277d5167dcdba18954effc7d6f0401c37"`

2. **API call with config key fails**:

   ```bash
   curl -H "X-API-Key: d380462e333f25a1c61bad1d5d3f673277d5167dcdba18954effc7d6f0401c37" \
     http://127.0.0.1:8080/api/v1/servers
   ```

   Result: `{"success": false, "error": "Invalid or missing API key"}`

3. **Check logs for API key source**:
   ```bash
   grep -i "api.*key" ~/Library/Logs/mcpproxy/main.log | tail -10
   ```
   Result: `API key authentication enabled | {"source": "environment variable", "api_key_prefix": "9fc1****ee1c"}`

### Root Cause

The `MCPPROXY_API_KEY` environment variable was set (likely by the tray app), which takes precedence over the config file. The actual API key was `9fc15eb0...` (different from config).

### Solution

Use the environment variable key or unset the environment variable:

**Option 1**: Use the actual key from logs

```bash
# Extract from log prefix
grep "api_key_prefix" ~/Library/Logs/mcpproxy/main.log | tail -1
```

**Option 2**: Unset environment variable to use config file

```bash
unset MCPPROXY_API_KEY
pkill mcpproxy
open /Applications/mcpproxy.app
```

### Key Lesson

Always check both environment variables and config file when debugging API authentication. Environment variables take precedence.

## Pattern: Missing Package Name in uvx/npx

**Error**: `unexpected argument '--some-flag' found`

**Example**:

```json
// WRONG
{"command": "uvx", "args": ["--local-timezone", "America/New_York"]}

// CORRECT
{"command": "uvx", "args": ["mcp-server-time", "--local-timezone", "America/New_York"]}
```

**Diagnostic**: Check stderr in server logs for "unexpected argument" errors, then verify args array has package name first.

## Pattern: Context Deadline Exceeded

**Error**: `MCP initialize failed: transport error: context deadline exceeded`

**Common Causes**:

1. Missing package name (uvx/npx) - check stderr for "unexpected argument"
2. Docker TTY issue - check stderr for "not a TTY"
3. Server crashed on startup - check stderr for stack traces
4. Environment variables missing - check stderr for "missing" or "required"

**Diagnostic Workflow**:

```bash
# 1. Check stderr for actual error
grep "stderr" ~/Library/Logs/mcpproxy/server-{SERVER_NAME}.log | tail -20

# 2. Check if server started at all
grep "Starting connection" ~/Library/Logs/mcpproxy/server-{SERVER_NAME}.log | tail -5

# 3. Check Docker container if isolation enabled
docker ps | grep mcpproxy
docker logs CONTAINER_ID
```
