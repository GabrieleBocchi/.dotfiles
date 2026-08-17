#!/bin/sh

set -eu

detect_pm() {
    if command -v apk >/dev/null 2>&1; then
        echo apk
    elif command -v apt-get >/dev/null 2>&1; then
        echo apt-get
    elif command -v dnf >/dev/null 2>&1; then
        echo dnf
    fi
}

# Single point where the supported package managers and their install command are defined.
# Runs without sudo when root; otherwise via sudo.
# --allowerasing only matters for dnf.
pm_install() {
    sudo_=sudo
    allowerasing=0
    [ "$(id -u)" -eq 0 ] && sudo_=""
    while [ $# -gt 0 ]; do
        case "$1" in
        --allowerasing)
            allowerasing=1
            shift
            ;;
        *) break ;;
        esac
    done
    pm="$1"
    shift
    case "$pm" in
    apk) $sudo_ apk add "$@" ;;
    apt-get)
        $sudo_ apt-get update
        $sudo_ apt-get install -y "$@"
        ;;
    dnf)
        if [ "$allowerasing" = 1 ]; then
            $sudo_ dnf install -y --allowerasing "$@"
        else
            $sudo_ dnf install -y "$@"
        fi
        ;;
    *)
        echo "ERROR: unsupported PM: $pm" >&2
        return 1
        ;;
    esac
}

bootstrap_env() {
    if command -v sudo >/dev/null 2>&1 &&
        command -v bash >/dev/null 2>&1 &&
        command -v curl >/dev/null 2>&1 &&
        command -v git >/dev/null 2>&1 &&
        command -v gpg >/dev/null 2>&1; then
        return 0
    fi
    echo "▸ Bootstrapping environment..."
    case "$(detect_pm)" in
    apk)
        pm_install apk sudo bash curl git gnupg unzip
        ;;
    apt-get)
        pm_install apt-get sudo bash curl git gnupg unzip
        ;;
    dnf)
        # --allowerasing: RHEL-family minimal images (e.g. Rocky, Alma) ship
        # curl-minimal by default, which conflicts with the full curl package.
        pm_install --allowerasing dnf sudo bash curl git gnupg2 unzip
        ;;
    *)
        echo "ERROR: failed to bootstrap environment" >&2
        exit 1
        ;;
    esac
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
            pm_install apt-get software-properties-common

        echo "▸ Enabling PPA: $name"
        sudo add-apt-repository -y "ppa:$name"
        echo "✓ Enabled PPA: $name"
        ;;
    apk-testing)
        # Pins one package from Alpine's edge/testing repo without adding it
        # to /etc/apk/repositories or switching the whole system to edge.
        echo "▸ Enabling repo: $name"
        pm_install apk --no-cache --repository https://dl-cdn.alpinelinux.org/alpine/edge/testing "$name"
        echo "✓ Enabled repo: $name"
        ;;
    rpm-release)
        # %fedora is undefined (rpm echoes it back literally) on RHEL-family
        # systems (Rocky, Alma, RHEL) - fall back to %rhel there.
        releasever="$(rpm -E %fedora)"
        [ "$releasever" = "%fedora" ] && releasever="$(rpm -E %rhel)"
        basearch="$(rpm -E %_arch)"
        resolved_url=$(printf '%s' "$url" | sed "s/\$releasever/$releasever/g; s/\$basearch/$basearch/g")

        echo "▸ Enabling repo: $name"
        pm_install dnf "$resolved_url"
        echo "✓ Enabled repo: $name"
        ;;
    deb-release)
        tmpdeb="$(mktemp --suffix=.deb)"

        echo "▸ Enabling repo: $name"
        curl --proto '=https' --tlsv1.2 -sSfL -o "$tmpdeb" "$url"
        pm_install apt-get "$tmpdeb"
        rm -f "$tmpdeb"
        echo "✓ Enabled repo: $name"
        ;;
    custom)
        case "$pm" in
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
        dnf)
            repofile="/etc/yum.repos.d/${name}.repo"
            [ -f "$repofile" ] && return 0

            distro="fedora"
            [ "$(rpm -E %fedora)" = "%fedora" ] && distro="RHEL"
            baseurl=$(printf '%s' "$baseurl" | sed "s/\$distro/$distro/g")

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

    pm_install "$pm" "$@"

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
