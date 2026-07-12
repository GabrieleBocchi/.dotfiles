#!/usr/bin/env zsh

source ~/.zshrc

set -eo pipefail

source $HOME/.local/share/antidote/antidote.zsh
antidote update
