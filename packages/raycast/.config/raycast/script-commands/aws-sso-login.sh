#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title GenAI Login (AWS SSO)
# @raycast.mode compact

# Optional parameters:
# @raycast.icon ~/.config/raycast/script-commands/icons/claude.svg
# @raycast.packageName GenAI

# Documentation:
# @raycast.description Login to AWS SSO with genai profile for Claude Code
# @raycast.author Ammon Casey

aws sso login --profile genai

echo "✅ AWS SSO login initiated for genai profile"

