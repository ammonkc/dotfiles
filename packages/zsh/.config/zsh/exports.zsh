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

# npm
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/config/npmrc"
export NPM_CONFIG_CACHE="$XDG_CACHE_HOME/npm"

# pnpm
export PNPM_HOME="$XDG_DATA_HOME/pnpm"

# node (node REPL history)
export NODE_REPL_HISTORY="$XDG_STATE_HOME/node_repl_history"

# Subversion (svn)
export SUBVERSION_HOME="$XDG_CONFIG_HOME/subversion"

# Python
export PYTHONSTARTUP="$XDG_CONFIG_HOME/python/pythonrc"
export PYTHON_HISTORY="$XDG_STATE_HOME/python_history"

# Cargo (Rust)
export CARGO_HOME="$XDG_DATA_HOME/cargo"

# Go
export GOPATH="$XDG_DATA_HOME/go"
export GOMODCACHE="$XDG_CACHE_HOME/go/mod"

# Gradle
export GRADLE_USER_HOME="$XDG_DATA_HOME/gradle"

# GEM
export GEMRC="$XDG_CONFIG_HOME/gem/config"
export GEM_HOME="$XDG_DATA_HOME/gem"
export GEM_PATH="$GEM_HOME"

# AWS cli
export AWS_CONFIG_FILE="${AWS_CONFIG_FILE:-$XDG_CONFIG_HOME/aws/config}"
export AWS_SHARED_CREDENTIALS_FILE="${AWS_SHARED_CREDENTIALS_FILE:-$XDG_CONFIG_HOME/aws/credentials}"

# Docker
export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"

# bat (cat replacement) - Uses XDG by default, but can override
export BAT_CONFIG_PATH="$XDG_CONFIG_HOME/bat/config"
export BAT_THEME="Catppuccin Mocha"

# ripgrep - Uses XDG by default for config
export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/config"

# httpie - Native XDG support
export HTTPIE_CONFIG_DIR="$XDG_CONFIG_HOME/httpie"

# GitHub CLI - Native XDG support ($XDG_CONFIG_HOME/gh)
# GH_CONFIG_DIR can override if needed
# export GH_CONFIG_DIR="$XDG_CONFIG_HOME/gh"

# mise (asdf replacement) - Uses XDG by default
# These override defaults if you want custom locations
# export MISE_CONFIG_DIR="$XDG_CONFIG_HOME/mise"
# export MISE_DATA_DIR="$XDG_DATA_HOME/mise"
# export MISE_CACHE_DIR="$XDG_CACHE_HOME/mise"

# atuin (shell history) - Native XDG support
# export ATUIN_CONFIG_DIR="$XDG_CONFIG_HOME/atuin"

# zoxide (cd replacement) - Uses XDG by default
# export _ZO_DATA_DIR="$XDG_DATA_HOME/zoxide"

# tmux
export TMUX_PLUGIN_MANAGER_PATH="$XDG_DATA_HOME/tmux/plugins"

# less
export LESSHISTFILE="$XDG_STATE_HOME/less/history"

# PostgreSQL (if using psql)
export PSQL_HISTORY="$XDG_STATE_HOME/psql_history"

# MySQL (if using mysql cli)
export MYSQL_HISTFILE="$XDG_STATE_HOME/mysql_history"

# FastFetch
export FASTFETCH_STARTUP="${FASTFETCH_STARTUP:-true}"

# Make Terminal.app behave.
if [[ "$OSTYPE" == darwin* ]]; then
  export SHELL_SESSIONS_DISABLE=1
fi


# -----------------------
# ---- Local config -----
# -----------------------
[[ -f $HOME/.env.local ]] && source $HOME/.env.local || true
