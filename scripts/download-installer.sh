#!/bin/bash
# Download fully before executing. Usage: download-installer.sh URL [arguments...]
set -euo pipefail
url="$1"
shift
case "$url" in
  https://taskfile.dev/install.sh|https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh) ;;
  *) echo "Unapproved installer URL: $url" >&2; exit 1 ;;
esac
installer="$(mktemp "${TMPDIR:-/tmp}/dotfiles-installer.XXXXXX")"
trap 'rm -f "$installer"' EXIT
curl --fail --location --silent --show-error --retry 3 --connect-timeout 10 --max-time 120 "$url" --output "$installer"
test -s "$installer" || { echo "Installer download was empty: $url" >&2; exit 1; }
/bin/bash -n "$installer"
head -n 1 "$installer" | grep -Eq '^#!.*(ba)?sh([[:space:]]|$)' || {
  echo "Installer is not a shell script: $url" >&2; exit 1;
}
/bin/bash "$installer" "$@"
