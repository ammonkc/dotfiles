#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/packages/demo" "$scratch/target" "$scratch/backup" "$scratch/bin"
printf 'managed\n' > "$scratch/packages/demo/example"
printf 'original\n' > "$scratch/target/example"
printf 'older backup\n' > "$scratch/backup/example"
helper="$root/scripts/backup-stow-conflicts.sh"
if /bin/bash "$helper" "$scratch/packages" demo "$scratch/target" "$scratch/backup" > "$scratch/output" 2>&1; then
  echo 'Conflict backup overwrote an existing backup' >&2
  exit 1
fi
test "$(cat "$scratch/target/example")" = original
test "$(cat "$scratch/backup/example")" = 'older backup'
if /bin/bash "$helper" "$scratch/packages" missing "$scratch/target" "$scratch/new-backup" > "$scratch/output" 2>&1; then
  echo 'Conflict backup ignored a Stow failure' >&2
  exit 1
fi
test "$(cat "$scratch/target/example")" = original
test ! -e "$scratch/new-backup"
cat > "$scratch/bin/stow" <<'EOF'
#!/bin/sh
echo 'Stow failed with an unfamiliar diagnostic' >&2
exit 1
EOF
chmod +x "$scratch/bin/stow"
if PATH="$scratch/bin:$PATH" /bin/bash "$helper" "$scratch/packages" demo "$scratch/target" "$scratch/new-backup" > "$scratch/output" 2>&1; then
  echo 'Conflict backup ignored an unknown diagnostic' >&2
  exit 1
fi
test "$(cat "$scratch/target/example")" = original
test ! -e "$scratch/new-backup"
printf 'Backup collision and Stow failure checks passed.\n'
