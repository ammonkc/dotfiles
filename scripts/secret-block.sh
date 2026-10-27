#!/bin/bash
# Replace the managed section of a local file with a fully staged block from stdin.
set -euo pipefail
target="$1"
marker="$2"
umask 077
if [ -e "$target" ]; then
  chmod 600 "$target"
fi
staged="$(mktemp "${target}.tmp.XXXXXX")"
trap 'rm -f "$staged"' EXIT
if [ -f "$target" ]; then
  awk -v marker="$marker" '
    $0 == marker { exit }
    $0 == "" { blanks++; next }
    { for (i = 0; i < blanks; i++) print ""; blanks = 0; print }
  ' "$target" > "$staged"
fi
printf '\n%s\n' "$marker" >> "$staged"
cat >> "$staged"
chmod 600 "$staged"
mv -f "$staged" "$target"
