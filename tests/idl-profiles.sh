#!/bin/bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/bin" "$scratch/worktrees/main"
cat > "$scratch/bin/docker" <<'EOF'
#!/bin/bash
printf '%s\n' "$@" > "$IDL_DOCKER_ARGS_FILE"
EOF
chmod +x "$scratch/bin/docker"

helpers="$root/packages/bin/.local/bin"
export PATH="$scratch/bin:$PATH" IDL_WORKTREES_DIR="$scratch/worktrees"
export IDL_DOCKER_ARGS_FILE="$scratch/up-args"
/bin/bash "$helpers/idl-up" --profile queue main example.test > /dev/null
printf '%s\n' compose -f docker-compose.yaml --profile sftp --profile queue up --detach --remove-orphans > "$scratch/expected-up"
diff -u "$scratch/expected-up" "$scratch/up-args"

export IDL_DOCKER_ARGS_FILE="$scratch/down-args"
/bin/bash "$helpers/idl-down" main example.test > /dev/null
printf '%s\n' compose -f docker-compose.yaml --profile sftp --profile queue down > "$scratch/expected-down"
diff -u "$scratch/expected-down" "$scratch/down-args"

for helper in idl-up idl-down; do
    if /bin/bash "$helpers/$helper" --profile php8-work main example.test > "$scratch/invalid-output" 2>&1; then
        echo "$helper accepted an obsolete Compose profile" >&2
        exit 1
    fi
    if ! /usr/bin/grep -q 'available: sftp, queue' "$scratch/invalid-output"; then
        echo "$helper did not explain the available profiles" >&2
        exit 1
    fi
done

printf 'IDL Compose profile checks passed.\n'
