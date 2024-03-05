#!/usr/bin/env bash

set -e

# Ask for delete old nvim config
read -p "Do you want to delete old nvim configs? y/N " yn
if [[ $yn = "Y" || $yn = "y" ]]; then
	rm -rf ~/.local/share/nvim
fi

# Open nvim to install plugins
nvim --headless +"qa"
