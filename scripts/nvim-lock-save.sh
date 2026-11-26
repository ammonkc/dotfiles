#!/usr/bin/env bash
# Copy Neovim's own lazy-lock.json into the development checkout so new plugin versions can be reviewed
# and committed by hand.
#
# lazy.nvim rewrites the lockfile whenever it installs or updates a plugin, so Neovim keeps its own copy
# (see `task nvim:restore`). This script writes only to the development checkout, never to the deployed
# one, and never commits.
set -euo pipefail
export GIT_OPTIONAL_LOCKS=0

home=${DOTFILES_TARGET_HOME:-$HOME}
config=${XDG_CONFIG_HOME:-$home/.config}
local_lock="$config/nvim/lazy-lock.json"
deployed=${DOTFILES_DEPLOY_DIR:-$home/.dotfiles}
source_dir=${DOTFILES_SOURCE_DIR:-$home/Developer/repos/ammonkc/dotfiles}
relative=packages/nvim/.config/nvim/lazy-lock.json

if [[ -L "$local_lock" || ! -f "$local_lock" ]]; then
  printf 'Neovim has no lockfile copy of its own at %s; run task nvim:restore first.\n' "$local_lock" >&2
  exit 1
fi
if ! git -C "$source_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  printf 'Development checkout missing: %s (set DOTFILES_SOURCE_DIR)\n' "$source_dir" >&2
  exit 1
fi
# Writing here would dirty the deployed checkout, which is what keeping the lockfile unstowed avoids.
if [[ -d "$deployed" && "$(cd "$source_dir" && pwd -P)" == "$(cd "$deployed" && pwd -P)" ]]; then
  printf 'Refusing to write into the deployed checkout (%s); point DOTFILES_SOURCE_DIR at the development checkout.\n' "$deployed" >&2
  exit 1
fi

destination="$source_dir/$relative"
if [[ -f "$destination" ]] && cmp -s "$local_lock" "$destination"; then
  printf 'Neovim lockfile already matches the committed one in %s.\n' "$source_dir"
  exit 0
fi

mkdir -p "$(dirname "$destination")"
cp "$local_lock" "$destination"
printf 'Copied %s\n    to %s\n\n' "$local_lock" "$destination"
git -C "$source_dir" diff --stat -- "$relative"
printf '\nReview and commit it yourself; nothing was committed.\n'
