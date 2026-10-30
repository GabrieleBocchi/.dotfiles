#!/bin/sh
# Bitwarden CLI: install (render-time) and persist BW_SESSION.

set -eu

. "$(dirname "$0")/pkg-utils.sh"

# renovate: datasource=github-releases depName=bitwarden/clients extractVersion=^cli-v(?<version>.+)$
BW_VERSION="2026.10.1"
BW_BIN="/usr/local/bin/bw"

install_bw() {
    case "$(uname -s)-$(uname -m)" in
    Linux-x86_64)
        os="linux"
        suffix=""
        ;;
    Linux-aarch64 | Linux-arm64)
        os="linux"
        suffix="-arm64"
        ;;
    *)
        echo "ERROR: unsupported platform $(uname -s)/$(uname -m)" >&2
        exit 1
        ;;
    esac

    asset="bw-${os}${suffix}-${BW_VERSION}.zip"
    url="https://github.com/bitwarden/clients/releases/download/cli-v${BW_VERSION}/${asset}"

    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT

    echo "▸ Installing Bitwarden CLI $BW_VERSION..."
    curl --proto '=https' --tlsv1.2 -sSfL -o "$tmp/bw.zip" "$url"
    unzip -oq "$tmp/bw.zip" -d "$tmp"

    if [ ! -f "$tmp/bw" ]; then
        echo "ERROR: '$asset' extracted no 'bw' binary" >&2
        exit 1
    fi

    as_root install -m 755 "$tmp/bw" "$BW_BIN"
    echo "✓ Installed Bitwarden CLI $BW_VERSION"
}

persist_session() {
    secrets="$HOME/.secrets"
    env_file="$secrets/.env"

    mkdir -p "$secrets"
    chmod 700 "$secrets"

    if [ -r "$env_file" ]; then
        session="$(sed -n 's/^export BW_SESSION="\([^"]*\)"$/\1/p' "$env_file" 2>/dev/null | head -n1)"
        if [ -n "$session" ] && BW_SESSION="$session" bw unlock --check </dev/null >/dev/null 2>&1; then
            return 0
        fi
    fi

    case "$(bw status 2>/dev/null)" in
    *'"status":"unauthenticated"'* | '')
        session="$(bw login --raw)"
        ;;
    *)
        session="$(bw unlock --raw)"
        ;;
    esac

    env_tmp="$(
        umask 077
        mktemp "$env_file.XXXXXX"
    )"
    # Keep every other line; rewrite only the BW_SESSION line.
    grep -v '^export BW_SESSION=' "$env_file" 2>/dev/null >"$env_tmp" || true
    printf 'export BW_SESSION="%s"\n' "$session" >>"$env_tmp"
    mv "$env_tmp" "$env_file"
}

case "${1:-}" in
install)
    # Non-interactive run with no session (CI, container).
    [ ! -t 0 ] && [ -z "${BW_SESSION:-}" ] && exit 0

    # The standalone bw is glibc-only; without it the keys are skipped.
    if is_musl; then
        [ -L "$BW_BIN" ] && as_root rm -f "$BW_BIN"
        echo "− Skipping Bitwarden CLI (no musl build)"
        exit 0
    fi

    # Also replaces the old symlink to npm's bw, which needs node on PATH.
    if [ -L "$BW_BIN" ] || [ "$("$BW_BIN" --version 2>/dev/null)" != "$BW_VERSION" ]; then
        install_bw
    fi

    PATH="/usr/local/bin:$PATH"
    persist_session
    ;;
*)
    echo "usage: $0 install" >&2
    exit 1
    ;;
esac
