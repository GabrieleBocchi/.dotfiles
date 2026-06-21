#!/usr/bin/env bash

set -euo pipefail

echo "▸ Updating antidote plugins"
zsh -c '
  fpath=("$HOME/.local/share/antidote/functions" $fpath)
  autoload -Uz antidote
  antidote update
'
echo "✓ Antidote plugins updated"
