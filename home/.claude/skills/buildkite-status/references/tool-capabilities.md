# Tool Capabilities Reference

This document provides complete capability information for all Buildkite status checking tools.

## Overview

Three tool categories exist with different strengths and limitations:

1. **MCP Tools** - Direct Buildkite API access via Model Context Protocol
2. **bktide CLI** - Human-readable command-line tool (npm package)
3. **Bundled Scripts** - Helper wrappers in this skill's `scripts/` directory

## Capability Matrix

| Capability            | MCP Tools                       | bktide                  | Scripts                    | Notes                      |
| --------------------- | ------------------------------- | ----------------------- | -------------------------- | -------------------------- |
| List organizations    | ✅ `buildkite:list_orgs`        | ❌                      | ❌                         |                            |
| List pipelines        | ✅ `buildkite:list_pipelines`   | ✅ `bktide pipelines`   | ❌                         |                            |
| List builds           | ✅ `buildkite:list_builds`      | ✅ `bktide builds`      | ✅ `find-commit-builds.js` | Scripts are specialized    |
| Get build details     | ✅ `buildkite:get_build`        | ✅ `bktide build`       | ❌                         |                            |
| Get annotations       | ✅ `buildkite:list_annotations` | ✅ `bktide annotations` | ❌                         |                            |
| **Retrieve job logs** | **✅ `buildkite:get_logs`**     | **❌ NO**               | **✅ `get-build-logs.js`** | **bktide cannot get logs** |
| Get log metadata      | ✅ `buildkite:get_logs_info`    | ❌                      | ❌                         |                            |
| List artifacts        | ✅ `buildkite:list_artifacts`   | ❌                      | ❌                         |                            |
| Wait for build        | ✅ `buildkite:wait_for_build`   | ❌                      | ✅ `wait-for-build.js`     | MCP preferred              |
| Unblock jobs          | ✅ `buildkite:unblock_job`      | ❌                      | ❌                         |                            |
| Real-time updates     | ✅                              | ❌                      | ✅                         | Via polling                |
| Human-readable output | ❌ (JSON)                       | ✅                      | Varies                     |                            |
| Works offline         | ❌                              | ❌                      | ❌                         | All need network           |
| Requires auth         | ✅ (MCP config)                 | ✅ (BK_TOKEN)           | ✅ (uses bktide)           |                            |

## Detailed Tool Information

### MCP Tools (Primary)

**Access Method:** `mcp__MCPProxy__call_tool("buildkite:<tool>", {...})`

**Authentication:** Configured in MCP server settings (typically uses `BUILDKITE_API_TOKEN`)

**Pros:**

- Complete API coverage
- Always available (no external dependencies)
- Real-time data
- Structured JSON responses

**Cons:**

- Verbose JSON output
- Requires parsing for human reading

**Key Tools:**

#### `buildkite:get_build`

Get detailed build information including job states, timing, and metadata.

Parameters:

- `org_slug` (required): Organization slug
- `pipeline_slug` (required): Pipeline slug
- `build_number` (required): Build number
- `detail_level` (optional): "summary" | "detailed" | "complete"
- `job_state` (optional): Filter jobs by state ("failed", "passed", etc.)

Returns: Build object with jobs array, state, timing, author, etc.

#### `buildkite:get_logs`

**THE CRITICAL TOOL** - Retrieve actual log output from a job.

Parameters:

- `org_slug` (required): Organization slug
- `pipeline_slug` (required): Pipeline slug
- `build_number` (required): Build number
- `job_id` (required): Job UUID (NOT step ID from URL)

Returns: Log text content

**Common Issues:**

- "job not found" → Using step ID instead of job UUID
- Empty response → Job hasn't started or finished yet

#### `buildkite:wait_for_build`

Poll build until completion.

Parameters:

- `org_slug` (required): Organization slug
- `pipeline_slug` (required): Pipeline slug
- `build_number` (required): Build number
- `timeout` (optional): Seconds until timeout (default: 1800)
- `poll_interval` (optional): Seconds between checks (default: 30)

Returns: Final build state when complete or timeout

### bktide CLI (Secondary)

**Access Method:** `npx bktide <command>`

**Authentication:** `BK_TOKEN` environment variable or `~/.bktide/config`

**Pros:**

- Human-readable colored output
- Intuitive command structure
- Good for interactive terminal work

**Cons:**

- External npm dependency
- **CANNOT retrieve job logs** (most critical limitation)
- Limited compared to full API
- Requires npx/node installed

