#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Zim Upgrade
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon 🐚
# @raycast.packageName Dotfiles

# Documentation:
# @raycast.description Upgrade zimfw to the latest version
# @raycast.author Ammon Casey

/bin/zsh -ic "zimfw upgrade"

