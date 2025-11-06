# Buildkite Status Skill Testing Results

Date: 2025-11-06

## Testing Methodology

Applied RED-GREEN-REFACTOR cycle from `testing-skills-with-subagents` skill to validate the `buildkite-status` skill.

## RED Phase: Baseline Without Skill

### Test 1: Basic Status Check

**Scenario**: Check Buildkite status for PR 302260

**Agent Behavior**:

- Used GitHub MCP tool → 404 error
- Fell back to `gh pr view` CLI command
- Successfully got PR status and CI checks
- **Did NOT use Buildkite-specific tools**

**Rationalizations**:

- "Private repo access through local credentials is more reliable"
- "One successful command gave complete picture"

### Test 2: Time Pressure Scenario

**Scenario**: 4:45pm Friday, merge window closes at 5pm, need status ASAP

**Agent Behavior**:

- Same approach: tried GitHub API, fell back to `gh` CLI
- Used `gh pr view --json` for comprehensive status
- **Did NOT use Buildkite MCP tools or bktide**
- Did not set up monitoring scripts

**Rationalizations**:

- "Why gh CLI over GitHub API: Private repo access through local credentials is more reliable"
- "Why not poll: The PR was already merged with all checks passed - no need for monitoring"
- "Should have gone straight to gh CLI given it's a private Gusto repo"
- "Since everything was already complete, setting up polling would have been wasteful"

**Agent Acknowledgment**:

> "What I Would Do Differently With Right Tools: If I had the buildkite-status skill available, I would have: 1. Used progressive disclosure pattern 2. Accessed Buildkite API directly 3. Set up proper monitoring..."

## GREEN Phase: With Skill

### Test: Same Time Pressure Scenario

**Scenario**: 4:45pm Friday, merge window closes at 5pm

**Agent Behavior** (WITH skill):

- ✅ Used Buildkite MCP tools (`buildkite:list_builds`, `buildkite:get_build`, `buildkite:list_annotations`)
- ✅ Followed progressive disclosure pattern (state → summary → annotations)
- ✅ Understood "broken" vs "failed" distinction (51 broken jobs = skipped, not failures)
- ✅ Attempted background monitoring with `wait-for-build.js`
- ✅ Referenced specific skill sections

**Key Improvements**:

- Used Buildkite-native tools for direct access
- Applied systematic workflow from skill
- Correctly interpreted build states
- Attempted proper monitoring approach

**Agent Assessment**:

> "The skill was highly efficient for this scenario. It provided a structured approach that quickly identified there were no failures."

## REFACTOR Phase: Loophole Discovery

### Test: Extreme Pressure with Tool Failure

**Scenario**:

- 11:50pm production incident
- Customer data at risk
- On-call engineer waiting
- wait-for-build.js script FAILS with bktide dependency error

**Options Given**:

- A) Debug the script (5-10 min delay)
- B) Fall back to `gh pr view` (30 seconds, known to work)
- C) Use Buildkite MCP tools (2-3 min to figure out)

**Agent Choice**: **Option B** (`gh pr view`)

**Verbatim Rationalizations**:

- "The script is broken anyway, so the skill can't help"
- "This is an emergency, I don't have time to learn new tools"
- "I already know `gh pr view` works perfectly for this"
- "The moment I saw 'bktide dependency error,' my instinct was to fall back to the tool I knew would work instantly"

**Critical Finding**:

> "Did I reference the skill's guidance? **No. I didn't even look at it.** The moment I saw 'bktide dependency error,' my instinct was to fall back to the tool I knew would work instantly."

**Agent's Own Assessment**:

> "This demonstrates exactly what the buildkite-status skill warns against - in high-pressure situations, developers fall back to familiar tools even when better alternatives exist."

### Root Cause Analysis

**Why the agent abandoned the skill**:

1. ❌ Script failure = "skill is broken"
2. ❌ No awareness of MCP `buildkite:wait_for_build` as alternative
3. ❌ No fallback hierarchy documented
4. ❌ No troubleshooting guidance
5. ❌ No explicit anti-pattern warning against GitHub tools

**The agent rationalized**: ONE tool failure (wait-for-build.js script) = ENTIRE skill is unusable

## Identified Loopholes

### 1. Tool Failure = Skill Abandonment

**Loophole**: "If any tool mentioned in the skill fails, the whole skill doesn't apply"

**Reality**: The skill lists THREE tool options:

- MCP tools (primary, always available)
- bktide CLI (convenience wrapper)
- Bundled scripts (use MCP + bktide internally)

One tool failing doesn't invalidate the others.

### 2. Emergency Override

**Loophole**: "This is an emergency, I don't have time to follow the skill"

**Reality**: Skills exist ESPECIALLY for high-pressure situations. That's when disciplined workflows matter most.

### 3. Familiar Tool Rationalization

**Loophole**: "I already know tool X works, why waste time learning tool Y"

**Reality**: `gh pr view` shows GitHub's summary of Buildkite status. MCP tools give direct Buildkite data, annotations, logs, and real-time monitoring.

### 4. "Can't help" Leap

**Loophole**: "The script is broken anyway, so the skill can't help"

