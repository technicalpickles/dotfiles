# GitHub PR Communication Skill Design

**Date:** 2025-11-07
**Status:** Approved

## Overview

A Claude Code skill for creating, updating, and commenting on GitHub pull requests with focus on material impact, human reviewability, and safe shell operations.

## Core Principles

1. **Safety first:** All PR bodies written to scratch files before use with `gh --body-file`
2. **Material impact:** Focus on why changes matter, not what files changed
3. **Smart merge:** Detect manual edits, only update when changes are material
4. **Human-friendly:** Concise, warm tone; respect busy reviewers
5. **Flexible workflow:** Explicit commands when clear, smart routing when ambiguous

## Architecture

### File Structure

```
.scratch/pr-bodies/
  drafts/
    <slugified-title>.md          # Draft body before PR creation
  <pr-number>/
    metadata.json                  # PR metadata and state
    <timestamp>-body.md           # Timestamped snapshots of generated bodies
    <timestamp>-comment.md        # Comment drafts
```

### Metadata Schema

```json
{
  "pr_number": 123,
  "branch": "feature/add-skill",
  "base": "main",
  "title": "Add spotlight exclusion skill",
  "created_at": "2025-11-07T10:30:00Z",
  "last_generated_hash": "abc123def456",
  "last_updated_at": "2025-11-07T16:45:30Z",
  "manual_edits_detected": false
}
```

### Change Detection Strategy

1. **Quick hash check:** Compare current PR body hash vs `last_generated_hash`
2. **If hash matches:** No changes detected, skip processing
3. **If hash differs:**
   - Compute diff between current and last generated body
   - Analyze diff: whitespace-only vs content changes
   - If material changes: set `manual_edits_detected = true`
4. **When manual edits detected:** Show diff to user, get confirmation before overwriting

## Operation Flows

### 1. Create PR

```
1. Check if PR already exists for branch
   - gh pr view --json number 2>/dev/null
   - If exists → error or route to update

2. Gather information:
   - Get commits: git log <base>..HEAD
   - Check for PR template: .github/pull_request_template.md, etc.
   - Check for CONTRIBUTING.md
   - Analyze commit messages and diffs

3. Generate PR content:
   - Title: from branch name or first commit if meaningful
   - Body:
     * Follow template structure if exists
     * Include: Summary (2-4 bullets of material impact)
     * Include: Test plan (if relevant)
     * Tone: concise, warm, focus on why/impact not what
     * NO metrics (# tests, # files, etc.)
     * Strip any H1 heading from body (avoid title duplication)

4. Draft review:
   - Write to .scratch/pr-bodies/drafts/<slug>.md
   - Show draft to user
   - Allow edits before creating

5. Create PR:
   - gh pr create --title "..." --body-file .scratch/pr-bodies/drafts/<slug>.md
   - Capture PR number from output

6. Archive and track:
   - Create .scratch/pr-bodies/<number>/ directory
   - Move draft to <number>/<timestamp>-body.md
   - Write metadata.json with hash of generated body
   - Clean up drafts/ directory
```

### 2. Update PR Body

```
1. Verify PR exists:
   - gh pr view --json number,body,title
   - Load metadata.json if exists

2. Detect manual edits:
   - Hash current body from gh pr view
   - Compare to last_generated_hash in metadata
   - If differs: compute diff and analyze
   - If material changes: show diff, ask to proceed

3. Generate updated body:
   - Re-analyze full commit range: <base>..HEAD
   - Check if scope/impact has changed materially
   - If no material change → inform user, skip update
   - If material change → generate new body

4. Draft review:
   - Write to .scratch/pr-bodies/<number>/<timestamp>-body.md
   - Show diff between current and proposed
   - Allow edits before updating

5. Update PR:
   - gh pr edit --body-file .scratch/pr-bodies/<number>/<timestamp>-body.md
   - Update metadata.json with new hash and timestamp
```

### 3. Add PR Comment

```
1. Verify PR exists and get context:
   - gh pr view --json number,title,reviews,comments
   - Check if there's been review activity

2. Determine comment content:
   - Analyze recent commits since last update
   - Focus on: what changed and why
   - Common scenarios:
     * Responding to review feedback
     * Noting significant additions after initial review
     * Summarizing a batch of changes

3. Draft comment:
   - Write to .scratch/pr-bodies/<number>/<timestamp>-comment.md
   - Tone: conversational, helpful, concise
   - Structure: "I've updated the PR to address..."
   - Show draft to user

4. Post comment:
   - gh pr comment <number> --body-file <file>
   - Optional: Update metadata.json with comment timestamp
```

