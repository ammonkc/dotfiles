# -------
# Editors
# -------
export EDITOR="${EDITOR:-nvim}"
export VISUAL="${VISUAL:-nvim}"
export PAGER="${PAGER:-less}"

export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# Locale
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# Homebrew
export HOMEBREW_NO_ENV_HINTS=1

# ZSH
export SHELL_SESSION_DIR="$XDG_STATE_HOME/zsh/sessions"

# Enable SSH Agent for all hosts
export SSH_AUTH_SOCK=~/.1password/agent.sock

# Cursor
export CURSOR_CONFIG_DIR="$XDG_CONFIG_HOME/cursor"

# wget
export WGETRC="$XDG_CONFIG_HOME/wget/wgetrc"

# gnupg
export GNUPGHOME="$XDG_DATA_HOME/gnupg"

# GEM
export GEMRC="$XDG_CONFIG_HOME/gem/config"
export GEM_HOME="$XDG_DATA_HOME/gem"
export GEM_PATH="$GEM_HOME"

# pnpm
export PNPM_HOME="$XDG_DATA_HOME/pnpm"

# AWS cli
export AWS_CONFIG_FILE="${AWS_CONFIG_FILE:-XDG_CONFIG_HOME/aws/config}"
export AWS_SHARED_CREDENTIALS_FILE="${AWS_SHARED_CREDENTIALS_FILE:-XDG_CONFIG_HOME/aws/credentials}"

# FastFetch
export FASTFETCH_STARTUP="${FASTFETCH_STARTUP:-true}"

# Make Terminal.app behave.
if [[ "$OSTYPE" == darwin* ]]; then
  export SHELL_SESSIONS_DISABLE=1
fi


# -----------------------
# ---- Local config -----
# -----------------------
[[ -f ~/.env.local ]] && source ~/.env.local || true
