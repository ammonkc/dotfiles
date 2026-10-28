#!/bin/bash
# Read-only, rerunnable checklist for a fresh machine.
set -u
pending=0
check() {
  if eval "$2" >/dev/null 2>&1; then
    printf '✓ %s\n' "$1"
  else
    printf '○ %s — %s\n' "$1" "$3"
    pending=$((pending + 1))
  fi
}
check 'Task available' 'command -v task' 'run bin/install'
check 'Dotfiles stowed' "test -L \"\$HOME/.config/nvim\" -o -L \"\$HOME/.config/nvim/init.lua\"" 'run task dot:install'
check 'mise available' 'command -v mise' 'run task mise:install after packages are installed'
lockfile="${XDG_CONFIG_HOME:-$HOME/.config}/nvim/lazy-lock.json"
nvim_data="${XDG_DATA_HOME:-$HOME/.local/share}/nvim"
if [ -f "$lockfile" ]; then
  lock_hash="$(shasum -a 256 "$lockfile" | cut -d' ' -f1)"
  check 'Neovim plugins restored' "test -d \"$nvim_data/lazy/lazy.nvim\" && test \"\$(cat \"$nvim_data/.lazy-restore-hash\" 2>/dev/null)\" = \"$lock_hash\"" 'run task nvim:restore'
  check 'Neovim parsers and tools installed' "test \"\$(cat \"$nvim_data/.lazy-tools-hash\" 2>/dev/null)\" = \"$lock_hash\"" 'run task nvim:restore'
fi
if [ "$(uname -s)" = Darwin ]; then
  brew_state="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
  if [ -f "$brew_state/full-brew-pending" ]; then
    printf '○ Full Homebrew bundle incomplete — run dotfiles brew:retry\n'
    pending=$((pending + 1))
  elif [ -f "$brew_state/full-brew-complete" ]; then
    printf '✓ Full Homebrew bundle\n'
  else
    printf '○ Full Homebrew bundle optional — run DOTFILES_PROFILE=full dotfiles install\n'
  fi
  check '1Password signed in' 'command -v op && op account get >/dev/null' 'sign in with op signin'
  check 'Personal secrets installed' "grep -qF '# --- 1Password secrets (do not edit below) ---' \"\$HOME/.gitconfig.local\"" 'run task system:post-install'
fi
if [ "$pending" -eq 0 ]; then
  printf 'All checked setup steps are complete.\n'
else
  printf '%s setup step(s) remain. Rerun this command after completing them.\n' "$pending"
fi
