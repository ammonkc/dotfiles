#!/bin/bash
# Task runs commands in its own built-in shell, which has no umask builtin. A bare umask in a
# task command block fails with "umask: unsupported builtin", so those blocks must run in bash.
# On macOS the real post-install flow also runs against a stub op in a scratch home.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"

python3 -I - "$root" <<'PY'
import re, sys
from pathlib import Path

root = Path(sys.argv[1])
errors = []
for path in sorted(root.glob("taskfiles/*.yml")) + [root / "taskfile.dist.yml"]:
    in_bash_script = False
    for lineno, line in enumerate(path.read_text().splitlines(), 1):
        if "<<'SCRIPT'" in line:
            in_bash_script = True
        elif line.strip() == "SCRIPT":
            in_bash_script = False
        elif re.match(r"^\s*umask\b", line) and not in_bash_script:
            errors.append(f"{path.relative_to(root)}:{lineno}: bare umask in a task command (run the block with /bin/bash -c)")
if errors:
    print("\n".join(errors), file=sys.stderr)
    sys.exit(1)
PY

if [ "$(uname -s)" = Darwin ] && command -v jq >/dev/null 2>&1; then
  scratch="$(mktemp -d)"
  trap 'rm -rf "$scratch"' EXIT
  mkdir -p "$scratch/bin" "$scratch/home"
  cat > "$scratch/bin/op" <<'STUB'
#!/bin/sh
case "$*" in
  "account list"*|"account get"*) exit 0 ;;
  "user get --me"*) echo '{"email":"test@example.test","name":"Test User"}' ;;
  "item get id_ed25519"*) echo "ssh-ed25519 AAAATESTKEY test" ;;
  "item get github"*"username"*) echo "testuser" ;;
  "item get github"*"token"*) echo "ghp_testtoken" ;;
  *) exit 1 ;;
esac
STUB
  chmod +x "$scratch/bin/op"
  home="$scratch/home"
  # Never reach the real home, keychain or GitHub login.
  env HOME="$home" XDG_CONFIG_HOME="$home/.config" XDG_DATA_HOME="$home/.local/share" \
    XDG_STATE_HOME="$home/.local/state" GH_CONFIG_DIR="$home/.config/gh" PATH="$scratch/bin:$PATH" \
    task -d "$root" system:post-install > "$scratch/out.txt" 2>&1 || { cat "$scratch/out.txt" >&2; exit 1; }
  grep -q 'Post-installation complete' "$scratch/out.txt"
  # GNU stat (first on PATH in CI) takes -c; BSD stat takes -f.
  mode() { stat -c %a "$1" 2>/dev/null || stat -f %Lp "$1"; }
  for file in .gitconfig.local .env.local; do
    test "$(mode "$home/$file")" = 600
  done
  # Signing is switched on only once a key exists, in the generated 1Password block.
  grep -q 'signingkey = ssh-ed25519 AAAATESTKEY test' "$home/.gitconfig.local"
  awk '/^\[commit\]/ { c = 1 } c && /gpgsign = true/ { ok = 1 } END { exit !ok }' "$home/.gitconfig.local"
  test -d "$home/Developer/repos"
fi
printf 'Post-install secrets checks passed.\n'
