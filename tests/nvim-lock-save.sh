#!/bin/bash
# `task nvim:lock:save` copies Neovim's own lazy-lock.json into the development checkout. It must never
# write into the deployed checkout (that is the dirty-checkout problem the unstowed lockfile avoids)
# and never commit.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT

relative=packages/nvim/.config/nvim/lazy-lock.json
home="$scratch/home"
dev="$scratch/dev"
deployed="$home/.dotfiles"
mkdir -p "$home/.config/nvim"
for checkout in "$dev" "$deployed"; do
  mkdir -p "$checkout/$(dirname "$relative")"
  printf 'committed\n' > "$checkout/$relative"
  git -C "$checkout" init -q
  git -C "$checkout" add .
  git -C "$checkout" -c user.name=Test -c user.email=test@example.com commit -qm initial
done
printf 'updated by lazy.nvim\n' > "$home/.config/nvim/lazy-lock.json"

save() {
  HOME="$home" XDG_CONFIG_HOME="$home/.config" DOTFILES_SOURCE_DIR="${SOURCE:-$dev}" DOTFILES_DEPLOY_DIR="$deployed" \
    task -d "$root" nvim:lock:save
}
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

# The development checkout gets the file and a diff, and nothing is committed.
save > "$scratch/out" 2>&1 || { cat "$scratch/out" >&2; fail 'save failed'; }
test "$(cat "$dev/$relative")" = 'updated by lazy.nvim'
grep -q 'lazy-lock.json' "$scratch/out" || fail 'no diff shown'
test "$(git -C "$dev" rev-list --count HEAD)" -eq 1 || fail 'a commit was made'
test -n "$(git -C "$dev" status --porcelain)" || fail 'the change is not left uncommitted'

# The deployed checkout is never touched.
test "$(cat "$deployed/$relative")" = committed
test -z "$(git -C "$deployed" status --porcelain)" || fail 'deployed checkout was dirtied'

# Saving the same file again changes nothing.
save > "$scratch/out" 2>&1
grep -q 'already matches' "$scratch/out" || fail 'no no-op message'

# Pointing at the deployed checkout is refused, including through a symlink to it.
ln -s "$deployed" "$scratch/deployed-link"
for target in "$deployed" "$scratch/deployed-link"; do
  if SOURCE="$target" save > "$scratch/out" 2>&1; then
    fail "wrote into the deployed checkout through $target"
  fi
  grep -q 'deployed checkout' "$scratch/out" || fail 'wrong refusal message for the deployed checkout'
  test "$(cat "$deployed/$relative")" = committed || fail 'deployed checkout file changed'
done

# A directory that is not a git checkout is refused.
mkdir "$scratch/not-a-checkout"
if SOURCE="$scratch/not-a-checkout" save > "$scratch/out" 2>&1; then
  fail 'saved into a directory that is not a checkout'
fi
test ! -e "$scratch/not-a-checkout/$relative"

# A lockfile that is still a link into a checkout is refused: it is not Neovim's own copy yet.
printf 'newer\n' > "$scratch/linked-target"
rm "$home/.config/nvim/lazy-lock.json"
ln -s "$scratch/linked-target" "$home/.config/nvim/lazy-lock.json"
if save > "$scratch/out" 2>&1; then
  fail 'saved a lockfile that is still a link'
fi
grep -q 'nvim:restore' "$scratch/out" || fail 'no hint to run nvim:restore'
test "$(cat "$dev/$relative")" = 'updated by lazy.nvim'

printf 'nvim:lock:save writes only to the development checkout and never commits.\n'
