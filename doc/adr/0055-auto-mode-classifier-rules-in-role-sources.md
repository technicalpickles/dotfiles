# 55. Auto mode classifier rules in role sources

Date: 2026-09-08

## Status

2026-09-08 accepted

## Context and Problem Statement

Claude Code's auto mode adjudicates each tool call with an LLM classifier before running it. The classifier's judgement is shaped by an `autoMode` block in settings: `allow`, `soft_deny` and `hard_deny` rules, plus an `environment` array describing the org, its infrastructure, and what counts as sensitive. Running `/auto-mode-setup` mines the repo, shell history and past denials and writes that block.

It writes it to `~/.claude/settings.json`, which `claudeconfig.sh` regenerates from `claude/roles/` and `claude/stacks/`. Only `enabledPlugins` and `extraKnownMarketplaces` are preserved across a regeneration. Everything else is replaced, so a generated `autoMode` block survives until the next `./claudeconfig.sh` and then disappears without a word.

This is not theoretical. The block generated on 2026-09-08 was gone from `~/.claude/settings.json` within the hour, before any regeneration ran, recovered only because its text was still in the session transcript.

The obvious fix, checking the rules into the repo's own `.claude/settings.json`, does not work. Claude Code reads `autoMode` from user, `--settings` and managed settings only. It looks at project and local settings, and when it finds valid rules there it logs `settings autoMode in projectSettings ignored — only user/flag/managed settings may set classifier rules (projectSettings and localSettings are repo-controllable)` and drops them. A repo you clone must not be able to talk the classifier into trusting it. So these rules have to reach the generated user settings file, which means they have to live in this repo's role sources.

That raises a second problem. The `environment` block is a description of an employer: organization name, internal hostnames, deploy targets, protected namespaces. This repo is public. The home-role picture is fine to publish. The work-role picture is not.

## Decision Drivers

- A silent wipe is the worst failure mode here. Nothing errors, and the classifier quietly falls back to shipped defaults.
- The two roles need genuinely different answers. A classifier told `Organization: None configured` reads an upload to a company host as an upload to a stranger.
- Anything shared between home and work should be written once.
- This repo is public and stays public.

## Considered Options

- Add `autoMode` to the preserved-keys list so regeneration leaves the live block alone.
- Keep the whole block in `base.jsonc`, one copy for every role.
- Put the shared part in `base.jsonc`, let roles and stacks contribute the rest, and keep the work-role part in a file outside this repo.

## Decision Outcome

The third option.

**`autoMode` is generated, not preserved.** It joins `permissions` and `sandbox` as a key merged across `base.jsonc`, the active role, every stack, and finally a private overlay. Preserving the live block instead would have left the source of truth in a file that `/auto-mode-setup`, `claude auto-mode reset` and this script all write, with no record of what any of them decided.

**Stacks contribute too.** `beans.jsonc` carries the classifier carve-out for `beans` next to the permissions entry for `beans`, rather than that rule living in `base.jsonc` away from everything else about the tool.

**The arrays concatenate in source order and are never sorted.** This is the opposite of every other array in `claudeconfig.sh`, which ends in `unique | sort`, and the reason is that order carries meaning here:

- `$defaults` is a splice point, not a flag. The settings schema describes it as "include the literal string `$defaults` to inherit the built-in rules at that position". Sorting moves the shipped rules to wherever the sort puts the sentinel.
- A non-empty `allow`, `soft_deny` or `hard_deny` that lacks `$defaults` **replaces** the shipped rules rather than extending them. A stack adding one narrow carve-out would silently delete every built-in rule. The generator prepends `$defaults` when it is missing.
- `environment` is a structured document, not a set. Its `### Org-wide` and `### User-specific` headers group the bullets that follow them, and the bullets come from a fixed label list. Sorting scatters bullets out from under their headers.

Because `environment` is header-grouped, plain concatenation is not enough either: home's Org-wide bullets would land after base's User-specific ones. The generator regroups by section, and within a section a later source's bullet **replaces** an earlier one carrying the same `**Label**`, keeping the position the earlier one established. Role beats base, the same way role beats base for every scalar in the script. That is what lets `base.jsonc` hold the shipped "None configured" text for the org-shaped slots (correct as written under the home role) while the work role overrides just the ones that differ.

**The work role's environment lives outside this repo,** at `~/.config/dotpickles/roles/<role>.jsonc`, merged last so it wins over base, role and stacks alike. It is a full role file, not an `autoMode`-only one: same schema, same merge rules.

Outside rather than gitignored inside. A gitignored `claude/roles/work.private.jsonc` would sit one `git add -f` from being public, and would vanish on a fresh clone of dotfiles.

That last risk does not disappear by moving the file, it just changes shape: the overlay is now absent on a machine that has never had one, and the work role would generate with base's placeholder answers. So a role file can declare `"requiresPrivateOverlay": true` and the generator warns loudly when the overlay is missing, matching the existing loud guard for a missing role file. The flag is stripped before writing settings.

### Consequences

- `claude auto-mode reset` and any future `/auto-mode-setup` run write the live file and are undone by the next `./claudeconfig.sh`. The generated-key contract now covers a key that has a CLI actively inviting you to edit it. Port changes back to source.
- A machine's work-role classifier context is only as good as its overlay, which is hand-carried. There is no sync.
- `base.jsonc` describes a posture that is accurate at home and placeholder at work. That asymmetry is deliberate and is what the `requiresPrivateOverlay` guard exists to make loud.
