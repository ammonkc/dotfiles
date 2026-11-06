#!/usr/bin/env bash
# Protect automatic discovery and failure propagation in the test infrastructure.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/scripts" "$scratch/tests"
cp "$root/scripts/test.sh" "$root/scripts/check-shells.py" "$scratch/scripts/"
printf '#!/bin/bash\nexit 1\n' > "$scratch/tests/a-failure.sh"
printf '#!/bin/bash\necho later-suite-ran\n' > "$scratch/tests/z-success.sh"
if /bin/bash "$scratch/scripts/test.sh" > "$scratch/result" 2>&1; then
  echo 'Runner hid a failed suite' >&2
  exit 1
fi
grep -q 'later-suite-ran' "$scratch/result"
grep -q '2 suites; 1 failed' "$scratch/result"
git -C "$scratch" init -q
printf '#!/bin/bash\nif\n' > "$scratch/tests/z-success.sh"
if python3 "$scratch/scripts/check-shells.py" > "$scratch/syntax" 2>&1; then
  echo 'Syntax checker accepted a malformed later file' >&2
  exit 1
fi
grep -q 'FAIL tests/z-success.sh' "$scratch/syntax"
printf 'Test discovery, continued execution and failure propagation passed.\n'
