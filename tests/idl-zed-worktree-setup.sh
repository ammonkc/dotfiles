#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT

base="$scratch/IDL worktrees"
main="$base/main"
feature="$base/feature branch"
mkdir -p "$main"
git -C "$main" init -q
git -C "$main" -c user.name=Test -c user.email=test@example.test -c commit.gpgsign=false commit --allow-empty -qm initial
git -C "$main" worktree add -q -b feature "$feature"

export IDL_WORKTREES_DIR="$base"
export IDL_ZED_TASKS_TEMPLATE="$root/packages/zed/.config/zed/templates/idl-tasks.json"
helper="$root/packages/bin/.local/bin/idl-worktree-setup"

"$helper" "$feature" > /dev/null
cmp "$IDL_ZED_TASKS_TEMPLATE" "$feature/.zed/tasks.json"

"$helper" "$feature" > "$scratch/unchanged"
test -z "$(find "$feature/.zed" -maxdepth 1 -name 'tasks.json.backup.*' -print -quit)"

printf 'custom worktree tasks\n' > "$feature/.zed/tasks.json"
"$helper" "$feature" > /dev/null
cmp "$IDL_ZED_TASKS_TEMPLATE" "$feature/.zed/tasks.json"
backup="$(find "$feature/.zed" -maxdepth 1 -name 'tasks.json.backup.*' -print -quit)"
test -n "$backup"
test "$(cat "$backup")" = 'custom worktree tasks'

if "$helper" "$scratch/other" > /dev/null 2>&1; then
  echo 'IDL setup accepted a path outside the IDL worktrees directory' >&2
  exit 1
fi

printf 'IDL Zed worktree setup checks passed.\n'
