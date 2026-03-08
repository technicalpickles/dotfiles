# Buildkite Status Skill Improvements

**Date**: 2025-11-07
**Context**: Analysis of transcript from `.specstory/history/2025-11-07_16-42-25Z-warmup.md` where the buildkite-status skill failed to help investigate a CI failure.

## Executive Summary

The buildkite-status skill failed at its primary use case: helping a user investigate a failing build from a Buildkite URL. The skill has good theory (tool hierarchy, progressive disclosure) but **missing critical workflows** for actually retrieving error logs - the most important piece of debugging information.

## Critical Gaps Identified

### 1. No "From URL to Logs" Workflow (CRITICAL)

**Problem**: User provided a Buildkite URL (line 50 of transcript). Agent should have:

1. Parsed URL → extracted org/pipeline/build
2. Got build details → identified failed job
3. **Retrieved error logs** → showed user what failed
4. Helped reproduce locally

**What Happened**: Agent got stuck at step 3. Tried multiple approaches (lines 89-251, 431-673) but never successfully retrieved logs.

**Why Critical**: This is likely the most common entry point for the skill. When a build fails, users share the URL and ask "what went wrong?"

**Fix Required**:

- Add "Investigating a Build from URL" as the FIRST workflow in SKILL.md
- Document step-by-step: URL parsing → build details → job identification → **log retrieval**

### 2. Job Log Retrieval Not Documented (CRITICAL)

**Problem**: The skill mentions checking logs (line 230: "Get logs for actually failed jobs") but provides **zero guidance** on how.

**What Happened**:

- Line 245-250: Tried MCP `buildkite:get_logs` → "job not found" error
- Line 433-673: Tried multiple bktide approaches → discovered bktide has NO logs command
- Line 533-538: Tried direct API access → rejected by hook

**Why Critical**: Without logs, you cannot debug failures. This is the MOST important capability.

**Fix Required**:

