#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd -P)"
if ! command -v wt >/dev/null 2>&1; then
  echo 'Worktrunk checks skipped: wt is not installed.'
  exit 0
fi
scratch="$(mktemp -d)"
scratch="$(cd "$scratch" && pwd -P)"
trap 'rm -rf "$scratch"' EXIT
export HOME="$scratch/home"
export WORKTRUNK_CONFIG_PATH="$root/packages/worktrunk/.config/worktrunk/config.toml"
export IDL_REPO_DIR="$HOME/Developer/code/indirect"
export IDL_WORKTREES_DIR="$HOME/Developer/worktrees/indirect-lending-application"
export IDL_ZED_TASKS_TEMPLATE="$root/packages/zed/.config/zed/templates/idl-tasks.json"
mkdir -p "$IDL_REPO_DIR" "$HOME/.local/bin"
ln -s "$root/packages/bin/.local/bin/idl-worktree-setup" "$HOME/.local/bin/idl-worktree-setup"
git -C "$IDL_REPO_DIR" init -q -b main
git -C "$IDL_REPO_DIR" config core.excludesfile "$root/packages/git/.config/git/ignore"
git -C "$IDL_REPO_DIR" remote add origin https://github.com/ncino/indirect-lending-application.git
printf '.env\nvendor/\nnode_modules/\nprivate-cache/\n' > "$IDL_REPO_DIR/.gitignore"
git -C "$IDL_REPO_DIR" add .gitignore
git -C "$IDL_REPO_DIR" -c user.name=Test -c user.email=test@example.test -c commit.gpgsign=false commit -qm initial
mkdir -p "$IDL_REPO_DIR/vendor" "$IDL_REPO_DIR/private-cache"
printf 'fixture\n' > "$IDL_REPO_DIR/.env"
printf 'dependency\n' > "$IDL_REPO_DIR/vendor/test"
printf 'excluded\n' > "$IDL_REPO_DIR/private-cache/test"

wt -C "$IDL_REPO_DIR" switch --create feature/no-include --no-cd > /dev/null
destination="$IDL_WORKTREES_DIR/feature-no-include"
test ! -e "$destination/.env"
cmp "$IDL_ZED_TASKS_TEMPLATE" "$destination/.zed/tasks.json"

printf '.env\nvendor/\nnode_modules/\n' > "$IDL_REPO_DIR/.worktreeinclude"
git -C "$IDL_REPO_DIR" -c core.excludesfile="$root/packages/git/.config/git/ignore" check-ignore -q .worktreeinclude
wt -C "$IDL_REPO_DIR" switch --create feature/with-include --no-cd > /dev/null
destination="$IDL_WORKTREES_DIR/feature-with-include"
cmp "$IDL_REPO_DIR/.env" "$destination/.env"
cmp "$IDL_REPO_DIR/vendor/test" "$destination/vendor/test"
test ! -e "$destination/private-cache"
cmp "$IDL_ZED_TASKS_TEMPLATE" "$destination/.zed/tasks.json"

# Removal keeps even a branch with no changes beyond main.
wt -C "$IDL_REPO_DIR" remove --foreground feature/with-include > /dev/null
git -C "$IDL_REPO_DIR" show-ref --verify --quiet refs/heads/feature/with-include
test ! -d "$destination"
echo 'Worktrunk creation, copy selection, IDL tasks, and branch retention checks passed.'
