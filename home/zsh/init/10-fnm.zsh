# fnm (installed with --skip-shell; init handled here)
if [[ -x "$HOME/.local/share/fnm/fnm" ]]; then
    path=("$HOME/.local/share/fnm" $path)

    # musl (Alpine/void): fetch musl-linked node binaries
    if [[ -n "$(ls /lib/ld-musl-*.so.1(N) 2>/dev/null)" ]]; then
        export FNM_NODE_DIST_MIRROR="https://unofficial-builds.nodejs.org/download/release"
        case "$(uname -m)" in
            aarch64) export FNM_ARCH="arm64-musl" ;;
            x86_64)  export FNM_ARCH="x64-musl" ;;
            *)
                print -u2 "fnm: unsupported musl arch: $(uname -m)"
                return 1
                ;;
        esac
    fi

    eval "$(fnm env --use-on-cd --shell zsh)"
fi
