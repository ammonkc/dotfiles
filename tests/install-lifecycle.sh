#!/usr/bin/env bash
# Exercise the real Taskfiles against a disposable deployed checkout and home.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
fixture="$scratch/deployed"
mkdir -p "$fixture/packages/demo/.config" "$fixture/packages/ssh/.config/ssh" "$fixture/scripts" "$scratch/home/.config" "$scratch/home/.ssh"
cp -R "$root/taskfiles" "$fixture/taskfiles"
cp "$root/taskfile.dist.yml" "$fixture/"
cp "$root/scripts/backup-stow-conflicts.sh" "$fixture/scripts/"
printf 'managed\n' > "$fixture/packages/demo/.config/example with spaces"
printf 'template\n' > "$fixture/packages/demo/env.local"
printf 'ssh template\n' > "$fixture/packages/ssh/.config/ssh/ssh_config_local"
printf 'original\n' > "$scratch/home/.config/example with spaces"
chmod 640 "$scratch/home/.config/example with spaces"
printf 'personal\n' > "$scratch/home/.env.local"
printf 'personal ssh\n' > "$scratch/home/.ssh/config"

# Only child processes get a fixture HOME; the invoking user's HOME is untouched.
run_task() {
  env HOME="$scratch/home" XDG_DATA_HOME="$scratch/data" XDG_CONFIG_HOME="$scratch/home/.config" \
    task -d "$fixture" "$@"
}
run_task dot:install
test -L "$scratch/home/.config/example with spaces"
test "$(cat "$scratch/home/.config/example with spaces")" = managed
test "$(cat "$scratch/home/.env.local")" = personal
test "$(cat "$scratch/home/.ssh/config")" = 'personal ssh'
backup=$(find "$scratch/data/dotfiles/backups" -type f -name 'example with spaces')
test "$(cat "$backup")" = original
test "$(stat -c %a "$backup" 2>/dev/null || stat -f %Lp "$backup")" = 640
for private in .env.local .ssh/config; do
  test "$(stat -c %a "$scratch/home/$private" 2>/dev/null || stat -f %Lp "$scratch/home/$private")" = 600
done
test "$(stat -c %a "$scratch/home/.ssh" 2>/dev/null || stat -f %Lp "$scratch/home/.ssh")" = 700
run_task dot:install
test "$(find "$scratch/data/dotfiles/backups" -type f | wc -l | tr -d ' ')" = 1
run_task dot:uninstall
test ! -L "$scratch/home/.config/example with spaces"
test "$(cat "$scratch/home/.config/example with spaces")" = original
test "$(cat "$scratch/home/.env.local")" = personal
test "$(cat "$scratch/home/.ssh/config")" = 'personal ssh'
timestamp=$(basename "$(dirname "$(dirname "$(dirname "$backup")")")")
printf 'changed\n' > "$scratch/home/.config/example with spaces"
run_task backup:restore TIMESTAMP="$timestamp"
test "$(cat "$scratch/home/.config/example with spaces")" = original

# A foreign symlink must stop installation without moving it or its referent.
rm "$scratch/home/.config/example with spaces"
printf 'external\n' > "$scratch/external"
ln -s "$scratch/external" "$scratch/home/.config/example with spaces"
if run_task dot:install > "$scratch/foreign.out" 2>&1; then
  echo 'Installation accepted a foreign symlink' >&2
  exit 1
fi
test "$(readlink "$scratch/home/.config/example with spaces")" = "$scratch/external"
test "$(cat "$scratch/external")" = external

# A fresh installation creates private templates with the required modes.
mkdir -p "$scratch/fresh"
env HOME="$scratch/fresh" XDG_DATA_HOME="$scratch/fresh-data" XDG_CONFIG_HOME="$scratch/fresh/.config" \
  task -d "$fixture" dot:install
test "$(cat "$scratch/fresh/.env.local")" = template
test "$(cat "$scratch/fresh/.ssh/config")" = 'ssh template'
for private in .env.local .ssh/config; do
  test ! -L "$scratch/fresh/$private"
  test "$(stat -c %a "$scratch/fresh/$private" 2>/dev/null || stat -f %Lp "$scratch/fresh/$private")" = 600
done
printf 'Installation, backup, repeat install, uninstall and restore passed.\n'
