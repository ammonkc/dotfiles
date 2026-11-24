#!/bin/bash
# Current Homebrew refuses to load formulae from untrusted third-party taps. Every such tap
# used by a Brewfile must be listed for the profile that installs it, and the bundle tasks
# must trust them first.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT

core_listed="$(sed -n 's/^  TRUSTED_TAPS_CORE: //p' "$root/taskfiles/brew.yml")"
full_listed="$(sed -n 's/^  TRUSTED_TAPS_FULL: //p' "$root/taskfiles/brew.yml")"
test -n "$core_listed"
test -n "$full_listed"

# Third-party taps are declared with `tap` or implied by owner/repo/name entries. Entries can be
# indented (casks sit inside an `if OS.mac?` block) and quoted with either quote style.
python3 -I - "$root" "$core_listed" "$full_listed" <<'PY'
import re, sys

root, core_listed, full_listed = sys.argv[1], sys.argv[2].split(), sys.argv[3].split()

def used(path):
    taps = set()
    for line in open(path):
        m = re.match(r"""^\s*(tap|brew|cask)\s+['"]([^'"]+)['"]""", line)
        if not m:
            continue
        kind, name = m.groups()
        parts = name.split("/")
        if kind == "tap" and len(parts) == 2:
            taps.add(name)
        elif kind != "tap" and len(parts) >= 3:
            taps.add("/".join(parts[:2]))
    return {t for t in taps if not t.startswith("homebrew/")}

core_used = used(f"{root}/Brewfile.core")
full_used = used(f"{root}/Brewfile")
assert core_used and full_used, "Brewfile parsing found no third-party taps"

errors = []
for tap in sorted(core_used - set(core_listed)):
    errors.append(f"Brewfile.core uses tap {tap} but it is not in TRUSTED_TAPS_CORE")
for tap in sorted(full_used - set(core_listed) - set(full_listed)):
    errors.append(f"Brewfile uses tap {tap} but it is not in TRUSTED_TAPS_CORE or TRUSTED_TAPS_FULL")
for tap in sorted(set(core_listed) | set(full_listed)):
    if tap not in core_used | full_used:
        errors.append(f"{tap} is trusted but no Brewfile uses it")
for tap in sorted(set(full_listed) & core_used):
    errors.append(f"{tap} is a core tap and belongs in TRUSTED_TAPS_CORE only")
if errors:
    print("\n".join(errors), file=sys.stderr)
    sys.exit(1)
PY

# Both bundle tasks must run the trust task before brew bundle.
python3 -I - "$root/taskfiles/brew.yml" <<'PY'
import re, sys
text = open(sys.argv[1]).read()
for name in ("retry", "install:tools"):
    m = re.search(rf"^  {re.escape(name)}:\n(.*?)(?=^  \S|\Z)", text, re.M | re.S)
    body = m.group(1)
    assert "task: trust:taps" in body, f"{name} does not run trust:taps"
    assert body.index("task: trust:taps") < body.index("brew bundle"), f"{name} bundles before trusting"
PY

# On macOS, run the real task against a stub brew and check what it was asked to do.
if [ "$(uname -s)" = Darwin ]; then
  make_stub() {
    cat > "$scratch/brew" <<STUB
#!/bin/sh
$1
printf '%s\n' "\$*" >> "\$BREW_TEST_LOG"
exit 0
STUB
    chmod +x "$scratch/brew"
  }
  run_trust() {
    : > "$scratch/log"
    BREW_TEST_LOG="$scratch/log" BREW_BIN="$scratch/brew" task -d "$root" brew:trust:taps "$@" >/dev/null 2>"$scratch/err"
  }

  make_stub ''
  # The core profile touches only the core taps.
  DOTFILES_PROFILE=core run_trust
  for tap in $core_listed; do
    grep -qx "tap $tap" "$scratch/log"
    grep -qx "trust --tap $tap" "$scratch/log"
  done
  # (A bare `! grep` would not trip set -e, so test with if.)
  for tap in $full_listed; do
    if grep -q " $tap\$" "$scratch/log"; then
      echo "core profile touched full tap $tap" >&2
      exit 1
    fi
  done
  # The full profile (the default) trusts every tap, and an explicit PROFILE wins over the environment.
  DOTFILES_PROFILE=core run_trust PROFILE=full
  for tap in $core_listed $full_listed; do
    grep -qx "tap $tap" "$scratch/log"
    grep -qx "trust --tap $tap" "$scratch/log"
  done
  run_trust
  grep -qx "trust --tap $(printf '%s\n' $full_listed | head -n 1)" "$scratch/log"

  # One unreachable tap is reported and skipped; the remaining taps are still trusted.
  first="$(printf '%s\n' $full_listed | head -n 1)"
  make_stub "[ \"\$1 \$2\" = \"tap $first\" ] && exit 1"
  run_trust
  grep -q "could not tap and trust $first" "$scratch/err"
  for tap in $core_listed $full_listed; do
    [ "$tap" = "$first" ] || grep -qx "trust --tap $tap" "$scratch/log"
  done

  # Older Homebrew without `brew trust` must not fail the install.
  cat > "$scratch/brew" <<'STUB'
#!/bin/sh
[ "$1" = trust ] && exit 1
printf '%s\n' "$*" >> "$BREW_TEST_LOG"
STUB
  run_trust
  test ! -s "$scratch/log"
fi
printf 'Brew tap trust checks passed.\n'
