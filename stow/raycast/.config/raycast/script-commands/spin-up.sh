#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Spin up
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🤖
# @raycast.packageName Docker Environment
# @raycast.argument1 { "type": "dropdown", "placeholder": "option", "optional": true, "data": [{"title": "fresh", "value": "--fresh"}, {"title": "reset", "value": "--reset"}, {"title": "build", "value": "--build"}, {"title": "remove-data", "value": "--remove-data"}, {"title": "help", "value": "--help"}] }

# Documentation:
# @raycast.description Spin up docker
# @raycast.author Ammon Casey

cd ~/Developer/code/allegro.test && ./spin up $1
echo "Docker is up"
