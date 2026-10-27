#!/usr/bin/env bash
# Optional terminal menu. Each action delegates to an existing Task command.
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ ! -t 0 || ! -t 1 ]]; then
  echo 'Guided setup needs an interactive terminal. Run individual dotfiles tasks for unattended setup.' >&2
  exit 1
fi
if ! command -v gum >/dev/null 2>&1; then
  echo 'Gum is required for guided setup. Install it with: brew install gum' >&2
  exit 1
fi

run_task() {
  if ! task -d "$repo_dir" "$@"; then
    printf '\nThat step did not complete. Review the error above, then retry it from the menu.\n' >&2
  fi
}

printf 'Dotfiles guided setup\n\n'
run_task system:status

while true; do
  choice="$(gum choose --header 'Choose a setup step' \
    'Show setup status' \
    'Finish personal setup' \
    'Set up work accounts' \
    'Link 1Password SSH agent' \
    'Use SSH for GitHub URLs' \
    'Preview macOS preferences' \
    'Apply macOS preferences' \
    'Install or retry optional apps' \
    'Quit')" || break

  case "$choice" in
    'Show setup status') run_task system:status ;;
    'Finish personal setup') run_task system:post-install ;;
    'Set up work accounts') run_task system:work-setup ;;
    'Link 1Password SSH agent')
      printf 'Enable the SSH agent in 1Password > Settings > Developer first.\n'
      run_task mac:op:setup
      ;;
    'Use SSH for GitHub URLs')
      if gum confirm 'Rewrite GitHub HTTPS URLs to SSH? Ensure SSH authentication works first.'; then
        run_task mac:github:force_ssh
      fi
      ;;
    'Preview macOS preferences') run_task mac:preview:defaults ;;
    'Apply macOS preferences')
      if gum confirm 'Apply macOS preferences and restart affected applications?'; then
        run_task mac:set:defaults
      fi
      ;;
    'Install or retry optional apps') run_task brew:retry ;;
    'Quit') break ;;
  esac
  printf '\n'
done
