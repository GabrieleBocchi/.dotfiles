# Dotfiles

This is my dotfiles collection, managed with [chezmoi](https://chezmoi.io/).

## Modules

- `Ghostty`: Terminal emulator
- `Git`: Version control system
- `GNOME`: Desktop environment settings (dconf)
- `Keyboard`: Keyboard personalisation (kanata)
- `Neovim`: Text editor ([gab.lazy](https://github.com/GabrieleBocchi/gab.lazy))
- `Tmux`: Terminal multiplexer (gpakosz/.tmux base)
- `Zsh`: Shell (antidote plugin manager)

## Installation

Clone this repository and run the installer:

```sh
git clone https://github.com/GabrieleBocchi/.dotfiles ~/.dotfiles
~/.dotfiles/install.sh
```

The installer reads the target version from `.chezmoiversion` and installs
chezmoi at that exact version via `get.chezmoi.io`.

## Updating

```sh
git -C ~/.dotfiles pull --prune
./install.sh
```

Or use the `updateDotfiles` alias.

## Environment variables

- `IDENTITIES`: Space-separated list of SSH/GPG key identities for keychain

## Dependency management

Dependencies are declared in YAML files under `home/.chezmoidata/` and installed
automatically by chezmoi scripts. The system is cross-distro and detects the
package manager at apply time.

### System packages

`home/.chezmoidata/system.yaml` organises dependencies by package manager.
Each PM section has `base` and `desktop` keys directly at its root — desktop
entries are only installed when a GUI session is detected.

```yaml
dnf:
  base:
    pm:
      - gh
      - vim-enhanced
  desktop:
    pm:
      - ghostty

common:
  base:
    pm:
      - bat
      - git
      - neovim
      - tmux
      - zsh
    script:
      - name: Rust
        url: "https://sh.rustup.rs"
        args: ["-y"]
      - name: Uv
        url: "https://astral.sh/uv/install.sh"
        envs: ["UV_NO_MODIFY_PATH=1"]
      - name: Terragrunt
        url: "https://terragrunt.com/install"
        args: ["--force"]
```

- **`pm`**: List of packages to install via the native package manager.
- **`script`**: List of URL-based installers to download and execute.
  - `name`: Display name for logs.
  - `url`: Script URL.
  - `args` (optional): Arguments passed to the script.
  - `envs` (optional): Environment variables passed to the script (e.g. `["KEY=value"]`).
- **`repos`** (optional, see below): Repositories to enable before installing `pm` packages.

The install script:

1. Enables repositories (`enable_repo pm kind name [key=value ...]`)
2. Installs PM packages (`install_pkgs pm pkg1 pkg2 ...`)
3. Runs script-based installers (`install_script name url [args...]`)
4. Installs cargo packages with `--locked`
5. Installs npm global packages

### Repositories

Some packages (e.g. Google Chrome) aren't in the default repos and need one
enabled first. Declared per package manager as a `repos` list under `base` or
`desktop` (usually `desktop`, since these repos are only needed when their
package is actually going to be installed), enabled before packages are
installed so the package itself is then just a normal entry under `pm`:

```yaml
dnf:
  desktop:
    pm:
      - ghostty
      - google-chrome-stable
    repos:
      - kind: copr
        name: scottames/ghostty
      - kind: custom
        name: google-chrome
        baseurl: "https://dl.google.com/linux/chrome/rpm/stable/x86_64"
        gpgkey: "https://dl.google.com/linux/linux_signing_key.pub"

apt-get:
  desktop:
    pm:
      - google-chrome-stable
    repos:
      - kind: custom
        name: google-chrome
        uri: "https://dl.google.com/linux/chrome/deb/"
        suites: "stable"
        components: "main"
        signed_by: "https://dl.google.com/linux/linux_signing_key.pub"
```

- **`kind: copr`** (dnf only): enables a Fedora COPR repo (`dnf copr enable`).
- **`kind: custom`**: writes the repo config natively.
  - dnf: `baseurl` + `gpgkey` → `/etc/yum.repos.d/<name>.repo`.
  - apt-get: `uri`, `suites`, `components`, `signed_by` → a signing key dearmored
    into `/usr/share/keyrings/<name>.gpg` and a deb822 source file at
    `/etc/apt/sources.list.d/<name>.sources`.

Every field besides `kind`/`name` is passed to `enable_repo` as `key=value`
pairs, so the template itself never branches on package manager or kind —
`enable_repo` in `scripts/pkg-utils.sh` handles the dispatch entirely.

### GUI detection

`hasGUI` is available as a chezmoi template variable. It detects a desktop
environment by checking for the presence of `/usr/share/xsessions` or
`/usr/share/wayland-sessions` — no distro-specific logic.

### Toolchain packages

`home/.chezmoidata/cargo.yaml` and `home/.chezmoidata/npm.yaml` declare
packages installed via their respective toolchains, each a flat list directly
under `base`/`desktop` (e.g. `cargo.base`, `cargo.desktop`). Managed by
Renovate for auto-updates.

### Script-based installs

URL-based installers (rustup, terragrunt, etc.) are downloaded,
saved to a temp directory, made executable, and run respecting their shebang.

### GNOME settings (dconf)

`home/dconf/` holds GNOME desktop settings as plain dconf keyfiles, split by
category (`interface.ini`, `window-manager.ini`, `peripherals.ini`,
`notifications.ini`, `keybindings.ini`, `caffeine.ini`, `favorite-apps.ini`,
`nautilus.ini`, `datetime.ini`, `input-sources.ini`, `audio.ini`, `power.ini`). `run_after_20-load-gnome-settings.sh.tmpl`
concatenates every `*.ini` file and renders every `*.ini.tmpl` file (via
`chezmoi execute-template`), then feeds the result to `dconf load /`. It runs
on every apply (not `run_onchange`), so manual drift made in the GNOME
Settings app gets reverted back to the declared state on the next apply.
Skipped entirely when `hasGnome` is false.

`extensions.ini.tmpl` is the one templated file: it lists desired GNOME Shell
extension UUIDs and only enables the ones actually installed, checked via
`stat` against `/usr/share/gnome-shell/extensions/` and
`~/.local/share/gnome-shell/extensions/` — no package-manager-specific logic,
works regardless of which PM (or method) installed the extension.

`home/.chezmoidata/gnome.yaml` declares packages (e.g. GNOME Shell extensions)
that should only be installed when `hasGnome` is true, independently of
`hasGUI` — a KDE/XFCE desktop has `hasGUI = true` but doesn't need
`gnome-shell-extension-*` packages.

`hasGnome` is a chezmoi template variable (like `hasGUI`), detected via
`lookPath "gnome-shell"`.

## Post-install updates

`run_after_40-updates.sh.tmpl` runs after every chezmoi apply and handles updates.

## External dependencies (version-pinned)

Managed via `.chezmoiexternal.toml.tmpl` and `.chezmoiversion`. Renovate
auto-updates the following:

| Dependency              | Tracks                                                    |
| ----------------------- | --------------------------------------------------------- |
| chezmoi                 | `twpayne/chezmoi` GitHub releases — via `.chezmoiversion` |
| antidote                | `mattmc3/antidote` GitHub releases                        |
| JetBrainsMono Nerd Font | `ryanoasis/nerd-fonts` GitHub releases                    |
| gpakosz/.tmux           | main branch (no releases)                                 |
| gab.lazy (nvim)         | main branch — intentionally unpinned                      |
