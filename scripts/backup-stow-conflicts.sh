#!/usr/bin/env bash
# Fail closed on unknown Stow diagnostics; never move foreign symlinks.
set -euo pipefail
packages=${1:?Usage: backup-stow-conflicts.sh PACKAGES PACKAGE TARGET BACKUP}
package=${2:?}
target=${3:?}
backup=${4:?}
if output=$(LC_ALL=C stow --simulate --restow --no-folding --dir="$packages" --target="$target" "$package" 2>&1); then
  exit 0
fi
conflicts=()
while IFS= read -r line; do
  case "$line" in
    *'cannot stow '*' over existing target '*' since '*)
      relative=${line#* over existing target }
      relative=${relative% since *}
      ;;
    *'existing target is neither a link nor a directory: '*)
      relative=${line#*existing target is neither a link nor a directory: }
      ;;
    *'existing target is not owned by stow: '*)
      relative=${line#*existing target is not owned by stow: }
      ;;
    '  * '*) printf '%s\n' "$output" >&2; exit 1 ;;
    *) continue ;;
  esac
  case "/$relative/" in *'/../'*|*'/./'*|*'//'*) printf 'Unsafe conflict path: %s\n' "$relative" >&2; exit 1 ;; esac
  if [[ -L "$target/$relative" || ! -e "$target/$relative" ]]; then
    printf 'Cannot back up foreign link or missing target: %s\n' "$relative" >&2
    exit 1
  fi
  # Refuse paths below a symlink, too: backups must stay within the target.
  parent=$(dirname "$relative")
  while [[ "$parent" != . ]]; do
    [[ ! -L "$target/$parent" ]] || { printf 'Symlink parent: %s\n' "$parent" >&2; exit 1; }
    parent=$(dirname "$parent")
  done
  [[ ! -e "$backup/$relative" && ! -L "$backup/$relative" ]] || { printf 'Backup already exists: %s\n' "$relative" >&2; exit 1; }
  conflicts+=("$relative")
done <<< "$output"
if [[ ${#conflicts[@]} -eq 0 ]]; then
  printf '%s\n' "$output" >&2
  exit 1
fi
for relative in "${conflicts[@]}"; do
  printf 'Backing up %s/%s\n' "$package" "$relative"
  mkdir -p "$backup/$(dirname "$relative")"
  mv "$target/$relative" "$backup/$relative"
done
