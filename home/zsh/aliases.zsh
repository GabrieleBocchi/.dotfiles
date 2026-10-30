# Better commands
alias c='clear'
alias cl='claude'
alias cdtemp='cd $(mktemp -d)'
alias ez="exec zsh"
alias gdb='gdb -q'
alias gist_ctf_create='gist -p -c'
alias gist_ctf_update='gist -u'
alias grep='grep -i --color=auto'
alias l='ls -lAh'
alias o='opencode'
alias open='xdg-open'
alias sl='sl -ade5'
alias tmx='tmux'
alias top='btop'
alias tree='tree -a'

# bat (resolved to bat/batcat in dot_zshenv's $BAT_CMD)
if [[ -n "${BAT_CMD:-}" ]]; then
    alias cat="$BAT_CMD"
fi

# Bitwarden session: only bw and chezmoi get it (see scripts/password-manager.sh)
bw_session_env() { [[ -r ~/.secrets/bw-session ]] && print -r -- "BW_SESSION=$(<~/.secrets/bw-session)" }
bw() { env $(bw_session_env) bw "$@" }
chezmoi() { env $(bw_session_env) chezmoi "$@" }

# Docker
alias docker='sudo docker'
if command -v podman &> /dev/null; then
    alias docker="podman"
fi

# Grep
alias agrep="alias | grep"
alias hgrep="history | grep"
alias psgrep="ps aux | grep"

# Ipinfo.io
alias ipinfo='curl -s ipinfo.io | jq'

# Neofetch
if command -v fastfetch &> /dev/null; then
    alias neofetch='fastfetch'
fi

# Python
alias venv='python3 -m venv env'
alias activate='source */bin/activate'

# Updates
alias updateDotfiles='git -C "$DOTFILES" pull --prune && $DOTFILES/install.sh'
alias updateNvim='nvim --headless "+Lazy! sync" +qa >/dev/null'
alias updateOpencodeSlim='bunx oh-my-opencode-slim install --companion=no'
function updatePackages {
    if (( $+commands[apk] )); then
        sudo apk upgrade --update-cache
    elif (( $+commands[apt-get] )); then
        sudo apt-get update && sudo apt-get upgrade -y
    else
        sudo dnf upgrade --refresh -y
    fi
}
alias updateAll='updatePackages && updateDotfiles && updateNvim'

# Import local aliases
if [ -f ~/.aliases_local.zsh ]; then
    . ~/.aliases_local.zsh
fi
