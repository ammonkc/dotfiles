#!/usr/bin/env bash
# Strict, read-only check for a completed core installation.
set -euo pipefail

checkout=${1:?Usage: system-check.sh CHECKOUT}
home=${DOTFILES_TARGET_HOME:-$HOME}
failed=0
for tool in git stow task mise nvim ya; do
  if command -v "$tool" >/dev/null 2>&1; then
    printf '✓ %s\n' "$tool"
  else
    printf '✗ Missing core tool: %s\n' "$tool" >&2
    failed=1
  fi
done

if ! bash "$checkout/scripts/dotfiles-verify.sh" "$checkout" --links-only; then
  failed=1
fi

config=${XDG_CONFIG_HOME:-$home/.config}
data=${XDG_DATA_HOME:-$home/.local/share}
lock="$config/nvim/lazy-lock.json"
if [[ -f "$lock" ]]; then
  hash=$(shasum -a 256 "$lock" | cut -d' ' -f1)
  for marker in .lazy-restore-hash .lazy-tools-hash; do
    if [[ -f "$data/nvim/$marker" && "$(cat "$data/nvim/$marker")" == "$hash" ]]; then
      printf '✓ Neovim %s\n' "$marker"
    else
      printf '✗ Neovim %s is missing or stale; run nvim:restore\n' "$marker" >&2
      failed=1
    fi
  done
else
  printf '✗ Neovim lockfile missing: %s\n' "$lock" >&2
  failed=1
fi

if [[ "$(uname -s)" == Darwin ]] && [[ -f "${XDG_STATE_HOME:-$home/.local/state}/dotfiles/full-brew-pending" ]]; then
  printf '✗ Full Homebrew bundle is pending; run brew:retry\n' >&2
  failed=1
fi

if ((failed)); then
  printf 'System check failed.\n' >&2
  exit 1
fi
printf 'Core installation checks passed.\n'
