#!/bin/sh

set -eu

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# Bootstrap the environment
. "$DOTFILES_DIR/scripts/pkg-utils.sh" && bootstrap_env

TARGET_VERSION="$(cat "$DOTFILES_DIR/.chezmoiversion")"
BIN_DIR="/usr/local/bin"

current_ver=$("$BIN_DIR/chezmoi" --version 2>/dev/null | awk '{print $3}' | tr -d 'v,')
if [ "$current_ver" != "$TARGET_VERSION" ]; then
    echo "▸ Installing chezmoi ${TARGET_VERSION}..."
    # TODO: remove when upstream get.chezmoi.io handles libc detection
    if [ -x /lib/ld-musl-x86_64.so.1 ] || [ -x /lib/ld-musl-aarch64.so.1 ]; then
        chezmoi_url="https://github.com/twpayne/chezmoi/releases/download/v${TARGET_VERSION}/chezmoi-linux-amd64-musl"
        curl -fsSL "$chezmoi_url" -o /tmp/chezmoi
        sudo install -m 755 /tmp/chezmoi "$BIN_DIR/chezmoi"
    else
        curl -fsLS get.chezmoi.io | sudo sh -s -- -t "v${TARGET_VERSION}" -b "$BIN_DIR"
    fi
    echo "✓ chezmoi ${TARGET_VERSION} installed"
fi

echo "▸ Applying chezmoi configuration"
"$BIN_DIR/chezmoi" init --source "$DOTFILES_DIR" --apply
echo "✓ chezmoi configuration applied"
