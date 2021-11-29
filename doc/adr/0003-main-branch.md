# 3. main branch

Date: 2021-11-29

## Status

Accepted

## Context

Previously, the default branch was called master.

GitHub has moved to using main as the new default branch.

[github/renaming: Guidance for changing the default branch name for GitHub repositories](https://github.com/github/renaming/)

## Decision

Rename master branch to main.

## Consequences

Muscle memory may accidentally recreate the master branch. This command can help mitigate:

    git symbolic-ref refs/heads/master refs/heads/main

Existing checkouts won't get updates from the master branch unless they manually switch.
