# Load Antidote
zsh_plugins=$DOTFILES/zsh/.zsh_plugins

fpath=($DOTFILES/zsh/antidote/functions $fpath)
autoload -Uz antidote

if [[ ! ${zsh_plugins}.zsh -nt ${zsh_plugins}.txt ]]; then
  antidote bundle <${zsh_plugins}.txt >|${zsh_plugins}.zsh
fi

source ${zsh_plugins}.zsh

# Load SSH identities
zstyle :omz:plugins:ssh-agent identities $(echo $SSH_IDENTITIES)

# Load The Fuck plugin
eval $(thefuck --alias)
