# Better commands
alias cat='bat'
alias cdtemp='cd $(mktemp -d)'
alias ez="exec zsh"
alias gdb='gdb -q'
alias gist_ctf_create='gist -p -c'
alias gist_ctf_update='gist -u'
alias grep='grep -i --color=auto'
alias l='ls -lAh'
alias open='xdg-open'
alias sl='sl -ade5'
alias tmx='tmux'
alias tree='tree -a'

# Docker
alias docker='sudo docker'
if command -v podman &> /dev/null; then
    alias docker="podman"
fi

# GitHub CLI
alias copilot='gh copilot'
alias gce='gh copilot explain'
alias gcs='gh copilot suggest'

# Grep
alias agrep="alias | grep"
alias hgrep="history | grep"
alias psgrep="ps aux | grep"

# Ipinfo.io
alias ipinfo='curl -s ipinfo.io | jq'

# Mount
alias mountNas='sudo mount -t cifs -o rw,vers=3.0,credentials=$NASCREDSLOCATION $NASLOCATION /mnt/NAS'
alias umountNas='sudo umount /mnt/NAS'

# Neofetch
if command -v fastfetch &> /dev/null; then
    alias neofetch='fastfetch'
fi

# Network
alias connect='nmcli connection up'
alias disconnect='nmcli connection down'

# Python
alias venv='python3 -m venv env'
alias activate='source */bin/activate'

# Updates
alias updatePackages='sudo dnf upgrade --refresh -y'
alias updateNvim='nvim --headless "+Lazy! sync" +qa >/dev/null'
alias updatePip='(pip install --upgrade pip && pip --disable-pip-version-check list --outdated --format=json | python -c "import json, sys; print(\"\n\".join([x[\"name\"] for x in json.load(sys.stdin)]))" | xargs -n1 pip install -U) || true'
alias updateAll='updatePackages && updateNvim && updatePip && antidote update'

# Import work aliases
if [ -f ~/.aliases_work ]; then
    . ~/.aliases_work
fi
