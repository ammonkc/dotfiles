#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Spin down
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🤖
# @raycast.packageName Docker Environment

# Documentation:
# @raycast.description Spin down docker
# @raycast.author Ammon Casey

cd ~/Developer/code/allegro.test && ./spin down
echo "Docker is down"
