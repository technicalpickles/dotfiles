---
# dotfiles-4tco
title: Make dotfiles + this Mac compatible with hardened Homebrew
status: in-progress
type: feature
priority: normal
created_at: 2026-10-04T15:16:20Z
updated_at: 2026-10-04T17:30:17Z
---

Migrate this machine (and the dotfiles install flow) to be compatible with automic-vault's hardened Homebrew (`av harden brew`). Survey done 2026-10-04.

## Constraints from hardened brew (automic-vault `src/isotopes/hardeners/homebrew.md`, `src/brew_stub/main.rs`)

- brew runs setuid as `automic`, `HOME=/opt/homebrew/var/automic`, env scrubbed, `/opt/homebrew` owned `automic:vault`.
- **`brew services` unsupported**; hardening refuses while any service is loaded/registered. Undocumented why, but follows from: launchd plist lands in automic's HOME not ours, can't bootstrap into our gui domain, and service state/logs live in the now-protected prefix.
- **Casks rejected** unless official `homebrew/cask`, `binary` artifacts only, targets directly in `/opt/homebrew/bin`. Hardening refuses while Caskroom has anything else.
- **`brew bundle` is unavailable** (stub hard-errors). `functions.sh:205` pipes Brewfiles into `brew bundle` -> install.sh breaks.
- Mutations without `--cask` are pinned to `--formula`, so `brew 'orbstack'` in Brewfile.home (which bundle silently resolves to the cask) will fail.
- Third-party *formula* taps are fine (markjaquith/tap, buildkite/buildkite).
- Each install/upgrade needs menu bar Approval at Read & Update level, so batch into one `brew install --formula a b c` call.

## Services

| formula | state | action |
|---|---|---|
| ollama | `brew services` started (installed ad hoc, not in Brewfile) | dotfiles LaunchAgent `LaunchAgents/arm64-macos/com.technicalpickles.ollama.plist`; keep `OLLAMA_FLASH_ATTENTION=1`, `OLLAMA_KV_CACHE_TYPE=q8_0`; logs to `~/Library/Logs/ollama.log`, WorkingDirectory out of `/opt/homebrew/var` |
| gost | not a brew service | already run by `com.technicalpickles.agent-ssh-relay` |
| sleepwatcher | not a brew service | already run by `com.technicalpickles.karabiner-wake-fix` |

## Casks (27 installed)

**Keep as cask (allowed):** `1password-cli`, `mitmproxy` (official, binary-only). Verify the hardener accepts them.

**CLI cask from 3rd-party tap:** `beans` (hmans/beans) -> install via mise (`github:hmans/beans` backend) or release binary; untap hmans/beans.

**Apps -> install directly, let them self-update** (all have built-in updaters):

| cask | in Brewfile? | notes |
|---|---|---|
| cleanshot, dash, finicky, hammerspoon, obsidian, claude, claude-devtools | Brewfile | hammerspoon loses `hs` cask binary (use `hs.ipc.cliInstall()`); obsidian loses cask CLI link; claude-devtools: confirm it has an updater |
| discord, google-chrome, slack, zoom, karabiner-elements, spotify, raycast, orbstack | Brewfile.home | karabiner/zoom are pkgs; uninstall via cask first is fine, then reinstall from vendor. `karabiner_cli` lives in the app bundle anyway. orbstack manages its own `~/.orbstack/bin`. Slack also on MAS |
| granola, wispr-flow | Brewfile.work | work machine, same treatment |
| chatgpt, dropbox, google-drive, ghostty, jordanbaird-ice, open-webui, openclaw, playcover-community, telegram | ad hoc | ghostty loses cask-linked completions/manpage (shell integration from app bundle still works). Telegram also on MAS |

Removing via `brew uninstall --cask` deletes the .app; instead, to keep apps in place, drop the Caskroom entry without touching /Applications (e.g. `rm -rf /opt/homebrew/Caskroom/<name>` while unhardened, then confirm the app still launches/updates). Decide per-app.

## Declarative replacement for Brewfile casks

- Formulae: replace `brew bundle` in `functions.sh` with: parse `tap`/`brew` lines, `brew tap` missing taps, compute missing formulae vs `brew list --formula`, one `brew install --formula ...` call. Fix `brew 'orbstack'`.
- Apps: move `cask` lines to an apps manifest (e.g. `Appfile` / `apps.<role>`), each with bundle name + source (vendor URL or `mas` id). `install.sh` / `dotfiles-doctor` report missing apps with the download link instead of auto-installing (no unattended DMG downloads). Optional: `mas` for the couple of MAS-available apps.
- Rejected: a second user-owned Homebrew just for casks. Makes `brew` ambiguous and reopens unattended agent installs the vault is meant to gate.

## Checklist

- [ ] ollama -> dotfiles LaunchAgent; `brew services stop ollama`; verify `:11434`
- [ ] beans -> mise; untap hmans/beans
- [ ] Replace `brew bundle` in functions.sh with formula-only installer; fix `brew 'orbstack'`
- [ ] Apps manifest + doctor check; move all `cask` lines out of Brewfiles (keep 1password-cli, mitmproxy as `--cask` explicit installs)
- [ ] Detach each app cask from Caskroom, confirm app still updates
- [ ] ADR for "apps are not Homebrew-managed under hardened brew"
- [ ] `av harden brew`, then `install.sh` end to end

## Plan

`doc/plans/2026-10-04-hardened-homebrew.md` (branch `hardened-brew`)

## Status (2026-10-04)

Repo work done on branch `hardened-brew` (ADR 0058, ollama agent, beans via mise, `brew_install_brewfiles`, stub-aware shells, Appfile + doctor, `scripts/detach-cask.sh`). Remaining: the plan's `cutover` task (user-run after merge). Follow-ups: dotfiles-gp5r (lefthook), dotfiles-i4a9 (bash login PATH order).