## Trigger Patterns & Routing

### Explicit Triggers (Always Honored)

- "create a PR" / "open a PR" → Create flow
- "update the PR body/description" → Update body flow
- "comment on the PR" / "add a PR comment" → Comment flow

### Ambiguous Triggers (Smart Routing)

**"update the PR":**

- No PR exists → Error: "No PR found for this branch. Did you mean to create one?"
- PR exists, no reviews → Update body
- PR exists, has reviews → Ask: "This PR has reviews. Update body or add comment?"

**"communicate the changes" / "update reviewers":**

- PR exists, no reviews yet → Update body
- PR exists, has reviews → Add comment (better for notifications)

### Decision Matrix: Update Body vs Comment

**Prefer UPDATE BODY when:**

- PR has no reviews/comments yet
- User explicitly says "update description/body"
- Material scope change that needs description rewrite

**Prefer COMMENT when:**

- PR has review activity (comments, requested changes)
- User mentions "responding to feedback"
- Batch of changes after initial review
- Want to notify watchers

## Content Generation Guidelines

### PR Title

**Derive from:**

1. Branch name (if semantic): `feature/add-spotlight` → "Add Spotlight exclusion management"
2. First commit message (if descriptive and singular focus)
3. Ask user if ambiguous

**Format:**

- Imperative mood: "Add", "Fix", "Update", "Refactor"
- Concise: < 72 characters ideal
- Capitalize first word
- No period at end

### PR Body Structure

**When PR template exists:**

- Follow template structure exactly
- Fill in sections based on commit analysis
- Preserve template comments/instructions

**When no template:**

```markdown
## Summary

- Material impact point 1
- Material impact point 2
- Material impact point 3 (if needed)

## Test plan

- How to verify the changes work
- Only if non-obvious or requires manual testing

[Optional sections based on context:]

## Breaking changes

## Migration notes

## Follow-up work
```

### Content Principles

**Focus on material impact:**

- ✅ "Enables pattern-based Spotlight exclusions for easier maintenance"
- ❌ "Adds 3 new scripts and updates 2 config files"

**Concise yet warm:**

- ✅ "This makes it easier to manage exclusions at scale."
- ❌ "This change significantly improves the developer experience by implementing a novel approach to..."

**Assume busy human reader:**

- Avoid: File counts, line counts, test counts
- Avoid: Implementation details visible in diff
- Include: Why this matters, what problem it solves
- Include: Non-obvious testing steps

**Handling H1 headings:**

- Never include H1 (`# Title`) in body
- GitHub shows title separately, would duplicate
- Start body with H2 (`## Summary`) or text

### Following Repository Guidelines

**PR Templates:**

```
Search locations:
- .github/pull_request_template.md
- .github/PULL_REQUEST_TEMPLATE.md
- .github/PULL_REQUEST_TEMPLATE/*.md

If found:
- Parse template structure
- Preserve section headers
- Fill in based on commit analysis
- Keep any template instructions/comments
```

**CONTRIBUTING.md:**

```
Search locations:
- CONTRIBUTING.md
- .github/CONTRIBUTING.md
- docs/CONTRIBUTING.md

Extract PR-related guidance:
- Required information
- Checklist items
- Style preferences
- Incorporate into body generation
```

### Comment Content Guidelines

**For batch updates:**

```markdown
I've updated the PR to address the feedback:

- Point about what changed
- Another significant change
- Why these changes were made

[Optional: specific response to review comment if relevant]
```

**Tone:**

- Conversational but professional
- Acknowledge reviewers' input
- Explain reasoning when non-obvious
- Keep brief (3-5 sentences typical)

## Error Handling & Edge Cases

### Common Errors

**No PR exists (when updating/commenting):**

```
Error: "No PR found for branch '<branch-name>'.
Would you like to create one?"

Action: Offer to route to create flow
```

**Multiple PRs for branch:**

```
Scenario: Branch has closed/merged PRs plus maybe one open

Logic:
1. gh pr list --head <branch> --state open
2. If exactly 1 open PR → use it
3. If 0 open PRs:
   - Check for closed/merged: gh pr list --head <branch> --state all
   - Error: "No open PR found for '<branch>'. Last PR was #123 (closed/merged)."
   - Action: Offer to create new PR
4. If >1 open PR (should be rare/impossible):
   - Error: "Found multiple open PRs for '<branch>': #123, #456."
   - Action: Ask user which one
```

