#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/home/.config/nvim" "$scratch/data/nvim/lazy/lazy.nvim" "$scratch/brew/bin"
cp "$root/packages/nvim/.config/nvim/lazy-lock.json" "$scratch/home/.config/nvim/lazy-lock.json"
cat > "$scratch/brew/bin/nvim" <<'EOF'
#!/bin/sh
exit 13
EOF
chmod +x "$scratch/brew/bin/nvim"
if HOME="$scratch/home" XDG_CONFIG_HOME="$scratch/home/.config" XDG_DATA_HOME="$scratch/data" XDG_STATE_HOME="$scratch/state" NVIM_BIN="$scratch/brew/bin/nvim" task -d "$root" nvim:restore; then
  echo 'Neovim restore succeeded after a plugin failure' >&2
  exit 1
fi
test ! -e "$scratch/data/nvim/.lazy-restore-hash"
cat > "$scratch/brew/bin/nvim" <<'EOF'
#!/bin/sh
echo 'E492: Not an editor command: Lazy! restore'
exit 0
EOF
if HOME="$scratch/home" XDG_CONFIG_HOME="$scratch/home/.config" XDG_DATA_HOME="$scratch/data" XDG_STATE_HOME="$scratch/state" NVIM_BIN="$scratch/brew/bin/nvim" task -d "$root" nvim:restore; then
  echo 'Neovim restore accepted an editor error with exit status zero' >&2
  exit 1
fi
test ! -e "$scratch/data/nvim/.lazy-restore-hash"
printf 'Neovim restore failure check passed.\n'
