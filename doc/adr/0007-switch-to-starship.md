# 7. Switch to starship

Date: 2025-08-11

## Status

Accepted

## Context and Problem Statement

I've been using [Cursor](https://cursor.com/) and have been seeing this weird error when using the terminal:

[Frequent “node:events:502 throw err; // Unhandled ‘error’ event” in terminals](https://forum.cursor.com/t/frequent-node502-throw-err-unhandled-error-event-in-terminals/123536/3)

I was able to narrow it down to [tide](https://github.com/IlanCosman/tide), but couldn't figure out what part of it was. It seems to have been around for awhile in vscode, which cursor is forked from, so not sure why it started.

## Decision Outcome

Switch to [starship](https://starship.rs/)

## Consequences

No more annoying errors in Cursor's terminal!

Can switch bash and zsh to using starship directly, for a consistent prompt across all of them.
