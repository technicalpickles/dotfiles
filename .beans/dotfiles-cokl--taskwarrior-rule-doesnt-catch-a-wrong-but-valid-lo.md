---
# dotfiles-cokl
title: taskwarrior rule doesn't catch a wrong-but-valid-looking UUID
status: done
type: task
created_at: 2026-08-05T00:20:15Z
updated_at: 2026-09-02T00:00:00Z
---

While resuming a parked handoff (.parkinglot/herdr-keymap-popup-and-polish.md,
2026-08-04), the handoff cited taskwarrior UUID d5dc1a02 as "tracks watching
PR #1". That UUID was correctly *formatted* (8-char short UUID, per
claude/rules/taskwarrior.md's guidance to always use UUIDs over integer
IDs) but wrong: it actually resolved to an unrelated task ("Reinstall
Playwright browser..."). The real task was a different UUID (e203902f)
entirely. Caught only by independently searching taskwarrior
(`task description.contains:herdr list`) rather than trusting the cited ID.

This is a gap the existing guidance doesn't cover. claude/rules/taskwarrior.md's
"Stable Task References: Use UUIDs" section correctly warns that integer IDs
get reused, but says nothing about verifying a *UUID* actually resolves to
the intended task before writing it into a durable artifact (handoff, bean,
commit, memory). Using a UUID instead of an integer ID prevents ID-recycling
drift, but doesn't prevent plain citation error (wrong UUID copied, hand-typed
from memory instead of freshly queried, stale after the task was edited
elsewhere, etc.) The plugins/taskwarrior skill
(pickled-claude-plugins marketplace) is also silent on this -- it's a query
density guide, not a correctness guide. The agent-meta park skill doesn't
mention taskwarrior/UUIDs at all, so nothing prompts verification when a
UUID gets embedded in a parked handoff.

## Checklist
- [x] Add a line to claude/rules/taskwarrior.md's "Stable Task References"
      section: before citing a UUID in a durable artifact, verify it resolves
      to the intended task (e.g. `task <uuid> info` or `_get <uuid>.description`)
      -- a UUID is only as trustworthy as the citation that produced it.
      Also added the related mid-session gap found since this bean was filed:
      re-resolve a cached *integer* ID before acting on it (`done`/`annotate`/
      `modify`) if it was captured more than a few commands ago, since the
      pending list can renumber underneath a long-running session.
- [x] Consider whether agent-meta:park should say the same for any
      taskwarrior UUIDs it captures into a handoff -- added to
      plugins/agent-meta/skills/park/SKILL.md in pickled-claude-plugins
      (step 3 of "Before Writing": verify a cited UUID resolves before
      writing it into the handoff).
- [x] Re-run ./claudeconfig.sh after editing claude/rules/taskwarrior.md so
      the update reaches ~/.claude/rules/taskwarrior.md. Confirmed identical
      via diff.

## Resolution

Closed 2026-09-02. Taskwarrior task bc88db3c (was showing as ID 322) marked
done. This bean sat untouched for 4 weeks after filing -- during that window
at least three more live incidents of the same underlying pattern happened
(integer ID drift mid-session causing wrong-task `done`/`annotate` calls in
chirpfinder and elsewhere), confirmed via `cq` session review. The fix
landed covers both the original ask (verify a cited UUID before writing it
into a durable artifact) and the broader pattern (re-resolve any cached ID,
integer or UUID, before acting on it if time has passed).
