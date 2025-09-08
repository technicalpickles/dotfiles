

## managing git directories

### git add
ALWAYS use `git add` with specific files that have been updated. NEVER use `git add .` or `git add -A`.

IF adding files that look like they are agent configuration, or adding planning documentation, ALWAYS prompt the user to confirm if they should be included or not.

### git commit

PREFER writing out a commit message to `scratch/`, and save it to a name reflecting what is being commited. Then use use `git commit -t scratch/path-to-message.txt`
