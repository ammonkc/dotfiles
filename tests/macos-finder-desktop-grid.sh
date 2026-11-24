#!/usr/bin/env bash
# macos.sh sets the Desktop icon grid with PlistBuddy and groups the Desktop by Kind with
# defaults. Writing DesktopViewSettings as a whole dict in between replaces IconViewSettings, which
# silently drops the grid settings and makes the later gridSpacing write fail. Replay the real
# Desktop lines from macos.sh against a scratch plist with the real tools and check the result.
set -euo pipefail
if [ ! -x /usr/bin/defaults ] || [ ! -x /usr/libexec/PlistBuddy ]; then
  printf 'Desktop grid checks skipped: defaults and PlistBuddy are macOS tools.\n'
  exit 0
fi
root="$(cd "$(dirname "$0")/.." && pwd)"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
plist="$scratch/com.apple.finder.plist"

# A Finder preferences file that already has desktop icon view settings, as a used account does.
/usr/libexec/PlistBuddy -c 'Add :DesktopViewSettings dict' \
  -c 'Add :DesktopViewSettings:IconViewSettings dict' \
  -c 'Add :DesktopViewSettings:IconViewSettings:arrangeBy string none' \
  -c 'Add :DesktopViewSettings:IconViewSettings:gridSpacing integer 54' "$plist" >/dev/null 2>&1

lines="$(grep -n 'DesktopViewSettings' "$root/scripts/macos.sh" | grep -v '^[0-9]*:#' | cut -d: -f2-)"
test -n "$lines"
run_optional() { "$@"; }
defaults() {
  args=()
  for arg in "$@"; do
    [ "$arg" = com.apple.finder ] && args+=("$plist") || args+=("$arg")
  done
  /usr/bin/defaults "${args[@]}"
}
while IFS= read -r line; do
  eval "${line//\~\/Library\/Preferences\/com.apple.finder.plist/$plist}"
done <<< "$lines"

value() { /usr/libexec/PlistBuddy -c "Print :DesktopViewSettings:$1" "$plist"; }
test "$(value IconViewSettings:arrangeBy)" = grid
test "$(value IconViewSettings:gridSpacing)" = 100
test "$(value GroupBy)" = Kind
printf 'Desktop icon grid checks passed.\n'