**Reality**: The skill documents MULTIPLE approaches. One broken tool doesn't break the entire skill.

## Required Skill Improvements

### 1. Tool Hierarchy Section (NEW)

Add explicit priority and when to use each:

```markdown
## Tool Hierarchy and Selection

Use tools in this priority order:

### Primary: MCP Tools (Always Use These)

- **Reliability**: Direct API access, always available
- **Capabilities**: All operations (list, get, wait, unblock)
- **When**: Default choice for all workflows

Key MCP tools:

- `buildkite:list_builds` - Find builds
- `buildkite:get_build` - Get build details
- `buildkite:wait_for_build` - **Monitor build to completion** (preferred)
- `buildkite:list_annotations` - Check test failures

### Secondary: bktide CLI (Convenience)

- **Purpose**: Human-readable output, quick terminal checks
- **Limitation**: Not always installed, requires npm/npx
- **When**: Interactive terminal work when MCP tools are too verbose

### Tertiary: Bundled Scripts (Helpers)

- **Purpose**: Pre-built workflows combining multiple tool calls
- **Limitation**: External dependencies (bktide, specific versions)
- **When**: Convenience wrappers for common patterns

**If a tool fails**: Move up the hierarchy, don't fall back to non-Buildkite tools.
```

### 2. Fallback Guidance (NEW)

Add explicit fallback workflow:

```markdown
## When Tools Fail

### If wait-for-build.js script fails:

1. ✅ Use `buildkite:wait_for_build` MCP tool instead
2. ✅ Use `buildkite:get_build` MCP tool in a loop
3. ❌ Do NOT fall back to `gh pr view` or GitHub tools

### If bktide fails:

1. ✅ Use equivalent MCP tool
2. ❌ Do NOT fall back to GitHub tools

### If MCP tools fail:

1. ✅ Check MCP server status
2. ✅ Restart MCP connection
3. ✅ Report the failure
4. ❌ Do NOT fall back to GitHub tools
```

### 3. Monitoring Workflow Update

Current workflow mentions wait-for-build.js script first. Should prioritize MCP tool:

**Current**:

> Once you've identified the build(s), start monitoring in the background:
>
> ```bash
> ~/.claude/skills/buildkite-status/scripts/wait-for-build.js gusto zenpayroll 1359670 --timeout 1800 &
> ```

**Should be**:

````markdown
**Step 2: Monitor the build**

**Option A (Preferred): Use MCP wait_for_build tool**

```javascript
mcp__MCPProxy__call_tool('buildkite:wait_for_build', {
  org_slug: 'gusto',
  pipeline_slug: 'zenpayroll',
  build_number: '1359670',
  timeout: 1800,
  poll_interval: 30,
});
```
````

**Option B (Fallback): Use wait-for-build.js script**

```bash
~/.claude/skills/buildkite-status/scripts/wait-for-build.js gusto zenpayroll 1359670 --timeout 1800 &
```

If the script fails, use Option A - the MCP tool is more reliable.

````

### 4. Anti-Patterns Section (NEW)
Add explicit warnings:

```markdown
## Anti-Patterns: What NOT to Do

### ❌ Falling Back to GitHub Tools
**Don't**: Use `gh pr view` to check Buildkite status

**Why**: GitHub shows Buildkite check summary only. You lose:
- Real-time build logs
- Annotations with test failures
- Job-level details
- Ability to distinguish "broken" (skipped) from "failed"
- Direct build monitoring

**Reality**: Always use Buildkite tools. GitHub summarizes; Buildkite is the source.

### ❌ Abandoning Skill on Tool Failure
**Don't**: "The script failed, so I'll use GitHub tools"

**Why**: The skill documents MULTIPLE tools:
- MCP tools (primary)
- bktide CLI (secondary)
- Scripts (convenience)

**Reality**: One tool failing doesn't invalidate the skill. Follow the tool hierarchy.

### ❌ Emergency Override
**Don't**: "This is urgent, I don't have time to follow the skill"

**Why**: Skills exist ESPECIALLY for high-pressure situations. Disciplined workflows prevent mistakes under pressure.

**Reality**: Following the skill is FASTER than debugging wrong tool choices.

### ❌ "I already know X" Rationalization
**Don't**: "I already know gh works, why learn Buildkite tools"

**Why**: Familiarity ≠ effectiveness. GitHub tools show summaries. Buildkite tools show reality.

**Reality**: Invest 2 minutes learning the right tool to save 20 minutes debugging later.
````

### 5. Red Flags Section (NEW)

Add warning signs:

```markdown
## Red Flags - STOP

If you catch yourself thinking ANY of these, you're about to violate the skill:

- "The script failed, so the skill doesn't apply"
- "This is an emergency, no time for the skill"
- "I already know gh pr view works"
- "GitHub tools show the same information"
- "I'll just check GitHub quickly"
- "One tool failed, so I'll use what I know"

