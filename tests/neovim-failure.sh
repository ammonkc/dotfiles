#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
# The restore task reacts to Composer being installed; COMPOSER_BIN points it at a missing file
# unless a test installs the stub below.
export COMPOSER_BIN="$scratch/absent/composer"
mkdir -p "$scratch/home/.config/nvim" "$scratch/data/nvim/lazy/lazy.nvim" "$scratch/brew/bin"
# The committed lockfile seeds Neovim's own copy, so the restore task creates the copy itself.
cp "$root/packages/nvim/.config/nvim/lazy-lock.json" "$scratch/committed-lock.json"
export NVIM_LOCKFILE_SOURCE="$scratch/committed-lock.json"
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
  *nvim-treesitter*)
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
# Two passes: the second one, after putting the committed lockfile back, pins plugins that were
# still being cloned during the first.
test "$(grep -c 'Lazy! restore' "$NVIM_TEST_LOG")" -eq 2
test -f "$scratch/home/.config/nvim/lazy-lock.json"
test ! -L "$scratch/home/.config/nvim/lazy-lock.json"
test "$(grep -c nvim-treesitter "$NVIM_TEST_LOG")" -eq 2
before="$(wc -l < "$NVIM_TEST_LOG")"
HOME="$scratch/home" XDG_CONFIG_HOME="$scratch/home/.config" XDG_DATA_HOME="$scratch/data" NVIM_BIN="$scratch/brew/bin/nvim" task -d "$root" nvim:restore
test "$(wc -l < "$NVIM_TEST_LOG")" -eq "$before"

# pint is installed through Composer, which only the full bundle provides. A core restore must
# finish complete without it, and installing Composer later must trigger one more restore.
mkdir -p "$scratch/composer-bin"
printf '#!/bin/sh\nexit 0\n' > "$scratch/composer-bin/composer"
chmod +x "$scratch/composer-bin/composer"
before="$(wc -l < "$NVIM_TEST_LOG")"
COMPOSER_BIN="$scratch/composer-bin/composer" HOME="$scratch/home" XDG_CONFIG_HOME="$scratch/home/.config" XDG_DATA_HOME="$scratch/data" NVIM_BIN="$scratch/brew/bin/nvim" task -d "$root" nvim:restore
test "$(wc -l < "$NVIM_TEST_LOG")" -gt "$before"
mkdir -p "$scratch/data/nvim/mason/bin"
: > "$scratch/data/nvim/mason/bin/pint"
before="$(wc -l < "$NVIM_TEST_LOG")"
COMPOSER_BIN="$scratch/composer-bin/composer" HOME="$scratch/home" XDG_CONFIG_HOME="$scratch/home/.config" XDG_DATA_HOME="$scratch/data" NVIM_BIN="$scratch/brew/bin/nvim" task -d "$root" nvim:restore
test "$(wc -l < "$NVIM_TEST_LOG")" -eq "$before"

# lazy.nvim rewrites its lockfile, so Neovim keeps its own copy and the markers hash the committed
# file. The fake Neovim below rewrites the lockfile like lazy.nvim does on every restore pass.
cat > "$scratch/brew/bin/nvim" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$NVIM_TEST_LOG"
case "$*" in
  *"Lazy! restore"*)
    lock="$XDG_CONFIG_HOME/nvim/lazy-lock.json"
    printf 'pass sees: %s\n' "$(head -n 1 "$lock")" >> "$NVIM_PASS_LOG"
    printf 'rewritten by lazy\n' > "$lock"
    ;;
esac
exit 0
EOF
export NVIM_PASS_LOG="$scratch/passes.log"
run_restore() { # run_restore DIR: run the restore task against the Neovim environment under DIR
  local dir="$1"
  HOME="$dir/home" XDG_CONFIG_HOME="$dir/home/.config" XDG_DATA_HOME="$dir/data" NVIM_BIN="$scratch/brew/bin/nvim" task -d "$root" nvim:restore > "$dir/out" 2>&1 \
    || { cat "$dir/out" >&2; return 1; }
}
new_env() {
  rm -rf "$1"
  mkdir -p "$1/home/.config/nvim" "$1/data/nvim/lazy/lazy.nvim"
}
printf 'committed-v1\n' > "$scratch/committed-lock.json"
cp "$scratch/committed-lock.json" "$scratch/committed-v1.json"

