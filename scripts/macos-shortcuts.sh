#!/usr/bin/env bash
# Optional: put the launcher on Cmd+Space by moving Spotlight and input source switching away.
#
#   Tinycast toggle (hotkey.togglePalette)  Cmd+Space
#   Spotlight (symbolic hotkey 64)          Ctrl+Space
#   Previous input source (symbolic 60)     Ctrl+Shift+Space
#
# macOS's default for input source switching is Ctrl+Space, so it must move first or it would
# clash with Spotlight. Both formats are undocumented: the Tinycast value is a JSON string in
# its preferences, and the symbolic hotkey entries are the private ones System Settings writes.
# Usage: macos-shortcuts.sh [--dry-run]
set -euo pipefail

dry_run=0
case "${1:-}" in
  '') ;;
  --dry-run) dry_run=1 ;;
  *) echo "Usage: ${0##*/} [--dry-run]" >&2; exit 2 ;;
esac

# Carbon modifier bits (Tinycast) and Cocoa modifier flags (symbolic hotkeys).
tinycast_cmd=256
cocoa_control=262144
cocoa_shift=131072
space_key=49
space_char=32

hotkey_xml() {
  printf '<dict><key>enabled</key><true/><key>value</key><dict><key>parameters</key><array>'
  printf '<integer>%s</integer><integer>%s</integer><integer>%s</integer>' "$space_char" "$space_key" "$1"
  printf '</array><key>type</key><string>standard</string></dict></dict>'
}

run() {
  # Single quote anything with shell metacharacters so the preview can be pasted back.
  printf ' '
  for arg in "$@"; do
    case "$arg" in
      *[!A-Za-z0-9._:/=-]*) printf " '%s'" "$arg" ;;
      *) printf ' %s' "$arg" ;;
    esac
  done
  printf '\n'
  if [ "$dry_run" -eq 0 ]; then
    "$@"
  fi
}

if [ "$dry_run" -eq 1 ]; then
  printf 'Dry run: these commands would be run.\n'
else
  printf 'Setting keyboard shortcuts...\n'
fi

printf 'Input source switching: Ctrl+Shift+Space\n'
run defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 60 \
  "$(hotkey_xml $((cocoa_control + cocoa_shift)))"

printf 'Spotlight: Ctrl+Space\n'
run defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 \
  "$(hotkey_xml "$cocoa_control")"

printf 'Tinycast toggle: Cmd+Space\n'
run defaults write com.abueammar.tinycast hotkey.togglePalette -string \
  "{\"combo\":{\"_0\":{\"carbonModifiers\":$tinycast_cmd,\"carbonKeyCode\":$space_key}}}"

if [ "$dry_run" -eq 1 ]; then
  exit 0
fi

if pgrep -x Tinycast >/dev/null 2>&1; then
  printf 'Tinycast is running and may overwrite this on exit. Quit and reopen it.\n' >&2
fi

# Best effort: apply the symbolic hotkeys without logging out. The helper is private and may
# be missing on a new macOS release, in which case a logout applies them.
activate="${DOTFILES_ACTIVATE_SETTINGS:-/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings}"
if [ -x "$activate" ] && "$activate" -u >/dev/null 2>&1; then
  printf 'Applied. If Spotlight or Tinycast still use the old shortcut, log out and back in.\n'
else
  printf 'Log out and back in for the Spotlight and input source shortcuts to take effect.\n'
fi
