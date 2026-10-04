# 58. Hardened Homebrew compatibility

Date: 2026-10-04

## Status

Accepted

## Context

automic-vault's Homebrew hardener (`av harden brew`) makes `/opt/homebrew`
owned by a dedicated `automic` user and installs a setuid launcher at
`/usr/local/bin/brew` that gates every brew command behind menu-bar approval.
This stops same-user code (malware, agents) from replacing installed tools.

Under it:

- `brew services` is unsupported. Hardening refuses while any service is
  loaded or registered. Upstream doesn't document why, but it follows from the
  design: brew runs as `automic` with `HOME=/opt/homebrew/var/automic`, so it
  can't install a plist into our `~/Library/LaunchAgents` or bootstrap into our
  `gui/<uid>` launchd domain, and service logs/state live in the now-protected
  prefix.
- `brew bundle` is refused outright, because Brewfiles may contain casks.
- Casks are refused unless they're official, CLI-only (`binary` artifacts into
  `/opt/homebrew/bin`). App and pkg casks reach outside the prefix.
- Shell startup must use `/usr/local/bin/brew` and put `/usr/local/bin` ahead
  of `/opt/homebrew/bin`.

## Decision

- Long-running services are dotfiles LaunchAgents (`LaunchAgents/`), pointing
  at stable `/opt/homebrew/opt/<formula>/bin/...` paths, with logs outside
  `/opt/homebrew`. This was already the pattern for gost and sleepwatcher.
- `install.sh` installs formulae (and CLI-only casks) with
  `brew_install_brewfiles` in `functions.sh`: one `brew install --formula`
  call for whatever is missing, so approval fires once.
- Mac apps are listed in `Appfile`/`Appfile.<role>` and installed by hand from
  the vendor. They update themselves. `install.sh` and `bin/dotfiles-doctor`
  report missing ones with a download link; nothing downloads installers
  unattended.
- Shell setup (`home/.zshenv`, `config/fish/conf.d/__homebrew.fish`,
  `load_brew_shellenv`) detects the launcher by its setuid bit and sets the
  Homebrew env statically, so no brew process spawns per shell start.

## Consequences

- No more `brew upgrade` for apps; each app's own updater handles it. Finicky
  has no auto-updater and needs a manual check now and then.
- A second user-owned Homebrew just for casks was rejected: it makes `brew`
  ambiguous and reopens the unattended installs the vault exists to gate.
- When `av harden brew` offers to rewrite shell startup files, answer N; the
  repo's files already handle both modes.
- Unhardened machines (work, containers) behave exactly as before.
