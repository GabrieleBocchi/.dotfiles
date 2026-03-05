# Browser
export BROWSER=google-chrome-stable

# Directories
export DOTFILES=$HOME/.dotfiles
export REPOS=$HOME/repos

# Docker
if command -v podman &> /dev/null; then
    export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/podman/podman.sock
fi

# Editor
VIM="nvim"
export EDITOR=$VIM
export VISUAL=$VIM

# Rust
. "$HOME/.cargo/env"

# Import secret environment variables
if [[ -f "$HOME/.secrets/.env" ]]; then
  source "$HOME/.secrets/.env"
fi
