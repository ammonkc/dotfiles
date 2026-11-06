#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/home" "$scratch/bin"
stow --no-folding --dir="$root/packages" --target="$scratch/home" zsh
# Force a minimal PATH after the real path setup, hiding optional integrations.
printf 'path=("%s")\nHOMEBREW_PREFIX=$HOME/missing-homebrew\n' "$scratch/bin" > "$scratch/home/.zshenv.local"
for tool in mkdir chmod dirname uname; do
  ln -s "$(command -v "$tool")" "$scratch/bin/$tool"
done
zsh_bin=$(command -v zsh)
for mode in -c -ic -lic; do
  env -i HOME="$scratch/home" PATH="$scratch/bin" TERM=xterm-256color \
    "$zsh_bin" -d "$mode" '
      [[ $ZDOTDIR == "$HOME/.config/zsh" ]] || exit 1
      [[ -d $XDG_STATE_HOME/zsh && -d $GNUPGHOME ]] || exit 1
      (( $+commands[brew] == 0 && $+commands[mise] == 0 )) || exit 1
      print -r -- startup-ok
    ' > "$scratch/stdout" 2> "$scratch/stderr"
  grep -qx startup-ok "$scratch/stdout"
  test ! -s "$scratch/stderr" || { cat "$scratch/stderr" >&2; exit 1; }
done
printf 'Zsh noninteractive, interactive and login startup passed without optional tools.\n'
