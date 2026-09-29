#!/bin/sh
# Runs inside the disposable test container.
# Bootstraps sudo as root first, then everything runs as a non-root user.

set -eu

REPO_NAME=".dotfiles"
CASE_HAS_GUI="${CASE_HAS_GUI:-false}"
CASE_HAS_GNOME="${CASE_HAS_GNOME:-false}"
TESTUSER_PASSWORD="testuser-pw-1234"

# Some images ship /etc/shadow at mode 0000; recent runc breaks setuid PAM
# helpers reading it. Owner-readable is enough.
chmod 600 /etc/shadow 2>/dev/null || true

# shellcheck source=../scripts/pkg-utils.sh
. /repo/scripts/pkg-utils.sh

PM="$(detect_pm)"
if [ -z "$PM" ]; then
    echo "ERROR: unsupported distro (no dnf/apt-get/apk)" >&2
    exit 1
fi

echo "▸ Installing sudo"
pm_install "$PM" sudo

echo "▸ Creating test user"
if command -v useradd >/dev/null 2>&1; then
    useradd -m testuser
else
    adduser -D testuser
fi

# chsh (shell change in install.sh) needs a password on the account.
echo "testuser:$TESTUSER_PASSWORD" | chpasswd

echo "testuser ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/testuser
chmod 0440 /etc/sudoers.d/testuser

if [ "$CASE_HAS_GUI" = "true" ]; then
    echo "▸ Forcing hasGUI=true (creating a fake /usr/share/xsessions entry)"
    mkdir -p /usr/share/xsessions
    touch /usr/share/xsessions/fake-test-session.desktop

    # Flatpak needs a D-Bus session bus even for --user installs.
    case "$PM" in
    apk) pm_install "$PM" dbus ;;
    apt-get) pm_install "$PM" dbus ;;
    dnf) pm_install "$PM" dbus-daemon ;;
    esac

    # Debian/Ubuntu's flatpak needs accountsservice (libmalcontent query) on
    # the system bus, or install fails with "Could not connect".
    if [ "$PM" = "apt-get" ]; then
        pm_install "$PM" accountsservice
        mkdir -p /run/dbus
        dbus-daemon --system --fork
    fi
fi

if [ "$CASE_HAS_GNOME" = "true" ]; then
    echo "▸ Forcing hasGnome=true (faking a gnome-shell binary on PATH)"
    printf '#!/bin/sh\ntrue\n' >/usr/bin/gnome-shell
    chmod +x /usr/bin/gnome-shell

    case "$PM" in
    apk) pm_install "$PM" dconf ;;
    apt-get) pm_install "$PM" dconf-cli dconf-service ;;
    dnf) pm_install "$PM" dconf ;;
    esac
fi

echo "▸ Copying repository to test user's home"
cp -r /repo "/home/testuser/$REPO_NAME"
chown -R testuser "/home/testuser/$REPO_NAME"

run_dir="/home/testuser/$REPO_NAME"
# GUI needs a session bus: Flatpak installs (any GUI case) and dconf load (GNOME).
prefix=""
[ "$CASE_HAS_GUI" = "true" ] && prefix="dbus-run-session -- "
run_script="/home/testuser/run-install.sh"
cat >"$run_script" <<EOF
#!/bin/sh
set -eu
export PATH="/usr/local/bin:\$PATH"
cd "$run_dir"
exec $prefix ./install.sh
EOF
chmod +x "$run_script"
chown testuser "$run_script"

echo "▸ Running install.sh as testuser"
sudo -u testuser -H "$run_script"

echo "▸ Installing bats-core"
git clone -q --depth 1 https://github.com/bats-core/bats-core.git /tmp/bats-core
/tmp/bats-core/install.sh /usr/local

# Asserts via zsh so PATH from .zshrc (e.g. ~/.cargo/bin) is loaded.
echo "▸ Running assertions"
sudo -u testuser -H zsh -c "
    export CASE_HAS_GUI='$CASE_HAS_GUI'
    export CASE_HAS_GNOME='$CASE_HAS_GNOME'
    export REPO_DIR='$run_dir'
    source ~/.zshrc >/dev/null 2>&1
    # Add /usr/local/bin to PATH to ensure chezmoi is found
    export PATH='/usr/local/bin:'\$PATH
    exec bats '$run_dir/tests/install.bats'
"
