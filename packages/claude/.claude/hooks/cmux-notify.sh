#!/bin/bash
set -euo pipefail

# Only notify if cmux is available
command -v cmux >/dev/null 2>&1 || exit 0

cmux notify --title "Claude Code" --body "Session complete"
