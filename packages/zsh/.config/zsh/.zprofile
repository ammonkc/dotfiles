#!/usr/bin/env zsh
# Login-shell configuration. This file runs for interactive and non-interactive
# login shells; interactive startup continues in .zshrc.
# https://zsh.sourceforge.io/Doc/Release/Files.html
# https://zsh.sourceforge.io/Doc/Release/Parameters.html
# XDG variables and directories are set up in ~/.zshenv
# This file is for login-shell-specific configuration only

# Include local .zprofile.local if it exists
[[ -f ~/.zprofile.local ]] && source ~/.zprofile.local
