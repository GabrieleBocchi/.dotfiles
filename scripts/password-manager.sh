#!/bin/sh
# Bitwarden CLI: install (render-time), persist BW_SESSION, or link.

set -eu

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
    Darwin-x86_64)
        os="macos"
        suffix=""
        ;;
    Darwin-arm64)
        os="macos"
        suffix="-arm64"
        ;;
    *)
        echo "ERROR: unsupported platform $(uname -s)/$(uname -m)" >&2
        exit 1
        ;;
    esac

    bw_version="$(
        curl --proto '=https' --tlsv1.2 -sSfL \
            'https://api.github.com/repos/bitwarden/clients/releases?per_page=30' |
            grep -o '"tag_name"[[:space:]]*:[[:space:]]*"cli-v[^"]*"' |
            head -n1 |
            sed 's/.*cli-v//; s/"$//'
    )"
    [ -n "$bw_version" ] || {
        echo "ERROR: couldn't resolve latest bw version" >&2
        exit 1
    }

    asset="bw-${os}${suffix}-${bw_version}.zip"
    url="https://github.com/bitwarden/clients/releases/download/cli-v${bw_version}/${asset}"

    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT

    echo "▸ Installing Bitwarden CLI $bw_version..."
    curl --proto '=https' --tlsv1.2 -sSfL -o "$tmp/bw.zip" "$url"
    unzip -oq "$tmp/bw.zip" -d "$tmp"

    if [ ! -f "$tmp/bw" ]; then
        echo "ERROR: '$asset' extracted no 'bw' binary" >&2
        exit 1
    fi

    if [ "$(id -u)" -eq 0 ]; then
        install -m 755 "$tmp/bw" /usr/local/bin/bw
    else
        sudo install -m 755 "$tmp/bw" /usr/local/bin/bw
    fi
    echo "✓ Installed Bitwarden CLI $bw_version"
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

    tmp="$(
        umask 077
        mktemp "$env_file.XXXXXX"
    )"
    # Keep every other line; rewrite only the BW_SESSION line.
    grep -v '^export BW_SESSION=' "$env_file" 2>/dev/null >"$tmp" || true
    printf 'export BW_SESSION="%s"\n' "$session" >>"$tmp"
    mv "$tmp" "$env_file"
}

link_bw() {
    per_user="$HOME/.local/share/fnm/aliases/default/bin/bw"
    [ -x "$per_user" ] || return 0

    # Skip linking if the symlink already points to the per-user bw binary.
    [ "$(readlink -- /usr/local/bin/bw 2>/dev/null)" = "$per_user" ] && return 0

    if [ "$(id -u)" -eq 0 ]; then
        ln -sfn "$per_user" /usr/local/bin/bw
    else
        sudo ln -sfn "$per_user" /usr/local/bin/bw
    fi
}

case "${1:-}" in
install)
    # Non-interactive run with no session (CI, container).
    [ ! -t 0 ] && [ -z "${BW_SESSION:-}" ] && exit 0

    # Install bw when missing.
    command -v bw >/dev/null 2>&1 || install_bw

    persist_session
    ;;
link)
    link_bw
    ;;
*)
    echo "usage: $0 [install|link]" >&2
    exit 1
    ;;
esac
