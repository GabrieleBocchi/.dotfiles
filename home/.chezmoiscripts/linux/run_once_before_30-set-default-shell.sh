#!/usr/bin/env bash

set -euo pipefail

if [[ "$SHELL" != "$(command -v zsh)" ]]; then
    echo "▸ Setting default shell to zsh"
    chsh -s "$(command -v zsh)"
    echo "✓ Default shell set to zsh"
fi
