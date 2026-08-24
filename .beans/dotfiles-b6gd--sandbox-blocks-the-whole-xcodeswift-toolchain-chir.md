---
# dotfiles-b6gd
title: Sandbox blocks the whole Xcode/Swift toolchain (chirpfinder)
status: todo
type: bug
priority: normal
created_at: 2026-08-24T13:22:07Z
updated_at: 2026-08-24T13:22:07Z
---

chirpfinder had 507 dangerouslyDisableSandbox Bash calls - the toolchain is effectively unusable sandboxed. All 20 xcode/swiftpm/simulator denials in Jul-Aug are chirpfinder.

Blocked paths:
- $DARWIN_USER_TEMP_DIR (/var/folders/w0/<hash>/T) - xcodegen generate fails with NSCocoaErrorDomain 513 'You don't have permission to save the file X in the folder T'. Setting TMPDIR does NOT help: BSD mktemp and Foundation's itemReplacementDirectory both use confstr(_CS_DARWIN_USER_TEMP_DIR) and ignore TMPDIR. Confirmed live 2026-08-24: 'mktemp -d' -> mkdtemp failed on /var/folders/.../T
- $DARWIN_USER_CACHE_DIR (/var/folders/w0/<hash>/C/clang/ModuleCache) - swiftc: 'unable to open output file ...SwiftShims.pcm: Operation not permitted', 'couldn't create cache file xcrun_db'
- ~/Library/org.swift.swiftpm/{configuration,security} - swift test warns 'not accessible or not writable, disabling user-level cache features'
- ~/Library/Developer/Xcode/DerivedData - xcodebuild
- ~/Library/Logs/CoreSimulator - xcodebuild/simctl
- 'sandbox-exec: sandbox_apply: Operation not permitted' (23 hits) - nested sandbox, xcodebuild spawning its own sandboxed helpers

## Checklist
- [ ] Create claude/stacks/xcode.jsonc with allowWrite for ~/Library/Developer/Xcode, ~/Library/org.swift.swiftpm, ~/Library/Logs/CoreSimulator, ~/Library/Caches/org.swift.swiftpm
- [ ] Figure out whether /var/folders/<...>/{T,C} can be allowlisted at all (machine-specific path; may be blocked by the same non-~ stripping as /tmp)
- [ ] Test whether nested sandbox-exec can ever work; if not, document that xcodebuild/simctl always need dangerouslyDisableSandbox
- [ ] Add the conclusion to chirpfinder's CLAUDE.md so agents stop rediscovering it
