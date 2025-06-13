# Other sources
source "$DOTFILES"/zsh/oh-my-zsh.zsh
source "$DOTFILES"/zsh/aliases.zsh
source "$DOTFILES"/zsh/functions.zsh

# Opts
setopt extendedglob
setopt globdots
zstyle ':completion:*' special-dirs false

# Remove duplicate entries from PATH:
pathPrepend "$HOME"/bin
pathPrepend "$HOME"/.ghcup/bin
pathPrepend "$HOME"/.local/bin
pathPrepend "$HOME"/.local/share/cargo/bin
pathPrepend /usr/local/texlive/2024/bin/x86_64-linux
[[ -d $HOME/.pyenv/bin ]] && export PATH="$HOME/.pyenv/bin:$PATH"

PATH=$(echo "$PATH" | awk -v RS=':' -v ORS=":" '!a[$1]++{if (NR > 1) printf ORS; printf $a[$1]}')

# Pyenv
eval "$(pyenv init - zsh)"
