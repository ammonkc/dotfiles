#!/usr/bin/env zsh
# Login-shell configuration. This file runs for interactive and non-interactive
# login shells; interactive startup continues in .zshrc.
# https://zsh.sourceforge.io/Doc/Release/Files.html
# https://zsh.sourceforge.io/Doc/Release/Parameters.html
# XDG variables and directories are set up in ~/.zshenv
# This file is for login-shell-specific configuration only

# Homebrew environment (once per login shell).
if [[ -n $HOMEBREW_PREFIX && -x $HOMEBREW_PREFIX/bin/brew ]]; then
  eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"
fi

# /etc/zprofile runs path_helper after .zshenv and pushes ~/.local/bin behind
# /usr/bin. Re-source path.zsh to restore the intended ordering.
[[ -e $ZDOTDIR/path.zsh ]] && source $ZDOTDIR/path.zsh

# Include local .zprofile.local if it exists
[[ -f ~/.zprofile.local ]] && source ~/.zprofile.local
