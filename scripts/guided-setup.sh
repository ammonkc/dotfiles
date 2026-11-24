#!/usr/bin/env bash
# Optional terminal menu. Each action delegates to an existing Task command.
# Steps that have a read-only check show a marker, and the cursor starts on the
# first pending one. Source this file to use its functions in tests.
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/setup-checks.sh
. "$repo_dir/scripts/setup-checks.sh"

# Menu order follows dependencies: GitHub login comes before the personal setup
# that syncs SSH keys, and Neovim and mise come after the dotfiles are stowed.
STEP_IDS='status github personal work op-agent ssh-urls nvim mise brew preview-defaults apply-defaults shortcuts tinycast verify quit'

# Keep in sync with the install links in README.md.
TINYCAST_EXTENSION_URLS='https://github.com/ammonkc/tinycast-extensions/tree/main/developer-utilities
https://github.com/ammonkc/tinycast-extensions/tree/main/idl-docker
https://github.com/ammonkc/tinycast-extensions/tree/main/obsidian-prompts
https://github.com/ammonkc/tinycast-extensions/tree/main/window-edges'

run_task() {
  if ! task -d "$repo_dir" "$@"; then
    printf '\nThat step did not complete. Review the error above, then retry it from the menu.\n' >&2
  fi
}

step_label() {
  case "$1" in
    status) echo 'Show setup status' ;;
    github) echo 'Sign in to GitHub and test SSH' ;;
    personal) echo 'Finish personal setup' ;;
    work) echo 'Set up work accounts' ;;
    op-agent) echo 'Link 1Password SSH agent' ;;
    ssh-urls) echo 'Use SSH for GitHub URLs' ;;
    nvim) echo 'Restore Neovim plugins and tools' ;;
    mise) echo 'Install mise tools' ;;
    brew) echo 'Install or retry optional apps' ;;
    preview-defaults) echo 'Preview macOS preferences' ;;
    apply-defaults) echo 'Apply macOS preferences' ;;
    shortcuts) echo 'Move Spotlight so Tinycast can use Cmd+Space' ;;
    tinycast) echo 'Show Tinycast extension install links' ;;
    verify) echo 'Verify the installation' ;;
    quit) echo 'Quit' ;;
    *) return 1 ;;
  esac
}

# Exit status: 0 done, 1 pending, 2 no check exists for this step.
step_state() {
  local check
  case "$1" in
    github) check=setup_check_github_auth ;;
    personal) check=setup_check_personal_secrets ;;
    nvim) check=setup_check_nvim ;;
    mise) check=setup_check_mise_tools ;;
    brew) check=setup_check_brew_complete ;;
    *) return 2 ;;
  esac
  # Collapse any nonzero status (grep returns 2 for a missing file) to pending.
  if "$check"; then return 0; else return 1; fi
}

menu_line() {
  local state=0
  step_state "$1" || state=$?
  case "$state" in
    0) printf '✓ %s\n' "$(step_label "$1")" ;;
    1) printf '○ %s\n' "$(step_label "$1")" ;;
    *) printf '· %s\n' "$(step_label "$1")" ;;
  esac
}

# Prints the first step whose check is pending, or nothing when none is.
next_pending_step() {
  local id state
  for id in $STEP_IDS; do
    state=0
    step_state "$id" || state=$?
    if [[ "$state" -eq 1 ]]; then
      echo "$id"
      return 0
    fi
  done
}

# Prints the step id for a menu line, or nothing when no step matches.
step_for_line() {
  local id line="$1"
  line="${line#"${line%%[![:space:]]*}"}"
  for id in $STEP_IDS; do
    if [[ "$(menu_line "$id")" == "$line" ]]; then
      echo "$id"
      return 0
    fi
  done
}

run_step() {
  case "$1" in
    status) run_task system:status ;;
    github)
      run_task github:auth
      run_task github:ssh:test
      printf 'Syncing SSH keys to GitHub needs the admin:public_key and admin:ssh_signing_key scopes.\n'
      printf 'If a later step reports missing scopes, run: gh auth refresh -s admin:public_key,admin:ssh_signing_key\n'
      ;;
    personal) run_task system:post-install ;;
    work) run_task system:work-setup ;;
    op-agent)
      printf 'Enable the SSH agent in 1Password > Settings > Developer first.\n'
      run_task mac:op:setup
      ;;
    ssh-urls)
      if gum confirm 'Rewrite GitHub HTTPS URLs to SSH? Ensure SSH authentication works first.'; then
        run_task mac:github:force_ssh
      fi
      ;;
    nvim) run_task nvim:restore ;;
    mise) run_task mise:install ;;
    brew) run_task brew:retry ;;
    preview-defaults) run_task mac:preview:defaults ;;
    apply-defaults)
      if gum confirm 'Apply macOS preferences and restart affected applications?'; then
        run_task mac:set:defaults
      fi
      ;;
    shortcuts)
      run_task mac:preview:shortcuts
      if gum confirm 'Apply these keyboard shortcuts? Quit Tinycast first.'; then
        run_task mac:set:shortcuts
      fi
      ;;
    tinycast)
      printf 'In Tinycast, open Settings > Extensions > Install New > Install from GitHub and paste a link.\n'
      printf 'Installing needs Node.js 22.22.2 or newer and a package manager on the PATH.\n\n'
      printf '%s\n' "$TINYCAST_EXTENSION_URLS"
      ;;
    verify) run_task system:check ;;
    *) return 1 ;;
  esac
}

main() {
  if [[ ! -t 0 || ! -t 1 ]]; then
    echo 'Guided setup needs an interactive terminal. Run individual dotfiles tasks for unattended setup.' >&2
    exit 1
  fi
  if ! command -v gum >/dev/null 2>&1; then
    echo 'Gum is required for guided setup. Install it with: brew install gum' >&2
    exit 1
  fi

  local id choice next lines selected_args
  printf 'Dotfiles guided setup\n\n'
  run_task system:status

  while true; do
    lines=()
    for id in $STEP_IDS; do
      lines+=("$(menu_line "$id")")
    done
    next="$(next_pending_step)"
    selected_args=()
    if [[ -n "$next" ]]; then
      selected_args=(--selected "$(menu_line "$next")")
    fi
    choice="$(gum choose --header 'Choose a setup step (✓ done, ○ pending)' \
      --height "$((${#lines[@]} + 2))" \
      ${selected_args[@]+"${selected_args[@]}"} \
      "${lines[@]}")" || break
    id="$(step_for_line "$choice")"
    [[ -n "$id" && "$id" != quit ]] || break
    run_step "$id"
    printf '\n'
  done
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
