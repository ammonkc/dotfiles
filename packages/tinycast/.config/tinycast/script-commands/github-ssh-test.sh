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

# Set up SSH agent for 1Password (if available)
if [ -S "$HOME/.1password/agent.sock" ]; then
  export SSH_AUTH_SOCK="$HOME/.1password/agent.sock"
elif [ -S "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock" ]; then
  export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
fi

# ssh -T returns exit code 1 even on success (GitHub denies shell access)
OUTPUT=$(ssh -T git@github.com 2>&1) || true

if echo "$OUTPUT" | grep -q "successfully authenticated"; then
  USER=$(echo "$OUTPUT" | sed -n 's/.*Hi \([^!]*\)!.*/\1/p')
  echo "✅ Connected as $USER"
else
  echo "❌ $OUTPUT"
fi

