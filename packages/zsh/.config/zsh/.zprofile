#!/usr/bin/env zsh
# Zsh configuration for non-interactive shells
# in interactive shells, both `~/.zprofile` and `~/.zshrc` are loaded.
# to avoid activating tools twice, a conditional can be used that checks the
# `$-` special parameter. `$-` will contain `i` if the shell is interactive.
# https://zsh.sourceforge.io/Doc/Release/Files.html
# https://zsh.sourceforge.io/Doc/Release/Parameters.html
[[ $- == *i* ]] && return

# Set XDG base paths if you want to re-home Zsh.
export XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}
export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
export XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
export XDG_STATE_HOME=${XDG_STATE_HOME:-$HOME/.local/state}
export XDG_BIN_DIR=${XDG_BIN_DIR:-$HOME/.local/bin}
export XDG_PROJECTS_DIR=${XDG_PROJECTS_DIR:-$HOME/Projects}

# Create XDG directories if they do not exist
mkdir -p "$(dirname $XDG_CONFIG_HOME)"
mkdir -p "$(dirname $XDG_CACHE_HOME)"
mkdir -p "$(dirname $XDG_DATA_HOME)"
mkdir -p "$(dirname $XDG_STATE_HOME)"
mkdir -p "$(dirname $XDG_BIN_DIR)"
