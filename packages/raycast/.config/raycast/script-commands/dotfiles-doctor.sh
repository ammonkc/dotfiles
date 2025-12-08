#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Dotfiles Doctor
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon 🩺
# @raycast.packageName Dotfiles

# Documentation:
# @raycast.description Run health checks on dotfiles setup
# @raycast.author Ammon Casey

cd "$HOME/Developer/src/ammonkc/dotfiles" || exit 1
task doctor

