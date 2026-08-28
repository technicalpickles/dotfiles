---
# dotfiles-b6gd
title: Sandbox blocks the whole Xcode/Swift toolchain (chirpfinder)
status: todo
type: bug
priority: normal
created_at: 2026-08-24T13:22:07Z
updated_at: 2026-08-24T13:46:02Z
---

chirpfinder had 507 dangerouslyDisableSandbox Bash calls - the toolchain is effectively unusable sandboxed. All 20 xcode/swiftpm/simulator denials in Jul-Aug are chirpfinder.

Blocked paths:
- $DARWIN_USER_TEMP_DIR (/var/folders/w0/<hash>/T) - xcodegen generate fails with NSCocoaErrorDomain 513 'You don't have permission to save the file X in the folder T'. Setting TMPDIR does NOT help: BSD mktemp and Foundation's itemReplacementDirectory both use confstr(_CS_DARWIN_USER_TEMP_DIR) and ignore TMPDIR.
- $DARWIN_USER_CACHE_DIR (/var/folders/w0/<hash>/C/clang/ModuleCache) - swiftc: 'unable to open output file ...SwiftShims.pcm: Operation not permitted', 'couldn't create cache file xcrun_db'
- ~/Library/org.swift.swiftpm/{configuration,security} - swift test warns 'not accessible or not writable, disabling user-level cache features'
- ~/Library/Developer/Xcode/DerivedData - xcodebuild
- ~/Library/Logs/CoreSimulator - xcodebuild/simctl
- 'sandbox-exec: sandbox_apply: Operation not permitted' (23 hits) - nested sandbox, xcodebuild spawning its own sandboxed helpers

## UPDATE 2026-08-24: /var/folders IS allowlistable (ADR 0050)

The blocker here was believed dead -- dotfiles-uxr8 hypothesized that non-`~`-rooted
absolute paths get stripped, making /var/folders permanently unallowlistable. That
hypothesis is REFUTED. See [ADR 0050](doc/adr/0050-canonicalize-sandbox-allowwrite-paths.md).

The real cause is macOS symlink canonicalization: /var is a symlink to /private/var and
Seatbelt matches the resolved path, so a rule from "/var/folders/..." never fires. Spell
it "/private/var/folders/..." and it works.

Already fixed and verified: DARWIN_USER_TEMP_DIR (/T) is now injected automatically by
claudeconfig.sh as /private$(getconf DARWIN_USER_TEMP_DIR). `mktemp` works sandboxed.
That knocks out the first bullet above.

Remaining for this bean: DARWIN_USER_CACHE_DIR (/C) is NOT injected -- it was deliberately
left out to keep the temp allowance narrow. The xcode stack should add it as
/private$(getconf DARWIN_USER_CACHE_DIR), which needs the same generate-time computation
claudeconfig.sh now does for /T (the path is per-user/per-machine, so it cannot be a static
jsonc entry).

## Checklist
- [ ] Create claude/stacks/xcode.jsonc with allowWrite for ~/Library/Developer/Xcode, ~/Library/org.swift.swiftpm, ~/Library/Logs/CoreSimulator, ~/Library/Caches/org.swift.swiftpm
- [x] Figure out whether /var/folders/<...>/{T,C} can be allowlisted at all -- YES, via the /private prefix. /T done; /C still to do.
- [ ] Extend claudeconfig.sh to also inject /private$(getconf DARWIN_USER_CACHE_DIR), ideally only when the xcode stack is active
- [ ] Test whether nested sandbox-exec can ever work; if not, document that xcodebuild/simctl always need dangerouslyDisableSandbox
- [ ] Add the conclusion to chirpfinder's CLAUDE.md so agents stop rediscovering it
