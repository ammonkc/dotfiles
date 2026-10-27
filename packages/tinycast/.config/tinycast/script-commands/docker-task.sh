#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Docker
# @raycast.mode compact

# Optional parameters:
# @raycast.icon ~/.config/raycast/script-commands/icons/docker.svg
# @raycast.packageName Docker
# @raycast.argument1 { "type": "dropdown", "placeholder": "task", "data": [{"title": "📊 Status", "value": "status"}, {"title": "📋 List Containers", "value": "ps"}, {"title": "🖼️ List Images", "value": "images"}, {"title": "💾 List Volumes", "value": "volumes"}, {"title": "🌐 List Networks", "value": "networks"}, {"title": "🔀 Show Context", "value": "context"}, {"title": "🛑 Stop All", "value": "stop:all"}, {"title": "💀 Kill All", "value": "kill:all"}, {"title": "🗑️ Remove All Containers", "value": "rm:all"}, {"title": "🧹 Prune", "value": "prune"}, {"title": "🧹 Prune Images", "value": "prune:images"}, {"title": "🧹 Prune Volumes", "value": "prune:volumes"}, {"title": "🧹 Prune Build Cache", "value": "prune:builders"}, {"title": "🦙 Use Colima", "value": "use:colima"}, {"title": "🌀 Use OrbStack", "value": "use:orbstack"}] }

# Documentation:
# @raycast.description Run Docker management tasks
# @raycast.author Ammon Casey

cd ~/.dotfiles && task docker:$1

