#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
export HOME="$scratch/home"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
mkdir -p "$HOME" "$scratch/source/packages/demo/.config" "$scratch/bin"
printf 'managed\n' > "$scratch/source/packages/demo/.config/example"
git -C "$scratch/source" init -q
git -C "$scratch/source" add .
git -C "$scratch/source" -c commit.gpgsign=false -c user.name=Test -c user.email=test@example.com commit -qm initial
git clone -q "$scratch/source" "$HOME/.dotfiles"
stow --no-folding --dir="$HOME/.dotfiles/packages" --target="$HOME" demo

export DOTFILES_SOURCE_DIR="$scratch/source"
export DOTFILES_DEPLOY_DIR="$HOME/.dotfiles"
export DOTFILES_TARGET_HOME="$HOME"
bash "$root/scripts/dotfiles-verify.sh" "$scratch/source" > "$scratch/verify.out"
grep -q 'verified' "$scratch/verify.out"
task -d "$root" dot:verify > "$scratch/task-verify.out"
grep -q 'verified' "$scratch/task-verify.out"

bash "$root/scripts/dotfiles-plan.sh" "$HOME/.dotfiles" "$HOME" > "$scratch/plan.out" 2>&1
grep -q 'No files changed' "$scratch/plan.out"

mkdir -p "$HOME/.config/nvim" "$HOME/.local/share/nvim"
printf 'lock\n' > "$HOME/.config/nvim/lazy-lock.json"
lock_hash=$(shasum -a 256 "$HOME/.config/nvim/lazy-lock.json" | cut -d' ' -f1)
printf '%s\n' "$lock_hash" > "$HOME/.local/share/nvim/.lazy-restore-hash"
printf '%s\n' "$lock_hash" > "$HOME/.local/share/nvim/.lazy-tools-hash"
for tool in mise nvim ya; do
  printf '#!/bin/sh\nexit 0\n' > "$scratch/bin/$tool"
done
chmod +x "$scratch/bin"/*
export PATH="$scratch/bin:$PATH"
bash "$root/scripts/system-check.sh" "$root" > "$scratch/check.out"
grep -q 'checks passed' "$scratch/check.out"
task -d "$root" system:check > "$scratch/task-check.out"
grep -q 'checks passed' "$scratch/task-check.out"
printf 'stale\n' > "$HOME/.local/share/nvim/.lazy-tools-hash"
if bash "$root/scripts/system-check.sh" "$root" > "$scratch/stale.out" 2>&1; then
  printf 'system:check accepted a stale Neovim tools marker\n' >&2
  exit 1
fi

rm "$HOME/.config/example"
if bash "$root/scripts/dotfiles-verify.sh" "$scratch/source" > "$scratch/missing.out" 2>&1; then
  printf 'dot:verify accepted a missing managed link\n' >&2
  exit 1
fi
grep -q 'Missing managed links' "$scratch/missing.out"
stow --no-folding --dir="$HOME/.dotfiles/packages" --target="$HOME" demo

printf 'new commit\n' > "$scratch/source/README.md"
git -C "$scratch/source" add README.md
git -C "$scratch/source" -c commit.gpgsign=false -c user.name=Test -c user.email=test@example.com commit -qm second
if bash "$root/scripts/dotfiles-verify.sh" "$scratch/source" > "$scratch/outdated.out" 2>&1; then
  printf 'dot:verify accepted different development and deployed commits\n' >&2
  exit 1
fi
grep -q 'different commit' "$scratch/outdated.out"

printf 'unmanaged\n' > "$HOME/.config/conflict"
printf 'new\n' > "$HOME/.dotfiles/packages/demo/.config/conflict"
if bash "$root/scripts/dotfiles-plan.sh" "$HOME/.dotfiles" "$HOME" > "$scratch/conflict.out" 2>&1; then
  printf 'dot:plan missed an unmanaged conflict\n' >&2
  exit 1
fi
grep -q 'conflict' "$scratch/conflict.out"
grep -q unmanaged "$HOME/.config/conflict"

task -d "$root" dev:setup DEV_DIR="$HOME/Developer" DEFAULT_ORGS=testorg > "$scratch/setup.out"
for directory in code documentation repos/testorg scripts worktrees; do
  test -d "$HOME/Developer/$directory"
done
task -d "$root" dev:list DEV_DIR="$HOME/Developer" > "$scratch/list.out"
grep -q "Scripts ($HOME/Developer/scripts)" "$scratch/list.out"

mkdir -p "$XDG_DATA_HOME/dotfiles/backups/20260101-000000"
task -d "$root" info:all > "$scratch/info.out"
grep -Eq 'Backups +1$' "$scratch/info.out"

mkdir -p "$HOME/Developer/repos/testorg/sample"
git -C "$HOME/Developer/repos/testorg/sample" init -q
printf 'tracked\n' > "$HOME/Developer/repos/testorg/sample/file"
git -C "$HOME/Developer/repos/testorg/sample" add .
git -C "$HOME/Developer/repos/testorg/sample" -c commit.gpgsign=false -c user.name=Test -c user.email=test@example.com commit -qm initial
mkdir -p "$HOME/Developer/worktrees/sample"
git -C "$HOME/Developer/repos/testorg/sample" worktree add -qb feature "$HOME/Developer/worktrees/sample/feature"
printf 'changed\n' > "$HOME/Developer/worktrees/sample/feature/file"
task -d "$root" dev:status DEV_DIR="$HOME/Developer" > "$scratch/status.out"
grep -q "$HOME/Developer/worktrees/sample/feature" "$scratch/status.out"
grep -q 'Checked 2 repositories and worktrees; 1 has local changes' "$scratch/status.out"

printf 'Task gap checks passed.\n'
