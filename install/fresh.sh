#!/bin/sh

notice "Setting up your Mac..."

# Check for Homebrew and install if we don't have it
if test ! $(which brew); then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  echo 'eval "$($(which brew) shellenv)"' >> $HOME/.zprofile
  eval "$($(which brew) shellenv)"
fi

notice "Brew all the things"

# Update Homebrew recipes
brew update

# Install all our dependencies with bundle (See Brewfile)
brew tap homebrew/bundle
brew bundle --file $DOTFILES/install/Brewfile

# Setup development environment
source $DOTFILES/install/develop.sh

# Copy .private_env file
cp -Rf $DOTFILES/.private_env $HOME/.private_env

# Set macOS preferences - we will run this last because this will reload the shell
notice "Updating macOS settings"
source $DOTFILES/install/macos.sh
