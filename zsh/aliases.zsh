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

# Network
alias connect='nmcli connection up'
alias disconnect='nmcli connection down'

# Python
alias venv='python3 -m venv env'
alias activate='source env/bin/activate'

# Import work aliases
if [ -f ~/.aliases_work ]; then
    . ~/.aliases_work
fi
