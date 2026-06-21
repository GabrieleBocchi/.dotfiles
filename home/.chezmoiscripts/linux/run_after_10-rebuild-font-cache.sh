#!/usr/bin/env bash

set -euo pipefail

echo "▸ Rebuilding font cache"
fc-cache
echo "✓ Font cache rebuilt"
