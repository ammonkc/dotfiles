#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/home/project" "$scratch/home/.aws/sso/cache" "$scratch/bin"
touch "$scratch/home/project/compose.yml"
cat > "$scratch/bin/docker" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$DOCKER_CALLS_FILE"
if [ "${DOCKER_FAIL:-0}" = 1 ]; then exit 1; fi
cat "$DOCKER_PS_FILE"
EOF
chmod +x "$scratch/bin/docker"

run_context() {
  HOME="$scratch/home" DOCKER_PS_FILE="$scratch/ps.json" DOCKER_CALLS_FILE="$scratch/calls" \
    POSH_CONTEXT_FILE="$root/packages/zsh/.config/zsh/functions/set_poshcontext" \
    PATH="$scratch/bin:$PATH" zsh -f -c '
      cd "$HOME/project"
      source "$POSH_CONTEXT_FILE"
      set_poshcontext
      print -r -- "${DOCKER_COMPOSE_STATUS:-unset}|${DOCKER_COMPOSE_STATE:-unset}|${AWS_AUTH_STATUS:-unset}"
    '
}
assert_context() {
  : > "$scratch/calls"
  actual="$(run_context)"
  if [ "$actual" != "$1" ]; then
    printf 'Expected %s, got %s\n' "$1" "$actual" >&2
    exit 1
  fi
  test "$(wc -l < "$scratch/calls" | tr -d ' ')" -eq 1
  grep -qx 'compose ps -a --format json' "$scratch/calls"
}

printf '[{"State":"running"},{"State":"exited"}]\n' > "$scratch/ps.json"
assert_context '1/2|partial|unset'
printf '{"State":"running"}\n{"State":"running"}\n' > "$scratch/ps.json"
assert_context '2/2|up|unset'
printf '[{"State":"exited"}]\n' > "$scratch/ps.json"
assert_context '0/1|down|unset'
printf '[]\n' > "$scratch/ps.json"
assert_context 'unset|none|unset'

printf '[{"State":"running"}]\n' > "$scratch/ps.json"
printf '{"accessToken":"synthetic","expiresAt":"2099-01-01T00:00:00.000Z"}\n' > "$scratch/home/.aws/sso/cache/token.json"
assert_context '1/1|up|active'
printf '{"accessToken":"synthetic","expiresAt":"2000-01-01T00:00:00Z"}\n' > "$scratch/home/.aws/sso/cache/token.json"
assert_context '1/1|up|unset'

export DOCKER_FAIL=1
: > "$scratch/calls"
test "$(run_context)" = 'unset|unset|unset'
unset DOCKER_FAIL
printf 'Prompt context checks passed.\n'
