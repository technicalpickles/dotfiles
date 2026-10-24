# Diagnosing silent failures under `safe` (agent-safehouse)

How we tracked down `safe cloudsmith whoami` exiting 255 with no output, on 2026-10-23. The method generalizes to any tool that dies under `safe` with no message and no logged deny.

## Symptom

- `safe <tool> ...` exits non-zero (here 255) with **nothing** on stdout or stderr.
- `safe -- /usr/bin/true` is fine, so the wrapper itself works.
- Works from `~`, fails from every other cwd (`/tmp`, `~/Downloads`, `~/pickleton`).
- `log show` for Sandbox denies matching the tool shows **nothing**.

## Method

1. **Reproduce from a real terminal, not nested inside Claude Code's sandbox.** A `safe` run launched from a Claude Bash call is sandbox-in-sandbox and gave inconsistent results (a cwd passed once and failed later). Drive a detached tmux session instead, write results to a file, read the file back:

   ```fish
   tmux new-session -d -s probe -c /tmp
   tmux send-keys -t probe 'safe cloudsmith --version; echo "rc=$status" > /tmp/out.txt' Enter
   ```

   The role matters too: the tool's shell reports `DOTPICKLES_ROLE=work`, an agent Bash tool may not. A policy generated in the wrong role has different grants and sends you down the wrong path (we lost a round on this).

2. **Vary one thing at a time.** The cwd matrix (`~` passes, everything else fails) was the first real signal. Invocation shape (`safe cloudsmith`, `safe -- /full/path`, `safe -- sh -c ...`) made no difference.

3. **Diff the generated policies** for a passing and a failing cwd. `safe --stdout` prints the policy without running anything:

   ```fish
   cd ~;   safe --stdout > /tmp/pol-home.sb
   cd /tmp; safe --stdout > /tmp/pol-tmp.sb
   diff /tmp/pol-home.sb /tmp/pol-tmp.sb
   ```

   Here the only substantive difference was the workdir grant: from `~`, safehouse grants all of home read-write. So the tool needs _something under home_ the profile doesn't grant.

4. **Reproduce without the wrapper.** `sandbox-exec -f policy.sb <command>` fails the same way, which takes `safe`'s env handling out of the picture and makes each experiment one line.

5. **Bisect grants onto the failing policy.** Append one allow rule per variant to a copy of the policy and see which flips the exit code. Narrow in steps:

   | Rule appended                                            | Result   |
   | -------------------------------------------------------- | -------- |
   | `subpath ~`                                              | pass     |
   | `subpath ~/Library`                                      | pass     |
   | `subpath ~/Library/Caches`                               | pass     |
   | each single existing entry under `Caches`, one at a time | all fail |
   | `file-read*` on `literal ~/Library/Caches`               | pass     |
   | `file-read-metadata` on `literal ~/Library/Caches`       | pass     |
   | `file-read-data` on `literal ~/Library/Caches`           | fail     |

   "The whole dir passes but no child does" means the process touches the **directory itself** (a stat), not anything inside. Then split `file-read*` into its operations (`file-read-metadata` vs `file-read-data`) to find the minimum.

6. **Fix in the profile, re-verify end to end.** Apply the narrowest rule, then run the original command from a bad cwd.

## Cause

`role-work.sb` granted `~/Library/Caches/dotslash` but not a stat of its parent. Dotslash-launched tools (`/opt/gusto/bin/cloudsmith`, `pi`, ...) stat `~/Library/Caches` and exit 255 when it's denied. Fix: `(allow file-read-metadata (home-literal "/Library/Caches"))` in `role-work.sb`.

## Gotchas

- **Denies can be silent.** `log show --predicate 'eventMessage CONTAINS "deny"'` found nothing for the tool's process. Don't conclude "not the sandbox" from an empty log. Use the on/off bisect instead. Use `/usr/bin/log`: zsh's `log` builtin eats the arguments.
- **`(trace ...)` doesn't exist** in this SBPL (`unbound variable: trace`), so there's no free syscall trace. Bisecting grants is the substitute.
- **Fish:** `$?` is a parse error. Use `$status`, `$pipestatus[1]`.
- **Directory vs contents.** `subpath` covers a dir and everything under it; `literal` covers only the node itself. Failures that only a whole-parent grant fixes are usually a missing `literal` on a parent.
- **A stale daemon keeps its old profile** (see the prime-agent daemon note): `prime-agent shutdown` after changing profiles.
- **Test the fix with the branch's profile,** not `~/.config/agent-safehouse` (a symlink into `worktrees/main`): call `safehouse --append-profile=<worktree>/common.sb --append-profile=<worktree>/role-work.sb -- <cmd>` directly.
