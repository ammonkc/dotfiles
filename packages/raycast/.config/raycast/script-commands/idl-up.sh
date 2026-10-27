#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title IDL Up
# @raycast.mode compact

# Optional parameters:
# @raycast.icon ~/.config/raycast/script-commands/icons/docker.svg
# @raycast.packageName IDL Docker
# @raycast.argument1 { "type": "text", "placeholder": "worktree", "optional": true }
# @raycast.argument2 { "type": "text", "placeholder": "domain", "optional": true }
# @raycast.argument3 { "type": "text", "placeholder": "queue, --build (optional)", "optional": true }

# Documentation:
# @raycast.description Start IDL Docker containers
# @raycast.author Ammon Casey

helper="$HOME/.local/bin/idl-up"
if [[ ! -x "$helper" ]]; then
  echo "IDL helper missing: $helper. Install the bin dotfiles package." >&2
  exit 1
fi

args=()
worktree=""
domain=""
for arg in "${1:-}" "${2:-}"; do
  case "$arg" in
    -b|--build) args+=(--build) ;;
    ""|true|false) ;;
    *) if [[ -z "$worktree" ]]; then worktree="$arg"; else domain="$arg"; fi ;;
  esac
done
args+=("$worktree" "$domain")

IFS=',' read -r -a options <<< "${3:-}"
for option in "${options[@]}"; do
  option="${option#"${option%%[![:space:]]*}"}"
  option="${option%"${option##*[![:space:]]}"}"
  case "$option" in
    -b|--build|true) args+=(--build) ;;
    ""|false) ;;
    *) args+=(--profile "$option") ;;
  esac
done

exec "$helper" "${args[@]}"