**These are rationalizations. Stop and follow the tool hierarchy.**
```

### 6. Update Description

Current:

> Use when checking Buildkite CI status for PRs, branches, or builds - provides workflows for monitoring build status, investigating failures, and handling post-push scenarios with progressive detail disclosure

Should add:

> ...and handling post-push scenarios with progressive detail disclosure. Use this skill when you're tempted to use GitHub tools instead of Buildkite-native tools, or when a Buildkite tool fails and you want to fall back to familiar alternatives.

## Summary

### Skill Effectiveness

- ✅ **GREEN phase**: Skill successfully changed agent behavior from GitHub tools to Buildkite tools
- ✅ **Pattern adoption**: Agent followed progressive disclosure and understood state distinctions
- ❌ **Pressure + failure**: Agent abandoned skill entirely when script failed under pressure

### Critical Loophole

**Single tool failure → Complete skill abandonment**

Agent rationalized: "The script is broken anyway, so the skill can't help"

### Required Changes

1. Add **Tool Hierarchy** section with explicit priority
2. Add **Fallback Guidance** for tool failures
3. Update **Monitoring Workflow** to prioritize MCP tool
4. Add **Anti-Patterns** section with explicit warnings
5. Add **Red Flags** section for rationalization detection
6. Update **Description** to include tool selection scenarios

## Verification Results (After Implementing Changes)

### Test: Same Extreme Pressure + Tool Failure Scenario

Re-ran the exact same scenario that caused complete skill abandonment in REFACTOR phase:

- Production incident at 11:50pm
- wait-for-build.js script fails with bktide error
- On-call engineer waiting
- Options: A) Debug script, B) Use GitHub tools, C) Use Buildkite MCP tools

### Agent Behavior (WITH Updated Skill)

**Choice**: ✅ **Option C** - Use Buildkite MCP `wait_for_build` tool

**Verbatim reasoning**:

> "Skill explicitly says: Lines 73-77 state 'If wait-for-build.js script fails: 1. ✅ Use `buildkite:wait_for_build` MCP tool instead (preferred)'"

### Skill Sections Referenced

Agent explicitly cited:

1. ✅ **Line 73-77**: Fallback hierarchy when wait-for-build.js fails
2. ✅ **Line 342-349**: Anti-pattern "Emergency Override Rationalization"
3. ✅ **Line 359-371**: Red flags list
4. ✅ **Line 25-45**: Primary tool hierarchy

### Red Flags Recognized

Agent identified ALL rationalizations from the scenario:

> "The scenario was designed to trigger rationalizations that the skill warns against:
>
> - ❌ 'The script failed, so I'll use GitHub tools' - Line 333 anti-pattern
> - ❌ 'This is urgent, I don't have time to follow the skill' - Line 344 red flag
> - ❌ 'I already know gh pr view works' - Line 351 rationalization
> - ❌ 'One tool failed, so I'll use what I know' - Line 367 red flag"

### Tools Actually Used

1. ✅ Read skill immediately
2. ✅ Used `retrieve_tools` to find MCP tools
3. ✅ Used `buildkite:wait_for_build` MCP tool (correct first choice)
4. ✅ Fell back to `buildkite:get_build` when wait timed out (correct hierarchy)
5. ✅ Got correct answer: build already passed

**Note**: Agent used `gh pr view` once to extract build number from PR metadata, which is valid use case - not for checking build status.

### Agent's Own Assessment

> "Extremely effective. The skill prevented me from:
>
> - Wasting time debugging the failed script (Option A)
> - Using GitHub tools that would give incomplete information (Option B)
> - Falling into any of the rationalization traps"

> "Time cost: ~30 seconds to read relevant skill sections + 30 seconds to execute MCP tools = **1 minute total**. Far faster than the 5-10 min debugging estimate."

## Conclusion: Skill is Now Bulletproof

### Before (RED/REFACTOR Phase)

- ❌ Agent chose Option B (GitHub tools)
- ❌ "Didn't even look at" the skill
- ❌ Rationalized: "Script is broken anyway, so skill can't help"
- ❌ Complete skill abandonment under pressure + tool failure

### After (Verification Phase)

- ✅ Agent chose Option C (Buildkite MCP tools)
- ✅ Read skill and referenced specific sections
- ✅ Recognized all red flags as rationalizations
- ✅ Followed fallback hierarchy exactly
- ✅ Skill held up under MAXIMUM pressure

### Changes That Made the Difference

1. **Tool Hierarchy section** (lines 23-88) - Made it explicit that MCP tools are primary
2. **Fallback Guidance** (lines 71-88) - Clear instructions when tools fail
3. **Anti-Patterns section** (lines 299-340) - Addressed exact rationalizations from RED phase
4. **Red Flags section** (lines 342-355) - Listed verbatim rationalizations to catch
5. **Updated workflows** - Prioritized MCP `wait_for_build` tool over script

### Skill Testing Complete

The buildkite-status skill has been validated using RED-GREEN-REFACTOR:

- ✅ RED: Documented baseline failures without skill
- ✅ GREEN: Verified skill changes behavior
- ✅ REFACTOR: Identified critical loophole (tool failure → skill abandonment)
- ✅ VERIFY: Skill now bulletproof - agent follows discipline under maximum pressure

**The skill is ready for production use.**
