#!/bin/bash
# Read-only setup checks shared by install-status.sh and guided-setup.sh.
# Source this file. It has no side effects and every function only reads state.

SETUP_SECRETS_MARKER='# --- 1Password secrets (do not edit below) ---'

SETUP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Neovim's own copy of the lockfile. lazy.nvim rewrites it, so it is not stowed.
setup_nvim_lockfile() {
  printf '%s/nvim/lazy-lock.json' "${XDG_CONFIG_HOME:-$HOME/.config}"
}

# The committed lockfile. The restore and tools markers hash this file, not the local copy.
# NVIM_LOCKFILE_SOURCE overrides the path for tests.
setup_nvim_committed_lockfile() {
  printf '%s' "${NVIM_LOCKFILE_SOURCE:-$SETUP_ROOT/packages/nvim/.config/nvim/lazy-lock.json}"
}

setup_nvim_data() {
  printf '%s/nvim' "${XDG_DATA_HOME:-$HOME/.local/share}"
}

setup_nvim_lock_hash() {
  shasum -a 256 "$(setup_nvim_committed_lockfile)" | cut -d' ' -f1
}

# Neovim plugins match the committed lockfile and Neovim has its own copy of it. False when the
# local lockfile is missing or is still a link into the checkout (installs from before it was unstowed).
setup_check_nvim_plugins() {
  local data hash local_lock
  [ -f "$(setup_nvim_committed_lockfile)" ] || return 1
  local_lock="$(setup_nvim_lockfile)"
  [ -f "$local_lock" ] && [ ! -L "$local_lock" ] || return 1
  data="$(setup_nvim_data)"
  hash="$(setup_nvim_lock_hash)"
  [ -d "$data/lazy/lazy.nvim" ] && [ "$(cat "$data/.lazy-restore-hash" 2>/dev/null)" = "$hash" ]
}

# Neovim parsers and tools match the committed lockfile. False when it is absent.
setup_check_nvim_tools() {
  local data hash
  [ -f "$(setup_nvim_committed_lockfile)" ] || return 1
  data="$(setup_nvim_data)"
  hash="$(setup_nvim_lock_hash)"
  [ "$(cat "$data/.lazy-tools-hash" 2>/dev/null)" = "$hash" ]
}

setup_check_nvim() {
  setup_check_nvim_plugins && setup_check_nvim_tools
}

setup_check_op_signed_in() {
  command -v op >/dev/null 2>&1 && op account get >/dev/null 2>&1
}

setup_check_personal_secrets() {
  grep -qF "$SETUP_SECRETS_MARKER" "$HOME/.gitconfig.local" 2>/dev/null
}

setup_check_github_auth() {
  command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1
}

# mise is installed and has no declared tool versions left to install.
setup_check_mise_tools() {
  command -v mise >/dev/null 2>&1 || return 1
  [ -z "$(mise ls --missing 2>/dev/null)" ]
}

# Prints pending, complete, or none for the full Homebrew bundle.
setup_brew_state() {
  local dir="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
  if [ -f "$dir/full-brew-pending" ]; then
    echo pending
  elif [ -f "$dir/full-brew-complete" ]; then
    echo complete
  else
    echo none
  fi
}

setup_check_brew_complete() {
  [ "$(setup_brew_state)" = complete ]
}
