#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title IDL Down
# @raycast.mode compact

# Optional parameters:
# @raycast.icon ~/.config/raycast/script-commands/icons/docker.svg
# @raycast.packageName IDL Docker
# @raycast.argument1 { "type": "text", "placeholder": "worktree", "optional": true }
# @raycast.argument2 { "type": "text", "placeholder": "domain", "optional": true }

# Documentation:
# @raycast.description Stop IDL Docker containers
# @raycast.author Ammon Casey

BASE_DIR="$HOME/Developer/code/indirect"
ALLEGRO_DOMAIN="${2:-allegro.test}"

# Resolve worktree from arg, else from cwd under BASE_DIR, else 'main'
default_worktree() {
    local pwd_real base_real rel
    pwd_real="$(pwd -P 2>/dev/null)" || { echo main; return; }
    base_real="$(cd "$BASE_DIR" 2>/dev/null && pwd -P)" || { echo main; return; }
    if [[ "$pwd_real" == "$base_real"/* ]]; then
        rel="${pwd_real#"$base_real"/}"
        echo "${rel%%/*}"
    else
        echo main
    fi
}

WORKTREE="${1:-$(default_worktree)}"

# Get list of available worktrees (directories in BASE_DIR)
# Uses fd if available, otherwise falls back to find
get_worktrees() {
    if command -v fd &>/dev/null; then
        fd --type d --max-depth 1 --base-directory "$BASE_DIR" . 2>/dev/null | sort
    else
        /usr/bin/find "$BASE_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null | sort
    fi
}

PROJECT_DIR="$BASE_DIR/$WORKTREE"

# Validate worktree exists
if [[ ! -d "$PROJECT_DIR" ]]; then
    echo "❌ Worktree '$WORKTREE' not found"
    echo "Available: $(get_worktrees | tr '\n' ' ')"
    exit 1
fi

cd "$PROJECT_DIR" || { echo "❌ Cannot find $PROJECT_DIR"; exit 1; }

ALLEGRO_DOMAIN="$ALLEGRO_DOMAIN" docker compose -f docker-compose.yaml \
    --profile sftp \
    --profile php8-work \
    down

echo "✅ IDL containers stopped ($WORKTREE) @ $ALLEGRO_DOMAIN"
