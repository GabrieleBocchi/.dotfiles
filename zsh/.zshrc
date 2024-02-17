# Oh My Zsh plugins
plugins=(git)

# Other sources
source "$ZSH"/oh-my-zsh.sh
source "$DOTFILES"/zsh/aliases.zsh
source "$DOTFILES"/zsh/functions.zsh

# Opts
setopt extendedglob
setopt globdots
zstyle ':completion:*' special-dirs false

# Remove duplicate entries from PATH:
pathPrepend "$HOME"/.local/bin
pathPrepend "$HOME"/.local/share/cargo/bin
PATH=$(echo "$PATH" | awk -v RS=':' -v ORS=":" '!a[$1]++{if (NR > 1) printf ORS; printf $a[$1]}')
