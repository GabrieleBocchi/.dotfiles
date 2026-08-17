#!/usr/bin/env bats

setup_file() {
    : "${REPO_DIR:?REPO_DIR must be set}"
    (cd "$REPO_DIR" && chezmoi data --format json) >"$BATS_FILE_TMPDIR/data.json"
    jq -r '.pm' "$BATS_FILE_TMPDIR/data.json" >"$BATS_FILE_TMPDIR/pm"
}

setup() {
    : "${REPO_DIR:?REPO_DIR must be set}"
    : "${CASE_HAS_GUI:=false}"
    : "${CASE_HAS_GNOME:=false}"
    PM="$(cat "$BATS_FILE_TMPDIR/pm")"
    DATA="$BATS_FILE_TMPDIR/data.json"
    FAMILY="$(jq -r '.family' "$DATA")"
    DCONF_DIR="$(jq -r '.chezmoi.sourceDir' "$DATA")/dconf"
}

pkg_installed() {
    case "$PM" in
    apk) apk info -e "$1" >/dev/null 2>&1 ;;
    apt-get) dpkg -s "$1" >/dev/null 2>&1 ;;
    dnf) rpm -q --whatprovides "$1" >/dev/null 2>&1 ;;
    esac
}

gui_flag() { [ "$CASE_HAS_GUI" = "true" ] && echo true || echo false; }
gnome_flag() { [ "$CASE_HAS_GNOME" = "true" ] && echo true || echo false; }

expected_system_packages() {
    jq -r --arg family "$FAMILY" \
        --argjson gui "$(gui_flag)" --argjson gnome "$(gnome_flag)" '
        (.common.base.pm + .[$family].base.pm)
        + (if $gui then .common.desktop.pm + .[$family].desktop.pm else [] end)
        + (if $gnome then (.gnome[$family] // []) else [] end)
        | .[]
    ' "$DATA"
}

expected_cargo_crates() {
    jq -r --argjson gui "$(gui_flag)" '
        .cargo.base + (if $gui then .cargo.desktop else [] end)
        | .[] | split("@")[0]
    ' "$DATA"
}

expected_npm_packages() {
    jq -r --argjson gui "$(gui_flag)" '
        .npm.base + (if $gui then .npm.desktop else [] end)
        | .[] | match("^(@[^/]+/[^@]+|[^@]+)").string
    ' "$DATA"
}

expected_scripts() {
    jq -r --arg family "$FAMILY" --argjson gui "$(gui_flag)" '
        (.common.base.script + .[$family].base.script)
        + (if $gui then .common.desktop.script + .[$family].desktop.script else [] end)
        | .[].name
    ' "$DATA"
}

expected_desktop_packages() {
    jq -r --arg family "$FAMILY" '
        (.common.desktop.pm + .[$family].desktop.pm) | .[]
    ' "$DATA"
}

# Maps a script display-name to its binary when it differs from the lowercase name.
script_tool_binary() {
    case "$1" in
    Rust) echo rustc ;;
    *) echo "$1" | tr '[:upper:]' '[:lower:]' ;;
    esac
}

@test "chezmoi is installed at the pinned version" {
    run chezmoi --version
    [ "$status" -eq 0 ]

    pinned="$(cat "$REPO_DIR/.chezmoiversion")"
    case "$output" in
    *"$pinned"*) ;;
    *)
        echo "expected chezmoi $pinned, got: $output" >&2
        return 1
        ;;
    esac
}

@test "declared system packages are installed" {
    local -a missing=()
    while IFS= read -r pkg; do
        [ -z "$pkg" ] && continue
        pkg_installed "$pkg" || missing+=("$pkg")
    done < <(expected_system_packages)
    if ((${#missing[@]})); then
        printf 'missing packages:\n' >&2
        printf '  - %s\n' "${missing[@]}" >&2
        return 1
    fi
}

@test "script-installed tools are on PATH" {
    while IFS= read -r name; do
        [ -z "$name" ] && continue
        bin="$(script_tool_binary "$name")"
        command -v "$bin" >/dev/null 2>&1 || {
            echo "missing: $bin ($name)" >&2
            return 1
        }
    done < <(expected_scripts)
}

@test "declared cargo packages are installed" {
    installed="$(cargo install --list 2>/dev/null)"

    while IFS= read -r crate; do
        [ -z "$crate" ] && continue
        printf '%s\n' "$installed" | grep -q "^$crate v" || {
            echo "missing cargo package: $crate" >&2
            return 1
        }
    done < <(expected_cargo_crates)
}

@test "declared npm packages are installed" {
    installed="$(npm list -g --depth=0 --json 2>/dev/null)"

    while IFS= read -r pkg; do
        [ -z "$pkg" ] && continue
        printf '%s' "$installed" | jq -e --arg pkg "$pkg" '.dependencies[$pkg] != null' >/dev/null || {
            echo "missing npm package: $pkg" >&2
            return 1
        }
    done < <(expected_npm_packages)
}

@test "opencode config is present and valid" {
    [ -f "$HOME/.config/opencode/opencode.json" ]
    [ -f "$HOME/.config/opencode/tui.json" ]

    run opencode debug config
    [ "$status" -eq 0 ]
}

@test "kanata config is valid" {
    run kanata --check --cfg "$REPO_DIR/home/dot_config/kanata/config.kbd"
    [ "$status" -eq 0 ]
}

@test "ssh config and directory permissions are correct" {
    [ -f "$HOME/.ssh/config" ]
    perm_ssh="$(stat -c '%a' "$HOME/.ssh")"
    perm_config="$(stat -c '%a' "$HOME/.ssh/config")"
    [ "${perm_ssh: -3}" = "700" ]
    [ "${perm_config: -3}" = "600" ]

    run ssh -G localhost </dev/null
    [ "$status" -eq 0 ]
}

@test "install.sh second run" {
    cd "$REPO_DIR"
    cmd="./install.sh"
    [ "$CASE_HAS_GNOME" = "true" ] && cmd="dbus-run-session -- $cmd"
    run $cmd
    [ "$status" -eq 0 ]
}

@test "desktop packages absent when headless" {
    [ "$CASE_HAS_GUI" = "true" ] && skip "GUI present"

    # Whitelist: desktop packages allowed on headless systems (for example transitive dependencies)
    local -a whitelist=(fontconfig)

    while IFS= read -r pkg; do
        [ -z "$pkg" ] && continue
        for entry in "${whitelist[@]}"; do
            [[ "$pkg" == "$entry" ]] && continue 2
        done
        if pkg_installed "$pkg"; then
            echo "$pkg should NOT be installed (hasGUI=false)" >&2
            return 1
        fi
    done < <(expected_desktop_packages)
}

@test "GNOME dconf keyfiles load without error" {
    [ "$CASE_HAS_GNOME" != "true" ] && skip "GNOME not present"

    local tmp
    tmp="$(mktemp)"
    for f in "$DCONF_DIR"/*.ini; do
        cat "$f" >>"$tmp"
        echo >>"$tmp"
    done
    for f in "$DCONF_DIR"/*.ini.tmpl; do
        [ -e "$f" ] || continue
        (cd "$REPO_DIR" && chezmoi execute-template <"$f") >>"$tmp"
        echo >>"$tmp"
    done

    run dbus-run-session -- sh -c "dconf load / < '$tmp'"
    local status_of_load=$status
    rm -f "$tmp"
    [ "$status_of_load" -eq 0 ]
}
