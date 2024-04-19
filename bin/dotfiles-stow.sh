#!/bin/sh

STOW_DIR="$DOTFILES/stow"

notice "Stowing dotfiles..."

stow_pkg() {
    stow -t "$HOME" -d "$STOW_DIR" -S "$1"
    c_list "$1 stowed"
}

# Removes .zshrc from $HOME (if it exists)
if [ -f $HOME/.zshrc ]; then
    rm -rf $HOME/.zshrc
fi

packages=($STOW_DIR/*)
packages=("${packages[@]%/}")
packages=("${packages[@]##*/}")

if [ "$#" -eq 0 ]; then
    for package in "${packages[@]}"; do
        stow_pkg "$package"
    done
else
    stow_pkg "$1"
fi
