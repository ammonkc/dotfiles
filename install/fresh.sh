#!/bin/sh

notice "Setting up your Mac..."

mkdir -p $HOME/.ssh
ssh-keyscan -H github.com >> $HOME/.ssh/known_hosts
ssh-keyscan -H bitbucket.org >> $HOME/.ssh/known_hosts

# Brew
source $DOTFILES/install/brew.sh

# Stow dotfiles
source $DOTFILES/bin/dotfiles-stow.sh

# Setup development environment
source $DOTFILES/install/develop.sh

# Generating new SSH keys
# source $DOTFILES/install/ssh.sh

# Copy .private_env file
cp -Rf $DOTFILES/.private_env $HOME/.private_env

# Set macOS preferences - we will run this last because this will reload the shell
# notice "Updating macOS settings"
# source $DOTFILES/install/macos.sh
