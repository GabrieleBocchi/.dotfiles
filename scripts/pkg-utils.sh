#!/bin/sh

set -eu

bootstrap_env() {
    if command -v sudo >/dev/null 2>&1 &&
        command -v bash >/dev/null 2>&1 &&
        command -v curl >/dev/null 2>&1; then
        return 0
    fi
    echo "▸ Bootstrapping environment..."
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update
        apt-get install -y sudo bash curl
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y sudo bash curl
    elif command -v apk >/dev/null 2>&1; then
        apk add sudo bash curl
    else
        echo "ERROR: failed to bootstrap environment" >&2
        exit 1
    fi
    echo "✓ Environment bootstrapped"
}

install_pkgs() {
    if [ $# -eq 0 ]; then
        return 0
    fi
    if command -v apt >/dev/null 2>&1; then
        sudo apt-get install -y "$@"
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y "$@"
    elif command -v apk >/dev/null 2>&1; then
        sudo apk add "$@"
    else
        echo "ERROR: failed to install packages: $*" >&2
        exit 1
    fi
}

enable_copr() {
    repo="$1"
    if ! sudo dnf copr list 2>/dev/null | grep -q "$repo"; then
        sudo dnf copr enable -y "$repo"
    fi
}
