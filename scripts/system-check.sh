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
# The markers hash the committed lockfile; Neovim keeps its own rewritable copy in its config dir.
lock="${NVIM_LOCKFILE_SOURCE:-$checkout/packages/nvim/.config/nvim/lazy-lock.json}"
local_lock="$config/nvim/lazy-lock.json"
if [[ -f "$lock" ]]; then
  hash=$(shasum -a 256 "$lock" | cut -d' ' -f1)
  # A link into the checkout (installs from before the lockfile was unstowed) lets lazy.nvim dirty it.
  if [[ -L "$local_lock" ]]; then
    printf '✗ Neovim lockfile is still a link into the checkout; run nvim:restore\n' >&2
    failed=1
  fi
  for marker in .lazy-restore-hash .lazy-tools-hash; do
    if [[ -f "$data/nvim/$marker" && "$(cat "$data/nvim/$marker")" == "$hash" ]]; then
      printf '✓ Neovim %s\n' "$marker"
    else
      printf '✗ Neovim %s is missing or stale; run nvim:restore\n' "$marker" >&2
      failed=1
    fi
  done
  # pint is installed by Mason only when Composer exists (see lua/plugins/mason.lua).
  if command -v "${COMPOSER_BIN:-composer}" >/dev/null 2>&1 && [[ ! -e "$data/nvim/mason/bin/pint" ]]; then
    printf '✗ Composer is installed but Mason pint is missing; run nvim:restore\n' >&2
    failed=1
  fi
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
