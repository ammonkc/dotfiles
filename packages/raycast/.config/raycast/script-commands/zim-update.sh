#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Zim Update Modules
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon 🐚
# @raycast.packageName Dotfiles

# Documentation:
# @raycast.description Update zimfw modules
# @raycast.author Ammon Casey

/bin/zsh -ic "zimfw update"

