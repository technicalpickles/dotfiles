## interacting with git

Preferences and best practices for interacting with a git repository.

### git add

ALWAYS use `git add` with specific files that have been updated. NEVER use `git add .` or `git add -A`.

IF adding files that look like they are agent configuration, or adding planning documentation, ALWAYS prompt the user to confirm if they should be included or not.

### git commit

PREFER writing out a commit message to the `scratch/` directory, and save it to a name reflecting what is being commited. Then use use `git commit -t scratch/path-to-message.txt`

#### signing

We have git commit signing setup. If it fails due to a message like:

    error: 1Password: failed to fill whole buffer

    fatal: failed to write commit object

... it is because the user was being prompted to authorize signing, and didn't see it or missed it. Do not try to fix or bypass it. Stop and prompt the user about either fixing it, or confirm bypassing it.

### hooks

#### pre-commit failures

When git precommit checks fail, analyze what the failures are, and try to autofix when possible, otherwise think through how to fix it. Ask the user how to proceed when it's unclear if how to fix.

DO NOT follow sorbet's autocorrection advice.
DO NOT skip verification without confirmation from the user.

#### prepare-commit-msg and post-commit

If we see errors like:

```
git: 'duet-prepare-commit-msg' is not a git command. See 'git --help'.
```

it is because we previously were using git-duet. It uses a git template, with hooks that call `git duet-prepare-commit-msg`. We've sinced moved, but the files will still be present

In this case, check .git/hooks/ for references to these. Remove files that call it.