# A fresh machine has no lockfile copy: it is seeded, and the second pass starts from the committed
# contents again rather than from what the first pass left behind.
env1="$scratch/lock-fresh"
new_env "$env1"
: > "$NVIM_PASS_LOG"
run_restore "$env1"
test ! -L "$env1/home/.config/nvim/lazy-lock.json"
test "$(cat "$NVIM_PASS_LOG")" = "$(printf 'pass sees: committed-v1\npass sees: committed-v1')"
cmp -s "$scratch/committed-lock.json" "$scratch/committed-v1.json"

# lazy.nvim's rewrite of Neovim's copy must not make the restore look stale.
before="$(wc -l < "$NVIM_TEST_LOG")"
run_restore "$env1"
test "$(wc -l < "$NVIM_TEST_LOG")" -eq "$before"
test "$(cat "$env1/home/.config/nvim/lazy-lock.json")" = "rewritten by lazy"

# A changed committed lockfile restores again, from the new contents.
printf 'committed-v2\n' > "$scratch/committed-lock.json"
: > "$NVIM_PASS_LOG"
run_restore "$env1"
test "$(head -n 1 "$NVIM_PASS_LOG")" = "pass sees: committed-v2"
printf 'committed-v1\n' > "$scratch/committed-lock.json"

# Installs from before the lockfile was unstowed have a link into the checkout. It is replaced by a
# copy, even when the markers already match, and the checkout's file is never written through.
checkout="$scratch/lock-checkout"
mkdir -p "$checkout"
printf 'checkout-version\n' > "$checkout/lazy-lock.json"
cp "$checkout/lazy-lock.json" "$checkout/original"
env2="$scratch/lock-linked"
new_env "$env2"
run_restore "$env2"
rm "$env2/home/.config/nvim/lazy-lock.json"
ln -s "$checkout/lazy-lock.json" "$env2/home/.config/nvim/lazy-lock.json"
before="$(wc -l < "$NVIM_TEST_LOG")"
run_restore "$env2"
test "$(wc -l < "$NVIM_TEST_LOG")" -gt "$before"
test ! -L "$env2/home/.config/nvim/lazy-lock.json"
cmp -s "$checkout/lazy-lock.json" "$checkout/original"

# With a real Neovim, the Mason tool list itself must depend on Composer.
if command -v nvim >/dev/null 2>&1; then
  cat > "$scratch/tools.lua" <<LUA
local spec = dofile("$root/packages/nvim/.config/nvim/lua/plugins/mason.lua")
local has = false
-- spec[2] is mason-tool-installer, which receives the tool list as plain opts.
for _, t in ipairs(spec[2].opts.ensure_installed) do if t == "pint" then has = true end end
io.stdout:write(has and "pint" or "no-pint")
LUA
  nvim_bin="$(command -v nvim)"
  without="$(env -i PATH="$scratch/absent" "$nvim_bin" --headless -u NONE -l "$scratch/tools.lua" 2>&1)"
  with="$(env -i PATH="$scratch/composer-bin" "$nvim_bin" --headless -u NONE -l "$scratch/tools.lua" 2>&1)"
  test "$without" = no-pint
  test "$with" = pint

  # LazyVim and its extras add their own tools to mason's ensure_installed, and opts_extend only
  # concatenates the lists. LazyVim installs every entry without checking for an install in
  # progress, so a repeated name fails a fresh machine with "package is already installing".
  cat > "$scratch/dedupe.lua" <<LUA
local spec = dofile("$root/packages/nvim/.config/nvim/lua/plugins/mason.lua")
local opts = { ensure_installed = { "stylua", "shfmt", "shellcheck", "hadolint", "stylua" } }
spec[1].opts(nil, opts)
local seen, dup = {}, {}
for _, t in ipairs(opts.ensure_installed) do
  if seen[t] then dup[#dup + 1] = t end
  seen[t] = true
end
io.stdout:write(#dup == 0 and "unique" or ("duplicates:" .. table.concat(dup, ",")))
io.stdout:write(seen["stylua"] and seen["actionlint"] and " keeps-both" or " lost-entries")
LUA
  test "$(env -i PATH="$scratch/absent" "$nvim_bin" --headless -u NONE -l "$scratch/dedupe.lua" 2>&1)" = "unique keeps-both"
fi
printf 'Neovim restore failure check passed.\n'
