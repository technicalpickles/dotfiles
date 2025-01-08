# 5. EditorConfig

Date: 2025-01-08

## Status

Accepted

## Context

Using different editors, it's easy to get inconsistent indentation in a project.

Ideally, our editors keep files consistent. If an editor doesn't, we should
catch it during a pre-commit hook.

## Decision

Add [.editorconfig configuration](https://editorconfig.org/)

Use [prettier](https://prettier.io/) to check and fix for inconsiencies. And use
it as a pre-commit hook.

Use .editorconfig options as much as possible rather than prettier
configuration, since prettier will read .editorconfig.

## Alternates Considered

Originally, I looked for tools that would reformat files based on .editorconfig.
There are a few tools that can check that an error exists, but not write out
changes. I even started contributing a feature to do that. That was before I
knew about prettier and that it essentially does the same, and has

## Consequences

Hopefully, less inconsiencies in files.

prettier doesn't support every file though, so we will need to manage a ignore
file for unsupported files. Notably is fish, but there are also one-off files
that dont' have a particular format we need to ensure.
