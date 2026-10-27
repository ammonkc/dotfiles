#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT

git init -q "$scratch/main"
git -C "$scratch/main" config user.name Test
git -C "$scratch/main" config user.email test@example.invalid
git -C "$scratch/main" config commit.gpgsign false
printf 'ignored.txt\n' > "$scratch/main/.gitignore"
git -C "$scratch/main" add .gitignore
git -C "$scratch/main" commit -qm initial
git -C "$scratch/main" worktree add -qb feature "$scratch/feature"
printf 'ignored data\n' > "$scratch/main/ignored.txt"
printf 'untracked data\n' > "$scratch/main/untracked.txt"
mkdir -p "$scratch/main/config dir"
printf 'nested data\n' > "$scratch/main/config dir/nested.txt"
printf 'source only\n' > "$scratch/main/config dir/new.txt"

setup="$root/packages/bin/.local/bin/git-worktree-setup"
PATH=/usr/bin:/bin /bin/bash "$setup" "$scratch/main" "$scratch/feature" > "$scratch/no-manifest.out"
test ! -e "$scratch/feature/ignored.txt"
test ! -e "$scratch/feature/untracked.txt"
grep -q 'nothing to copy' "$scratch/no-manifest.out"

printf '# Explicit paths only\nignored.txt\nconfig dir\n' > "$scratch/main/.worktree-copy"
PATH=/usr/bin:/bin /bin/bash "$setup" -n "$scratch/main" "$scratch/feature" > "$scratch/dry-run.out"
test ! -e "$scratch/feature/ignored.txt"
grep -q ignored.txt "$scratch/dry-run.out"
mkdir -p "$scratch/feature/config dir"
printf 'worktree edit\n' > "$scratch/feature/config dir/nested.txt"
PATH=/usr/bin:/bin /bin/bash "$setup" "$scratch/main" "$scratch/feature" >/dev/null
test "$(cat "$scratch/feature/ignored.txt")" = 'ignored data'
test "$(cat "$scratch/feature/config dir/nested.txt")" = 'worktree edit'
test "$(cat "$scratch/feature/config dir/new.txt")" = 'source only'
test ! -e "$scratch/feature/untracked.txt"

# The fallback must also copy listed directories when rsync is unavailable.
git -C "$scratch/main" worktree add -qb fallback "$scratch/fallback"
mkdir -p "$scratch/no-rsync-bin"
for command_name in git sed awk readlink dirname mkdir cp; do
  ln -s "$(command -v "$command_name")" "$scratch/no-rsync-bin/$command_name"
done
PATH="$scratch/no-rsync-bin" /bin/bash "$setup" "$scratch/main" "$scratch/fallback" >/dev/null
test "$(cat "$scratch/fallback/config dir/new.txt")" = 'source only'

printf '../outside\n' > "$scratch/main/.worktree-copy"
if PATH=/usr/bin:/bin /bin/bash "$setup" "$scratch/main" "$scratch/feature" > "$scratch/invalid.out" 2>&1; then
  echo 'Worktree setup accepted a path outside the source' >&2
  exit 1
fi
grep -q 'Invalid .worktree-copy path' "$scratch/invalid.out"

printf 'ignored.txt\n' > "$scratch/main/.worktree-copy"
PATH=/usr/bin:/bin /bin/bash "$setup" --all "$scratch/main" "$scratch/feature" >/dev/null
test "$(cat "$scratch/feature/untracked.txt")" = 'untracked data'

# /bin/bash is 3.2 on macOS. Use the system rsync through PATH as well.
PATH=/usr/bin:/bin /bin/bash "$root/packages/bin/.local/bin/git-worktree-copy-ignored" -v "$scratch/main" "$scratch/feature" >/dev/null
PATH=/usr/bin:/bin /bin/bash "$root/packages/bin/.local/bin/git-worktree-copy-untracked" "$scratch/main" "$scratch/feature" >/dev/null
test "$(cat "$scratch/feature/ignored.txt")" = 'ignored data'
test "$(cat "$scratch/feature/untracked.txt")" = 'untracked data'
printf 'Worktree copy compatibility checks passed.\n'
