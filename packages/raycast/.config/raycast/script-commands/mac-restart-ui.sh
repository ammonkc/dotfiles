#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Restart UI Components
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🔄
# @raycast.packageName Dotfiles

# Documentation:
# @raycast.description Restart Dock, Finder, and SystemUIServer
# @raycast.author Ammon Casey

cd "$HOME/Developer/src/ammonkc/dotfiles" || exit 1
task mac:restart:all
echo "✅ Dock, Finder, and SystemUIServer restarted"

