#!/usr/bin/env bash

set -euo pipefail

shell_name=zsh

shell_path="$(command -v $shell_name)"

if [[ "$SHELL" != "$shell_path" ]]; then
    echo "▸ Setting default shell to $shell_name..."
    chsh -s "$shell_path"
    echo "✓ Default shell set to $shell_name"
fi
