# Buildkite Build and Job States

Understanding Buildkite states is critical for correctly interpreting build status. Some states are misleading or require additional context.

## Build States

### Terminal States

- **`passed`** - All jobs completed successfully
- **`failed`** - One or more jobs failed
- **`canceled`** - Build was manually canceled
- **`skipped`** - Build was skipped (e.g., due to branch filters)
- **`blocked`** - Build is waiting for manual approval via block step

### Active States

- **`running`** - Build is currently executing
- **`scheduled`** - Build is queued and waiting to start
- **`creating`** - Build is being created

## Job States

### Terminal States

- **`passed`** - Job completed successfully
- **`failed`** - Job failed with non-zero exit code
- **`canceled`** - Job was canceled
- **`skipped`** - Job was skipped
- **`timed_out`** - Job exceeded time limit

### Special States (Often Misleading)

- **`broken`** - This is the most misleading state. It can mean:

  - Job was skipped because an earlier job in the pipeline failed
  - Job was skipped due to dependency conditions not being met
  - Job was skipped due to conditional logic in the pipeline config
  - **NOT necessarily a failure of this specific job**

  Example: In the zen-payroll pipeline, many jobs show as "broken" but are actually skipped because their dependencies indicated they weren't needed (e.g., no relevant file changes).

- **`soft_failed`** - Job failed but was marked as "soft fail" (doesn't block pipeline)
  - Shows as failed but doesn't cause overall build failure
  - Often used for optional checks or flaky tests

### Active States

- **`waiting`** - Job is waiting for dependencies
- **`waiting_failed`** - Job was waiting but its dependency failed
- **`assigned`** - Job has been assigned to an agent
- **`accepted`** - Agent has accepted the job
- **`running`** - Job is currently executing
- **`blocked`** - Job is a block step waiting for manual unblock

## Interpreting Build Status

### Progressive Disclosure Pattern

When checking build status, follow this pattern:

1. **Start with overall state**: `passed`, `failed`, `canceled`, `blocked`
2. **If failed, check job summary**: How many jobs failed vs broken vs passed?
3. **Examine failed jobs specifically**: Don't assume "broken" means the job itself failed
4. **Check annotations**: Some projects surface important failures in annotations
5. **Inspect logs**: For actual failures, read the job logs

### Common Pitfalls

1. **Treating "broken" as "failed"**: A "broken" job is often just skipped due to pipeline logic, not an actual failure.

2. **Ignoring soft fails**: Jobs marked as `soft_failed` may contain important information even though they don't block the build.

3. **Missing blocked builds**: A `blocked` build is waiting for approval and won't progress without manual intervention.

4. **Overlooking job dependencies**: Jobs may be skipped (`broken`) because their dependencies weren't met, which is expected behavior.

## Project-Specific Patterns

### zen-payroll Pipeline

- **Heavy use of conditional execution**: Many jobs are conditionally skipped based on file changes
- **"broken" is normal**: A build with many "broken" jobs may still be perfectly healthy
- **Check annotations**: Important test failures are often surfaced in build annotations
- **Multiple test suites**: Different test types (unit, integration, system) have different failure patterns

### Smaller Pipelines (e.g., gusto-karafka)

- **Fewer conditional jobs**: Most jobs are expected to run
- **"broken" usually indicates a problem**: Less conditional logic means broken jobs are more likely to be actual issues
- **Simpler job graphs**: Easier to trace why a job didn't run
- **May not use annotations**: Failures are usually just in job logs

## When to Investigate

Investigate a build when:

1. Overall build state is `failed`
2. Jobs show `failed` state (not just `broken`)
3. Build is `blocked` and you need to unblock it
4. Annotations contain error messages
5. Job logs show actual errors (red output, stack traces, test failures)

Don't automatically investigate when:

1. Build is `passed` (even if some jobs are `broken`)
2. Jobs are `soft_failed` unless specifically requested
3. Jobs are `broken` due to conditional execution (check pipeline config)
