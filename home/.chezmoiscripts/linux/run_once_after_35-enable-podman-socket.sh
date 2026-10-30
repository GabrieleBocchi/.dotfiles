#!/usr/bin/env bash

set -euo pipefail

if [ ! -d /run/systemd/system ]; then
    echo "− Skipping podman socket (no systemd)"
    exit 0
fi

systemctl --user enable --now podman.socket
echo "✓ podman socket"
