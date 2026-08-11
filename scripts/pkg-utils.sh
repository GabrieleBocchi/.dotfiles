#!/bin/sh

set -eu

bootstrap_env() {
    if command -v sudo >/dev/null 2>&1 &&
        command -v bash >/dev/null 2>&1 &&
        command -v curl >/dev/null 2>&1 &&
        command -v git >/dev/null 2>&1 &&
        command -v gpg >/dev/null 2>&1; then
        return 0
    fi
    echo "▸ Bootstrapping environment..."
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update
        apt-get install -y sudo bash curl git gnupg
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y sudo bash curl git gnupg2
    elif command -v apk >/dev/null 2>&1; then
        apk add sudo bash curl git gnupg
    else
        echo "ERROR: failed to bootstrap environment" >&2
        exit 1
    fi
    echo "✓ Environment bootstrapped"
}

enable_repo() {
    pm="$1"
    kind="$2"
    name="$3"
    shift 3

    baseurl="" gpgkey="" uri="" suites="" components="" signed_by="" url=""
    for arg in "$@"; do
        case "$arg" in
        baseurl=*) baseurl="${arg#baseurl=}" ;;
        gpgkey=*) gpgkey="${arg#gpgkey=}" ;;
        uri=*) uri="${arg#uri=}" ;;
        suites=*) suites="${arg#suites=}" ;;
        components=*) components="${arg#components=}" ;;
        signed_by=*) signed_by="${arg#signed_by=}" ;;
        url=*) url="${arg#url=}" ;;
        *)
            echo "ERROR: unknown repo field: $arg" >&2
            exit 1
            ;;
        esac
    done

    case "$kind" in
    copr)
        if ! sudo dnf copr list 2>/dev/null | grep -q "$name"; then
            echo "▸ Enabling COPR: $name"
            sudo dnf copr enable -y "$name"
            echo "✓ Enabled COPR: $name"
        fi
        ;;
    ppa)
        command -v add-apt-repository >/dev/null 2>&1 ||
            sudo apt-get install -y software-properties-common

        echo "▸ Enabling PPA: $name"
        sudo add-apt-repository -y "ppa:$name"
        echo "✓ Enabled PPA: $name"
        ;;
    rpm-release)
        releasever="$(rpm -E %fedora)"
        basearch="$(rpm -E %_arch)"
        resolved_url=$(printf '%s' "$url" | sed "s/\$releasever/$releasever/g; s/\$basearch/$basearch/g")

        echo "▸ Enabling repo: $name"
        sudo dnf install -y "$resolved_url"
        echo "✓ Enabled repo: $name"
        ;;
    custom)
        case "$pm" in
        dnf)
            repofile="/etc/yum.repos.d/${name}.repo"
            [ -f "$repofile" ] && return 0

            echo "▸ Enabling repo: $name"
            sudo tee "$repofile" >/dev/null <<EOF
[$name]
name=$name
baseurl=$baseurl
enabled=1
gpgcheck=1
gpgkey=$gpgkey
EOF
            echo "✓ Enabled repo: $name"
            ;;
        apt-get)
            keyring="/usr/share/keyrings/${name}.gpg"
            sourcefile="/etc/apt/sources.list.d/${name}.sources"
            [ -f "$sourcefile" ] && return 0

            codename="$(. /etc/os-release && echo "$VERSION_CODENAME")"
            suites=$(printf '%s' "$suites" | sed "s/\$codename/$codename/g")

            echo "▸ Enabling repo: $name"
            curl --proto '=https' --tlsv1.2 -sSfL "$signed_by" |
                sudo gpg --dearmor -o "$keyring"
            sudo tee "$sourcefile" >/dev/null <<EOF
Types: deb
URIs: $uri
Suites: $suites
Components: $components
Signed-By: $keyring
EOF
            sudo apt-get update -qq
            echo "✓ Enabled repo: $name"
            ;;
        *)
            echo "ERROR: unsupported PM for custom repo: $pm" >&2
            exit 1
            ;;
        esac
        ;;
    *)
        echo "ERROR: unsupported repo kind: $kind" >&2
        exit 1
        ;;
    esac
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
