# Buildkite Status Troubleshooting

Common errors when working with Buildkite and how to resolve them.

## MCP Tool Errors

### Error: "job not found"

**When**: Calling `buildkite:get_logs`

**Cause**: Using step ID from URL instead of job UUID from API

**Solution**:

1. Call `buildkite:get_build` with `detail_level: "detailed"`
2. Find job by `label` field
3. Extract `uuid` field (NOT the `id` field)
4. Use that UUID in `get_logs`

**Example**:

```javascript
// ❌ Wrong - using step ID from URL
mcp__MCPProxy__call_tool('buildkite:get_logs', {
  job_id: '019a5f23-8109-4656-a033-bd62a82ca239', // This is a step ID
});

// ✅ Correct - get job UUID from API first
const build = await mcp__MCPProxy__call_tool('buildkite:get_build', {
  org_slug: 'gusto',
  pipeline_slug: 'payroll-building-blocks',
  build_number: '29627',
  detail_level: 'detailed',
});

const job = build.jobs.find(
  (j) => j.label === 'ste rspec' && j.state === 'failed'
);

await mcp__MCPProxy__call_tool('buildkite:get_logs', {
  org_slug: 'gusto',
  pipeline_slug: 'payroll-building-blocks',
  build_number: '29627',
  job_id: job.uuid, // This is the correct job UUID
});
```

**See Also**: [url-parsing.md](url-parsing.md) for step ID vs job UUID explanation

---

### Error: "build not found" or "pipeline not found"

**When**: Calling any MCP tool

**Cause**: Incorrect org slug or pipeline slug format

**Common Mistakes**:

- Using repository name instead of pipeline slug
- Including org name in pipeline slug
- Using display name instead of URL slug

**Solution**:
Extract slugs from URL correctly:

```
https://buildkite.com/gusto/payroll-building-blocks/builds/123
                        ^^^^^ ^^^^^^^^^^^^^^^^^^^^^^
                        org   pipeline slug
```

**Slug Format Rules**:

- All lowercase
- Hyphens instead of underscores
- No spaces
- No special characters

**Example**:

```javascript
// ❌ Wrong
{ org_slug: "Gusto", pipeline_slug: "Payroll Building Blocks" }

// ✅ Correct
{ org_slug: "gusto", pipeline_slug: "payroll-building-blocks" }
```

---

### Error: Empty logs returned

**When**: Calling `buildkite:get_logs`

**Causes**:

1. Job hasn't started yet
2. Job is still running
3. Job failed before producing output
4. Logs not available yet (eventual consistency)

**Diagnosis**:
Check job state first:

```javascript
const build = await mcp__MCPProxy__call_tool('buildkite:get_build', {
  detail_level: 'detailed',
});

const job = build.jobs.find((j) => j.uuid === jobUuid);
console.log(job.state); // Should be terminal: passed/failed/canceled
console.log(job.started_at); // Should not be null
console.log(job.finished_at); // Should not be null for terminal state
```

**Solution**:

- If state is `waiting` or `running`: Wait for job to complete
- If state is terminal but logs empty: Wait a few seconds for eventual consistency
- If still empty: Job may have failed immediately (check exit_status)

---

### Error: "Unauthorized" or "Forbidden"

**When**: Any MCP tool call

**Cause**: Authentication or permission issue

**Diagnosis Steps**:

1. Check MCP server configuration:

   ```bash
   # MCP server should have BUILDKITE_API_TOKEN configured
   ```

2. Verify token has correct scope:

   - `read_builds` - Required for reading build info
   - `read_build_logs` - Required for log retrieval
   - `read_pipelines` - Required for pipeline listing

3. Check organization access:
   - Token must have access to the specific organization
   - Some orgs require SSO

**Solution**:

- Verify BUILDKITE_API_TOKEN in MCP config
- Generate new token at https://buildkite.com/user/api-access-tokens
- Ensure token has required scopes
- Report to human partner if still failing (may need org admin help)

---

## bktide CLI Errors

### Error: "bktide: command not found"

**Cause**: bktide not installed or not in PATH

**Solution**:
Use MCP tools instead (preferred):

```javascript
// Instead of: npx bktide build gusto/payroll-building-blocks/123
mcp__MCPProxy__call_tool('buildkite:get_build', {
  org_slug: 'gusto',
  pipeline_slug: 'payroll-building-blocks',
  build_number: '123',
});
```

Or install bktide:

```bash
npm install -g @anthropic/bktide
```

---

### Error: "Cannot read logs with bktide"

**Cause**: bktide does not have log retrieval capability

**Solution**:
Use MCP tools for logs:

