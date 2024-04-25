#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Spin up
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🤖
# @raycast.packageName Docker Environment

# Documentation:
# @raycast.description Spin up docker
# @raycast.author Ammon Casey

cd ~/Developer/code/allegro.test && ./spin up

echo "Docker is up"
