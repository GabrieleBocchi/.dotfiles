# Load identities
zstyle :omz:plugins:keychain agents gpg,ssh
zstyle :omz:plugins:keychain identities $(echo $IDENTITIES)
zstyle :omz:plugins:keychain options '--quiet'

# Load Antidote
zsh_plugins_list=$DOTFILES/home/zsh/.zsh_plugins.txt
zsh_plugins_static=$HOME/.cache/antidote/.zsh_plugins.zsh

mkdir -p $HOME/.cache/antidote

if [[ ! $zsh_plugins_static -nt $zsh_plugins_list ]]; then
  (
    source $HOME/.local/share/antidote/antidote.zsh
    antidote bundle <$zsh_plugins_list >$zsh_plugins_static
  )
fi

source $zsh_plugins_static
