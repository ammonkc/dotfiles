#!/bin/sh

echo "Setting up your Mac..."

DOTFILES=$HOME/.dotfiles

# Check for Homebrew and install if we don't have it
if test ! $(which brew); then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> $HOME/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

notice "Brew all the things"

# Update Homebrew recipes
brew update

# Install all our dependencies with bundle (See Brewfile)
brew tap homebrew/bundle
brew bundle --file $DOTFILES/mac/Brewfile

# Install PHP extensions with PECL
pecl install imagick
# pecl install redis swoole

# Install global Composer packages
# /usr/local/bin/composer global require laravel/installer

# Clone Github repositories
source $DOTFILES/mac/clone.sh

# Copy .private_env file
cp -Rf $DOTFILES/mac/.private_env $HOME/.private_env

# Set macOS preferences - we will run this last because this will reload the shell
notice "Updating macOS settings"
source $DOTFILES/mac/macos.sh
