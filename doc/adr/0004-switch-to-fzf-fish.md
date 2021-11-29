# 4. switch to fzf.fish

Date: 2021-11-29

## Status

Accepted

## Context

fzf comes with its own Fish extension: https://github.com/junegunn/fzf/blob/master/shell/key-bindings.fish

[fzf.fish](https://github.com/PatrickF1/fzf.fish) is a plugin to "Augment your Fish command line with mnemonic key bindings to efficiently find what you need using fzf."



## Decision

Switch to fzf.fish

## Consequences

iTerm requires additional configuration for the bindings to work. [discussion](https://github.com/PatrickF1/fzf.fish/discussions/97)

Additional package required, `fd`
