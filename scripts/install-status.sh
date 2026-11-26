#!/bin/bash
# Read-only, rerunnable checklist for a fresh machine.
set -u
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$root/scripts/setup-checks.sh"
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
if [ -f "$(setup_nvim_committed_lockfile)" ]; then
  check 'Neovim plugins restored' setup_check_nvim_plugins 'run task nvim:restore'
  check 'Neovim parsers and tools installed' setup_check_nvim_tools 'run task nvim:restore'
fi
if [ "$(uname -s)" = Darwin ]; then
  case "$(setup_brew_state)" in
    pending)
      printf '○ Full Homebrew bundle incomplete — run dotfiles brew:retry\n'
      pending=$((pending + 1))
      ;;
    complete) printf '✓ Full Homebrew bundle\n' ;;
    *) printf '○ Full Homebrew bundle optional — run DOTFILES_PROFILE=full dotfiles install\n' ;;
  esac
  check '1Password signed in' setup_check_op_signed_in 'sign in with op signin'
  check 'Personal secrets installed' setup_check_personal_secrets 'run task system:post-install'
fi
if [ "$pending" -eq 0 ]; then
  printf 'All checked setup steps are complete.\n'
else
  printf '%s setup step(s) remain. Rerun this command after completing them.\n' "$pending"
fi
