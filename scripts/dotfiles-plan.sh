#!/usr/bin/env bash
# Preview the same Stow operation used by dot:install, without moving conflicts.
set -euo pipefail

checkout=${1:?Usage: dotfiles-plan.sh CHECKOUT [TARGET]}
target=${2:-$HOME}
packages="$checkout/packages"
[[ -d "$packages" && -d "$target" ]] || {
  printf 'Missing packages directory or target: %s, %s\n' "$packages" "$target" >&2
  exit 1
}
command -v stow >/dev/null || { printf 'stow is required\n' >&2; exit 1; }

printf 'Stow preview: %s → %s\n' "$packages" "$target"
failed=0
for package_path in "$packages"/*; do
  [[ -d "$package_path" ]] || continue
  package=${package_path##*/}
  printf '\n[%s]\n' "$package"
  if ! stow --simulate --verbose=1 --restow --no-folding \
      --dir="$packages" --target="$target" "$package"; then
    failed=1
  fi
done
if ((failed)); then
  printf '\nConflicts found. dot:install would back up eligible conflicting files before Stow.\n' >&2
  exit 1
fi
printf '\nPreview complete. No files changed.\n'
