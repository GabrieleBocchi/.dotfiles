# Load identities
zstyle :omz:plugins:keychain agents gpg,ssh
zstyle :omz:plugins:keychain identities $(echo $IDENTITIES)

# Load Antidote
zsh_plugins=$DOTFILES/zsh/.zsh_plugins

fpath=($DOTFILES/zsh/antidote/functions $fpath)
autoload -Uz antidote

if [[ ! ${zsh_plugins}.zsh -nt ${zsh_plugins}.txt ]]; then
  antidote bundle <${zsh_plugins}.txt >|${zsh_plugins}.zsh
fi

source ${zsh_plugins}.zsh
