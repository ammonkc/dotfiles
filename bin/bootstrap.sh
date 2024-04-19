#!/bin/bash

DOTFILES="$HOME/.dotfiles"

#-----------------------------------------------------------------------------
# Functions
#-----------------------------------------------------------------------------

# xterm colors
if [[ $COLORTERM = gnome-* && $TERM = xterm ]] && infocmp gnome-256color >/dev/null 2>&1; then
    export TERM=gnome-256color
elif infocmp xterm-256color >/dev/null 2>&1; then
    export TERM=xterm-256color
fi

# Notice (yellow) title
notice() { printf  "\033[1;32m=> $1\033[0m \n"; }

# Info (blue) title
info() { printf  "\033[0;34m=> $1\033[0m \n"; }

# Success (gree) title
success() { printf  "\033[0;32m=> $1\033[0m \n"; }

# Error () title
error() { printf "\033[1;31m=> Error: $1\033[0m \n"; }

# List item
c_list() { printf  "  \033[1;32m✔\033[0m $1 \n"; }

# Error list item
e_list() { printf  "  \033[1;31m✖\033[0m $1 \n"; }

# Check for dependency
dep() {
  type -p $1 &> /dev/null
  local installed=$?
  if [ $installed -eq 0 ]; then
    c_list $1
  else
    e_list $1
  fi
  return $installed
}

zsh_shell() {
  if [ ! -n "`$SHELL -c 'echo $ZSH_VERSION'`" ]; then
    chsh -s /bin/zsh
  fi
}

#-----------------------------------------------------------------------------
# Initialize
#-----------------------------------------------------------------------------

dependencies=(git tree vim stow)

#-----------------------------------------------------------------------------
# Dependencies
#-----------------------------------------------------------------------------

notice "Checking dependencies"

not_met=0
for need in "${dependencies[@]}"; do
  dep $need
  met=$?
  not_met=$(echo "$not_met + $met" | bc)
done

if [ $not_met -gt 0 ]; then
  error "$not_met dependencies not met!"
  exit 1
fi


#-----------------------------------------------------------------------------
# Install
#-----------------------------------------------------------------------------

# Assumes $DOTFILES is *ours*
if [ -d $DOTFILES ]; then
  pushd $DOTFILES

  # Sync Repo
  source $DOTFILES/bin/dotfiles-sync.sh

  # Stow dotfiles
  source $DOTFILES/bin/dotfiles-stow.sh

else
  # Check for Oh My Zsh and install if we don't have it
  if test ! $(which omz); then
    # Clone Repo
    notice "Cloning dotfiles repo"
    git clone --recursive https://github.com/ammonkc/dotfiles.git --branch stow --single-branch $DOTFILES
  fi

  if [ -d $DOTFILES ]; then
    pushd $DOTFILES

    git submodule update --remote

    # Removes .zshrc from $HOME (if it exists)
    if [ -f $HOME/.zshrc ]; then
      rm -rf $HOME/.zshrc
    fi

    # Install vimify
    # source $DOTFILES/bin/dotfiles-vimify.sh

    # Stow dotfiles
    source $DOTFILES/bin/dotfiles-stow.sh

    # Setup a fresh mac
    if [ "$(uname)" == "Darwin" ]; then
      notice "Running on OSX"
      echo
      notice "Setup fresh mac"
      source $DOTFILES/install/fresh.sh
    fi
    info "Don't forget to set your API Keys in $HOME/.private_env"
  fi
fi

#-----------------------------------------------------------------------------
# Finished
#-----------------------------------------------------------------------------

popd
notice "Done"
exec $SHELL -l
