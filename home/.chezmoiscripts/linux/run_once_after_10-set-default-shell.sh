#!/usr/bin/env bash

set -euo pipefail

shell_name=zsh

shell_path="$(command -v $shell_name)"
user="$(id -un)"

if [[ "$(getent passwd "$user" | cut -d: -f7)" != "$shell_path" ]]; then
    echo "▸ Setting default shell to $shell_name..."
    sudo chsh -s "$shell_path" "$user"
    echo "✓ Default shell set to $shell_name"
fi
