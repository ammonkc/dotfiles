#!/usr/bin/env bash
# Current atuin keeps its files in ~/.atuin by default and only falls back to the XDG locations
# for files that already exist. The zsh exports must point it at XDG paths so a fresh account never
# gets a ~/.atuin directory. Everything runs in a scratch home with a clean environment.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
home="$scratch/home"
mkdir -p "$home" "$scratch/bin"
stow --no-folding --dir="$root/packages" --target="$home" zsh atuin

# A minimal PATH, so the shell cannot reach the real home, tools or an inherited XDG variable.
for tool in mkdir chmod dirname uname; do
  ln -s "$(command -v "$tool")" "$scratch/bin/$tool"
done
atuin_bin=$(command -v atuin || true)
[ -z "$atuin_bin" ] || ln -s "$atuin_bin" "$scratch/bin/atuin"
zsh_bin=$(command -v zsh)
run() {
  env -i HOME="$home" PATH="$scratch/bin" TERM=dumb "$zsh_bin" -d -c "$1"
}

expect_var() {
  actual="$(run "print -r -- \$$1")"
  if [ "$actual" != "$2" ]; then
    echo "$1 is '$actual', expected '$2'" >&2
    exit 1
  fi
}
expect_var ATUIN_HOME "$home/.local/share/atuin"
expect_var ATUIN_CONFIG_DIR "$home/.config/atuin"

if [ -n "$atuin_bin" ]; then
  info="$(run 'atuin info' 2>&1)"
  grep -qF "client config: \"$home/.config/atuin/config.toml\"" <<< "$info"
  grep -qF "client db path: $home/.local/share/atuin/data/history.db" <<< "$info"
  grep -qF "key path: $home/.local/share/atuin/data/key" <<< "$info"
  # The configured theme must load: atuin reads themes from $ATUIN_HOME/themes, not the config dir.
  if [ ! -e "$home/.local/share/atuin/themes/catppuccin-mocha-mauve.toml" ]; then
    echo "the configured theme is not stowed under ~/.local/share/atuin/themes" >&2
    exit 1
  fi
  if grep -q 'could not load theme' <<< "$info"; then
    echo "atuin cannot load the configured theme:" >&2
    grep 'could not load theme' <<< "$info" >&2
    exit 1
  fi
  # Exercise the database and key creation paths, then look for the default home.
  run 'atuin history list; atuin search --limit 1 < /dev/null' >/dev/null 2>&1 || true
  test -f "$home/.local/share/atuin/data/history.db"
  if [ -e "$home/.atuin" ]; then
    echo "atuin created ~/.atuin despite ATUIN_HOME" >&2
    find "$home/.atuin" >&2
    exit 1
  fi
  # The stowed config must contain only settings atuin recognises.
  # Capture first: under pipefail, `cmd | grep -q` can report the producer's SIGPIPE status.
  config_out="$(run 'atuin config get db_path' 2>&1 || true)"
  if grep -q 'unrecognized settings' <<< "$config_out"; then
    echo "atuin reports unrecognized settings in the stowed config.toml" >&2
    exit 1
  fi
else
  printf 'atuin is not installed; checked the exported variables only.\n'
fi
printf 'Atuin XDG layout checks passed.\n'
