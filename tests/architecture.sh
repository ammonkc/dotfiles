#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
cat > "$scratch/uname" <<'EOF'
#!/bin/sh
case "$1" in
  -s) echo Darwin ;;
  -m) echo x86_64 ;;
esac
EOF
chmod +x "$scratch/uname"
if PATH="$scratch:$PATH" bash -c 'source "$1"' _ "$root/scripts/bootstrap-env.sh"; then
  echo 'Intel macOS environment was accepted' >&2
  exit 1
fi
sed 's/x86_64/arm64/' "$scratch/uname" > "$scratch/uname.arm"
mv "$scratch/uname.arm" "$scratch/uname"
chmod +x "$scratch/uname"
PATH="$scratch:$PATH" bash -c 'source "$1"; case "$PATH" in /opt/homebrew/bin:/opt/homebrew/sbin:*) ;; *) exit 1 ;; esac' _ "$root/scripts/bootstrap-env.sh"
printf 'macOS architecture checks passed.\n'
