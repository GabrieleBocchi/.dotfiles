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

This is the single command to update everything: it re-downloads the fnm binary
(fnm has no `self-update`) and re-runs `fnm install --lts`, an idempotent
operation that downloads the latest LTS node when a new one exists and keeps
the `lts-latest` default pointing at it. No pinned node version is tracked.

## Environment variables

- `OPENCODE_CONFIG`: path to an untracked local opencode provider config (set in `.zshenv`)

## Dependency management

Dependencies are declared in YAML files under `home/.chezmoidata/` and installed
automatically by chezmoi scripts. The system is cross-distro and detects the
package manager at apply time.

### Distro families (source of truth)

`home/.chezmoidata/families.yaml` is the single source of truth that maps a
distro `os-release` id to a package manager and a "family":

```yaml
families:
  fedora:
    pm: dnf
    distros: [fedora]
  rhel:
    pm: dnf
    distros: [almalinux, ol, rocky]
  debian:
    pm: apt-get
    distros: [debian]
  ubuntu:
    pm: apt-get
    distros: [ubuntu]
  alpine:
    pm: apk
    distros: [alpine]
```

A system matches **exactly one** family via `/etc/os-release`'s `id`; the
package manager is derived from that family's `pm` field (never redeclared
elsewhere). Both `system.yaml` and `repos.yaml` are keyed by these family
names, so adding a distro to an existing family is just adding its id to the
`distros` list here — no other file changes. If no family matches, the
installed PM is detected by `lookPath` (fallback) and only the `common`
sections are used (no family-specific repos or packages).

### System packages

`home/.chezmoidata/system.yaml` organises dependencies by distro **family**.
The `common` section (cross-family, package-manager-agnostic) applies to every
system; each family section (`fedora`, `rhel`, `debian`, `ubuntu`, `alpine`)
holds only packages/scripts that family can actually install — a package is
listed under a family only if that family enables a repo providing it (see
`repos.yaml`). Each section has `base` and `desktop` keys — desktop entries are
only installed when a GUI session is detected.

```yaml
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
        args: ["--no-modify-path", "--quiet", "-y"]
      - name: Uv
        url: "https://astral.sh/uv/install.sh"
        envs: ["UV_NO_MODIFY_PATH=1"]
      - name: Terragrunt
        url: "https://terragrunt.com/install"
        args: ["--force"]

fedora:
  desktop:
    pm:
      - ghostty # repo scottames/ghostty (Fedora-only)

rhel:
  desktop:
    pm:
      - google-chrome-stable # ghostty NOT here: its COPR is Fedora-only
```

- **`pm`**: List of packages to install via the native package manager.
- **`script`**: List of URL-based installers to download and execute.
  - `name`: Display name for logs.
  - `url`: Script URL.
  - `args` (optional): Arguments passed to the script.
  - `envs` (optional): Environment variables passed to the script (e.g. `["KEY=value"]`).

Before any of this, `install.sh` calls `bootstrap_env` (in `scripts/pkg-utils.sh`),
which ensures the core tools the install process itself depends on (shell,
downloader, VCS, GPG, unzip for the Bitwarden CLI bootstrap) are present,
installing them with the native PM if any are missing. GPG is needed because
`enable_repo`'s apt-get `custom` kind (see
below) has to dearmor signing keys, and that step always runs _before_ `pm`
packages (including `gnupg` itself) are installed.

The install script:

1. Enables repositories (`enable_repo pm kind name [key=value ...]`)
2. Installs PM packages (`install_pkgs pm pkg1 pkg2 ...`)
3. Runs script-based installers (`install_script name url [args...]`)
4. Installs the latest LTS node via [fnm](https://github.com/Schniz/fnm) (managed, per-user; on
   musl/Alpine it fetches a musl-linked build from the unofficial mirror) and defaults to it
