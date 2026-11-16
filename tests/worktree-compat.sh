#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd -P)"
scratch="$(mktemp -d)"
scratch="$(cd "$scratch" && pwd -P)"
trap 'rm -rf "$scratch"' EXIT
main="$scratch/main checkout"
feature="$scratch/feature checkout"
git init -q -b main "$main"
git -C "$main" config user.name Test
git -C "$main" config user.email test@example.invalid
git -C "$main" config commit.gpgsign false
printf 'ignored.txt\nexcluded.txt\n' > "$main/.gitignore"
git -C "$main" add .gitignore
git -C "$main" commit -qm initial
git -C "$main" worktree add -qb feature "$feature"
printf 'ignored data\n' > "$main/ignored.txt"
printf 'excluded data\n' > "$main/excluded.txt"
printf 'untracked data\n' > "$main/untracked.txt"
setup="$root/packages/bin/.local/bin/git-worktree-setup"

# Standalone copy utilities remain compatible with system Bash and rsync.
PATH=/usr/bin:/bin /bin/bash "$root/packages/bin/.local/bin/git-worktree-copy-ignored" -v "$main" "$feature" >/dev/null
PATH=/usr/bin:/bin /bin/bash "$root/packages/bin/.local/bin/git-worktree-copy-untracked" "$main" "$feature" >/dev/null
test "$(cat "$feature/ignored.txt")" = 'ignored data'
test "$(cat "$feature/untracked.txt")" = 'untracked data'
rm "$feature/ignored.txt" "$feature/excluded.txt" "$feature/untracked.txt"

if ! command -v wt >/dev/null 2>&1; then
  if /bin/bash "$setup" "$main" "$feature" > "$scratch/missing-wt" 2>&1; then
    echo 'Setup accepted a missing Worktrunk installation' >&2
    exit 1
  fi
  grep -q 'Worktrunk (wt) is required' "$scratch/missing-wt"
  echo 'Standalone copy checks passed; Worktrunk integration skipped (wt not installed).'
  exit 0
fi
# Use isolated configuration, without the user's creation hooks.
export WORKTRUNK_CONFIG_PATH="$scratch/wt.toml"
printf '' > "$WORKTRUNK_CONFIG_PATH"
/bin/bash "$setup" "$main" "$feature" > "$scratch/no-include"
test ! -e "$feature/ignored.txt"
printf 'ignored.txt\n' > "$main/.worktreeinclude"
/bin/bash "$setup" -n "$main" "$feature" > "$scratch/dry-run"
test ! -e "$feature/ignored.txt"
grep -q ignored.txt "$scratch/dry-run"
(cd "$feature" && /bin/bash "$setup" > /dev/null)
test "$(cat "$feature/ignored.txt")" = 'ignored data'
test ! -e "$feature/excluded.txt"
test ! -e "$feature/untracked.txt"
printf 'destination edit\n' > "$feature/ignored.txt"
/bin/bash "$setup" -v "" "$feature" > /dev/null
test "$(cat "$feature/ignored.txt")" = 'destination edit'

# Explicit alternate source selects its branch, not the primary checkout.
git -C "$main" worktree add -qb destination "$scratch/destination"
printf 'ignored.txt\n' > "$feature/.worktreeinclude"
/bin/bash "$setup" "$feature" "$scratch/destination" > /dev/null
test "$(cat "$scratch/destination/ignored.txt")" = 'destination edit'

if /bin/bash "$setup" --all "$main" "$feature" > "$scratch/retired" 2>&1; then
  echo 'Setup accepted retired copy-all behavior' >&2
  exit 1
fi
grep -q 'retired' "$scratch/retired"
printf 'ignored.txt\n' > "$main/.worktree-copy"
if /bin/bash "$setup" "$main" "$feature" > "$scratch/retired" 2>&1; then
  echo 'Setup silently accepted the retired manifest' >&2
  exit 1
fi
grep -q '.worktree-copy is retired' "$scratch/retired"
rm "$main/.worktree-copy"

git init -q "$scratch/unrelated"
if /bin/bash "$setup" "$main" "$scratch/unrelated" > "$scratch/unrelated.out" 2>&1; then
  echo 'Setup accepted an unrelated repository' >&2
  exit 1
fi
grep -q 'same repository' "$scratch/unrelated.out"
printf 'Worktree setup delegation and standalone copy compatibility checks passed.\n'
