---
name: checkout-pr
description: Use when reviewing a GitHub PR locally - fetches PR details, sets up isolated worktree, and provides initial review summary with existing feedback
---

# Checkout PR for Local Review

## Overview

Streamline PR review workflow: fetch details, create isolated worktree, summarize changes and existing feedback.

**Announce:** "I'm using the checkout-pr skill to set up a local review environment."

## When to Use

- User wants to review a PR locally
- User provides PR URL or number
- User says "checkout PR", "review PR locally", or similar

## Workflow

### 1. Parse PR Reference

Accept formats:

- Full URL: `https://github.com/{owner}/{repo}/pull/{number}`
- Short: `{repo}#{number}` or `#{number}` (infer repo from cwd)
- Number only: `{number}` (infer owner/repo from git remote)

```bash
# Get owner/repo from current directory if needed
gh repo view --json owner,name -q '"\(.owner.login)/\(.name)"'
```

### 2. Fetch PR Details

```bash
# Core PR info
gh pr view {number} --json title,body,author,state,baseRefName,headRefName,files,reviews,comments,url

# Diff for review
gh pr diff {number}

# Review comments (inline feedback)
gh api repos/{owner}/{repo}/pulls/{number}/comments
```

### 3. Set Up Worktree

**REQUIRED:** Use superpowers:using-git-worktrees skill.

```bash
# Fetch the PR branch
git fetch origin {headRefName}

# Create worktree (skill handles directory selection)
git worktree add .worktrees/pr-{number}-{short-description} origin/{headRefName}
```

Name worktree: `pr-{number}-{2-3-word-description}` (e.g., `pr-310008-karafka-logging`)

### 4. Present Review Summary

Structure the summary:

```markdown
## PR #{number} Review Summary

**Title:** {title}
**Author:** @{author}
**Branch:** {headRefName}
**Status:** {state}, {mergeable status}
**Reviewers:** {requested reviewers and their status}

### What it does

{1-3 sentence summary of the PR purpose}

### Files changed ({count})

{Grouped by directory, with +/- line counts}

### Existing review feedback

{Summarize comments, grouped by:}

- Blocking issues
- Suggestions/questions
- Resolved items

### Outstanding items

{What still needs to be addressed}

---

**Worktree ready at:** {full path}
```

## Quick Reference

| Step            | Command                                                           |
| --------------- | ----------------------------------------------------------------- |
| PR info         | `gh pr view {n} --json title,body,author,state,headRefName,files` |
| Diff            | `gh pr diff {n}`                                                  |
| Comments        | `gh api repos/{o}/{r}/pulls/{n}/comments`                         |
| Fetch branch    | `git fetch origin {branch}`                                       |
| Create worktree | `git worktree add .worktrees/pr-{n}-{desc} origin/{branch}`       |

## Common Mistakes

| Mistake                           | Fix                                          |
| --------------------------------- | -------------------------------------------- |
| Creating worktree before fetching | Always `git fetch` the PR branch first       |
| Generic worktree name             | Include PR number AND short description      |
| Missing review context            | Always fetch and summarize existing comments |
| Not checking mergeable status     | Include in summary - affects review priority |

## Related

- superpowers:using-git-worktrees - Handles worktree directory selection
- code-review - For detailed note-taking during review
- superpowers:finishing-a-development-branch - For cleanup after review
