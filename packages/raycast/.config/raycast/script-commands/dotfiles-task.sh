#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Dotfiles Task
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon ⚙️
# @raycast.packageName Dotfiles
# @raycast.argument1 { "type": "dropdown", "placeholder": "task", "optional": false, "data": [{"title": "Clean Caches", "value": "clean"}, {"title": "Show Info", "value": "info"}, {"title": "Brew Cleanup", "value": "brew:cleanup"}, {"title": "Mise Update", "value": "mise:update"}, {"title": "Mise Outdated", "value": "mise:outdated"}, {"title": "Apply macOS Defaults", "value": "mac:set:defaults"}, {"title": "Install Secrets", "value": "secrets:install"}, {"title": "Dotfiles Install", "value": "dot:install"}, {"title": "Neovim Restore", "value": "nvim:restore"}, {"title": "Neovim Health", "value": "nvim:health"}] }

# Documentation:
# @raycast.description Run various dotfiles maintenance tasks
# @raycast.author Ammon Casey

cd "$HOME/Developer/src/ammonkc/dotfiles" || exit 1
task "$1"

