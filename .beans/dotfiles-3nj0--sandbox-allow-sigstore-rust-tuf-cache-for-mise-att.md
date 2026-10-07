---
# dotfiles-3nj0
title: 'Sandbox: allow sigstore-rust TUF cache for mise attestation checks'
status: todo
type: bug
created_at: 2026-10-07T02:28:38Z
updated_at: 2026-10-07T02:28:38Z
---

mise install of a github: tool with attestations (e.g. codebase-memory-mcp 0.11.0) fails sandboxed: sigstore-rust writes its TUF cache to ~/Library/Caches/dev.sigstore.sigstore-rust/tuf/... and gets EPERM. PR #47 allowlisted the tuf-repo-cdn.sigstore.dev host only. Add ~/Library/Caches/dev.sigstore.sigstore-rust to allowWrite in claude/stacks/mise.jsonc (and github.jsonc if gh attestation uses the same path), re-run claudeconfig.sh, retry a sandboxed mise install. Found 2026-10-06.
