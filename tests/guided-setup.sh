#!/bin/bash
# Guided setup: step wiring, status markers, ordering, and agreement with install-status.sh.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT

# Resolve the real task list before the stub shadows `task`.
task_list=$(task -d "$root" --list-all 2>/dev/null)
[[ -n "$task_list" ]] || { echo 'FAIL: could not list tasks' >&2; exit 1; }

export HOME="$scratch/home"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
mkdir -p "$HOME" "$scratch/bin"
export TASK_LOG="$scratch/task.log"
export GH_EXIT=1
export MISE_MISSING='node 22.0.0'
export GUM_CONFIRM_EXIT=0

# `task -d DIR args...` is recorded as `args...`.
cat > "$scratch/bin/task" <<'EOF'
#!/bin/bash
shift 2
printf '%s\n' "$*" >> "$TASK_LOG"
EOF
cat > "$scratch/bin/gum" <<'EOF'
#!/bin/bash
[ "$1" = confirm ] && exit "$GUM_CONFIRM_EXIT"
exit 0
EOF
cat > "$scratch/bin/gh" <<'EOF'
#!/bin/bash
exit "$GH_EXIT"
EOF
cat > "$scratch/bin/mise" <<'EOF'
#!/bin/bash
[ "$1" = ls ] && [ "$2" = --missing ] && printf '%s' "$MISE_MISSING"
exit 0
EOF
chmod +x "$scratch/bin/"*
export PATH="$scratch/bin:$PATH"

fail() { echo "FAIL: $*" >&2; exit 1; }
assert_eq() { [[ "$1" == "$2" ]] || fail "$3: expected [$2], got [$1]"; }

# Without a terminal the menu refuses to run.
if out=$(bash "$root/scripts/guided-setup.sh" < /dev/null 2>&1); then
  fail 'guided setup ran without a terminal'
fi
grep -q 'interactive terminal' <<<"$out" || fail 'missing non-interactive message'

# shellcheck source=scripts/guided-setup.sh
. "$root/scripts/guided-setup.sh"

state_of() {
  local rc=0
  step_state "$1" || rc=$?
  echo "$rc"
}

# --- Every menu step is wired to the intended tasks, and those tasks exist. ---
expected_tasks() {
  case "$1" in
    status) echo 'system:status' ;;
    github) printf 'github:auth\ngithub:ssh:test' ;;
    personal) echo 'system:post-install' ;;
    work) echo 'system:work-setup' ;;
    op-agent) echo 'mac:op:setup' ;;
    ssh-urls) echo 'mac:github:force_ssh' ;;
    nvim) echo 'nvim:restore' ;;
    mise) echo 'mise:install' ;;
    brew) echo 'brew:retry' ;;
    preview-defaults) echo 'mac:preview:defaults' ;;
    apply-defaults) echo 'mac:set:defaults' ;;
    shortcuts) printf 'mac:preview:shortcuts\nmac:set:shortcuts' ;;
    tinycast) printf '' ;;
    verify) echo 'system:check' ;;
    *) fail "step $1 has no expected tasks in this test" ;;
  esac
}

for id in $STEP_IDS; do
  [[ "$id" == quit ]] && continue
  : > "$TASK_LOG"
  run_step "$id" > "$scratch/step.out"
  expected="$(expected_tasks "$id")"
  assert_eq "$(cat "$TASK_LOG")" "$expected" "tasks run by step $id"
  while IFS= read -r name; do
    [[ -n "$name" ]] || continue
    grep -qE "^\* ${name}:" <<<"$task_list" || fail "step $id runs task $name, which does not exist"
  done <<<"$expected"
done

# Declining a confirmation runs nothing for the steps that ask first.
GUM_CONFIRM_EXIT=1
: > "$TASK_LOG"
run_step ssh-urls
run_step apply-defaults
assert_eq "$(cat "$TASK_LOG")" '' 'declined confirmations'
run_step shortcuts
assert_eq "$(cat "$TASK_LOG")" 'mac:preview:shortcuts' 'declined shortcut change still previews'
GUM_CONFIRM_EXIT=0

# GitHub login reminds about the key sync scopes that github:auth does not request.
run_step github | grep -q 'gh auth refresh -s admin:public_key,admin:ssh_signing_key' \
  || fail 'github step hides the key sync scope hint'

# --- Tinycast links match the README and are printed by the step. ---
while IFS= read -r url; do
  grep -qF "$url" "$root/README.md" || fail "README is missing $url"
  run_step tinycast | grep -qF "$url" || fail "tinycast step did not print $url"
done <<<"$TINYCAST_EXTENSION_URLS"
assert_eq "$(printf '%s\n' "$TINYCAST_EXTENSION_URLS" | wc -l | tr -d ' ')" 4 'tinycast link count'

# --- Status checks. ---
assert_eq "$(state_of work)" 2 'step without a check'

