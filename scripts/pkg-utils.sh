#!/bin/sh

set -eu

bootstrap_env() {
    if command -v sudo >/dev/null 2>&1 &&
        command -v bash >/dev/null 2>&1 &&
        command -v curl >/dev/null 2>&1 &&
        command -v git >/dev/null 2>&1; then
        return 0
    fi
    echo "▸ Bootstrapping environment..."
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update
        apt-get install -y sudo bash curl git
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y sudo bash curl git
    elif command -v apk >/dev/null 2>&1; then
        apk add sudo bash curl git
    else
        echo "ERROR: failed to bootstrap environment" >&2
        exit 1
    fi
    echo "✓ Environment bootstrapped"
}

enable_copr() {
    repo="$1"
    if ! sudo dnf copr list 2>/dev/null | grep -q "$repo"; then
        sudo dnf copr enable -y "$repo"
    fi
}

install_pkgs() {
    pm="$1"

    shift
    [ $# -eq 0 ] && return 0

    echo "▸ Installing packages: $*"

    case "$pm" in
    apk) sudo apk add "$@" ;;
    apt-get) sudo apt-get install -y "$@" ;;
    dnf) sudo dnf install -y "$@" ;;
    *)
        echo "ERROR: unsupported PM: $pm" >&2
        exit 1
        ;;
    esac

    echo "✓ Installed packages: $*"
}

install_script() {
    name="$1"
    url="$2"
    shift 2

    tmpdir="$(mktemp -d)"
    script="$tmpdir/installer"

    echo "▸ Installing $name"

    curl --proto '=https' --tlsv1.2 -sSfL -o "$script" "$url"
    chmod +x "$script"

    "$script" "$@"

    rm -rf "$tmpdir"

    echo "✓ Installed $name"
}
