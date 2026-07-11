#!/usr/bin/env bash

set -euo pipefail

if [ ! -f "$HOME/.cargo/bin/rustup" ]; then
    echo "▸ Installing Rust"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    echo "✓ Rust installed"
fi

. "$HOME/.cargo/env"

echo "▸ Updating Rust toolchain"
rustup update
echo "✓ Rust toolchain updated"
