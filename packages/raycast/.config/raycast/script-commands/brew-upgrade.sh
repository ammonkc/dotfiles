#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Brew Upgrade
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon 🍺
# @raycast.packageName Dotfiles

# Documentation:
# @raycast.description Upgrade all Homebrew packages
# @raycast.author Ammon Casey

cd "$HOME/Developer/src/ammonkc/dotfiles" || exit 1
task brew:upgrade

