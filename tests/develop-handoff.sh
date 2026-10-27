#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
scratch=$(mktemp -d)
scratch=$(cd "$scratch" && pwd -P)
trap 'status=$?; if ((status)); then cat "$scratch/handoff.md" "$scratch/task.stderr" 2>/dev/null || true; fi; rm -rf "$scratch"' EXIT
git init -qb main "$scratch/main"
git -C "$scratch/main" config user.name Test
git -C "$scratch/main" config user.email test@example.invalid
git -C "$scratch/main" config commit.gpgsign false
printf 'initial\n' > "$scratch/main/file.txt"
git -C "$scratch/main" add .
git -C "$scratch/main" commit -qm initial
base=$(git -C "$scratch/main" rev-parse HEAD)
git -C "$scratch/main" worktree add -qb feature "$scratch/feature"
printf 'committed\n' > "$scratch/feature/committed.txt"
git -C "$scratch/feature" add .
git -C "$scratch/feature" commit -qm 'add committed file'
printf 'unfinished\n' > "$scratch/feature/unfinished.txt"

(
  cd "$scratch/feature"
  DOTFILES_DIR="$root" bash "$root/packages/bin/.local/bin/dotfiles" \
    dev:handoff SUMMARY='Implemented feature' CHECKS='task test passed' \
    NEXT='Review the remaining change'
) > "$scratch/handoff.md" 2> "$scratch/task.stderr"

grep -Fq "Worktree: \`$scratch/feature\`" "$scratch/handoff.md"
grep -Fq "Base: \`main\` (\`$base\`)" "$scratch/handoff.md"
grep -Fq 'A'"$(printf '\t')"'committed.txt' "$scratch/handoff.md"
grep -Fq '?? unfinished.txt' "$scratch/handoff.md"
grep -Fq 'Implemented feature' "$scratch/handoff.md"
grep -Fq 'task test passed' "$scratch/handoff.md"
grep -Fq 'Review the remaining change' "$scratch/handoff.md"

if bash "$root/scripts/develop-handoff.sh" "$scratch" > "$scratch/not-a-repo.out" 2>&1; then
  printf 'Handoff accepted a directory outside Git.\n' >&2
  exit 1
fi

printf 'Development handoff checks passed.\n'
