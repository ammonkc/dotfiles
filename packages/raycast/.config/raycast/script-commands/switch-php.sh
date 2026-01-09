#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Switch PHP Version
# @raycast.mode compact

# Optional parameters:
# @raycast.icon ~/.config/raycast/script-commands/icons/php.svg
# @raycast.packageName php version
# @raycast.argument1 { "type": "dropdown", "placeholder": "version", "optional": true, "data": [{"title": "8.0", "value": "8.0"}, {"title": "8.1", "value": "8.1"}, {"title": "8.2", "value": "8.2"}, {"title": "8.3", "value": "8.3"}, {"title": "8.4", "value": "8.4"}] }

# Documentation:
# @raycast.description Switch PHP version (leave empty to show current version)
# @raycast.author Ammon Casey

# Use zsh to call the phpswitch function and capture output
output=$(/bin/zsh -ic "phpswitch $1" 2>/dev/null)

# Strip ANSI color codes and extract version number from first line
version=$(echo "$output" | sed 's/\x1b\[[0-9;]*m//g' | head -1 | cut -d' ' -f2)

if [[ -n "$1" ]]; then
    echo "Switched to PHP $version"
else
    echo "PHP $version"
fi
