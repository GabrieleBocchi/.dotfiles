# Directories
export DOTFILES=$HOME/.dotfiles
export REPOS=$HOME/repos

# Editor
VIM="nvim"
export EDITOR=$VIM
export VISUAL=$VIM

# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
export ZSH_THEME="robbyrussell"

# Rust
. "$HOME/.cargo/env"

# Import secret environment variables
if [[ -f "$HOME/.secrets/.env" ]]; then
  source "$HOME/.secrets/.env"
fi
