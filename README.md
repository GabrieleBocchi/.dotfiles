# Dotfiles

My dotfiles, managed with [chezmoi](https://chezmoi.io/): Ghostty, Git, GNOME
(dconf), kanata, Neovim ([gab.lazy](https://github.com/GabrieleBocchi/gab.lazy)),
OpenCode, Claude Code, SSH, tmux ([gpakosz/.tmux](https://github.com/gpakosz/.tmux))
and zsh (antidote, Starship).

## Install and update

```sh
git clone https://github.com/GabrieleBocchi/.dotfiles ~/.dotfiles
~/.dotfiles/install.sh
```

To update, run `updateDotfiles`, or `git -C ~/.dotfiles pull --prune` and then
`install.sh` again. `install.sh` installs the chezmoi version from
`.chezmoiversion`, sets up the Bitwarden CLI, and applies the config.

Every apply updates the zsh plugins, the Rust toolchain, the OpenCode plugins
and the Flatpak apps. The dependency script re-runs only when its rendered
content changes: a package, a version, or `scripts/pkg-utils.sh`.

## Shell

- `PATH` is set in `.zshenv`, so non-interactive shells (`ssh host cmd`, cron)
  also find it. `.zshrc` sets it again because some `/etc/profile` files
  (Alpine) reset it.
- `~/.secrets/.env` (untracked) loads only in interactive shells, as
  unexported variables. Child processes (agents, MCP servers, scripts) do not
  get them. Pass one explicitly: `VAR=$VAR cmd`.
- `DOCKER_HOST` points to the rootless podman socket.

## Dependencies

All dependencies are data in `home/.chezmoidata/`:

| File            | Content                                              |
| --------------- | ---------------------------------------------------- |
| `families.yaml` | os-release id → family → package manager             |
| `system.yaml`   | native packages and URL installers, per family       |
| `repos.yaml`    | repositories to enable before packages, per family   |
| `gnome.yaml`    | GNOME packages, per family (only when `hasGnome`)    |
| `flatpak.yaml`  | Flatpak remotes and apps (user install, GUI only)    |
| `cargo.yaml`    | `cargo install --locked` packages                    |
| `npm.yaml`      | `npm install -g` packages (Node comes from fnm, LTS) |

Rules:

- A system matches exactly one family. If none matches, chezmoi detects the
  package manager and uses only the `common` sections.
- To support a new distro of an existing family, add its id to
  `families.yaml`. No template change is necessary.
- `base` entries install everywhere. `desktop` entries install only when
  `hasGUI` is true.
- List a package under a family only if that family has a repo for it.
- `hasGUI` is true when `/usr/share/{x,wayland-}sessions` contains a session
  file. The directory alone is not enough: Fedora and RHEL ship it empty.
  `hasGnome` is true when `gnome-shell` is on `PATH`.

Repo kinds (`enable_repo` in `scripts/pkg-utils.sh`): `copr` and `rpm-release`
(dnf), `deb-release` (apt-get), `apk-testing` (one package from Alpine
edge/testing), and `custom` (writes a `.repo` file or a deb822 source with a
dearmored key).

`enable_repo` resolves these placeholders on the target machine:
`$releasever`, `$basearch`, `$distro` (`fedora` or `RHEL`) and `$codename`. The
template quotes them with `squote` so that the shell does not expand them.

## GNOME

`home/dconf/*.ini` files are loaded with `dconf load /` on every apply, so
changes made in GNOME Settings are reverted. `extensions.ini.tmpl` enables only
the extensions that are installed.

## Claude Code

- `home/.chezmoitemplates/claude-settings.json` is the tracked base of
  `~/.claude/settings.json`. Its `permissions.deny` rules block reads of
  secrets.
- Put machine-specific settings in the untracked
  `~/.claude/settings.overrides.json`. Its hooks and deny rules are appended;
  other keys override the base.
- Apply reverts changes made with `/config`. Claude Code also rewrites the
  file in its own key order, so chezmoi can report a diff after `/config` or
  `/effort`. Accept the overwrite.
- The status line is [ccstatusline](https://github.com/sirmalloc/ccstatusline).
  After you change it in its TUI, run
  `chezmoi re-add ~/.config/ccstatusline/settings.json`. Do not use the TUI
  install/uninstall option: it edits `~/.claude/settings.json`.
- Register MCP servers by hand with `claude mcp add`.

## OpenCode

- `home/dot_config/opencode/` holds `opencode.json`, `cli.json` and the
  oh-my-opencode-slim routing (`oh-my-opencode-slim.json`).
- The `cc-safety-net` plugin blocks destructive commands and secret reads. It
  is necessary because OpenCode's own `deny` patterns
  [can be bypassed](https://github.com/anomalyco/opencode/issues/28682).
- `updateOpencodeSlim` refreshes the Slim skills and keeps the routing. It does
  not update model IDs. `--reset` replaces the routing and makes a backup.
- For machine-only providers, create `~/.config/opencode/opencode-local.json`.
  `.zshenv` sets `OPENCODE_CONFIG` to it when the file exists.
- RTK generates its own OpenCode and Claude Code integration files after each
  apply. They are not tracked.

## SSH and GPG keys

Keys are stored in Bitwarden, not in this repo. `~/.ssh/config.local`
(untracked) holds the machine-specific `Host` blocks.

- SSH: the secure notes `Personal SSH Key` and `Work SSH Key` have the custom
  fields `privateKey` and `publicKey`. Use a secure note, not an "SSH Key"
  item: its import removes the passphrase protection.
- GPG: the secure note `Personal GPG Key` has the field `privateKey`. Fill it
  with `gpg --armor --export-secret-keys <fingerprint>`. The apply imports the
  key only when it is missing or when the note changed. gpg asks for the
  passphrase at the first signature.
- chezmoi renders the keys only when the vault is reachable: an interactive
  run, or `BW_SESSION` set. In CI and containers they are skipped. The
  standalone `bw` is glibc-only, so musl systems skip the keys too.
- The session key is stored in `~/.secrets/bw-session`. Only `install.sh` and
  the `bw` and `chezmoi` shell functions use it, and the chezmoi scripts that
  run third-party installers unset it. It does not expire until
  `bw lock`/`bw logout`.

## Tests

`tests/cases/*.yaml` lists the test cases: an image plus `hasGUI`/`hasGnome`.
Each case runs `install.sh` as a non-root user in a container, then
`tests/install.bats` checks the result. CI builds its matrix from the same
files.

```sh
tests/run.sh fedora-desktop-gnome   # one case
tests/run.sh --all                  # all cases
CONTAINER_RUNTIME=docker tests/run.sh --all
```

## Version pins

Renovate updates chezmoi (`.chezmoiversion`), the externals in
`.chezmoiexternal.toml.tmpl`, the Bitwarden CLI
(`scripts/password-manager.sh`), and the cargo/npm packages. gab.lazy is not
pinned: it follows `main` and updates at most once every 24h.
