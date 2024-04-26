#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Spin artisan
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon 🤖
# @raycast.packageName Docker Environment
# @raycast.argument1 { "type": "text", "placeholder": "artisan command", "optional": true }

# Documentation:
# @raycast.description Spin artisan command
# @raycast.author Ammon Casey

cd ~/Developer/code/allegro.test && ./spin artisan $1
