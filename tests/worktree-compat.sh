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

# /bin/bash is 3.2 on macOS. Use the system rsync through PATH as well.
PATH=/usr/bin:/bin /bin/bash "$root/packages/bin/.local/bin/git-worktree-copy-ignored" -v "$scratch/main" "$scratch/feature" >/dev/null
PATH=/usr/bin:/bin /bin/bash "$root/packages/bin/.local/bin/git-worktree-copy-untracked" "$scratch/main" "$scratch/feature" >/dev/null
test "$(cat "$scratch/feature/ignored.txt")" = 'ignored data'
test "$(cat "$scratch/feature/untracked.txt")" = 'untracked data'
printf 'Worktree copy compatibility checks passed.\n'
