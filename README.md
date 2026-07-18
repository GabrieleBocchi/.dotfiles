# Dotfiles

This is my dotfiles collection, managed with [chezmoi](https://chezmoi.io/).

## Modules

- `Alacritty`: Terminal emulator
- `Git`: Version control system
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
Each PM section has `base` and `desktop` variants — desktop packages are only
installed when a GUI session is detected.

```yaml
dnf:
  packages:
    base:
      pm:
        - gh
        - vim-enhanced
    desktop:
      pm:
        - alacritty

common:
  packages:
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

The install script:

1. Installs PM packages (`install_pkgs pm pkg1 pkg2 ...`)
2. Runs script-based installers (`install_script name url [args...]`)
3. Installs cargo packages with `--locked`
4. Installs npm global packages

### GUI detection

`hasGUI` is available as a chezmoi template variable. It detects a desktop
environment by checking for the presence of `/usr/share/xsessions` or
`/usr/share/wayland-sessions` — no distro-specific logic.

### Toolchain packages

`home/.chezmoidata/cargo.yaml` and `home/.chezmoidata/npm.yaml` declare
packages installed via their respective toolchains (also split by `base`
and `desktop`). Managed by Renovate for auto-updates.

### Script-based installs

URL-based installers (rustup, terragrunt, etc.) are downloaded,
saved to a temp directory, made executable, and run respecting their shebang.

## Post-install updates

`run_after_00-updates.sh.tmpl` runs after every chezmoi apply and handles updates.

## External dependencies (version-pinned)

Managed via `.chezmoiexternal.toml.tmpl` and `.chezmoiversion`. Renovate
auto-updates the following:

| Dependency              | Tracks                                                    |
| ----------------------- | --------------------------------------------------------- |
| chezmoi                 | `twpayne/chezmoi` GitHub releases — via `.chezmoiversion` |
| antidote                | `mattmc3/antidote` GitHub releases                        |
| JetBrainsMono Nerd Font | `ryanoasis/nerd-fonts` GitHub releases                    |
| alacritty-theme         | main branch (no releases)                                 |
| gpakosz/.tmux           | main branch (no releases)                                 |
| gab.lazy (nvim)         | main branch — intentionally unpinned                      |
