#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Allegro Up
# @raycast.mode compact

# Optional parameters:
# @raycast.icon ~/.config/raycast/script-commands/icons/docker.svg
# @raycast.packageName Allegro Docker

# Documentation:
# @raycast.description Start Allegro Docker containers (allegro.test)
# @raycast.author Ammon Casey

PROJECT_DIR="$HOME/Developer/code/allegro.test"

cd "$PROJECT_DIR" || { echo "❌ Cannot find $PROJECT_DIR"; exit 1; }

docker compose -f docker-compose.yaml \
    --profile sftp \
    --profile php8-work \
    up --force-recreate --build --detach --remove-orphans

echo "✅ allegro containers started"

