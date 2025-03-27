#!/usr/bin/env bash

set -e

FONT="JetBrainsMono"
FONT_PATH="$FONT.tar.xz"

if ! fc-match -a | grep -q $FONT; then
    curl -OL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$FONT_PATH
    tar -xf ./$FONT_PATH -C ~/.local/share/fonts/fonts/
    rm ./$FONT_PATH
    rm -f ~/.local/share/fonts/fonts/OFL.txt
    rm -f ~/.local/share/fonts/fonts/README.md
    fc-cache -f -v
else
    echo "$FONT is already installed"
fi
