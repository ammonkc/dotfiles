#!/bin/sh

notice "Setting up your Mac..."

# Check for Homebrew and install if we don't have it
if test ! $(which brew); then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  echo 'eval "$($(which brew) shellenv)"' >> $HOME/.zprofile
  eval "$($(which brew) shellenv)"
fi

mkdir -p $HOME/.ssh
ssh-keyscan -H github.com >> $HOME/.ssh/known_hosts
ssh-keyscan -H bitbucket.org >> $HOME/.ssh/known_hosts

notice "Brew all the things"

# Update Homebrew recipes
brew update

# Install all our dependencies with bundle (See Brewfile)
brew tap homebrew/bundle
brew bundle --file $DOTFILES/install/Brewfile

# Setup development environment
source $DOTFILES/install/develop.sh

# Generating new SSH keys
# source $DOTFILES/install/ssh.sh

# Copy .private_env file
cp -Rf $DOTFILES/.private_env $HOME/.private_env

# Set macOS preferences - we will run this last because this will reload the shell
notice "Updating macOS settings"
source $DOTFILES/install/macos.sh
