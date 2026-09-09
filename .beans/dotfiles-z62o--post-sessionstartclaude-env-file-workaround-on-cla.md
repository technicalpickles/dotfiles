---
# dotfiles-z62o
title: Post SessionStart/CLAUDE_ENV_FILE workaround on claude-code#70684
status: todo
type: task
priority: normal
created_at: 2026-09-09T00:59:04Z
updated_at: 2026-09-09T00:59:04Z
---

The upstream thread (anthropics/claude-code#70684, open since 2026-06-24) currently concludes that no config-level fix restores sandboxed git-over-SSH on macOS. That conclusion is stale.

A `SessionStart` hook appending `export GIT_SSH_COMMAND=ssh` to $CLAUDE_ENV_FILE works on 2.1.263. The only prior test of it in the thread was jthurne's on 2.1.191 in June (~70 versions ago), which is why everyone moved on to HTTP CONNECT helper scripts and `insteadOf` HTTPS rewrites.

Worth posting because it is strictly simpler than both current workarounds, and because it clarifies *why* it works: role/settings `env` is applied before the harness injection and loses, while $CLAUDE_ENV_FILE is read later into a cached session-environment script and wins. That distinction is not in the thread.

Caveat to state honestly in the comment: bare `ssh` only gets you a working connection if something else already provides a path to port 22. Our setup has a local SOCKS relay (gost on 127.0.0.1:1080, allowed because localhost is exempt). Someone relying on the harness proxy alone still needs the CONNECT helper. So this is a fix for 'I have my own relay and the injection is clobbering it', not a universal one.

See bean dotfiles-mo7y for the full investigation. There is also a queued local Claude Code feedback draft covering the same ground -- redundant with the issue, do not also send it.

## Checklist
- [ ] Draft the comment (keep it short: version tested, the hook, the env-ordering explanation, the local-relay caveat)
- [ ] Post to https://github.com/anthropics/claude-code/issues/70684
