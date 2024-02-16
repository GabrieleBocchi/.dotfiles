#!/usr/bin/env bash

set -e

# Install keyd
cd ~/dotfiles/keyboard/keyd/
make && sudo make install
sudo systemctl enable keyd && sudo systemctl start keyd

# Create a symlink to the keyd configuration
sudo ln -s -f ~/dotfiles/keyboard/default.conf /etc/keyd/default.conf

# Reload keyd
sudo keyd reload
