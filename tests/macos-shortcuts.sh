#!/usr/bin/env bash
# The optional shortcuts script moves Spotlight and input source switching away from
# Cmd+Space and gives it to Tinycast. Commands are stubbed so nothing touches real preferences;
# on macOS the same arguments are replayed into scratch plists with the real defaults tool.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/bin" "$scratch/plists"
export TEST_LOG="$scratch/defaults.log"
export REPLAY_DIR="$scratch/plists"

cat > "$scratch/bin/defaults" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$TEST_LOG"
# Replay into a scratch plist (never the real domain) when the real tool exists.
if [ -x /usr/bin/defaults ] && [ "$1" = write ]; then
  domain="$2"
  shift 2
  /usr/bin/defaults write "$REPLAY_DIR/$domain.plist" "$@"
fi
STUB
cat > "$scratch/bin/pgrep" <<'STUB'
#!/usr/bin/env bash
[ "${TINYCAST_RUNNING:-0}" = 1 ]
STUB
cat > "$scratch/activate" <<'STUB'
#!/usr/bin/env bash
printf 'activate %s\n' "$*" >> "$TEST_LOG"
[ "${ACTIVATE_FAILS:-0}" != 1 ]
STUB
chmod +x "$scratch/bin/defaults" "$scratch/bin/pgrep" "$scratch/activate"
export PATH="$scratch/bin:$PATH"
export DOTFILES_ACTIVATE_SETTINGS="$scratch/activate"
script="$root/scripts/macos-shortcuts.sh"

# A dry run shows every change and writes nothing.
bash "$script" --dry-run > "$scratch/dry.out"
test ! -e "$TEST_LOG"
grep -q 'Spotlight: Ctrl+Space' "$scratch/dry.out"
grep -q 'Input source switching: Ctrl+Shift+Space' "$scratch/dry.out"
grep -q 'Tinycast toggle: Cmd+Space' "$scratch/dry.out"
grep -q "hotkey.togglePalette" "$scratch/dry.out"

# An unknown argument is rejected.
if bash "$script" --apply >/dev/null 2>&1; then
  echo 'Shortcuts script accepted an unknown argument' >&2
  exit 1
fi

# A real run writes all three, with input switching moved before Spotlight takes Ctrl+Space.
bash "$script" > "$scratch/run.out" 2> "$scratch/run.err"
test "$(grep -c '^write ' "$TEST_LOG")" -eq 3
input_line=$(grep -n 'AppleSymbolicHotKeys -dict-add 60 ' "$TEST_LOG" | cut -d: -f1)
spotlight_line=$(grep -n 'AppleSymbolicHotKeys -dict-add 64 ' "$TEST_LOG" | cut -d: -f1)
test -n "$input_line" && test -n "$spotlight_line"
test "$input_line" -lt "$spotlight_line"
grep -qF 'write com.abueammar.tinycast hotkey.togglePalette -string {"combo":{"_0":{"carbonModifiers":256,"carbonKeyCode":49}}}' "$TEST_LOG"
grep -qx 'activate -u' "$TEST_LOG"
test ! -s "$scratch/run.err"

# Tinycast running is a warning, not a failure. A failing activate helper falls back to a logout notice.
: > "$TEST_LOG"
TINYCAST_RUNNING=1 ACTIVATE_FAILS=1 bash "$script" > "$scratch/run2.out" 2> "$scratch/run2.err"
grep -q 'Tinycast is running' "$scratch/run2.err"
grep -q 'Log out and back in' "$scratch/run2.out"

# On macOS, the real defaults tool must accept the arguments and store the intended values.
if [ -x /usr/bin/defaults ] && [ -x /usr/libexec/PlistBuddy ]; then
  hotkeys="$REPLAY_DIR/com.apple.symbolichotkeys.plist"
  value() { /usr/libexec/PlistBuddy -c "Print :AppleSymbolicHotKeys:$1" "$hotkeys" | tr -s ' \n' ' '; }
  for key in 60 64; do
    value "$key" | grep -q 'enabled = true'
    value "$key" | grep -q 'type = standard'
  done
  value 64 | grep -q 'Array { 32 49 262144 }'
  value 60 | grep -q 'Array { 32 49 393216 }'
  toggle="$(/usr/bin/defaults read "$REPLAY_DIR/com.abueammar.tinycast.plist" hotkey.togglePalette)"
  python3 -I -c 'import json,sys; c=json.loads(sys.argv[1])["combo"]["_0"]; assert c=={"carbonModifiers":256,"carbonKeyCode":49}, c' "$toggle"
fi
printf 'Keyboard shortcut checks passed.\n'
