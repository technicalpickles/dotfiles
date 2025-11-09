# Buildkite URL Parsing Reference

This document explains Buildkite URL formats and how to extract information from them.

## URL Formats

Buildkite uses several URL patterns for builds and jobs:

### Build URL (Most Common)

```
https://buildkite.com/{org}/{pipeline}/builds/{number}
```

Example:

```
https://buildkite.com/gusto/payroll-building-blocks/builds/29627
```

Extracting:

- `org`: "gusto"
- `pipeline`: "payroll-building-blocks"
- `number`: "29627"

### Step/Job URL (From Build Page)

```
https://buildkite.com/{org}/{pipeline}/builds/{number}/steps/{view}?sid={step-id}
```

Example:

```
https://buildkite.com/gusto/payroll-building-blocks/builds/29627/steps/canvas?sid=019a5f23-8109-4656-a033-bd62a82ca239
```

Extracting:

- `org`: "gusto"
- `pipeline`: "payroll-building-blocks"
- `number`: "29627"
- `view`: "canvas" (UI view type)
- `sid`: "019a5f23-8109-4656-a033-bd62a82ca239" (step ID)

**IMPORTANT**: The `sid` (step ID) is NOT the same as job UUID. See "Step IDs vs Job UUIDs" below.

### Job Detail URL

```
https://buildkite.com/{org}/{pipeline}/builds/{number}/jobs/{job-uuid}
```

Example:

```
https://buildkite.com/gusto/payroll-building-blocks/builds/29627/jobs/019a5f20-2d30-4c67-9edd-87fb92e1f487
```

Extracting:

- `org`: "gusto"
- `pipeline`: "payroll-building-blocks"
- `number`: "29627"
- `job-uuid`: "019a5f20-2d30-4c67-9edd-87fb92e1f487"

**NOTE**: This format contains the actual job UUID needed for log retrieval.

## Step IDs vs Job UUIDs

**Critical distinction**: Buildkite has two types of identifiers that are easily confused.

### Step IDs

- **Source**: Query parameter `sid` in step URLs
- **Format**: ULID format (e.g., `019a5f23-8109-4656-a033-bd62a82ca239`)
- **Purpose**: Frontend UI routing
- **Use**: Navigating to specific steps in web UI
- **API Usage**: ❌ NOT accepted by MCP tools

### Job UUIDs

- **Source**: `uuid` field in API responses
- **Format**: ULID format (e.g., `019a5f20-2d30-4c67-9edd-87fb92e1f487`)
- **Purpose**: Backend job identification
- **Use**: API calls to get logs, job details, etc.
- **API Usage**: ✅ Required by MCP `get_logs` tool

### Why the Confusion?

Both use ULID format (starts with `019a5f...`), but:

- Step IDs come from URLs → Web UI routing
- Job UUIDs come from API responses → Backend identification

**You cannot use a step ID for log retrieval.** Always get job UUID from `buildkite:get_build` API.

## Resolving Step ID to Job UUID

When given a step URL with `sid` parameter:

**Step 1: Extract build identifiers**

```javascript
// From: https://buildkite.com/gusto/payroll-building-blocks/builds/29627/steps/canvas?sid=019a5f23...
const org = 'gusto';
const pipeline = 'payroll-building-blocks';
const build = '29627';
// Ignore the sid parameter
```

**Step 2: Get job details from API**

```javascript
mcp__MCPProxy__call_tool('buildkite:get_build', {
  org_slug: org,
  pipeline_slug: pipeline,
  build_number: build,
  detail_level: 'detailed',
  job_state: 'failed', // If investigating failures
});
```

**Step 3: Match job by properties**

The API response includes all jobs. Match by:

- `label` field (e.g., "ste rspec", "Rubocop")
- `state` field (e.g., "failed")
- `type` field (e.g., "script")
- `step_key` field if available

**Step 4: Extract job UUID**

