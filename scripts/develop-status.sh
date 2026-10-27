#!/usr/bin/env bash
# Report local repository and worktree changes without fetching or pulling.
set -euo pipefail
export GIT_OPTIONAL_LOCKS=0

dev_dir=${1:-$HOME/Developer}
found=0
dirty=0
for area in code repos worktrees; do
  [[ -d "$dev_dir/$area" ]] || continue
  while IFS= read -r git_marker; do
    repo=${git_marker%/.git}
    [[ -d "$repo" ]] || continue
    found=$((found + 1))
    changes=$(git -C "$repo" status --porcelain --untracked-files=normal)
    if [[ -n "$changes" ]]; then
      dirty=$((dirty + 1))
      printf '\n%s (%s)\n' "$repo" "$(git -C "$repo" branch --show-current)"
      git -C "$repo" status --short
    fi
  done < <(find "$dev_dir/$area" \
    \( -name node_modules -o -name vendor -o -name .venv -o -name target -o -name .cache \) -prune -o \
    -name .git -print -prune)
done
if ((dirty == 1)); then
  printf '\nChecked %s repositories and worktrees; 1 has local changes.\n' "$found"
else
  printf '\nChecked %s repositories and worktrees; %s have local changes.\n' "$found" "$dirty"
fi
