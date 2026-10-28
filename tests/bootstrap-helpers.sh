#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT

target="$scratch/env.local"
printf 'KEEP=1\n' > "$target"
chmod 644 "$target"
printf 'TOKEN=first\n' | bash "$root/scripts/secret-block.sh" "$target" '# managed'
printf 'TOKEN=second\n' | bash "$root/scripts/secret-block.sh" "$target" '# managed'
test "$(grep -c '^# managed$' "$target")" -eq 1
test "$(grep -c '^TOKEN=second$' "$target")" -eq 1
! grep -q 'TOKEN=first' "$target"
grep -q '^KEEP=1$' "$target"
test "$(stat -c %a "$target" 2>/dev/null || stat -f %Lp "$target")" = 600

# Older work setup appended this setting inside the personal secrets section.
# Refreshing that section must move it ahead of the marker and keep it once.
printf 'KEEP=1\n# managed\nTOKEN=old\nexport OP_WORK_ACCOUNT="work.example"\n' > "$target"
printf 'TOKEN=new\n' | bash "$root/scripts/secret-block.sh" "$target" '# managed' 'export OP_WORK_ACCOUNT='
printf 'TOKEN=newer\n' | bash "$root/scripts/secret-block.sh" "$target" '# managed' 'export OP_WORK_ACCOUNT='
test "$(grep -c '^export OP_WORK_ACCOUNT="work.example"$' "$target")" -eq 1
test "$(grep -c '^# managed$' "$target")" -eq 1
grep -q '^TOKEN=newer$' "$target"
! grep -q '^TOKEN=old$' "$target"
! grep -q '^TOKEN=new$' "$target"
awk '/^export OP_WORK_ACCOUNT=/ { account = NR } /^# managed$/ { marker = NR } END { exit !(account > 0 && marker > account) }' "$target"

mkdir "$scratch/bin"
cat > "$scratch/bin/curl" <<'EOF'
#!/bin/bash
exit 22
EOF
chmod +x "$scratch/bin/curl"
if PATH="$scratch/bin:$PATH" bash "$root/scripts/download-installer.sh" https://taskfile.dev/install.sh; then
  echo 'Downloader executed after curl failure' >&2
  exit 1
fi
cat > "$scratch/bin/curl" <<'EOF'
#!/bin/bash
while [ "$#" -gt 0 ]; do
  if [ "$1" = --output ]; then
    printf '#!/bin/bash\necho executed > "%s"\nif\n' "$TEST_EXECUTED_MARKER" > "$2"
    exit 0
  fi
  shift
done
exit 2
EOF
chmod +x "$scratch/bin/curl"
if TEST_EXECUTED_MARKER="$scratch/executed" PATH="$scratch/bin:$PATH" bash "$root/scripts/download-installer.sh" https://taskfile.dev/install.sh; then
  echo 'Downloader accepted a malformed shell script' >&2
  exit 1
fi
test ! -e "$scratch/executed"
if bash "$root/scripts/download-installer.sh" https://example.com/install.sh; then
  echo 'Downloader accepted an unapproved URL' >&2
  exit 1
fi
printf 'Bootstrap helper checks passed.\n'
