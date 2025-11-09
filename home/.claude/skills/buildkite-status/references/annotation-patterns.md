# Buildkite Annotation Patterns

Annotations are build-level messages that appear at the top of a build page. They can contain success messages, warnings, errors, or informational content. **Not all projects use annotations consistently.**

## What Are Annotations?

Annotations are created by build steps using the `buildkite-agent annotate` command. They appear prominently at the top of the build page and can be styled with different colors/icons.

### Annotation Styles

- **`success`** - Green, checkmark icon, positive message
- **`info`** - Blue, info icon, informational message (most common)
- **`warning`** - Yellow, warning icon, something to be aware of
- **`error`** - Red, error icon, indicates problems

## Project-Specific Patterns

### Projects That Use Annotations Heavily (e.g., zen-payroll)

These projects surface important information in annotations:

1. **Test Failures**: RSpec, Jest, or other test failures may be summarized in annotations

   - Failed test count
   - Links to failed test files
   - Stack traces or error messages

2. **Coverage Reports**: Code coverage changes or drops below thresholds

3. **Linting Errors**: Rubocop, ESLint violations grouped by severity

4. **Build Resources**: Links to documentation, help channels, or common issues

5. **Security Scans**: Dependency vulnerabilities, security warnings

6. **Performance Issues**: Slow tests, memory issues, or other performance concerns

**When checking status**: Always look at annotations first for these projects. They often contain the most actionable information.

### Projects Without Annotations (e.g., gusto-karafka)

Smaller or simpler projects may not use annotations at all. For these projects:

- **All failure information is in job logs**: Must read individual job output
- **No centralized summary**: Need to check each failed job separately
- **Simpler debugging path**: Less information to parse, but more manual work

## Accessing Annotations

### Via MCP Tools

```javascript
// List all annotations for a build
mcp__MCPProxy__call_tool('buildkite:list_annotations', {
  org_slug: 'gusto',
  pipeline_slug: 'zenpayroll',
  build_number: '1359675',
});
```

Annotation response includes:

- `context`: Unique identifier for the annotation
- `style`: success/info/warning/error
- `body_html`: HTML content of the annotation
- `created_at`: Timestamp

### Via bktide

```bash
npx bktide annotations gusto/zenpayroll#1359675
```

## Interpreting Annotations

### 1. Start with Error-Styled Annotations

Check for `style: "error"` first - these indicate critical problems:

- Test suite failures
- Build failures
- Security issues

### 2. Check Warning Annotations

`style: "warning"` may indicate:

- Degraded performance
- Coverage drops
- Flaky tests
- Deprecated dependencies

### 3. Info Annotations for Context

`style: "info"` often contains:

- Build metadata
- Links to resources
- Change summaries
- Help information

### 4. Success Annotations

`style: "success"` indicates:

- All tests passed
- Coverage improved
- Performance metrics good

## Common Annotation Patterns

### Test Failure Annotations

Typically include:

```
❌ 15 tests failed

spec/models/user_spec.rb
  - validates email format
  - validates password strength

spec/controllers/api_controller_spec.rb
  - returns 401 when unauthorized
```

**Action**: Read the listed test failures, then examine the job logs for full details.

### Build Resource Annotations

```
Having problems with your build?
- Check build documentation: [link]
- Ask in #build-stability Slack channel
```

**Action**: These are informational - reference them if you're stuck debugging.

### Coverage Annotations

```
⚠️ Code coverage decreased by 2.5%
Current: 85.3% | Previous: 87.8%
```

**Action**: May or may not be actionable depending on project policy.

## When Annotations Are Missing

If a build has no annotations:

1. **Don't assume success**: Check the overall build state
2. **Look at job logs**: All failure information will be in individual jobs
3. **Check job states**: Failed jobs will have `state: "failed"`
4. **Read failed job logs**: Use MCP tools or bktide to get logs

## Inconsistencies Across Projects

Be aware that annotation usage varies wildly:

- **Some projects**: Every failure is annotated
- **Some projects**: Only critical failures annotated
- **Some projects**: No annotations at all
- **Some projects**: Annotations are informational only, not diagnostic

**Never rely solely on annotations.** Always check:

1. Overall build state
2. Job states
3. Annotations (if present)
4. Job logs for failed jobs

## Example Workflows

### Checking a Failed Build With Annotations

1. Get build status → state is `failed`
2. List annotations → find error-styled annotation with test failures
3. Note which tests failed from annotation
4. Get detailed logs for failed job
5. Read stack traces and error messages

### Checking a Failed Build Without Annotations

1. Get build status → state is `failed`
2. Check job summary → identify which jobs failed
3. Get detailed information for each failed job
4. Read logs for each failed job
5. Identify root cause from logs

### Checking a Passing Build

1. Get build status → state is `passed`
2. Optionally check annotations for warnings or info
3. Note any "broken" jobs (may be expected)
4. No need to read logs unless investigating performance
