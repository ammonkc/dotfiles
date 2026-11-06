#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
target="$scratch/home"
mkdir -p "$target/.config" "$target/.local"
packages=()
for package in "$root"/packages/*; do
  [[ -d "$package" ]] && packages+=("${package##*/}")
done
stow --simulate --no-folding --dir="$root/packages" --target="$target" "${packages[@]}"
stow --no-folding --dir="$root/packages" --target="$target" "${packages[@]}"
find "$target" -type l | sort > "$scratch/before"
test -s "$scratch/before"
while IFS= read -r link; do
  test -e "$link" || { printf 'Broken managed link: %s\n' "$link" >&2; exit 1; }
done < "$scratch/before"
test -L "$target/.zshenv"
test -L "$target/.config/zsh/.zshrc"
test -L "$target/.local/bin/dotfiles"
python3 - "$target" "$root/packages" <<'PY'
import os
from pathlib import Path
import sys
target, packages = map(Path, sys.argv[1:])
for directory, _, files in os.walk(target):
    for name in files:
        link = Path(directory) / name
        if link.is_symlink():
            assert link.resolve().is_relative_to(packages.resolve()), f'Foreign link: {link}'
PY
test ! -e "$target/extensions"
test ! -e "$target/.config/tinycast/extensions"
stow --restow --no-folding --dir="$root/packages" --target="$target" "${packages[@]}"
find "$target" -type l | sort > "$scratch/after"
cmp "$scratch/before" "$scratch/after"
printf 'unmanaged\n' > "$target/keep"
stow --delete --no-folding --dir="$root/packages" --target="$target" "${packages[@]}"
test -z "$(find "$target" -type l -print)"
test "$(cat "$target/keep")" = unmanaged
test ! -e "$target/.zshenv"
printf 'All-package Stow lifecycle passed.\n'
