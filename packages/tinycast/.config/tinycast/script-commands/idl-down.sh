#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title IDL Down
# @raycast.mode compact

# Optional parameters:
# @raycast.icon ~/.config/tinycast/script-commands/icons/docker.svg
# @raycast.packageName IDL Docker
# @raycast.argument1 { "type": "text", "placeholder": "worktree", "optional": true }
# @raycast.argument2 { "type": "text", "placeholder": "domain", "optional": true }
# @raycast.argument3 { "type": "text", "placeholder": "queue (already included)", "optional": true }

# Documentation:
# @raycast.description Stop IDL Docker containers
# @raycast.author Ammon Casey

helper="$HOME/.local/bin/idl-down"
if [[ ! -x "$helper" ]]; then
  echo "IDL helper missing: $helper. Install the bin dotfiles package." >&2
  exit 1
fi

args=("${1:-}" "${2:-}")
IFS=',' read -r -a profiles <<< "${3:-}"
for profile in "${profiles[@]}"; do
  profile="${profile#"${profile%%[![:space:]]*}"}"
  profile="${profile%"${profile##*[![:space:]]}"}"
  [[ -n "$profile" ]] && args+=(--profile "$profile")
done

exec "$helper" "${args[@]}"
