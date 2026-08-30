keychain_keys=(personal work)

if (( $+commands[keychain] )); then
  _kc_env="$HOME/.keychain/${(%):-%m}-sh"
  [[ -z $SSH_AUTH_SOCK && -f $_kc_env ]] && source "$_kc_env"
  if [[ ! -S ${SSH_AUTH_SOCK:-} ]] || ! ssh-add -l >/dev/null 2>&1; then
    keychain add --quiet --host "${(%):-%m}" "${keychain_keys[@]}"
    source "$_kc_env"
  fi
  unset _kc_env
fi

# oh-my-zsh is managed by antidote (`antidote update`)
zstyle ':omz:update' mode disabled

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