**Key Commands:**

```bash
npx bktide pipelines <org>                    # List pipelines
npx bktide builds <org>/<pipeline>            # List recent builds
npx bktide build <org>/<pipeline>/<number>    # Build details
npx bktide build <org>/<pipeline>/<number> --jobs  # Show job summary
npx bktide build <org>/<pipeline>/<number> --failed # Show failed jobs only
npx bktide annotations <org>/<pipeline>/<number>    # Show annotations
```

**Critical**: bktide has NO command for retrieving logs. The `build` command shows job states and names, but NOT log content.

### Bundled Scripts (Tertiary)

**Access Method:** `~/.claude/skills/buildkite-status/scripts/<script>.js`

**Authentication:** Use bktide internally (requires `BK_TOKEN`)

**Pros:**

- Purpose-built for specific workflows
- Handle common use cases automatically
- Provide structured output

**Cons:**

- Depend on bktide (external dependency)
- Limited to specific use cases
- May have version compatibility issues

**Available Scripts:**

#### `find-commit-builds.js`

Find builds matching a specific commit SHA.

Usage:

```bash
~/.claude/skills/buildkite-status/scripts/find-commit-builds.js <org> <commit-sha>
```

Returns: JSON array of matching builds

#### `wait-for-build.js`

Monitor build until completion (background-friendly).

Usage:

```bash
~/.claude/skills/buildkite-status/scripts/wait-for-build.js <org> <pipeline> <build> [options]
```

Options:

- `--timeout <seconds>`: Max wait time (default: 1800)
- `--interval <seconds>`: Poll interval (default: 30)

Exit codes:

- 0: Build passed
- 1: Build failed
- 2: Build canceled
- 3: Timeout

#### `get-build-logs.js` (NEW - to be implemented)

Retrieve logs for a failed job with automatic UUID resolution.

Usage:

```bash
~/.claude/skills/buildkite-status/scripts/get-build-logs.js <org> <pipeline> <build> <job-label-or-uuid>
```

Features:

- Accepts job label or UUID
- Automatically resolves label → UUID
- Handles step ID confusion
- Formats output for readability

## Decision Matrix: Which Tool to Use

### Use MCP Tools When:

- Getting build details
- **Retrieving job logs** (ONLY option with bktide)
- Waiting for builds (preferred over script)
- Unblocking jobs
- Automating workflows
- Need structured data

### Use bktide When:

- Interactive terminal work
- Want human-readable summary
- Listing pipelines/builds
- Getting quick status overview
- **NOT when you need logs** (it can't do this)

### Use Scripts When:

- Need specialized workflow (find commits)
- Want background monitoring
- MCP tools fail (fallback)
- Automating repetitive tasks

## Common Mistakes

### ❌ Trying to get logs with bktide

**Don't**: `npx bktide build <org>/<pipeline>/<number> --logs`

**Why**: This flag doesn't exist. bktide cannot retrieve logs.

**Do**: Use `buildkite:get_logs` MCP tool

### ❌ Using step ID for log retrieval

**Don't**: Extract `sid=019a5f...` from URL and use directly

**Why**: Step IDs ≠ Job UUIDs. MCP tools need job UUIDs.

**Do**: Call `buildkite:get_build` to get job details, extract `uuid` field

### ❌ Abandoning MCP tools when script fails

**Don't**: "Script failed, I'll use GitHub instead"

**Why**: Scripts depend on bktide. MCP tools are independent.

**Do**: Use MCP tools directly when scripts fail

## Troubleshooting

### Issue: "job not found" when calling get_logs

**Diagnosis**: Using step ID instead of job UUID

**Solution**:

1. Call `buildkite:get_build` with `detail_level: "detailed"`
2. Find job by `label` field
3. Extract `uuid` field
4. Use that UUID in `get_logs` call

### Issue: bktide command not found

**Diagnosis**: npm/npx not installed or not in PATH

**Solution**:

1. Use MCP tools instead (preferred)
2. Or install: `npm install -g @anthropic/bktide`

### Issue: Empty logs returned

**Diagnosis**: Job hasn't completed or logs not available yet

**Solution**:

1. Check job `state` - should be terminal (passed/failed/canceled)
2. Wait for job to finish
3. Check job `started_at` and `finished_at` timestamps

## See Also

- [SKILL.md](../SKILL.md) - Main skill documentation
- [troubleshooting.md](troubleshooting.md) - Common errors and solutions
- [url-parsing.md](url-parsing.md) - Understanding Buildkite URLs
