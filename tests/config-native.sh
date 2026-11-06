#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
# Parse Git's tracked config without following its user-local include.
git config --no-includes --file "$root/packages/git/.config/git/config" --list > /dev/null
export RIPGREP_CONFIG_PATH="$root/packages/ripgrep/.config/ripgrep/config"
rg --type-list > "$scratch/types"
grep -q '^laravel:' "$scratch/types"
mkdir -p "$scratch/source"
printf 'native-parser-smoke\n' > "$scratch/source/Example.ts"
rg --type ts native-parser-smoke "$scratch/source" > "$scratch/matches"
grep -q Example.ts "$scratch/matches"
printf 'Native Git and ripgrep configuration checks passed.\n'
