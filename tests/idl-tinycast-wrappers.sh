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

for launcher in tinycast raycast; do
  scripts="$root/packages/$launcher/.config/$launcher/script-commands"
  HOME="$scratch" IDL_ARGS_FILE="$scratch/up-args" /bin/bash "$scripts/idl-up.sh" main example.test 'queue, --build'
  printf '%s\n' main example.test --profile queue --build > "$scratch/expected-up"
  diff -u "$scratch/expected-up" "$scratch/up-args"

  HOME="$scratch" IDL_ARGS_FILE="$scratch/down-args" /bin/bash "$scripts/idl-down.sh" main example.test
  printf '%s\n' main example.test > "$scratch/expected-down"
  diff -u "$scratch/expected-down" "$scratch/down-args"
done

# Keep script behavior in sync; only launcher-specific icon paths may differ.
python3 - "$root" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1])
raycast = root / "packages/raycast/.config/raycast/script-commands"
tinycast = root / "packages/tinycast/.config/tinycast/script-commands"
raycast_names = {p.name for p in raycast.glob("*.sh")}
tinycast_names = {p.name for p in tinycast.glob("*.sh")}
assert raycast_names == tinycast_names, (raycast_names - tinycast_names, tinycast_names - raycast_names)
for name in sorted(raycast_names):
    raycast_text = (raycast / name).read_text().replace(".config/raycast/script-commands", ".config/launcher/script-commands").strip()
    tinycast_text = (tinycast / name).read_text().replace(".config/tinycast/script-commands", ".config/launcher/script-commands").strip()
    assert raycast_text == tinycast_text, f"Script command drift: {name}"
PY

printf 'Tinycast and Raycast script command parity passed.\n'
