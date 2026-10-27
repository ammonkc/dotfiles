#!/bin/bash
# Replace the managed section of a local file with a fully staged block from stdin.
# An optional line prefix moves a legacy setting out of that section before replacement.
set -euo pipefail
target="$1"
marker="$2"
preserve_prefix="${3:-}"
umask 077
if [ -e "$target" ]; then
  chmod 600 "$target"
fi
staged="$(mktemp "${target}.tmp.XXXXXX")"
trap 'rm -f "$staged"' EXIT
if [ -f "$target" ]; then
  awk -v marker="$marker" -v preserve_prefix="$preserve_prefix" '
    $0 == marker { managed = 1; next }
    managed {
      if (preserve_prefix != "" && index($0, preserve_prefix) == 1) saved = $0
      next
    }
    preserve_prefix != "" && index($0, preserve_prefix) == 1 { already_preserved = 1 }
    $0 == "" { blanks++; next }
    { for (i = 0; i < blanks; i++) print ""; blanks = 0; print }
    END { if (!already_preserved && saved != "") print saved }
  ' "$target" > "$staged"
fi
printf '\n%s\n' "$marker" >> "$staged"
cat >> "$staged"
chmod 600 "$staged"
mv -f "$staged" "$target"
