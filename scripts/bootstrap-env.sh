#!/bin/sh
# Environment needed before the user's interactive shell configuration is loaded.
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_BIN_DIR="${XDG_BIN_DIR:-$HOME/.local/bin}"
export GNUPGHOME="${GNUPGHOME:-$XDG_DATA_HOME/gnupg}"

if [ "$(uname -s)" = Darwin ]; then
  if [ "$(uname -m)" != arm64 ]; then
    echo "This macOS setup supports Apple Silicon in a native arm64 shell only." >&2
    return 1 2>/dev/null || exit 1
  fi
  PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
  export PATH
fi
