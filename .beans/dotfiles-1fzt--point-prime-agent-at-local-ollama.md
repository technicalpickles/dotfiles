---
# dotfiles-1fzt
title: Point prime-agent at local Ollama
status: in-progress
type: task
created_at: 2026-10-23T14:56:42Z
updated_at: 2026-10-23T14:56:42Z
---

prime-agent has no built-in Ollama. Add a custom provider in prime/models.json (localhost:11434/v1, cloud models via the local server's sign-in, so no key) and link it from prime.sh. safehouse already allows outbound IP, so localhost works under safe. Supersedes the Ollama Cloud key question.
