#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Neovim Update
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon 📝
# @raycast.packageName Dotfiles

# Documentation:
# @raycast.description Update Neovim plugins, CLI utils, and TreeSitter
# @raycast.author Ammon Casey

cd "$HOME/Developer/src/ammonkc/dotfiles" || exit 1
task nvim:update

