<!-- dotpickles_role: home,coi-host -->

## Private-Repo Comments: Post Without a Draft Step

Comments on PRs and issues in the user's own private repos (`technicalpickles/*`) go out without showing a draft first. This overrides `git:pull-request`'s confirm step for those comments.

**Why:** a private repo under the user's account has no outside audience, so the draft step is friction (the user's call, 2026-11-04).

**How to apply:**

- Check `gh repo view <repo> --json visibility` when unsure. Public repos, org-owned repos, and anyone else's repo keep the confirm step.
- Still write in the user's voice, with no em-dashes.
- This covers comments only. Committing, pushing, opening and merging PRs follow their own rules.
