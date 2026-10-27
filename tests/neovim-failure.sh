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

# A parser failure must remain pending, while a successful plugin restore is reused.
cat > "$scratch/brew/bin/nvim" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$NVIM_TEST_LOG"
case "$*" in
  *TSUpdateSync*)
    if [ ! -f "$NVIM_TS_FAILED" ]; then
      touch "$NVIM_TS_FAILED"
      exit 13
    fi
    ;;
  *MasonToolsInstall*)
    if [ ! -f "$NVIM_MASON_FAILED" ]; then
      touch "$NVIM_MASON_FAILED"
      echo 'E492: Not an editor command: MasonToolsInstall'
      exit 0
    fi
    ;;
esac
exit 0
EOF
export NVIM_TEST_LOG="$scratch/nvim.log" NVIM_TS_FAILED="$scratch/ts-failed" NVIM_MASON_FAILED="$scratch/mason-failed"
HOME="$scratch/home" XDG_CONFIG_HOME="$scratch/home/.config" XDG_DATA_HOME="$scratch/data" NVIM_BIN="$scratch/brew/bin/nvim" task -d "$root" nvim:restore
test -s "$scratch/data/nvim/.lazy-restore-hash"
test ! -e "$scratch/data/nvim/.lazy-tools-hash"
HOME="$scratch/home" XDG_CONFIG_HOME="$scratch/home/.config" XDG_DATA_HOME="$scratch/data" NVIM_BIN="$scratch/brew/bin/nvim" task -d "$root" nvim:restore
test -s "$scratch/data/nvim/.lazy-tools-hash"
test "$(grep -c 'Lazy! restore' "$NVIM_TEST_LOG")" -eq 1
test "$(grep -c TSUpdateSync "$NVIM_TEST_LOG")" -eq 2
before="$(wc -l < "$NVIM_TEST_LOG")"
HOME="$scratch/home" XDG_CONFIG_HOME="$scratch/home/.config" XDG_DATA_HOME="$scratch/data" NVIM_BIN="$scratch/brew/bin/nvim" task -d "$root" nvim:restore
test "$(wc -l < "$NVIM_TEST_LOG")" -eq "$before"
printf 'Neovim restore failure check passed.\n'
