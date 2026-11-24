#!/bin/bash
# Current Homebrew refuses to load formulae from untrusted third-party taps. Every such tap
# used by a Brewfile must be listed in TRUSTED_TAPS, and the bundle tasks must trust them first.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT

trusted="$(sed -n 's/^  TRUSTED_TAPS: //p' "$root/taskfiles/brew.yml")"
test -n "$trusted"

# Third-party taps are declared with `tap` or implied by owner/repo/name entries.
used="$(
  { sed -n "s/^tap '\([^']*\)'.*/\1/p" "$root/Brewfile" "$root/Brewfile.core"
    sed -n "s#^\(brew\|cask\) '\([^'/]*/[^'/]*\)/[^'/]*'.*#\2#p" "$root/Brewfile" "$root/Brewfile.core"
  } | grep -v '^homebrew/' | sort -u
)"
test -n "$used"
for tap in $used; do
  case " $trusted " in
    *" $tap "*) ;;
    *) echo "Brewfile uses tap $tap but it is not in TRUSTED_TAPS" >&2; exit 1 ;;
  esac
done

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
  cat > "$scratch/brew" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >> "$BREW_TEST_LOG"
exit 0
STUB
  chmod +x "$scratch/brew"
  BREW_TEST_LOG="$scratch/log" BREW_BIN="$scratch/brew" task -d "$root" brew:trust:taps >/dev/null
  for tap in $trusted; do
    grep -qx "tap $tap" "$scratch/log"
    grep -qx "trust --tap $tap" "$scratch/log"
  done
  # Older Homebrew without `brew trust` must not fail the install.
  cat > "$scratch/brew" <<'STUB'
#!/bin/sh
[ "$1" = trust ] && exit 1
printf '%s\n' "$*" >> "$BREW_TEST_LOG"
STUB
  : > "$scratch/log"
  BREW_TEST_LOG="$scratch/log" BREW_BIN="$scratch/brew" task -d "$root" brew:trust:taps >/dev/null
  test ! -s "$scratch/log"
fi
printf 'Brew tap trust checks passed.\n'
