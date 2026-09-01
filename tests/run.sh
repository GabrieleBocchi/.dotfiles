#!/usr/bin/env bash
# Usage:
#   run.sh <case-name>   # run a single case (searched across all files)
#   run.sh --all         # run every case declared in tests/cases/*.yaml

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CASES_DIR="$SCRIPT_DIR/cases"
RUNTIME="${CONTAINER_RUNTIME:-podman}"

# Flatpak (bwrap) needs unprivileged user namespaces.
sudo sysctl -w kernel.unprivileged_userns_clone=1 >/dev/null 2>&1 || true

# Docker's default seccomp profile blocks bwrap's userns syscalls; reuse
# Podman's (already permissive) profile instead of going fully unconfined.
SECCOMP_PROFILE="$SCRIPT_DIR/.podman-seccomp.json"
if [ "$RUNTIME" = "docker" ] && [ ! -s "$SECCOMP_PROFILE" ]; then
    curl --proto '=https' --tlsv1.2 -sSfL -o "$SECCOMP_PROFILE" \
        https://raw.githubusercontent.com/containers/common/main/pkg/seccomp/seccomp.json
fi

all_cases_json() {
    # shellcheck disable=SC2016
    yq eval-all -o=json '[.cases[]] as $i ireduce ([]; . + $i)' "$CASES_DIR"/*.yaml
}

run_case() {
    local name="$1" image hasGUI hasGnome seccomp_args=()

    image="$(all_cases_json | yq ".[] | select(.name == \"$name\") | .image")"
    hasGUI="$(all_cases_json | yq ".[] | select(.name == \"$name\") | .hasGUI")"
    hasGnome="$(all_cases_json | yq ".[] | select(.name == \"$name\") | .hasGnome")"

    if [ -z "$image" ]; then
        echo "ERROR: no case named '$name' in $CASES_DIR/*.yaml" >&2
        exit 1
    fi

    [ -s "$SECCOMP_PROFILE" ] && seccomp_args=(--security-opt "seccomp=$SECCOMP_PROFILE")

    echo "▸ [$name] image=$image hasGUI=$hasGUI hasGnome=$hasGnome"
    "$RUNTIME" run --rm \
        --cap-add=SYS_ADMIN \
        --security-opt apparmor=unconfined \
        --security-opt systempaths=unconfined \
        "${seccomp_args[@]}" \
        -v "$REPO_DIR:/repo:ro,Z" \
        -e "CASE_HAS_GUI=$hasGUI" \
        -e "CASE_HAS_GNOME=$hasGnome" \
        "$image" \
        sh /repo/tests/in-container.sh
    echo "✓ [$name] passed"
}

case "${1:-}" in
"")
    echo "usage: $0 <case-name>|--all" >&2
    exit 1
    ;;
--all)
    for name in $(all_cases_json | yq '.[].name'); do
        run_case "$name"
    done
    ;;
*)
    run_case "$1"
    ;;
esac
