#!/usr/bin/env bash
# Check deployed revision and Stow links. --links-only is for fresh machines.
set -euo pipefail
export GIT_OPTIONAL_LOCKS=0

checkout=${1:?Usage: dotfiles-verify.sh CHECKOUT [--links-only]}
mode=${2:-full}
home=${DOTFILES_TARGET_HOME:-$HOME}
deployed=${DOTFILES_DEPLOY_DIR:-$home/.dotfiles}
if [[ ! -d "$deployed/packages" ]] || ! git -C "$deployed" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  printf 'Deployed checkout missing: %s\n' "$deployed" >&2
  exit 1
fi
command -v stow >/dev/null || { printf 'stow is required\n' >&2; exit 1; }

failed=0
if [[ "$mode" != --links-only ]]; then
  if [[ "$checkout" != "$deployed" ]]; then
    source_dir=${DOTFILES_SOURCE_DIR:-$checkout}
  else
    source_dir=${DOTFILES_SOURCE_DIR:-$home/Developer/repos/ammonkc/dotfiles}
  fi
  if ! git -C "$source_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf 'Development checkout missing: %s\n' "$source_dir" >&2
    failed=1
  else
    source_head=$(git -C "$source_dir" rev-parse HEAD)
    deployed_head=$(git -C "$deployed" rev-parse HEAD)
    printf 'Development: %s (%s)\n' "$source_head" "$source_dir"
    printf 'Deployed:    %s (%s)\n' "$deployed_head" "$deployed"
    if [[ "$source_head" != "$deployed_head" ]]; then
      printf 'Deployment is at a different commit.\n' >&2
      failed=1
    fi
    if [[ -n "$(git -C "$source_dir" status --porcelain)" ]]; then
      printf 'Development checkout has uncommitted changes.\n' >&2
      failed=1
    fi
  fi
fi
if [[ -n "$(git -C "$deployed" status --porcelain)" ]]; then
  printf 'Deployed checkout has uncommitted changes.\n' >&2
  failed=1
fi

# With no --restow, Stow prints LINK for missing files and fails on conflicting
# or wrongly owned links. This checks every package path, including deep paths.
for package_path in "$deployed/packages"/*; do
  [[ -d "$package_path" ]] || continue
  package=${package_path##*/}
  if output=$(stow --simulate --verbose=1 --no-folding \
      --dir="$deployed/packages" --target="$home" "$package" 2>&1); then
    if [[ "$output" == *'LINK:'* ]]; then
      printf '[%s] Missing managed links:\n%s\n' "$package" "$output" >&2
      failed=1
    fi
  else
    printf '[%s] Stow conflicts or invalid links:\n%s\n' "$package" "$output" >&2
    failed=1
  fi
done

if ((failed)); then exit 1; fi
printf 'Deployed checkout and managed links verified.\n'
