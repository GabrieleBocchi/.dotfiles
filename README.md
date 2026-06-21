# Dotfiles

This is my dotfiles collection, managed with [chezmoi](https://chezmoi.io/).

## Modules

- `Alacritty`: Terminal emulator
- `Git`: Version control system
- `Keyboard`: Keyboard personalisation (keyd)
- `Neovim`: Text editor ([gab.lazy](https://github.com/GabrieleBocchi/gab.lazy))
- `Tmux`: Terminal multiplexer (gpakosz/.tmux base)
- `Zsh`: Shell (antidote plugin manager)

## Installation

Clone this repository and run the installer:

```sh
git clone https://github.com/GabrieleBocchi/.dotfiles ~/.dotfiles
~/.dotfiles/install
```

The installer reads the target version from `.chezmoiversion` and installs
chezmoi at that exact version via `get.chezmoi.io`.

## Updating

```sh
git -C ~/.dotfiles pull --prune
./install
```

Or use the `updateDotfiles` alias.

## Environment variables

- `IDENTITIES`: Space-separated list of SSH/GPG key identities for keychain

## Dependency management

System packages and toolchain dependencies are declared in
`home/.chezmoidata/` and installed automatically.

## External dependencies (version-pinned)

Managed via `.chezmoiexternal.toml` and `.chezmoiversion`. Renovate auto-updates
the following:

| Dependency              | Tracks                                                    |
| ----------------------- | --------------------------------------------------------- |
| chezmoi                 | `twpayne/chezmoi` GitHub releases — via `.chezmoiversion` |
| antidote                | `mattmc3/antidote` GitHub releases                        |
| JetBrainsMono Nerd Font | `ryanoasis/nerd-fonts` GitHub releases                    |
| alacritty-theme         | main branch (no releases)                                 |
| gpakosz/.tmux           | main branch (no releases)                                 |
| gab.lazy (nvim)         | main branch — intentionally unpinned                      |
