#!/usr/bin/env bats
#
# Tests for bin/claude-sandbox-guard (the PreToolUse/Bash sandbox hook).
# Run: bats test/   (bats-core is on the mise toolchain)
#
# Two layers:
#   1. Hand-written edge cases that pin the tricky parsing behaviour.
#   2. A data-driven sweep over real commands pulled from the session corpus
#      (test/fixtures/sandbox-guard-corpus.jsonl), labelled by intended decision.

GUARD="${BATS_TEST_DIRNAME}/../bin/claude-sandbox-guard"

# decision_for <command> [unsandboxed]
# echoes DENY or ALLOW. The hook only ever emits a deny decision, so non-empty
# output == DENY, empty == ALLOW (normal permission flow).
decision_for() {
  local json out
  if [ "${2:-}" = "unsandboxed" ]; then
    json=$(jq -nc --arg c "$1" '{tool_name:"Bash",tool_input:{command:$c,dangerouslyDisableSandbox:true}}')
  else
    json=$(jq -nc --arg c "$1" '{tool_name:"Bash",tool_input:{command:$c}}')
  fi
  out=$(printf '%s' "$json" | "$GUARD")
  if [ -z "$out" ]; then echo ALLOW; else echo DENY; fi
}

assert_deny()  { [ "$(decision_for "$1" "${2:-}")" = DENY ]  || { echo "expected DENY:  $1"; return 1; }; }
assert_allow() { [ "$(decision_for "$1" "${2:-}")" = ALLOW ] || { echo "expected ALLOW: $1"; return 1; }; }

# --- git writes: should DENY -------------------------------------------------

@test "git add is denied" { assert_deny "git add ."; }
@test "git commit is denied" { assert_deny 'git commit -m "fix"'; }
@test "git push is denied" { assert_deny "git push -u origin feature"; }
@test "git push with redirect is denied" { assert_deny "git push 2>&1 | tail -10"; }
@test "git worktree add is denied" { assert_deny "git worktree add ../foo"; }
@test "git stash (bare == push) is denied" { assert_deny "git stash"; }
@test "git stash push is denied" { assert_deny "git stash push -m wip"; }
@test "git submodule update is denied" { assert_deny "git submodule update --init"; }
@test "cd then git commit (compound) is denied" { assert_deny "cd /some/path && git commit -m x"; }
@test "git -C <path> push is denied" { assert_deny "git -C /repo push origin main"; }
@test "git -c k=v commit is denied" { assert_deny "git -c user.email=a@b.com commit -m x"; }
@test "git --no-pager add is denied" { assert_deny "git --no-pager add ."; }
@test "leading env assignment is denied" { assert_deny "FOO=1 git checkout -b new"; }
@test "commit message containing the word add is still denied" { assert_deny 'git commit -m "add stuff"'; }
@test "chained add && commit && push is denied" { assert_deny "git add -A && git commit -m x && git push"; }

# --- srb: should DENY --------------------------------------------------------

@test "srb tc is denied" { assert_deny "srb tc"; }
@test "bin/srb is denied" { assert_deny "bin/srb tc"; }
@test "bundle exec srb is denied" { assert_deny "bundle exec srb tc"; }

# --- reads / non-git / ambiguous list-forms: should ALLOW --------------------

@test "git log is allowed" { assert_allow "git log --oneline -5"; }
@test "git show is allowed" { assert_allow "git show HEAD"; }
@test "git status is allowed" { assert_allow "git status -sb"; }
@test "git diff is allowed" { assert_allow "git diff --stat"; }
@test "git branch list is allowed" { assert_allow "git branch -a"; }
@test "git config get is allowed" { assert_allow "git config user.email"; }
@test "git worktree list is allowed (read-only)" { assert_allow "git worktree list"; }
@test "git stash list is allowed (read-only)" { assert_allow "git stash list"; }
@test "git submodule status is allowed (read-only)" { assert_allow "git submodule status"; }
@test "plain ls is allowed" { assert_allow "ls -la"; }
@test "echo is allowed" { assert_allow "echo hi"; }
@test "rspec (not srb) is allowed" { assert_allow "bundle exec rspec"; }
@test "grep for the string git add is allowed" { assert_allow 'grep -rn "git add" .'; }
@test "cd then git status is allowed" { assert_allow "cd /p && git status"; }

# --- gating: already-unsandboxed and non-Bash tools ALLOW (no decision) ------

@test "git add already unsandboxed is not re-flagged" { assert_allow "git add ." unsandboxed; }

@test "non-Bash tool is ignored" {
  out=$(jq -nc '{tool_name:"Edit",tool_input:{file_path:"/x"}}' | "$GUARD")
  [ -z "$out" ]
}

# --- data-driven sweep over the real session corpus --------------------------

@test "real corpus: every labelled command gets the intended decision" {
  local fixture="${BATS_TEST_DIRNAME}/fixtures/sandbox-guard-corpus.jsonl"
  [ -f "$fixture" ] || skip "fixture missing"
  local fails=0 total=0 line expect cmd got
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    expect=$(jq -r '.expect' <<<"$line")
    cmd=$(jq -r '.command' <<<"$line")
    got=$(decision_for "$cmd")
    total=$((total + 1))
    if [ "$got" != "$expect" ]; then
      echo "MISMATCH want=$expect got=$got :: $cmd"
      fails=$((fails + 1))
    fi
  done <"$fixture"
  echo "checked $total corpus commands, $fails mismatches"
  [ "$fails" -eq 0 ]
}
