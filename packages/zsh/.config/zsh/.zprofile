#!/usr/bin/env zsh
# Zsh configuration for non-interactive shells
# in interactive shells, both `~/.zprofile` and `~/.zshrc` are loaded.
# to avoid activating tools twice, a conditional can be used that checks the
# `$-` special parameter. `$-` will contain `i` if the shell is interactive.
# https://zsh.sourceforge.io/Doc/Release/Files.html
# https://zsh.sourceforge.io/Doc/Release/Parameters.html
[[ $- == *i* ]] && return

# XDG variables and directories are set up in ~/.zshenv
# This file is for login-shell-specific configuration only
