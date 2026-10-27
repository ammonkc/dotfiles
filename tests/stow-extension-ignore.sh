#!/bin/bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
target="$(mktemp -d)"
trap 'rm -rf "$target"' EXIT

stow --no-folding --dir="$root/packages" --target="$target" raycast tinycast

if [[ -e "$target/extensions" || -L "$target/extensions" ]]; then
    echo 'Raycast extension source was stowed into ~/extensions' >&2
    exit 1
fi
if [[ -e "$target/.config/tinycast/extensions" || -L "$target/.config/tinycast/extensions" ]]; then
    echo 'Tinycast extension source was stowed into ~/.config/tinycast/extensions' >&2
    exit 1
fi
test -L "$target/.config/raycast/script-commands/idl-up.sh"
test -L "$target/.config/tinycast/script-commands/idl-up.sh"

printf 'Extension source Stow exclusions passed.\n'
