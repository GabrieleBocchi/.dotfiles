# Better commands
alias c='clear'
alias cat='bat'
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
alias updateOpencodeModels='bunx oh-my-openagent install'
alias updatePackages='sudo dnf upgrade --refresh -y'
alias updateAll='updatePackages && updateNvim && updateDotfiles'

# Import work aliases
if [ -f ~/.aliases_work ]; then
    . ~/.aliases_work
fi
