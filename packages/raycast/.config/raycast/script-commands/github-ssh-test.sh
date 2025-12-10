#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title GitHub SSH Test
# @raycast.mode compact

# Optional parameters:
# @raycast.icon ~/.config/raycast/script-commands/icons/github.svg
# @raycast.packageName GitHub

# Documentation:
# @raycast.description Test SSH connectivity to GitHub
# @raycast.author Ammon Casey

# ssh -T returns exit code 1 even on success (GitHub denies shell access)
OUTPUT=$(ssh -T git@github.com 2>&1) || true

if echo "$OUTPUT" | grep -q "successfully authenticated"; then
  USER=$(echo "$OUTPUT" | sed -n 's/.*Hi \([^!]*\)!.*/\1/p')
  echo "✅ Connected as $USER"
else
  echo "❌ $OUTPUT"
fi