5. Installs cargo packages with `--locked`
6. Installs npm global packages (via fnm's per-user npm) and drops the bootstrap's root `bw`, so only the npm-installed one remains

### Repositories

Some packages (e.g. Google Chrome) aren't in the default repos and need one
enabled first. All repositories are declared centrally in
`home/.chezmoidata/repos.yaml`, keyed by the **same distro family** names as
`system.yaml` (from `families.yaml`), each with the `base`/`desktop` split, and
enabled before packages are installed so the package itself is then just a
normal entry under `pm`. The system's family (from `.chezmoi.toml.tmpl`) picks
the section; there's no `common` split here because a repo is intrinsically
package-manager-specific, so each family already carries exactly the repos its
own PM needs (repos shared by several families of the same PM are simply
repeated per family):

```yaml
repos:
  rhel:
    base:
      - kind: custom
        name: hashicorp
        baseurl: "https://rpm.releases.hashicorp.com/$distro/$releasever/$basearch/stable"
        gpgkey: "https://rpm.releases.hashicorp.com/gpg"
      - kind: rpm-release
        name: epel-release
        url: "https://dl.fedoraproject.org/pub/epel/epel-release-latest-$releasever.noarch.rpm"
  fedora:
    base:
      - kind: custom
        name: hashicorp
        baseurl: "https://rpm.releases.hashicorp.com/$distro/$releasever/$basearch/stable"
        gpgkey: "https://rpm.releases.hashicorp.com/gpg"
    desktop:
      - kind: copr
        name: scottames/ghostty
  ubuntu:
    base:
      - kind: custom
        name: hashicorp
        uri: "https://apt.releases.hashicorp.com"
        suites: "$codename"
        components: "main"
        signed_by: "https://apt.releases.hashicorp.com/gpg"
    desktop:
      - kind: ppa
        name: atareao/telegram
```

Each family section has `base` (enabled always) and `desktop` (enabled only
when a GUI session is detected). The target system is matched to **exactly
one** family via `/etc/os-release`'s `id` (from `families.yaml`). A package is
listed in `system.yaml` under a family only if that family enables a repo
providing it — e.g. `ghostty`/`spotify-client` need Fedora-only repos so they
appear under `fedora` but NOT `rhel`, and `telegram` comes from an Ubuntu-only
PPA so it appears under `ubuntu` but NOT `debian`. A family section here lists
exactly the repos that family enables; adding a new family is just adding it to
`families.yaml` plus a section in `system.yaml`/`repos.yaml`; no template
changes needed.

- **`kind: copr`** (dnf only): enables a Fedora COPR repo (`dnf copr enable`).
- **`kind: ppa`** (apt-get only): enables an Ubuntu PPA (`add-apt-repository`), self-installing
  `software-properties-common` first if missing.
- **`kind: rpm-release`** (dnf only): installs a release RPM directly (`dnf install <url>`), for
  packages distributed as a release package rather than a repo file (e.g. RPM Fusion).
- **`kind: deb-release`** (apt-get only): downloads a `.deb` to a temp file and installs it
  (`apt-get` can't install directly from a URL like `dnf` can).
- **`kind: apk-testing`** (apk only): installs one package from Alpine's edge/testing repo
  (`apk add --repository ...`) without switching the whole system to edge.
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
  them itself via `rpm -E %fedora`/`rpm -E %_arch` before calling `dnf install`
  (falling back to `%rhel` when `%fedora` is undefined, i.e. RHEL-family).
- `$distro` (dnf `custom` baseurl): some vendors (HashiCorp) publish a
  separate repo tree per distro family instead of one shared "fedora" tree —
  resolved to `fedora` or `RHEL` the same way as above.
- `$codename` (apt-get `custom` suites): resolved by `enable_repo` from
  `/etc/os-release`'s `VERSION_CODENAME`, for repos (like HashiCorp's) that
  publish per-codename suites instead of a generic channel name like `stable`.

These fields are written with single quotes (`squote`) in the generated
script so the literal `$...` survives shell parsing and reaches `enable_repo`
unexpanded.

### GUI detection

`hasGUI` is available as a chezmoi template variable. It detects a desktop
environment by checking for actual session entries inside
`/usr/share/xsessions` or `/usr/share/wayland-sessions` (not just that the
directory exists — Fedora/RHEL ship it empty by default even on headless
systems) — no distro-specific logic.

### Toolchain packages

`home/.chezmoidata/cargo.yaml` and `home/.chezmoidata/npm.yaml` declare
packages installed via their respective toolchains, each a list under
`base`/`desktop` (e.g. `cargo.base`, `cargo.desktop`). Each package is an
object with a `name` (`pkg@ver`) and an optional `args` list of extra
toolchain flags (e.g. `args: ["--force"]`). Managed by Renovate for
auto-updates.

Node itself comes from fnm (`Fnm` script installer in `system.yaml`), which
manages one LTS node per-user and is set up in `home/zsh/init/10-fnm.zsh`;
npm globals are installed through that same per-user npm. See "Updating" for
how the LTS is kept current.

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
`gnome-shell-extension-*` packages. Keyed by distro **family**, so each family
lists only extensions its repos carry (e.g. `appindicator` is Fedora-only).

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
ship. Run `updateOpencodeModels` (`bunx oh-my-opencode-slim install`, aliased
in `home/zsh/aliases.zsh`) to (re)generate it — the official installer
interviews you about your subscriptions (Claude, Copilot, Gemini, etc.) and
picks current best-fit models per agent, kept up to date by the plugin
maintainer instead of by us. It writes to
`~/.config/opencode/oh-my-opencode-slim.json[c]` (the plugin's unified config
location). Since that file isn't in the source state under
`home/dot_config/opencode/`, chezmoi treats it as unmanaged and leaves it alone.

Excluded on purpose (regenerated automatically, or machine-specific state, not
tracked here): `node_modules/`, `bun.lock`, `package*.json`, `logs/`, and
`~/.local/share/opencode/auth.json`/`account.json` (real credentials).


Machines needing extra providers not shared here (e.g. a local-only provider)
point `OPENCODE_CONFIG` at an untracked `~/.config/opencode/opencode-local.json`
via `home/dot_zshenv` (set only if that file exists); the tracked
`opencode.json` stays shared and host-agnostic.

### SSH configuration

`home/private_dot_ssh/private_config` ships a generic `~/.ssh/config` `Host *`
block (keepalive, `known_hosts` hygiene, no global agent forwarding) — safe,
host-agnostic defaults. `Include ~/.ssh/config.local` at the top pulls in
machine/work-specific `Host` blocks (VPN ranges, enterprise aliases, etc.)
from an untracked file, silently skipped by ssh if absent. SSH connection
multiplexing (`ControlMaster`) is intentionally disabled — it was previously
used but caused connection issues.

The `.ssh` directory itself is tracked as `private_dot_ssh`, so chezmoi
enforces `700` permissions on every apply.

SSH keys live in Bitwarden, not in this repo. Two note items in the vault
(`Personal SSH Key`, `Work SSH Key`) map to `~/.ssh/personal{,.pub}` and
`~/.ssh/work{,.pub}` via templates evaluated at apply time. Each note stores
the key as two custom fields, `privateKey` and `publicKey` — deliberately a
**note (secure note)** item and NOT an "SSH Key" item, whose import strips the
passphrase bcrypt header and silently saves the key in clear (so the rendered
key keeps its passphrase). They're rendered only when the vault is reachable —
an interactive run (chezmoi prompts for the master password via
`bitwarden.unlock = "auto"`) or when `BW_SESSION` is set; in a non-interactive
run with no session (CI, container) `.chezmoiignore` skips them so `bw` is
never invoked. `~/.ssh/config` lists both as `IdentityFile`.

The passphrase-protected OpenPGP secret key is also kept out of the repository.
Create a Bitwarden secure note named `Personal GPG Key` with one custom field named
`privateKey`. On the source machine, export the desired secret key directly
for copying into that field:

```sh
gpg --armor --export-secret-keys <fingerprint>
```

The export preserves the key's existing passphrase protection. When an
interactive chezmoi run or `BW_SESSION` makes the vault reachable, the
platform-neutral `run_before_00-import-gpg-key.sh.tmpl` script runs on every
enabled apply. It fetches the field once, stores only its SHA-256 hash under
the chezmoi state directory, and streams the armor directly to
`gpg --batch --import` only if the secret key is missing locally or the armor
changed. This also repairs a locally deleted key on the next enabled apply; no
armored key file is created. Import should not prompt. The first signing
operation prompts via pinentry for the key's existing passphrase unless
`gpg-agent` already has it cached.

The Bitwarden CLI is what makes this possible on a genuinely fresh machine, where
bw isn't installed yet at render time. Before invoking chezmoi, `install.sh`
runs `scripts/password-manager.sh install`, which installs the standalone `bw`
binary (latest CLI release, resolved from GitHub at runtime) and persists a
`BW_SESSION` key. It is a cheap no-op when bw is already present and the
persisted token is valid, or in non-interactive CI/container runs where the keys
are skipped anyway.

The session itself lives as a persisted `BW_SESSION` in the untracked
`~/.secrets/.env`. The installer sources it before running chezmoi, and
`.zshenv` sources it blindly in interactive shells (0ms — no `bw` call at shell
startup). Bitwarden session keys never expire on their own — they only die on
`bw lock`/`bw logout` — so once persisted, `chezmoi apply` (even a no-op one)
and `bw` are prompt-free: with `bitwarden.unlock = "auto"`, a present
`BW_SESSION` means chezmoi neither re-unlocks nor locks. If the token is ever
invalidated, the next `install.sh` run re-authenticates and rewrites it. npm's
`@bitwarden/cli` is the source of truth for `bw`: it installs via fnm's per-user
npm, and after the chezmoi apply `install.sh` calls
`scripts/password-manager.sh link`, which points `/usr/local/bin/bw` at the
per-user npm binary via symlink (`aliases/default` follows fnm's active LTS), so
there's a single real bw that chezmoi reaches via the system PATH and that isn't
re-downloaded on later runs. `unzip` is ensured by both `bootstrap_env` and the
`common` system packages.

## Testing

`tests/cases/*.yaml` (one file per package manager family) declares test
cases — a distro image plus forced `hasGUI`/`hasGnome` values. `tests/run.sh`
reads them and runs `install.sh` for one case or all of them, locally
or in CI (docker via `CONTAINER_RUNTIME=docker`):

```sh
tests/run.sh fedora-desktop-gnome   # single case
tests/run.sh --all                  # every case
```

Each case runs in a disposable container as a genuine non-root user (not
root — install.sh must actually work the way a real person runs it), then
`tests/install.bats` asserts on the result (packages present, config valid,
permissions correct, idempotent re-run, desktop/GNOME packages present only
when expected). `.github/workflows/test-configuration.yaml` generates its
job matrix directly from the same `tests/cases/*.yaml` files — no case list
duplicated between local and CI.

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
