#!/bin/bash
# lazy.nvim rewrites its lockfile whenever it installs or updates a plugin. The nvim package must not
# link the file into ~/.config/nvim: through a link, those writes land in the deployed checkout and
# leave it with uncommitted changes. `task nvim:restore` copies the committed lockfile there instead.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
target="$(mktemp -d)"
trap 'rm -rf "$target"' EXIT

stow --no-folding --dir="$root/packages" --target="$target" nvim
test -L "$target/.config/nvim/init.lua"
if [[ -e "$target/.config/nvim/lazy-lock.json" || -L "$target/.config/nvim/lazy-lock.json" ]]; then
  echo 'lazy-lock.json was stowed into ~/.config/nvim' >&2
  exit 1
fi
# The committed file stays in the package, because it is what seeds Neovim's own copy.
test -s "$root/packages/nvim/.config/nvim/lazy-lock.json"

printf 'The nvim lockfile is committed but not stowed.\n'
