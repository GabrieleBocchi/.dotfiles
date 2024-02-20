# better commands
alias cat='bat'
alias cdtemp='cd $(mktemp -d)'
alias ez="exec zsh"
alias gdb='gdb -q'
alias grep='grep -i --color=auto'
alias l='ls -lAh'
alias mkdir='mkdir -pv'
alias open='xdg-open'
alias sl='sl -ade5'
alias tmx='tmux'
alias tree='tree -a'

# docker
alias docker='sudo docker'
if command -v podman &> /dev/null; then
    alias docker="podman"
fi

# GitHub CLI
alias copilot='gh copilot'
alias gce='gh copilot explain'
alias gcs='gh copilot suggest'

# grep
alias agrep="alias | grep"
alias hgrep="history | grep"
alias psgrep="ps aux | grep"

# ipinfo.io
alias ipinfo='curl -s ipinfo.io | jq'

# mount
alias mountNas='sudo mount -t cifs -o rw,vers=3.0,credentials=$NASCREDSLOCATION $NASLOCATION /mnt/NAS'
alias umountNas='sudo umount /mnt/NAS'

# network
alias connect='nmcli connection up'
alias disconnect='nmcli connection down'

# python
alias venv='python3 -m venv env'
alias activate='source env/bin/activate'
