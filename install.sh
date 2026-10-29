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
    # (only amd64 has a separate musl build).
    if is_musl && [ "$(uname -m)" = "x86_64" ]; then
        chezmoi_url="https://github.com/twpayne/chezmoi/releases/download/v${TARGET_VERSION}/chezmoi-linux-amd64-musl"
        tmp="$(mktemp)"
        curl -fsSL "$chezmoi_url" -o "$tmp"
        sudo install -m 755 "$tmp" "$BIN_DIR/chezmoi"
        rm -f "$tmp"
    else
        curl -fsLS https://get.chezmoi.io | sudo sh -s -- -t "v${TARGET_VERSION}" -b "$BIN_DIR"
    fi
    echo "✓ chezmoi ${TARGET_VERSION} installed"
fi

# Install password manager and login to it
"$DOTFILES_DIR/scripts/password-manager.sh" install

# Load password manager session
# shellcheck source=/dev/null
[ -r "$HOME/.secrets/.env" ] && . "$HOME/.secrets/.env"

echo "▸ Applying chezmoi configuration"
"$BIN_DIR/chezmoi" init --source "$DOTFILES_DIR" --apply
echo "✓ chezmoi configuration applied"
