#!/usr/bin/env bash
# Discover suites; run all of them even when an earlier suite fails.
set -uo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
group=${1:-all}
case "$group" in all|shell|stow|config) ;; *) echo "Usage: $0 [all|shell|stow|config]" >&2; exit 2 ;; esac
failed=0
count=0
for suite in "$root"/tests/*.sh; do
  name=${suite##*/}
  case "$name" in stow-*|install-lifecycle.sh) category=stow ;; config-*|zsh-startup.sh) category=config ;; *) category=shell ;; esac
  [[ "$group" == all || "$group" == "$category" ]] || continue
  count=$((count + 1))
  printf '\n[%s] %s\n' "$category" "$name"
  if /bin/bash "$suite"; then
    printf 'PASS %s\n' "$name"
  else
    printf 'FAIL %s\n' "$name" >&2
    failed=$((failed + 1))
  fi
done
printf '\n%d suites; %d failed.\n' "$count" "$failed"
[[ "$count" -gt 0 && "$failed" -eq 0 ]]
