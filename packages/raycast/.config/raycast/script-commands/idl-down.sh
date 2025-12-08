#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title IDL Down
# @raycast.mode compact

# Optional parameters:
# @raycast.icon ~/.config/raycast/script-commands/icons/docker.svg
# @raycast.packageName IDL Docker

# Documentation:
# @raycast.description Stop IDL Docker containers (allegro.test)
# @raycast.author Ammon Casey

PROJECT_DIR="$HOME/Developer/code/allegro.test"

cd "$PROJECT_DIR" || { echo "❌ Cannot find $PROJECT_DIR"; exit 1; }

USER_ID=502 GROUP_ID=20 docker compose -f docker-compose.yaml \
    --profile sftp \
    --profile php8-work \
    down

echo "✅ IDL containers stopped"