```javascript
// From API response
const job = response.jobs.find(
  (j) => j.label === 'ste rspec' && j.state === 'failed'
);
const jobUuid = job.uuid; // e.g., "019a5f20-2d30-4c67-9edd-87fb92e1f487"
```

**Step 5: Use job UUID for logs**

```javascript
mcp__MCPProxy__call_tool('buildkite:get_logs', {
  org_slug: org,
  pipeline_slug: pipeline,
  build_number: build,
  job_id: jobUuid, // NOT the step ID from URL
});
```

## Parsing Logic

### Simple Regex Approach

```javascript
function parseBuildkiteUrl(url) {
  // Match build URL pattern
  const buildMatch = url.match(
    /buildkite\.com\/([^/]+)\/([^/]+)\/builds\/(\d+)/
  );

  if (!buildMatch) {
    throw new Error('Invalid Buildkite URL');
  }

  return {
    org: buildMatch[1],
    pipeline: buildMatch[2],
    buildNumber: buildMatch[3],
  };
}

// Usage
const info = parseBuildkiteUrl(
  'https://buildkite.com/gusto/payroll-building-blocks/builds/29627'
);
// => { org: "gusto", pipeline: "payroll-building-blocks", buildNumber: "29627" }
```

### Extracting Step ID (If Needed)

```javascript
function parseStepUrl(url) {
  const base = parseBuildkiteUrl(url);

  // Extract step ID from query parameter
  const sidMatch = url.match(/[?&]sid=([^&]+)/);

  return {
    ...base,
    stepId: sidMatch ? sidMatch[1] : null,
  };
}

// Usage
const info = parseStepUrl(
  'https://buildkite.com/gusto/payroll-building-blocks/builds/29627/steps/canvas?sid=019a5f23...'
);
// => { org: "gusto", pipeline: "payroll-building-blocks", buildNumber: "29627", stepId: "019a5f23..." }
```

**Remember**: The `stepId` is useful for debugging but cannot be used for API calls. Always fetch job UUID from the API.

## Common URL Patterns in Practice

### Pattern 1: User Shares Failing Build URL

**URL**: `https://buildkite.com/org/pipeline/builds/123`

**Workflow**:

1. Extract org/pipeline/build
2. Call `get_build` with `detail_level: "summary"`
3. Check build state
4. If failed, call `get_build` with `detail_level: "detailed"` and `job_state: "failed"`
5. Get logs for each failed job

### Pattern 2: User Shares Step URL (Clicked on Specific Job)

**URL**: `https://buildkite.com/org/pipeline/builds/123/steps/canvas?sid=019a5f23...`

**Workflow**:

1. Extract org/pipeline/build (ignore `sid`)
2. Call `get_build` with `detail_level: "detailed"`
3. Find job matching user's intent (often the failed one)
4. Extract job UUID
5. Get logs for that job

The `sid` hints at which job the user was looking at, but you must resolve it via the API.

### Pattern 3: User Provides Job UUID Directly

**URL**: `https://buildkite.com/org/pipeline/builds/123/jobs/019a5f20-...`

**Workflow**:

1. Extract org/pipeline/build/job-uuid
2. Call `get_logs` directly with the job UUID
3. No resolution needed - this is the actual job UUID

This is the ideal format but least common in practice.

## Edge Cases

### Multiple Jobs with Same Label

Some pipelines parallelize jobs:

- "rspec (1/10)"
- "rspec (2/10)"
- "rspec (3/10)"

When resolving, match the full label string including the partition number.

### Dynamic Pipeline Steps

Some pipelines generate steps dynamically. The step structure may not be predictable from the URL alone. Always query the API to see actual job structure.

### Retried Jobs

When jobs are retried, multiple job UUIDs exist for the same step. The API returns the most recent attempt. Check `retries_count` and `retry_source` fields if investigating retry behavior.

## See Also

- [SKILL.md](../SKILL.md) - Main skill documentation
- [tool-capabilities.md](tool-capabilities.md) - Tool limitations and capabilities
- [troubleshooting.md](troubleshooting.md) - Common errors
