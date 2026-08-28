# 46. declarative herdr plugin manifest

Date: 2026-08-07

## Status

Accepted

## Context

herdr (the terminal multiplexer) has its own plugin system, separate from anything dotfiles manages. Plugins are installed with `herdr plugin install <owner/repo>` (or `herdr plugin link <path>` for local ones), and that state -- the cloned plugin sources, build artifacts, and `plugins.json`/`.plugins.lock` -- lives entirely under `~/.config/herdr/plugins/`. That directory is deliberately _not_ symlinked into the repo (see the `config/herdr/config.toml` comment and `functions.sh`'s `link_directory_contents` skip list): herdr keeps live sockets, `session.json`, and logs alongside it, and a directory symlink would put that runtime state where `git clean -xfd` could eat it.

The consequence: nothing in dotfiles ever runs `herdr plugin install`/`link`. Every plugin has been a manual, undocumented, per-machine step. This surfaced concretely on 2026-08-07: `config/herdr/config.toml`'s keybindings (git-tracked, synced normally) reference the `chmarax.herdr-nvim` plugin action, and the companion nvim-side Lua plugin (`~/.config/nvim/lua/plugins/herdr-nvim.lua`, a separate repo) had been pulled -- but the herdr-side plugin itself was never installed on the second machine, so the integration silently didn't work. `config.toml` only carries plugin _IDs_ (e.g. `chmarax.herdr-nvim.pick-file`); there's no naming convention that reliably derives an install source (`owner/repo`, or a local path) from an ID, so config.toml alone can't drive automated installs.

## Decision

Add `config/herdr/plugins.toml`, a small git-tracked manifest declaring every plugin herdr should have, as `(id, source)` pairs:

```toml
[[plugin]]
id = "chmarax.herdr-nvim"
github = "ChmaraX/herdr-nvim"

[[plugin]]
id = "tds.keymap"
local = "~/github.com/technicalpickles/herdr-keymap"
```

Add `herdr.sh`, following the same shape as `skills.sh` (which restores agent skills from `agents/.skill-lock.json` the same way): guard on `command_available herdr`, read currently-installed plugin IDs via `herdr plugin list --json | jq`, parse the manifest with `yq -p toml -o json` (both already unconditional Brewfile deps), and for each manifest entry not already installed, run `herdr plugin install <github> --yes` or `herdr plugin link <local>`. Wire `./herdr.sh` into `install.sh` alongside `./skills.sh`, so a fresh or catch-up machine restores the full plugin set automatically.

### Alternatives Considered

1. **Hardcode the (id, source) list directly in `herdr.sh`**

   - Pros: one file instead of two.
   - Cons: the script itself needs editing every time a plugin is added or removed, rather than a config change. Rejected -- `plugins.toml` keeps `herdr.sh` generic and the plugin set is then just data, matching how `config/herdr/config.toml` itself is already data-driven.

2. **Symlink `~/.config/herdr/plugins/` into the repo**

   - Rejected outright, and not reconsidered here: this is exactly what the existing file-only-link comment in `config/herdr/config.toml` already rules out, since it would put live sockets/logs/session state under git.

3. **Derive plugin sources from `config/herdr/config.toml`'s `[[keys.command]]` entries**
   - The `command = "<plugin_id>.<action>"` strings do reveal which plugin IDs are _used_, but not where to install them from -- `jt.command-palette`'s ID gives no way to derive `JanTvrdik/herdr-command-palette`. Some explicit id-to-source mapping is unavoidable; `plugins.toml` is that mapping, kept separate from the keybinding config it's referenced by.

## Consequences

### Positive

- `./herdr.sh` (called standalone, or via `./install.sh`) brings any machine's herdr plugin set in line with the declared manifest in one step, closing the "works on one machine, not another" failure mode this ADR was written in response to.
- Adding, removing, or re-sourcing a plugin is a one-line edit to `plugins.toml`, not a script change.

### Negative

- `plugins.toml` is a second place (beyond `config.toml`'s keybindings) that has to be kept in sync by hand when a plugin is added -- nothing enforces that the two agree. Mitigated with a note in `plugins.toml` itself and in `CLAUDE.md` to update it alongside any `herdr plugin install`/`link` run.
- `herdr plugin install`'s idempotency under repeated `--yes` runs wasn't verified against the live CLI (all plugins were already installed on the machine this was built on); `herdr.sh` guards against re-installing by checking `herdr plugin list --json` first rather than relying on the CLI's own behavior.

## Related, not addressed here

`install.sh` never symlinks `config/herdr/config.toml` at all -- only the standalone `./symlinks.sh` does (it has its own duplicate of `link_directory_contents` plus the herdr special case that `install.sh` lacks). A fresh `./install.sh` run therefore restores plugins via `herdr.sh` but not the config symlink itself. Pre-existing gap, not introduced or fixed here.
