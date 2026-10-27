#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/bin" "$scratch/home/Desktop"
export TEST_LOG="$scratch/commands.log"

cat > "$scratch/bin/defaults" <<'EOF'
#!/usr/bin/env bash
printf 'defaults %s\n' "$*" >> "$TEST_LOG"
if [[ "$1" == read ]]; then
  [[ "${FAIL_BACKUP:-}" != 1 ]] || exit 1
  printf 'saved defaults\n'
elif [[ "$*" == *'com.apple.Safari UniversalSearchEnabled'* ]]; then
  printf 'Safari setting unavailable\n' >&2
  exit 1
fi
EOF
cat > "$scratch/bin/pmset" <<'EOF'
#!/usr/bin/env bash
printf 'pmset %s\n' "$*" >> "$TEST_LOG"
if [[ "$*" == '-g custom' ]]; then
  [[ "${FAIL_POWER_BACKUP:-}" != 1 ]] || exit 1
  printf 'saved power settings\n'
elif [[ "$*" == '-a lidwake 1' ]]; then
  printf 'unsupported power setting\n' >&2
  exit 1
fi
EOF
cat > "$scratch/bin/sudo" <<'EOF'
#!/usr/bin/env bash
"$@"
EOF
cat > "$scratch/bin/networksetup" <<'EOF'
#!/usr/bin/env bash
printf 'networksetup %s\n' "$*" >> "$TEST_LOG"
EOF
for command_name in osascript killall chflags xattr systemsetup; do
  cat > "$scratch/bin/$command_name" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
done
chmod +x "$scratch/bin"/*

export HOME="$scratch/home"
export PATH="$scratch/bin:$PATH"
if FAIL_BACKUP=1 bash "$root/scripts/macos.sh" >"$scratch/failed.out" 2>&1; then
  printf 'Preferences continued after a snapshot failure.\n' >&2
  exit 1
fi
! grep -Eq '^defaults write|^pmset -[abc] ' "$TEST_LOG"
! find "$HOME/Desktop" -type f | grep -q .

: > "$TEST_LOG"
if FAIL_POWER_BACKUP=1 bash "$root/scripts/macos.sh" >"$scratch/failed-power.out" 2>&1; then
  printf 'Preferences continued after a power snapshot failure.\n' >&2
  exit 1
fi
! grep -Eq '^defaults write|^pmset -[abc] ' "$TEST_LOG"
! find "$HOME/Desktop" -type f | grep -q .

: > "$TEST_LOG"
bash "$root/scripts/macos.sh" >"$scratch/applied.out" 2>&1
test "$(find "$HOME/Desktop" -type f | wc -l | tr -d ' ')" -eq 2
grep -q 'Could not apply: sudo pmset -a lidwake 1' "$scratch/applied.out"
grep -q 'Could not apply: defaults write com.apple.Safari UniversalSearchEnabled' "$scratch/applied.out"
grep -q 'optional settings could not be applied' "$scratch/applied.out"
! grep -q 'networksetup\|LSQuarantine' "$TEST_LOG"

bash "$root/scripts/macos-preview.sh" "$root/scripts/macos.sh" "$scratch/preview.md" >/dev/null 2>&1
grep -q 'sudo pmset -a hibernatemode 0' "$scratch/preview.md"
! grep -Eq 'setdhcp|LSQuarantine|Save to disk by default' "$scratch/preview.md"

printf 'macOS preferences safety checks passed.\n'