**Not on a branch / on main:**

```
Error: "Currently on '<branch>'.
PRs should be created from feature branches, not main/master."

Action: Stop, suggest creating a branch first
```

**PR already merged/closed:**

```
Warning: "PR #123 is <merged|closed>.
Are you sure you want to update it?"

Action: Allow but confirm with user first
```

**gh CLI not available:**

```
Error: "GitHub CLI (gh) not found.
Install with: brew install gh"

Action: Stop with installation instructions
```

**gh not authenticated:**

```
Error: "GitHub CLI not authenticated.
Run: gh auth login"

Action: Stop with auth instructions
```

### Edge Cases

**Manual edits detected:**

```
1. Show diff between current and last generated:
   "The PR body has been manually edited. Here's what changed:"
   [Show diff]

2. Ask: "Overwrite manual edits, merge, or cancel?"
   - Overwrite: Replace with new generated body
   - Merge: Attempt to preserve manual sections
   - Cancel: Keep current body, skip update

3. If merge: Use semantic diff to identify:
   - Added sections → preserve
   - Modified existing sections → ask per section
   - Removed sections → keep removed
```

**No material changes in update:**

```
Info: "Analyzed commits - no material changes to scope or impact.
The current PR description is still accurate."

Action: Skip update unless user forces with explicit flag
```

**Draft in progress:**

```
If .scratch/pr-bodies/drafts/<slug>.md exists:
Warning: "Found existing draft for '<title>'.
Use existing draft, create new, or cancel?"

Action: Let user choose
```

**Scratch directory doesn't exist:**

```
Auto-create: mkdir -p .scratch/pr-bodies/drafts

Log: "Created .scratch/pr-bodies directory structure"
```

### Safety Checks

**Before creating PR:**

- ✓ Current branch is not main/master
- ✓ Branch has commits ahead of base
- ✓ gh CLI is authenticated
- ✓ User has reviewed draft

**Before updating PR body:**

- ✓ PR exists and is open
- ✓ Manual edits check complete
- ✓ User has reviewed diff

**Before posting comment:**

- ✓ PR exists
- ✓ Comment is not empty
- ✓ User has reviewed content

## Integration with Other Skills

**working-in-scratch-areas:**

- All drafts go to `.scratch/pr-bodies/`
- Follows scratch area conventions
- Auto-creates directory structure if needed

**git-preferences-and-practices:**

- Respects existing git workflow preferences
- Works with branch naming conventions
- Integrates with commit message style

**Repository conventions:**

- Checks for ADRs (Architecture Decision Records)
- References them in PR body if relevant
- Links to docs/plans if design doc exists

## Example User Interactions

### Creating a PR

```
User: "create a PR for this branch"

Claude: "I'm using the gh-pr skill to create the pull request."
[Analyzes commits]
[Checks for templates]
[Generates draft in .scratch/pr-bodies/drafts/add-spotlight-skill.md]
"Here's the draft PR. The summary focuses on the pattern-based
approach and easier maintenance. Does this look good?"

User: "yes"

Claude: [Creates PR, archives draft]
"Created PR #123: Add spotlight exclusion skill"
```

### Updating After Changes

```
User: "update the PR"

Claude: "I'm using the gh-pr skill to update the pull request."
[Checks for manual edits - none found]
[Re-analyzes full commit range]
"I've added 3 commits since the PR was created. The scope has
expanded to include monitoring tools. Should I update the
description to reflect this?"

User: "yes"

Claude: [Shows diff of proposed changes]
"Here's what would change in the description. Look good?"

User: "yes"

Claude: [Updates PR]
"Updated PR #123 description"
```

### Adding a Comment

```
User: "comment on the PR about the changes"

Claude: "I'm using the gh-pr skill to comment on the pull request."
"This PR has review comments. I'll add a comment about the
recent updates. Here's the draft:"

[Shows comment draft]

User: "looks good"

Claude: [Posts comment]
"Added comment to PR #123"
```

## File Management

**Keep:**

- metadata.json (permanent record)
- Last 5 timestamped bodies (recent history)
- Current draft (if in progress)

**Remove:**

- Timestamped bodies older than 30 days (optional)
- Completed drafts after PR creation

## Future Enhancements

Potential additions outside initial scope:

- Auto-detect related issues and link them
- Suggest reviewers based on git blame
- Integration with CI status checks
- PR template validation
- Automated follow-up reminders
