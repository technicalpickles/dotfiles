# managing PRs with gh

Preferences and best practices for interacting with PRs via `gh pr`

## PR bodies

When using the `gh pr` command to create or edit PR bodies, always write out the proposed body to a file in the `scratch/` directory, and then use the `-F` argument to use that file.

This is safer than accidentally using backticks and running arbitrary commands when trying to create a PR.