# Missing file must read as pending, not as "no check".
assert_eq "$(state_of personal)" 1 'personal setup without .gitconfig.local'
printf '# --- 1Password secrets (do not edit below) ---\n' > "$HOME/.gitconfig.local"
assert_eq "$(state_of personal)" 0 'personal setup with secrets block'

GH_EXIT=1
assert_eq "$(state_of github)" 1 'github signed out'
GH_EXIT=0
assert_eq "$(state_of github)" 0 'github signed in'

MISE_MISSING='node 22.0.0'
assert_eq "$(state_of mise)" 1 'mise with missing tools'
MISE_MISSING=''
assert_eq "$(state_of mise)" 0 'mise with every tool installed'

assert_eq "$(state_of brew)" 1 'brew bundle never installed'
mkdir -p "$XDG_STATE_HOME/dotfiles"
touch "$XDG_STATE_HOME/dotfiles/full-brew-pending"
assert_eq "$(state_of brew)" 1 'brew bundle incomplete'
rm "$XDG_STATE_HOME/dotfiles/full-brew-pending"
touch "$XDG_STATE_HOME/dotfiles/full-brew-complete"
assert_eq "$(state_of brew)" 0 'brew bundle complete'

# Neovim is done only when both markers match the current lockfile.
assert_eq "$(state_of nvim)" 1 'neovim without a lockfile'
mkdir -p "$XDG_CONFIG_HOME/nvim" "$XDG_DATA_HOME/nvim/lazy/lazy.nvim"
printf '{"plugin":"one"}\n' > "$XDG_CONFIG_HOME/nvim/lazy-lock.json"
assert_eq "$(state_of nvim)" 1 'neovim before restore'
hash=$(shasum -a 256 "$XDG_CONFIG_HOME/nvim/lazy-lock.json" | cut -d' ' -f1)
printf '%s' "$hash" > "$XDG_DATA_HOME/nvim/.lazy-restore-hash"
assert_eq "$(state_of nvim)" 1 'neovim plugins restored but tools missing'
printf '%s' "$hash" > "$XDG_DATA_HOME/nvim/.lazy-tools-hash"
assert_eq "$(state_of nvim)" 0 'neovim fully restored'
printf '{"plugin":"two"}\n' > "$XDG_CONFIG_HOME/nvim/lazy-lock.json"
assert_eq "$(state_of nvim)" 1 'neovim after the lockfile changed'
printf '{"plugin":"one"}\n' > "$XDG_CONFIG_HOME/nvim/lazy-lock.json"

# --- Menu lines, ordering, and reverse lookup. ---
assert_eq "$(menu_line nvim)" '✓ Restore Neovim plugins and tools' 'done marker'
assert_eq "$(menu_line work)" '· Set up work accounts' 'unchecked marker'
GH_EXIT=1
assert_eq "$(menu_line github)" '○ Sign in to GitHub and test SSH' 'pending marker'

# GitHub sign in comes before the personal setup that needs it.
rm "$HOME/.gitconfig.local"
assert_eq "$(next_pending_step)" github 'first pending step'
GH_EXIT=0
assert_eq "$(next_pending_step)" personal 'next pending step after github'
printf '# --- 1Password secrets (do not edit below) ---\n' > "$HOME/.gitconfig.local"
MISE_MISSING=''
assert_eq "$(next_pending_step)" '' 'no pending step when every check passes'

labels=''
for id in $STEP_IDS; do
  line="$(menu_line "$id")"
  assert_eq "$(step_for_line "$line")" "$id" "round trip for $id"
  labels="$labels$(step_label "$id")"$'\n'
done
assert_eq "$(printf '%s' "$labels" | sort | uniq -d)" '' 'duplicate menu labels'
# gum may trim leading whitespace from the selected line.
assert_eq "$(step_for_line '  Quit')" '' 'unknown line'
assert_eq "$(step_for_line "$(menu_line quit)")" quit 'quit line'

# --- install-status.sh agrees with the shared checks. ---
printf '{"plugin":"two"}\n' > "$XDG_CONFIG_HOME/nvim/lazy-lock.json"
bash "$root/scripts/install-status.sh" > "$scratch/status.out" 2>&1 || true
grep -q '○ Neovim plugins restored — run task nvim:restore' "$scratch/status.out" || fail 'status misses stale neovim restore'
grep -q '○ Neovim parsers and tools installed' "$scratch/status.out" || fail 'status misses stale neovim tools'
printf '{"plugin":"one"}\n' > "$XDG_CONFIG_HOME/nvim/lazy-lock.json"
bash "$root/scripts/install-status.sh" > "$scratch/status.out" 2>&1 || true
grep -q '✓ Neovim plugins restored' "$scratch/status.out" || fail 'status misses restored neovim plugins'
grep -q '✓ Neovim parsers and tools installed' "$scratch/status.out" || fail 'status misses installed neovim tools'

printf 'Guided setup steps, markers, ordering and status agreement passed.\n'