- Add "Retrieving Job Logs" section with multiple strategies
- Document fallback chain: MCP tool → bktide (oh wait, it can't) → direct API → manual URL construction
- Add troubleshooting section for "job not found" errors

### 3. Tool Capabilities Not Documented (HIGH PRIORITY)

**Problem**: Skill says "use bktide for convenience" but doesn't document that bktide **cannot retrieve logs**.

**What Happened**:

- Line 652-671: Agent discovers bktide has no logs command
- This is after ~300 lines of trying various approaches
- Agent wasted time trying tool combinations that couldn't work

**Why Important**: Understanding tool limitations prevents wasted effort.

**Fix Required**:

- Create `references/tool-capabilities.md` with a capability matrix:
  ```
  | Capability        | MCP Tools | bktide | Scripts |
  |-------------------|-----------|--------|---------|
  | List builds       | ✅        | ✅     | ✅      |
  | Get build details | ✅        | ✅     | ✅      |
  | Retrieve logs     | ✅        | ❌     | ✅      |
  | Wait for build    | ✅        | ❌     | ✅      |
  ```
- Reference this in the "Tool Hierarchy" section

### 4. Step ID → Job ID Mapping Not Explained (MEDIUM PRIORITY)

**Problem**: User's URL contains `sid=019a5f23-8109-4656-a033-bd62a82ca239` (a step ID). Agent needs a job UUID for log retrieval. The mapping isn't documented.

**What Happened**:

- Line 225-237: Agent extracts step ID from URL
- Line 245-250: Tries to use it directly → fails
- No guidance on how to resolve step ID to job UUID

**Why Important**: Build URLs often include step IDs, but APIs need job UUIDs.

**Fix Required**:

- Create `references/url-parsing.md` documenting:
  - Different URL formats (build URL vs step URL)
  - What step IDs are vs job UUIDs
  - How to resolve: Get build details → filter jobs by properties → find UUID
- Add example workflow showing the resolution

### 5. Fallback Hierarchy is Theoretical (MEDIUM PRIORITY)

**Problem**: Lines 74-88 document a fallback hierarchy, but when tools actually fail, there's no guidance on **debugging tool failures** vs **working around them**.

**What Happened**:

- Line 250: MCP tool fails with "job not found"
- Agent doesn't know if this is:
  - Wrong job ID format?
  - Permissions issue?
  - Tool bug?
  - Should try a different approach?

**Why Important**: Tool failures are part of reality. Skill needs to handle them.

**Fix Required**:

- Add "Troubleshooting Tool Failures" section
- For each common error, document:
  - What it means
  - How to diagnose
  - What to try next
- Example: "job not found" error usually means step ID vs job UUID confusion

## Proposed Skill Structure Changes

### Reorder SKILL.md Workflows

**Current order** (lines 92-238):

1. Checking Current Branch/PR Status
2. Post-Push Monitoring Workflow
3. Investigating Failures
4. Checking Blocked Builds

**Proposed order**:

1. **Investigating a Build from URL** (NEW - most common)
2. **Retrieving Job Logs** (NEW - critical capability)
3. Investigating Failures (existing, but reference log retrieval)
4. Checking Current Branch/PR Status (existing)
5. Post-Push Monitoring Workflow (existing)
6. Checking Blocked Builds (existing)

### New Reference Files

1. **`references/tool-capabilities.md`**

   - Capability matrix for all tools
   - Document what each tool CAN and CANNOT do
   - Referenced from "Tool Hierarchy" section

2. **`references/url-parsing.md`**

   - Buildkite URL formats and structure
   - Step IDs vs Job UUIDs
   - How to extract and resolve identifiers

3. **`references/troubleshooting.md`**
   - Common error messages and what they mean
   - Diagnostic steps for tool failures
   - Fallback strategies when primary methods fail

### New Scripts

1. **`scripts/get-build-logs.js`**

   - Wrapper that tries multiple strategies for log retrieval
   - Handles step ID → job UUID resolution
   - Returns formatted error logs or clear error message

2. **`scripts/parse-buildkite-url.js`**
   - Extracts org/pipeline/build/step from URLs
   - Returns structured JSON
   - Used by other scripts and workflows

## Implementation Priority

### P0 (Blocking - skill is broken without these)

1. Add "Retrieving Job Logs" workflow to SKILL.md
2. Document MCP log retrieval tools with examples
3. Add troubleshooting for "job not found" error

### P1 (High Impact - significantly improves usability)

1. Add "Investigating a Build from URL" as first workflow
2. Create `references/tool-capabilities.md`
3. Create `scripts/get-build-logs.js`

### P2 (Nice to Have - polish)

1. Create `references/url-parsing.md`
2. Create `scripts/parse-buildkite-url.js`
3. Create `references/troubleshooting.md`

## Key Insights from Transcript Analysis

### What Worked

1. **Progressive disclosure concept** - Agent understood to start with build overview
2. **Tool hierarchy awareness** - Agent knew to prefer MCP over GitHub tools
3. **State understanding** - Agent understood "broken" vs "failed" distinction

### What Failed

1. **No executable path to logs** - Theory without implementation
2. **Tool limitations not documented** - Wasted time on impossible approaches
3. **Missing concrete workflows** - Abstract guidance doesn't help when stuck

### Lessons for Skill Design

1. **Document the happy path AND the failure paths** - When tools fail, what next?
2. **Capability documentation is critical** - Don't make Claude discover tool limits
3. **Concrete workflows beat abstract principles** - Step-by-step instructions over philosophy
4. **Most common use case should be first** - "Here's a failing URL, help me" is #1

## Example: What the "Retrieving Job Logs" Section Should Look Like

````markdown
### Retrieving Job Logs

Once you've identified a failed job, you need to retrieve its logs to see the actual error.

**Prerequisites**:

- Build number (from URL or list_builds)
- Job identification (label/name or UUID)

**Step 1: Get the job UUID**

If you have a job label (e.g., "ste rspec"), use get_build with detail_level="detailed":

```javascript
mcp__MCPProxy__call_tool('buildkite:get_build', {
  org_slug: 'gusto',
  pipeline_slug: 'payroll-building-blocks',
  build_number: '29627',
  detail_level: 'detailed',
  job_state: 'failed',
});
```
````

Find the job in the response and extract its `uuid` field.

**Step 2: Retrieve logs using the job UUID**

```javascript
mcp__MCPProxy__call_tool('buildkite:get_logs', {
  org_slug: 'gusto',
  pipeline_slug: 'payroll-building-blocks',
  build_number: '29627',
  job_id: '<job-uuid>',
});
```

**Common Issues**:

- **"job not found" error**: You likely provided a step ID instead of job UUID. Step IDs start with `019a5f...` and come from URLs. Job UUIDs come from the build details API response.

- **Empty logs**: The job may not have started yet, or logs may not be available. Check job state first.

**Fallback Strategy**:

If MCP tools fail, you can construct the log URL manually:

```
https://buildkite.com/{org}/{pipeline}/builds/{build}/jobs/{job-uuid}
```

```

## Validation Questions

Before implementing, validate these assumptions with the user:

1. Is "investigating a build from URL" actually the most common entry point?
2. Are there other log retrieval methods we should document (e.g., gh CLI, direct API tokens)?
3. What are the actual permission/auth requirements for log access?
4. Should we add automated testing for the scripts?

## Success Criteria

The improved skill will succeed when:

1. Given a Buildkite URL, Claude can retrieve error logs in <3 attempts
2. Claude never tries to use bktide for log retrieval
3. When MCP tools fail, Claude follows documented fallback paths
4. Users can successfully reproduce failures locally using retrieved logs

## References

- Original transcript: `.specstory/history/2025-11-07_16-42-25Z-warmup.md`
- Current skill: `~/.claude/skills/buildkite-status/SKILL.md`
- Skill creator guidance: Plugin `example-skills:skill-creator`
```
