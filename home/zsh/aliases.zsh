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

# Bitwarden session (not exported, see dot_zshenv)
bw() { BW_SESSION="${BW_SESSION:-}" command bw "$@" }
chezmoi() { BW_SESSION="${BW_SESSION:-}" command chezmoi "$@" }

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
updatePackages() {
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
