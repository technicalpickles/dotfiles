---
# dotfiles-a1kx
title: Back the app manifest with the Homebrew cask API + Team ID pins
status: draft
type: feature
created_at: 2026-10-04T19:40:14Z
updated_at: 2026-10-04T19:40:14Z
---

Follow-up to dotfiles-4tco / ADR 0058 (hardened Homebrew). Today `Caskfile*` (renamed from `Appfile` 2026-10-04) is `<Bundle>.app | <vendor URL>`, maintained by hand, and doctor only reports missing apps.

## Research (2026-10-04)

- **Mac App Store:** only Slack is a real Mac listing (`mas` id 803453959). Spotify and Obsidian bundle-ID lookups hit their iOS/iPad apps, not Mac ones. Not worth wiring `mas` in for one app.
- **Cask JSON API** (`https://formulae.brew.sh/api/cask/<token>.json`): every app in the manifest has a cask. It gives url, version, sha256, artifacts (app name), homepage, auto_updates. Caveats: google-chrome and spotify are `sha256 no_check`; zoom and karabiner-elements are `pkg`; finicky has `auto_updates: null` (no self-updater). No Team ID in the data.
- **Other tools surveyed:** Installomator (Team ID verification, root-only; no labels for hammerspoon/finicky/dash), Munki/AutoPkg (fleet-scale, root daemon), nix-darwin (heavy; homebrew module still uses casks), Applite/Topgrade (drive brew, blocked), MacUpdater (dead Jan 2026), Latest (read-only checker). None declare GUI apps in a manifest outside brew.
- **Name clash:** fastlane uses `Appfile` for something unrelated, hence the rename to `Caskfile`.

## Team IDs (from `codesign -dv` on installed apps, 2026-10-04)

cleanshot AFJU4P8ZV4, dash JP58VMK957, finicky C3XWNKDP3M, hammerspoon VQCYSNZB89, obsidian 6JSW4SJWN9, claude Q6L2SF6YDW, claude-devtools 55PSHY2MW6, discord 53Q6R32WPB, google-chrome EQHXZ8M8AV, slack BQR82RBBHL, zoom BJ4HAAB9B3, karabiner-elements G43BCU2T37, spotify 2FNC3A47ZF, raycast SY64MV22J9, orbstack HUAQ24HBR6. wispr-flow: pull on the work machine.

## Proposed shape

- Manifest keyed by cask token + pinned Team ID (`spotify  2FNC3A47ZF`); app name/homepage/URL derived from the cask API.
- Doctor: missing -> install hint; signer != pin -> flag (catches a swapped .app); optional "behind cask version" check (covers finicky, replaces MacUpdater).
- Maybe a user-run `app-install <token>`: download, check sha256 when present, verify Team ID pin, copy to /Applications; pkg casks hand off to Installer. Never called from install.sh.

## Checklist

- [x] Pick a new name for the manifest: `Caskfile` (done in #46)
- [ ] New manifest format + parser in functions.sh
- [ ] Doctor: Team ID verification
- [ ] Doctor: version-behind check (optional)
- [ ] Decide on user-run installer
- [ ] Update ADR 0058 (or new ADR) with the decision
