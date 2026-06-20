#!/usr/bin/env bash

set -euo pipefail

install_pkg() {
    local pkg="$1"
    if command -v apt &>/dev/null; then
        sudo apt-get install -y "$pkg"
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y "$pkg"
    elif command -v apk &>/dev/null; then
        sudo apk add "$pkg"
    else
        echo "ERROR: No supported package manager (apt, dnf, apk) found" >&2
        exit 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -lt 1 ]]; then
        echo "Usage: $(basename "$0") <package>" >&2
        exit 1
    fi
    install_pkg "$1"
fi
