#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/.local/bin"
cat > "$scratch/.local/bin/idl-up" <<'EOF'
#!/bin/bash
printf '%s\n' "$@" > "$IDL_ARGS_FILE"
EOF
cp "$scratch/.local/bin/idl-up" "$scratch/.local/bin/idl-down"
chmod +x "$scratch/.local/bin/idl-up" "$scratch/.local/bin/idl-down"

scripts="$root/packages/tinycast/.config/tinycast/script-commands"
HOME="$scratch" IDL_ARGS_FILE="$scratch/up-args" /bin/bash "$scripts/idl-up.sh" main example.test 'queue, --build'
printf '%s\n' main example.test --profile queue --build > "$scratch/expected-up"
diff -u "$scratch/expected-up" "$scratch/up-args"

HOME="$scratch" IDL_ARGS_FILE="$scratch/down-args" /bin/bash "$scripts/idl-down.sh" main example.test
printf '%s\n' main example.test > "$scratch/expected-down"
diff -u "$scratch/expected-down" "$scratch/down-args"
printf 'IDL Tinycast wrapper checks passed.\n'
