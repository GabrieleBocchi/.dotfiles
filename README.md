# Dotfiles

This is my dotfiles collection, managed with [chezmoi](https://chezmoi.io/).

## Modules

- `Ghostty`: Terminal emulator
- `Git`: Version control system
- `GNOME`: Desktop environment settings (dconf)
- `Keyboard`: Keyboard personalisation (kanata)
- `Neovim`: Text editor ([gab.lazy](https://github.com/GabrieleBocchi/gab.lazy))
- `OpenCode`: AI coding agent CLI, with permission guardrails and a security plugin
- `SSH`: Client config with sane defaults, machine-specific hosts kept out of the repo
- `Tmux`: Terminal multiplexer (gpakosz/.tmux base)
- `Zsh`: Shell (antidote plugin manager, Starship prompt)

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

Before any of this, `install.sh` calls `bootstrap_env` (in `scripts/pkg-utils.sh`),
which ensures the core tools the install process itself depends on (shell,
downloader, VCS, GPG) are present, installing them with the native PM if any
are missing. GPG is needed because `enable_repo`'s apt-get `custom` kind (see
below) has to dearmor signing keys, and that step always runs *before* `pm`
packages (including `gnupg` itself) are installed.

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
  base:
    pm:
      - terraform
    repos:
      - kind: custom
        name: hashicorp
        baseurl: "https://rpm.releases.hashicorp.com/fedora/$releasever/$basearch/stable"
        gpgkey: "https://rpm.releases.hashicorp.com/gpg"
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
      - kind: rpm-release
        name: rpmfusion-free
        url: "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$releasever.noarch.rpm"

apt-get:
  base:
    pm:
      - terraform
    repos:
      - kind: custom
        name: hashicorp
        uri: "https://apt.releases.hashicorp.com"
        suites: "$codename"
        components: "main"
        signed_by: "https://apt.releases.hashicorp.com/gpg"
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
      - kind: ppa
        name: atareao/telegram
```

- **`kind: copr`** (dnf only): enables a Fedora COPR repo (`dnf copr enable`).
- **`kind: ppa`** (apt-get only): enables an Ubuntu PPA (`add-apt-repository`), self-installing
  `software-properties-common` first if missing.
- **`kind: rpm-release`** (dnf only): installs a release RPM directly (`dnf install <url>`), for
  packages distributed as a release package rather than a repo file (e.g. RPM Fusion).
- **`kind: custom`**: writes the repo config natively.
  - dnf: `baseurl` + `gpgkey` → `/etc/yum.repos.d/<name>.repo`.
  - apt-get: `uri`, `suites`, `components`, `signed_by` → a signing key dearmored
    into `/usr/share/keyrings/<name>.gpg` and a deb822 source file at
    `/etc/apt/sources.list.d/<name>.sources`.

Every field besides `kind`/`name` is passed to `enable_repo` as `key=value`
pairs, so the template itself never branches on package manager or kind —
`enable_repo` in `scripts/pkg-utils.sh` handles the dispatch entirely.

### Repo URL/field placeholders

Some repo fields need a value only known at runtime on the target machine,
resolved by `enable_repo` before use (not by the chezmoi template):

- `$releasever` / `$basearch` (dnf `custom` baseurl, `rpm-release` url): DNF's
  own variables. For `custom`, DNF expands them itself when reading the
  written `.repo` file. For `rpm-release`, since the URL is passed directly as
  a `dnf install` argument (not read from a repo file), `enable_repo` resolves
  them itself via `rpm -E %fedora`/`rpm -E %_arch` before calling `dnf install`.
- `$codename` (apt-get `custom` suites): resolved by `enable_repo` from
  `/etc/os-release`'s `VERSION_CODENAME`, for repos (like HashiCorp's) that
  publish per-codename suites instead of a generic channel name like `stable`.

These fields are written with single quotes (`squote`) in the generated
script so the literal `$...` survives shell parsing and reaches `enable_repo`
unexpanded.

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

`home/dconf/` holds GNOME desktop settings as plain dconf keyfiles, one file
per settings category (e.g. `interface.ini`, `peripherals.ini`,
`keybindings.ini`). `run_after_20-load-gnome-settings.sh.tmpl`
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

### OpenCode configuration

`home/dot_config/opencode/` holds config for [OpenCode](https://opencode.ai)
(the CLI itself is installed via `npm.yaml`, not here): `opencode.json`
(plugins + `model`/`small_model`) and `tui.json`.

Permission is left at opencode's own defaults (mostly permissive, so it
doesn't ask for approval on every action) — the `cc-safety-net` plugin adds an
independent guardrail that blocks destructive commands (`rm -rf`,
`git reset --hard`, force pushes, etc.) and secret file access, running as its
own hook rather than through opencode's own permission system, since
pattern-based `deny` rules there have
[known bugs](https://github.com/anomalyco/opencode/issues/28682) where they
can be silently bypassed.

Per-agent model routing for the orchestration plugin is intentionally **not**
tracked here: it maps agents to specific model IDs, which drift as new models
ship. Run `updateOpencodeModels` (`bunx oh-my-openagent install`, aliased in
`home/zsh/aliases.zsh`) to (re)generate it — the official installer interviews
you about your subscriptions (Claude, Copilot, Gemini, etc.) and picks current
best-fit models per agent, kept up to date by the plugin maintainer instead of
by us. It writes to `~/.omo/omo.jsonc` (the plugin's unified config location,
not `~/.config/opencode/`), migrating any older `oh-my-openagent.json` it
finds there automatically.

Excluded on purpose (regenerated automatically, or machine-specific state, not
tracked here): `node_modules/`, `bun.lock`, `package*.json`, `logs/`,
`~/.omo/` (model routing, see above), and
`~/.local/share/opencode/auth.json`/`account.json` (real credentials).

### SSH configuration

`home/private_dot_ssh/private_config` ships a generic `~/.ssh/config` `Host *`
block (connection multiplexing, keepalive, `known_hosts` hygiene, no global
agent forwarding) — safe, host-agnostic defaults. `Include
~/.ssh/config.local` at the top pulls in machine/work-specific `Host` blocks
(VPN ranges, enterprise aliases, etc.) from an untracked file, silently
skipped by ssh if absent.

The `.ssh` directory itself is tracked as `private_dot_ssh`, so chezmoi
enforces `700` permissions on every apply. The `cm/` subdirectory used for
multiplexed connection sockets is tracked the same way (`private_cm/`, with
an `empty_dot_keep` placeholder so chezmoi materialises the otherwise-empty
directory) — no custom script needed.

Keys and `known_hosts` are never tracked here — they're machine/identity
specific and stay purely local.

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
