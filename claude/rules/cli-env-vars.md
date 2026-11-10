## No Env Vars in the Command Line

Don't encode environment variables in the command you run: no `FOO=bar cmd`, no `env FOO=bar cmd`, no `FOO=$(cat file) cmd`. Put the value somewhere the command reads it from, so the command itself is just its name and flags.

**Why:** an inline assignment changes the string that allow rules and the auto-mode classifier judge, so a command you meant to match an existing rule stops matching and gets denied or prompts. The value also lands in the transcript, shell history and process list, which is wrong for anything secret. Seen 2026-11-10: auto mode denied a command that read a token inline, and each retry had to be reshaped by hand.

**How to apply:**

- Wrap the invocation in a script or mise task that sets what it needs, then run that (`scripts/bugsink-dry-run`, `mise run deploy`). The script is the reviewable, allow-listable unit.
- Secrets come from the credential manager at run time: `av inject +NAME -- cmd`, or `op run --env-file <file> -- cmd` where the file holds references, not values.
- Non-secret settings go in a committed config or `.env` file the tool already reads, or in the tool's own flag when it has one.
- If a one-off really needs a variable and no script fits, write the script first. Don't fall back to the inline form.