```javascript
mcp__MCPProxy__call_tool('buildkite:get_logs', {
  org_slug: 'gusto',
  pipeline_slug: 'payroll-building-blocks',
  build_number: '123',
  job_id: '<job-uuid>',
});
```

**See Also**: [tool-capabilities.md](tool-capabilities.md) for complete capability matrix

---

## Script Errors

### Error: Script fails with "bktide error"

**Cause**: Scripts depend on bktide internally

**Solution**:

1. Use equivalent MCP tool instead (preferred)
2. Or ensure bktide is installed and configured
3. Or check `BK_TOKEN` environment variable is set

**Example**:

```bash
# Script failing
~/.claude/skills/buildkite-status/scripts/wait-for-build.js gusto payroll-building-blocks 123

# Use MCP tool instead
mcp__MCPProxy__call_tool("buildkite:wait_for_build", {
  org_slug: "gusto",
  pipeline_slug: "payroll-building-blocks",
  build_number: "123",
  timeout: 1800,
  poll_interval: 30
})
```

---

## Build State Confusion

### Issue: Many jobs show "broken" but build looks healthy

**Cause**: "broken" doesn't mean failed - it usually means skipped

**Explanation**:
Buildkite uses "broken" state for:

- Jobs skipped because dependency failed
- Jobs skipped due to conditional logic
- Jobs skipped because file changes didn't affect them

**Solution**:
Filter for actual failures:

```javascript
mcp__MCPProxy__call_tool('buildkite:get_build', {
  detail_level: 'detailed',
  job_state: 'failed', // Only show actually failed jobs
});
```

**See Also**: [buildkite-states.md](buildkite-states.md) for complete state explanations

---

### Issue: Build shows "failed" but all jobs passed

**Cause**: A "soft_failed" job counts as passed in job list but failed for build state

**Solution**:
Check for soft failures:

```javascript
const build = await mcp__MCPProxy__call_tool('buildkite:get_build', {
  detail_level: 'detailed',
});

const softFails = build.jobs.filter((j) => j.soft_failed === true);
console.log(softFails); // These caused build to fail but are marked non-blocking
```

---

## Common Workflow Issues

### Issue: Cannot find recent build for branch

**Cause**: Build may be filtered or pipeline has many builds

**Solution**:
Use branch filter and increase limit:

```javascript
mcp__MCPProxy__call_tool('buildkite:list_builds', {
  org_slug: 'gusto',
  pipeline_slug: 'payroll-building-blocks',
  branch: 'my-feature-branch',
  per_page: 20, // Default may be smaller
});
```

Or find by commit:

```bash
~/.claude/skills/buildkite-status/scripts/find-commit-builds.js gusto <commit-sha>
```

---

### Issue: Multiple jobs have same label, can't tell which failed

**Cause**: Parallelized jobs have same base label

**Solution**:
Jobs with same label are numbered:

- "rspec (1/10)"
- "rspec (2/10)"

Match on full label including partition:

```javascript
const failedJob = build.jobs.find(
  (j) => j.label === 'rspec (2/10)' && j.state === 'failed'
);
```

Or find all failed jobs with that label:

```javascript
const failedRspecJobs = build.jobs.filter(
  (j) => j.label.startsWith('rspec (') && j.state === 'failed'
);
```

---

## Decision Tree: What to Do When Stuck

```
Unable to investigate build failure?
│
├─ Can't get build details
│  ├─ Check URL format → [url-parsing.md]
│  ├─ Check org/pipeline slugs → lowercase, hyphenated
│  └─ Check auth → BUILDKITE_API_TOKEN configured
│
├─ Can't get job logs
│  ├─ Using bktide? → Use MCP tools instead [tool-capabilities.md]
│  ├─ Getting "job not found"? → Using step ID instead of job UUID [url-parsing.md]
│  ├─ Empty logs? → Check job state (started_at, finished_at)
│  └─ Still failing? → Report to human partner (may be auth/permission)
│
├─ Confused about job states
│  ├─ Many "broken" jobs? → Normal, means skipped [buildkite-states.md]
│  ├─ "soft_failed"? → Failed but non-blocking
│  └─ Can't find failed job? → Filter with job_state: "failed"
│
└─ Tool not working
   ├─ MCP tool error? → Check auth, verify slugs
   ├─ bktide error? → Use MCP tools instead
   └─ Script error? → Use MCP tools directly
```

## See Also

- [SKILL.md](../SKILL.md) - Main skill documentation
- [tool-capabilities.md](tool-capabilities.md) - What each tool can do
- [url-parsing.md](url-parsing.md) - Understanding URLs and IDs
- [buildkite-states.md](buildkite-states.md) - Build and job states
